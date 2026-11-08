-- Blade Ball 格挡调用学习器
-- 作用：录下游戏自己发格挡时用的「远程名 + 真实参数」，用来还原正确调用
-- 用法：loadstring(game:HttpGet("https://raw.githubusercontent.com/78589wlg/baby-script/main/BB_Learn.lua?v=1"))()

local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local P = game:GetService("Players")
local LP = P.LocalPlayer

local log = {}
local MAX = 60

local function push(s)
	log[#log + 1] = s
	if #log > MAX then table.remove(log, 1) end
end

local function dump(v, d)
	d = d or 0
	local t = typeof(v)
	if t == "Vector3" then
		return string.format("V3(%.1f,%.1f,%.1f)", v.X, v.Y, v.Z)
	elseif t == "Vector2" then
		return string.format("V2(%.1f,%.1f)", v.X, v.Y)
	elseif t == "CFrame" then
		local p = v.Position
		return string.format("CF(%.1f,%.1f,%.1f)", p.X, p.Y, p.Z)
	elseif t == "table" then
		if d >= 2 then return "{..}" end
		local parts, n = {}, 0
		for k, val in pairs(v) do
			n = n + 1
			if n > 10 then parts[#parts + 1] = "..." break end
			parts[#parts + 1] = tostring(k) .. "=" .. dump(val, d + 1)
		end
		return "{" .. table.concat(parts, ", ") .. "}"
	elseif t == "Instance" then
		local ok, n2 = pcall(function() return v:GetFullName() end)
		return ok and n2 or v.ClassName
	elseif t == "string" then
		if #v > 30 then v = v:sub(1, 30) .. "…" end
		return '"' .. v .. '"'
	elseif t == "boolean" or t == "number" then
		return tostring(v)
	else
		return "<" .. t .. ">"
	end
end

local function interesting(name)
	local n = string.lower(name)
	if not string.find(n, "remotes", 1, true) then return false end
	for _, k in ipairs({ "parry", "unparry", "setparry", "deflect", "block" }) do
		if string.find(n, k, 1, true) then return true end
	end
	return false
end

local hooked = false
local okHook = pcall(function()
	local old
	old = hookmetamethod(game, "__namecall", function(self, ...)
		local m = getnamecallmethod()
		if m == "FireServer" or m == "InvokeServer" then
			local ok, name = pcall(function() return self:GetFullName() end)
			if ok and name and interesting(name) then
				local args = table.pack(...)
				local strs = {}
				for i = 1, args.n do
					strs[#strs + 1] = dump(args[i])
				end
				push("[发] " .. name .. " (" .. table.concat(strs, ", ") .. ")")
			end
		end
		return old(self, ...)
	end)
	hooked = true
end)

-- 记录按键 / 鼠标
pcall(function()
	UIS.InputBegan:Connect(function(input, gp)
		if gp then return end
		local it = tostring(input.UserInputType)
		local kc = tostring(input.KeyCode)
		push("[按] " .. it .. " / " .. kc)
	end)
end)

-- 记录游戏下发的格挡反馈
pcall(function()
	task.spawn(function()
		local rm = RS:WaitForChild("Remotes", 20)
		if not rm then return end
		for _, n in ipairs({ "ParrySuccess", "ParrySuccessAll", "TimesParriedUpdate", "VisualCD", "UnParry" }) do
			local ev = rm:FindFirstChild(n)
			if ev then
				ev.OnClientEvent:Connect(function(...)
					local args = table.pack(...)
					local strs = {}
					for i = 1, math.min(args.n, 6) do
						strs[#strs + 1] = dump(args[i])
					end
					push("[收] " .. n .. " (" .. table.concat(strs, ", ") .. ")")
				end)
			end
		end
	end)
end)

-- 界面
local parent = (gethui and gethui()) or LP:WaitForChild("PlayerGui")
local sg = Instance.new("ScreenGui")
sg.Name = "BBLearnGUI"
sg.ResetOnSpawn = false
sg.DisplayOrder = 998
sg.Parent = parent

local fr = Instance.new("Frame")
fr.Size = UDim2.new(0, 560, 0, 420)
fr.Position = UDim2.new(0.5, -280, 0, 40)
fr.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
fr.BorderSizePixel = 0
fr.Parent = sg
local c1 = Instance.new("UICorner") c1.CornerRadius = UDim.new(0, 10) c1.Parent = fr

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 34)
title.Position = UDim2.new(0, 12, 0, 6)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextColor3 = Color3.fromRGB(120, 220, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = hooked and "学习中｜现在手动格挡 2~3 次" or "hook 失败（执行器不支持）"
title.Parent = fr

local tb = Instance.new("TextBox")
tb.Size = UDim2.new(1, -24, 1, -96)
tb.Position = UDim2.new(0, 12, 0, 42)
tb.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
tb.TextColor3 = Color3.fromRGB(210, 220, 225)
tb.Font = Enum.Font.Code
tb.TextSize = 12
tb.MultiLine = true
tb.TextWrapped = true
tb.TextEditable = false
tb.ClearTextOnFocus = false
tb.TextXAlignment = Enum.TextXAlignment.Left
tb.TextYAlignment = Enum.TextYAlignment.Bottom
tb.Text = ""
tb.Parent = fr
local c2 = Instance.new("UICorner") c2.CornerRadius = UDim.new(0, 8) c2.Parent = tb

local function btn(text, x, color, cb)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, 110, 0, 30)
	b.Position = UDim2.new(0, x, 1, -40)
	b.BackgroundColor3 = color
	b.Text = text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 13
	b.TextColor3 = Color3.new(1, 1, 1)
	b.BorderSizePixel = 0
	b.Parent = fr
	local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = b
	b.MouseButton1Click:Connect(cb)
	return b
end

btn("复制全部", 12, Color3.fromRGB(40, 130, 220), function()
	if setclipboard then setclipboard(table.concat(log, "\n")) end
	title.Text = "已复制 " .. #log .. " 条"
end)
btn("清空", 130, Color3.fromRGB(90, 90, 100), function()
	log = {}
	title.Text = "已清空"
end)
btn("关闭", 248, Color3.fromRGB(200, 60, 60), function()
	sg:Destroy()
end)

task.spawn(function()
	while sg.Parent do
		tb.Text = table.concat(log, "\n")
		task.wait(0.4)
	end
end)
