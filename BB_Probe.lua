-- Blade Ball 输入探针 V1
-- 目的：搞清楚「手动点」和「脚本点」在这游戏里到底有没有区别
-- 用法：loadstring(game:HttpGet("https://raw.githubusercontent.com/78589wlg/baby-script/main/BB_Probe.lua?v=1"))()

local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")
local P = game:GetService("Players")
local WS = game:GetService("Workspace")
local LP = P.LocalPlayer
local VIM = game:GetService("VirtualInputManager")

local function clip(t)
	if type(t) ~= "string" or t == "" then return false end
	if setclipboard then if pcall(setclipboard, t) then return true end end
	if toclipboard then if pcall(toclipboard, t) then return true end end
	return false
end

local log, dirty = {}, true
local MAX = 60
local function add(s)
	log[#log + 1] = os.date("%H:%M:%S") .. " " .. s
	if #log > MAX then table.remove(log, 1) end
	dirty = true
end

local handN, simN, simHit = 0, 0, 0
local simAt = 0

-- ============ 1. 手动输入 vs 模拟输入 ============
UIS.InputBegan:Connect(function(input, gp)
	local t = input.UserInputType.Name
	if t ~= "Touch" and t ~= "MouseButton1" and t ~= "Key" then return end
	local pos = input.Position
	local tag = ""
	if os.clock() - simAt < 0.35 then
		tag = " [脚本模拟]"
		simHit = simHit + 1
	elseif t == "Touch" or t == "MouseButton1" then
		handN = handN + 1
		tag = " [你的手]"
	end
	add(("输入 %s%s gp=%s pos=(%d,%d)"):format(t, tag, tostring(gp), pos.X, pos.Y))
end)

-- ============ 2. 游戏绑定了什么按键 ============
local binds = {}
pcall(function()
	local ok, info = pcall(function() return CAS:GetAllBoundActionInfo() end)
	if ok and type(info) == "table" then
		for name, d in pairs(info) do
			local types = {}
			local it = d.inputTypes or d.InputTypes
			if type(it) == "table" then
				for _, v in pairs(it) do types[#types + 1] = tostring(v) end
			end
			binds[#binds + 1] = name .. " ← " .. (#types > 0 and table.concat(types, "/") or "?")
		end
	end
end)
table.sort(binds)

-- ============ 3. 格挡按钮的连接数 ============
local function findBlock()
	local pg = LP:FindFirstChild("PlayerGui")
	if not pg then return nil, "无 PlayerGui" end
	for _, path in ipairs({{"Hotbar", "Block"}, {"Hotbar", "Parry"}, {"Block"}, {"Parry"}}) do
		local cur = pg
		for _, nm in ipairs(path) do
			cur = cur and cur:FindFirstChild(nm)
		end
		if cur and (cur:IsA("TextButton") or cur:IsA("ImageButton")) then
			return cur, table.concat(path, ".")
		end
	end
	for _, d in ipairs(pg:GetDescendants()) do
		if (d:IsA("TextButton") or d:IsA("ImageButton")) and string.find(string.lower(d.Name), "block") then
			return d, d:GetFullName()
		end
	end
	return nil, "未找到"
end

local btn, btnPath = findBlock()
local connInfo = "?"
if btn then
	local n = 0
	if typeof(getconnections) == "function" then
		for _, evName in ipairs({"Activated", "MouseButton1Click", "InputBegan", "TouchTap"}) do
			local sig = btn[evName]
			if sig then
				local ok, cs = pcall(getconnections, sig)
				if ok and cs then n = n + #cs end
			end
		end
	end
	connInfo = tostring(n)
end

-- ============ 4. 我的格挡成功 ============
local myOK = 0
task.spawn(function()
	local r = RS:WaitForChild("Remotes", 20)
	if not r then return end
	local ev = r:FindFirstChild("ParrySuccessAll") or r:FindFirstChild("ParrySuccess")
	if not ev then return end
	ev.OnClientEvent:Connect(function(...)
		local a = table.pack(...)
		for i = 1, a.n do
			if a[i] == LP then
				myOK = myOK + 1
				add("★ 我格挡成功（累计 " .. myOK .. "）")
				break
			end
		end
	end)
end)

-- ============ 5. 每 6 秒模拟一次鼠标点击 ============
task.spawn(function()
	while true do
		task.wait(6)
		local cam = WS.CurrentCamera
		if cam then
			local vp = cam.ViewportSize
			simN = simN + 1
			simAt = os.clock()
			pcall(function()
				VIM:SendMouseButtonEvent(math.floor(vp.X * 0.5), math.floor(vp.Y * 0.35), 0, true, game, 1)
				VIM:SendMouseButtonEvent(math.floor(vp.X * 0.5), math.floor(vp.Y * 0.35), 0, false, game, 1)
			end)
		end
	end
end)

-- ============ 界面 ============
local parent = LP:FindFirstChild("PlayerGui")
pcall(function() if gethui then parent = gethui() or parent end end)

local sg = Instance.new("ScreenGui")
sg.Name = "BBProbeGUI"
sg.ResetOnSpawn = false
sg.DisplayOrder = 999
sg.Parent = parent

local pill = Instance.new("TextButton")
pill.Size = UDim2.new(0, 250, 0, 40)
pill.Position = UDim2.new(1, -262, 0, 150)
pill.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
pill.TextColor3 = Color3.fromRGB(120, 220, 255)
pill.Font = Enum.Font.GothamBold
pill.TextSize = 13
pill.BorderSizePixel = 0
pill.Text = "探针启动中…"
pill.Parent = sg
Instance.new("UICorner", pill).CornerRadius = UDim.new(0, 20)
local ps = Instance.new("UIStroke", pill)
ps.Color = Color3.fromRGB(80, 180, 255)
ps.Thickness = 1.2

local fr = Instance.new("Frame")
fr.Size = UDim2.new(0, 560, 0, 420)
fr.Position = UDim2.new(0.5, -280, 0.5, -210)
fr.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
fr.BorderSizePixel = 0
fr.Visible = false
fr.Parent = sg
Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 10)

local tb = Instance.new("TextBox")
tb.Size = UDim2.new(1, -28, 1, -100)
tb.Position = UDim2.new(0, 14, 0, 14)
tb.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
tb.TextColor3 = Color3.fromRGB(210, 220, 225)
tb.Font = Enum.Font.Code
tb.TextSize = 12
tb.MultiLine = true
tb.TextWrapped = true
tb.TextEditable = false
tb.Text = ""
tb.TextXAlignment = Enum.TextXAlignment.Left
tb.TextYAlignment = Enum.TextYAlignment.Top
tb.Parent = fr
Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 8)

local cp = Instance.new("TextButton")
cp.Size = UDim2.new(1, -28, 0, 40)
cp.Position = UDim2.new(0, 14, 1, -52)
cp.BackgroundColor3 = Color3.fromRGB(35, 140, 90)
cp.Text = "复制结果（也自动复制）"
cp.Font = Enum.Font.GothamBold
cp.TextSize = 14
cp.TextColor3 = Color3.new(1, 1, 1)
cp.BorderSizePixel = 0
cp.Parent = fr
Instance.new("UICorner", cp).CornerRadius = UDim.new(0, 8)

local busy = false
local function bind(b, fn)
	b.Activated:Connect(function()
		if busy then return end
		busy = true
		pcall(fn)
		task.delay(0.3, function() busy = false end)
	end)
end
bind(pill, function() fr.Visible = true pill.Visible = false end)
bind(cp, function() clip(tb.Text) end)

local function build()
	local o = {}
	o[#o + 1] = "== 环境 =="
	o[#o + 1] = "触屏设备 = " .. tostring(UIS.TouchEnabled)
	o[#o + 1] = "鼠标设备 = " .. tostring(UIS.MouseEnabled)
	o[#o + 1] = "VIM = " .. (VIM and "有" or "无")
	o[#o + 1] = "格挡按钮 = " .. tostring(btnPath) .. "（连接数 " .. connInfo .. "）"
	o[#o + 1] = "脚本模拟点击 = " .. simN .. " 次，其中被 InputBegan 收到 " .. simHit .. " 次"
	o[#o + 1] = "你的手点 = " .. handN .. " 次｜我格挡成功 = " .. myOK
	o[#o + 1] = ""
	o[#o + 1] = "== 游戏绑定的动作（ContextActionService）=="
	if #binds == 0 then
		o[#o + 1] = "（读不到，说明没走这套）"
	else
		for i = 1, math.min(#binds, 20) do o[#o + 1] = binds[i] end
	end
	o[#o + 1] = ""
	o[#o + 1] = "== 输入记录 =="
	for i = math.max(1, #log - 28), #log do o[#o + 1] = log[i] or "" end
	return table.concat(o, "\n")
end

task.spawn(function()
	local last = ""
	while sg.Parent do
		local txt = build()
		if txt ~= last then
			tb.Text = txt
			if dirty then clip(txt) end
			last = txt
			dirty = false
		end
		pill.Text = ("手点 %d｜模拟 %d(收到%d)｜成功 %d"):format(handN, simN, simHit, myOK)
		pill.TextColor3 = myOK > 0 and Color3.fromRGB(120, 255, 170) or Color3.fromRGB(120, 220, 255)
		task.wait(0.6)
	end
end)

add("探针已启动：先手动点一次屏幕，脚本每 6 秒也会自己模拟点一次")
