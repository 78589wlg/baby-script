-- 婴儿脚本 · Blade Ball V1
-- 自动格挡 / 自动挥剑 / 球透视 / 玩家透视 / 速度
-- 适配：Blade Ball (PlaceId 13772394625, Wiggity.)

local P = game:GetService("Players")
local LP = P.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local WS = game:GetService("Workspace")
local RUN = game:GetService("RunService")

local cfg = {
	autoParry = false,
	geoMode = false,     -- 不依赖「被锁定」标记，纯几何判断
	threshold = 0.16,    -- 到撞击剩余秒数小于这个值就格挡
	clash = false,       -- 自动挥剑 / 拼刀
	clashGap = 0.08,
	ballESP = true,
	playerESP = false,
	distTag = true,
}

-- ================= 基础对象 =================
local Remotes, Balls
local function refreshRefs()
	if not Remotes or not Remotes.Parent then
		Remotes = RS:FindFirstChild("Remotes")
	end
	if not Balls or not Balls.Parent then
		Balls = WS:FindFirstChild("Balls")
	end
	return Remotes, Balls
end
refreshRefs()

local function parryRemote()
	local r = refreshRefs()
	if not r then return nil end
	local ev = r:FindFirstChild("ParryButtonPress")
	if ev and ev:IsA("RemoteEvent") then return ev end
	for _, x in ipairs(r:GetChildren()) do
		if x:IsA("RemoteEvent") and string.find(string.lower(x.Name), "parry", 1, true) then
			return x
		end
	end
	return nil
end

-- ================= 界面 =================
local WindUI = loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/Footagesus/WindUI@main/dist/main.lua"))()
local Win = WindUI:CreateWindow({Title = "Blade Ball"})
local T1 = Win:Tab({Title = "格挡", Icon = "shield"})
local T2 = Win:Tab({Title = "视觉", Icon = "eye"})
local T3 = Win:Tab({Title = "移动", Icon = "zap"})

-- ================= 自动格挡 =================
local lastParry = 0
local function doParry()
	local now = os.clock()
	if now - lastParry < 0.05 then return end
	local ev = parryRemote()
	if not ev then return end
	lastParry = now
	pcall(function() ev:Fire() end)
end

local function rootOf(char)
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
end

local function isTarget(char)
	if not char then return false end
	if char:FindFirstChildOfClass("Highlight") then return true end
	if char:FindFirstChild("Highlight") then return true end
	return false
end

local function ballSpeed(b)
	local v = b.AssemblyLinearVelocity
	if not v or v.Magnitude < 0.1 then
		v = b.Velocity or Vector3.zero
	end
	return v
end

local function checkBall(b, char, root)
	if not b or not b.Parent then return end
	if b:GetAttribute("realBall") ~= true then return end
	local pos = b.Position
	local dist = (pos - root.Position).Magnitude
	if dist > 60 then return end

	local v = ballSpeed(b)
	local speed = v.Magnitude

	-- 距离很近，直接格挡
	if dist < 9 then
		doParry()
		return
	end

	if speed < 1 then return end
	local toMe = (root.Position - pos).Unit
	local closing = v:Dot(toMe)
	if closing < 5 then return end          -- 没朝我来

	local t = (dist - 8) / closing
	if t <= cfg.threshold then
		doParry()
	end
end

task.spawn(function()
	while true do
		local dt = RUN.Heartbeat:Wait()
		if cfg.autoParry then
			local char = LP.Character
			local root = rootOf(char)
			local _, balls = refreshRefs()
			if root and balls then
				local targetOk = cfg.geoMode or isTarget(char)
				if targetOk then
					for _, b in ipairs(balls:GetChildren()) do
						pcall(checkBall, b, char, root)
					end
				end
			end
		end
	end
end)

-- 自动挥剑 / 拼刀
task.spawn(function()
	while true do
		task.wait(cfg.clashGap)
		if cfg.clash then
			pcall(doParry)
		end
	end
end)

-- ================= 球透视 =================
local ballTags = {}

local function killTag(t)
	pcall(function() if t.hl then t.hl:Destroy() end end)
	pcall(function() if t.bb then t.bb:Destroy() end end)
end

local function makeBallTag(b)
	local hl = Instance.new("Highlight")
	hl.Name = "BB_HL"
	hl.Adornee = b
	hl.FillColor = Color3.fromRGB(255, 70, 70)
	hl.FillTransparency = 0.45
	hl.OutlineColor = Color3.fromRGB(255, 255, 255)
	hl.OutlineTransparency = 0
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Parent = b

	local bb = Instance.new("BillboardGui")
	bb.Name = "BB_TAG"
	bb.Adornee = b
	bb.Size = UDim2.new(0, 150, 0, 30)
	bb.StudsOffset = Vector3.new(0, 1.6, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 400
	bb.Parent = b

	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.new(1, 0, 1, 0)
	tl.BackgroundTransparency = 1
	tl.Text = "球"
	tl.TextColor3 = Color3.fromRGB(255, 120, 120)
	tl.TextStrokeColor3 = Color3.new(0, 0, 0)
	tl.TextStrokeTransparency = 0.2
	tl.Font = Enum.Font.GothamBold
	tl.TextScaled = true
	tl.Parent = bb

	return {hl = hl, bb = bb, tl = tl}
end

task.spawn(function()
	while true do
		task.wait(0.15)
		local _, balls = refreshRefs()
		if balls then
			if cfg.ballESP then
				local root = rootOf(LP.Character)
				for _, b in ipairs(balls:GetChildren()) do
					if b:IsA("BasePart") then
						local t = ballTags[b]
						if not t then
							t = makeBallTag(b)
							ballTags[b] = t
						end
						if cfg.distTag and root and t.tl then
							local d = math.floor((b.Position - root.Position).Magnitude)
							t.tl.Text = "球 [" .. d .. "]"
						elseif t.tl then
							t.tl.Text = "球"
						end
					end
				end
			end
			for b, t in pairs(ballTags) do
				if not cfg.ballESP or not b.Parent then
					killTag(t)
					ballTags[b] = nil
				end
			end
		end
	end
end)

-- ================= 玩家透视 =================
local pTags = {}
task.spawn(function()
	while true do
		task.wait(0.4)
		if cfg.playerESP then
			for _, pl in ipairs(P:GetPlayers()) do
				if pl ~= LP and pl.Character then
					local hrp = pl.Character:FindFirstChild("HumanoidRootPart")
					if hrp then
						local t = pTags[hrp]
						if not t then
							local hl = Instance.new("Highlight")
							hl.Name = "BBPHL"
							hl.Adornee = pl.Character
							hl.FillColor = Color3.fromRGB(80, 200, 255)
							hl.FillTransparency = 0.6
							hl.OutlineColor = Color3.fromRGB(80, 200, 255)
							hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
							hl.Parent = pl.Character
							pTags[hrp] = {hl = hl}
						end
					end
				end
			end
		else
			for hrp, t in pairs(pTags) do
				if t.hl then pcall(function() t.hl:Destroy() end) end
				pTags[hrp] = nil
			end
		end
	end
end)

-- ================= 移动 =================
local sp = 16
local function applyHum()
	local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
	if not h then return end
	pcall(function() h.WalkSpeed = sp end)
end
LP.CharacterAdded:Connect(function() task.wait(0.6) pcall(applyHum) end)

-- ================= UI =================
T1:Section({Title = "自动格挡"})
T1:Toggle({Title = "自动格挡（Auto Parry）", Value = false, Callback = function(v)
	cfg.autoParry = v
	WindUI:Notify({Title = "自动格挡", Content = v and "已开启" or "已关闭", Duration = 3})
end})
T1:Slider({Title = "触发提前量（秒）", Value = {Min = 8, Max = 30, Default = 16}, Callback = function(v)
	cfg.threshold = v / 100
end})
T1:Toggle({Title = "不依赖锁定标记（纯速度判断）", Value = false, Callback = function(v)
	cfg.geoMode = v
	WindUI:Notify({Title = "判定模式", Content = v and "已切换为纯速度判断，可能多挥几刀" or "已切回锁定标记判断", Duration = 4})
end})

T1:Section({Title = "拼刀"})
T1:Toggle({Title = "自动挥剑 / 拼刀（Auto Clash）", Value = false, Callback = function(v)
	cfg.clash = v
	WindUI:Notify({Title = "自动挥剑", Content = v and "已开启，注意频繁触发可能被检测" or "已关闭", Duration = 4})
end})
T1:Slider({Title = "挥剑间隔（毫秒）", Value = {Min = 30, Max = 300, Default = 80}, Callback = function(v)
	cfg.clashGap = v / 1000
end})

T1:Section({Title = "状态"})
T1:Button({Title = "检查远程与球", Callback = function()
	local okR = parryRemote() ~= nil
	local _, balls = refreshRefs()
	local n = balls and #balls:GetChildren() or 0
	local locked = isTarget(LP.Character) and "是" or "否"
	WindUI:Notify({Title = "状态", Content = "格挡远程：" .. (okR and "正常" or "没找到") .. "｜球：" .. n .. " 个｜被锁定：" .. locked, Duration = 6})
end})

T2:Section({Title = "透视"})
T2:Toggle({Title = "球透视（红色 + 距离）", Value = true, Callback = function(v) cfg.ballESP = v end})
T2:Toggle({Title = "显示距离数字", Value = true, Callback = function(v) cfg.distTag = v end})
T2:Toggle({Title = "玩家透视（蓝色）", Value = false, Callback = function(v) cfg.playerESP = v end})

T3:Section({Title = "移动"})
T3:Slider({Title = "移动速度", Value = {Min = 16, Max = 120, Default = 16}, Callback = function(v)
	sp = v
	applyHum()
end})
T3:Button({Title = "恢复默认速度", Callback = function()
	sp = 16
	applyHum()
end})

task.delay(1, function()
	pcall(function()
		local okR = parryRemote() ~= nil
		WindUI:Notify({Title = "Blade Ball", Content = okR and "远程已找到，可以开自动格挡" or "没找到格挡远程，先打一局再点「检查远程与球」", Duration = 6})
	end)
end)
