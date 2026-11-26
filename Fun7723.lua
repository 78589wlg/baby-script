-- ============================================================
-- 7723 作弊菜单 · 娱乐版（婴儿脚本出品）
-- 风格：7723游戏盒作弊菜单（悬浮球 + 左侧分类 + 绿色主题）
-- 功能：人物 / 动作 / 视觉 / 彩蛋 四类娱乐效果
-- 用法：loadstring(game:HttpGet("https://raw.githubusercontent.com/78589wlg/baby-script/main/Fun7723.lua?v=1"))()
-- ============================================================

local P = game:GetService("Players")
local LP = P.LocalPlayer
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local WS = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

-- 防重复执行
if getgenv().Fun7723Stop then pcall(getgenv().Fun7723Stop) end

local GRN = Color3.fromRGB(76, 175, 80)      -- 7723 绿
local GRND = Color3.fromRGB(46, 125, 50)     -- 深绿
local DK = Color3.fromRGB(24, 26, 30)        -- 面板底
local DK2 = Color3.fromRGB(34, 37, 43)       -- 行底
local TXT = Color3.fromRGB(235, 240, 235)
local ON = Color3.fromRGB(102, 220, 120)
local OFF = Color3.fromRGB(120, 126, 132)

local conns = {}
local function on(sig, fn)
	local c = sig:Connect(fn)
	conns[#conns + 1] = c
	return c
end

-- ---------- 状态与效果引擎 ----------
local FX = {}          -- [key] = { on=bool, start=fn, stop=fn }
local saved = {}       -- 恢复用
local charConn = nil

local function root()
	local c = LP.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end
local function humanoid()
	local c = LP.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end

local function setFx(key, on)
	local fx = FX[key]
	if not fx then return end
	if on == fx.on then return end
	if on then
		local ok = pcall(fx.start)
		if ok then
			fx.on = true
		end
	else
		pcall(fx.stop)
		fx.on = false
	end
end

local function toggleFx(key)
	local fx = FX[key]
	if not fx then return end
	setFx(key, not fx.on)
	return fx.on
end

-- 重生后重放已开的效果
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
		pcall(function()
			p.Transparency = r.tr
		end)
	end
end

-- 疯狂旋转
local spinAtt, spinBV = nil, nil
local function spinStart()
	spinStop2()
	local r = root()
	local h = humanoid()
	if not r or not h then return end
	local a = Instance.new("Attachment")
	a.Name = "FunSpinAtt"
	a.Parent = r
	local b = Instance.new("BodyAngularVelocity")
	b.Name = "FunSpin"
	b.Attachment0 = a
	b.MaxTorque = Vector3.new(0, 1e7, 0)
	b.AngularVelocity = Vector3.new(0, 25, 0)
	b.Parent = r
	spinAtt, spinBV = a, b
end
function spinStop2()
	if spinBV then pcall(function() spinBV:Destroy() end) spinBV = nil end
	if spinAtt then pcall(function() spinAtt:Destroy() end) spinAtt = nil end
	local h = humanoid()
	if h then pcall(function() h.AutoRotate = true end) end
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

-- 慢动作（走路慢 + 重力小）
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

-- 夜幕滤镜（紫色滤镜）
local filterObj = nil
local function filterStart()
	if filterObj and filterObj.Parent then filterObj.Enabled = true return end
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "Fun7723Filter"
	cc.TintColor = Color3.fromRGB(190, 160, 255)
	cc.Saturation = 0.15
	cc.Parent = Lighting
	filterObj = cc
end
local function filterStop()
	if filterObj then filterObj.Enabled = false end
end

-- 摔不死（缓降气球）
local softBV = nil
local function softStart()
	softStop2()
	local r = root()
	if not r then return end
	local b = Instance.new("BodyVelocity")
	b.Name = "FunSoft"
	b.MaxForce = Vector3.new(0, 1e5, 0)
	b.Velocity = Vector3.new(0, -6, 0)
	b.Parent = r
	softBV = b
end
function softStop2()
	if softBV then pcall(function() softBV:Destroy() end) softBV = nil end
end

-- 头顶称号
local titleBB = nil
local function titleStart()
	titleStop2()
	local c = LP.Character
	local head = c and c:FindFirstChild("Head")
	if not head then return end
	local bb = Instance.new("BillboardGui")
	bb.Name = "Fun7723Title"
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
	t.TextColor3 = Color3.fromRGB(255, 230, 100)
	t.TextStrokeTransparency = 0.3
	t.Text = saved.titleText or "7723作弊菜单"
	t.Parent = bb
	titleBB = bb
end
function titleStop2()
	if titleBB then pcall(function() titleBB:Destroy() end) titleBB = nil end
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
local function fwStart()
	fwStop2()
	local c = LP.Character
	local head = c and c:FindFirstChild("Head")
	if not head then return end
	local e = Instance.new("ParticleEmitter")
	e.Name = "Fun7723FW"
	e.Texture = "rbxasset://textures/particles/fire_main.dds"
	e.Rate = 26
	e.Lifetime = NumberRange.new(0.7, 1.3)
	e.Speed = NumberRange.new(6, 11)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Color = ColorSequence.new(Color3.fromRGB(255, 90, 90), Color3.fromRGB(255, 220, 90))
	e.Size = NumberSequence.new(0.8, 0.1)
	e.Parent = head
	fwObj = e
end
function fwStop2()
	if fwObj then pcall(function() fwObj:Destroy() end) fwObj = nil end
end

-- 注册效果
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

-- 初始快照（彩虹/隐身恢复用）
saved.rainbow = partsSnapshot()

-- ---------- 分类定义 ----------
local CATS = {
	{ name = "人物", items = {
		{ key = "rainbow", label = "彩虹身体" },
		{ key = "big", label = "变大巨人" },
		{ key = "small", label = "变小矮人" },
		{ key = "ghost", label = "半透明隐身" },
	} },
	{ name = "动作", items = {
		{ key = "spin", label = "疯狂旋转" },
		{ key = "infjump", label = "无限跳" },
		{ key = "highjump", label = "弹簧腿高跳" },
		{ key = "slow", label = "慢动作世界" },
		{ key = "moon", label = "月球重力" },
	} },
	{ name = "视觉", items = {
		{ key = "night", label = "夜视" },
		{ key = "zoom", label = "超远视角" },
		{ key = "fov", label = "广角镜头" },
		{ key = "filter", label = "夜幕紫滤镜" },
	} },
	{ name = "彩蛋", items = {
		{ key = "title", label = "头顶称号", input = true },
		{ key = "soft", label = "摔不死气球" },
		{ key = "firework", label = "头顶烟花" },
	} },
}

-- ---------- UI ----------
local gui = Instance.new("ScreenGui")
gui.Name = "Fun7723Menu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 950
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

local function mk(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = o
	return o
end

-- 悬浮球
local ball = Instance.new("TextButton")
ball.Name = "Ball"
ball.Size = UDim2.new(0, 56, 0, 56)
ball.Position = UDim2.new(0.02, 0, 0.42, 0)
ball.BackgroundColor3 = GRN
ball.Text = "作弊"
ball.TextColor3 = Color3.fromRGB(255, 255, 255)
ball.TextSize = 18
ball.Font = Enum.Font.GothamBold
ball.AutoButtonColor = false
ball.Parent = gui
local bc = Instance.new("UICorner")
bc.CornerRadius = UDim.new(1, 0)
bc.Parent = ball
local bst = Instance.new("UIStroke")
bst.Color = Color3.fromRGB(255, 255, 255)
bst.Thickness = 1.5
bst.Transparency = 0.55
bst.Parent = ball

-- 主面板
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(0, 372, 0, 440)
panel.Position = UDim2.new(0.5, -186, 0.5, -220)
panel.BackgroundColor3 = DK
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui
local pc = Instance.new("UICorner")
pc.CornerRadius = UDim.new(0, 10)
pc.Parent = panel
local pst = Instance.new("UIStroke")
pst.Color = GRN
pst.Thickness = 1.5
pst.Transparency = 0.25
pst.Parent = panel

-- 标题栏
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 42)
header.BackgroundColor3 = GRND
header.BorderSizePixel = 0
header.Parent = panel
local hc = Instance.new("UICorner")
hc.CornerRadius = UDim.new(0, 10)
hc.Parent = header
local htitle = Instance.new("TextLabel")
htitle.Size = UDim2.new(1, -96, 1, 0)
htitle.Position = UDim2.new(0, 12, 0, 0)
htitle.BackgroundTransparency = 1
htitle.Font = Enum.Font.GothamBold
htitle.TextSize = 17
htitle.TextColor3 = Color3.fromRGB(255, 255, 255)
htitle.TextXAlignment = Enum.TextXAlignment.Left
htitle.Text = "7723 作弊菜单"
htitle.Parent = header

local miniBtn = mk("TextButton", {
	Size = UDim2.new(0, 36, 0, 30),
	Position = UDim2.new(1, -80, 0, 6),
	BackgroundColor3 = Color3.fromRGB(255, 193, 7),
	Text = "—", TextSize = 16, Font = Enum.Font.GothamBold,
	TextColor3 = Color3.fromRGB(0, 0, 0),
}, header)
local closeBtn = mk("TextButton", {
	Size = UDim2.new(0, 36, 0, 30),
	Position = UDim2.new(1, -40, 0, 6),
	BackgroundColor3 = Color3.fromRGB(229, 57, 53),
	Text = "×", TextSize = 18, Font = Enum.Font.GothamBold,
	TextColor3 = Color3.fromRGB(255, 255, 255),
}, header)

-- 左侧分类
local left = Instance.new("Frame")
left.Size = UDim2.new(0, 92, 1, -42)
left.Position = UDim2.new(0, 0, 0, 42)
left.BackgroundColor3 = DK2
left.BorderSizePixel = 0
left.Parent = panel

local right = Instance.new("ScrollingFrame")
right.Size = UDim2.new(1, -92, 1, -42)
right.Position = UDim2.new(0, 92, 0, 42)
right.BackgroundTransparency = 1
right.BorderSizePixel = 0
right.ScrollBarThickness = 4
right.ScrollBarImageColor3 = GRN
right.CanvasSize = UDim2.new(0, 0, 0, 0)
right.AutomaticCanvasSize = Enum.AutomaticSize.Y
right.Parent = panel
local rlist = Instance.new("UIListLayout")
rlist.Padding = UDim.new(0, 8)
rlist.HorizontalAlignment = Enum.HorizontalAlignment.Center
rlist.Parent = right
local rpad = Instance.new("UIPadding")
rpad.PaddingTop = UDim.new(0, 10)
rpad.PaddingBottom = UDim.new(0, 10)
rpad.PaddingLeft = UDim.new(0, 10)
rpad.PaddingRight = UDim.new(0, 10)
rpad.Parent = right

-- 标题输入小窗
local inputWin = Instance.new("Frame")
inputWin.Size = UDim2.new(0, 280, 0, 130)
inputWin.Position = UDim2.new(0.5, -140, 0.5, -65)
inputWin.BackgroundColor3 = DK
inputWin.BorderSizePixel = 0
inputWin.Visible = false
inputWin.ZIndex = 5
inputWin.Parent = gui
local ic = Instance.new("UICorner")
ic.CornerRadius = UDim.new(0, 10)
ic.Parent = inputWin
local ist = Instance.new("UIStroke")
ist.Color = GRN
ist.Thickness = 1.5
ist.Parent = inputWin
local ilbl = Instance.new("TextLabel")
ilbl.Size = UDim2.new(1, -20, 0, 30)
ilbl.Position = UDim2.new(0, 10, 0, 6)
ilbl.BackgroundTransparency = 1
ilbl.Font = Enum.Font.GothamBold
ilbl.TextSize = 15
ilbl.TextColor3 = TXT
ilbl.Text = "输入头顶称号"
ilbl.Parent = inputWin
local inbox = Instance.new("TextBox")
inbox.Size = UDim2.new(1, -20, 0, 34)
inbox.Position = UDim2.new(0, 10, 0, 40)
inbox.BackgroundColor3 = DK2
inbox.TextColor3 = TXT
inbox.Font = Enum.Font.Gotham
inbox.TextSize = 15
inbox.Text = ""
inbox.PlaceholderText = "最多 12 个字"
inbox.ClearTextOnFocus = false
inbox.Parent = inputWin
local ibc = Instance.new("UICorner")
ibc.CornerRadius = UDim.new(0, 6)
ibc.Parent = inbox
local iok = mk("TextButton", {
	Size = UDim2.new(0, 110, 0, 34),
	Position = UDim2.new(0, 20, 0, 84),
	BackgroundColor3 = GRN,
	Text = "确定", TextSize = 15, Font = Enum.Font.GothamBold,
	TextColor3 = Color3.fromRGB(255, 255, 255),
}, inputWin)
local icancel = mk("TextButton", {
	Size = UDim2.new(0, 110, 0, 34),
	Position = UDim2.new(1, -130, 0, 84),
	BackgroundColor3 = OFF,
	Text = "取消", TextSize = 15, Font = Enum.Font.GothamBold,
	TextColor3 = Color3.fromRGB(255, 255, 255),
}, inputWin)

-- ---------- 行（功能项） ----------
local rows = {}   -- [key] = btn
local function rowText(key)
	local fx = FX[key]
	local label = ""
	for _, cat in ipairs(CATS) do
		for _, it in ipairs(cat.items) do
			if it.key == key then label = it.label end
		end
	end
	if fx and fx.on then
		return label .. "   [开]"
	else
		return label .. "   [关]"
	end
end

local function refreshRow(key)
	local b = rows[key]
	if b then
		b.Text = rowText(key)
		local fx = FX[key]
		b.BackgroundColor3 = (fx and fx.on) and Color3.fromRGB(40, 66, 44) or DK2
		b.TextColor3 = (fx and fx.on) and ON or TXT
	end
end

local function buildCat(idx)
	for _, ch in ipairs(right:GetChildren()) do
		if ch:IsA("TextButton") then ch:Destroy() end
	end
	rows = {}
	local cat = CATS[idx]
	for _, it in ipairs(cat.items) do
		local b = mk("TextButton", {
			Size = UDim2.new(1, -12, 0, 40),
			BackgroundColor3 = DK2,
			Text = rowText(it.key),
			TextColor3 = TXT,
			TextSize = 15,
			Font = Enum.Font.GothamMedium,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = it.key,
		}, right)
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 10)
		pad.Parent = b
		rows[it.key] = b
		b.MouseButton1Click:Connect(function()
			if it.input then
				inputWin.Visible = true
				inbox.Text = saved.titleText or ""
				return
			end
			local now = toggleFx(it.key)
			refreshRow(it.key)
			pcall(function()
				game:GetService("StarterGui"):SetCore("SendNotification", {
					Title = "7723作弊菜单",
					Text = it.label .. (now and " 已开启" or " 已关闭"),
					Duration = 2,
				})
			end)
		end)
		refreshRow(it.key)
	end
	-- 彩蛋分类附送一键清空
	if idx == #CATS then
		local b = mk("TextButton", {
			Size = UDim2.new(1, -12, 0, 40),
			BackgroundColor3 = Color3.fromRGB(90, 40, 40),
			Text = "关闭全部效果",
			TextColor3 = Color3.fromRGB(255, 190, 190),
			TextSize = 15,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, right)
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 10)
		pad.Parent = b
		b.MouseButton1Click:Connect(function()
			for key, _ in pairs(FX) do
				setFx(key, false)
				refreshRow(key)
			end
		end)
	end
end

-- 左侧分类按钮
local catBtns = {}
for i, cat in ipairs(CATS) do
	local b = mk("TextButton", {
		Size = UDim2.new(1, -12, 0, 46),
		Position = UDim2.new(0, 6, 0, 8 + (i - 1) * 54),
		BackgroundColor3 = (i == 1) and GRND or DK2,
		Text = cat.name,
		TextColor3 = (i == 1) and Color3.fromRGB(255, 255, 255) or TXT,
		TextSize = 16,
		Font = Enum.Font.GothamBold,
	}, left)
	catBtns[i] = b
	b.MouseButton1Click:Connect(function()
		for j, cb in ipairs(catBtns) do
			cb.BackgroundColor3 = (j == i) and GRND or DK2
			cb.TextColor3 = (j == i) and Color3.fromRGB(255, 255, 255) or TXT
		end
		buildCat(i)
	end)
end
buildCat(1)

-- ---------- 交互 ----------
local panelOpen = false
local function setPanel(v)
	panelOpen = v
	panel.Visible = v
end
ball.MouseButton1Click:Connect(function()
	setPanel(not panelOpen)
end)
miniBtn.MouseButton1Click:Connect(function()
	setPanel(false)
end)
closeBtn.MouseButton1Click:Connect(function()
	-- × = 彻底关闭：清掉所有效果并退出脚本
	if getgenv().Fun7723Stop then pcall(getgenv().Fun7723Stop) end
end)

iok.MouseButton1Click:Connect(function()
	local txt = tostring(inbox.Text):gsub("%s+", "")
	if #txt > 0 then
		titleSetText(txt:sub(1, 24))
		setFx("title", true)
		refreshRow("title")
	end
	inputWin.Visible = false
end)
icancel.MouseButton1Click:Connect(function()
	inputWin.Visible = false
end)

-- 悬浮球拖动（位移小于 6 像素视为点击）
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

-- 面板也可以拖标题栏
local pd, pds, psp = false, nil, nil
on(header.InputBegan, function(inp)
	if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
		pd = true
		pds = inp.Position
		psp = panel.Position
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

-- 通知
pcall(function()
	game:GetService("StarterGui"):SetCore("SendNotification", {
		Title = "7723 作弊菜单",
		Text = "加载成功，点绿色「作弊」球打开菜单",
		Duration = 5,
	})
end)

-- 退出清理
getgenv().Fun7723Stop = function()
	for key, fx in pairs(FX) do
		if fx.on then pcall(fx.stop) end
		fx.on = false
	end
	if charConn then pcall(function() charConn:Disconnect() end) charConn = nil end
	for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
	conns = {}
	pcall(function() gui:Destroy() end)
	getgenv().Fun7723Stop = nil
end
