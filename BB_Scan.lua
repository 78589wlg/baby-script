-- Blade Ball 结构探测（一次性诊断，不修改游戏）
-- 用法：loadstring(game:HttpGet("https://raw.githubusercontent.com/78589wlg/baby-script/main/BB_Scan.lua?v=1"))()

local RS = game:GetService("ReplicatedStorage")
local WS = game:GetService("Workspace")
local P = game:GetService("Players")
local LP = P.LocalPlayer

local L = {}
local function add(s) L[#L + 1] = s end

-- 1. 所有远程
add("===== 1. ReplicatedStorage 远程 =====")
local cnt = 0
pcall(function()
	for _, d in ipairs(RS:GetDescendants()) do
		local c = d.ClassName
		if c == "RemoteEvent" or c == "UnreliableRemoteEvent" or c == "RemoteFunction" then
			cnt = cnt + 1
			if cnt <= 100 then
				add(d:GetFullName() .. "  <" .. c .. ">")
			end
		end
	end
end)
add("-- 共 " .. cnt .. " 个" .. (cnt > 100 and "（仅显示前 100）" or ""))

-- 2. 疑似球
add("")
add("===== 2. 名字含 ball / orb 的对象 =====")
local bc = 0
pcall(function()
	for _, d in ipairs(WS:GetDescendants()) do
		local nm = string.lower(d.Name)
		if string.find(nm, "ball", 1, true) or string.find(nm, "orb", 1, true) then
			bc = bc + 1
			if bc <= 30 then
				add(d:GetFullName() .. "  <" .. d.ClassName .. ">")
				local ok, at = pcall(function() return d:GetAttributes() end)
				if ok and at then
					for k, v in pairs(at) do
						add("    @" .. k .. " = " .. tostring(v))
					end
				end
			end
		end
	end
end)
add("-- 共 " .. bc .. " 个")

-- 3. 结构
add("")
add("===== 3. ReplicatedStorage 顶层 =====")
pcall(function()
	for _, d in ipairs(RS:GetChildren()) do
		add("  " .. d.Name .. "  <" .. d.ClassName .. ">")
	end
end)

add("")
add("===== 4. Workspace 顶层 =====")
pcall(function()
	for _, d in ipairs(WS:GetChildren()) do
		add("  " .. d.Name .. "  <" .. d.ClassName .. ">")
	end
end)

-- 4. 角色
add("")
add("===== 5. 你的角色 =====")
local ch = LP.Character
if ch then
	local n = 0
	for _, d in ipairs(ch:GetDescendants()) do
		n = n + 1
		if n <= 60 then add("  " .. d.Name .. "  <" .. d.ClassName .. ">") end
	end
	add("-- 共 " .. n .. " 个")
else
	add("  （角色还没出生，等进游戏后再跑一次）")
end

-- 5. 环境
add("")
add("===== 6. 环境 =====")
add("  PlaceId = " .. tostring(game.PlaceId))
add("  JobId = " .. tostring(game.JobId))
add("  执行器 = " .. tostring(identifyexecutor and identifyexecutor() or "未知"))
local okName, name = pcall(function()
	return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
end)
add("  游戏名 = " .. (okName and tostring(name) or "读取失败"))

-- 输出
local txt = table.concat(L, "\n")
if setclipboard then pcall(setclipboard, txt) end

local parent = (gethui and gethui()) or LP:WaitForChild("PlayerGui")
local sg = Instance.new("ScreenGui")
sg.Name = "BBScanGUI"
sg.ResetOnSpawn = false
sg.DisplayOrder = 999
sg.Parent = parent

local fr = Instance.new("Frame")
fr.Size = UDim2.new(0, 540, 0, 500)
fr.Position = UDim2.new(0.5, -270, 0.5, -250)
fr.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
fr.BorderSizePixel = 0
fr.Parent = sg
local cor = Instance.new("UICorner")
cor.CornerRadius = UDim.new(0, 10)
cor.Parent = fr

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 0, 40)
title.Position = UDim2.new(0, 14, 0, 6)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.TextColor3 = Color3.fromRGB(120, 220, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "结构探测结果｜已尝试复制到剪贴板"
title.Parent = fr

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 32, 0, 32)
close.Position = UDim2.new(1, -42, 0, 8)
close.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
close.Text = "X"
close.Font = Enum.Font.GothamBold
close.TextSize = 14
close.TextColor3 = Color3.new(1, 1, 1)
close.BorderSizePixel = 0
close.Parent = fr
local c2 = Instance.new("UICorner")
c2.CornerRadius = UDim.new(0, 6)
c2.Parent = close
close.MouseButton1Click:Connect(function() sg:Destroy() end)

local tb = Instance.new("TextBox")
tb.Size = UDim2.new(1, -24, 1, -84)
tb.Position = UDim2.new(0, 12, 0, 44)
tb.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
tb.TextColor3 = Color3.fromRGB(220, 220, 220)
tb.PlaceholderText = ""
tb.Font = Enum.Font.Code
tb.TextSize = 12
tb.MultiLine = true
tb.TextWrapped = true
tb.TextEditable = false
tb.ClearTextOnFocus = false
tb.TextXAlignment = Enum.TextXAlignment.Left
tb.TextYAlignment = Enum.TextYAlignment.Top
tb.Text = txt
tb.Parent = fr
local c3 = Instance.new("UICorner")
c3.CornerRadius = UDim.new(0, 8)
c3.Parent = tb

local tip = Instance.new("TextLabel")
tip.Size = UDim2.new(1, -24, 0, 28)
tip.Position = UDim2.new(0, 12, 1, -34)
tip.BackgroundTransparency = 1
tip.Font = Enum.Font.Gotham
tip.TextSize = 12
tip.TextColor3 = Color3.fromRGB(160, 160, 170)
tip.TextXAlignment = Enum.TextXAlignment.Left
tip.Text = "复制不了就点文本框 → Ctrl+A → Ctrl+C，把内容发我"
tip.Parent = fr
