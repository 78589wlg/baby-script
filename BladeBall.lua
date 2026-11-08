-- 婴儿脚本 · Blade Ball V15
-- 自动格挡 / 球透视 / 玩家透视 / 速度
-- 适配：Blade Ball (PlaceId 13772394625, Wiggity.)
-- V5 关键修复：此服格挡是本地判定，客户端不发 ParryAttempt，必须模拟触摸点击
-- V6：该服有频率型反作弊，默认点击间隔放宽到 120ms，狂点模式 150ms
-- V7：按行为特征防踢（随机抖动 + 故意失误率），100% 格挡成功率是最明显的机器特征
-- V9：取消失误率，反应延迟 150~600ms 随机
-- V10：加距离限制，球进入设定格数内才格挡（太远挡了服务端不认，球打不回去）
-- V11：延迟严格受剩余飞行时间约束（最多用 60%），贴脸走紧急通道绕过节流，解决漏挡被球打死
-- V12：去掉按球对象记录的锁（游戏复用球实例会导致第二回合永久失效），改为时间戳 + 重生重置
-- V13：监听格挡成功，连续 N 次后主动冷却
-- V14：改用 getconnections 直连游戏格挡按钮（Hotbar.Block），不再模拟虚假输入，规避输入层检测
-- V15：界面精简成一个开关按钮（去掉三种模式按钮）

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
	missRate = 0,        -- 故意不格挡的概率（0 = 每颗都挡）
	reactMin = 0.15,     -- 反应延迟下限（秒）：球锁定后不立刻点
	reactMax = 0.60,     -- 反应延迟上限（秒）
	maxDist = 16,        -- 球进入这个距离内才允许格挡（太远挡了服务端不认）
	pointDist = 9,       -- 贴脸距离：不管时间，直接挡
	streakMax = 6,       -- 连续格挡成功 N 次后主动歇一下（0 = 不歇）
	coolMin = 4,         -- 冷却下限（秒）
	coolMax = 6,         -- 冷却上限（秒）
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

-- ================= 方案A：直接触发游戏格挡按钮的连接（推荐） =================
-- 参考开源实现：PlayerGui.Hotbar.Block 的 Activated / MouseButton1Click 连接可以直接 Fire
-- 好处：不产生虚假输入事件，走的是游戏自己的点击逻辑，反作弊看不到异常输入
local blockBtn, blockPath = nil, "未找到"

local function findBlockButton()
	local pg = LP:FindFirstChild("PlayerGui")
	if not pg then return nil, "无 PlayerGui" end

	local paths = {
		{"Hotbar", "Block"}, {"Hotbar", "Parry"}, {"Hotbar", "Deflect"},
		{"Block"}, {"Parry"}, {"Main", "Block"},
	}
	for _, path in ipairs(paths) do
		local cur = pg
		local okp = true
		for _, nm in ipairs(path) do
			if not cur then okp = false break end
			cur = cur:FindFirstChild(nm)
			if not cur then okp = false break end
		end
		if okp and cur and (cur:IsA("TextButton") or cur:IsA("ImageButton")) then
			return cur, table.concat(path, ".")
		end
	end

	-- 全局扫一遍，名字带 block / parry / deflect
	for _, d in ipairs(pg:GetDescendants()) do
		if d:IsA("TextButton") or d:IsA("ImageButton") then
			local n = string.lower(d.Name)
			if n:find("block") or n:find("parry") or n:find("deflect") then
				return d, d:GetFullName()
			end
		end
	end
	return nil, "未找到"
end

local function fireButton(btn)
	if not btn or not btn.Parent then return false end
	if typeof(getconnections) ~= "function" then return false end

	local fired = false
	for _, evName in ipairs({"Activated", "MouseButton1Click", "MouseButton1Down", "TouchTap"}) do
		local sig = btn[evName]
		if sig then
			local okc, conns = pcall(getconnections, sig)
			if okc and conns then
				for _, c in pairs(conns) do
					local okf = pcall(function() c:Fire() end)
					if okf then fired = true end
				end
			end
		end
	end
	return fired
end

local function refreshBlockButton()
	local b, pathName = findBlockButton()
	blockBtn, blockPath = b, pathName
	return b
end

local function tapScreen()
	-- 优先：直接触发格挡按钮的连接
	if blockBtn and blockBtn.Parent then
		if fireButton(blockBtn) then
			lastTapOk, lastTapErr = true, ("按钮连接 " .. tostring(blockPath))
			return true
		end
	end

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

local function trigger(isAuto, urgent)
	local now = os.clock()

	-- 自动触发时，按概率故意放过一颗球（默认 0，不生效）
	if isAuto and not urgent and cfg.humanOn and math.random() < (cfg.missRate or 0) then
		return
	end

	-- 间隔加抖动；球快贴脸时走紧急通道，放宽到 40ms，宁可多点一次也不能漏
	local gap = cfg.minGap or 0.12
	if urgent then
		gap = 0.04
	elseif cfg.humanOn then
		gap = gap * rnd(0.85, 1.45)
	end
	if now - lastAct < gap then return end
	lastAct = now
	S.lastFire = now
	S.fires = S.fires + 1
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
-- 不用 table 记录球对象：游戏可能复用同一个球实例，会导致永久锁死（第二回合失效）
local S = {
	pBall = nil,     -- 正在等待触发的球
	pAt = 0,         -- 该球开始等待的时间
	pTTL = 1.2,      -- 等待超时，超过就允许重新触发
	beats = 0,       -- 主循环心跳计数（诊断用）
	balls = 0,       -- 最近一帧扫到的球数
	mine = 0,        -- 最近一帧锁定我的球数
	lastFire = 0,    -- 最近一次实际点屏幕的时间
	fires = 0,       -- 累计点击次数
}

local function resetState()
	S.pBall, S.pAt = nil, 0
	S.coolUntil = 0
end
local function checkBall(b, root)
	if not b or not b.Parent then return end
	if os.clock() < (S.coolUntil or 0) then return end
	if b:GetAttribute("target") ~= LP.Name then return end

	local v = b.AssemblyLinearVelocity
	local speed = v.Magnitude
	if speed < 1 then return end

	local dist = (b.Position - root.Position).Magnitude
	local eta = dist / speed

	local thr = cfg.threshold
	if cfg.humanOn then thr = thr * rnd(0.82, 1.22) end

	-- 距离限制：球太远时格挡，服务端判定不成立，打不回去
	local maxD = cfg.maxDist or 16
	local pD = cfg.pointDist or 9
	local near = dist <= maxD
	local pointBlank = dist <= pD

	if pointBlank or (near and eta <= thr) then
		local now = os.clock()
		if S.pBall == b and (now - S.pAt) < S.pTTL then return end
		S.pBall, S.pAt = b, now

		-- 人类反应时间，但绝不能超过剩余飞行时间，否则必漏
		local waitT = 0
		if cfg.humanOn then
			if pointBlank or eta < 0.12 then
				waitT = rnd(0.02, 0.05)
			else
				-- 最多用掉剩余时间的 60%，留 40% 给输入和网络延迟
				local budget = math.max(0.03, eta * 0.60)
				local lo = math.min(cfg.reactMin or 0.15, budget)
				local hi = math.min(cfg.reactMax or 0.60, budget)
				if hi < lo then hi = lo end
				waitT = rnd(lo, hi)
			end
		end

		task.delay(waitT, function()
			if S.pBall == b then S.pBall = nil end
			if b and b.Parent then
				-- 到点后再确认一次距离，超时太久的球直接放弃
				local r2 = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
				if not r2 then return end
				local d2 = (b.Position - r2.Position).Magnitude
				if d2 > (cfg.maxDist or 16) + 6 then return end
				trigger(true, d2 <= (cfg.pointDist or 9) + 3 or eta < 0.18)
			end
		end)
	end
end

-- ================= 连击统计（用于避开服务端阈值） =================
do
	local rm = remotes()
	local psAll = rm and (rm:FindFirstChild("ParrySuccessAll") or rm:FindFirstChild("ParrySuccess"))
	if psAll and psAll.OnClientEvent then
		psAll.OnClientEvent:Connect(function(...)
			local args = table.pack(...)
			for i = 1, args.n do
				if args[i] == LP then
					S.streak = S.streak + 1
					S.lastWin = os.clock()
					if S.streak >= (cfg.streakMax or 3) then
						-- 到阈值前主动停手，等窗口滑过去
						S.coolUntil = os.clock() + rnd(cfg.coolMin or 3.5, cfg.coolMax or 5.5)
						S.streak = 0
					end
					break
				end
			end
		end)
	end
end

task.spawn(function()
	while true do
		RUN.Heartbeat:Wait()
		S.beats = S.beats + 1
		if cfg.mode == "smart" then
			pcall(function()
			local ch = LP.Character
			local hum = ch and ch:FindFirstChildOfClass("Humanoid")
			local root = ch and ch:FindFirstChild("HumanoidRootPart")
			local folder = ballFolder()
			if root and hum and hum.Health > 0 and folder then
				local list = folder:GetChildren()
				S.balls = #list
				local m = 0
				for _, b in ipairs(list) do
					if b:GetAttribute("target") == LP.Name then m = m + 1 end
					pcall(checkBall, b, root)
				end
				S.mine = m
			end
			end)
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
local Win = WindUI:CreateWindow({ Title = "Blade Ball V14" })
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
LP.CharacterAdded:Connect(function()
	resetState()
	lastAct = 0
	task.wait(0.6)
	pcall(applyHum)
	pcall(refreshBlockButton)
end)

-- 启动时扫一次格挡按钮（PlayerGui 里可能有，也可能要等角色加载）
task.spawn(function()
	for i = 1, 10 do
		if refreshBlockButton() then break end
		task.wait(1)
	end
end)

-- ================= UI =================
T1:Section({ Title = "自动格挡" })

local mainBtn, mainTitle
mainTitle = function()
	if cfg.mode == "off" then return "▶ 开启自动格挡" end
	return "■ 已开启 · 点此关闭"
end

local function paintMain()
	if not mainBtn then return end
	local t = mainTitle()
	pcall(function() mainBtn:SetTitle(t) end)
end

mainBtn = T1:Button({
	Title = mainTitle(),
	Desc = "点一下开关，球锁定你时自动格挡",
	Callback = function()
		setMode(cfg.mode == "off" and "smart" or "off")
		paintMain()
	end,
})

-- 按钮下面实时显示状态，点了有没有生效一眼能看出来
task.spawn(function()
	while true do
		task.wait(1)
		if mainBtn then
			local d = "点一下开关，球锁定你时自动格挡"
			if cfg.mode ~= "off" then
				d = "运行中 · 已点击 " .. tostring(S.fires) .. " 次 · 锁定你的球 " .. tostring(S.mine) .. " 颗"
			end
			pcall(function() mainBtn:SetDesc(d) end)
		end
	end
end)

T1:Section({ Title = "参数" })
T1:Slider({ Title = "提前量（0.10–0.60 秒）", Value = { Min = 10, Max = 60, Default = 30 }, Callback = function(v)
	cfg.threshold = v / 100
end})
T1:Toggle({ Title = "人类化（随机抖动 + 故意失误，防踢）", Value = true, Callback = function(v)
	cfg.humanOn = v
	WindUI:Notify({ Title = "人类化", Content = v and "已开启：间隔/坐标/按压时长/反应时间随机" or "已关闭：变成固定节拍，容易被踢", Duration = 5 })
end})
T1:Slider({ Title = "故意失误率（0–30%，0 = 每颗都挡）", Value = { Min = 0, Max = 30, Default = 0 }, Callback = function(v)
	cfg.missRate = v / 100
end})
T1:Slider({ Title = "反应延迟下限（60–600 毫秒）", Value = { Min = 60, Max = 600, Default = 150 }, Callback = function(v)
	cfg.reactMin = v / 1000
	if cfg.reactMax < cfg.reactMin then cfg.reactMax = cfg.reactMin + 0.05 end
end})
T1:Slider({ Title = "反应延迟上限（60–600 毫秒）", Value = { Min = 60, Max = 600, Default = 600 }, Callback = function(v)
	cfg.reactMax = v / 1000
	if cfg.reactMin > cfg.reactMax then cfg.reactMin = math.max(0.06, cfg.reactMax - 0.05) end
end})
T1:Slider({ Title = "格挡距离（8–40 格，越小越近才挡）", Value = { Min = 8, Max = 40, Default = 16 }, Callback = function(v)
	cfg.maxDist = v
	if cfg.pointDist > v then cfg.pointDist = math.max(5, v - 4) end
end})
T1:Slider({ Title = "贴脸距离（5–20 格，无条件挡）", Value = { Min = 5, Max = 20, Default = 9 }, Callback = function(v)
	cfg.pointDist = v
end})

T1:Section({ Title = "连击保护（避开服务端阈值）" })
T1:Slider({ Title = "连续格挡上限（1–6 次，到就歇）", Value = { Min = 1, Max = 6, Default = 6 }, Callback = function(v)
	cfg.streakMax = v
end})
T1:Slider({ Title = "歇多久下限（2–10 秒）", Value = { Min = 2, Max = 10, Default = 4 }, Callback = function(v)
	cfg.coolMin = v
	if cfg.coolMax < cfg.coolMin then cfg.coolMax = cfg.coolMin + 1 end
end})
T1:Slider({ Title = "歇多久上限（2–12 秒）", Value = { Min = 2, Max = 12, Default = 6 }, Callback = function(v)
	cfg.coolMax = v
	if cfg.coolMin > cfg.coolMax then cfg.coolMin = math.max(2, cfg.coolMax - 1) end
end})
T1:Slider({ Title = "最小点击间隔（80–400 毫秒，防踢）", Value = { Min = 80, Max = 400, Default = 120 }, Callback = function(v)
	cfg.minGap = v / 1000
end})
T1:Slider({ Title = "点击位置 X（0.20–0.80）", Value = { Min = 20, Max = 80, Default = 50 }, Callback = function(v)
	cfg.tapX = v / 100
end})
T1:Slider({ Title = "点击位置 Y（0.20–0.85）", Value = { Min = 20, Max = 85, Default = 62 }, Callback = function(v)
	cfg.tapY = v / 100
end})

T1:Section({ Title = "自检" })
T1:Button({ Title = "重新扫描格挡按钮", Callback = function()
	local b = refreshBlockButton()
	WindUI:Notify({
		Title = b and "找到格挡按钮" or "没找到格挡按钮",
		Content = b and (tostring(blockPath) .. "｜将直连它的点击连接") or "会降级为模拟触摸点击",
		Duration = 8,
	})
end})
T1:Button({ Title = "诊断状态（自动复制）", Callback = function()
	local ev = parryEvent()
	local folder = ballFolder()
	local total = folder and #folder:GetChildren() or 0
	local mine = lockedBallCount()
	local cam = WS.CurrentCamera

	local since = os.clock() - (S.lastFire or 0)
	local txt = "【运行】模式=" .. tostring(cfg.mode)
		.. " | 心跳=" .. tostring(S.beats)
		.. " | 球=" .. tostring(S.balls) .. " 锁定我=" .. tostring(S.mine)
		.. " | 累计点击=" .. tostring(S.fires)
		.. " | 上次点击=" .. (S.lastFire > 0 and (string.format("%.1f", since) .. "秒前") or "从未")
		.. "\n【连击】连续成功=" .. tostring(S.streak)
		.. " | 冷却剩余=" .. (os.clock() < (S.coolUntil or 0) and string.format("%.1f", S.coolUntil - os.clock()) .. "秒" or "无")
		.. "\n【远程】ParryAttempt=" .. (ev and "存在" or "不存在")
		.. " | 相机=" .. (cam and "有" or "无")
		.. " | 球总数=" .. total .. " 锁定我=" .. mine
		.. " | 触摸=" .. (lastTapOk and "可用" or "未成功")
		.. " | 方式=" .. tostring(lastTapErr)
		.. "\n【按钮】" .. tostring(blockPath)
		.. " | getconnections=" .. (typeof(getconnections) == "function" and "可用" or "不可用")

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
			Title = "Blade Ball V15",
			Content = blockBtn and "格挡按钮已就绪，点「▶ 开启自动格挡」" or "没找到格挡按钮，会降级为模拟触摸点击",
			Duration = 7,
		})
	end)
end)
