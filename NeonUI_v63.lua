-- 自制 UI（半透明玻璃窗 + 彩色流光 + 可收成方形按钮）
-- 三重保障：主源 → 镜像 → 内嵌源码（内嵌一定成功，不会再退回旧界面）
local OLDKEY="BabyOldUI.txt"
local function oldUIFlag()
local v=false
pcall(function()
if type(getgenv)=="function" then
local g=getgenv()
if g and g.babyOldUI then v=true end
end
end)
if v then return true end
pcall(function()
if type(isfile)=="function" and isfile(OLDKEY) and type(readfile)=="function" then
local t=tostring(readfile(OLDKEY)):gsub("%s","")
if t=="1" then v=true end
end
end)
return v
end
local function setOldUIFlag(on)
pcall(function()
if type(getgenv)=="function" then
local g=getgenv()
if g then
if on then g.babyOldUI=true else g.babyOldUI=nil end
end
end
end)
pcall(function()
if type(writefile)=="function" then
if on then writefile(OLDKEY,"1") else writefile(OLDKEY,"0") end
end
end)
end
local WindUI
local UI_SRC="内嵌版"
local USE_OLD=oldUIFlag()
do
local function tryLoad(url)
local ok,r=pcall(function()
return loadstring(game:HttpGet(url))()
end)
if ok and type(r)=="table" and r.CreateWindow then return r end
return nil
end
if USE_OLD then
local W=tryLoad("https://cdn.jsdelivr.net/gh/Footagesus/WindUI@main/dist/main.lua")
if not W then W=tryLoad("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua") end
if W then
WindUI=W
UI_SRC="以前的界面"
else
USE_OLD=false
end
end
local B=nil
if not WindUI then
B=tryLoad("https://raw.githubusercontent.com/78589wlg/baby-script/main/BabyUI.lua?v=7")
if B then UI_SRC="远程主源" end
end
if not B and not WindUI then
B=tryLoad("https://cdn.jsdelivr.net/gh/78589wlg/baby-script@main/BabyUI.lua")
if B then UI_SRC="镜像源" end
end
if not B and not WindUI then
local EMBED=[====[--[[ ============================================================
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
	local function hardQuit()
		-- 关闭 = 退出脚本：先让脚本清掉自己开的效果，再停渲染、移除界面
		dead = true
		if type(BabyUI.OnQuit) == "function" then
			pcall(BabyUI.OnQuit)
		end
		if renderConn then pcall(function() renderConn:Disconnect() end) end
		pcall(function() ball:Destroy() end)
		pcall(function() bShadow:Destroy() end)
		pcall(function() gui:Destroy() end)
	end

	-- 退出前确认框：左边「点错了」/ 右边「退出」
	local asking = false
	local function askQuit()
		if asking or dead then return end
		asking = true

		local pg = inst("ScreenGui", {
			Name = "BabyUI_ExitAsk",
			ResetOnSpawn = false,
			IgnoreGuiInset = true,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			DisplayOrder = 20000,
		})
		local okp = pcall(function() pg.Parent = game:GetService("CoreGui") end)
		if not okp or not pg.Parent then
			pcall(function() pg.Parent = LP:WaitForChild("PlayerGui") end)
		end

		inst("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.44,
			BorderSizePixel = 0,
			ZIndex = 1,
		}, pg)

		local vp = viewport()
		local bw = math.floor(math.min(320, math.max(262, vp.X - 70)))
		local bh = 156

		local box = inst("Frame", {
			Size = UDim2.fromOffset(bw, bh),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(18, 21, 30),
			BackgroundTransparency = 0.05,
			BorderSizePixel = 0,
			ZIndex = 3,
		}, pg)
		round(box, 14)
		gradient(stroke(box, WHT, 0.5, 1.2), 0)

		local bar = inst("Frame", {
			Size = UDim2.new(0, 3, 0, 15),
			Position = UDim2.new(0, 16, 0, 18),
			BackgroundColor3 = WHT,
			BorderSizePixel = 0,
			ZIndex = 4,
		}, box)
		round(bar, 2)

		mklabel(box, {
			Size = UDim2.new(1, -34, 0, 20),
			Position = UDim2.new(0, 26, 0, 16),
			Text = "是否关闭脚本？",
			Font = FONTB,
			TextSize = 15,
			TextColor3 = WHT,
			ZIndex = 4,
		})
		mklabel(box, {
			Size = UDim2.new(1, -34, 0, 34),
			Position = UDim2.new(0, 26, 0, 40),
			Text = "退出后界面和功能都会停止，要重新执行脚本才能再打开。",
			TextSize = 12,
			TextColor3 = SUB,
			TextWrapped = true,
			TextYAlignment = Enum.TextYAlignment.Top,
			ZIndex = 4,
		})

		local bwid = math.floor((bw - 44) / 2)
		local function mkBtn(text, offX, anchorX, trans, tcol)
			local b = inst("TextButton", {
				Size = UDim2.fromOffset(bwid, 38),
				Position = UDim2.new(0, offX, 1, -50),
				AnchorPoint = Vector2.new(anchorX, 0),
				BackgroundColor3 = WHT,
				BackgroundTransparency = trans,
				Text = text,
				Font = FONTB,
				TextSize = 14,
				TextColor3 = tcol,
				AutoButtonColor = false,
				BorderSizePixel = 0,
				ZIndex = 4,
			}, box)
			round(b, 10)
			return b
		end

		local bBack = mkBtn("点错了", 14, 0, 0.9, TXT)
		stroke(bBack, WHT, 0.75, 1)
		local bQuit = mkBtn("退出", bw - 14, 1, 0.05, Color3.fromRGB(20, 22, 30))

		bBack.MouseEnter:Connect(function() tweenTo(bBack, { BackgroundTransparency = 0.82 }, 0.14) end)
		bBack.MouseLeave:Connect(function() tweenTo(bBack, { BackgroundTransparency = 0.90 }, 0.14) end)
		bQuit.MouseEnter:Connect(function() tweenTo(bQuit, { BackgroundTransparency = 0.00 }, 0.14) end)
		bQuit.MouseLeave:Connect(function() tweenTo(bQuit, { BackgroundTransparency = 0.05 }, 0.14) end)

		local function closeAsk()
			asking = false
			pcall(function() pg:Destroy() end)
		end
		bBack.Activated:Connect(closeAsk)
		bQuit.Activated:Connect(function()
			closeAsk()
			hardQuit()
		end)
	end

	btnClose.Activated:Connect(askQuit)

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

]====]
local okE,rE=pcall(function()
return loadstring(EMBED)()
end)
if okE and type(rE)=="table" and rE.CreateWindow then B=rE end
end
if B then
WindUI=B
elseif not WindUI then
-- 最后兜底：老界面（只有内嵌也坏了才会走到这里）
WindUI=loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/Footagesus/WindUI@main/dist/main.lua"))()
end
end

local P=game:GetService("Players")
local LP=P.LocalPlayer
local sp,jp=16,50
local function guiRoots()
local t={}
local pg=LP:FindFirstChildOfClass("PlayerGui")
if pg then t[#t+1]=pg end
local okc,cg=pcall(function() return game:GetService("CoreGui") end)
if okc and cg then t[#t+1]=cg end
return t
end
local GUIO={}
for _,r in ipairs(guiRoots()) do for _,c in ipairs(r:GetChildren()) do GUIO[c]=true end end
local Win=WindUI:CreateWindow({Title="婴儿脚本"})
task.delay(1,function()
pcall(function()
WindUI:Notify({Title="欢迎使用婴儿脚本",Content="玻璃界面已就绪（"..UI_SRC.."）· 左边选功能 · − 收起 · × 退出",Duration=4})
end)
end)
local SelfGui
for _,r in ipairs(guiRoots()) do
for _,c in ipairs(r:GetChildren()) do
if not GUIO[c] and c:IsA("ScreenGui") then SelfGui=c end
end
end
local MAIN_URL="https://raw.githubusercontent.com/78589wlg/baby-script/main/NeonUI_v63.lua?v=63"
local function reloadUI()
task.spawn(function()
local okd,src=pcall(function()return game:HttpGet(MAIN_URL)end)
if not okd or type(src)~="string" or #src<2000 then
pcall(function()WindUI:Notify({Title="切换界面",Content="下载失败，检查网络后再点一次",Duration=3})end)
return
end
pcall(function()WindUI:Notify({Title="切换界面",Content="正在换成另一套界面…",Duration=2})end)
if type(WindUI.OnQuit)=="function" then pcall(WindUI.OnQuit) end
task.wait(0.55)
for _,r in ipairs(guiRoots())do
for _,c in ipairs(r:GetChildren())do
if not GUIO[c] and c:IsA("ScreenGui")then
pcall(function()c:Destroy()end)
end
end
end
task.wait(0.4)
local okk=pcall(function()loadstring(src)()end)
if not okk then
pcall(function()loadstring(game:HttpGet(MAIN_URL.."&r="..tostring(os.time())))() end)
end
end)
end
local ok=false
local T2,T3,T4,T5,T6,T7
local ntHeartStart
local G="https://cdn.jsdelivr.net/gh/78589wlg/baby-script@main/"
local PM={[537413528]="https://raw.githubusercontent.com/78589wlg/baby-script/main/Boat_v37.lua?v=53",[98502499119821]=G.."Fish_v2.lua",[90148635862803]=G.."Deadly.lua",[107778070777162]=G.."Egg.lua",[79546208627805]=G.."N99.lua",[10165583746]=G.."Examination_zh.lua",[136431686349723]="https://raw.githubusercontent.com/78589wlg/baby-script/main/Pursued.lua?v=5"}
local subLoaded=false
local function subAuto()
local u=PM[game.PlaceId]
if not u then return end
if subLoaded then return end
subLoaded=true
local okk=pcall(function()loadstring(game:HttpGet(u))()end)
if not okk then subLoaded=false end
end
local th={"落日","极光","深海","樱花","森林","紫夜","熔岩","月白"}
local TMAP={["落日"]="Rose",["极光"]="Emerald",["深海"]="Sky",["樱花"]="Rose",["森林"]="Plant",["紫夜"]="Violet",["熔岩"]="Red",["月白"]="Light"}
local function hum()
local c=LP.Character
if c then return c:FindFirstChildOfClass("Humanoid")end
end
-- 卡密验证已拆成独立脚本 BabyKey.lua；主脚本不再校验卡密
local auto=true
local AM={[537413528]=1,[98502499119821]=1,[90148635862803]=1,[107778070777162]=1,[79546208627805]=1,[10165583746]=1,[136431686349723]=1}
local done=false
local function ktrim(x)return (tostring(x):gsub("^%s+",""):gsub("%s+$",""))end
local function doUnlock()
if done then return end
done=true
for _,x in ipairs({T2,T3,T4,T5,T6,T7})do
if x then pcall(function()x.Locked=false x:UnlockAll()end)end
end
if ntHeartStart then pcall(ntHeartStart) end
if auto and AM[game.PlaceId]then
WindUI:Notify({Title="自动加载",Content="正在加载副脚本",Duration=3})
task.wait(1)
subAuto()
end
end

local T1=Win:Tab({Title="设置",Icon="settings"})
if USE_OLD then
T1:Button({Title="换成新的UI",Callback=function()
setOldUIFlag(false)
reloadUI()
end})
else
T1:Button({Title="看不惯现在的UI？加载以前的UI",Callback=function()
setOldUIFlag(true)
reloadUI()
end})
end
T1:Section({Title="界面配色（点一下立刻换色）"})
for i=1,#th do
local n=th[i]
T1:Button({Title=n,Callback=function()
pcall(function()WindUI:SetTheme(USE_OLD and (TMAP[n] or "Dark") or n)end)
WindUI:Notify({Title="主题",Content=n,Duration=1})
end})
end
T6=Win:Tab({Title="传送",Icon="arrow"})
T6:Section({Title="传送到玩家头顶"})
local tpList={}
local tpSel=""
local function refreshTp()
for i=#tpList,1,-1 do tpList[i]=nil end
local n=0
for _,p in ipairs(P:GetPlayers())do
if p~=LP then n=n+1 tpList[n]=p.Name end
end
table.sort(tpList)
if n==0 then tpList[1]="（暂无其他玩家）" end
return n
end
local tpN=refreshTp()
tpSel=tpList[1] or ""
local function tpFind(n)
for _,p in ipairs(P:GetPlayers())do
if p.Name==n and p~=LP then return p end
end
end
local function tpTop(n)
local p=tpFind(n)
if not p then return false,"先选一个玩家（可以点刷新列表）" end
local myCh=LP.Character
local myH=myCh and myCh:FindFirstChildOfClass("Humanoid")
local myRoot=myCh and myCh:FindFirstChild("HumanoidRootPart")
if not myRoot or not myH then return false,"你的角色还没加载" end
if myH.Health<=0 then return false,"你已经死了，等重生" end
local tCh=p.Character
local tRoot=tCh and tCh:FindFirstChild("HumanoidRootPart")
if not tRoot then return false,"对方角色还没加载" end
myRoot.CFrame=CFrame.new(tRoot.Position+Vector3.new(0,3,0))
return true
end
local tpFollow=false
local tpConn=nil
local function tpStopFollow()
tpFollow=false
if tpConn then pcall(function()tpConn:Disconnect()end) tpConn=nil end
end
local function tpStartFollow()
tpStopFollow()
if tpN==0 then return false end
tpFollow=true
tpConn=game:GetService("RunService").Heartbeat:Connect(function()
if not tpFollow then return end
local okk=tpTop(tpSel)
if not okk then tpStopFollow() end
end)
return true
end
local tpDD=T6:Dropdown({Title="选择玩家",Values=tpList,Value=tpSel,Callback=function(v)
tpSel=v
end})
T6:Button({Title="传送到头顶",Callback=function()
local okk,why=tpTop(tpSel)
if okk then
WindUI:Notify({Title="传送",Content="已传送到 "..tostring(tpSel).." 头顶",Duration=2})
else
WindUI:Notify({Title="传送",Content=tostring(why),Duration=2})
end
end})
local function tpRefreshUI()
tpN=refreshTp()
if not tpFind(tpSel) then tpSel=tpList[1] or "" end
if tpDD then pcall(function()tpDD:Set(tpSel)end) end
end
pcall(function()
P.PlayerAdded:Connect(function() task.defer(tpRefreshUI) end)
P.PlayerRemoving:Connect(function() task.defer(tpRefreshUI) end)
end)
T6:Button({Title="刷新玩家列表",Callback=function()
tpRefreshUI()
WindUI:Notify({Title="传送",Content=tpN>0 and ("发现 "..tpN.." 个其他玩家") or "目前没有其他玩家",Duration=2})
end})
T6:Toggle({Title="持续跟随头顶",Value=false,Callback=function(v)
if v then
local okk=tpStartFollow()
if not okk then WindUI:Notify({Title="传送",Content="没有可以跟随的玩家",Duration=2}) end
else
tpStopFollow()
end
end})

T7=Win:Tab({Title="旋转",Icon="refresh"})
T7:Section({Title="角色自转（可以调速度）"})
local spinOn=false
local spinSpeed=180
local spinAtt,spinBv=nil,nil
local function spinStop()
if spinBv then pcall(function()spinBv:Destroy()end) spinBv=nil end
if spinAtt then pcall(function()spinAtt:Destroy()end) spinAtt=nil end
local ch=LP.Character
local h=ch and ch:FindFirstChildOfClass("Humanoid")
if h then pcall(function()h.AutoRotate=true end) end
end
local function spinStart()
spinStop()
local ch=LP.Character
local h=ch and ch:FindFirstChildOfClass("Humanoid")
local root=ch and ch:FindFirstChild("HumanoidRootPart")
if not root or not h then return false,"角色还没加载" end
if h.Health<=0 then return false,"你已经死了，等重生" end
pcall(function()h.AutoRotate=false end)
local a=Instance.new("Attachment")
a.Name="BabySpinAtt"
a.Parent=root
local b=Instance.new("BodyAngularVelocity")
b.Name="BabySpin"
b.Attachment0=a
b.MaxTorque=Vector3.new(0,1e7,0)
b.AngularVelocity=Vector3.new(0,math.rad(spinSpeed),0)
b.Parent=root
spinAtt,spinBv=a,b
return true
end
T7:Slider({Title="旋转速度（度/秒）",Value={Min=30,Max=900,Default=180},Callback=function(v)
spinSpeed=v
if spinBv then pcall(function()spinBv.AngularVelocity=Vector3.new(0,math.rad(v),0)end) end
end})
T7:Toggle({Title="开启旋转",Value=false,Callback=function(v)
spinOn=v
if v then
local okk,why=spinStart()
if not okk then
spinOn=false
WindUI:Notify({Title="旋转",Content=tostring(why),Duration=2})
end
else
spinStop()
end
end})
LP.CharacterAdded:Connect(function()
task.wait(1)
if spinOn then spinStart() end
end)
WindUI.OnQuit=function()
pcall(tpStopFollow)
pcall(spinStop)
end

T2=Win:Tab({Title="玩家增强",Icon="user"})
T2:Section({Title="移动设置"})
T2:Slider({Title="移动速度",Value={Min=16,Max=500,Default=16},Callback=function(v)
sp=v
local h=hum()
if h then h.WalkSpeed=sp end
end})
T2:Slider({Title="跳跃力",Value={Min=50,Max=500,Default=50},Callback=function(v)
jp=v
local h=hum()
if h then h.UseJumpPower=true h.JumpPower=jp end
end})
T2:Section({Title="飞行设置"})
local flyOn=false
local flySpeed=80
local flyBV,flyBG,flyConn=nil,nil,nil
local flyHoldUp,flyHoldDown=false,false
local flyPad,flyPadUp,flyPadDown
local flyToggleRef

local function buildFlyPad()
if flyPad then return flyPad end
local g=Instance.new("ScreenGui")
g.Name="BabyFlyPad"
g.ResetOnSpawn=false
g.IgnoreGuiInset=true
g.DisplayOrder=900
pcall(function()g.Parent=game:GetService("CoreGui")end)
if not g.Parent then g.Parent=LP:WaitForChild("PlayerGui")end
local function mk(text,posY)
local b=Instance.new("TextButton")
b.Size=UDim2.new(0,58,0,58)
b.Position=UDim2.new(1,-160,0.5,posY)
b.BackgroundColor3=Color3.fromRGB(28,31,40)
b.BackgroundTransparency=0.1
b.Text=text
b.TextColor3=Color3.fromRGB(255,255,255)
b.TextSize=22
b.Font=Enum.Font.GothamBold
b.AutoButtonColor=false
b.Parent=g
local c=Instance.new("UICorner")
c.CornerRadius=UDim.new(1,0)
c.Parent=b
local st=Instance.new("UIStroke")
st.Color=Color3.fromRGB(245,166,35)
st.Thickness=1
st.Transparency=0.4
st.Parent=b
return b
end
flyPadUp=mk("▲",-36)
flyPadDown=mk("▼",34)
local function bindHold(btn,field)
btn.InputBegan:Connect(function(i)
if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
if field=="up" then flyHoldUp=true else flyHoldDown=true end
end
end)
btn.InputEnded:Connect(function(i)
if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
if field=="up" then flyHoldUp=false else flyHoldDown=false end
end
end)
end
bindHold(flyPadUp,"up")
bindHold(flyPadDown,"down")
g.Enabled=false
flyPad=g
return g
end

local function stopFly(quiet)
flyOn=false
flyHoldUp=false
flyHoldDown=false
if flyConn then flyConn:Disconnect() flyConn=nil end
if flyBV then pcall(function() flyBV:Destroy() end) flyBV=nil end
if flyBG then pcall(function() flyBG:Destroy() end) flyBG=nil end
if flyPad then flyPad.Enabled=false end
local c=LP.Character
local h=c and c:FindFirstChildOfClass("Humanoid")
if h then pcall(function() h.PlatformStand=false end) end
if not quiet then
pcall(function() WindUI:Notify({Title="飞行",Content="已关闭",Duration=1}) end)
end
end

local function startFly()
local c=LP.Character
local h=c and c:FindFirstChildOfClass("Humanoid")
local hrp=c and c:FindFirstChild("HumanoidRootPart")
if not (h and hrp) then
pcall(function() WindUI:Notify({Title="飞行",Content="没找到角色，重生后再试",Duration=2}) end)
return false
end
stopFly(true)
flyOn=true
local uis=game:GetService("UserInputService")
if not uis.TouchEnabled then
pcall(function() h.PlatformStand=true end)
end
flyBV=Instance.new("BodyVelocity")
flyBV.MaxForce=Vector3.new(100000,100000,100000)
flyBV.P=1250
flyBV.Velocity=Vector3.new(0,0,0)
flyBV.Parent=hrp
flyBG=Instance.new("BodyGyro")
flyBG.MaxTorque=Vector3.new(100000,100000,100000)
flyBG.P=3000
flyBG.D=100
flyBG.CFrame=hrp.CFrame
flyBG.Parent=hrp
buildFlyPad().Enabled=true
flyConn=game:GetService("RunService").RenderStepped:Connect(function()
local ch=LP.Character
local root=ch and ch:FindFirstChild("HumanoidRootPart")
local hum=ch and ch:FindFirstChildOfClass("Humanoid")
if not root or not flyBV or not flyBG or not flyOn then return end
local cam=workspace.CurrentCamera
local dir=Vector3.new(0,0,0)
if uis:GetFocusedTextBox()==nil then
if uis:IsKeyDown(Enum.KeyCode.W) then dir=dir+cam.CFrame.LookVector end
if uis:IsKeyDown(Enum.KeyCode.S) then dir=dir-cam.CFrame.LookVector end
if uis:IsKeyDown(Enum.KeyCode.D) then dir=dir+cam.CFrame.RightVector end
if uis:IsKeyDown(Enum.KeyCode.A) then dir=dir-cam.CFrame.RightVector end
if uis:IsKeyDown(Enum.KeyCode.Space) then dir=dir+Vector3.new(0,1,0) end
if uis:IsKeyDown(Enum.KeyCode.LeftControl) or uis:IsKeyDown(Enum.KeyCode.LeftShift) then dir=dir-Vector3.new(0,1,0) end
end
-- 手机摇杆（摇杆方向直接当飞行方向）
if hum and hum.MoveDirection.Magnitude>0.1 then
dir=dir+hum.MoveDirection
end
if flyHoldUp then dir=dir+Vector3.new(0,1,0) end
if flyHoldDown then dir=dir-Vector3.new(0,1,0) end
if dir.Magnitude>0 then
flyBV.Velocity=dir.Unit*flySpeed
else
flyBV.Velocity=Vector3.new(0,0,0)
end
flyBG.CFrame=cam.CFrame
end)
return true
end

flyToggleRef=T2:Toggle({Title="飞行（F 键开关 · 朝相机方向飞）",Value=false,Callback=function(v)
if v then
if not startFly() then
pcall(function() if flyToggleRef and flyToggleRef.Set then flyToggleRef:Set(false) end end)
end
else
stopFly()
end
end})
T2:Slider({Title="飞行速度",Value={Min=20,Max=300,Default=80},Callback=function(v)
flySpeed=v
end})
T2:Button({Title="飞行 · 上升一点",Callback=function()
local c=LP.Character
local hrp=c and c:FindFirstChild("HumanoidRootPart")
if hrp then hrp.CFrame=hrp.CFrame+Vector3.new(0,3,0) end
end})
T2:Button({Title="飞行 · 下降一点",Callback=function()
local c=LP.Character
local hrp=c and c:FindFirstChild("HumanoidRootPart")
if hrp then hrp.CFrame=hrp.CFrame-Vector3.new(0,3,0) end
end})
game:GetService("UserInputService").InputBegan:Connect(function(i,gpe)
if gpe then return end
if i.KeyCode==Enum.KeyCode.F then
if flyOn then
stopFly()
else
startFly()
end
pcall(function() if flyToggleRef and flyToggleRef.Set then flyToggleRef:Set(flyOn) end end)
end
end)
LP.CharacterAdded:Connect(function()
if flyOn then
task.wait(1)
pcall(function() stopFly(true) end)
end
end)
T2:Section({Title="穿墙设置"})
local pc={}
T2:Toggle({Title="穿墙",Value=false,Callback=function(s)
local c=LP.Character
if not c then return end
for _,v in pairs(c:GetDescendants())do
if v:IsA("BasePart")then
if s then
if v.CanCollide==true then pc[v]=true end
v.CanCollide=false
else
if pc[v] then v.CanCollide=true end
end
end
end
if not s then pc={} end
WindUI:Notify({Title="穿墙",Content=s and "已开启" or "已关闭",Duration=1})
end})
T2:Toggle({Title="透视",Value=false,Callback=function(s)
if s then
local cg=game:GetService("CoreGui")
for _,v in pairs(P:GetPlayers())do
if v~=LP and v.Character then
local h=Instance.new("Highlight")
h.FillColor=Color3.fromRGB(255,0,0)
h.FillTransparency=0.5
h.OutlineColor=Color3.fromRGB(255,0,0)
h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
h.Adornee=v.Character
h.Parent=cg
end
end
else
for _,h in pairs(game:GetService("CoreGui"):GetChildren())do
if h:IsA("Highlight")then pcall(function()h:Destroy()end)end
end
end
WindUI:Notify({Title="透视",Content=s and "已开启" or "已关闭",Duration=1})
end})
T3=Win:Tab({Title="其他脚本",Icon="package"})
T3:Section({Title="脚本列表"})
T3:Button({Title="皮脚本",Callback=function()
getgenv().XiaoPi="皮脚本QQ1002100032"
pcall(function()loadstring(game:HttpGet("https://raw.githubusercontent.com/xiaopi77/xiaopi77/main/QQ1002100032-Roblox-Pi-script.lua"))()end)
end})
T3:Section({Title="剑球（第三方 · 先私服试）"})
local function bb3(name,url)
WindUI:Notify({Title="第三方脚本",Content=name.." 不是我写的，用私服小号测",Duration=3})
pcall(function()loadstring(game:HttpGet(url))()end)
end
T3:Button({Title="剑球 · Fairn't Hub（8KB 明文）",Callback=function()
bb3("Fairn't Hub","https://cdn.jsdelivr.net/gh/Asyrantheyt/Fairn-t-Hub@main/scripts/Blade%20Ball.lua")
end})
T3:Button({Title="剑球 · CritClHub（6KB 明文，最简）",Callback=function()
bb3("CritClHub","https://cdn.jsdelivr.net/gh/wploits/critclhub@main/bladeball.lua")
end})
T3:Button({Title="剑球 · Opensurs（60KB 大杂烩）",Callback=function()
bb3("Opensurs","https://cdn.jsdelivr.net/gh/HOSTI1315/Opensurs@main/bladeball_2.lua")
end})
T4=Win:Tab({Title="更多"})
T4:Section({Title="工具"})
T4:Button({Title="重生",Callback=function()
local h=hum()
if h then h.Health=0 end
end})
T4:Toggle({Title="友好玩家变绿",Value=false,Callback=function(v)
if v then
pcall(function()loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/78589wlg/baby-script@main/EspUser.lua"))()end)
else
pcall(function()getgenv().BabyClear()end)
end
end})
T4:Toggle({Title="头顶名字标签",Value=false,Callback=function(v)
if v then
pcall(function()loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/78589wlg/baby-script@main/TagUser.lua"))()end)
getgenv().BabyTagOn=true
WindUI:Notify({Title="头顶名字标签",Content="只给名单里的人显示",Duration=3})
else
getgenv().BabyTagOn=false
if getgenv().BabyTagClean then
pcall(getgenv().BabyTagClean)
else
for _,o in ipairs(game.Players:GetPlayers())do
local c=o.Character
local hd=c and c:FindFirstChild("Head")
local b=hd and hd:FindFirstChild("BabyNameTag")
if b then pcall(function()b:Destroy()end)end
end
end
end
end})
-- ===== 翻译 =====
T4:Section({Title="翻译"})
local trLang,trScene,trOther,trEngine="zh",false,true,"google"
T4:Dropdown({Title="翻译成",Values={"简体中文","English","日本語","한국어","繁體中文"},Value="简体中文",Callback=function(v)
local m={["简体中文"]="zh",["English"]="en",["日本語"]="ja",["한국어"]="ko",["繁體中文"]="zh-TW"}
trLang=m[v] or "zh"
getgenv().BabyTransLang=trLang
if getgenv().BabyTransSetLang then pcall(getgenv().BabyTransSetLang,trLang) end
end})
T4:Dropdown({Title="翻译引擎",Values={"Google","自动（谁快用谁）","必应","腾讯","MyMemory"},Value="Google",Callback=function(v)
local m={["自动（谁快用谁）"]="auto",["Google"]="google",["必应"]="bing",["腾讯"]="tencent",["MyMemory"]="mymemory"}
trEngine=m[v] or "auto"
getgenv().BabyTransEngine=trEngine
if getgenv().BabyTransSetEngine then pcall(getgenv().BabyTransSetEngine,trEngine) end
end})
T4:Toggle({Title="翻译游戏文字（界面）",Value=false,Callback=function(v)
if v then
getgenv().BabyTransLang=trLang
getgenv().BabyTransScene=trScene
getgenv().BabyTransOther=trOther
getgenv().BabyTransEngine=trEngine
getgenv().BabyTransSelfGui=SelfGui
pcall(function()loadstring(game:HttpGet("https://raw.githubusercontent.com/78589wlg/baby-script/main/Trans.lua?v=5"))()end)
else
if getgenv().BabyTransOff then pcall(getgenv().BabyTransOff) end
end
end})
T4:Toggle({Title="包含场景文字（告示牌/头顶字）",Value=false,Callback=function(v)
trScene=v
getgenv().BabyTransScene=v
if getgenv().BabyTransSetScene then pcall(getgenv().BabyTransSetScene,v) end
end})
T4:Toggle({Title="翻译其他脚本（第三方面板）",Value=true,Callback=function(v)
trOther=v
getgenv().BabyTransOther=v
if getgenv().BabyTransSetOther then pcall(getgenv().BabyTransSetOther,v) end
end})
-- ===== 在线脚本用户（公共在线表，免部署） =====
local NT="https://ntfy.sh/"
local ntOn=false
local ntSeen={}
local ntGui,ntTitle,ntBody
local hudOn=false

local function ntTopic()return "bs_online_"..tostring(game.PlaceId)end
local function ntClean(s)local t=tostring(s or "")return (t:gsub("[|\r\n]",""))end
local function ntPost(u,b)
local ok=pcall(function()game:HttpPost(u,b)end)
if ok then return true end
local f=request
if not f then f=http_request end
if not f and syn and syn.request then f=syn.request end
if f then
local ok2=pcall(function()f({Url=u,Method="POST",Body=b,Headers={["Content-Type"]="text/plain"}})end)
return ok2
end
return false
end

local function ntHUD()
if ntGui and ntGui.Parent then return true end
local pg=LP:FindFirstChildOfClass("PlayerGui")
if not pg then return false end
local oldg=pg:FindFirstChild("BabyOnline")
if oldg then pcall(function()oldg:Destroy()end) end
local g=Instance.new("ScreenGui")
g.Name="BabyOnline"
g.ResetOnSpawn=false
g.IgnoreGuiInset=true
g.DisplayOrder=999
g.Parent=pg
local f=Instance.new("Frame")
f.Name="Box"
f.AnchorPoint=Vector2.new(1,0)
f.Position=UDim2.new(1,-12,0,84)
f.Size=UDim2.new(0,236,0,186)
f.BackgroundColor3=Color3.fromRGB(20,20,26)
f.BackgroundTransparency=0.12
f.BorderSizePixel=0
f.Parent=g
local c1=Instance.new("UICorner")
c1.CornerRadius=UDim.new(0,8)
c1.Parent=f
local t=Instance.new("TextButton")
t.Name="Head"
t.Size=UDim2.new(1,0,0,30)
t.BackgroundColor3=Color3.fromRGB(38,38,50)
t.BorderSizePixel=0
t.Text="在线脚本用户 0"
t.TextColor3=Color3.fromRGB(255,255,255)
t.Font=Enum.Font.GothamBold
t.TextSize=14
t.AutoButtonColor=false
t.Parent=f
local b=Instance.new("TextLabel")
b.Name="Body"
b.Position=UDim2.new(0,10,0,36)
b.Size=UDim2.new(1,-20,1,-44)
b.BackgroundTransparency=1
b.Text=""
b.TextColor3=Color3.fromRGB(215,215,225)
b.Font=Enum.Font.Gotham
b.TextSize=13
b.TextXAlignment=Enum.TextXAlignment.Left
b.TextYAlignment=Enum.TextYAlignment.Top
b.TextWrapped=true
b.Parent=f
ntGui=g
ntTitle=t
ntBody=b
t.MouseButton1Click:Connect(function()
b.Visible=not b.Visible
f.Size=UDim2.new(0,236,0,b.Visible and 186 or 34)
end)
return true
end

local function ntRender()
if not hudOn then return end
if not ntHUD() then return end
local arr={}
for _,v in pairs(ntSeen)do arr[#arr+1]=v end
table.sort(arr,function(a,b)return (a.t or 0)>(b.t or 0)end)
local myJ=tostring(game.JobId)
local lines={}
local cross=0
local shown=0
local lim=12
local sameFirst={}
local otherFirst={}
for _,v in ipairs(arr)do
if v.j and v.j~="" and v.j~=myJ then otherFirst[#otherFirst+1]=v else sameFirst[#sameFirst+1]=v end
end
for _,v in ipairs(sameFirst)do
if shown>=lim then break end
shown=shown+1
local nm=v.dn
if not nm or nm=="" then nm=v.nm end
local me=(tostring(v.u)==tostring(LP.UserId)) and "（你）" or ""
lines[#lines+1]="· "..nm..me
end
if #otherFirst>0 then
lines[#lines+1]="── 其他服务器 "..#otherFirst.." 人 ──"
for _,v in ipairs(otherFirst)do
cross=cross+1
if shown<lim then
shown=shown+1
local nm=v.dn
if not nm or nm=="" then nm=v.nm end
lines[#lines+1]="· "..nm.."（跨服 @"..v.nm.."）"
end
end
end
if #arr==0 then lines[#lines+1]="暂无记录" end
local hidden=#arr-shown
if hidden>0 then lines[#lines+1]="…还有 "..hidden.." 人" end
if cross>0 then
ntTitle.Text="在线脚本用户 "..#arr.."（跨服 "..cross.."）"
else
ntTitle.Text="在线脚本用户 "..#arr
end
ntBody.Text=table.concat(lines,"\n")
end

local function ntBeat()
local jid=ntClean(tostring(game.JobId))
if jid=="" then jid="unknown" end
local b=tostring(LP.UserId).."|"..ntClean(LP.DisplayName).."|"..ntClean(LP.Name).."|"..tostring(game.PlaceId).."|"..tostring(os.time()).."|"..jid
return ntPost(NT..ntTopic(),b)
end

-- 常驻心跳：与两个开关无关，脚本一解锁就一直上报（这样别人关掉开关也能被你看到）
local ntHeartOn=false
ntHeartStart=function()
if ntHeartOn then return end
ntHeartOn=true
task.spawn(function()
while ntHeartOn do
pcall(ntBeat)
local n=0
while ntHeartOn and n<60 do task.wait(1) n=n+1 end
end
end)
end

local function ntFetch()
local ok,txt=pcall(function()return game:HttpGet(NT..ntTopic().."/json?poll=1&since=15m")end)
if not ok or type(txt)~="string" then return false end
local now=os.time()
local seen={}
for line in txt:gmatch("[^\r\n]+")do
local m=line:match('"message":"(.-)"')
if m then
local u,dn,nm,p,ts,j=m:match("^(%d+)|([^|]*)|([^|]*)|(%d+)|(%d+)|?(.-)$")
if u and ts then
local tt=tonumber(ts)
if tt and now-tt<=200 then
local o=seen[u]
if not o or tt>o.t then
seen[u]={u=u,dn=dn,nm=nm,t=tt,j=j or ""}
end
end
end
end
end
local added={}
for u,v in pairs(seen)do
if not ntSeen[u] then added[#added+1]=v end
end
ntSeen=seen
return true,added
end

-- ===== 脚本使用者：绿色高亮 + 头顶标签 =====
local espOn=false
local espMap={}
local function espClear()
for pl,e in pairs(espMap)do
if e.hl then pcall(function()e.hl:Destroy()end) end
if e.tag then pcall(function()e.tag:Destroy()end) end
end
espMap={}
end

local function espApply()
if not espOn then return end
for _,pl in ipairs(game.Players:GetPlayers())do
local rec=ntSeen[tostring(pl.UserId)]
local ch=pl.Character
local e=espMap[pl]
if rec and ch then
if not e then e={} espMap[pl]=e end
if not (e.hl and e.hl.Parent) then
local hl=Instance.new("Highlight")
hl.Name="BabyScriptHL"
hl.FillColor=Color3.fromRGB(0,255,90)
hl.FillTransparency=0.55
hl.OutlineColor=Color3.fromRGB(0,255,90)
hl.OutlineTransparency=0
hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
hl.Adornee=ch
hl.Parent=ch
e.hl=hl
end
local hd=ch:FindFirstChild("Head")
if hd and not (e.tag and e.tag.Parent) then
local bb=Instance.new("BillboardGui")
bb.Name="BabyScriptTag"
bb.Size=UDim2.new(0,150,0,34)
bb.StudsOffset=Vector3.new(0,2.4,0)
bb.AlwaysOnTop=true
bb.MaxDistance=150
local tl=Instance.new("TextLabel")
tl.Size=UDim2.new(1,0,1,0)
tl.BackgroundTransparency=1
tl.Text="脚本使用者"
tl.TextColor3=Color3.fromRGB(0,255,90)
tl.TextStrokeColor3=Color3.fromRGB(0,0,0)
tl.TextStrokeTransparency=0.35
tl.Font=Enum.Font.GothamBold
tl.TextScaled=true
tl.Parent=bb
bb.Parent=hd
e.tag=bb
end
else
if e then
if e.hl then pcall(function()e.hl:Destroy()end) end
if e.tag then pcall(function()e.tag:Destroy()end) end
espMap[pl]=nil
end
end
end
end

local function ntDropHud()
hudOn=false
if ntGui then pcall(function()ntGui:Destroy()end) end
ntGui=nil
end

local function ntStop()
ntOn=false
hudOn=false
if ntGui then pcall(function()ntGui:Destroy()end) end
ntGui=nil
ntSeen={}
espClear()
end

local function ntStart()
if ntOn then return end
ntOn=true
task.spawn(function()
local first=true
local fast=0
while ntOn do
local ok,added=pcall(ntFetch)
if ok then
pcall(ntRender)
pcall(espApply)
if first then
local n=0
for _ in pairs(ntSeen)do n=n+1 end
if n>1 then
WindUI:Notify({Title="脚本使用者",Content="发现 "..n.." 个同脚本玩家（含你）",Duration=5})
elseif n==1 then
local only=nil
for _,v in pairs(ntSeen)do only=v end
if only then
if tostring(only.u)==tostring(LP.UserId)then
WindUI:Notify({Title="脚本使用者",Content="目前只有你在用",Duration=4})
else
local nm=only.dn
if not nm or nm=="" then nm=only.nm end
local cj=only.j and only.j~="" and only.j~=tostring(game.JobId)
local pre=cj and "跨服发现脚本使用者：" or "发现脚本使用者："
WindUI:Notify({Title="脚本使用者",Content=pre..nm..(cj and "（在其他服务器）" or ""),Duration=5})
end
end
end
first=false
elseif type(added)=="table" and #added>0 then
local k=0
for _,v in ipairs(added)do
if tostring(v.u)~=tostring(LP.UserId)then
k=k+1
if k<=3 then
local nm=v.dn
if not nm or nm=="" then nm=v.nm end
local isCross=v.j and v.j~="" and v.j~=tostring(game.JobId)
if isCross then
WindUI:Notify({Title="跨服发现脚本使用者",Content=nm.."（在其他服务器）",Duration=4})
else
WindUI:Notify({Title="新发现脚本使用者",Content=nm,Duration=4})
end
end
end
end
end
end
fast=fast+1
local gap=60
if fast<=6 then gap=20 end
local n=0
while ntOn and n<gap do task.wait(1) n=n+1 end
end
end)
task.spawn(function()
while ntOn do
task.wait(2)
if espOn then pcall(espApply) end
end
end)
task.delay(5,function()
if not ntOn then return end
local n=0
for _ in pairs(ntSeen)do n=n+1 end
if n==0 then
WindUI:Notify({Title="脚本用户检测",Content="暂时没拉到在线数据（没人开或网络受限）",Duration=5})
end
end)
end

T4:Toggle({Title="脚本用户检测（显示右侧小窗）",Value=false,Callback=function(v)
if v then
hudOn=true
WindUI:Notify({Title="脚本用户检测",Content="正在连接公共在线表…",Duration=3})
if ntOn then
task.spawn(function()
pcall(ntFetch)
pcall(ntRender)
pcall(espApply)
end)
else
ntStart()
end
else
ntDropHud()
if not espOn then
ntStop()
WindUI:Notify({Title="脚本用户检测",Content="小窗已关闭｜你的心跳仍在上报，别人依然看得到你",Duration=5})
else
WindUI:Notify({Title="脚本用户检测",Content="小窗已关闭，变绿仍生效｜你依然在别人的名单里",Duration=5})
end
end
end})
T4:Toggle({Title="脚本使用者变绿 + 头顶字（独立生效）",Value=false,Callback=function(v)
espOn=v
if v then
if not ntOn then
hudOn=false
ntStart()
end
WindUI:Notify({Title="脚本使用者",Content="同脚本玩家会变绿，头顶显示「脚本使用者」",Duration=4})
task.spawn(function()
pcall(ntFetch)
pcall(ntRender)
pcall(espApply)
end)
else
espClear()
if not hudOn then ntStop() end
WindUI:Notify({Title="脚本使用者",Content="已关闭｜你依然在别人的名单里（心跳常驻）",Duration=5})
end
end})
T4:Button({Title="刷新在线名单",Callback=function()
if not ntOn then WindUI:Notify({Title="在线名单",Content="请先打开上面的开关",Duration=3})return end
local ok=ntFetch()
if ok then pcall(ntRender) end
local n=0
for _ in pairs(ntSeen)do n=n+1 end
WindUI:Notify({Title="在线名单",Content=ok and ("当前 "..n.." 人") or "拉取失败，检查网络",Duration=3})
end})
T4:Button({Title="复制在线名单",Callback=function()
local arr={}
for _,v in pairs(ntSeen)do
local nm=v.dn
if not nm or nm=="" then nm=v.nm end
arr[#arr+1]=nm.."("..tostring(v.nm)..")"
end
if #arr==0 then WindUI:Notify({Title="在线名单",Content="暂无数据",Duration=3})return end
pcall(function()if setclipboard then setclipboard(table.concat(arr,"\n"))end end)
WindUI:Notify({Title="在线名单",Content="已复制 "..#arr.." 人",Duration=3})
end})
T4:Input({Title="本局临时名单",Placeholder="@后面的英文名，逗号分隔",Value="",Callback=function(t)
getgenv().BabyExtra2=t
pcall(function()if getgenv().BabyRescan then getgenv().BabyRescan()end end)
end})
T4:Button({Title="查看当前名单",Callback=function()
local L={}
pcall(function()if getgenv().BabyList then L=getgenv().BabyList()end end)
if #L==0 then
WindUI:Notify({Title="当前名单",Content="暂无名字",Duration=3})
else
WindUI:Notify({Title="当前名单",Content=table.concat(L,"，"),Duration=5})
end
end})
T4:Section({Title="开发者功能"})
local DEVKEY="婴儿nb-作者-VIP8888"
local DEVURL="https://raw.githubusercontent.com/78589wlg/baby-script/main/Dev_v5.lua"
local devTxt=""
local function devLoad()
local okk=pcall(function()loadstring(game:HttpGet(DEVURL))()end)
if okk then
WindUI:Notify({Title="开发者功能",Content="已加载",Duration=3})
else
WindUI:Notify({Title="开发者功能",Content="加载失败，检查网络",Duration=4})
end
end
T4:Input({Title="开发者卡密",Placeholder="请输入开发者专用卡密",Value="",Callback=function(t)devTxt=t end})
T4:Button({Title="验证并加载开发者功能",Callback=function()
if ktrim(devTxt)~=DEVKEY then
WindUI:Notify({Title="开发者功能",Content="卡密不对",Duration=4})
return
end
pcall(function()if writefile then writefile("BabyDev.txt",DEVKEY)end end)
getgenv().babyDevOK=true
devLoad()
end})
T4:Button({Title="重新打开开发者面板（免输卡密）",Callback=function()
local has=false
pcall(function()if isfile and isfile("BabyDev.txt")then has=readfile("BabyDev.txt")==DEVKEY end end)
if not has and not getgenv().babyDevOK then
WindUI:Notify({Title="开发者功能",Content="还没解锁，请先输入开发者卡密验证",Duration=4})
return
end
devLoad()
end})

T4:Button({Title="复制QQ号",Callback=function()
pcall(function()setclipboard("3492202561")end)
WindUI:Notify({Title="QQ号",Content="3492202561 已复制",Duration=2})
end})
T5=Win:Tab({Title="脚本库",Icon="list"})
T5:Section({Title="其他脚本"})
local sel="造船寻宝"
local LU={["造船寻宝"]="https://raw.githubusercontent.com/78589wlg/baby-script/main/Boat_v37.lua?v=53",["重型钓鱼"]="https://cdn.jsdelivr.net/gh/78589wlg/baby-script@main/Fish_v2.lua",["在末日中生存下来"]="https://cdn.jsdelivr.net/gh/78589wlg/baby-script@main/Deadly.lua",["偷一个蛋"]="https://cdn.jsdelivr.net/gh/78589wlg/baby-script@main/Egg.lua",["森林中的99夜"]="https://cdn.jsdelivr.net/gh/78589wlg/baby-script@main/N99.lua",["试炼"]="https://cdn.jsdelivr.net/gh/78589wlg/baby-script@main/Examination_zh.lua",["战利品"]="https://raw.githubusercontent.com/78589wlg/baby-script/main/Loot_v2.lua",["被追捕（HUNTED）"]="https://raw.githubusercontent.com/78589wlg/baby-script/main/Pursued.lua?v=5",["Blade Ball（剑球）"]="https://raw.githubusercontent.com/78589wlg/baby-script/main/BladeBall.lua?v=17",["监狱人生（Prison Life）"]="https://raw.githubusercontent.com/78589wlg/baby-script/main/PrisonLife.lua?v=2"}
T5:Dropdown({Title="选择脚本",Values={"造船寻宝","重型钓鱼","在末日中生存下来","偷一个蛋","森林中的99夜","试炼","战利品","被追捕（HUNTED）","Blade Ball（剑球）","监狱人生（Prison Life）"},Value="造船寻宝",Callback=function(v)
sel=v
end})
T5:Button({Title="使用",Callback=function()
local u=LU[sel]
if not u then WindUI:Notify({Title="脚本库",Content="未知脚本",Duration=2})return end
WindUI:Notify({Title="脚本库",Content="正在执行 "..sel,Duration=2})
pcall(function()loadstring(game:HttpGet(u))()end)
end})
T5:Toggle({Title="进入游戏自动加载副脚本",Value=true,Callback=function(v)auto=v end})
LP.CharacterAdded:Connect(function(c)
local h=c:WaitForChild("Humanoid",10)
if h then
task.wait(0.5)
h.WalkSpeed=sp
h.UseJumpPower=true
h.JumpPower=jp
end
end)
doUnlock()
