-- 婴儿脚本 · Blade Ball V2
-- 自动格挡（多路兜底）/ 球透视 / 玩家透视 / 速度
-- 适配：Blade Ball (PlaceId 13772394625, Wiggity.)
-- V2 修复：客户端不能用 RemoteEvent:Fire()，必须 FireServer()；球与远程都改成多路探测

local P = game:GetService("Players")
local LP = P.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local WS = game:GetService("Workspace")
local RUN = game:GetService("RunService")

local cfg = {
	mode = "off",        -- off / smart / lock / spam
	threshold = 0.18,    -- 到撞击剩余秒数小于它就算
	spamGap = 0.05,      -- 狂点间隔
	ballESP = true,
	playerESP = false,
	distTag = true,
}

-- ================= 格挡远程探测 =================
local CAB = {}
local lastScan = 0

local KW = { "parry", "deflect", "block", "guard" }

local function nameHit(n)
	n = string.lower(n)
	for _, k in ipairs(KW) do
		if string.find(n, k, 1, true) then return true end
	end
	return false
end

local function okClass(c)
	return c == "RemoteEvent" or c == "UnreliableRemoteEvent" or c == "RemoteFunction"
end

local function scoreOf(x)
	local s = 10
	local n = string.lower(x.Name)
	if x.Name == "ParryButtonPress" then s = 0
	elseif x.Name == "Parry" then s = 1
	elseif string.find(n, "parry", 1, true) then s = 2
	elseif string.find(n, "deflect", 1, true) then s = 3
	elseif string.find(n, "block", 1, true) then s = 4
	end
	if x.ClassName == "RemoteFunction" then s = s + 0.5 end
	return s
end

local function scanRemotes()
	local now = os.clock()
	if #CAB == 0 then
		if now - lastScan < 1 then return CAB end
	else
		if now - lastScan < 5 then return CAB end
	end
	lastScan = now

	local out = {}
	pcall(function()
		for _, d in ipairs(RS:GetDescendants()) do
			if okClass(d.ClassName) and nameHit(d.Name) then
				table.insert(out, d)
			end
		end
	end)

	if #out == 0 then
		local rm = RS:FindFirstChild("Remotes") or RS:FindFirstChild("RemoteEvents")
		if rm then
			for _, d in ipairs(rm:GetChildren()) do
				if okClass(d.ClassName) and nameHit(d.Name) then
					table.insert(out, d)
				end
			end
		end
	end

	table.sort(out, function(a, b) return scoreOf(a) < scoreOf(b) end)
	CAB = out
	return CAB
end

local lastParry = 0

local function fireOne(r)
	if not r or not r.Parent then return false end
	if r.ClassName == "RemoteFunction" then
		task.spawn(function() pcall(function() r:InvokeServer() end) end)
		return true
	end
	return pcall(function() r:FireServer() end)
end

local function doParry()
	local now = os.clock()
	if now - lastParry < 0.04 then return end
	local list = scanRemotes()
	if #list == 0 then return end
	lastParry = now
	for i = 1, math.min(#list, 3) do
		if fireOne(list[i]) then return end
	end
end

-- ================= 球探测 =================
local ballCache = {}
local lastBallScan = 0

local function ballPos(b)
	if b:IsA("BasePart") then return b.Position end
	local p = b.PrimaryPart
	if p then return p.Position end
	local ok, cf = pcall(function() return b:GetPivot() end)
	if ok and cf then return cf.Position end
	local any = b:FindFirstChildWhichIsA("BasePart", true)
	if any then return any.Position end
	return nil
end

local function ballPart(b)
	if b:IsA("BasePart") then return b end
	local p = b.PrimaryPart or b:FindFirstChildWhichIsA("BasePart", true)
	return p
end

local function ballVel(b)
	local part = ballPart(b)
	if not part then return Vector3.new() end
	local v = part.AssemblyLinearVelocity
	if not v or v.Magnitude < 0.5 then
		local ok, vv = pcall(function() return part.Velocity end)
		if ok and vv then v = vv end
	end
	return v or Vector3.new()
end

local function isFake(b)
	local a = b:GetAttribute("realBall")
	if a == false then return true end
	local b2 = b:GetAttribute("IsReal")
	if b2 == false then return true end
	return false
end

local function getBalls()
	local c = WS:FindFirstChild("Balls") or RS:FindFirstChild("Balls")
	if c then
		local out = {}
		for _, x in ipairs(c:GetChildren()) do
			if x:IsA("BasePart") or x:IsA("Model") then table.insert(out, x) end
		end
		return out
	end

	local now = os.clock()
	if now - lastBallScan > 2 then
		lastBallScan = now
		ballCache = {}
		pcall(function()
			for _, d in ipairs(WS:GetDescendants()) do
				if d:IsA("BasePart") and string.find(string.lower(d.Name), "ball", 1, true) then
					table.insert(ballCache, d)
				end
			end
		end)
	end
	return ballCache
end

-- ================= 判定 =================
local function rootOf(char)
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
end

local function isLocked(char)
	if not char then return false end
	if char:FindFirstChildOfClass("Highlight") then return true end
	for _, b in ipairs(getBalls()) do
		local t = b:GetAttribute("Target") or b:GetAttribute("TargetPlayer")
		if t ~= nil then
			if t == char or t == LP or t == LP.Name then return true end
		end
	end
	return false
end

local distCache = setmetatable({}, { __mode = "k" })

local function checkBall(b, char, root)
	if not b or not b.Parent then return end
	if isFake(b) then return end

	local pos = ballPos(b)
	if not pos then return end
	local dist = (pos - root.Position).Magnitude
	if dist > 90 then
		distCache[b] = dist
		return
	end

	local prev = distCache[b]
	distCache[b] = dist

	-- 贴脸无条件格挡
	if dist < 11 then
		doParry()
		return
	end

	local v = ballVel(b)
	if v.Magnitude < 1 then return end

	local toMe = root.Position - pos
	if toMe.Magnitude < 0.1 then
		doParry()
		return
	end
	toMe = toMe.Unit

	local closing = v:Dot(toMe)
	if closing < 3 then return end        -- 不是朝我来

	local t = (dist - 7) / closing
	if t <= cfg.threshold then
		doParry()
		return
	end

	-- 距离骤降兜底（应对速度数据异常）
	if prev and prev > dist and (prev - dist) > 3 and dist < 30 then
		doParry()
	end
end

-- ================= 主循环 =================
task.spawn(function()
	while true do
		RUN.Heartbeat:Wait()
		if cfg.mode == "smart" or cfg.mode == "lock" then
			local char = LP.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local root = rootOf(char)
			if root and hum and hum.Health > 0 then
				if cfg.mode == "smart" or isLocked(char) then
					for _, b in ipairs(getBalls()) do
						pcall(checkBall, b, char, root)
					end
				end
			end
		end
	end
end)

-- 狂点模式
task.spawn(function()
	while true do
		task.wait(cfg.spamGap)
		if cfg.mode == "spam" then
			pcall(doParry)
		end
	end
end)

-- ================= 界面 =================
local WindUI = loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/Footagesus/WindUI@main/dist/main.lua"))()
local Win = WindUI:CreateWindow({ Title = "Blade Ball V2" })
local T1 = Win:Tab({ Title = "格挡", Icon = "shield" })
local T2 = Win:Tab({ Title = "视觉", Icon = "eye" })
local T3 = Win:Tab({ Title = "移动", Icon = "zap" })

local LABEL = {
	off = "关闭",
	smart = "智能预测",
	lock = "锁定判定",
	spam = "狂点",
}

local function setMode(m)
	cfg.mode = m
	WindUI:Notify({
		Title = "格挡模式：" .. LABEL[m],
		Content = m == "off" and "自动格挡已停止"
			or (m == "spam" and "每 " .. math.floor(cfg.spamGap * 1000) .. " 毫秒发一次，最暴力"
			or "球朝你飞来时会自动格挡"),
		Duration = 4,
	})
end

-- ================= 球透视 =================
local ballTags = {}

local function killTag(t)
	pcall(function() if t.hl then t.hl:Destroy() end end)
	pcall(function() if t.bb then t.bb:Destroy() end end)
end

local function makeBallTag(b)
	local target = ballPart(b) or b
	local hl = Instance.new("Highlight")
	hl.Name = "BB_HL"
	hl.Adornee = target
	hl.FillColor = Color3.fromRGB(255, 70, 70)
	hl.FillTransparency = 0.45
	hl.OutlineColor = Color3.fromRGB(255, 255, 255)
	hl.OutlineTransparency = 0
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Parent = target

	local bb = Instance.new("BillboardGui")
	bb.Name = "BB_TAG"
	bb.Adornee = target
	bb.Size = UDim2.new(0, 150, 0, 30)
	bb.StudsOffset = Vector3.new(0, 1.6, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 500
	bb.Parent = target

	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.new(1, 0, 1, 0)
	tl.BackgroundTransparency = 1
	tl.Text = "球"
	tl.TextColor3 = Color3.fromRGB(255, 120, 120)
	tl.TextStrokeColor3 = Color3.new(0, 0, 0)
	tl.TextStrokeTransparency = 0.2
	tl.Font = Enum.Font.GothamBold
	tl.TextScaled = true
	tl.Parent = bb

	return { hl = hl, bb = bb, tl = tl, part = target }
end

task.spawn(function()
	while true do
		task.wait(0.15)
		if cfg.ballESP then
			local root = rootOf(LP.Character)
			for _, b in ipairs(getBalls()) do
				local part = ballPart(b)
				if part then
					local t = ballTags[b]
					if not t or t.part ~= part then
						if t then killTag(t) end
						t = makeBallTag(b)
						ballTags[b] = t
					end
					if t.tl then
						if cfg.distTag and root then
							t.tl.Text = "球 [" .. math.floor((part.Position - root.Position).Magnitude) .. "]"
						else
							t.tl.Text = "球"
						end
					end
				end
			end
		end
		for b, t in pairs(ballTags) do
			if not cfg.ballESP or not b.Parent then
				killTag(t)
				ballTags[b] = nil
			end
		end
	end
end)

-- ================= 玩家透视 =================
local pTags = {}
task.spawn(function()
	while true do
		task.wait(0.4)
		if cfg.playerESP then
			for _, pl in ipairs(P:GetPlayers()) do
				if pl ~= LP and pl.Character then
					local t = pTags[pl.Character]
					if not t then
						local hl = Instance.new("Highlight")
						hl.Name = "BBPHL"
						hl.Adornee = pl.Character
						hl.FillColor = Color3.fromRGB(80, 200, 255)
						hl.FillTransparency = 0.65
						hl.OutlineColor = Color3.fromRGB(80, 200, 255)
						hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
						hl.Parent = pl.Character
						pTags[pl.Character] = { hl = hl }
					end
				end
			end
		else
			for c, t in pairs(pTags) do
				pcall(function() if t.hl then t.hl:Destroy() end end)
				pTags[c] = nil
			end
		end
	end
end)

-- ================= 移动 =================
local sp = 16
local function applyHum()
	local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
	if h then pcall(function() h.WalkSpeed = sp end) end
end
LP.CharacterAdded:Connect(function() task.wait(0.6) pcall(applyHum) end)

-- ================= UI 面板 =================
T1:Section({ Title = "格挡模式（点一个）" })
T1:Button({ Title = "① 智能预测（推荐）", Callback = function() setMode("smart") end })
T1:Button({ Title = "② 只在被锁定时格挡", Callback = function() setMode("lock") end })
T1:Button({ Title = "③ 狂点模式（无冷却，最暴力）", Callback = function() setMode("spam") end })
T1:Button({ Title = "关闭自动格挡", Callback = function() setMode("off") end })

T1:Section({ Title = "参数" })
T1:Slider({ Title = "触发提前量（0.08–0.30 秒）", Value = { Min = 8, Max = 30, Default = 18 }, Callback = function(v)
	cfg.threshold = v / 100
end})
T1:Slider({ Title = "狂点间隔（30–200 毫秒）", Value = { Min = 30, Max = 200, Default = 50 }, Callback = function(v)
	cfg.spamGap = v / 1000
end})

T1:Section({ Title = "自检" })
T1:Button({ Title = "诊断：远程 / 球 / 锁定状态（自动复制）", Callback = function()
	local list = scanRemotes()
	local names = {}
	for i, r in ipairs(list) do
		table.insert(names, r.Name .. "[" .. r.ClassName .. "]")
		if i >= 8 then table.insert(names, "…"); break end
	end

	local balls = getBalls()
	local holder = "未找到"
	if WS:FindFirstChild("Balls") then holder = "Workspace.Balls"
	elseif RS:FindFirstChild("Balls") then holder = "ReplicatedStorage.Balls"
	elseif #balls > 0 then holder = "扫描 workspace（名字含 ball）"
	end

	local realInfo = "无"
	if #balls > 0 then
		local a = balls[1]:GetAttribute("realBall")
		realInfo = a == nil and "属性不存在" or tostring(a)
	end

	local txt = "远程(" .. #list .. ")：" .. (#names > 0 and table.concat(names, ", ") or "没找到")
		.. " | 球(" .. #balls .. ")：" .. holder .. " | realBall=" .. realInfo
		.. " | 被锁定=" .. (isLocked(LP.Character) and "是" or "否")

	if setclipboard then pcall(setclipboard, txt) end
	WindUI:Notify({ Title = "诊断（已复制）", Content = txt, Duration = 12 })
end})

T1:Button({ Title = "手动发一次格挡（测试）", Callback = function()
	local list = scanRemotes()
	if #list == 0 then
		WindUI:Notify({ Title = "测试", Content = "没找到任何格挡远程", Duration = 5 })
		return
	end
	local res = {}
	for i, r in ipairs(list) do
		local ok = fireOne(r)
		table.insert(res, r.Name .. (ok and "✓" or "✗"))
		if i >= 3 then break end
	end
	local txt = "已发：" .. table.concat(res, ", ") .. "｜看人物有没有挥剑动作"
	if setclipboard then pcall(setclipboard, txt) end
	WindUI:Notify({ Title = "测试", Content = txt, Duration = 8 })
end})

T2:Section({ Title = "透视" })
T2:Toggle({ Title = "球透视（红色 + 距离）", Value = true, Callback = function(v) cfg.ballESP = v end })
T2:Toggle({ Title = "显示距离数字", Value = true, Callback = function(v) cfg.distTag = v end })
T2:Toggle({ Title = "玩家透视（蓝色）", Value = false, Callback = function(v) cfg.playerESP = v end })

T3:Section({ Title = "移动" })
T3:Slider({ Title = "移动速度", Value = { Min = 16, Max = 150, Default = 16 }, Callback = function(v)
	sp = v
	applyHum()
end})
T3:Button({ Title = "恢复默认速度", Callback = function()
	sp = 16
	applyHum()
end})

task.delay(1, function()
	pcall(function()
		local n = #scanRemotes()
		WindUI:Notify({
			Title = "Blade Ball V2",
			Content = n > 0 and ("找到 " .. n .. " 个格挡远程，点「① 智能预测」开始")
				or "还没扫到格挡远程，进一局后再点「诊断」",
			Duration = 7,
		})
	end)
end)
