-- 婴儿脚本 · 游戏文字翻译（界面 + 场景）
-- 用法：主脚本「更多 → 翻译」开关；也可单独执行本文件
-- 引擎：腾讯 transmart（批量）→ Google gtx（逐条，备用）
if getgenv().BabyTransOff then pcall(getgenv().BabyTransOff) end

local P = game:GetService("Players")
local LP = P.LocalPlayer
local HS = game:GetService("HttpService")

local cfg = { lang = getgenv().BabyTransLang or "zh", scene = getgenv().BabyTransScene == true, other = getgenv().BabyTransOther ~= false }

local cache = {}                                  -- "lang|原文" -> 译文
local rec = setmetatable({}, { __mode = "k" })     -- 控件 -> {src=,out=}
local queue, qh = {}, 1                            -- 待翻译队列
local queued = setmetatable({}, { __mode = "k" })  -- 控件 -> 已排队的原文
local conns = {}
local alive = true
local okCount = 0
local engineName = "腾讯"
local lastErr = ""

-- ================= 网络 =================
local function post(url, body)
	local res
	local function pick(r) if r and r.Body then res = r.Body end end
	if request then
		local ok, r = pcall(request, { Url = url, Method = "POST", Body = body, Headers = { ["Content-Type"] = "application/json" } })
		if ok then pick(r) end
	elseif http_request then
		local ok, r = pcall(http_request, { Url = url, Method = "POST", Body = body, Headers = { ["Content-Type"] = "application/json" } })
		if ok then pick(r) end
	elseif syn and syn.request then
		local ok, r = pcall(syn.request, { Url = url, Method = "POST", Body = body, Headers = { ["Content-Type"] = "application/json" } })
		if ok then pick(r) end
	end
	if not res then
		local ok, r = pcall(function() return game:HttpPost(url, body, "application/json") end)
		if ok and type(r) == "string" then res = r end
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

-- 腾讯：一次可翻多条，返回数组
local function engineTencent(texts)
	local body = HS:JSONEncode({
		header = { fn = "auto_translation", client_key = "browser-chrome-110.0.0-Mac OS", user_type = "web", device_type = "web" },
		type = "plain",
		model_category = "normal",
		source = { lang = "auto", text_list = texts },
		target = { lang = cfg.lang },
	})
	local js = decode(post("https://transmart.qq.com/api/imt", body))
	if not js then return nil end
	local code = js.header and js.header.ret_code
	if code ~= "succ" and code ~= "0" then
		lastErr = "腾讯:" .. tostring(code or "?")
		return nil
	end
	local arr = js.auto_translation
	if type(arr) ~= "table" or #arr ~= #texts then return nil end
	return arr
end

-- Google：逐条，仅作备用
local function engineGoogle(texts)
	local out = {}
	for i, t in ipairs(texts) do
		local url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl="
			.. cfg.lang .. "&dt=t&q=" .. urlenc(t)
		local ok, raw = pcall(function() return game:HttpGet(url) end)
		if not ok then lastErr = "Google:取不到" return nil end
		local js = decode(raw)
		if not js or type(js[1]) ~= "table" then return nil end
		local s = ""
		for _, seg in ipairs(js[1]) do
			if type(seg) == "table" and type(seg[1]) == "string" then s = s .. seg[1] end
		end
		if s == "" then return nil end
		out[i] = s
		task.wait(0.1)
	end
	return out
end

local ENGINES = {
	{ name = "腾讯", fn = engineTencent },
	{ name = "Google", fn = engineGoogle },
}

local function translate(texts)
	local first = 1
	for i, e in ipairs(ENGINES) do
		if e.name == engineName then first = i break end
	end
	for k = 0, #ENGINES - 1 do
		local e = ENGINES[(first - 1 + k) % #ENGINES + 1]
		if e.name == "Google" and #texts > 8 then break end   -- 逐条引擎，批量时反而更慢
		local ok, out = pcall(e.fn, texts)
		if ok and out then
			engineName = e.name
			return out
		end
	end
	return nil
end

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
local BATCH = 40      -- 每批条数（腾讯实测 40 条约 2 秒，翻 40 条和翻 1 条差不多的等待时间）
local WORKERS = 3     -- 同时发几个请求

local function hudUpdate()
	if hudText and hudText.Parent then
		local qn = #queue - qh + 1
		if qn < 0 then qn = 0 end
		hudText.Text = "翻译 " .. okCount .. " 条 · 队列 " .. qn .. " · " .. engineName
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
