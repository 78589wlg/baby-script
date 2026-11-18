--[[ ============================================================
     BabyUI v1.0  —— 自制轻量 UI 库
     特性：
       · 半透明玻璃窗体（中间透，能看见游戏画面）
       · 四周彩色流光装饰（内圈彩虹描边持续旋转）
       · 可缩成一个方形玻璃按钮，点一下展开
       · 兼容 WindUI 常用 API：CreateWindow / Tab / Section
         / Button / Toggle / Slider / Input / Dropdown
         / LockAll / UnlockAll / Notify / SetTheme
     ============================================================ ]]

local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local LP = game:GetService("Players").LocalPlayer

local BabyUI = {}
BabyUI.__index = BabyUI

local FONT = Enum.Font.GothamMedium
local FONTB = Enum.Font.GothamBold

local ACCENT = Color3.fromRGB(255, 138, 66)
local TXT = Color3.fromRGB(240, 243, 252)
local SUB = Color3.fromRGB(146, 156, 178)
local WHT = Color3.fromRGB(255, 255, 255)

-- 彩虹渐变（首尾同色，旋转时无缝）
local RAINBOW = {
	ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 104, 140)),
	ColorSequenceKeypoint.new(0.20, Color3.fromRGB(255, 178, 92)),
	ColorSequenceKeypoint.new(0.40, Color3.fromRGB(122, 236, 178)),
	ColorSequenceKeypoint.new(0.60, Color3.fromRGB(100, 188, 255)),
	ColorSequenceKeypoint.new(0.80, Color3.fromRGB(168, 130, 255)),
	ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 104, 140)),
}

local function clamp(v, a, b)
	if v < a then return a end
	if v > b then return b end
	return v
end

local function inst(cls, props, parent)
	local o = Instance.new(cls)
	if props then
		for k, v in pairs(props) do
			o[k] = v
		end
	end
	if parent then
		o.Parent = parent
	end
	return o
end

local function round(o, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = o
	return c
end

local function stroke(o, col, trans, thick, mode)
	local s = Instance.new("UIStroke")
	s.Color = col or WHT
	s.Transparency = (trans == nil) and 0.8 or trans
	s.Thickness = thick or 1
	s.ApplyStrokeMode = mode or Enum.ApplyStrokeMode.Border
	s.Parent = o
	return s
end

local function gradient(o, rot)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(RAINBOW)
	g.Rotation = rot or 0
	g.Parent = o
	return g
end

local function mklabel(parent, props)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.BorderSizePixel = 0
	t.Font = FONT
	t.TextSize = 13
	t.TextColor3 = TXT
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.TextYAlignment = Enum.TextYAlignment.Center
	t.RichText = false
	if props then
		for k, v in pairs(props) do
			t[k] = v
		end
	end
	t.Parent = parent
	return t
end

local function tweenTo(obj, target, dur, style)
	TS:Create(obj, TweenInfo.new(dur or 0.18, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), target):Play()
end

local function viewport()
	local cam = workspace.CurrentCamera
	local v = cam and cam.ViewportSize or Vector2.new(1280, 720)
	if v.X < 200 or v.Y < 200 then
		v = Vector2.new(1280, 720)
	end
	return v
end

-- ============ GUI 根 ============
local gui = Instance.new("ScreenGui")
gui.Name = "BabyUI_" .. tostring(math.random(1000, 9999))
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999
local okCore = pcall(function()
	gui.Parent = game:GetService("CoreGui")
end)
if not okCore or not gui.Parent then
	pcall(function()
		gui.Parent = LP:WaitForChild("PlayerGui")
	end)
end

-- 主题色刷新表
local accentUsers = {}
local function regAccent(fn)
	table.insert(accentUsers, fn)
	fn(ACCENT)
end

-- ============ 通知 ============
local notifList = {}
local notifHolder = inst("Frame", {
	Name = "Notifs",
	Size = UDim2.new(0, 300, 1, 0),
	Position = UDim2.new(1, -12, 0, 10),
	AnchorPoint = Vector2.new(1, 0),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 60,
}, gui)

local function relayoutNotifs()
	local y = 0
	for i, it in ipairs(notifList) do
		local target = UDim2.new(1, -10, 0, y)
		tweenTo(it.card, { Position = target }, 0.22)
		y = y + it.h + 8
	end
end

local function countLines(s)
	local n = 0
	s = s .. "\n"
	for seg in string.gmatch(s, "([^\n]*)\n") do
		local len = 0
		for _ in string.gmatch(seg, ".") do len = len + 1 end
		n = n + math.max(1, math.ceil(len / 19))
	end
	if n < 1 then n = 1 end
	return n
end

function BabyUI:Notify(o)
	if not gui or not gui.Parent then return end
	o = o or {}
	local title = tostring(o.Title or "提示")
	local content = tostring(o.Content or "")
	local dur = tonumber(o.Duration) or 4
	local lines = countLines(content)
	local h = 26 + lines * 16

	local card = inst("Frame", {
		Size = UDim2.new(1, 0, 0, h),
		Position = UDim2.new(1, 320, 0, 0),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = Color3.fromRGB(16, 19, 30),
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		ZIndex = 61,
	}, notifHolder)
	round(card, 10)
	local cs = stroke(card, WHT, 0.82, 1)
	gradient(cs, 0)

	local bar = inst("Frame", {
		Size = UDim2.new(0, 3, 1, -14),
		Position = UDim2.new(0, 0, 0, 7),
		BackgroundColor3 = WHT,
		BorderSizePixel = 0,
		ZIndex = 62,
	}, card)
	round(bar, 2)

	mklabel(card, {
		Size = UDim2.new(1, -20, 0, 18),
		Position = UDim2.new(0, 12, 0, 7),
		Text = title,
		Font = FONTB,
		TextSize = 13,
		TextColor3 = WHT,
		ZIndex = 62,
	})
	mklabel(card, {
		Size = UDim2.new(1, -20, 0, h - 28),
		Position = UDim2.new(0, 12, 0, 24),
		Text = content,
		TextSize = 12,
		TextColor3 = SUB,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 62,
	})

	table.insert(notifList, 1, { card = card, h = h })
	relayoutNotifs()

	task.delay(math.max(1.2, dur), function()
		for i, it in ipairs(notifList) do
			if it.card == card then
				table.remove(notifList, i)
				break
			end
		end
		tweenTo(card, { Position = UDim2.new(1, 320, 0, card.Position.Y.Offset) }, 0.2)
		task.delay(0.24, function()
			if card then card:Destroy() end
		end)
		relayoutNotifs()
	end)
end

-- ============ 主题 ============
local THEMES = {
	["落日"] = { 255, 138, 66 },
	["极光"] = { 79, 227, 193 },
	["深海"] = { 74, 158, 255 },
	["樱花"] = { 255, 127, 168 },
	["森林"] = { 111, 208, 140 },
	["紫夜"] = { 169, 139, 255 },
	["熔岩"] = { 255, 90, 90 },
	["月白"] = { 216, 224, 240 },
}

function BabyUI:SetTheme(name)
	local c = THEMES[tostring(name)]
	if not c then return end
	ACCENT = Color3.fromRGB(c[1], c[2], c[3])
	for _, fn in ipairs(accentUsers) do
		pcall(fn, ACCENT)
	end
end

-- ============ 窗口 ============
local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

function BabyUI:CreateWindow(opt)
	opt = opt or {}
	local vp = viewport()
	local W = clamp(math.floor(vp.X - 40), 300, 620)
	local H = clamp(math.floor(vp.Y - 70), 320, 520)

	local shell = inst("Frame", {
		Name = "Shell",
		Size = UDim2.fromOffset(W + 24, H + 24),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, gui)

	-- 窗体（半透明，能看见游戏）
	local root = inst("Frame", {
		Name = "Main",
		Size = UDim2.fromOffset(W, H),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(14, 17, 27),
		BackgroundTransparency = 0.34,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 2,
	}, shell)
	round(root, 18)
	local rs1 = stroke(root, WHT, 0.45, 1.5)
	local rg1 = gradient(rs1, 0)

	-- ===== 标题栏 =====
	local titleBar = inst("Frame", {
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, root)

	local logoBar = inst("Frame", {
		Size = UDim2.new(0, 3, 0, 18),
		Position = UDim2.new(0, 16, 0.5, -9),
		BackgroundColor3 = WHT,
		BorderSizePixel = 0,
		ZIndex = 4,
	}, titleBar)
	round(logoBar, 2)

	mklabel(titleBar, {
		Size = UDim2.new(1, -150, 1, 0),
		Position = UDim2.new(0, 28, 0, 0),
		Text = tostring(opt.Title or "脚本"),
		Font = FONTB,
		TextSize = 15,
		TextColor3 = WHT,
		ZIndex = 4,
	})

	local function miniBtn(txtHint, rightOffset)
		local b = inst("TextButton", {
			Size = UDim2.new(0, 26, 0, 26),
			Position = UDim2.new(1, rightOffset, 0.5, -13),
			BackgroundColor3 = WHT,
			BackgroundTransparency = 0.93,
			Text = txtHint,
			Font = FONTB,
			TextSize = 15,
			TextColor3 = SUB,
			AutoButtonColor = false,
			BorderSizePixel = 0,
			ZIndex = 4,
		}, titleBar)
		round(b, 8)
		b.MouseEnter:Connect(function()
			tweenTo(b, { BackgroundTransparency = 0.86, TextColor3 = WHT }, 0.14)
		end)
		b.MouseLeave:Connect(function()
			tweenTo(b, { BackgroundTransparency = 0.93, TextColor3 = SUB }, 0.14)
		end)
		return b
	end

	local btnMin = miniBtn("−", -76)
	local btnClose = miniBtn("×", -44)

	-- 标题栏下方的彩线
	local divLine = inst("Frame", {
		Size = UDim2.new(1, -32, 0, 1),
		Position = UDim2.new(0, 16, 0, 45),
		BackgroundColor3 = WHT,
		BackgroundTransparency = 0.72,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, root)

	-- ===== 页签栏 =====
	local tabW = clamp(math.floor(W * 0.28), 92, 140)
	local tabBar = inst("ScrollingFrame", {
		Size = UDim2.new(0, tabW, 1, -58),
		Position = UDim2.new(0, 12, 0, 58),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = SUB,
		ScrollBarImageTransparency = 0.6,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ZIndex = 3,
	}, root)
	local tabLayout = Instance.new("UIListLayout")
	tabLayout.Padding = UDim.new(0, 5)
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabLayout.Parent = tabBar

	-- ===== 内容区 =====
	local content = inst("Frame", {
		Size = UDim2.new(1, -(tabW + 20), 1, -58),
		Position = UDim2.new(0, tabW + 16, 0, 58),
		BackgroundColor3 = WHT,
		BackgroundTransparency = 0.955,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, root)
	round(content, 12)

	local win = setmetatable({}, Window)
	win.Gui = gui
	win.Root = root
	win.Shell = shell
	win.Tabs = {}
	win.Current = nil
	win.Content = content

	-- ===== 拖动 / 收起 =====
	local dragging = false
	local dragStart = nil

	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = { pos = input.Position, origin = shell.Position }
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local d = input.Position - dragStart.pos
		shell.Position = UDim2.new(
			dragStart.origin.X.Scale, dragStart.origin.X.Offset + d.X,
			dragStart.origin.Y.Scale, dragStart.origin.Y.Offset + d.Y
		)
	end)

	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	-- ===== 收起按钮（方形玻璃砖：投影 + 彩色描边 + 内圈细边 + 顶部高光）=====
	local bShadow = inst("Frame", {
		Name = "BallShadow",
		Size = UDim2.fromOffset(58, 58),
		Position = UDim2.new(1, -72, 0, 264),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.66,
		BorderSizePixel = 0,
		ZIndex = 48,
	}, gui)
	round(bShadow, 18)

	local ball = inst("TextButton", {
		Name = "Ball",
		Size = UDim2.fromOffset(54, 54),
		Position = UDim2.new(1, -70, 0, 262),
		BackgroundColor3 = Color3.fromRGB(17, 21, 33),
		BackgroundTransparency = 0.66,
		Text = "",
		AutoButtonColor = false,
		BorderSizePixel = 0,
		ZIndex = 50,
	}, gui)
	round(ball, 15)

	-- 暗玻璃底：极淡的斜向冷暖过渡，有质感但不抢眼
	local bgrad = Instance.new("UIGradient")
	bgrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 34, 52)),
		ColorSequenceKeypoint.new(0.52, Color3.fromRGB(17, 21, 33)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(33, 26, 46)),
	})
	bgrad.Rotation = 135
	bgrad.Parent = ball

	-- 外圈：缓慢旋转的彩色细边
	local bstroke = stroke(ball, WHT, 0.10, 2)
	local bstrokeGrad = gradient(bstroke, 0)

	-- 内圈：1px 细白边，双层边让边缘更利落
	local bInner = inst("Frame", {
		Size = UDim2.new(1, -7, 1, -7),
		Position = UDim2.new(0, 3.5, 0, 3.5),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 51,
	}, ball)
	round(bInner, 12)
	local bInnerStroke = stroke(bInner, WHT, 0.86, 1)

	-- 顶部高光条：玻璃反光
	local bGloss = inst("Frame", {
		Size = UDim2.new(1, -18, 0, 1),
		Position = UDim2.new(0, 9, 0, 6),
		BackgroundColor3 = WHT,
		BackgroundTransparency = 0.52,
		BorderSizePixel = 0,
		ZIndex = 52,
	}, ball)
	round(bGloss, 1)

	mklabel(ball, {
		Size = UDim2.new(1, 0, 1, 0),
		Text = "婴",
		Font = FONTB,
		TextSize = 21,
		TextColor3 = WHT,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 53,
	})

	-- 悬停/按下的一点反馈
	ball.MouseEnter:Connect(function()
		tweenTo(ball, { BackgroundTransparency = 0.46 }, 0.14)
	end)
	ball.MouseLeave:Connect(function()
		tweenTo(ball, { BackgroundTransparency = 0.66 }, 0.14)
	end)

	local dead = false
	local renderConn = nil
	local ballDrag = false
	local ballMoved = false
	local ballStart = nil
	local ballOrigin = nil

	ball.InputBegan:Connect(function(input)
		if dead then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			ballDrag = true
			ballMoved = false
			ballStart = input.Position
			ballOrigin = ball.Position
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if dead or not ballDrag then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local d = input.Position - ballStart
		if math.abs(d.X) + math.abs(d.Y) > 6 then
			ballMoved = true
		end
		ball.Position = UDim2.new(
			ballOrigin.X.Scale, ballOrigin.X.Offset + d.X,
			ballOrigin.Y.Scale, ballOrigin.Y.Offset + d.Y
		)
		bShadow.Position = UDim2.new(0, ball.Position.X.Offset - 2, 0, ball.Position.Y.Offset + 2)
	end)
	UIS.InputEnded:Connect(function(input)
		if dead or not ballDrag then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if not ballMoved and input.Position then
				-- 点一下：展开 / 收起
				local vis = not shell.Visible
				shell.Visible = vis
				ball.Text = ""
				if vis then
					shell.Size = UDim2.fromOffset(W + 24, H + 24)
				end
			end
			ballDrag = false
		end
	end)

	btnMin.Activated:Connect(function()
		shell.Visible = false
		BabyUI:Notify({ Title = "已收起", Content = "点屏幕上的方形按钮可以再打开", Duration = 2 })
	end)
	btnClose.Activated:Connect(function()
		-- 关闭 = 退出脚本：停掉渲染循环，整块界面移除
		dead = true
		if renderConn then pcall(function() renderConn:Disconnect() end) end
		pcall(function() ball:Destroy() end)
		pcall(function() bShadow:Destroy() end)
		pcall(function() gui:Destroy() end)
	end)

	-- 流光动画：渐变旋转 + 轻微呼吸
	local t = 0
	local brot = 0
	renderConn = RS.RenderStepped:Connect(function(dt)
		t = t + dt
		local rot = (t * 26) % 360
		rg1.Rotation = rot * 0.8
		rs1.Transparency = 0.34 + math.sin(t * 1.8) * 0.06
		brot = (brot + dt * 30) % 360
		if bstrokeGrad then bstrokeGrad.Rotation = brot end
		if bgrad then bgrad.Rotation = 135 + math.sin(t * 0.6) * 18 end
	end)

	-- ===== Tab 方法 =====
	local order = 0
	function win:Tab(o)
		o = o or {}
		order = order + 1

		local btn = inst("TextButton", {
			Size = UDim2.new(1, -6, 0, 34),
			BackgroundColor3 = WHT,
			BackgroundTransparency = 0.955,
			Text = "",
			AutoButtonColor = false,
			BorderSizePixel = 0,
			LayoutOrder = order,
			ZIndex = 4,
		}, tabBar)
		round(btn, 9)

		local accBar = inst("Frame", {
			Size = UDim2.new(0, 3, 0, 16),
			Position = UDim2.new(0, 0, 0.5, -8),
			BackgroundColor3 = WHT,
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = 5,
		}, btn)
		round(accBar, 2)

		local lbl = mklabel(btn, {
			Size = UDim2.new(1, -16, 1, 0),
			Position = UDim2.new(0, 11, 0, 0),
			Text = tostring(o.Title or "页"),
			TextSize = 13,
			TextColor3 = SUB,
			ZIndex = 5,
		})

		local page = inst("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = ACCENT,
			ScrollBarImageTransparency = 0.45,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			Visible = false,
			ZIndex = 4,
		}, content)
		local pp = Instance.new("UIPadding")
		pp.PaddingLeft = UDim.new(0, 9)
		pp.PaddingRight = UDim.new(0, 6)
		pp.PaddingTop = UDim.new(0, 8)
		pp.PaddingBottom = UDim.new(0, 14)
		pp.Parent = page
		local pl = Instance.new("UIListLayout")
		pl.Padding = UDim.new(0, 7)
		pl.SortOrder = Enum.SortOrder.LayoutOrder
		pl.Parent = page

		-- 锁定遮罩
		local mask = inst("TextButton", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.fromRGB(10, 12, 20),
			BackgroundTransparency = 0.28,
			Text = "",
			AutoButtonColor = false,
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = 20,
		}, content)
		round(mask, 12)
		mklabel(mask, {
			Size = UDim2.new(1, -20, 0, 40),
			Position = UDim2.new(0, 10, 0.5, -30),
			Text = "已锁定",
			Font = FONTB,
			TextSize = 17,
			TextColor3 = WHT,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 21,
		})
		mklabel(mask, {
			Size = UDim2.new(1, -20, 0, 40),
			Position = UDim2.new(0, 10, 0.5, 8),
			Text = "请先在「卡密验证」页输入卡密",
			TextSize = 12,
			TextColor3 = SUB,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 21,
		})

		local tab = setmetatable({}, Tab)
		tab.Page = page
		tab.TabButton = btn
		tab.Mask = mask
		tab.Locked = false
		tab.Order = order
		tab.Win = win
		tab._accBar = accBar
		tab._lbl = lbl

		table.insert(win.Tabs, tab)

		btn.Activated:Connect(function()
			win:Select(tab)
		end)

		if o.Locked then
			tab:LockAll()
		end
		if order == 1 then
			win:Select(tab)
		end
		return tab
	end

	function win:Select(tab)
		if win.Current == tab then return end
		for _, t in ipairs(win.Tabs) do
			if t == tab then
				t.Page.Visible = true
				t._accBar.Visible = true
				t.TabButton.BackgroundColor3 = ACCENT
				tweenTo(t.TabButton, { BackgroundTransparency = 0.84 }, 0.16)
				tweenTo(t._lbl, { TextColor3 = WHT }, 0.16)
				if t.Locked then
					t.Mask.Visible = true
				end
			else
				t.Page.Visible = false
				t._accBar.Visible = false
				t.TabButton.BackgroundColor3 = WHT
				tweenTo(t.TabButton, { BackgroundTransparency = 0.955 }, 0.16)
				tweenTo(t._lbl, { TextColor3 = SUB }, 0.16)
				t.Mask.Visible = false
			end
		end
		win.Current = tab
	end

	-- 主题色跟随
	regAccent(function(c)
		for _, t in ipairs(win.Tabs) do
			if win.Current == t then
				t.TabButton.BackgroundColor3 = c
			end
			t.Page.ScrollBarImageColor3 = c
		end
	end)

	win.Minimize = function()
		shell.Visible = false
	end
	win.Restore = function()
		shell.Visible = true
	end

	return win
end

-- ============ Tab 上的控件 ============
local ord = 0
local function nextOrder()
	ord = ord + 1
	return ord
end

-- 通用卡片底
local function card(tab, h)
	local c = inst("Frame", {
		Size = UDim2.new(1, -4, 0, h),
		BackgroundColor3 = WHT,
		BackgroundTransparency = 0.945,
		BorderSizePixel = 0,
		LayoutOrder = nextOrder(),
		ZIndex = 5,
	}, tab.Page)
	round(c, 10)
	return c
end

function Tab:LockAll()
	self.Locked = true
	self.Mask.Visible = true
	self.Mask.ZIndex = 20
end

function Tab:UnlockAll()
	self.Locked = false
	self.Mask.Visible = false
end

-- ---- 分组标题 ----
function Tab:Section(o)
	o = o or {}
	local f = inst("Frame", {
		Size = UDim2.new(1, -4, 0, 24),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = nextOrder(),
		ZIndex = 5,
	}, self.Page)
	local bar = inst("Frame", {
		Size = UDim2.new(0, 3, 0, 12),
		Position = UDim2.new(0, 2, 0.5, -6),
		BackgroundColor3 = WHT,
		BorderSizePixel = 0,
		ZIndex = 6,
	}, f)
	round(bar, 2)
	mklabel(f, {
		Size = UDim2.new(1, -14, 1, 0),
		Position = UDim2.new(0, 12, 0, 0),
		Text = tostring(o.Title or ""),
		Font = FONTB,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(210, 200, 195),
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 6,
	})
	return f
end

-- ---- 按钮 ----
function Tab:Button(o)
	o = o or {}
	local b = inst("TextButton", {
		Size = UDim2.new(1, -4, 0, 38),
		BackgroundColor3 = WHT,
		BackgroundTransparency = 0.935,
		Text = "",
		AutoButtonColor = false,
		BorderSizePixel = 0,
		LayoutOrder = nextOrder(),
		ZIndex = 5,
	}, self.Page)
	round(b, 10)
	local bs = stroke(b, WHT, 0.9, 1)

	mklabel(b, {
		Size = UDim2.new(1, -20, 1, 0),
		Position = UDim2.new(0, 12, 0, 0),
		Text = tostring(o.Title or ""),
		TextSize = 13,
		TextColor3 = TXT,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 6,
	})

	b.MouseEnter:Connect(function()
		tweenTo(b, { BackgroundTransparency = 0.87 }, 0.14)
		bs.Transparency = 0.72
	end)
	b.MouseLeave:Connect(function()
		tweenTo(b, { BackgroundTransparency = 0.935 }, 0.14)
		bs.Transparency = 0.9
	end)
	b.Activated:Connect(function()
		tweenTo(b, { BackgroundTransparency = 0.8 }, 0.08)
		task.delay(0.09, function()
			tweenTo(b, { BackgroundTransparency = 0.87 }, 0.12)
		end)
		if o.Callback then
			task.spawn(o.Callback)
		end
	end)
	return b
end

-- ---- 开关 ----
function Tab:Toggle(o)
	o = o or {}
	local row = card(self, 40)
	local state = o.Value and true or false

	mklabel(row, {
		Size = UDim2.new(1, -76, 1, 0),
		Position = UDim2.new(0, 12, 0, 0),
		Text = tostring(o.Title or ""),
		TextSize = 13,
		TextColor3 = TXT,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 6,
	})

	local track = inst("Frame", {
		Size = UDim2.fromOffset(42, 22),
		Position = UDim2.new(1, -54, 0.5, -11),
		BackgroundColor3 = Color3.fromRGB(60, 66, 82),
		BorderSizePixel = 0,
		ZIndex = 6,
	}, row)
	round(track, 11)

	local knob = inst("Frame", {
		Size = UDim2.fromOffset(16, 16),
		Position = UDim2.new(0, 3, 0.5, -8),
		BackgroundColor3 = WHT,
		BorderSizePixel = 0,
		ZIndex = 7,
	}, track)
	round(knob, 8)

	local hit = inst("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 8,
	}, row)

	local obj = { Value = state }

	local function render(animated)
		if state then
			track.BackgroundColor3 = ACCENT
			if animated then
				tweenTo(knob, { Position = UDim2.new(1, -19, 0.5, -8) }, 0.16)
			else
				knob.Position = UDim2.new(1, -19, 0.5, -8)
			end
		else
			track.BackgroundColor3 = Color3.fromRGB(60, 66, 82)
			if animated then
				tweenTo(knob, { Position = UDim2.new(0, 3, 0.5, -8) }, 0.16)
			else
				knob.Position = UDim2.new(0, 3, 0.5, -8)
			end
		end
	end

	local function setState(v)
		v = v and true or false
		if v == state then return end
		state = v
		obj.Value = v
		render(true)
		if o.Callback then
			task.spawn(o.Callback, v)
		end
	end

	-- 同时支持 obj:Set(v) 和 obj.Set(v)
	obj.Set = function(a, b)
		if type(a) == "table" then
			setState(b)
		else
			setState(a)
		end
	end

	obj.Get = function()
		return state
	end

	hit.Activated:Connect(function()
		setState(not state)
	end)

	render(false)

	regAccent(function(c)
		if state then track.BackgroundColor3 = c end
	end)

	return obj
end

-- ---- 滑条 ----
function Tab:Slider(o)
	o = o or {}
	local cfg = o.Value or {}
	local minV = tonumber(cfg.Min) or 0
	local maxV = tonumber(cfg.Max) or 100
	local cur = tonumber(cfg.Default) or minV

	local box = card(self, 54)

	mklabel(box, {
		Size = UDim2.new(1, -60, 0, 18),
		Position = UDim2.new(0, 12, 0, 5),
		Text = tostring(o.Title or ""),
		TextSize = 13,
		TextColor3 = TXT,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 6,
	})
	local valLbl = mklabel(box, {
		Size = UDim2.new(0, 48, 0, 18),
		Position = UDim2.new(1, -58, 0, 5),
		Text = tostring(cur),
		Font = FONTB,
		TextSize = 13,
		TextColor3 = ACCENT,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 6,
	})

	local track = inst("Frame", {
		Size = UDim2.new(1, -24, 0, 6),
		Position = UDim2.new(0, 12, 0, 34),
		BackgroundColor3 = Color3.fromRGB(58, 64, 80),
		BorderSizePixel = 0,
		ZIndex = 6,
	}, box)
	round(track, 3)

	local fill = inst("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = WHT,
		BorderSizePixel = 0,
		ZIndex = 7,
	}, track)
	round(fill, 3)
	gradient(fill, 0)

	local knob = inst("Frame", {
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.new(0, -7, 0.5, -7),
		BackgroundColor3 = WHT,
		BorderSizePixel = 0,
		ZIndex = 8,
	}, track)
	round(knob, 8)
	local ks = stroke(knob, ACCENT, 0.2, 2)

	local hit = inst("TextButton", {
		Size = UDim2.new(1, 0, 1, 12),
		Position = UDim2.new(0, 0, 0.5, -6),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 9,
	}, track)

	local obj = { Value = cur }

	local function apply(v, fire)
		v = clamp(v, minV, maxV)
		local pct = 0
		if maxV > minV then
			pct = (v - minV) / (maxV - minV)
		end
		fill.Size = UDim2.new(pct, 0, 1, 0)
		knob.Position = UDim2.new(pct, -7, 0.5, -7)
		valLbl.Text = tostring(math.floor(v + 0.5))
		cur = v
		obj.Value = v
		if fire and o.Callback then
			task.spawn(o.Callback, math.floor(v + 0.5))
		end
	end

	apply(cur, false)

	local dragging = false
	local function fromX(x)
		local abs = track.AbsolutePosition.X
		local w = track.AbsoluteSize.X
		if w <= 0 then return end
		local pct = clamp((x - abs) / w, 0, 1)
		apply(minV + (maxV - minV) * pct, true)
	end

	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			fromX(input.Position.X)
		end
	end)

	local conn
	conn = UIS.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
		fromX(input.Position.X)
	end)

	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	obj.Set = function(a, b)
		local v = a
		if type(a) == "table" then v = b end
		apply(tonumber(v) or cur, true)
	end

	regAccent(function(c)
		ks.Color = c
		valLbl.TextColor3 = c
	end)

	return obj
end

-- ---- 输入框 ----
function Tab:Input(o)
	o = o or {}
	local box = card(self, 60)

	mklabel(box, {
		Size = UDim2.new(1, -20, 0, 16),
		Position = UDim2.new(0, 12, 0, 4),
		Text = tostring(o.Title or ""),
		TextSize = 12,
		TextColor3 = SUB,
		ZIndex = 6,
	})

	local tb = inst("TextBox", {
		Size = UDim2.new(1, -24, 0, 30),
		Position = UDim2.new(0, 12, 0, 22),
		BackgroundColor3 = Color3.fromRGB(24, 28, 40),
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		Text = tostring(o.Value or ""),
		PlaceholderText = tostring(o.Placeholder or ""),
		PlaceholderColor3 = Color3.fromRGB(108, 116, 136),
		Font = FONT,
		TextSize = 12.5,
		TextColor3 = TXT,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		ZIndex = 6,
	}, box)
	round(tb, 8)
	local tbs = stroke(tb, WHT, 0.88, 1)
	local tp = Instance.new("UIPadding")
	tp.PaddingLeft = UDim.new(0, 8)
	tp.PaddingRight = UDim.new(0, 8)
	tp.Parent = tb

	tb.Focused:Connect(function()
		tbs.Color = ACCENT
		tbs.Transparency = 0.3
	end)
	tb.FocusLost:Connect(function()
		tbs.Color = WHT
		tbs.Transparency = 0.88
		if o.Callback then
			task.spawn(o.Callback, tb.Text)
		end
	end)

	local obj = { TextBox = tb }
	obj.Set = function(a, b)
		local v = a
		if type(a) == "table" then v = b end
		tb.Text = tostring(v or "")
	end
	obj.Get = function()
		return tb.Text
	end

	regAccent(function(c)
		if tb:IsFocused() then tbs.Color = c end
	end)

	return obj
end

-- ---- 下拉 ----
function Tab:Dropdown(o)
	o = o or {}
	local box = card(self, 60)

	mklabel(box, {
		Size = UDim2.new(1, -20, 0, 16),
		Position = UDim2.new(0, 12, 0, 4),
		Text = tostring(o.Title or ""),
		TextSize = 12,
		TextColor3 = SUB,
		ZIndex = 6,
	})

	local btn = inst("TextButton", {
		Size = UDim2.new(1, -24, 0, 30),
		Position = UDim2.new(0, 12, 0, 22),
		BackgroundColor3 = Color3.fromRGB(24, 28, 40),
		BackgroundTransparency = 0.25,
		Text = "",
		AutoButtonColor = false,
		BorderSizePixel = 0,
		ZIndex = 6,
	}, box)
	round(btn, 8)
	stroke(btn, WHT, 0.88, 1)

	local cur = tostring(o.Value or "")
	local nameLbl = mklabel(btn, {
		Size = UDim2.new(1, -26, 1, 0),
		Position = UDim2.new(0, 8, 0, 0),
		Text = cur,
		TextSize = 12.5,
		TextColor3 = TXT,
		ZIndex = 7,
	})
	mklabel(btn, {
		Size = UDim2.new(0, 16, 1, 0),
		Position = UDim2.new(1, -20, 0, 0),
		Text = "▾",
		TextSize = 12,
		TextColor3 = SUB,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 7,
	})

	local listFrame = nil
	local backdrop = nil

	local function closeList()
		if backdrop then backdrop:Destroy() backdrop = nil end
		if listFrame then listFrame:Destroy() listFrame = nil end
	end

	local function buildList()
		local vals = o.Values or {}
		local abs = btn.AbsolutePosition
		local bh = btn.AbsoluteSize.Y
		local vp = viewport()
		local itemH = 30
		local h = math.min(#vals * itemH + 8, 210)
		local y = abs.Y + bh + 4
		if y + h > vp.Y - 10 then
			y = abs.Y - h - 4
		end

		backdrop = inst("TextButton", {
			Size = UDim2.fromOffset(vp.X, vp.Y),
			Position = UDim2.fromOffset(0, 0),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 70,
		}, gui)
		backdrop.Activated:Connect(closeList)

		listFrame = inst("Frame", {
			Size = UDim2.fromOffset(btn.AbsoluteSize.X, h),
			Position = UDim2.fromOffset(abs.X, y),
			BackgroundColor3 = Color3.fromRGB(18, 21, 32),
			BackgroundTransparency = 0.04,
			BorderSizePixel = 0,
			ZIndex = 72,
		}, gui)
		round(listFrame, 9)
		stroke(listFrame, WHT, 0.8, 1)

		local sf = inst("ScrollingFrame", {
			Size = UDim2.new(1, -8, 1, -8),
			Position = UDim2.new(0, 4, 0, 4),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 2,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ZIndex = 73,
		}, listFrame)
		local l = Instance.new("UIListLayout")
		l.Padding = UDim.new(0, 2)
		l.Parent = sf

		for _, v in ipairs(vals) do
			local name = tostring(v)
			local item = inst("TextButton", {
				Size = UDim2.new(1, -4, 0, itemH - 2),
				BackgroundColor3 = WHT,
				BackgroundTransparency = 0.96,
				Text = name,
				Font = FONT,
				TextSize = 12.5,
				TextColor3 = TXT,
				TextXAlignment = Enum.TextXAlignment.Left,
				AutoButtonColor = false,
				BorderSizePixel = 0,
				ZIndex = 74,
			}, sf)
			round(item, 7)
			local ip = Instance.new("UIPadding")
			ip.PaddingLeft = UDim.new(0, 8)
			ip.Parent = item

			item.MouseEnter:Connect(function()
				tweenTo(item, { BackgroundTransparency = 0.86 }, 0.12)
			end)
			item.MouseLeave:Connect(function()
				tweenTo(item, { BackgroundTransparency = 0.96 }, 0.12)
			end)
			item.Activated:Connect(function()
				cur = name
				nameLbl.Text = name
				closeList()
				if o.Callback then
					task.spawn(o.Callback, name)
				end
			end)
		end
	end

	btn.Activated:Connect(function()
		if listFrame then
			closeList()
		else
			buildList()
		end
	end)

	local obj = { Button = btn }
	obj.Set = function(a, b)
		local v = a
		if type(a) == "table" then v = b end
		cur = tostring(v or "")
		nameLbl.Text = cur
	end
	obj.Get = function()
		return cur
	end

	return obj
end

return BabyUI
