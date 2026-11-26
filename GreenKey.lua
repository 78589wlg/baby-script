-- ============================================================
-- GreenKey · 娱乐菜单（婴儿脚本出品）
-- 风格：绿钥匙 —— 绿色圆形悬浮球 + 白色钥匙图标 + 圆角卡片
-- 功能：人物 / 动作 / 视觉 / 彩蛋
-- 用法：loadstring(game:HttpGet("https://raw.githubusercontent.com/78589wlg/baby-script/main/GreenKey.lua?v=1"))()
-- ============================================================

local P = game:GetService("Players")
local LP = P.LocalPlayer
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local WS = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

if getgenv().GreenKeyStop then pcall(getgenv().GreenKeyStop) end

-- ---------- 配色（取自绿钥匙图标） ----------
local GRN = Color3.fromRGB(86, 166, 110)     -- 主绿
local GRN2 = Color3.fromRGB(66, 142, 92)     -- 深一点
local GRNL = Color3.fromRGB(112, 196, 138)   -- 高亮绿
local BG = Color3.fromRGB(22, 24, 27)        -- 面板底
local CARD = Color3.fromRGB(33, 36, 40)      -- 卡片
local CARD2 = Color3.fromRGB(41, 45, 50)     -- 卡片悬停
local LN = Color3.fromRGB(52, 57, 62)        -- 分割线
local TXT = Color3.fromRGB(232, 237, 233)
local SUB = Color3.fromRGB(140, 150, 143)
local RED = Color3.fromRGB(196, 78, 78)

local conns = {}
local clamp = math.clamp or function(v, lo, hi) return math.min(math.max(v, lo), hi) end
local function on(sig, fn)
	local c = sig:Connect(fn)
	conns[#conns + 1] = c
	return c
end

-- ---------- 状态与效果引擎 ----------
local FX = {}
local saved = {}
local charConn = nil

local function root()
	local c = LP.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end
local function humanoid()
	local c = LP.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end

local refreshCard   -- 前置声明，UI 建好后赋值，保证任何状态变化都能同步到卡片

local function setFx(key, on)
	local fx = FX[key]
	if not fx then return end
	if on == fx.on then return end
	if on then
		local ok = pcall(fx.start)
		if ok then fx.on = true end
	else
		pcall(fx.stop)
		fx.on = false
	end
	if refreshCard then refreshCard(key) end
end

local function toggleFx(key)
	local fx = FX[key]
	if not fx then return end
	setFx(key, not fx.on)
	return fx.on
end

local function replayAll()
	task.wait(1.2)
	for key, fx in pairs(FX) do
		if fx.on then
			pcall(function()
				fx.stop()
				fx.start()
			end)
		end
	end
end

-- ---------- 各效果实现 ----------
local function partsSnapshot()
	local t = {}
	local c = LP.Character
	if not c then return t end
	for _, p in ipairs(c:GetDescendants()) do
		if p:IsA("BasePart") then t[p] = { col = p.Color, tr = p.Transparency } end
	end
	return t
end

-- 彩虹身体
local rainbowConn = nil
local function rainbowStart()
	if rainbowConn then return end
	rainbowConn = RS.RenderStepped:Connect(function()
		local c = LP.Character
		if not c then return end
		local hue = (os.clock() % 4) / 4
		local col = Color3.fromHSV(hue, 1, 1)
		for _, p in ipairs(c:GetDescendants()) do
			if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
				p.Color = col
			end
		end
	end)
end
local function rainbowStop()
	if rainbowConn then pcall(function() rainbowConn:Disconnect() end) rainbowConn = nil end
	for p, r in pairs(saved.rainbow or {}) do
		pcall(function() p.Color = r.col end)
	end
end

-- 变大 / 变小（互斥）
local function setScale(v)
	local h = humanoid()
	if not h then return end
	for _, n in ipairs({ "BodyHeightScale", "BodyWidthScale", "BodyDepthScale", "HeadScale" }) do
		local x = h:FindFirstChild(n)
		if not x then
			x = Instance.new("NumberValue")
			x.Name = n
			x.Parent = h
		end
		x.Value = v
	end
end
local function bigStart()
	setFx("small", false)
	saved.bigScale = true
	setScale(2)
end
local function bigStop() setScale(1) end
local function smallStart()
	setFx("big", false)
	saved.smallScale = true
	setScale(0.5)
end
local function smallStop() setScale(1) end

-- 半透明隐身
local function ghostStart()
	saved.ghost = partsSnapshot()
	local c = LP.Character
	if not c then return end
	for _, p in ipairs(c:GetDescendants()) do
		if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
			p.Transparency = 0.75
		elseif p:IsA("Decal") then
			p.Transparency = 1
		end
	end
end
local function ghostStop()
	for p, r in pairs(saved.ghost or {}) do
		pcall(function() p.Transparency = r.tr end)
	end
end

-- 疯狂旋转
local spinAtt, spinBV = nil, nil
local function spinStop2()
	if spinBV then pcall(function() spinBV:Destroy() end) spinBV = nil end
	if spinAtt then pcall(function() spinAtt:Destroy() end) spinAtt = nil end
	local h = humanoid()
	if h then pcall(function() h.AutoRotate = true end) end
end
local function spinStart()
	spinStop2()
	local r = root()
	if not r then return end
	local a = Instance.new("Attachment")
	a.Name = "GKSpinAtt"
	a.Parent = r
	local b = Instance.new("BodyAngularVelocity")
	b.Name = "GKSpin"
	b.Attachment0 = a
	b.MaxTorque = Vector3.new(0, 1e7, 0)
	b.AngularVelocity = Vector3.new(0, 25, 0)
	b.Parent = r
	spinAtt, spinBV = a, b
end

-- 无限跳
local infConn = nil
local function infStart()
	if infConn then return end
	infConn = UIS.JumpRequest:Connect(function()
		local h = humanoid()
		if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
	end)
end
local function infStop()
	if infConn then pcall(function() infConn:Disconnect() end) infConn = nil end
end

-- 弹簧腿
local function highStart()
	local h = humanoid()
	if not h then return end
	saved.jp = h.JumpPower
	h.UseJumpPower = true
	h.JumpPower = 220
end
local function highStop()
	local h = humanoid()
	if h and saved.jp then h.JumpPower = saved.jp end
end

-- 慢动作
local function slowStart()
	local h = humanoid()
	if h then
		saved.sp2 = h.WalkSpeed or 16
		h.WalkSpeed = 8
	end
	saved.grav = WS.Gravity or 196.2
	WS.Gravity = 80
end
local function slowStop()
	local h = humanoid()
	if h and saved.sp2 then h.WalkSpeed = saved.sp2 end
	if saved.grav then WS.Gravity = saved.grav end
end

-- 月球重力
local function moonStart()
	saved.grav2 = WS.Gravity or 196.2
	WS.Gravity = 35
end
local function moonStop()
	if saved.grav2 then WS.Gravity = saved.grav2 end
end

-- 夜视
local function nightStart()
	saved.bri = Lighting.Brightness
	saved.amb = Lighting.Ambient
	saved.out = Lighting.OutdoorAmbient
	Lighting.Brightness = 3
	Lighting.Ambient = Color3.fromRGB(160, 160, 160)
	Lighting.OutdoorAmbient = Color3.fromRGB(160, 160, 160)
end
local function nightStop()
	if saved.bri then Lighting.Brightness = saved.bri end
	if saved.amb then Lighting.Ambient = saved.amb end
	if saved.out then Lighting.OutdoorAmbient = saved.out end
end

-- 超远视角
local function zoomStart()
	saved.zm = LP.CameraMaxZoomDistance
	LP.CameraMaxZoomDistance = 400
end
local function zoomStop()
	if saved.zm then LP.CameraMaxZoomDistance = saved.zm end
end

-- 广角
local fovConn = nil
local function fovStart()
	if fovConn then return end
	fovConn = RS.RenderStepped:Connect(function()
		local cam = WS.CurrentCamera
		if cam and cam.FieldOfView ~= 100 then cam.FieldOfView = 100 end
	end)
end
local function fovStop()
	if fovConn then pcall(function() fovConn:Disconnect() end) fovConn = nil end
	local cam = WS.CurrentCamera
	if cam then pcall(function() cam.FieldOfView = 70 end) end
end

-- 紫滤镜
local filterObj = nil
local function filterStart()
	if filterObj and filterObj.Parent then filterObj.Enabled = true return end
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "GKFilter"
	cc.TintColor = Color3.fromRGB(190, 160, 255)
	cc.Saturation = 0.15
	cc.Parent = Lighting
	filterObj = cc
end
local function filterStop()
	if filterObj then pcall(function() filterObj.Enabled = false end) end
end

-- 摔不死
local softBV = nil
local function softStop2()
	if softBV then pcall(function() softBV:Destroy() end) softBV = nil end
end
local function softStart()
	softStop2()
	local r = root()
	if not r then return end
	local b = Instance.new("BodyVelocity")
	b.Name = "GKSoft"
	b.MaxForce = Vector3.new(0, 1e5, 0)
	b.Velocity = Vector3.new(0, -6, 0)
	b.Parent = r
	softBV = b
end

-- 头顶称号
local titleBB = nil
local function titleStop2()
	if titleBB then pcall(function() titleBB:Destroy() end) titleBB = nil end
end
local function titleStart()
	titleStop2()
	local c = LP.Character
	local head = c and c:FindFirstChild("Head")
	if not head then return end
	local bb = Instance.new("BillboardGui")
	bb.Name = "GKTitle"
	bb.Adornee = head
	bb.AlwaysOnTop = true
	bb.Size = UDim2.new(0, 220, 0, 34)
	bb.StudsOffset = Vector3.new(0, 2.6, 0)
	bb.MaxDistance = 120
	bb.Parent = head
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, 0, 1, 0)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamBold
	t.TextSize = 16
	t.TextColor3 = Color3.fromRGB(255, 236, 150)
	t.TextStrokeTransparency = 0.3
	t.Text = saved.titleText or "GreenKey"
	t.Parent = bb
	titleBB = bb
end
local function titleSetText(txt)
	saved.titleText = txt
	if FX.title and FX.title.on then
		titleStop2()
		titleStart()
	end
end

-- 头顶烟花
local fwObj = nil
local function fwStop2()
	if fwObj then pcall(function() fwObj:Destroy() end) fwObj = nil end
end
local function fwStart()
	fwStop2()
	local c = LP.Character
	local head = c and c:FindFirstChild("Head")
	if not head then return end
	local e = Instance.new("ParticleEmitter")
	e.Name = "GKFW"
	e.Texture = "rbxasset://textures/particles/fire_main.dds"
	e.Rate = 26
	e.Lifetime = NumberRange.new(0.7, 1.3)
	e.Speed = NumberRange.new(6, 11)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Color = ColorSequence.new(Color3.fromRGB(120, 230, 150), Color3.fromRGB(255, 240, 140))
	e.Size = NumberSequence.new(0.8, 0.1)
	e.Parent = head
	fwObj = e
end

FX.rainbow = { start = rainbowStart, stop = rainbowStop }
FX.big = { start = bigStart, stop = bigStop }
FX.small = { start = smallStart, stop = smallStop }
FX.ghost = { start = ghostStart, stop = ghostStop }
FX.spin = { start = spinStart, stop = spinStop2 }
FX.infjump = { start = infStart, stop = infStop }
FX.highjump = { start = highStart, stop = highStop }
FX.slow = { start = slowStart, stop = slowStop }
FX.moon = { start = moonStart, stop = moonStop }
FX.night = { start = nightStart, stop = nightStop }
FX.zoom = { start = zoomStart, stop = zoomStop }
FX.fov = { start = fovStart, stop = fovStop }
FX.filter = { start = filterStart, stop = filterStop }
FX.soft = { start = softStart, stop = softStop2 }
FX.title = { start = titleStart, stop = titleStop2 }
FX.firework = { start = fwStart, stop = fwStop2 }

saved.rainbow = partsSnapshot()

-- ---------- 分类 ----------
local CATS = {
	{ name = "人物", icon = "◆", items = {
		{ key = "rainbow", label = "彩虹身体" },
		{ key = "big", label = "变大巨人" },
		{ key = "small", label = "变小矮人" },
		{ key = "ghost", label = "半透明隐身" },
	} },
	{ name = "动作", icon = "▶", items = {
		{ key = "spin", label = "疯狂旋转" },
		{ key = "infjump", label = "无限跳" },
		{ key = "highjump", label = "弹簧腿高跳" },
		{ key = "slow", label = "慢动作世界" },
		{ key = "moon", label = "月球重力" },
	} },
	{ name = "视觉", icon = "◉", items = {
		{ key = "night", label = "夜视" },
		{ key = "zoom", label = "超远视角" },
		{ key = "fov", label = "广角镜头" },
		{ key = "filter", label = "夜幕紫滤镜" },
	} },
	{ name = "彩蛋", icon = "★", items = {
		{ key = "title", label = "头顶称号", input = true },
		{ key = "soft", label = "摔不死气球" },
		{ key = "firework", label = "头顶烟花" },
	} },
}

-- ---------- UI 基础工具 ----------
local gui = Instance.new("ScreenGui")
gui.Name = "GreenKeyMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 960
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

local function corner(o, r)
	local c = Instance.new("UICorner")
	if r >= 100 then
		c.CornerRadius = UDim.new(1, 0)
	else
		c.CornerRadius = UDim.new(0, r)
	end
	c.Parent = o
	return c
end
local function stroke(o, col, th, tr)
	local s = Instance.new("UIStroke")
	s.Color = col
	s.Thickness = th
	s.Transparency = tr or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = o
	return s
end
local function mkFrame(parent, size, pos, color)
	local f = Instance.new("Frame")
	f.Size = size
	f.Position = pos
	f.BackgroundColor3 = color or CARD
	f.BorderSizePixel = 0
	f.Parent = parent
	return f
end
local function mkLabel(parent, props)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.BorderSizePixel = 0
	l.Font = Enum.Font.Gotham
	l.TextColor3 = TXT
	l.TextSize = 13
	l.TextXAlignment = Enum.TextXAlignment.Left
	for k, v in pairs(props) do l[k] = v end
	l.Parent = parent
	return l
end
local function mkBtn(parent, props)
	local b = Instance.new("TextButton")
	b.AutoButtonColor = false
	b.BorderSizePixel = 0
	b.Font = Enum.Font.GothamBold
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.TextSize = 13
	for k, v in pairs(props) do b[k] = v end
	b.Parent = parent
	return b
end

-- 绿色圆 + 白色钥匙 + 小锁（纯图形拼，无外链图）
local function drawKeyArt(parent, s, fg)
	local rot = Instance.new("Frame")
	rot.Name = "KeyArt"
	rot.AnchorPoint = Vector2.new(0.5, 0.5)
	rot.Position = UDim2.fromScale(0.5, 0.5)
	rot.Size = UDim2.fromOffset(s, s)
	rot.BackgroundTransparency = 1
	rot.Rotation = -42
	rot.Parent = parent

	local ring = Instance.new("Frame")
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Position = UDim2.fromScale(0.5, 0.24)
	ring.Size = UDim2.fromOffset(s * 0.42, s * 0.42)
	ring.BackgroundTransparency = 1
	ring.Parent = rot
	corner(ring, 100)
	stroke(ring, fg, math.max(2, s * 0.085))

	local shaft = mkFrame(rot, UDim2.fromOffset(s * 0.11, s * 0.44), UDim2.fromScale(0.5, 0.76), fg)
	shaft.AnchorPoint = Vector2.new(0.5, 1)
	corner(shaft, math.max(2, s * 0.055))

	local t1 = mkFrame(rot, UDim2.fromOffset(s * 0.17, s * 0.075), UDim2.fromScale(0.55, 0.72), fg)
	t1.AnchorPoint = Vector2.new(0, 0.5)
	corner(t1, math.max(1, s * 0.03))
	local t2 = mkFrame(rot, UDim2.fromOffset(s * 0.13, s * 0.07), UDim2.fromScale(0.55, 0.86), fg)
	t2.AnchorPoint = Vector2.new(0, 0.5)
	corner(t2, math.max(1, s * 0.03))
	return rot
end

local function drawLockBadge(parent, s, bgCol, lockCol)
	local bg = Instance.new("Frame")
	bg.AnchorPoint = Vector2.new(1, 1)
	bg.Position = UDim2.new(1, s * 0.06, 1, s * 0.06)
	bg.Size = UDim2.fromOffset(s * 0.46, s * 0.46)
	bg.BackgroundColor3 = bgCol
	bg.BorderSizePixel = 0
	bg.Parent = parent
	corner(bg, 100)
	local body = mkFrame(bg, UDim2.fromOffset(s * 0.19, s * 0.15), UDim2.fromScale(0.5, 0.60), lockCol)
	body.AnchorPoint = Vector2.new(0.5, 0)
	corner(body, math.max(1, s * 0.03))
	local sh = Instance.new("Frame")
	sh.AnchorPoint = Vector2.new(0.5, 1)
	sh.Position = UDim2.fromScale(0.5, 0.60)
	sh.Size = UDim2.fromOffset(s * 0.14, s * 0.15)
	sh.BackgroundTransparency = 1
	sh.Parent = bg
	corner(sh, s * 0.07)
	stroke(sh, lockCol, math.max(1, s * 0.028))
	return bg
end

-- ---------- 悬浮球 ----------
local BALL = 62
local ball = mkBtn(gui, {
	Name = "Ball",
	Size = UDim2.fromOffset(BALL, BALL),
	Position = UDim2.new(0, 14, 0.40, 0),
	BackgroundColor3 = GRN,
	Text = "",
})
corner(ball, 100)
stroke(ball, Color3.fromRGB(255, 255, 255), 2, 0.15)
drawKeyArt(ball, BALL, Color3.fromRGB(255, 255, 255))
drawLockBadge(ball, BALL, Color3.fromRGB(255, 255, 255), GRN)

-- ---------- 面板 ----------
local PW, PH = 420, 478
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromOffset(PW, PH)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.BackgroundColor3 = BG
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui
corner(panel, 18)
stroke(panel, Color3.fromRGB(70, 78, 72), 1, 0.35)

local uiScale = Instance.new("UIScale")
uiScale.Scale = 1
uiScale.Parent = panel

-- 顶部
local header = mkFrame(panel, UDim2.new(1, 0, 0, 70), UDim2.new(0, 0, 0, 0), BG)
corner(header, 18)

local logo = mkFrame(header, UDim2.fromOffset(42, 42), UDim2.new(0, 16, 0, 14), GRN)
corner(logo, 100)
drawKeyArt(logo, 42, Color3.fromRGB(255, 255, 255))
drawLockBadge(logo, 42, Color3.fromRGB(255, 255, 255), GRN)

mkLabel(header, {
	Size = UDim2.new(1, -160, 0, 20),
	Position = UDim2.new(0, 70, 0, 16),
	Text = "GreenKey 娱乐菜单",
	Font = Enum.Font.GothamBold,
	TextSize = 16,
})
mkLabel(header, {
	Size = UDim2.new(1, -160, 0, 16),
	Position = UDim2.new(0, 70, 0, 36),
	Text = "婴儿脚本 · 娱乐版",
	TextColor3 = SUB,
	TextSize = 11,
})

local closeBtn = mkBtn(header, {
	Size = UDim2.fromOffset(30, 30),
	Position = UDim2.new(1, -42, 0, 18),
	BackgroundColor3 = CARD,
	Text = "×",
	TextSize = 18,
})
corner(closeBtn, 100)
closeBtn.MouseButton1Click:Connect(function()
	if getgenv().GreenKeyStop then pcall(getgenv().GreenKeyStop) end
end)

local hLine = mkFrame(panel, UDim2.new(1, -32, 0, 1), UDim2.new(0, 16, 0, 70), LN)
hLine.BackgroundTransparency = 0.35

-- 选项卡
local tabBar = mkFrame(panel, UDim2.new(1, -32, 0, 36), UDim2.new(0, 16, 0, 80), BG)
local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 6)
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Parent = tabBar

-- 卡片滚动区
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -32, 1, -198)
scroll.Position = UDim2.new(0, 16, 0, 124)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = GRN
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ScrollingDirection = Enum.ScrollingDirection.Y
scroll.Parent = panel
local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.new(0.5, -6, 0, 84)
grid.CellPadding = UDim2.new(0, 8, 0, 8)
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = scroll

-- 底部按钮
local allOff = mkBtn(panel, {
	Size = UDim2.new(1, -32, 0, 38),
	Position = UDim2.new(0, 16, 1, -50),
	BackgroundColor3 = Color3.fromRGB(46, 34, 36),
	Text = "关闭全部效果",
	TextColor3 = Color3.fromRGB(226, 150, 150),
	TextSize = 13,
})
corner(allOff, 10)
stroke(allOff, RED, 1, 0.55)

-- 称号输入窗
local inputWin = Instance.new("Frame")
inputWin.Size = UDim2.fromOffset(300, 152)
inputWin.Position = UDim2.new(0.5, -150, 0.5, -76)
inputWin.BackgroundColor3 = Color3.fromRGB(28, 31, 35)
inputWin.BorderSizePixel = 0
inputWin.Visible = false
inputWin.ZIndex = 5
inputWin.Parent = gui
corner(inputWin, 14)
stroke(inputWin, GRN, 1, 0.3)

mkLabel(inputWin, {
	Size = UDim2.new(1, -32, 0, 20),
	Position = UDim2.new(0, 16, 0, 14),
	Text = "设置头顶称号",
	Font = Enum.Font.GothamBold,
	TextSize = 14,
})
local inbox = Instance.new("TextBox")
inbox.Size = UDim2.new(1, -32, 0, 40)
inbox.Position = UDim2.new(0, 16, 0, 42)
inbox.BackgroundColor3 = CARD
inbox.BorderSizePixel = 0
inbox.TextColor3 = TXT
inbox.Font = Enum.Font.Gotham
inbox.TextSize = 14
inbox.Text = ""
inbox.PlaceholderText = "最多 12 个字"
inbox.PlaceholderColor3 = SUB
inbox.ClearTextOnFocus = false
inbox.Parent = inputWin
corner(inbox, 9)

local iok = mkBtn(inputWin, {
	Size = UDim2.new(0.5, -22, 0, 36),
	Position = UDim2.new(0, 16, 0, 96),
	BackgroundColor3 = GRN,
	Text = "确定",
})
corner(iok, 9)
local icancel = mkBtn(inputWin, {
	Size = UDim2.new(0.5, -22, 0, 36),
	Position = UDim2.new(0.5, 6, 0, 96),
	BackgroundColor3 = CARD2,
	Text = "取消",
	TextColor3 = Color3.fromRGB(200, 206, 202),
})
corner(icancel, 9)

-- ---------- 卡片构建 ----------
local cards = {}   -- [key] = { card, knob, track, stateLbl }
local curCat = 1

local function itemLabel(key)
	for _, cat in ipairs(CATS) do
		for _, it in ipairs(cat.items) do
			if it.key == key then return it.label end
		end
	end
	return key
end

refreshCard = function(key)
	local c = cards[key]
	if not c then return end
	local fx = FX[key]
	local isOn = fx and fx.on
	c.track.BackgroundColor3 = isOn and GRN or Color3.fromRGB(58, 63, 68)
	if isOn then
		c.knob.Position = UDim2.new(1, -17, 0.5, -7)
		c.knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		c.state.Text = "已开启"
		c.state.TextColor3 = GRNL
		c.card.BackgroundColor3 = Color3.fromRGB(36, 50, 40)
		pcall(function() c.stroke.Color = GRN end)
		pcall(function() c.stroke.Transparency = 0.2 end)
	else
		c.knob.Position = UDim2.new(0, 3, 0.5, -7)
		c.knob.BackgroundColor3 = Color3.fromRGB(170, 176, 172)
		c.state.Text = "未开启"
		c.state.TextColor3 = SUB
		c.card.BackgroundColor3 = CARD
		pcall(function() c.stroke.Color = LN end)
		pcall(function() c.stroke.Transparency = 0.5 end)
	end
end

local function clearCards()
	for _, ch in ipairs(scroll:GetChildren()) do
		if ch:IsA("TextButton") or ch:IsA("Frame") then ch:Destroy() end
	end
	cards = {}
end

local function buildCat(idx)
	curCat = idx
	clearCards()
	local cat = CATS[idx]
	for i, it in ipairs(cat.items) do
		local card = mkBtn(scroll, {
			BackgroundColor3 = CARD,
			Text = "",
			LayoutOrder = i,
		})
		corner(card, 12)
		local st = stroke(card, LN, 1, 0.5)

		local ib = mkFrame(card, UDim2.fromOffset(28, 28), UDim2.new(0, 12, 0, 12), Color3.fromRGB(48, 62, 52))
		corner(ib, 9)
		mkLabel(ib, {
			Size = UDim2.fromScale(1, 1),
			Text = cat.icon,
			TextColor3 = GRNL,
			TextSize = 14,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Center,
		})

		mkLabel(card, {
			Size = UDim2.new(1, -24, 0, 18),
			Position = UDim2.new(0, 12, 0, 44),
			Text = it.label,
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})

		local state = mkLabel(card, {
			Size = UDim2.new(1, -60, 0, 14),
			Position = UDim2.new(0, 12, 0, 62),
			Text = "未开启",
			TextColor3 = SUB,
			TextSize = 11,
		})

		local track = mkFrame(card, UDim2.fromOffset(40, 20), UDim2.new(1, -52, 0, 16), Color3.fromRGB(58, 63, 68))
		corner(track, 10)
		local knob = mkFrame(track, UDim2.fromOffset(14, 14), UDim2.new(0, 3, 0.5, -7), Color3.fromRGB(170, 176, 172))
		corner(knob, 100)

		cards[it.key] = { card = card, knob = knob, track = track, state = state, stroke = st }
		refreshCard(it.key)

		on(card.MouseEnter, function() card.BackgroundColor3 = CARD2 end)
		on(card.MouseLeave, function()
			local fx = FX[it.key]
			card.BackgroundColor3 = (fx and fx.on) and Color3.fromRGB(36, 50, 40) or CARD
		end)

		card.MouseButton1Click:Connect(function()
			if it.input then
				inputWin.Visible = true
				inbox.Text = saved.titleText or ""
				return
			end
			local now = toggleFx(it.key)
			refreshCard(it.key)
			pcall(function()
				game:GetService("StarterGui"):SetCore("SendNotification", {
					Title = "GreenKey",
					Text = it.label .. (now and " 已开启" or " 已关闭"),
					Duration = 2,
				})
			end)
		end)
	end
end

-- 选项卡按钮
local tabBtns = {}
for i, cat in ipairs(CATS) do
	local b = mkBtn(tabBar, {
		Size = UDim2.new(0.25, -5, 1, 0),
		BackgroundColor3 = CARD,
		Text = cat.name,
		TextColor3 = SUB,
		TextSize = 13,
		LayoutOrder = i,
	})
	corner(b, 9)
	local sb = stroke(b, LN, 1, 0.6)
	tabBtns[i] = { btn = b, stroke = sb }
	b.MouseButton1Click:Connect(function()
		for j, t in ipairs(tabBtns) do
			local sel = (j == i)
			t.btn.BackgroundColor3 = sel and GRN or CARD
			t.btn.TextColor3 = sel and Color3.fromRGB(255, 255, 255) or SUB
			t.stroke.Transparency = sel and 1 or 0.6
			t.stroke.Color = sel and GRN or LN
		end
		buildCat(i)
	end)
end
tabBtns[1].btn.BackgroundColor3 = GRN
tabBtns[1].btn.TextColor3 = Color3.fromRGB(255, 255, 255)
tabBtns[1].stroke.Transparency = 1
buildCat(1)

allOff.MouseButton1Click:Connect(function()
	for key, _ in pairs(FX) do
		setFx(key, false)
		refreshCard(key)
	end
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = "GreenKey",
			Text = "已关闭全部效果",
			Duration = 2,
		})
	end)
end)

-- ---------- 交互 ----------
local panelOpen = false
local function setPanel(v)
	panelOpen = v
	if v then
		local cam = WS.CurrentCamera
		local vp = cam and cam.ViewportSize
		local vh = (vp and vp.Y) or 720
		uiScale.Scale = clamp(vh / 700, 0.62, 1)
	end
	panel.Visible = v
end

ball.MouseButton1Click:Connect(function()
	setPanel(not panelOpen)
end)

iok.MouseButton1Click:Connect(function()
	local txt = tostring(inbox.Text):gsub("%s+", "")
	if #txt > 0 then
		titleSetText(txt:sub(1, 24))
		setFx("title", true)
		refreshCard("title")
	end
	inputWin.Visible = false
end)
icancel.MouseButton1Click:Connect(function()
	inputWin.Visible = false
end)

-- 球拖动
local dragging, moved = false, 0
local dragStart, startPos
on(ball.InputBegan, function(inp)
	if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		moved = 0
		dragStart = inp.Position
		startPos = ball.Position
	end
end)
on(UIS.InputChanged, function(inp)
	if not dragging then return end
	if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseMovement then
		local d = inp.Position - dragStart
		moved = math.abs(d.X) + math.abs(d.Y)
		if moved > 6 then
			ball.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end
end)
on(UIS.InputEnded, function()
	dragging = false
end)

-- 面板拖标题栏
local pd, pds, psp = false, nil, nil
on(header.InputBegan, function(inp)
	if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
		pd = true
		pds = inp.Position
		psp = panel.Position
		panel.Position = psp
	end
end)
on(UIS.InputChanged, function(inp)
	if not pd then return end
	if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseMovement then
		local d = inp.Position - pds
		panel.Position = UDim2.new(psp.X.Scale, psp.X.Offset + d.X, psp.Y.Scale, psp.Y.Offset + d.Y)
	end
end)
on(UIS.InputEnded, function()
	pd = false
end)

-- 重生重放
charConn = LP.CharacterAdded:Connect(function()
	task.spawn(replayAll)
end)

pcall(function()
	game:GetService("StarterGui"):SetCore("SendNotification", {
		Title = "GreenKey",
		Text = "加载成功，点左侧绿钥匙球打开菜单",
		Duration = 5,
	})
end)

-- 退出清理
getgenv().GreenKeyStop = function()
	for key, fx in pairs(FX) do
		if fx.on then pcall(fx.stop) end
		fx.on = false
	end
	if charConn then pcall(function() charConn:Disconnect() end) charConn = nil end
	for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
	conns = {}
	pcall(function() gui:Destroy() end)
	getgenv().GreenKeyStop = nil
end
