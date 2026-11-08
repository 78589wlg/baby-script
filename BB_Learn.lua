-- Blade Ball 格挡调用学习器 V3
-- V3：面板缩成右上角小胶囊，不挡点击；自动复制；实时显示球数
-- 用法：loadstring(game:HttpGet("https://raw.githubusercontent.com/78589wlg/baby-script/main/BB_Learn.lua?v=3"))()

local RS = game:GetService("ReplicatedStorage")
local WS = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local P = game:GetService("Players")
local LP = P.LocalPlayer

local function copyToClip(t)
	if type(t) ~= "string" or t == "" then return false end
	if setclipboard then
		if pcall(setclipboard, t) then return true end
	end
	if toclipboard then
		if pcall(toclipboard, t) then return true end
	end
	return false
end

local clipOK = copyToClip("BB_Learn 已启动")

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

local rm = RS:FindFirstChild("Remotes")
local pa = rm and rm:FindFirstChild("ParryAttempt")
push("== 环境 ==")
push("ParryAttempt = " .. (pa and "存在" or "不存在"))
push("执行器 = Delta｜剪贴板 = " .. (clipOK and "可用" or "不可用"))
push("")

local hooked = false
pcall(function()
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

-- 按键 / 触摸（不再丢弃 gp，反而要标出来）
pcall(function()
	UIS.InputBegan:Connect(function(input, gp)
		push("[按] " .. tostring(input.UserInputType) .. " gp=" .. tostring(gp))
	end)
end)

pcall(function()
	task.spawn(function()
		local r = RS:WaitForChild("Remotes", 20)
		if not r then return end
		for _, n in ipairs({ "ParrySuccess", "ParrySuccessAll", "TimesParriedUpdate", "VisualCD", "UnParry" }) do
			local ev = r:FindFirstChild(n)
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

-- ================= 界面 =================
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

-- ---- 小胶囊（默认显示，右上角，不挡操作）----
local pill = Instance.new("TextButton")
pill.Size = UDim2.new(0, 200, 0, 42)
pill.Position = UDim2.new(1, -212, 0, 96)
pill.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
pill.BackgroundTransparency = 0.08
pill.Text = "记录 0 条｜局外"
pill.Font = Enum.Font.GothamBold
pill.TextSize = 13
pill.TextColor3 = Color3.fromRGB(120, 220, 255)
pill.BorderSizePixel = 0
pill.AutoButtonColor = true
pill.Parent = sg
local pc1 = Instance.new("UICorner") pc1.CornerRadius = UDim.new(0, 21) pc1.Parent = pill
local pst = Instance.new("UIStroke") pst.Color = Color3.fromRGB(80, 180, 255) pst.Thickness = 1.2 pst.Parent = pill

-- ---- 大面板（默认隐藏）----
local fr = Instance.new("Frame")
fr.Size = UDim2.new(0, 540, 0, 400)
fr.Position = UDim2.new(0.5, -270, 0.5, -200)
fr.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
fr.BorderSizePixel = 0
fr.Visible = false
fr.Parent = sg
local c1 = Instance.new("UICorner") c1.CornerRadius = UDim.new(0, 10) c1.Parent = fr
local st = Instance.new("UIStroke") st.Color = Color3.fromRGB(80, 180, 255) st.Thickness = 1.5 st.Parent = fr

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -160, 0, 34)
title.Position = UDim2.new(0, 14, 0, 8)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextColor3 = Color3.fromRGB(120, 220, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = hooked and "记录中｜自动复制" or "hook 失败"
title.Parent = fr

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 90, 0, 30)
closeBtn.Position = UDim2.new(1, -104, 0, 8)
closeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
closeBtn.Text = "收起"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 13
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.BorderSizePixel = 0
closeBtn.Parent = fr
local c4 = Instance.new("UICorner") c4.CornerRadius = UDim.new(0, 6) c4.Parent = closeBtn

local tb = Instance.new("TextBox")
tb.Size = UDim2.new(1, -28, 1, -96)
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

local copyBtn = Instance.new("TextButton")
copyBtn.Size = UDim2.new(1, -28, 0, 40)
copyBtn.Position = UDim2.new(0, 14, 1, -48)
copyBtn.BackgroundColor3 = Color3.fromRGB(35, 140, 90)
copyBtn.Text = "复制（也会自动复制）"
copyBtn.Font = Enum.Font.GothamBold
copyBtn.TextSize = 14
copyBtn.TextColor3 = Color3.new(1, 1, 1)
copyBtn.BorderSizePixel = 0
copyBtn.Parent = fr
local c5 = Instance.new("UICorner") c5.CornerRadius = UDim.new(0, 8) c5.Parent = copyBtn

-- 事件：优先 Activated（触摸/鼠标都触发）
local function bind(btn, fn)
	local busy = false
	local function run()
		if busy then return end
		busy = true
		pcall(fn)
		task.delay(0.35, function() busy = false end)
	end
	pcall(function() btn.Activated:Connect(run) end)
	pcall(function() btn.MouseButton1Click:Connect(run) end)
end

bind(pill, function()
	fr.Visible = true
	pill.Visible = false
end)

bind(closeBtn, function()
	fr.Visible = false
	pill.Visible = true
end)

bind(copyBtn, function()
	local ok = copyToClip(table.concat(log, "\n"))
	title.Text = ok and ("已复制 " .. #log .. " 条") or "剪贴板不可用"
end)

-- 自动同步 + 自动复制 + 球数提示
local lastTxt = ""
task.spawn(function()
	while sg.Parent do
		local txt = table.concat(log, "\n")
		if txt ~= lastTxt then
			tb.Text = txt
			if dirty and #log > 0 then
				if copyToClip(txt) then dirty = false end
			end
			lastTxt = txt
		end

		local folder = WS:FindFirstChild("Balls")
		local n = folder and #folder:GetChildren() or 0
		pill.Text = "记录 " .. #log .. " 条｜" .. (n > 0 and ("局内 " .. n .. " 球") or "局外") .. "｜点开"
		pill.TextColor3 = n > 0 and Color3.fromRGB(120, 255, 170) or Color3.fromRGB(255, 180, 90)

		task.wait(0.35)
	end
end)

