--[[
    Jandel's Road Trip · 旧服务器传送  v2
    ------------------------------------------------------------
    v2 改动：
      · 传送失败时把真实错误显示在面板上（方便定位问题）
      · 先 TeleportAsync 再 Teleport，双通道重试
      · 每个服务器多一个「复制」按钮，复制游戏链接，传送被拦也能手动进
      · 列表改为固定画布高度，避免部分执行器不支持自动画布导致按钮不显示
]]

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LP = Players.LocalPlayer
local UNIVERSE_ID = 5650396773

local PLACES = {
	{ Name = "圣诞节", PlaceId = 72639813364968 },
	{ Name = "德比", PlaceId = 18369256317 },
	{ Name = "复古", PlaceId = 17584310335 },
	{ Name = "万圣节", PlaceId = 98422814745197 },
	{ Name = "侏罗纪", PlaceId = 118569659995312 },
	{ Name = "怪物卡车（老服务器）", PlaceId = 17527910461 },
}

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

local old = game:GetService("CoreGui"):FindFirstChild("JandelOldServers")
if old then old:Destroy() end

local COL_BG      = Color3.fromRGB(16, 18, 24)
local COL_CARD    = Color3.fromRGB(31, 34, 43)
local COL_CARD_HL = Color3.fromRGB(44, 48, 60)
local COL_ACCENT  = Color3.fromRGB(245, 166, 35)
local COL_TEXT    = Color3.fromRGB(240, 242, 248)
local COL_SUB     = Color3.fromRGB(152, 158, 172)

local gui = Instance.new("ScreenGui")
gui.Name = "JandelOldServers"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
do
	pcall(function() gui.Parent = game:GetService("CoreGui") end)
	if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end
end

local ROW_H, ROW_GAP = 54, 8

local win = Instance.new("Frame")
win.Size = UDim2.new(0, 330, 0, 486)
win.Position = UDim2.new(1, -350, 0.5, -243)
win.BackgroundColor3 = COL_BG
win.BorderSizePixel = 0
win.ClipsDescendants = true
win.Active = true
win.Parent = gui

local winCorner = Instance.new("UICorner")
winCorner.CornerRadius = UDim.new(0, 14)
winCorner.Parent = win

local winStroke = Instance.new("UIStroke")
winStroke.Color = Color3.fromRGB(60, 64, 78)
winStroke.Thickness = 1
winStroke.Parent = win

local bar = Instance.new("Frame")
bar.Size = UDim2.new(1, 0, 0, 64)
bar.BackgroundColor3 = Color3.fromRGB(21, 24, 32)
bar.BorderSizePixel = 0
bar.Parent = win

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, 14)
barCorner.Parent = bar

local barFix = Instance.new("Frame")
barFix.Size = UDim2.new(1, 0, 0, 14)
barFix.Position = UDim2.new(0, 0, 1, -14)
barFix.BackgroundColor3 = Color3.fromRGB(21, 24, 32)
barFix.BorderSizePixel = 0
barFix.Parent = bar

local accent = Instance.new("Frame")
accent.Size = UDim2.new(0, 4, 0, 26)
accent.Position = UDim2.new(0, 16, 0, 19)
accent.BackgroundColor3 = COL_ACCENT
accent.BorderSizePixel = 0
accent.Parent = bar

local accentC = Instance.new("UICorner")
accentC.CornerRadius = UDim.new(1, 0)
accentC.Parent = accent

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

local foldBtn = Instance.new("TextButton")
foldBtn.Size = UDim2.new(0, 30, 0, 30)
foldBtn.Position = UDim2.new(1, -42, 0, 17)
foldBtn.BackgroundColor3 = Color3.fromRGB(36, 40, 50)
foldBtn.Text = "−"
foldBtn.TextColor3 = COL_TEXT
foldBtn.TextSize = 18
foldBtn.Font = Enum.Font.GothamBold
foldBtn.AutoButtonColor = false
foldBtn.Parent = bar

local foldC = Instance.new("UICorner")
foldC.CornerRadius = UDim.new(0, 8)
foldC.Parent = foldBtn

local body = Instance.new("Frame")
body.Size = UDim2.new(1, 0, 1, -64)
body.Position = UDim2.new(0, 0, 0, 64)
body.BackgroundTransparency = 1
body.Parent = win

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -32, 0, 46)
status.Position = UDim2.new(0, 16, 0, 6)
status.BackgroundTransparency = 1
status.Text = "当前 PlaceID：" .. game.PlaceId
status.TextColor3 = COL_SUB
status.TextSize = 11
status.Font = Enum.Font.Gotham
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextYAlignment = Enum.TextYAlignment.Top
status.TextWrapped = true
status.Parent = body

local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(1, -24, 1, -64 - 52 - 34)
list.Position = UDim2.new(0, 12, 0, 56)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 3
list.ScrollBarImageColor3 = Color3.fromRGB(70, 74, 88)
list.CanvasSize = UDim2.new(0, 0, 0, 0)
list.Parent = body

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, ROW_GAP)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local note = Instance.new("TextLabel")
note.Size = UDim2.new(1, -32, 0, 30)
note.Position = UDim2.new(0, 0, 1, -34)
note.BackgroundTransparency = 1
note.Text = "传送卡加载就重进；各旧服进度不互通"
note.TextColor3 = Color3.fromRGB(108, 114, 128)
note.TextSize = 11
note.Font = Enum.Font.Gotham
note.TextWrapped = true
note.TextXAlignment = Enum.TextXAlignment.Center
note.Parent = body

-- ===== 提示气泡 =====
local toastFrame = Instance.new("Frame")
toastFrame.Size = UDim2.new(0, 310, 0, 52)
toastFrame.Position = UDim2.new(0.5, -155, 1, -96)
toastFrame.BackgroundColor3 = Color3.fromRGB(28, 31, 40)
toastFrame.BorderSizePixel = 0
toastFrame.Visible = false
toastFrame.ZIndex = 20
toastFrame.Parent = gui

local toastC = Instance.new("UICorner")
toastC.CornerRadius = UDim.new(0, 10)
toastC.Parent = toastFrame

local toastLabel = Instance.new("TextLabel")
toastLabel.Size = UDim2.new(1, -24, 1, -14)
toastLabel.Position = UDim2.new(0, 12, 0, 7)
toastLabel.BackgroundTransparency = 1
toastLabel.Text = ""
toastLabel.TextColor3 = COL_TEXT
toastLabel.TextSize = 12
toastLabel.Font = Enum.Font.Gotham
toastLabel.TextWrapped = true
toastLabel.ZIndex = 21
toastLabel.Parent = toastFrame

local toastToken = 0
local function toast(msg)
	toastToken = toastToken + 1
	local my = toastToken
	toastLabel.Text = msg
	toastLabel.TextTransparency = 0
	toastFrame.BackgroundTransparency = 0
	toastFrame.Visible = true
	task.delay(6, function()
		if toastToken ~= my then return end
		TweenService:Create(toastFrame, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(toastLabel, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
		task.wait(0.32)
		if toastToken == my then
			toastFrame.Visible = false
		end
	end)
end

local function setStatus(text, isError)
	status.Text = text
	status.TextColor3 = isError and Color3.fromRGB(240, 105, 105) or COL_SUB
end

-- ===== 传送 =====
local busy = false
local function teleport(placeId, name)
	if busy then
		toast("正在传送中，等一下…")
		return
	end
	if placeId == game.PlaceId then
		toast("你已经在「" .. name .. "」里了")
		return
	end
	if not placeId or placeId == 0 then
		toast("这个入口还没查到地址，重新执行脚本试试")
		return
	end
	busy = true
	setStatus("正在传送到「" .. name .. "」…\nPlaceID " .. placeId)
	toast("正在传送… 10 秒没反应就看面板红字")

	task.spawn(function()
		local errText = nil
		local okA, errA = pcall(function()
			TeleportService:TeleportAsync(placeId, { LP })
		end)
		if not okA then
			errText = tostring(errA)
			local okB, errB = pcall(function()
				TeleportService:Teleport(placeId, LP)
			end)
			if okB then
				errText = nil
			else
				errText = errText .. " | " .. tostring(errB)
			end
		end

		task.wait(10)
		if busy then
			busy = false
			setStatus(
				"传送没有生效。\n"
					.. "当前 PlaceID：" .. game.PlaceId .. "（要在主游戏里执行）\n"
					.. "→ 点右边「复制」，用浏览器/Roblox 打开链接手动进"
					.. (errText and ("\n[报错] " .. errText) or ""),
				true
			)
			toast("传送失败：点「复制」拿链接手动进")
		end
	end)
end

-- ===== 复制链接 =====
local function copyLink(placeId)
	local link = "https://www.roblox.com/games/" .. placeId
	local ok = pcall(function()
		setclipboard(link)
	end)
	if ok then
		toast("已复制：" .. link)
	else
		toast("复制失败，手动记下：" .. link)
	end
end

-- ===== 列表行 =====
local function makeRow(order, name, placeId, accentColor, isHere, customAction)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, ROW_H)
	row.BackgroundColor3 = COL_CARD
	row.BorderSizePixel = 0
	row.LayoutOrder = order
	row.Parent = list

	local rc = Instance.new("UICorner")
	rc.CornerRadius = UDim.new(0, 10)
	rc.Parent = row

	local tap = Instance.new("TextButton")
	tap.Name = "Tap"
	tap.Size = UDim2.new(1, -70, 1, 0)
	tap.BackgroundTransparency = 1
	tap.Text = ""
	tap.AutoButtonColor = false
	tap.ZIndex = 2
	tap.Parent = row

	local left = Instance.new("Frame")
	left.Size = UDim2.new(0, 3, 0, 20)
	left.Position = UDim2.new(0, 10, 0.5, -10)
	left.BackgroundColor3 = accentColor
	left.BorderSizePixel = 0
	left.Parent = row

	local lc = Instance.new("UICorner")
	lc.CornerRadius = UDim.new(1, 0)
	lc.Parent = left

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -126, 0, 18)
	nameLabel.Position = UDim2.new(0, 22, 0, 9)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = (isHere and "● " or "") .. name
	nameLabel.TextColor3 = COL_TEXT
	nameLabel.TextSize = 14
	nameLabel.Font = Enum.Font.GothamMedium
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = row

	local idLabel = Instance.new("TextLabel")
	idLabel.Size = UDim2.new(1, -126, 0, 14)
	idLabel.Position = UDim2.new(0, 22, 0, 28)
	idLabel.BackgroundTransparency = 1
	idLabel.Text = placeId ~= 0 and ("PlaceID " .. placeId) or "自动查询"
	idLabel.TextColor3 = COL_SUB
	idLabel.TextSize = 10
	idLabel.Font = Enum.Font.Gotham
	idLabel.TextXAlignment = Enum.TextXAlignment.Left
	idLabel.Parent = row

	local copyBtn = Instance.new("TextButton")
	copyBtn.Size = UDim2.new(0, 54, 0, 30)
	copyBtn.Position = UDim2.new(1, -62, 0.5, -15)
	copyBtn.BackgroundColor3 = Color3.fromRGB(44, 48, 60)
	copyBtn.Text = "复制"
	copyBtn.TextColor3 = COL_SUB
	copyBtn.TextSize = 12
	copyBtn.Font = Enum.Font.GothamMedium
	copyBtn.AutoButtonColor = false
	copyBtn.ZIndex = 3
	copyBtn.Parent = row

	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(0, 8)
	cc.Parent = copyBtn

	local lastTap = 0
	tap.Activated:Connect(function()
		if os.clock() - lastTap < 0.8 then return end
		lastTap = os.clock()
		TweenService:Create(row, TweenInfo.new(0.08), { BackgroundColor3 = COL_CARD_HL }):Play()
		task.delay(0.12, function()
			TweenService:Create(row, TweenInfo.new(0.15), { BackgroundColor3 = COL_CARD }):Play()
		end)
		if customAction then
			customAction()
		else
			teleport(placeId, name)
		end
	end)

	copyBtn.MouseButton1Click:Connect(function()
		if customAction and placeId == 0 then
			toast("主游戏地址查询中…")
			return
		end
		copyLink(placeId)
	end)

	return row, copyBtn, idLabel
end

for i, p in ipairs(PLACES) do
	makeRow(i, p.Name, p.PlaceId, (game.PlaceId == p.PlaceId) and COL_ACCENT or Color3.fromRGB(92, 98, 114), game.PlaceId == p.PlaceId, nil)
end

local backRow, backCopy, backId = makeRow(100, "返回主游戏（当前版本）", 0, Color3.fromRGB(110, 200, 140), false, function()
	if rootPlaceId then
		teleport(rootPlaceId, "主游戏")
	else
		toast("暂时查不到主游戏地址，稍后再点或重进脚本")
	end
end)

makeRow(101, "重进当前服务器", game.PlaceId, Color3.fromRGB(120, 150, 230), true, function()
	toast("正在重新加入当前服务器…")
	task.spawn(function()
		pcall(function()
			TeleportService:Teleport(game.PlaceId, LP)
		end)
	end)
end)

list.CanvasSize = UDim2.new(0, 0, 0, (ROW_H + ROW_GAP) * 8 + 6)

-- 根地址查到了就更新那一行
task.spawn(function()
	for _ = 1, 30 do
		if rootPlaceId then
			backId.Text = "PlaceID " .. rootPlaceId
			return
		end
		task.wait(0.5)
	end
	backId.Text = "查询失败（点复制无效）"
end)

-- ===== 折叠 =====
local folded = false
foldBtn.MouseButton1Click:Connect(function()
	folded = not folded
	if folded then
		body.Visible = false
		TweenService:Create(win, TweenInfo.new(0.18), { Size = UDim2.new(0, 330, 0, 64) }):Play()
		foldBtn.Text = "+"
	else
		TweenService:Create(win, TweenInfo.new(0.18), { Size = UDim2.new(0, 330, 0, 486) }):Play()
		task.wait(0.1)
		body.Visible = true
		foldBtn.Text = "−"
	end
end)

-- ===== 拖动 =====
local dragging, dragStart, startPos = false, nil, nil
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
		local d = input.Position - dragStart
		win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end
end)
