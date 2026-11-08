-- Blade Ball 格挡调用学习器 V2
-- 作用：录下游戏自己发格挡时用的「远程名 + 真实参数」，用来还原正确调用
-- V2：全自动复制，不需要点任何按钮
-- 用法：loadstring(game:HttpGet("https://raw.githubusercontent.com/78589wlg/baby-script/main/BB_Learn.lua?v=2"))()

local RS = game:GetService("ReplicatedStorage")
local WS = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local P = game:GetService("Players")
local LP = P.LocalPlayer

-- 剪贴板兼容（不同执行器函数名不同）
local function copyToClip(t)
	if type(t) ~= "string" or t == "" then return false end
	if setclipboard then
		local ok = pcall(setclipboard, t)
		if ok then return true end
	end
	if toclipboard then
		local ok = pcall(toclipboard, t)
		if ok then return true end
	end
	if Clipboard and Clipboard.set then
		local ok = pcall(function() Clipboard.set(t) end)
		if ok then return true end
	end
	return false
end

-- 启动即验证剪贴板
local clipOK = copyToClip("BB_Learn 已启动｜请手动格挡 2~3 次，内容会自动写入剪贴板")

local log = {}
local MAX = 60
local dirty = false

local function push(s)
	log[#log + 1] = s
	if #log > MAX then table.remove(log, 1) end
	dirty = true
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

-- 环境快照
do
	local rm = RS:FindFirstChild("Remotes")
	local pa = rm and rm:FindFirstChild("ParryAttempt")
	local folder = WS:FindFirstChild("Balls")
	push("== 环境 ==")
	push("ParryAttempt = " .. (pa and "存在" or "不存在"))
	push("Balls 文件夹 = " .. (folder and ("存在，" .. #folder:GetChildren() .. " 个球") or "不存在"))
	push("Alive 文件夹 = " .. (WS:FindFirstChild("Alive") and "存在" or "不存在"))
	push("执行器 = " .. tostring(identifyexecutor and identifyexecutor() or "未知"))
	push("剪贴板 = " .. (clipOK and "可用" or "不可用"))
	push("")
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

-- 按键 / 鼠标
pcall(function()
	UIS.InputBegan:Connect(function(input, gp)
		if gp then return end
		push("[按] " .. tostring(input.UserInputType) .. " / " .. tostring(input.KeyCode))
	end)
end)

-- 服务端回包
pcall(function()
	task.spawn(function()
		local rm = RS:WaitForChild("Remotes", 20)
		if not rm then return end
		for _, n in ipairs({ "ParrySuccess", "ParrySuccessAll", "TimesParriedUpdate", "VisualCD", "UnParry", "SetParryType" }) do
			local ev = rm:FindFirstChild(n)
			if ev and ev:IsA("RemoteEvent") then
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
local parent
if gethui then
	local ok, h = pcall(gethui)
	if ok and h then parent = h end
end
if not parent then
	local ok, cg = pcall(function() return game:GetService("CoreGui") end)
	if ok and cg then parent = cg end
end
if not parent then parent = LP:WaitForChild("PlayerGui") end

local sg = Instance.new("ScreenGui")
sg.Name = "BBLearnGUI"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.DisplayOrder = 999
sg.Parent = parent

local fr = Instance.new("Frame")
fr.Size = UDim2.new(0, 560, 0, 440)
fr.Position = UDim2.new(0.5, -280, 0.5, -220)
fr.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
fr.BorderSizePixel = 0
fr.Parent = sg
local c1 = Instance.new("UICorner") c1.CornerRadius = UDim.new(0, 10) c1.Parent = fr
local st = Instance.new("UIStroke") st.Color = Color3.fromRGB(80, 180, 255) st.Thickness = 1.5 st.Parent = fr

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -140, 0, 34)
title.Position = UDim2.new(0, 14, 0, 8)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextColor3 = Color3.fromRGB(120, 220, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = hooked and "学习中｜手动格挡 2~3 次，自动复制" or "hook 失败：执行器不支持"
title.Parent = fr

local xBtn = Instance.new("TextButton")
xBtn.Size = UDim2.new(0, 30, 0, 30)
xBtn.Position = UDim2.new(1, -40, 0, 8)
xBtn.BackgroundColor3 = Color3.fromRGB(190, 55, 55)
xBtn.Text = "X"
xBtn.Font = Enum.Font.GothamBold
xBtn.TextSize = 14
xBtn.TextColor3 = Color3.new(1, 1, 1)
xBtn.BorderSizePixel = 0
xBtn.Parent = fr
local c4 = Instance.new("UICorner") c4.CornerRadius = UDim.new(0, 6) c4.Parent = xBtn
xBtn.Activated:Connect(function() sg:Destroy() end)

local tb = Instance.new("TextBox")
tb.Size = UDim2.new(1, -28, 1, -104)
tb.Position = UDim2.new(0, 14, 0, 46)
tb.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
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

-- 大按钮（同时绑 Activated 和 MouseButton1Click，触摸也能点）
local bigBtn = Instance.new("TextButton")
bigBtn.Size = UDim2.new(1, -28, 0, 44)
bigBtn.Position = UDim2.new(0, 14, 1, -50)
bigBtn.BackgroundColor3 = Color3.fromRGB(35, 140, 90)
bigBtn.Text = "点这里复制（不点也会自动复制）"
bigBtn.Font = Enum.Font.GothamBold
bigBtn.TextSize = 15
bigBtn.TextColor3 = Color3.new(1, 1, 1)
bigBtn.BorderSizePixel = 0
bigBtn.Parent = fr
local c5 = Instance.new("UICorner") c5.CornerRadius = UDim.new(0, 8) c5.Parent = bigBtn

local lastClick = 0
local function doCopy()
	if os.clock() - lastClick < 0.4 then return end
	lastClick = os.clock()
	local txt = table.concat(log, "\n")
	local ok = copyToClip(txt)
	title.Text = ok and ("已复制 " .. #log .. " 条，去粘贴吧") or "剪贴板不可用，请手动选中文本框复制"
end
bigBtn.Activated:Connect(doCopy)
bigBtn.MouseButton1Click:Connect(doCopy)

-- 自动同步 + 自动复制
local lastTxt = ""
task.spawn(function()
	while sg.Parent do
		local txt = table.concat(log, "\n")
		if txt ~= lastTxt then
			tb.Text = txt
			if dirty and #log > 0 then
				local ok = copyToClip(txt)
				if ok then
					title.Text = "已自动复制 " .. #log .. " 条｜手动格挡 2~3 次"
				end
				dirty = false
			end
			lastTxt = txt
		end
		task.wait(0.35)
	end
end)
