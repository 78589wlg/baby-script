-- 婴儿脚本 · Prison Life（监狱人生）
-- PlaceId 155615604 · 远程名取自游戏客户端反编译文档
if getgenv().PL_Unload then pcall(getgenv().PL_Unload) end

local WindUI = loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/Footagesus/WindUI@main/dist/main.lua"))()
local P = game:GetService("Players")
local LP = P.LocalPlayer
local WS = workspace
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RUN = game:GetService("RunService")

local Win = WindUI:CreateWindow({ Title = "Prison Life 监狱人生" })

local cfg = {
	speed = 16, jump = 50,
	espOther = false, espItem = false, espDist = 600,
	aim = false, aimFov = 140, aimSmooth = 0.35, aimPart = "Head",
	autoFire = false, gunMod = false,
	autoArrest = false, arrestRange = 30, handcuff = true,
	autoPick = false,
	fly = false, flySpeed = 60,
	noclip = false, infJump = false, god = false,
}

local conns = {}
local function track(c) conns[#conns + 1] = c; return c end
local function notif(t, c) pcall(function() WindUI:Notify({ Title = t, Content = c, Duration = 3 }) end) end

-- ================= 基础 =================
local function ch() return LP.Character end
local function root()
	local c = ch()
	return c and (c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart)
end
local function hum()
	local c = ch()
	return c and c:FindFirstChildOfClass("Humanoid")
end

-- ================= 远程 =================
local function remote(name)
	local r = RS:FindFirstChild("Remotes")
	if r then
		local a = r:FindFirstChild(name)
		if a then return a end
	end
	local old = WS:FindFirstChild("Remote")
	if old then
		local b = old:FindFirstChild(name)
		if b then return b end
	end
	return RS:FindFirstChild(name)
end

local function call(name, ...)
	local r = remote(name)
	if not r then return false, "没有远程 " .. name end
	local args = { ... }
	local done = false
	if r:IsA("RemoteFunction") then
		done = pcall(function() r:InvokeServer(table.unpack(args)) end)
	elseif r:IsA("RemoteEvent") then
		done = pcall(function() r:FireServer(table.unpack(args)) end)
	end
	if not done then
		local ok2 = pcall(function() r:FireServer(table.unpack(args)) end)
		local ok3 = pcall(function() r:InvokeServer(table.unpack(args)) end)
		done = ok2 or ok3
	end
	return done, r.ClassName
end

-- ================= 物品 =================
local function itemRoot() return WS:FindFirstChild("Prison_ITEMS") end

local function itemFolders()
	local out = {}
	local r = itemRoot()
	if not r then return out end
	for _, v in ipairs(r:GetChildren()) do
		if v:IsA("Folder") or v:IsA("Model") or v:IsA("Configuration") then
			out[#out + 1] = v
		end
	end
	return out
end

local function pickupOf(name)
	for _, f in ipairs(itemFolders()) do
		local o = f:FindFirstChild(name)
		if o then
			local pp = o:FindFirstChild("ITEMPICKUP", true)
			if pp then return pp end
		end
	end
	return nil
end

local GIVE_ORDER = { "InteractWithItem", "GiverPressed", "TouchGiver", "ItemHandler" }

local function giveItem(name)
	local pp = pickupOf(name)
	if not pp then return false, "没找到 " .. name end
	for _, rn in ipairs(GIVE_ORDER) do
		local r = remote(rn)
		if r then
			local ok = pcall(function()
				if r:IsA("RemoteFunction") then r:InvokeServer(pp) else r:FireServer(pp) end
			end)
			if ok then return true, rn end
		end
	end
	return false, "远程都失败"
end

local function itemNames()
	local seen, out = {}, {}
	for _, f in ipairs(itemFolders()) do
		for _, o in ipairs(f:GetChildren()) do
			if not seen[o.Name] then
				seen[o.Name] = true
				out[#out + 1] = o.Name
			end
		end
	end
	table.sort(out)
	return out
end

local function giveAll()
	local okc, all = 0, 0
	for _, nm in ipairs(itemNames()) do
		local ok = giveItem(nm)
		all = all + 1
		if ok then okc = okc + 1 end
		task.wait(0.07)
	end
	return okc, all
end

-- ================= 枪械 =================
local function gunTools()
	local out = {}
	for _, c in ipairs({ LP:FindFirstChild("Backpack"), ch() }) do
		if c then
			for _, t in ipairs(c:GetChildren()) do
				if t:IsA("Tool") and t:FindFirstChild("GunStates") then
					out[#out + 1] = t
				end
			end
		end
	end
	return out
end

local function applyGunMod()
	local n = 0
	for _, t in ipairs(gunTools()) do
		local ok, m = pcall(function() return require(t:FindFirstChild("GunStates")) end)
		if ok and type(m) == "table" then
			pcall(function()
				m.MaxAmmo = math.huge
				m.CurrentAmmo = math.huge
				m.StoredAmmo = math.huge
				m.FireRate = 0.0001
				m.Spread = 0
				m.Range = math.huge
				m.Bullets = 10
				m.ReloadTime = 0.01
				m.AutoFire = true
			end)
			n = n + 1
		end
	end
	return n
end

local function equippedTool()
	local c = ch()
	return c and c:FindFirstChildOfClass("Tool")
end

-- ================= 目标 =================
local function others(range)
	local out = {}
	local r = root()
	if not r then return out end
	for _, pl in ipairs(P:GetPlayers()) do
		if pl ~= LP and pl.Character then
			local h = pl.Character:FindFirstChildOfClass("Humanoid")
			local t = pl.Character:FindFirstChild("HumanoidRootPart")
			if h and t and h.Health > 0 then
				if not range or (t.Position - r.Position).Magnitude <= range then
					out[#out + 1] = pl
				end
			end
		end
	end
	return out
end

local function criminals(range)
	local out = {}
	for _, pl in ipairs(others(range)) do
		if (pl.Team and pl.Team.Name or "") == "Criminals" then out[#out + 1] = pl end
	end
	if #out == 0 then return others(range) end
	return out
end

-- ================= 透视 =================
local espStore = {}
local function clearEsp()
	for _, g in pairs(espStore) do pcall(function() g:Destroy() end) end
	espStore = {}
end

local TEAMCOLOR = {
	Guards = Color3.fromRGB(70, 140, 255),
	Criminals = Color3.fromRGB(255, 80, 80),
	Inmates = Color3.fromRGB(255, 190, 70),
	Neutral = Color3.fromRGB(180, 180, 180),
}

local function espPlayer()
	local r = root()
	if not r then return end
	for _, pl in ipairs(P:GetPlayers()) do
		if pl ~= LP and pl.Character then
			local c = pl.Character
			local rp = c:FindFirstChild("HumanoidRootPart")
			local h = c:FindFirstChildOfClass("Humanoid")
			if rp and h and h.Health > 0 then
				local d = (rp.Position - r.Position).Magnitude
				if d <= cfg.espDist then
					local col = TEAMCOLOR[(pl.Team and pl.Team.Name or "Neutral")] or Color3.new(1, 1, 1)
					local hl = c:FindFirstChild("PL_ESP")
					if not hl then
						hl = Instance.new("Highlight")
						hl.Name = "PL_ESP"
						hl.FillTransparency = 0.55
						hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
						hl.Adornee = c
						hl.Parent = c
						espStore[hl] = hl

						local bb = Instance.new("BillboardGui")
						bb.Name = "PL_TAG"
						bb.Size = UDim2.new(0, 220, 0, 40)
						bb.StudsOffset = Vector3.new(0, 2.6, 0)
						bb.AlwaysOnTop = true
						local tl = Instance.new("TextLabel")
						tl.Size = UDim2.new(1, 0, 1, 0)
						tl.BackgroundTransparency = 1
						tl.Font = Enum.Font.GothamBold
						tl.TextSize = 13
						tl.TextStrokeTransparency = 0.4
						tl.Parent = bb
						bb.Parent = c
						espStore[bb] = bb
					end
					hl.FillColor = col
					hl.OutlineColor = col
					local bb = c:FindFirstChild("PL_TAG")
					local tl = bb and bb:FindFirstChildOfClass("TextLabel")
					if tl then
						tl.TextColor3 = col
						tl.Text = string.format("%s [%s] %dm %d血", pl.Name, (pl.Team and pl.Team.Name or "?"), math.floor(d), math.floor(h.Health))
					end
				else
					local ex = c:FindFirstChild("PL_ESP")
					if ex then ex:Destroy() end
					local tg = c:FindFirstChild("PL_TAG")
					if tg then tg:Destroy() end
				end
			end
		end
	end
end

local function espItems()
	for _, f in ipairs(itemFolders()) do
		for _, o in ipairs(f:GetChildren()) do
			local pp = o:FindFirstChild("ITEMPICKUP", true)
			if pp and pp:IsA("BasePart") and not pp:FindFirstChild("PL_IHL") then
				local h = Instance.new("Highlight")
				h.Name = "PL_IHL"
				h.FillColor = Color3.fromRGB(90, 255, 140)
				h.FillTransparency = 0.5
				h.OutlineColor = Color3.fromRGB(90, 255, 140)
				h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				h.Adornee = pp
				h.Parent = pp
			end
		end
	end
end

local function clearItemEsp()
	for _, f in ipairs(itemFolders()) do
		for _, d in ipairs(f:GetDescendants()) do
			if d.Name == "PL_IHL" then pcall(function() d:Destroy() end) end
		end
	end
end

-- ================= 瞄准 / 开火 =================
local aimTarget = nil

local function pickTarget()
	local cam = workspace.CurrentCamera
	if not cam then return nil end
	local best, bestD = nil, cfg.aimFov
	for _, pl in ipairs(others(cfg.espDist)) do
		local c = pl.Character
		local part = c:FindFirstChild(cfg.aimPart) or c:FindFirstChild("HumanoidRootPart")
		if part then
			local sp, on = cam:WorldToViewportPoint(part.Position)
			if on then
				local d = (Vector2.new(sp.X, sp.Y) - Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)).Magnitude
				if d < bestD then
					bestD = d
					best = part
				end
			end
		end
	end
	return best
end

track(RUN.RenderStepped:Connect(function(dt)
	if cfg.aim then
		local part = pickTarget()
		aimTarget = part
		if part then
			local cam = workspace.CurrentCamera
			local goal = CFrame.new(cam.CFrame.Position, part.Position)
			local a = math.clamp(cfg.aimSmooth * (dt * 60), 0.05, 1)
			cam.CFrame = cam.CFrame:Lerp(goal, a)
		end
	else
		aimTarget = nil
	end
end))

task.spawn(function()
	while task.wait(0.12) do
		if cfg.autoFire and aimTarget then
			local t = equippedTool()
			if t and t:FindFirstChild("GunStates") then
				pcall(function() t:Activate() end)
			end
		end
	end
end)

task.spawn(function()
	while task.wait(2) do
		if cfg.gunMod then applyGunMod() end
	end
end)

-- ================= 逮捕 =================
local function equipCuffs()
	for _, c in ipairs({ LP:FindFirstChild("Backpack"), ch() }) do
		if c then
			local t = c:FindFirstChild("Handcuffs")
			if t and t:IsA("Tool") then
				local h = hum()
				if h and t.Parent ~= ch() then pcall(function() h:EquipTool(t) end) end
				return true
			end
		end
	end
	return false
end

local function arrestOne(pl)
	local c = pl.Character
	local tr = c and c:FindFirstChild("HumanoidRootPart")
	if not tr then return false end
	local r = root()
	if r and (tr.Position - r.Position).Magnitude > 8 then
		call("RequestHere", tr.Position)
		task.wait(0.12)
		pcall(function() r.CFrame = tr.CFrame + Vector3.new(0, 0, 2) end)
	end
	if cfg.handcuff then equipCuffs() end
	call("ArrestPlayer", pl)
	call("ArrestPlayer", c)
	local hd = c:FindFirstChild("Head")
	if hd then call("ArrestPlayer", hd) end
	return true
end

task.spawn(function()
	while task.wait(0.55) do
		if cfg.autoArrest then
			local list = criminals(cfg.arrestRange)
			if #list > 0 then arrestOne(list[1]) end
		end
	end
end)

-- ================= 移动 =================
local flyBV, flyBG
local function setFly(on)
	cfg.fly = on
	local r = root()
	if on then
		if not r then return end
		flyBV = Instance.new("BodyVelocity")
		flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
		flyBV.Velocity = Vector3.zero
		flyBV.Parent = r
		flyBG = Instance.new("BodyGyro")
		flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
		flyBG.P = 4000
		flyBG.Parent = r
	else
		if flyBV then pcall(function() flyBV:Destroy() end) flyBV = nil end
		if flyBG then pcall(function() flyBG:Destroy() end) flyBG = nil end
		local h = hum()
		if h then h.PlatformStand = false end
	end
end

track(RUN.RenderStepped:Connect(function()
	if not cfg.fly then return end
	local r, h = root(), hum()
	if not r or not h then return end
	local cam = workspace.CurrentCamera
	local dir = Vector3.zero
	if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
	if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
	if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
	if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
	if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
	if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end
	h.PlatformStand = true
	if flyBV then flyBV.Velocity = dir * cfg.flySpeed end
	if flyBG then flyBG.CFrame = cam.CFrame end
end))

task.spawn(function()
	while task.wait(0.3) do
		local h = hum()
		if h then
			if cfg.noclip and ch() then
				for _, v in ipairs(ch():GetDescendants()) do
					if v:IsA("BasePart") then v.CanCollide = false end
				end
			end
			if cfg.god and h.Health < h.MaxHealth then h.Health = h.MaxHealth end
			if not cfg.fly then
				if h.WalkSpeed ~= cfg.speed then h.WalkSpeed = cfg.speed end
			end
			if h.JumpPower ~= cfg.jump then h.JumpPower = cfg.jump end
		end
	end
end)

track(UIS.JumpRequest:Connect(function()
	if cfg.infJump then
		local h = hum()
		if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end))

task.spawn(function()
	while task.wait(1) do
		if cfg.espOther then pcall(espPlayer) end
		if cfg.espItem then pcall(espItems) end
	end
end)

task.spawn(function()
	while task.wait(4) do
		if cfg.autoPick then
			for _, nm in ipairs({ "AK-47", "Remington 870", "M9", "M4A1", "Handcuffs", "Taser" }) do
				giveItem(nm)
				task.wait(0.1)
			end
		end
	end
end)

-- ================= 传送点 =================
local PLACES = {
	{ "食堂", "Cafeteria" },
	{ "院子", "Yard" },
	{ "军械库", "Armory" },
	{ "牢房", "Cell" },
	{ "健身房", "Gym" },
	{ "屋顶", "Roof" },
	{ "塔楼", "Tower" },
	{ "草坪", "Lawn" },
	{ "机库", "Hangar" },
}

local function findPlace(kw)
	for _, d in ipairs(WS:GetDescendants()) do
		if d:IsA("BasePart") and d.Anchored and d.Name:lower():find(kw:lower(), 1, true) then
			return d
		end
	end
	return nil
end

local function tpTo(pos)
	local r = root()
	if not r then return end
	call("RequestHere", pos)
	task.wait(0.2)
	if r and r.Parent then
		pcall(function() r.CFrame = CFrame.new(pos + Vector3.new(0, 4, 0)) end)
	end
end

-- ================= 界面 =================
local T1 = Win:Tab({ Title = "主功能", Icon = "box" })
T1:Section({ Title = "物品" })
T1:Button({
	Title = "获取全部物品 / 武器",
	Desc = "遍历 Prison_ITEMS 下所有条目",
	Callback = function()
		local okc, all = giveAll()
		notif("物品", ("成功 %d / %d"):format(okc, all))
	end,
})

local itemList = itemNames()
if #itemList == 0 then itemList = { "AK-47", "Remington 870", "M9", "M4A1", "Handcuffs", "Taser" } end
T1:Dropdown({
	Title = "单个物品",
	Values = itemList,
	Value = itemList[1],
	Callback = function(v) cfg.oneItem = v end,
})
T1:Button({
	Title = "获取选中物品",
	Callback = function()
		local nm = cfg.oneItem or itemList[1]
		local ok, how = giveItem(nm)
		notif("物品", ok and (nm .. " 已获取（" .. tostring(how) .. "）") or (nm .. " 失败：" .. tostring(how)))
	end,
})
T1:Toggle({ Title = "自动补枪（每 4 秒）", Value = false, Callback = function(v) cfg.autoPick = v end })

T1:Section({ Title = "枪械强化（本地）" })
T1:Toggle({
	Title = "无限弹药 / 零散射 / 射速拉满",
	Value = false,
	Callback = function(v)
		cfg.gunMod = v
		if v then
			local n = applyGunMod()
			notif("枪械", n > 0 and ("已改 " .. n .. " 把枪") or "背包里没枪，先拿一把")
		end
	end,
})

T1:Section({ Title = "身份" })
T1:Button({ Title = "变成狱警 Guards", Callback = function()
	local ok = call("RequestTeamChange", "Guards")
	notif("身份", ok and "已请求切换" or "远程不可用")
end })
T1:Button({ Title = "变成囚犯 Inmates", Callback = function()
	call("RequestTeamChange", "Inmates"); notif("身份", "已请求切换")
end })
T1:Button({ Title = "变成罪犯 Criminals", Callback = function()
	call("RequestTeamChange", "Criminals"); notif("身份", "已请求切换")
end })
T1:Button({ Title = "重新加载角色", Callback = function()
	local ok = call("loadchar")
	notif("角色", ok and "已请求" or "没有 loadchar 远程")
end })

local T2 = Win:Tab({ Title = "战斗", Icon = "crosshair" })
T2:Section({ Title = "瞄准" })
T2:Toggle({ Title = "自动瞄准", Value = false, Callback = function(v) cfg.aim = v end })
T2:Slider({ Title = "瞄准范围（像素）", Value = { Min = 40, Max = 600, Default = 140 }, Callback = function(v) cfg.aimFov = v end })
T2:Slider({ Title = "平滑度（越小越硬）", Value = { Min = 5, Max = 100, Default = 35 }, Callback = function(v) cfg.aimSmooth = v / 100 end })
T2:Dropdown({ Title = "瞄准部位", Values = { "Head", "Torso", "HumanoidRootPart" }, Value = "Head", Callback = function(v) cfg.aimPart = v end })
T2:Toggle({ Title = "自动开火", Value = false, Callback = function(v) cfg.autoFire = v end })

local T3 = Win:Tab({ Title = "逮捕", Icon = "shield" })
T3:Section({ Title = "监狱警察" })
T3:Toggle({ Title = "自动逮捕罪犯", Value = false, Callback = function(v) cfg.autoArrest = v end })
T3:Toggle({ Title = "逮捕前自动装备手铐", Value = true, Callback = function(v) cfg.handcuff = v end })
T3:Slider({ Title = "逮捕范围", Value = { Min = 5, Max = 120, Default = 30 }, Callback = function(v) cfg.arrestRange = v end })
T3:Button({ Title = "逮捕范围内全部", Callback = function()
	local n = 0
	for _, pl in ipairs(criminals(cfg.arrestRange)) do
		if arrestOne(pl) then n = n + 1 end
		task.wait(0.15)
	end
	notif("逮捕", ("处理 %d 人"):format(n))
end })

local T4 = Win:Tab({ Title = "移动", Icon = "move" })
T4:Section({ Title = "基础" })
T4:Toggle({ Title = "无限跳跃", Value = false, Callback = function(v) cfg.infJump = v end })
T4:Toggle({ Title = "穿墙", Value = false, Callback = function(v) cfg.noclip = v end })
T4:Toggle({ Title = "飞行（WASD + 空格/Shift）", Value = false, Callback = function(v) setFly(v) end })
T4:Toggle({ Title = "本地无敌（拉血量）", Value = false, Callback = function(v) cfg.god = v end })
T4:Slider({ Title = "速度", Value = { Min = 16, Max = 200, Default = 16 }, Callback = function(v) cfg.speed = v end })
T4:Slider({ Title = "跳跃力", Value = { Min = 50, Max = 300, Default = 50 }, Callback = function(v) cfg.jump = v end })
T4:Slider({ Title = "飞行速度", Value = { Min = 20, Max = 300, Default = 60 }, Callback = function(v) cfg.flySpeed = v end })

local T5 = Win:Tab({ Title = "传送", Icon = "map-pin" })
T5:Section({ Title = "地点" })
for _, p in ipairs(PLACES) do
	T5:Button({
		Title = p[1],
		Callback = function()
			local part = findPlace(p[2])
			if part then
				tpTo(part.Position)
				notif("传送", "已到 " .. p[1])
			else
				notif("传送", "本局没找到 " .. p[1])
			end
		end,
	})
end
T5:Section({ Title = "玩家" })
local pnames = {}
for _, pl in ipairs(P:GetPlayers()) do
	if pl ~= LP then pnames[#pnames + 1] = pl.Name end
end
if #pnames == 0 then pnames = { "（无人）" } end
T5:Dropdown({ Title = "选择玩家", Values = pnames, Value = pnames[1], Callback = function(v) cfg.tpName = v end })
T5:Button({ Title = "传送到该玩家", Callback = function()
	local pl = P:FindFirstChild(cfg.tpName or "")
	local tr = pl and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
	if tr then
		tpTo(tr.Position)
		notif("传送", "已到 " .. pl.Name)
	else
		notif("传送", "找不到该玩家")
	end
end })

local T6 = Win:Tab({ Title = "透视", Icon = "eye" })
T6:Section({ Title = "透视" })
T6:Toggle({ Title = "玩家透视（按队伍上色）", Value = false, Callback = function(v)
	cfg.espOther = v
	if not v then clearEsp() end
end })
T6:Toggle({ Title = "物品高亮（武器/手铐）", Value = false, Callback = function(v)
	cfg.espItem = v
	if not v then clearItemEsp() end
end })
T6:Slider({ Title = "显示距离", Value = { Min = 50, Max = 2000, Default = 600 }, Callback = function(v) cfg.espDist = v end })

local T7 = Win:Tab({ Title = "设置", Icon = "settings" })
T7:Section({ Title = "诊断" })
T7:Button({ Title = "复制环境报告", Callback = function()
	local lines = {}
	lines[#lines + 1] = "== Prison Life 环境 =="
	lines[#lines + 1] = "PlaceId=" .. tostring(game.PlaceId) .. " 队伍=" .. tostring(LP.Team and LP.Team.Name)
	local rsr = RS:FindFirstChild("Remotes")
	lines[#lines + 1] = "Remotes 容器=" .. (rsr and "有" or "无")
	if rsr then
		local names = {}
		for _, c in ipairs(rsr:GetChildren()) do names[#names + 1] = c.Name end
		table.sort(names)
		lines[#lines + 1] = "Remotes: " .. table.concat(names, ", ")
	end
	local old = WS:FindFirstChild("Remote")
	if old then
		local names = {}
		for _, c in ipairs(old:GetChildren()) do names[#names + 1] = c.Name end
		table.sort(names)
		lines[#lines + 1] = "workspace.Remote: " .. table.concat(names, ", ")
	end
	lines[#lines + 1] = "物品条目: " .. table.concat(itemNames(), ", ")
	local guns = {}
	for _, t in ipairs(gunTools()) do guns[#guns + 1] = t.Name end
	lines[#lines + 1] = "背包枪械: " .. (#guns > 0 and table.concat(guns, ", ") or "无")
	local txt = table.concat(lines, "\n")
	if setclipboard then pcall(setclipboard, txt) end
	if toclipboard then pcall(toclipboard, txt) end
	notif("诊断", "已复制，粘贴发作者")
end })
T7:Button({ Title = "关闭脚本（清理）", Callback = function()
	if getgenv().PL_Unload then pcall(getgenv().PL_Unload) end
end })

-- ================= 卸载 =================
getgenv().PL_Unload = function()
	for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
	conns = {}
	pcall(function() setFly(false) end)
	pcall(clearEsp)
	pcall(clearItemEsp)
	getgenv().PL_Unload = nil
end

notif("监狱人生", "已加载 · 先点「获取全部物品」")
