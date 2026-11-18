--[[
    Jandel's Road Trip · 旧服务器传送
    ------------------------------------------------------------
    就是一个小面板，点按钮直接传送到各个旧版本 / 老服务器。
    灵感来源：@jrcrtktjhneleven
    ------------------------------------------------------------
    用法：执行即可，面板出现在屏幕右侧，可拖动，手机可点。
]]

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LP = Players.LocalPlayer
local UNIVERSE_ID = 5650396773

-- 旧服务器列表（全部是同一个 universe 下的老版本 place）
local PLACES = {
	{ Name = "圣诞节", PlaceId = 72639813364968 },
	{ Name = "德比", PlaceId = 18369256317 },
	{ Name = "复古", PlaceId = 17584310335 },
	{ Name = "万圣节", PlaceId = 98422814745197 },
	{ Name = "侏罗纪", PlaceId = 118569659995312 },
	{ Name = "怪物卡车（老服务器）", PlaceId = 17527910461 },
}

-- 主游戏 place（运行时自动查，查不到就隐藏返回按钮）
local rootPlaceId = nil
task.spawn(function()
	local ok, res = pcall(function()
		return game:HttpGet("https://games.roblox.com/v1/games?universeIds=" .. UNIVERSE_ID)
	end)
	if not ok or not res then return end
	local ok2, data = pcall(function()
		return HttpService:JSONDecode(res)
	end)
	if ok2 and data and data.data and data.data[1] then
		rootPlaceId = data.data[1].rootPlaceId
	end
end)

-- 重复执行时先清掉旧面板
local old = game:GetService("CoreGui"):FindFirstChild("JandelOldServers")
if old then old:Destroy() end

local COL_BG      = Color3.fromRGB(16, 18, 24)
local COL_CARD    = Color3.fromRGB(30, 33, 42)
local COL_CARD_HL = Color3.fromRGB(42, 46, 58)
local COL_ACCENT  = Color3.fromRGB(245, 166, 35)
local COL_TEXT    = Color3.fromRGB(240, 242, 248)
local COL_SUB     = Color3.fromRGB(150, 156, 170)

local gui = Instance.new("ScreenGui")
gui.Name = "JandelOldServers"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
do
	local ok = pcall(function() gui.Parent = game:GetService("CoreGui") end)
	if not ok or not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end
end

-- ===== 主窗口 =====
local win = Instance.new("Frame")
win.Name = "Window"
win.Size = UDim2.new(0, 320, 0, 448)
win.Position = UDim2.new(1, -340, 0.5, -224)
win.BackgroundColor3 = COL_BG
win.BorderSizePixel = 0
win.ClipsDescendants = true
win.Active = true
win.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = win

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(60, 64, 78)
stroke.Thickness = 1
stroke.Parent = win

-- ===== 标题栏 =====
local bar = Instance.new("Frame")
bar.Name = "TitleBar"
bar.Size = UDim2.new(1, 0, 0, 64)
bar.BackgroundColor3 = Color3.fromRGB(20, 23, 30)
bar.BorderSizePixel = 0
bar.Parent = win

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, 14)
barCorner.Parent = bar

local barFix = Instance.new("Frame")
barFix.Size = UDim2.new(1, 0, 0, 14)
barFix.Position = UDim2.new(0, 0, 1, -14)
barFix.BackgroundColor3 = Color3.fromRGB(20, 23, 30)
barFix.BorderSizePixel = 0
barFix.Parent = bar

local accentBar = Instance.new("Frame")
accentBar.Size = UDim2.new(0, 4, 0, 26)
accentBar.Position = UDim2.new(0, 16, 0, 19)
accentBar.BackgroundColor3 = COL_ACCENT
accentBar.BorderSizePixel = 0
accentBar.Parent = bar

local ac = Instance.new("UICorner")
ac.CornerRadius = UDim.new(1, 0)
ac.Parent = accentBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 0, 20)
title.Position = UDim2.new(0, 30, 0, 13)
title.BackgroundTransparency = 1
title.Text = "旧服务器传送"
title.TextColor3 = COL_TEXT
title.TextSize = 17
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = bar

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -60, 0, 16)
subtitle.Position = UDim2.new(0, 30, 0, 33)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Jandel's Road Trip"
subtitle.TextColor3 = COL_SUB
subtitle.TextSize = 12
subtitle.Font = Enum.Font.Gotham
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = bar

-- 折叠按钮
local foldBtn = Instance.new("TextButton")
foldBtn.Size = UDim2.new(0, 30, 0, 30)
foldBtn.Position = UDim2.new(1, -42, 0, 17)
foldBtn.BackgroundColor3 = Color3.fromRGB(34, 38, 48)
foldBtn.Text = "−"
foldBtn.TextColor3 = COL_TEXT
foldBtn.TextSize = 18
foldBtn.Font = Enum.Font.GothamBold
foldBtn.AutoButtonColor = false
foldBtn.Parent = bar

local fc = Instance.new("UICorner")
fc.CornerRadius = UDim.new(0, 8)
fc.Parent = foldBtn

-- ===== 内容区 =====
local body = Instance.new("Frame")
body.Name = "Body"
body.Size = UDim2.new(1, 0, 1, -64)
body.Position = UDim2.new(0, 0, 0, 64)
body.BackgroundTransparency = 1
body.Parent = win

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -32, 0, 34)
statusLabel.Position = UDim2.new(0, 16, 0, 8)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "点击下方按钮传送到老版本"
statusLabel.TextColor3 = COL_SUB
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextWrapped = true
statusLabel.Parent = body

local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(1, -24, 1, -112)
list.Position = UDim2.new(0, 12, 0, 48)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 3
list.ScrollBarImageColor3 = Color3.fromRGB(70, 74, 88)
list.CanvasSize = UDim2.new(0, 0, 0, 0)
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.Parent = body

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local note = Instance.new("TextLabel")
note.Size = UDim2.new(1, -32, 0, 40)
note.Position = UDim2.new(0, 0, 1, -46)
note.BackgroundTransparency = 1
note.Text = "传送后若卡在加载界面，重新加入游戏即可。\n不同旧服务器进度不互通。"
note.TextColor3 = Color3.fromRGB(110, 116, 130)
note.TextSize = 11
note.Font = Enum.Font.Gotham
note.TextWrapped = true
note.TextXAlignment = Enum.TextXAlignment.Center
note.Parent = body

-- ===== 小提示（右下角气泡） =====
local toastFrame = Instance.new("Frame")
toastFrame.Size = UDim2.new(0, 300, 0, 0)
toastFrame.Position = UDim2.new(0.5, -150, 1, -80)
toastFrame.BackgroundColor3 = Color3.fromRGB(28, 31, 40)
toastFrame.BackgroundTransparency = 0
toastFrame.BorderSizePixel = 0
toastFrame.Visible = false
toastFrame.ZIndex = 20
toastFrame.Parent = gui

local tc = Instance.new("UICorner")
tc.CornerRadius = UDim.new(0, 10)
tc.Parent = toastFrame

local toastLabel = Instance.new("TextLabel")
toastLabel.Size = UDim2.new(1, -24, 1, -16)
toastLabel.Position = UDim2.new(0, 12, 0, 8)
toastLabel.BackgroundTransparency = 1
toastLabel.Text = ""
toastLabel.TextColor3 = COL_TEXT
toastLabel.TextSize = 13
toastLabel.Font = Enum.Font.Gotham
toastLabel.TextWrapped = true
toastLabel.ZIndex = 21
toastLabel.Parent = toastFrame

local toastToken = 0
local function toast(msg)
	toastToken = toastToken + 1
	local myToken = toastToken
	toastLabel.Text = msg
	toastFrame.Visible = true
	toastFrame.Size = UDim2.new(0, 300, 0, 44)
	toastFrame.BackgroundTransparency = 0
	task.delay(4, function()
		if toastToken == myToken then
			TweenService:Create(toastFrame, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(toastLabel, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
			task.wait(0.32)
			if toastToken == myToken then
				toastFrame.Visible = false
				toastLabel.TextTransparency = 0
			end
		end
	end)
end

-- ===== 按钮 =====
local busy = false

local function setStatus(text, isError)
	statusLabel.Text = text
	statusLabel.TextColor3 = isError and Color3.fromRGB(240, 110, 110) or COL_SUB
end

local function teleport(placeId, name)
	if busy then
		toast("正在传送中，稍等一下…")
		return
	end
	if placeId == game.PlaceId then
		toast("你已经在「" .. name .. "」里了")
		return
	end
	busy = true
	setStatus("正在传送到「" .. name .. "」…")
	toast("正在传送到「" .. name .. "」…")
	task.spawn(function()
		local ok, err = pcall(function()
			TeleportService:Teleport(placeId, LP)
		end)
		if not ok then
			local ok2 = pcall(function()
				TeleportService:TeleportAsync(placeId, { LP })
			end)
			if not ok2 then
				setStatus("传送失败：" .. tostring(err), true)
				toast("传送失败，重试一次或手动加入")
			end
		end
		task.wait(6)
		busy = false
	end)
end

local function makeButton(order, label, subText, color, onClick)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 50)
	btn.BackgroundColor3 = COL_CARD
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = false
	btn.Text = ""
	btn.LayoutOrder = order
	btn.Parent = list

	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 10)
	bc.Parent = btn

	local left = Instance.new("Frame")
	left.Size = UDim2.new(0, 3, 0, 20)
	left.Position = UDim2.new(0, 10, 0.5, -10)
	left.BackgroundColor3 = color
	left.BorderSizePixel = 0
	left.Parent = btn

	local lc = Instance.new("UICorner")
	lc.CornerRadius = UDim.new(1, 0)
	lc.Parent = left

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -50, 0, 18)
	nameLabel.Position = UDim2.new(0, 22, 0, 8)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = label
	nameLabel.TextColor3 = COL_TEXT
	nameLabel.TextSize = 14
	nameLabel.Font = Enum.Font.GothamMedium
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = btn

	local idLabel = Instance.new("TextLabel")
	idLabel.Size = UDim2.new(1, -50, 0, 14)
	idLabel.Position = UDim2.new(0, 22, 0, 27)
	idLabel.BackgroundTransparency = 1
	idLabel.Text = subText
	idLabel.TextColor3 = COL_SUB
	idLabel.TextSize = 11
	idLabel.Font = Enum.Font.Gotham
	idLabel.TextXAlignment = Enum.TextXAlignment.Left
	idLabel.Parent = btn

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = COL_CARD_HL }):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = COL_CARD }):Play()
	end)
	btn.Activated:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.08), { BackgroundColor3 = COL_CARD_HL }):Play()
		task.delay(0.1, function()
			TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = COL_CARD }):Play()
		end)
		onClick()
	end)
	btn.TouchTap:Connect(function()
		onClick()
	end)

	return btn
end

for i, p in ipairs(PLACES) do
	local isHere = (game.PlaceId == p.PlaceId)
	makeButton(i, (isHere and "● " or "") .. p.Name, "PlaceID " .. p.PlaceId, isHere and COL_ACCENT or Color3.fromRGB(90, 96, 112), function()
		teleport(p.PlaceId, p.Name)
	end)
end

-- 返回主游戏（查到 rootPlaceId 才显示）
local backBtn = makeButton(100, "返回主游戏（当前版本）", "自动查询主服务器…", Color3.fromRGB(110, 200, 140), function()
	if rootPlaceId then
		teleport(rootPlaceId, "主游戏")
	else
		toast("暂时查不到主服务器地址，重新执行脚本再试")
	end
end)

-- 重进当前服务器
makeButton(101, "重进当前服务器", "PlaceID " .. game.PlaceId, Color3.fromRGB(120, 150, 230), function()
	toast("正在重新加入当前服务器…")
	pcall(function()
		TeleportService:Teleport(game.PlaceId, LP)
	end)
end)

-- rootPlaceId 查到了就更新返回按钮副标题
task.spawn(function()
	for _ = 1, 20 do
		if rootPlaceId then
			local labels = backBtn:GetChildren()
			for _, child in ipairs(labels) do
				if child:IsA("TextLabel") and child.TextSize == 11 then
					child.Text = "PlaceID " .. rootPlaceId
				end
			end
			break
		end
		task.wait(0.5)
	end
end)

-- ===== 拖动 =====
local dragging = false
local dragStart = nil
local startPos = nil

bar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = win.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not dragging then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		local delta = input.Position - dragStart
		win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

-- ===== 折叠 =====
local folded = false
foldBtn.Activated:Connect(function()
	folded = not folded
	if folded then
		body.Visible = false
		TweenService:Create(win, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { Size = UDim2.new(0, 320, 0, 64) }):Play()
		foldBtn.Text = "+"
	else
		TweenService:Create(win, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { Size = UDim2.new(0, 320, 0, 448) }):Play()
		task.wait(0.1)
		body.Visible = true
		foldBtn.Text = "−"
	end
end)

setStatus("当前 PlaceID：" .. game.PlaceId .. "　选一个旧服务器传送")
