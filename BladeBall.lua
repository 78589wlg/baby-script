-- 婴儿脚本 · Blade Ball V8
-- 自动格挡 / 球透视 / 玩家透视 / 速度
-- 适配：Blade Ball (PlaceId 13772394625, Wiggity.)
-- V5 关键修复：此服格挡是本地判定，客户端不发 ParryAttempt，必须模拟触摸点击
-- V6：该服有频率型反作弊，默认点击间隔放宽到 120ms，狂点模式 150ms
-- V7：按行为特征防踢（随机抖动 + 故意失误率），100% 格挡成功率是最明显的机器特征
-- V8：加入人类反应延迟（球锁定后随机等 100~240ms 再按），消除零延迟特征

local P = game:GetService("Players")
local LP = P.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local WS = game:GetService("Workspace")
local RUN = game:GetService("RunService")

local cfg = {
	mode = "off",        -- off / smart / spam / remote / key
	threshold = 0.30,    -- 剩余飞行秒数小于它才格挡
	spamGap = 0.15,
	minGap = 0.12,       -- 两次点击的最小间隔（防反作弊频率检测）
	humanOn = true,      -- 人类化：随机间隔/按压时长/坐标 + 故意失误
	missRate = 0.12,     -- 故意不格挡的概率（100% 成功率是最明显的机器特征）
	reactMin = 0.10,     -- 反应延迟下限（秒）：球锁定后不立刻点
	reactMax = 0.24,     -- 反应延迟上限（秒）
	arg1 = 0.50,         -- ParryAttempt 第一个参数
	fullArgs = true,     -- true=发完整 4 参数，false=空参数
	keyName = "F",
	useTap = true,       -- 优先模拟触摸（这游戏格挡走本地判定）
	tapX = 0.50,         -- 点击位置：屏宽比例
	tapY = 0.62,         -- 点击位置：屏高比例
	ballESP = true,
	playerESP = false,
	distTag = true,
}

-- ================= 格挡远程 =================
local function remotes()
	return RS:FindFirstChild("Remotes")
end

local function parryEvent()
	local r = remotes()
	return r and r:FindFirstChild("ParryAttempt")
end

-- 每个玩家的屏幕坐标（服务端用它校验「你确实看得见」）
local function playerPoints()
	local t = {}
	local cam = WS.CurrentCamera
	if not cam then return t end
	for _, v in ipairs(P:GetPlayers()) do
		local ch = v.Character
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
		if hrp then
			local ok, sp = pcall(function() return cam:WorldToScreenPoint(hrp.Position) end)
			if ok and sp then t[tostring(v.UserId)] = sp end
		end
	end
	return t
end

local lastAct = 0

local function doParryAct()
	local ev = parryEvent()
	if not ev then return false end
	local ch = LP.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	local cam = WS.CurrentCamera
	if not hrp or not cam then return false end

	return pcall(function()
		if cfg.fullArgs then
			local sp = cam:WorldToScreenPoint(hrp.Position)
			ev:FireServer(cfg.arg1, cam.CFrame, playerPoints(), { sp.X, sp.Y })
		else
			ev:FireServer()
		end
	end)
end

local function pressKey()
	local name = cfg.keyName or "F"
	local okc, kc = pcall(function() return Enum.KeyCode[name].Value end)

	if keypress and keyrelease and okc then
		local ok = pcall(function()
			keypress(kc)
			task.wait(0.015)
			keyrelease(kc)
		end)
		if ok then return true end
	end

	return pcall(function()
		local VIM = game:GetService("VirtualInputManager")
		VIM:SendKeyEvent(true, name, false, game)
		task.wait(0.015)
		VIM:SendKeyEvent(false, name, false, game)
	end)
end

-- ================= 模拟触摸（关键：这游戏格挡走本地判定，不发远程） =================
local lastTapOk, lastTapErr = false, "未执行"

local function rnd(a, b)
	return a + math.random() * (b - a)
end

local function tapScreen()
	local cam = WS.CurrentCamera
	local vp = (cam and cam.ViewportSize) or Vector2.new(800, 600)

	-- 人手的点击坐标不会每次完全一样，这里加几十像素的随机偏移
	local ox, oy = 0, 0
	if cfg.humanOn then
		ox = rnd(-24, 24)
		oy = rnd(-18, 18)
	end
	local x = math.floor(vp.X * (cfg.tapX or 0.5) + ox)
	local y = math.floor(vp.Y * (cfg.tapY or 0.62) + oy)

	-- 人手指按压通常 45~110 毫秒，固定 12 毫秒是机器特征
	local pressT = cfg.humanOn and rnd(0.045, 0.110) or 0.012

	local VIM = game:GetService("VirtualInputManager")
	local ok, err = pcall(function()
		VIM:SendMouseButtonEvent(x, y, 0, true, game, 1)
		task.wait(pressT)
		VIM:SendMouseButtonEvent(x, y, 0, false, game, 1)
	end)
	if ok then lastTapOk, lastTapErr = true, ("VIM @" .. x .. "," .. y) return true end

	if type(mouse1click) == "function" then
		local s2 = pcall(mouse1click)
		if s2 then lastTapOk, lastTapErr = true, "mouse1click" return true end
	end

	if touchscreen and type(touchscreen.tap) == "function" then
		local s3 = pcall(function() touchscreen.tap(x, y) end)
		if s3 then lastTapOk, lastTapErr = true, ("touchscreen @" .. x .. "," .. y) return true end
	end

	lastTapOk, lastTapErr = false, ("失败：" .. tostring(err))
	return false
end

local function trigger(isAuto)
	local now = os.clock()

	-- 自动触发时，按概率故意放过一颗球：成功率 100% 是最容易被识别的特征
	if isAuto and cfg.humanOn and math.random() < (cfg.missRate or 0) then
		return
	end

	-- 间隔加 ±25% 抖动，避免形成固定节拍
	local gap = cfg.minGap or 0.12
	if cfg.humanOn then gap = gap * rnd(0.85, 1.45) end
	if now - lastAct < gap then return end
	lastAct = now
	if cfg.mode == "key" then
		pressKey()
	elseif cfg.mode == "remote" then
		doParryAct()
	else
		-- smart / spam / tap 都走模拟触摸
		if cfg.useTap then
			if not tapScreen() then doParryAct() end
		else
			doParryAct()
		end
	end
end

-- ================= 球 =================
local function ballFolder()
	return WS:FindFirstChild("Balls")
end

local function lockedBallCount()
	local n, folder = 0, ballFolder()
	if not folder then return 0 end
	for _, b in ipairs(folder:GetChildren()) do
		if b:GetAttribute("target") == LP.Name then n = n + 1 end
	end
	return n
end

-- 只处理 target 指向我的球（游戏自己写这个属性，比几何判断准）
local pending = {}
local function checkBall(b, root)
	if not b or not b.Parent then return end
	if b:GetAttribute("target") ~= LP.Name then return end

	local v = b.AssemblyLinearVelocity
	local speed = v.Magnitude
	if speed < 1 then return end

	local dist = (b.Position - root.Position).Magnitude
	local eta = dist / speed

	local thr = cfg.threshold
	if cfg.humanOn then thr = thr * rnd(0.82, 1.22) end

	if eta <= thr or dist < 12 then
		if pending[b] then return end
		pending[b] = true

		-- 人类反应时间：不会在球锁定的同一帧就按下，也不会每次都一样
		local waitT = 0
		if cfg.humanOn then
			if dist < 12 then
				-- 球已经贴脸，只能象征性延迟一下
				waitT = rnd(0.03, 0.07)
			else
				local lo, hi = cfg.reactMin, cfg.reactMax
				-- 反应再慢也不能慢到球已经砸脸上，最多用到剩余时间的一半
				if hi > eta * 0.55 then hi = math.max(lo, eta * 0.55) end
				waitT = rnd(lo, hi)
			end
		end

		task.delay(waitT, function()
			pending[b] = nil
			if b and b.Parent then trigger(true) end
		end)
	end
end

task.spawn(function()
	while true do
		RUN.Heartbeat:Wait()
		if cfg.mode == "smart" then
			local ch = LP.Character
			local hum = ch and ch:FindFirstChildOfClass("Humanoid")
			local root = ch and ch:FindFirstChild("HumanoidRootPart")
			local folder = ballFolder()
			if root and hum and hum.Health > 0 and folder then
				for _, b in ipairs(folder:GetChildren()) do
					pcall(checkBall, b, root)
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
			pcall(function() trigger(false) end)
		end
	end
end)

-- ================= 界面 =================
local WindUI = loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/Footagesus/WindUI@main/dist/main.lua"))()
local Win = WindUI:CreateWindow({ Title = "Blade Ball V8" })
local T1 = Win:Tab({ Title = "格挡", Icon = "shield" })
local T2 = Win:Tab({ Title = "视觉", Icon = "eye" })
local T3 = Win:Tab({ Title = "移动", Icon = "zap" })

local LABEL = { off = "关闭", smart = "智能触摸", spam = "狂点触摸", key = "模拟按键", remote = "发远程" }

local function setMode(m)
	cfg.mode = m
	WindUI:Notify({
		Title = "格挡：" .. LABEL[m],
		Content = m == "off" and "已停止"
			or (m == "spam" and ("每 " .. math.floor(cfg.spamGap * 1000) .. " 毫秒点一次｜间隔太小会被踢"))
			or (m == "key" and ("模拟按 " .. (cfg.keyName or "F") .. " 键"))
			or (m == "remote" and "发 ParryAttempt 远程（本服无效）")
			or "球锁定你时自动点屏幕",
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
	local hl = Instance.new("Highlight")
	hl.Name = "BB_HL"
	hl.Adornee = b
	hl.FillColor = Color3.fromRGB(255, 70, 70)
	hl.FillTransparency = 0.45
	hl.OutlineColor = Color3.fromRGB(255, 255, 255)
	hl.OutlineTransparency = 0
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Parent = b

	local bb = Instance.new("BillboardGui")
	bb.Name = "BB_TAG"
	bb.Adornee = b
	bb.Size = UDim2.new(0, 160, 0, 30)
	bb.StudsOffset = Vector3.new(0, 1.8, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 600
	bb.Parent = b

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

	return { hl = hl, bb = bb, tl = tl }
end

task.spawn(function()
	while true do
		task.wait(0.15)
		if cfg.ballESP then
			local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
			local folder = ballFolder()
			if folder then
				for _, b in ipairs(folder:GetChildren()) do
					local t = ballTags[b]
					if not t then
						t = makeBallTag(b)
						ballTags[b] = t
					end
					if t.tl then
						local mine = b:GetAttribute("target") == LP.Name
						local txt = mine and "★ 球" or "球"
						if cfg.distTag and root then
							txt = txt .. " [" .. math.floor((b.Position - root.Position).Magnitude) .. "]"
						end
						t.tl.Text = txt
						t.tl.TextColor3 = mine and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(255, 170, 170)
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
					if not pTags[pl.Character] then
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

-- ================= UI =================
T1:Section({ Title = "格挡模式（点一个）" })
T1:Button({ Title = "① 智能格挡（模拟触摸，推荐）", Callback = function() setMode("smart") end })
T1:Button({ Title = "② 狂点触摸（无冷却，最暴力）", Callback = function() setMode("spam") end })
T1:Button({ Title = "③ 发远程（本服无效，备用）", Callback = function() setMode("remote") end })
T1:Button({ Title = "关闭自动格挡", Callback = function() setMode("off") end })

T1:Section({ Title = "参数" })
T1:Slider({ Title = "提前量（0.10–0.60 秒）", Value = { Min = 10, Max = 60, Default = 30 }, Callback = function(v)
	cfg.threshold = v / 100
end})
T1:Toggle({ Title = "人类化（随机抖动 + 故意失误，防踢）", Value = true, Callback = function(v)
	cfg.humanOn = v
	WindUI:Notify({ Title = "人类化", Content = v and "已开启：间隔/坐标/按压时长随机，并故意漏挡" or "已关闭：变成固定节拍，容易被踢", Duration = 5 })
end})
T1:Slider({ Title = "故意失误率（0–30%，越大越安全）", Value = { Min = 0, Max = 30, Default = 12 }, Callback = function(v)
	cfg.missRate = v / 100
end})
T1:Slider({ Title = "反应延迟下限（60–300 毫秒）", Value = { Min = 60, Max = 300, Default = 100 }, Callback = function(v)
	cfg.reactMin = v / 1000
	if cfg.reactMax < cfg.reactMin then cfg.reactMax = cfg.reactMin + 0.05 end
end})
T1:Slider({ Title = "反应延迟上限（60–400 毫秒）", Value = { Min = 60, Max = 400, Default = 240 }, Callback = function(v)
	cfg.reactMax = v / 1000
	if cfg.reactMin > cfg.reactMax then cfg.reactMin = math.max(0.06, cfg.reactMax - 0.05) end
end})
T1:Slider({ Title = "最小点击间隔（80–400 毫秒，防踢）", Value = { Min = 80, Max = 400, Default = 120 }, Callback = function(v)
	cfg.minGap = v / 1000
end})
T1:Slider({ Title = "狂点间隔（100–400 毫秒）", Value = { Min = 100, Max = 400, Default = 150 }, Callback = function(v)
	cfg.spamGap = v / 1000
end})
T1:Slider({ Title = "格挡参数1（0.10–1.00）", Value = { Min = 10, Max = 100, Default = 50 }, Callback = function(v)
	cfg.arg1 = v / 100
end})
T1:Slider({ Title = "点击位置 X（0.20–0.80）", Value = { Min = 20, Max = 80, Default = 50 }, Callback = function(v)
	cfg.tapX = v / 100
end})
T1:Slider({ Title = "点击位置 Y（0.20–0.85）", Value = { Min = 20, Max = 85, Default = 62 }, Callback = function(v)
	cfg.tapY = v / 100
end})
T1:Toggle({ Title = "发送完整参数（关掉=空参数）", Value = true, Callback = function(v)
	cfg.fullArgs = v
	WindUI:Notify({ Title = "参数模式", Content = v and "完整 4 参数（推荐）" or "空参数（多数服会用不了）", Duration = 4 })
end})
T1:Input({ Title = "③ 模式按键（默认 F）", Placeholder = "F", Value = "F", Callback = function(t)
	local v = tostring(t or ""):gsub("%s+", "")
	if v == "" then v = "F" end
	cfg.keyName = v:upper()
end})

T1:Section({ Title = "自检" })
T1:Button({ Title = "诊断状态（自动复制）", Callback = function()
	local ev = parryEvent()
	local folder = ballFolder()
	local total = folder and #folder:GetChildren() or 0
	local mine = lockedBallCount()
	local cam = WS.CurrentCamera

	local txt = "ParryAttempt=" .. (ev and "存在" or "不存在")
		.. " | 相机=" .. (cam and "有" or "无")
		.. " | 球总数=" .. total .. " 锁定我=" .. mine
		.. " | 参数模式=" .. (cfg.fullArgs and "完整" or "空")
		.. " | 触摸=" .. (lastTapOk and "可用" or "未成功")
		.. " | 方式=" .. tostring(lastTapErr)

	if setclipboard then pcall(setclipboard, txt) end
	WindUI:Notify({ Title = "诊断（已复制）", Content = txt, Duration = 10 })
end})

T1:Button({ Title = "测试：点一下屏幕（看有无格挡动作）", Callback = function()
	local ok = tapScreen()
	WindUI:Notify({
		Title = ok and "已点击屏幕" or "点击失败",
		Content = ok and ("方式：" .. lastTapErr .. "｜看人物有没有格挡动作") or lastTapErr,
		Duration = 8,
	})
end})

T2:Section({ Title = "透视" })
T2:Toggle({ Title = "球透视（标 ★ 的是锁定你的球）", Value = true, Callback = function(v) cfg.ballESP = v end})
T2:Toggle({ Title = "显示距离数字", Value = true, Callback = function(v) cfg.distTag = v end})
T2:Toggle({ Title = "玩家透视（蓝色）", Value = false, Callback = function(v) cfg.playerESP = v end})

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
		WindUI:Notify({
			Title = "Blade Ball V4",
			Content = parryEvent() and "ParryAttempt 已找到，点「① 智能格挡」开始" or "没找到 ParryAttempt，先别开格挡",
			Duration = 7,
		})
	end)
end)
