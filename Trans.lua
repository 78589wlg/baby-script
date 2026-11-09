-- 婴儿脚本 · 游戏文字翻译（界面 + 场景）
-- 用法：主脚本「更多 → 翻译」开关；也可单独执行本文件
-- 引擎：Google / 必应 / 腾讯 / MyMemory，可自选，失败自动换下一个
if getgenv().BabyTransOff then pcall(getgenv().BabyTransOff) end

local P = game:GetService("Players")
local LP = P.LocalPlayer
local HS = game:GetService("HttpService")

local cfg = { lang = getgenv().BabyTransLang or "zh", scene = getgenv().BabyTransScene == true, other = getgenv().BabyTransOther ~= false, engine = getgenv().BabyTransEngine or "auto" }

local cache = {}                                  -- "lang|原文" -> 译文
local rec = setmetatable({}, { __mode = "k" })     -- 控件 -> {src=,out=}
local queue, qh = {}, 1                            -- 待翻译队列
local queued = setmetatable({}, { __mode = "k" })  -- 控件 -> 已排队的原文
local conns = {}
local alive = true
local okCount = 0
local engineName = "自动"
local lastErr = ""

-- ================= 网络 =================
local function httpReq(method, url, body, headers)
	local h = {}
	if headers then for k, v in pairs(headers) do h[k] = v end end
	if body and not h["Content-Type"] then h["Content-Type"] = "application/json" end
	local res
	local function grab(r) if r and r.Body then res = r.Body end end
	if request then
		pcall(function() grab(request({ Url = url, Method = method, Body = body, Headers = h })) end)
	elseif http_request then
		pcall(function() grab(http_request({ Url = url, Method = method, Body = body, Headers = h })) end)
	elseif syn and syn.request then
		pcall(function() grab(syn.request({ Url = url, Method = method, Body = body, Headers = h })) end)
	end
	if not res then
		if method == "GET" then
			local ok, r = pcall(function() return game:HttpGet(url) end)
			if ok and type(r) == "string" then res = r end
		else
			local ok, r = pcall(function() return game:HttpPost(url, body, "application/json") end)
			if ok and type(r) == "string" then res = r end
		end
	end
	return res
end

local function urlenc(s)
	return (tostring(s):gsub("[^%w%-%._~]", function(c) return string.format("%%%02X", string.byte(c)) end))
end

local function decode(raw)
	if not raw or raw == "" then return nil end
	local ok, js = pcall(function() return HS:JSONDecode(raw) end)
	if ok and type(js) == "table" then return js end
	return nil
end

-- 各引擎的语言代码不一样，这里统一映射
local LNG = {
	google   = { zh = "zh-CN", ["zh-TW"] = "zh-TW", en = "en", ja = "ja", ko = "ko" },
	bing     = { zh = "zh-Hans", ["zh-TW"] = "zh-Hant", en = "en", ja = "ja", ko = "ko" },
	tencent  = { zh = "zh", ["zh-TW"] = "zh-TW", en = "en", ja = "ja", ko = "ko" },
	mymemory = { zh = "zh-CN", ["zh-TW"] = "zh-TW", en = "en", ja = "ja", ko = "ko" },
}

local function L(eng) return LNG[eng][cfg.lang] or LNG[eng].zh end

-- ---------- 腾讯 ----------
local function engineTencent(texts)
	local body = HS:JSONEncode({
		header = { fn = "auto_translation", client_key = "browser-chrome-110.0.0-Mac OS", user_type = "web", device_type = "web" },
		type = "plain",
		model_category = "normal",
		source = { lang = "auto", text_list = texts },
		target = { lang = L("tencent") },
	})
	local js = decode(httpReq("POST", "https://transmart.qq.com/api/imt", body))
	if not js or not js.header then return nil end
	local code = js.header.ret_code
	if code ~= "succ" and code ~= "0" then return nil end
	local arr = js.auto_translation
	if type(arr) ~= "table" or #arr ~= #texts then return nil end
	return arr
end

-- ---------- Google ----------
local googleOne

local function gsplit(chunk)
	local mid = math.floor(#chunk / 2)
	local a, b = {}, {}
	for i = 1, mid do a[#a + 1] = chunk[i] end
	for i = mid + 1, #chunk do b[#b + 1] = chunk[i] end
	local pa, pb = googleOne(a), googleOne(b)
	if not pa or not pb then return nil end
	local out = {}
	for _, v in ipairs(pa) do out[#out + 1] = v end
	for _, v in ipairs(pb) do out[#out + 1] = v end
	return out
end

googleOne = function(chunk)
	if #chunk == 0 then return {} end
	local q = table.concat(chunk, "\n")
	if #q > 1600 then
		if #chunk == 1 then return nil end
		return gsplit(chunk)
	end
	local url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl="
		.. L("google") .. "&dt=t&q=" .. urlenc(q)
	local js = decode(httpReq("GET", url))
	if not js or type(js[1]) ~= "table" then
		if #chunk == 1 then return nil end
		return gsplit(chunk)
	end
	local buf = {}
	for _, seg in ipairs(js[1]) do
		if type(seg) == "table" and type(seg[1]) == "string" then buf[#buf + 1] = seg[1] end
	end
	local whole = table.concat(buf)
	if whole == "" then
		if #chunk == 1 then return nil end
		return gsplit(chunk)
	end
	local parts = {}
	for line in (whole .. "\n"):gmatch("(.-)\n") do parts[#parts + 1] = line end
	if #parts == #chunk then return parts end
	if #chunk == 1 then return { whole } end
	-- 行数对不上（原文里带换行等），拆半重试，比整体走别的引擎快
	return gsplit(chunk)
end

local function engineGoogle(texts)
	local out, i = {}, 1
	while i <= #texts do
		local chunk, chars = {}, 0
		while i <= #texts and chars < 900 and #chunk < 30 do
			chunk[#chunk + 1] = texts[i]
			chars = chars + #texts[i] + 1
			i = i + 1
		end
		local part = googleOne(chunk)
		if not part then return nil end
		for k = 1, #part do out[#out + 1] = part[k] end
	end
	return out
end

-- ---------- 必应（微软 Azure 免费令牌，支持数组批量） ----------
local bingTok, bingTokAt = nil, 0
local function bingToken()
	if bingTok and os.clock() - bingTokAt < 480 then return bingTok end
	local raw = httpReq("GET", "https://edge.microsoft.com/translate/auth")
	if not raw or #raw < 40 then return nil end
	bingTok, bingTokAt = raw, os.clock()
	return bingTok
end

local function engineBing(texts)
	local tok = bingToken()
	if not tok then return nil end
	local arr = {}
	for i, t in ipairs(texts) do arr[i] = { Text = t } end
	local url = "https://api-edge.cognitive.microsofttranslator.com/translate?api-version=3.0&to=" .. L("bing")
	local js = decode(httpReq("POST", url, HS:JSONEncode(arr), { ["Authorization"] = "Bearer " .. tok }))
	if type(js) ~= "table" then return nil end
	local out = {}
	for i, item in ipairs(js) do
		local tr = item.translations and item.translations[1]
		if not tr or type(tr.text) ~= "string" then return nil end
		out[i] = tr.text
	end
	if #out ~= #texts then return nil end
	return out
end

-- ---------- MyMemory（免密钥，单条限额） ----------
local function engineMyMemory(texts)
	if #texts > 4 then return nil end
	local out = {}
	for i, t in ipairs(texts) do
		local url = "https://api.mymemory.translated.net/get?q=" .. urlenc(t) .. "&langpair=auto|" .. L("mymemory")
		local js = decode(httpReq("GET", url))
		local tx = js and js.responseData and js.responseData.translatedText
		if type(tx) ~= "string" or tx == "" then return nil end
		out[i] = tx
	end
	return out
end

local ENG = {
	google   = { name = "Google", fn = engineGoogle, max = 25 },
	bing     = { name = "必应", fn = engineBing, max = 25 },
	tencent  = { name = "腾讯", fn = engineTencent, max = 40 },
	mymemory = { name = "MyMemory", fn = engineMyMemory, max = 4 },
}
local AUTO_ORDER = { "google", "bing", "tencent", "mymemory" }
local badUntil, failN = {}, {}
local topEngine, probeDone = nil, false

local function runEngine(e, texts)
	local out, i = {}, 1
	while i <= #texts do
		local chunk = {}
		while i <= #texts and #chunk < e.max do
			chunk[#chunk + 1] = texts[i]
			i = i + 1
		end
		local ok, part = pcall(e.fn, chunk)
		if not ok or type(part) ~= "table" then return nil end
		for k = 1, #chunk do out[#out + 1] = part[k] or "" end
	end
	return out
end

local function orderEngines()
	local o, seen = {}, {}
	local function push(k)
		if ENG[k] and not seen[k] then seen[k] = true; o[#o + 1] = k end
	end
	if cfg.engine ~= "auto" then push(cfg.engine) end
	if cfg.engine == "auto" and topEngine then push(topEngine) end
	for _, k in ipairs(AUTO_ORDER) do push(k) end
	local live = {}
	for _, k in ipairs(o) do
		if not badUntil[k] or os.clock() > badUntil[k] then live[#live + 1] = k end
	end
	if #live == 0 then return o end
	return live
end

local function translate(texts)
	while cfg.engine == "auto" and not probeDone and alive do
		task.wait(0.1)
	end
	for _, k in ipairs(orderEngines()) do
		local e = ENG[k]
		local out = runEngine(e, texts)
		if out then
			failN[k] = 0
			engineName = e.name
			lastErr = ""
			return out
		end
		failN[k] = (failN[k] or 0) + 1
		if failN[k] >= 2 then badUntil[k] = os.clock() + 120 end
		lastErr = e.name .. "不通"
	end
	return nil
end

-- 自动模式：同时试四个，谁先回来用谁
local function startProbe()
	if cfg.engine ~= "auto" then probeDone = true; return end
	local best
	for _, k in ipairs(AUTO_ORDER) do
		task.spawn(function()
			local ok, out = pcall(ENG[k].fn, { "hello" })
			if ok and out and out[1] and out[1] ~= "" and not best then best = k end
		end)
	end
	local t0 = os.clock()
	while not best and os.clock() - t0 < 6 and alive do task.wait(0.1) end
	topEngine = best or "tencent"
	probeDone = true
end
task.spawn(startProbe)

-- ================= 文本筛选 =================
local function trim(s)
	return (tostring(s):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function usable(t)
	if type(t) ~= "string" then return nil end
	t = trim(t)
	if #t < 2 or #t > 240 then return nil end
	local ascii = t:find("%a") ~= nil
	local cjk = t:find("[\228-\233][\128-\191][\128-\191]") ~= nil
	if not ascii and not cjk then return nil end
	if cfg.lang == "zh" or cfg.lang == "zh-TW" then
		if cjk and not ascii then return nil end      -- 已经是中文
	elseif cfg.lang == "en" then
		if ascii and not cjk then return nil end      -- 已经是英文
	end
	return t
end

-- ================= HUD =================
local hud, hudText
local function buildHud()
	local pg = LP:FindFirstChildOfClass("PlayerGui") or game:GetService("CoreGui")
	local old = pg:FindFirstChild("BabyTrans")
	if old then pcall(function() old:Destroy() end) end
	local g = Instance.new("ScreenGui")
	g.Name = "BabyTrans"; g.ResetOnSpawn = false; g.IgnoreGuiInset = true; g.DisplayOrder = 998
	g.Parent = pg
	local f = Instance.new("Frame")
	f.Name = "Pill"
	f.AnchorPoint = Vector2.new(1, 0)
	f.Position = UDim2.new(1, -10, 0, 10)
	f.Size = UDim2.new(0, 196, 0, 30)
	f.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
	f.BackgroundTransparency = 0.15
	f.BorderSizePixel = 0
	f.Parent = g
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = f
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, -12, 1, 0); t.Position = UDim2.new(0, 8, 0, 0)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamMedium
	t.TextSize = 12
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.TextColor3 = Color3.fromRGB(235, 235, 240)
	t.Text = "翻译 0 条"
	t.Parent = f
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 1, 0); btn.BackgroundTransparency = 1; btn.Text = ""
	btn.Parent = f
	local mini = false
	btn.MouseButton1Click:Connect(function()
		mini = not mini
		f.Size = mini and UDim2.new(0, 34, 0, 30) or UDim2.new(0, 196, 0, 30)
		t.Visible = not mini
		if mini then t.Text = "" else t.Text = "翻译 " .. okCount .. " 条" end
	end)
	hud, hudText = g, t
end

-- ================= 核心 =================
local function applyText(inst, src, out)
	local r = rec[inst]
	if not r then r = {}; rec[inst] = r end
	r.src, r.out = src, out
	queued[inst] = nil
	pcall(function() inst.Text = out end)
end

local function enqueue(inst, text)
	local t = usable(text)
	if not t then return end
	local key = cfg.lang .. "|" .. t
	local hit = cache[key]
	if hit then
		applyText(inst, t, hit)
		return
	end
	if queued[inst] == t then return end
	queued[inst] = t
	queue[#queue + 1] = { inst = inst, text = t }
end

local watched = setmetatable({}, { __mode = "k" })

local function watch(inst)
	if inst:GetAttribute("BabyTrW") then return end
	watched[inst] = true
	pcall(function() inst:SetAttribute("BabyTrW", true) end)
	local c = inst:GetPropertyChangedSignal("Text"):Connect(function()
		if not alive then return end
		local now = inst.Text
		local r = rec[inst]
		if r and now == r.out then return end          -- 是我们刚写进去的译文
		if r and now ~= r.src then r.src, r.out = nil, nil end  -- 游戏换了新文字
		enqueue(inst, now)
	end)
	conns[#conns + 1] = c
end

-- 自己面板的根节点（由主脚本传入 WindUI 窗口），永远不翻
local selfRoot
do
	local w = getgenv().BabyTransSelfGui
	if w then
		local o, guard = w, 0
		while o and o.Parent and o.Parent ~= game and guard < 10 do o = o.Parent; guard = guard + 1 end
		if o and o ~= game then selfRoot = o end
	end
end

local OWN = { "婴儿脚本", "BabyTrans", "BabyOnline", "BabyTag" }
local OTHER = { "WindUI", "Rayfield", "Orion", "Kavo", "Fluent", "Linoria", "Owl" }

local function inSkip(inst)
	if selfRoot and inst:IsDescendantOf(selfRoot) then return true end
	local o = inst
	for _ = 1, 8 do
		o = o.Parent
		if not o or o == game then break end
		local nm = tostring(o.Name)
		for _, k in ipairs(OWN) do
			if nm:find(k, 1, true) then return true end
		end
		if not cfg.other then
			for _, k in ipairs(OTHER) do
				if nm:find(k, 1, true) then return true end
			end
		end
	end
	return false
end

local function visibleNow(inst)
	if inst.Visible == false then return false end
	local o, guard = inst.Parent, 0
	while o and o ~= game and guard < 12 do
		guard = guard + 1
		if o:IsA("GuiObject") then
			if o.Visible == false then return false end
		elseif o:IsA("LayerCollector") then
			return o.Enabled ~= false
		end
		o = o.Parent
	end
	return true
end

local function consider(inst)
	if not inst or not inst.Parent then return end
	if inSkip(inst) then return end
	if hud and inst:IsDescendantOf(hud) then return end
	if not visibleNow(inst) then return end          -- 关着/隐藏的界面先不翻，打开后由补扫接手
	if not inst:GetAttribute("BabyTrW") then watch(inst) end
	local r = rec[inst]
	if r and r.out and inst.Text == r.out then return end
	enqueue(inst, inst.Text)
end

-- 已登记的控件每 1 秒复查一次：从隐藏变可见、或文字被游戏改回原文，就立刻补翻
local function recheck()
	for inst in pairs(watched) do
		if inst.Parent and visibleNow(inst) then
			local r = rec[inst]
			if not (r and r.out and inst.Text == r.out) then
				enqueue(inst, inst.Text)
			end
		end
	end
end

local function isTextClass(o)
	return o:IsA("TextLabel") or o:IsA("TextButton")
end

local function scan(root)
	if not root then return end
	local ok, list = pcall(function() return root:GetDescendants() end)
	if not ok or not list then return end
	for _, d in ipairs(list) do
		if isTextClass(d) then consider(d) end
	end
end

local function watchTree(root)
	local c = root.DescendantAdded:Connect(function(d)
		if isTextClass(d) then consider(d) end
	end)
	conns[#conns + 1] = c
end

-- ================= 工作线程 =================
local BATCH = 25      -- 每批条数（Google 一次 20-25 条约 1 秒）
local WORKERS = 4     -- 同时发几个请求

local function hudUpdate()
	if hudText and hudText.Parent then
		local qn = #queue - qh + 1
		if qn < 0 then qn = 0 end
		local tail = engineName
		if qn > 20 and lastErr ~= "" then tail = lastErr end
		hudText.Text = "翻译 " .. okCount .. " 条 · 队列 " .. qn .. " · " .. tail
	end
end

local function worker()
	local idle = 0
	while alive do
		local items, texts, seen = {}, {}, {}
		local want = math.min(BATCH, #queue - qh + 1)
		local taken = 0
		while taken < want and qh <= #queue and #texts < BATCH do
			local it = queue[qh]; qh = qh + 1
			taken = taken + 1
			local inst = it.inst
			local r = rec[inst]
			local stillSame = inst.Parent and (inst.Text == it.text or (r and r.out == inst.Text))
			if stillSame and usable(it.text) then
				local key = cfg.lang .. "|" .. it.text
				local hit = cache[key]
				if hit then
					applyText(inst, it.text, hit)
				elseif not seen[key] then
					seen[key] = true
					texts[#texts + 1] = it.text
					items[#items + 1] = it
				end
			end
		end
		if qh > 600 then
			local fresh = {}
			for i = qh, #queue do fresh[#fresh + 1] = queue[i] end
			queue, qh = fresh, 1
		end

		if #texts == 0 then
			idle = idle + 1
			task.wait(idle > 3 and 0.4 or 0.15)
		else
			idle = 0
			local out = translate(texts)
			if out then
				for k, it in ipairs(items) do
					local t = out[k]
					if type(t) == "string" and t ~= "" then
						cache[cfg.lang .. "|" .. it.text] = t
						applyText(it.inst, it.text, t)
						okCount = okCount + 1
					else
						queued[it.inst] = nil
					end
				end
			else
				for _, it in ipairs(items) do queued[it.inst] = nil end
				task.wait(0.6)
			end
		end
		hudUpdate()
	end
end

for _ = 1, WORKERS do
	task.spawn(worker)
end

-- ================= 启停 =================
getgenv().BabyTransSetLang = function(code)
	if not code then return end
	cfg.lang = code
	-- 用原文重排一遍
	for inst, r in pairs(rec) do
		if r.src and inst.Parent then
			queued[inst] = nil
			queue[#queue + 1] = { inst = inst, text = r.src }
		end
	end
end

getgenv().BabyTransSetEngine = function(k)
	cfg.engine = k or "auto"
	badUntil, failN = {}, {}
	if cfg.engine == "auto" then
		probeDone = false
		task.spawn(startProbe)
	else
		probeDone = true
	end
end

getgenv().BabyTransSetScene = function(v)
	cfg.scene = v and true or false
	if cfg.scene then
		scan(workspace)
		watchTree(workspace)
	end
end

local function coreGui()
	local ok, c = pcall(function() return game:GetService("CoreGui") end)
	if ok then return c end
end

-- 翻译其他脚本（第三方面板）：WindUI/Rayfield/Orion 等，以及 CoreGui 里的执行器 UI
getgenv().BabyTransSetOther = function(v)
	cfg.other = v and true or false
	if cfg.other then
		local c = coreGui()
		if c then scan(c); watchTree(c) end
		local p = LP:FindFirstChildOfClass("PlayerGui")
		if p then scan(p) end
	end
end

getgenv().BabyTransOff = function()
	alive = false
	for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
	conns = {}
	-- 还原原文
	for inst, r in pairs(rec) do
		if inst.Parent and r.src then pcall(function() inst.Text = r.src end) end
	end
	rec = setmetatable({}, { __mode = "k" })
	queue, qh = {}, 1
	if hud then pcall(function() hud:Destroy() end) end
	getgenv().BabyTransOff = nil
	getgenv().BabyTransSetLang = nil
	getgenv().BabyTransSetScene = nil
	getgenv().BabyTransSetOther = nil
	getgenv().BabyTransSetEngine = nil
end

buildHud()
local pg = LP:FindFirstChildOfClass("PlayerGui")
if pg then
	scan(pg)
	watchTree(pg)
end
if cfg.scene then
	scan(workspace)
	watchTree(workspace)
end
if cfg.other then
	local c = coreGui()
	if c then scan(c); watchTree(c) end
end

-- 新界面延迟出现，隔几秒补扫一次
task.spawn(function()
	local tick = 0
	while alive do
		task.wait(1)
		if not alive then break end
		tick = tick + 1
		pcall(recheck)
		if tick % 5 == 0 then
			local p = LP:FindFirstChildOfClass("PlayerGui")
			if p then scan(p) end
			if cfg.scene then scan(workspace) end
		end
	end
end)
