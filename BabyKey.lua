--[[ ============================================================
     婴儿脚本 · 卡密验证（独立脚本）
     · 长方形面板，输入框在正上方，下方两个按钮
     · 左「获取卡密」：复制卡密网站链接（能开浏览器就顺手打开）
     · 右「确认」：校验卡密，通过后自动加载主脚本
     ============================================================ ]]

-- ====== 配置区（换网站/换入口只改这里） ======
local KEY_SITE = "https://ae1580126123eca19.app.workbuddy.host"
local MAIN_URL = "https://raw.githubusercontent.com/78589wlg/baby-script/main/main.lua"

local PERM = { "卡密制作婴儿脚本6767", "少羽没面" }
local KR  = "https://raw.githubusercontent.com/78589wlg/baby-script/main/"
local KSH = "https://ae1580126123eca19.app.workbuddy.host"
local KSS = "WGTNFAERQB"

local P   = game:GetService("Players")
local LP  = P.LocalPlayer
local UIS = game:GetService("UserInputService")
local TS  = game:GetService("TweenService")
local HSK = game:GetService("HttpService")

local WHT = Color3.fromRGB(255, 255, 255)
local TXT = Color3.fromRGB(240, 243, 252)
local SUB = Color3.fromRGB(150, 160, 182)
local OKC = Color3.fromRGB(122, 226, 164)
local ERRC = Color3.fromRGB(255, 120, 120)

local RAINBOW = {
	ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 104, 140)),
	ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 178, 92)),
	ColorSequenceKeypoint.new(0.50, Color3.fromRGB(122, 236, 178)),
	ColorSequenceKeypoint.new(0.75, Color3.fromRGB(100, 188, 255)),
	ColorSequenceKeypoint.new(1.00, Color3.fromRGB(168, 130, 255)),
}

local function inst(cls, props, parent)
	local o = Instance.new(cls)
	if props then
		for k, v in pairs(props) do o[k] = v end
	end
	if parent then o.Parent = parent end
	return o
end

local function round(o, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = o
	return c
end

local function stroke(o, col, trans, thick)
	local s = Instance.new("UIStroke")
	s.Color = col or WHT
	s.Transparency = (trans == nil) and 0.8 or trans
	s.Thickness = thick or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = o
	return s
end

local function grad(o, rot)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(RAINBOW)
	g.Rotation = rot or 0
	g.Parent = o
	return g
end

local function label(parent, props)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.BorderSizePixel = 0
	t.Font = Enum.Font.GothamMedium
	t.TextSize = 12
	t.TextColor3 = SUB
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.TextYAlignment = Enum.TextYAlignment.Center
	if props then
		for k, v in pairs(props) do t[k] = v end
	end
	t.Parent = parent
	return t
end

-- ====== 界面 ======
local gui = Instance.new("ScreenGui")
gui.Name = "BabyKeyUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

local panel = inst("Frame", {
	Name = "Panel",
	Size = UDim2.fromOffset(340, 212),
	Position = UDim2.new(0.5, 0, 0, 104),
	AnchorPoint = Vector2.new(0.5, 0),
	BackgroundColor3 = Color3.fromRGB(15, 18, 29),
	BackgroundTransparency = 0.12,
	BorderSizePixel = 0,
}, gui)
round(panel, 16)
local pStroke = stroke(panel, WHT, 0.16, 1.6)
local pGrad = grad(pStroke, 0)

-- 标题
local bar = inst("Frame", {
	Size = UDim2.new(0, 3, 0, 16),
	Position = UDim2.new(0, 16, 0, 18),
	BackgroundColor3 = WHT,
	BorderSizePixel = 0,
}, panel)
round(bar, 2)
grad(bar, 90)

label(panel, {
	Size = UDim2.new(1, -80, 0, 18),
	Position = UDim2.new(0, 26, 0, 15),
	Text = "婴儿脚本 · 卡密验证",
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	TextColor3 = TXT,
})
label(panel, {
	Size = UDim2.new(1, -80, 0, 14),
	Position = UDim2.new(0, 26, 0, 34),
	Text = "输入卡密后点「确认」，自动加载脚本",
	TextSize = 11,
	TextColor3 = SUB,
})

-- 关闭
local btnX = inst("TextButton", {
	Size = UDim2.fromOffset(26, 26),
	Position = UDim2.new(1, -38, 0, 14),
	BackgroundColor3 = WHT,
	BackgroundTransparency = 0.93,
	Text = "×",
	Font = Enum.Font.GothamBold,
	TextSize = 15,
	TextColor3 = SUB,
	AutoButtonColor = false,
	BorderSizePixel = 0,
}, panel)
round(btnX, 8)
btnX.Activated:Connect(function() gui:Destroy() end)

-- 输入框（正上方居中）
local box = inst("TextBox", {
	Size = UDim2.new(1, -48, 0, 40),
	Position = UDim2.new(0, 24, 0, 60),
	BackgroundColor3 = Color3.fromRGB(24, 28, 42),
	BackgroundTransparency = 0.12,
	BorderSizePixel = 0,
	Text = "",
	PlaceholderText = "请输入卡密",
	PlaceholderColor3 = Color3.fromRGB(108, 118, 140),
	Font = Enum.Font.GothamMedium,
	TextSize = 13,
	TextColor3 = TXT,
	ClearTextOnFocus = false,
	TextXAlignment = Enum.TextXAlignment.Center,
}, panel)
round(box, 10)
local boxStroke = stroke(box, WHT, 0.9, 1)
local boxGrad = grad(boxStroke, 0)

box.Focused:Connect(function()
	boxStroke.Transparency = 0.25
	boxStroke.Thickness = 1.6
end)
box.FocusLost:Connect(function()
	boxStroke.Transparency = 0.9
	boxStroke.Thickness = 1
end)

-- 两个按钮
local function mkBtn(text, x, primary)
	local b = inst("TextButton", {
		Size = UDim2.fromOffset(140, 40),
		Position = UDim2.new(0, x, 0, 112),
		BackgroundColor3 = primary and Color3.fromRGB(255, 138, 66) or Color3.fromRGB(30, 35, 50),
		BackgroundTransparency = primary and 0.02 or 0.10,
		Text = text,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = primary and Color3.fromRGB(255, 255, 255) or TXT,
		AutoButtonColor = false,
		BorderSizePixel = 0,
	}, panel)
	round(b, 10)
	if primary then
		local g = Instance.new("UIGradient")
		g.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 158, 74)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 104, 140)),
		})
		g.Rotation = 90
		g.Parent = b
	else
		local st = stroke(b, WHT, 0.72, 1)
		grad(st, 0)
	end
	b.MouseEnter:Connect(function()
		TS:Create(b, TweenInfo.new(0.14), { BackgroundTransparency = primary and 0 or 0.02 }):Play()
	end)
	b.MouseLeave:Connect(function()
		TS:Create(b, TweenInfo.new(0.14), { BackgroundTransparency = primary and 0.02 or 0.10 }):Play()
	end)
	return b
end

local btnGet = mkBtn("获取卡密", 24, false)
local btnOk  = mkBtn("确认", 176, true)

-- 状态文字
local status = label(panel, {
	Size = UDim2.new(1, -40, 0, 48),
	Position = UDim2.new(0, 20, 0, 157),
	Text = "",
	TextSize = 11.5,
	TextColor3 = SUB,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Center,
	TextYAlignment = Enum.TextYAlignment.Top,
})

local function setStatus(msg, kind)
	status.Text = tostring(msg or "")
	if kind == true then
		status.TextColor3 = OKC
	elseif kind == false then
		status.TextColor3 = ERRC
	else
		status.TextColor3 = SUB
	end
	-- 长链接自动换行显示
end

-- 拖动（按住标题区）
local dragging, dragStart, dragOrigin = false, nil, nil
panel.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if input.Position.Y - panel.AbsolutePosition.Y <= 52 then
			dragging = true
			dragStart = input.Position
			dragOrigin = panel.Position
		end
	end
end)
UIS.InputChanged:Connect(function(input)
	if not dragging then return end
	if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
	local d = input.Position - dragStart
	panel.Position = UDim2.new(dragOrigin.X.Scale, dragOrigin.X.Offset + d.X, dragOrigin.Y.Scale, dragOrigin.Y.Offset + d.Y)
end)
UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

-- 描边缓慢流动
local t = 0
game:GetService("RunService").RenderStepped:Connect(function(dt)
	t = t + dt
	pGrad.Rotation = (t * 22) % 360
	boxGrad.Rotation = (t * 30) % 360
end)

-- ====== 卡密校验 ======
local function ktrim(x)
	return (tostring(x):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function ktoday()
	local o, d = pcall(os.date, "%Y-%m-%d")
	return o and d or "1970-01-01"
end

local function kexpok(e)
	if not e or e == "" then return true, "永久" end
	local d = tostring(e):gsub("[^%d]", "")
	if #d == 8 then d = d:sub(1, 4) .. "-" .. d:sub(5, 6) .. "-" .. d:sub(7, 8) end
	if d < ktoday() then return false, d end
	return true, d
end

-- 在 "卡密,到期日" 列表里找
local function scanList(txt, k)
	if type(txt) ~= "string" then return false, nil end
	for line in txt:gmatch("[^\r\n]+") do
		local ln = ktrim(line)
		if ln ~= "" and ln:sub(1, 1) ~= "#" then
			local kk, ee = ln:match("^([^,]+),?(.*)$")
			if kk and ktrim(kk) == k then return true, ktrim(ee or "") end
		end
	end
	return false, nil
end

local function apiBase()
	local ok, txt = pcall(function() return game:HttpGet(KR .. "api.txt?t=" .. tostring(os.time())) end)
	if ok and type(txt) == "string" then
		for line in txt:gmatch("[^\r\n]+") do
			local s = ktrim(line)
			if s ~= "" and s:sub(1, 1) ~= "#" and s:find("^https?://") then
				return (s:gsub("/+$", ""))
			end
		end
	end
	return ""
end

local function keyCheck(k)
	k = ktrim(k)
	if k == "" then return false, "请输入卡密" end

	-- 1) 永久卡
	for _, v in ipairs(PERM) do
		if k == v then return true, "永久卡密（无限期）", "永久" end
	end

	-- 2) 本机开发者名单
	local okf, df = pcall(function() return readfile("BabyDevKeys.txt") end)
	if okf and type(df) == "string" then
		local hit, e = scanList(df, k)
		if hit then
			local good, d = kexpok(e)
			if not good then return false, "卡密已于 " .. d .. " 过期" end
			return true, "验证通过（开发者）", d
		end
	end

	-- 3) 云端开发者名单
	local okc, ct = pcall(function() return game:HttpGet(KSH .. "/devkeys?sharecode=" .. KSS .. "&t=" .. tostring(os.time())) end)
	if not okc or type(ct) ~= "string" or #ct < 1 then
		okc, ct = pcall(function() return game:HttpGet(KR .. "devkeys.txt?t=" .. tostring(os.time())) end)
	end
	if okc and type(ct) == "string" then
		local hit, e = scanList(ct, k)
		if hit then
			local good, d = kexpok(e)
			if not good then return false, "卡密已于 " .. d .. " 过期" end
			return true, "验证通过（开发者）", d
		end
	end

	-- 4) 普通卡密名单
	local okt, kt = pcall(function() return game:HttpGet(KR .. "keys.txt?t=" .. tostring(os.time())) end)
	if okt and type(kt) == "string" then
		local hit, e = scanList(kt, k)
		if hit then
			local good, d = kexpok(e)
			if not good then return false, "卡密已于 " .. d .. " 过期" end
			return true, "验证通过（有效期至 " .. d .. "）", d
		end
	end

	-- 5) 在线接口
	local base = apiBase()
	if base == "" then return false, "卡密无效（名单和接口都没有这条卡密）" end
	local ok2, res = pcall(function() return game:HttpGet(base .. "/verify?key=" .. k) end)
	if not ok2 or type(res) ~= "string" or #res < 3 then return false, "接口连接失败，检查网络后重试" end
	local okd, d = pcall(function() return HSK:JSONDecode(res) end)
	if not okd or type(d) ~= "table" then return false, "接口返回异常" end
	if not d.ok then return false, tostring(d.msg or "卡密无效") end
	local exp = tostring(d.exp or "")
	if exp == "" then return true, "验证通过", "" end
	return true, "验证通过（有效期至 " .. exp .. "）", exp
end

local function saveKey(k, exp)
	pcall(function()
		if writefile then writefile("BabyKey.txt", ktrim(k) .. "|" .. tostring(exp or "") .. "|" .. tostring(os.time())) end
	end)
end

-- ====== 按钮逻辑 ======
local busy = false

btnGet.Activated:Connect(function()
	local hasClip = type(setclipboard) == "function"
	local copied = false
	if hasClip then
		copied = pcall(function() setclipboard(KEY_SITE) end)
	end
	-- 部分执行器支持直接开浏览器
	pcall(function()
		if type(openbrowser) == "function" then openbrowser(KEY_SITE) end
	end)
	if copied then
		setStatus("卡密网站链接已复制，去浏览器粘贴打开：\n" .. KEY_SITE, true)
	else
		setStatus("请手动打开这个网址获取卡密：\n" .. KEY_SITE)
	end
end)

local function doConfirm()
	if busy then return end
	local k = ktrim(box.Text)
	if k == "" then
		setStatus("请先输入卡密", false)
		return
	end
	busy = true
	setStatus("正在校验卡密…")
	task.spawn(function()
		local good, msg, exp = keyCheck(k)
		busy = false
		if not good then
			setStatus(tostring(msg or "卡密无效"), false)
			return
		end
		saveKey(k, exp)
		setStatus("验证通过 · " .. tostring(msg or ""), true)
		task.wait(0.8)
		setStatus("正在加载脚本…", true)
		local okMain, err = pcall(function()
			loadstring(game:HttpGet(MAIN_URL .. "?t=" .. tostring(os.time())))()
		end)
		if not okMain then
			setStatus("主脚本加载失败：" .. tostring(err), false)
		else
			gui:Destroy()
		end
	end)
end

btnOk.Activated:Connect(doConfirm)

box.FocusLost:Connect(function(enter)
	if enter then
		-- 输入框回车等同于点确认
		if ktrim(box.Text) ~= "" then
			doConfirm()
		end
	end
end)
