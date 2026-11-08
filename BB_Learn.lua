-- Blade Ball 格挡调用学习器 V5
-- 记录 Remotes 下所有 FireServer（聚合计数，不刷屏）
-- 只显示「自己的」格挡成功，别人的一串不记
-- 用法：loadstring(game:HttpGet("https://raw.githubusercontent.com/78589wlg/baby-script/main/BB_Learn.lua?v=5"))()

local RS = game:GetService("ReplicatedStorage")
local WS = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local P = game:GetService("Players")
local LP = P.LocalPlayer

local function copyToClip(t)
	if type(t) ~= "string" or t == "" then return false end
	if setclipboard then if pcall(setclipboard, t) then return true end end
	if toclipboard then if pcall(toclipboard, t) then return true end end
	return false
end

local clipOK = copyToClip("BB_Learn V5 已启动")

local log = {}
local MAX = 40
local dirty = false
local mySuccess = 0
local touchN, touchGp = 0, 0
local SelfTest = nil

local function push(s)
	log[#log + 1] = s
	if #log > MAX then table.remove(log, 1) end
	dirty = true
end

local function dump(v, d)
	d = d or 0
	local t = typeof(v)
	if t == "Vector3" then
		return string.format("V3(%.0f,%.0f,%.0f)", v.X, v.Y, v.Z)
	elseif t == "Vector2" then
		return string.format("V2(%.0f,%.0f)", v.X, v.Y)
	elseif t == "CFrame" then
		local p = v.Position
		return string.format("CF(%.0f,%.0f,%.0f)", p.X, p.Y, p.Z)
	elseif t == "table" then
		if d >= 1 then return "{..}" end
		local parts, n = {}, 0
		for k, val in pairs(v) do
			n = n + 1
			if n > 6 then parts[#parts + 1] = "..." break end
			parts[#parts + 1] = tostring(k) .. "=" .. dump(val, d + 1)
		end
		return "{" .. table.concat(parts, ", ") .. "}"
	elseif t == "Instance" then
		local ok, n2 = pcall(function() return v:GetFullName() end)
		return ok and n2 or v.ClassName
	elseif t == "string" then
		if #v > 24 then v = v:sub(1, 24) .. "…" end
		return '"' .. v .. '"'
	elseif t == "boolean" or t == "number" then
		return tostring(v)
	else
		return "<" .. t .. ">"
	end
end

local rm = RS:FindFirstChild("Remotes")
local pa = rm and rm:FindFirstChild("ParryAttempt")

-- 聚合计数：远程名 -> {n, sample}
local fireStat, fireOrder = {}, {}

local function noteFire(name, argsStr)
	local s = fireStat[name]
	if not s then
		s = { n = 0, sample = argsStr }
		fireStat[name] = s
		fireOrder[#fireOrder + 1] = name
	end
	s.n = s.n + 1
	dirty = true
end

local hooked = false
pcall(function()
	local old
	old = hookmetamethod(game, "__namecall", function(self, ...)
		local m = getnamecallmethod()
		if m == "FireServer" or m == "InvokeServer" then
			local ok, name = pcall(function() return self:GetFullName() end)
			if ok and name and string.find(string.lower(name), "remotes", 1, true) then
				local args = table.pack(...)
				local strs = {}
				for i = 1, math.min(args.n, 6) do
					strs[#strs + 1] = dump(args[i])
				end
				noteFire(name, table.concat(strs, ", "))
				if SelfTest and self == SelfTest then
					push("[自检] 抓到自己发的 ParryAttempt → hook 正常")
				end
			end
		end
		return old(self, ...)
	end)
	hooked = true
end)

-- 点击记录（只记次数）
pcall(function()
	UIS.InputBegan:Connect(function(input, gp)
		touchN = touchN + 1
		if gp then touchGp = touchGp + 1 end
		dirty = true
	end)
end)

-- 只关心「自己」的格挡成功
pcall(function()
	task.spawn(function()
		local r = RS:WaitForChild("Remotes", 20)
		if not r then return end
		local ev = r:FindFirstChild("ParrySuccessAll") or r:FindFirstChild("ParrySuccess")
		if not ev then return end
		ev.OnClientEvent:Connect(function(a, b, c, plr)
			if plr == LP then
				mySuccess = mySuccess + 1
				push("[我格挡成功] 剑=" .. tostring(c) .. " 累计=" .. mySuccess)
			end
		end)
	end)
end)

-- hook 自检：5 秒后自己发一次空参 ParryAttempt
task.delay(5, function()
	if not pa then return end
	SelfTest = pa
	pcall(function() pa:FireServer() end)
	task.delay(1.5, function() SelfTest = nil end)
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

local pill = Instance.new("TextButton")
pill.Size = UDim2.new(0, 240, 0, 44)
pill.Position = UDim2.new(1, -252, 0, 96)
pill.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
pill.BackgroundTransparency = 0.08
pill.Text = "启动中…"
pill.Font = Enum.Font.GothamBold
pill.TextSize = 13
pill.TextColor3 = Color3.fromRGB(120, 220, 255)
pill.BorderSizePixel = 0
pill.Parent = sg
local pc1 = Instance.new("UICorner") pc1.CornerRadius = UDim.new(0, 22) pc1.Parent = pill
local pst = Instance.new("UIStroke") pst.Color = Color3.fromRGB(80, 180, 255) pst.Thickness = 1.2 pst.Parent = pill

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
title.Size = UDim2.new(1, -140, 0, 34)
title.Position = UDim2.new(0, 14, 0, 8)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextColor3 = Color3.fromRGB(120, 220, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "自动复制中"
title.Parent = fr

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 80, 0, 30)
closeBtn.Position = UDim2.new(1, -94, 0, 8)
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
tb.TextYAlignment = Enum.TextYAlignment.Top
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

bind(pill, function() fr.Visible = true pill.Visible = false end)
bind(closeBtn, function() fr.Visible = false pill.Visible = true end)
bind(copyBtn, function()
	local ok = copyToClip(tb.Text)
	title.Text = ok and "已复制" or "剪贴板不可用"
end)

local function buildText()
	local out = {}
	out[#out + 1] = "== 环境 =="
	out[#out + 1] = "ParryAttempt = " .. (pa and "存在" or "不存在")
	out[#out + 1] = "hook = " .. (hooked and "已挂载" or "挂载失败")
	out[#out + 1] = "点击次数 = " .. touchN .. "（被界面吃掉 " .. touchGp .. "）"
	out[#out + 1] = "我的格挡成功 = " .. mySuccess
	out[#out + 1] = ""
	out[#out + 1] = "== Remotes 下 FireServer 汇总 =="
	if #fireOrder == 0 then
		out[#out + 1] = "（一条都没有）"
	else
		for _, name in ipairs(fireOrder) do
			local s = fireStat[name]
			out[#out + 1] = name .. " ×" .. s.n
			out[#out + 1] = "    参数：" .. s.sample
		end
	end
	out[#out + 1] = ""
	out[#out + 1] = "== 关键事件 =="
	for _, l in ipairs(log) do out[#out + 1] = l end
	return table.concat(out, "\n")
end

local lastTxt = ""
task.spawn(function()
	while sg.Parent do
		local folder = WS:FindFirstChild("Balls")
		local n = folder and #folder:GetChildren() or 0

		local txt = buildText()
		if txt ~= lastTxt then
			tb.Text = txt
			if dirty then copyToClip(txt) end
			lastTxt = txt
			dirty = false
		end

		pill.Text = (n > 0 and ("局内" .. n .. "球") or "局外")
			.. "｜发出" .. #fireOrder .. "｜成功" .. mySuccess
		pill.TextColor3 = mySuccess > 0 and Color3.fromRGB(120, 255, 170)
			or (n > 0 and Color3.fromRGB(120, 220, 255) or Color3.fromRGB(255, 180, 90))

		task.wait(0.5)
	end
end)
