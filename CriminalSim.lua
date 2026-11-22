-- ============================================================
-- 婴儿脚本 · 犯罪模拟器（岛屿）Hub
-- 适配：[ISLAND] Criminal Simulator (PlaceId 10769851460)
-- 功能：战利品ESP / NPC ESP / 飞行 / 穿墙 / 自动扎带 / 传送 /
--       飞行跳 / 静默自瞄 / 去扩散 / 自由视角
-- ============================================================
local WindUI = getgenv().WindUI
if not WindUI then
	local ok, res = pcall(function()
		return loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/Footagesus/WindUI@main/dist/main.lua"))()
	end)
	if ok and type(res) == "table" then
		WindUI = res
		getgenv().WindUI = res
	end
end
if not WindUI then
	warn("[犯罪模拟器] WindUI 加载失败")
	return
end

local P = game:GetService("Players")
local WS = game:GetService("Workspace")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local CS = game:GetService("CollectionService")
local TS = game:GetService("TweenService")
local LP = P.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")
local Cam = WS.CurrentCamera

-- 旧实例清理（避免重复执行叠加）
if getgenv().CrimBabyStop then pcall(getgenv().CrimBabyStop) end
for _, n in ipairs({"CrimBabyESP", "CrimBabyFreecam"}) do
	local old = PG:FindFirstChild(n)
	if old then old:Destroy() end
end
for _, d in ipairs(WS:GetDescendants()) do
	if d.Name == "CrimBabyHL" or d.Name == "CrimBabyBB" then pcall(function() d:Destroy() end) end
end

-- ---------- ESP 图层 ----------
local espGui = Instance.new("ScreenGui")
espGui.Name = "CrimBabyESP"
espGui.ResetOnSpawn = false
espGui.IgnoreGuiInset = true
espGui.DisplayOrder = 999
espGui.Parent = PG

-- 自由视角退出按钮
local fcExit = Instance.new("TextButton")
fcExit.Size = UDim2.new(0, 120, 0, 40)
fcExit.Position = UDim2.new(0.5, -60, 0, 90)
fcExit.BackgroundColor3 = Color3.fromRGB(160, 45, 45)
fcExit.TextColor3 = Color3.new(1, 1, 1)
fcExit.Font = Enum.Font.GothamBold
fcExit.TextSize = 14
fcExit.Text = "退出自由视角"
fcExit.Visible = false
fcExit.Parent = espGui
pcall(function()
	local c = Instance.new("UICorner", fcExit)
	c.CornerRadius = UDim.new(0, 8)
end)

local COL = {
	Loot = Color3.fromRGB(255, 205, 60),
	Safe = Color3.fromRGB(255, 70, 70),
	Card = Color3.fromRGB(120, 255, 160),
	Cop = Color3.fromRGB(90, 170, 255),
	Guard = Color3.fromRGB(255, 170, 70),
	Npc = Color3.fromRGB(140, 255, 160),
	Dog = Color3.fromRGB(255, 130, 220),
}

local LOOT_NAMES = {
	CashBag = true, GoldBar = true, DiamondNecklace = true, Handbag = true,
	SeizedCash = true, TaserItem = true, CashBox = true, PoliceRadio = true,
	PoliceBadge = true, Ring = true, RingBox = true, Wallet = true,
	Watch = true, Necklace = true, Valuables = true, Item = true,
}

local state = {
	loot = false, showValue = true, range = 500,
	cop = false, guard = false, npc = false, dog = false,
	fly = false, flySpeed = 70, flyMode = "cam",
	noclip = false, flyJump = false,
	autoZip = false, zipDist = 26,
	aim = false, noSpread = false, freecam = false,
	grabNear = false, grabRange = 60,
	autoTp = false, tpDelay = 1, collectAll = false, collectLeft = 0,
	preferValue = true, minValue = 0,
	aura = false, auraRange = 22, auraDelay = 0.25, auraFace = true,
}

local hlStore = {}    -- [instance] = {hl=, bb=, kind=}
local npcStore = {}
local conns = {}
local function on(sig, fn)
	local c = sig:Connect(fn)
	conns[#conns + 1] = c
	return c
end

local function money(n)
	if type(n) ~= "number" then return "" end
	return "$" .. tostring(math.floor(n)):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function root()
	local ch = LP.Character
	local r = ch and ch:FindFirstChild("HumanoidRootPart")
	return r
end

local function lootFolder()
	local f = WS:FindFirstChild("Loot")
	return f
end

local function itemValue(m)
	local v = m:GetAttribute("Value")
	if typeof(v) == "number" and v > 0 then return v end
	local fv = m:GetAttribute("FreeValue")
	if typeof(fv) == "number" and fv > 0 then return fv end
	for _, k in ipairs({ "Worth", "Price", "Money", "Amount", "Cash", "Reward" }) do
		local a = m:GetAttribute(k)
		if typeof(a) == "number" and a > 0 then return a end
	end
	for _, d in ipairs(m:GetChildren()) do
		if d:IsA("NumberValue") or d:IsA("IntValue") then
			local n = string.lower(tostring(d.Name))
			if n:find("value") or n:find("worth") or n:find("price") then
				if d.Value > 0 then return d.Value end
			end
		end
	end
	local num = tostring(m.Name):match("(%d+)")
	if num and tonumber(num) then return tonumber(num) end
	return 0
end

local function itemLabel(m)
	local kind = m:GetAttribute("Kind")
	if kind and kind ~= "" then return kind end
	local tpl = m:GetAttribute("Template")
	if tpl and tpl ~= "" then return tpl end
	return m.Name
end

local function partOf(m)
	if m:IsA("BasePart") then return m end
	local hrp = m:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then return hrp end
	local head = m:FindFirstChild("Head")
	if head and head:IsA("BasePart") then return head end
	return m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true)
end

local function inAnyCharacter(obj)
	for _, p in ipairs(P:GetPlayers()) do
		if p.Character and obj:IsDescendantOf(p.Character) then return true end
	end
	return false
end

local function dropMark(inst)
	local r = hlStore[inst]
	if not r then return end
	pcall(function() if r.hl then r.hl:Destroy() end end)
	pcall(function() if r.bb then r.bb:Destroy() end end)
	hlStore[inst] = nil
end

local function clearAllMarks()
	for inst in pairs(hlStore) do dropMark(inst) end
	for inst, r in pairs(npcStore) do
		pcall(function() if r.hl then r.hl:Destroy() end end)
		pcall(function() if r.bb then r.bb:Destroy() end end)
		npcStore[inst] = nil
	end
end

local function ensureHL(obj, color, name, transparency)
	local rec = hlStore[obj]
	if rec and rec.hl and rec.hl.Parent then
		rec.hl.FillColor = color
		rec.hl.OutlineColor = color
		return rec
	end
	local hl = Instance.new("Highlight")
	hl.Name = "CrimBabyHL"
	hl.Adornee = obj
	hl.FillColor = color
	hl.OutlineColor = color
	hl.FillTransparency = transparency or 0.55
	hl.OutlineTransparency = 0.1
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Parent = obj
	rec = { hl = hl, kind = name }
	hlStore[obj] = rec
	return rec
end

local function ensureBB(rec, part, color)
	if rec.bb and rec.bb.Parent then return rec.bb end
	local bb = Instance.new("BillboardGui")
	bb.Name = "CrimBabyBB"
	bb.Adornee = part
	bb.AlwaysOnTop = true
	bb.Size = UDim2.new(0, 130, 0, 22)
	bb.StudsOffset = Vector3.new(0, 2.2, 0)
	bb.MaxDistance = 3000
	bb.Parent = espGui
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, 0, 1, 0)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamBold
	t.TextSize = 13
	t.TextColor3 = color
	t.TextStrokeTransparency = 0.35
	t.Text = ""
	t.Parent = bb
	rec.bb = bb
	rec.txt = t
	return bb
end

-- ---------- 战利品 ESP ----------
local function isLoot(d)
	if not (d:IsA("Model") or d:IsA("BasePart")) then return false, false end
	local n = d.Name
	if n:find("Safe") or n == "SafeDialing" then return true, true end
	if LOOT_NAMES[n] then return true, false end
	return false, false
end

local function scanLoot()
	local rootPart = root()
	if not rootPart then return end
	local pos = rootPart.Position
	local seen = {}
	local list = {}

	local f = lootFolder()
	if f then
		for _, c in ipairs(f:GetChildren()) do
			list[#list + 1] = c
		end
	else
		-- 兜底：全场景按名字找
		for _, d in ipairs(WS:GetDescendants()) do
			local ok2 = isLoot(d)
			if ok2 then list[#list + 1] = d end
		end
	end

	for _, m in ipairs(list) do
		if (m:IsA("Model") or m:IsA("BasePart")) and not inAnyCharacter(m) then
			local part = partOf(m)
			if part then
				local dist = (part.Position - pos).Magnitude
				if dist <= state.range then
					seen[m] = true
					local isSafe = tostring(m.Name):find("Safe") ~= nil
					local kind = m:GetAttribute("Kind")
					local color = COL.Loot
					if isSafe then
						color = COL.Safe
					elseif kind == "CreditCard" or kind == "GiftCard" then
						color = COL.Card
					end
					local rec = ensureHL(m, color, "loot", 0.55)
					ensureBB(rec, part, color)
					if rec.txt then
						local txt = "◆ " .. itemLabel(m)
						local v = itemValue(m)
						if state.showValue and v > 0 then txt = txt .. " " .. money(v) end
						txt = txt .. " (" .. math.floor(dist) .. "m)"
						if rec.txt.Text ~= txt then rec.txt.Text = txt end
					end
				end
			end
		end
	end
	for inst in pairs(hlStore) do
		if not seen[inst] then dropMark(inst) end
	end
end

-- ---------- NPC ESP ----------
local NPC_TAGS = {
	{ tag = "Cop", color = COL.Cop, key = "cop" },
	{ tag = "Guard", color = COL.Guard, key = "guard" },
	{ tag = "Npc", color = COL.Npc, key = "npc" },
	{ tag = "Dog", color = COL.Dog, key = "dog" },
}

local function scanNPC()
	local rootPart = root()
	if not rootPart then return end
	local pos = rootPart.Position
	local seen = {}
	for _, def in ipairs(NPC_TAGS) do
		if state[def.key] then
			local ok, tagged = pcall(function() return CS:GetTagged(def.tag) end)
			if ok and tagged then
				for _, m in ipairs(tagged) do
					if m:IsA("Model") and m:IsDescendantOf(WS) then
						local h = m:FindFirstChildOfClass("Humanoid")
						local part = partOf(m)
						if part and (not h or h.Health > 0) then
							local dist = (part.Position - pos).Magnitude
							if dist <= state.range then
								seen[m] = true
								local rec = npcStore[m]
								if not rec then
									local hl = Instance.new("Highlight")
									hl.Name = "CrimBabyHL"
									hl.Adornee = m
									hl.FillColor = def.color
									hl.OutlineColor = def.color
									hl.FillTransparency = 0.55
									hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
									hl.Parent = m
									local bb = Instance.new("BillboardGui")
									bb.Name = "CrimBabyBB"
									bb.Adornee = part
									bb.AlwaysOnTop = true
									bb.Size = UDim2.new(0, 120, 0, 20)
									bb.StudsOffset = Vector3.new(0, 3, 0)
									bb.MaxDistance = 3000
									bb.Parent = espGui
									local t = Instance.new("TextLabel")
									t.Size = UDim2.new(1, 0, 1, 0)
									t.BackgroundTransparency = 1
									t.Font = Enum.Font.GothamBold
									t.TextSize = 12
									t.TextColor3 = def.color
									t.TextStrokeTransparency = 0.35
									t.Text = def.tag .. " " .. math.floor(dist) .. "m"
									t.Parent = bb
									rec = { hl = hl, bb = bb, txt = t, tag = def.tag }
									npcStore[m] = rec
								else
									if rec.txt then
										local txt = rec.tag .. " " .. math.floor(dist) .. "m"
										if rec.txt.Text ~= txt then rec.txt.Text = txt end
									end
									if rec.bb and rec.bb.Adornee ~= part then rec.bb.Adornee = part end
								end
							end
						end
					end
				end
			end
		end
	end
	for inst, r in pairs(npcStore) do
		if not seen[inst] then
			pcall(function() if r.hl then r.hl:Destroy() end end)
			pcall(function() if r.bb then r.bb:Destroy() end end)
			npcStore[inst] = nil
		end
	end
end

-- ---------- 飞行 ----------
local flyBV, flyBG, flyConn = nil, nil, nil

local function flyStop()
	if flyConn then pcall(function() flyConn:Disconnect() end) flyConn = nil end
	if flyBV then pcall(function() flyBV:Destroy() end) flyBV = nil end
	if flyBG then pcall(function() flyBG:Destroy() end) flyBG = nil end
	local ch = LP.Character
	local h = ch and ch:FindFirstChildOfClass("Humanoid")
	if h then pcall(function() h.PlatformStand = false end) end
end

local function flyStart()
	flyStop()
	local ch = LP.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then return false, "角色还没加载" end
	pcall(function() hum.PlatformStand = true end)
	flyBV = Instance.new("BodyVelocity")
	flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	flyBV.Velocity = Vector3.zero
	flyBV.Parent = hrp
	flyBG = Instance.new("BodyGyro")
	flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
	flyBG.P = 1e4
	flyBG.CFrame = hrp.CFrame
	flyBG.Parent = hrp
	flyConn = RS.RenderStepped:Connect(function()
		if not state.fly then return end
		local c = LP.Character
		local r = c and c:FindFirstChild("HumanoidRootPart")
		if not r or not flyBV or not flyBG then return end
		local camCF = WS.CurrentCamera and WS.CurrentCamera.CFrame or r.CFrame
		local dir = Vector3.zero
		if state.flyMode == "cam" then
			dir = camCF.LookVector
		else
			if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + camCF.LookVector end
			if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - camCF.LookVector end
			if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + camCF.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - camCF.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
			if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end
		end
		if dir.Magnitude > 0 then dir = dir.Unit end
		flyBV.Velocity = dir * state.flySpeed
		flyBG.CFrame = camCF
	end)
	return true
end

-- ---------- 穿墙 ----------
local noclipConn = nil

local function noclipStop()
	if noclipConn then pcall(function() noclipConn:Disconnect() end) noclipConn = nil end
	local ch = LP.Character
	if ch then
		for _, p in ipairs(ch:GetDescendants()) do
			if p:IsA("BasePart") then pcall(function() p.CanCollide = true end) end
		end
	end
end

local function noclipStart()
	noclipStop()
	noclipConn = RS.Stepped:Connect(function()
		if not state.noclip then return end
		local ch = LP.Character
		if ch then
			for _, p in ipairs(ch:GetDescendants()) do
				if p:IsA("BasePart") then p.CanCollide = false end
			end
		end
	end)
end

-- ---------- 飞行跳 ----------
local jumpConn = nil

local function flyJumpStop()
	if jumpConn then pcall(function() jumpConn:Disconnect() end) jumpConn = nil end
end

local function flyJumpStart()
	flyJumpStop()
	jumpConn = UIS.JumpRequest:Connect(function()
		if not state.flyJump then return end
		local ch = LP.Character
		local h = ch and ch:FindFirstChildOfClass("Humanoid")
		if h then
			pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end)
			pcall(function() h:ChangeState(Enum.HumanoidStateType.Freefall) end)
		end
	end)
end

-- ---------- 自动扎带 ----------
local zipPrompts = {}
local zipFired = {}
local zipConn = nil

local function zipTry(p)
	if not p or not p.Parent then return end
	pcall(function()
		if p.MaxActivationDistance ~= state.zipDist then
			p.MaxActivationDistance = state.zipDist
			p.RequiresLineOfSight = false
			p.HoldDuration = 0
			p.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
		end
		if type(fireproximityprompt) == "function" then pcall(fireproximityprompt, p) end
		p:InputHoldBegin()
	end)
	task.defer(function()
		if p and p.Parent then pcall(function() p:InputHoldEnd() end) end
	end)
end

local function collectPrompts()
	zipPrompts = {}
	for _, d in ipairs(WS:GetDescendants()) do
		if d:IsA("ProximityPrompt") and d.Name == "ZipTiePrompt" then
			zipPrompts[#zipPrompts + 1] = d
		end
	end
end

local function zipStart()
	zipStop()
	collectPrompts()
	zipConn = on(WS.DescendantAdded, function(d)
		if d:IsA("ProximityPrompt") and d.Name == "ZipTiePrompt" then
			zipPrompts[#zipPrompts + 1] = d
		end
	end)
end

function zipStop()
	if zipConn then pcall(function() zipConn:Disconnect() end) zipConn = nil end
end

-- ---------- 自动拾取（抓取物品） ----------
local grabFired = {}
local grabTries = {}
local grabCache = { t = -99, list = {} }

local function promptLooksLoot(p)
	local n = string.lower(tostring(p.Name))
	if n:find("zip") or n:find("tie") then return false end
	local pn = p.Parent and tostring(p.Parent.Name) or ""
	if LOOT_NAMES[pn] then return true end
	if p.Parent and itemValue(p.Parent) > 0 then return true end
	return (n:find("grab") or n:find("pick") or n:find("take") or n:find("loot")
		or n:find("collect") or n:find("steal") or n:find("stash") or n:find("carry")
		or n:find("equip") or n:find("interact") or n:find("open") or n:find("money")) ~= nil
end

local function firstOfClass(obj, cls)
	for _, d in ipairs(obj:GetDescendants()) do
		if d:IsA(cls) then return d end
	end
	return nil
end

-- 扫描全部可拾取目标（不靠猜名字：Loot 文件夹里的东西无条件收）
local function grabCandidates()
	local out = {}
	local seen = {}
	local r = root()
	local pos = r and r.Position or Vector3.new()
	local function push(obj, prompt, cd)
		if not obj or seen[obj] then return end
		if inAnyCharacter(obj) then return end
		local part = partOf(obj)
		if not part then return end
		seen[obj] = true
		out[#out + 1] = {
			obj = obj, part = part, prompt = prompt, cd = cd,
			value = itemValue(obj), label = itemLabel(obj),
			dist = (part.Position - pos).Magnitude,
		}
	end
	local f = lootFolder()
	if f then
		for _, c in ipairs(f:GetChildren()) do
			if c:IsA("Model") or c:IsA("BasePart") then
				push(c, firstOfClass(c, "ProximityPrompt"), firstOfClass(c, "ClickDetector"))
			end
		end
	end
	for _, d in ipairs(WS:GetDescendants()) do
		if d:IsA("ProximityPrompt") and d.Parent and promptLooksLoot(d) then
			push(d.Parent, d, nil)
		end
	end
	for _, d in ipairs(WS:GetDescendants()) do
		if d:IsA("ClickDetector") and d.Parent and (d.Parent:IsA("Model") or d.Parent:IsA("BasePart")) then
			if not inAnyCharacter(d.Parent) then push(d.Parent, nil, d) end
		end
	end
	table.sort(out, function(a, b)
		if state.preferValue and a.value ~= b.value then return a.value > b.value end
		return a.dist < b.dist
	end)
	return out
end

local function grabList(force)
	if force or os.clock() - grabCache.t > 0.7 then
		grabCache.t = os.clock()
		grabCache.list = grabCandidates()
	end
	return grabCache.list
end

-- 真正触发拾取：三种方式一起上（执行器远程函数 / 按键按住 / 点击）
local function grabFire(t, dist, allowTp)
	if not t then return false end
	local p, cd = t.prompt, t.cd
	local fired = false
	if p and p.Parent and p.Enabled ~= false then
		pcall(function()
			if p.MaxActivationDistance < dist then p.MaxActivationDistance = dist end
			p.RequiresLineOfSight = false
			p.HoldDuration = 0
			p.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
		end)
		if type(fireproximityprompt) == "function" then
			pcall(fireproximityprompt, p)
			fired = true
		end
		pcall(function() p:InputHoldBegin() end)
		task.delay(0.1, function()
			if p and p.Parent then pcall(function() p:InputHoldEnd() end) end
		end)
		fired = true
	end
	if cd and cd.Parent then
		pcall(function() cd.MaxActivationDistance = math.max(cd.MaxActivationDistance, dist) end)
		if type(fireclickdetector) == "function" then pcall(fireclickdetector, cd) end
		fired = true
	end
	-- 没有拾取点：只能靠贴过去触发（Touched / 自动拾取）
	if not fired and allowTp then
		local r = root()
		if r and t.part then
			pcall(function() r.CFrame = CFrame.new(t.part.Position + Vector3.new(0, 3, 0)) end)
			fired = true
		end
	end
	return fired
end

local function grabTick(dist)
	local n = 0
	for _, t in ipairs(grabList()) do
		if t.dist <= dist then
			local last = grabFired[t.obj] or 0
			local tries = grabTries[t.obj] or 0
			if tries < 3 and os.clock() - last >= 0.4 then
				grabFired[t.obj] = os.clock()
				if grabFire(t, dist, false) then
					n = n + 1
					grabTries[t.obj] = tries + 1
				end
			end
		end
	end
	return n
end

-- 按「价值优先」挑一个目标
local function pickBest(list)
	for _, t in ipairs(list) do
		if t.obj and t.obj.Parent then
			local tries = grabTries[t.obj] or 0
			if tries < 3 and t.value >= state.minValue then
				return t
			end
		end
	end
	return nil
end

-- 主循环：自动抓取 / 自动传送拾取 / 一键收集
local grabRunning = false
local function grabLoop()
	if grabRunning then return end
	grabRunning = true
	task.spawn(function()
		local nextReset = os.clock() + 60
		while grabRunning do
			if not (state.grabNear or state.autoTp or state.collectAll) then
				grabRunning = false
				break
			end
			if os.clock() >= nextReset then
				nextReset = os.clock() + 60
				grabTries = {}
			end
			local r = root()
			if not r then
				task.wait(0.5)
			elseif state.autoTp or state.collectAll then
				if state.collectAll and (state.collectLeft or 0) <= 0 then
					state.collectAll = false
					pcall(function()
						WindUI:Notify({ Title = "自动拾取", Content = "一键收集结束", Duration = 3 })
					end)
				else
					local t = pickBest(grabList())
					if not t then
						task.wait(0.8)
					else
						if t.dist > 4 then
							pcall(function() r.CFrame = CFrame.new(t.part.Position + Vector3.new(0, 3.5, 0)) end)
							task.wait(0.35)
						end
						grabFire(t, math.max(state.grabRange, 25), true)
						grabFired[t.obj] = os.clock()
						grabTries[t.obj] = (grabTries[t.obj] or 0) + 1
						if state.collectAll then state.collectLeft = (state.collectLeft or 0) - 1 end
						task.wait(math.max(0.3, state.tpDelay))
					end
				end
			else
				grabTick(state.grabRange)
				task.wait(0.3)
			end
		end
		grabRunning = false
	end)
end

-- ---------- 范围攻击（Knockout Aura） ----------
local auraTargets = { cop = true, guard = true, npc = true, dog = true }

local function findHitRemote()
	local remotes = RS:FindFirstChild("Remotes") or WS:FindFirstChild("Remotes")
	if not remotes then return nil end
	for _, c in ipairs(remotes:GetChildren()) do
		local n = string.lower(tostring(c.Name))
		if c:IsA("RemoteEvent") and (n:find("punch") or n:find("hit") or n:find("attack") or n:find("knock")) then
			return c
		end
	end
	return nil
end

-- 标签找不到时，按「有 Humanoid 且不是玩家」兜底扫全场
local function scanNpcs()
	local out = {}
	for _, d in ipairs(WS:GetChildren()) do
		if d:IsA("Model") then
			local hum = d:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 and not inAnyCharacter(d) then
				out[#out + 1] = d
			end
		end
	end
	return out
end

local function auraPick()
	local r = root()
	if not r then return nil end
	local pos = r.Position
	local best, bestD = nil, state.auraRange
	local function consider(m)
		if not m or not m:IsA("Model") or not m:IsDescendantOf(WS) then return end
		local hum = m:FindFirstChildOfClass("Humanoid")
		local part = m:FindFirstChild("Head") or partOf(m)
		if part and hum and hum.Health > 0 then
			local d = (part.Position - pos).Magnitude
			if d <= bestD then best, bestD = m, d end
		end
	end
	for _, def in ipairs(NPC_TAGS) do
		if auraTargets[def.key] then
			local ok, tagged = pcall(function() return CS:GetTagged(def.tag) end)
			if ok and tagged then
				for _, m in ipairs(tagged) do consider(m) end
			end
		end
	end
	if not best then
		for _, m in ipairs(scanNpcs()) do consider(m) end
	end
	return best, bestD
end

-- 开火：武器 / 拳头 / 枪械都走这一套
local function fireWeapon(tool)
	if tool then
		pcall(function() tool:Activate() end)
		for _, d in ipairs(tool:GetDescendants()) do
			if d:IsA("RemoteEvent") then
				local n = string.lower(tostring(d.Name))
				if n:find("hit") or n:find("attack") or n:find("punch") or n:find("fire") or n:find("shoot") then
					pcall(function() d:FireServer() end)
				end
			end
		end
	end
	-- 模拟鼠标左键：枪械、拳头、近战都吃这个
	pcall(function() mouse1click() end)
	pcall(function()
		local vim = game:GetService("VirtualInputManager")
		vim:SendMouseButtonEvent(0, 0, 0, true, game, 0)
		task.wait(0.02)
		vim:SendMouseButtonEvent(0, 0, 0, false, game, 0)
	end)
end

local function auraAttack()
	local target = auraPick()
	if not target then return false end
	local r = root()
	local head = target:FindFirstChild("Head") or partOf(target)
	if not r or not head then return false end
	if state.auraFace then
		pcall(function()
			r.CFrame = CFrame.lookAt(r.Position, Vector3.new(head.Position.X, r.Position.Y, head.Position.Z))
		end)
	end
	local ch = LP.Character
	local tool = ch and ch:FindFirstChildOfClass("Tool")
	fireWeapon(tool)
	local rem = findHitRemote()
	if rem then
		pcall(function() rem:FireServer(target) end)
		pcall(function() rem:FireServer(head) end)
	end
	return true
end

task.spawn(function()
	while true do
		task.wait(math.max(0.08, state.auraDelay))
		if state.aura then pcall(auraAttack) end
	end
end)

-- ---------- 静默自瞄 / 去扩散 ----------
local GunShot, GunFire = nil, nil
local aimHooked, aimBusy = false, false
local savedSpread = nil

local function loadGun()
	if GunShot and GunFire then return true end
	local shared = RS:FindFirstChild("Shared")
	local mod = shared and shared:FindFirstChild("GunShot")
	local remotes = RS:FindFirstChild("Remotes")
	local ev = remotes and remotes:FindFirstChild("GunFire")
	if not mod or not ev then return false end
	local ok, res = pcall(require, mod)
	if not ok or type(res) ~= "table" or not res.GUNS then return false end
	GunShot, GunFire = res, ev
	return true
end

local function setSpread(onoff)
	if not GunShot or not GunShot.GUNS then return false end
	local G = GunShot.GUNS
	if onoff then
		savedSpread = {}
		for name, gun in pairs(G) do
			if type(gun) == "table" and gun.spread ~= nil then
				savedSpread[name] = gun.spread
				pcall(function() gun.spread = 0 end)
			end
		end
	elseif savedSpread then
		for name, v in pairs(savedSpread) do
			if G[name] then pcall(function() G[name].spread = v end) end
		end
		savedSpread = nil
	end
	return true
end

local AIM_TAGS = { "Npc", "Cop", "Guard", "Dog" }
local AIM_FOV = 35
local AIM_RANGE = 300

local function aimPick(origin, look)
	local best, bestDot = nil, math.cos(math.rad(AIM_FOV / 2))
	for _, tag in ipairs(AIM_TAGS) do
		local ok, tagged = pcall(function() return CS:GetTagged(tag) end)
		if ok and tagged then
			for _, m in ipairs(tagged) do
				if m:IsA("Model") and m:IsDescendantOf(WS) then
					local hum = m:FindFirstChildOfClass("Humanoid")
					local head = m:FindFirstChild("Head")
					if hum and head and head:IsA("BasePart") and hum.Health > 0 then
						local d = head.Position - origin
						local dist = d.Magnitude
						if dist > 0.5 and dist <= AIM_RANGE then
							local dot = (d.Unit).Dot(look)
							if dot > bestDot then
								best, bestDot = head, dot
							end
						end
					end
				end
			end
		end
	end
	return best
end

local function installAimHook()
	if aimHooked then return true end
	if type(hookmetamethod) ~= "function" or type(newcclosure) ~= "function" then return false end
	if not loadGun() then return false end
	local old
	local ok = pcall(function()
		old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
			local method = getnamecallmethod()
			if self ~= GunFire or method ~= "FireServer" then
				return old(self, ...)
			end
			if aimBusy or not state.aim then return old(self, ...) end
			local _, org, _, pos = ...
			if org == nil or pos == nil then return old(self, ...) end
			local ch = LP.Character
			local tool = ch and ch:FindFirstChildOfClass("Tool")
			if not tool or (tool.Name ~= "Pistol" and tool.Name ~= "AK47") then
				return old(self, ...)
			end
			local look = WS.CurrentCamera.CFrame.LookVector
			aimBusy = true
			local good, head = pcall(aimPick, org, look)
			if not good or not head then
				aimBusy = false
				return old(self, ...)
			end
			local dir = (head.Position - org).Unit
			local r1, r2 = pcall(old, self, dir, org, head, head.Position)
			aimBusy = false
			if not r1 then return old(self, ...) end
			return r2
		end))
	end)
	aimHooked = ok
	return ok
end

-- ---------- 自由视角 ----------
local fc = {
	on = false, pos = nil, rot = nil, conn = nil, conns = {},
	down = false, lastMouse = nil, keys = {},
}

local function fcStop()
	if not fc.on then return end
	fc.on = false
	for _, c in ipairs(fc.conns) do pcall(function() c:Disconnect() end) end
	fc.conns = {}
	fcExit.Visible = false
	local cam = WS.CurrentCamera
	if cam then
		pcall(function()
			cam.CameraType = Enum.CameraType.Custom
			cam.CameraSubject = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
		end)
	end
end

local function fcStart()
	if fc.on then return end
	local cam = WS.CurrentCamera
	if not cam then return false, "相机还没加载" end
	fc.on = true
	fc.pos = cam.CFrame.Position
	local rx, ry, rz = cam.CFrame:ToEulerAnglesYXZ()
	fc.rot = Vector2.new(rx, ry)
	pcall(function() cam.CameraType = Enum.CameraType.Scriptable end)
	fcExit.Visible = true

	table.insert(fc.conns, UIS.InputChanged:Connect(function(input)
		if not fc.on then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			if input.UserInputType == Enum.UserInputType.Touch and not fc.down then return end
			local d = input.Delta
			fc.rot = Vector2.new(fc.rot.X - d.Y * 0.005, fc.rot.Y - d.X * 0.005)
			fc.rot = Vector2.new(
				math.clamp(fc.rot.X, math.rad(-85), math.rad(85)),
				fc.rot.Y
			)
		end
	end))

	table.insert(fc.conns, UIS.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then fc.down = true end
	end))
	table.insert(fc.conns, UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then fc.down = false end
	end))

	fc.conn = RS.RenderStepped:Connect(function(dt)
		if not fc.on then return end
		local c = WS.CurrentCamera
		if not c then return end
		local speed = 60 * dt * 3
		local move = Vector3.zero
		local cf = CFrame.fromEulerAnglesYXZ(fc.rot.X, fc.rot.Y, 0)
		if UIS:IsKeyDown(Enum.KeyCode.W) or UIS:IsKeyDown(Enum.KeyCode.Up) then move = move + cf.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.S) or UIS:IsKeyDown(Enum.KeyCode.Down) then move = move - cf.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.D) or UIS:IsKeyDown(Enum.KeyCode.Right) then move = move + cf.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.A) or UIS:IsKeyDown(Enum.KeyCode.Left) then move = move - cf.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.E) then move = move + Vector3.new(0, 1, 0) end
		if UIS:IsKeyDown(Enum.KeyCode.Q) then move = move - Vector3.new(0, 1, 0) end
		if move.Magnitude > 0 then fc.pos = fc.pos + move.Unit * speed end
		c.CFrame = CFrame.new(fc.pos) * cf
	end)
	return true
end

fcExit.Activated:Connect(fcStop)

-- ---------- 传送 ----------
local function tpTo(pos)
	local r = root()
	if not r then return false, "角色还没加载" end
	pcall(function() r.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) end)
	return true
end

local function nearestLoot()
	local r = root()
	if not r then return nil end
	local best, bestD = nil, math.huge
	local f = lootFolder()
	local list = {}
	if f then
		for _, c in ipairs(f:GetChildren()) do list[#list + 1] = c end
	end
	for _, m in ipairs(list) do
		local part = partOf(m)
		if part then
			local d = (part.Position - r.Position).Magnitude
			if d < bestD then best, bestD = part.Position, d end
		end
	end
	return best, bestD
end

local itemsByType = {}
local function refreshItemTypes()
	itemsByType = {}
	local f = lootFolder()
	if not f then return end
	for _, m in ipairs(f:GetChildren()) do
		if m:IsA("Model") or m:IsA("BasePart") then
			local label = itemLabel(m)
			if not itemsByType[label] then itemsByType[label] = {} end
			table.insert(itemsByType[label], m)
		end
	end
end

local function typeList()
	local out = {}
	for k in pairs(itemsByType) do out[#out + 1] = k end
	table.sort(out)
	return out
end

-- ---------- 主循环 ----------
local lastScan = 0
on(RS.Heartbeat, function()
	if not (state.loot or state.cop or state.guard or state.npc or state.dog) then return end
	local now = os.clock()
	if now - lastScan < 0.35 then return end
	lastScan = now
	pcall(function()
		if state.loot then scanLoot() else
			for inst in pairs(hlStore) do dropMark(inst) end
		end
	end)
	pcall(function()
		if state.cop or state.guard or state.npc or state.dog then scanNPC() else
			for inst, r in pairs(npcStore) do
				pcall(function() if r.hl then r.hl:Destroy() end end)
				pcall(function() if r.bb then r.bb:Destroy() end end)
				npcStore[inst] = nil
			end
		end
	end)
end)

-- 自动扎带循环
task.spawn(function()
	while true do
		task.wait(0.2)
		if state.autoZip then
			pcall(function()
				for i = #zipPrompts, 1, -1 do
					local p = zipPrompts[i]
					if not p or not p.Parent then
						table.remove(zipPrompts, i)
					elseif p.Enabled then
						local t = zipFired[p] or 0
						if os.clock() - t >= 0.25 then
							zipFired[p] = os.clock()
							zipTry(p)
						end
					end
				end
			end)
		end
	end
end)

-- 重生恢复
on(LP.CharacterAdded, function()
	task.wait(1.2)
	if state.fly then pcall(flyStart) end
	if state.noclip then pcall(noclipStart) end
end)

-- ---------- UI ----------
local Win = WindUI:CreateWindow({Title = "犯罪模拟器（岛屿）"})

local T1 = Win:Tab({Title = "战利品", Icon = "gem"})
T1:Section({Title = "高亮战利品（金色=钱 红色=保险箱 绿色=银行卡）"})
T1:Toggle({Title = "战利品 ESP", Value = false, Callback = function(v)
	state.loot = v
	if not v then for inst in pairs(hlStore) do dropMark(inst) end end
end})
T1:Toggle({Title = "显示价值", Value = true, Callback = function(v) state.showValue = v end})
T1:Slider({Title = "ESP 距离（米）", Value = {Min = 100, Max = 3000, Default = 500}, Callback = function(v)
	state.range = v
end})
T1:Button({Title = "传送到最近战利品", Callback = function()
	local pos, d = nearestLoot()
	if not pos then
		WindUI:Notify({Title = "传送", Content = "附近没找到战利品", Duration = 3})
		return
	end
	local ok, why = tpTo(pos)
	if ok then
		WindUI:Notify({Title = "传送", Content = "已传送到最近战利品（" .. math.floor(d) .. "m）", Duration = 2})
	else
		WindUI:Notify({Title = "传送", Content = tostring(why), Duration = 2})
	end
end})
T1:Button({Title = "刷新物品类型列表", Callback = function()
	refreshItemTypes()
	WindUI:Notify({Title = "物品", Content = "已扫描到 " .. #typeList() .. " 种物品", Duration = 3})
end})
local chosenType = ""
T1:Dropdown({Title = "按类型传送", Values = {"（先点上面的刷新按钮）"}, Value = "（先点上面的刷新按钮）", Callback = function(v)
	chosenType = v
end})
T1:Button({Title = "传送到该类型物品", Callback = function()
	refreshItemTypes()
	local list = itemsByType[chosenType]
	if not list or #list == 0 then
		WindUI:Notify({Title = "传送", Content = "没找到这类物品，先刷新列表", Duration = 3})
		return
	end
	local r = root()
	if not r then return end
	local best, bestD
	for _, m in ipairs(list) do
		local part = partOf(m)
		if part then
			local d = (part.Position - r.Position).Magnitude
			if not bestD or d < bestD then best, bestD = part.Position, d end
		end
	end
	if best then
		tpTo(best)
		WindUI:Notify({Title = "传送", Content = "已传送到 " .. chosenType, Duration = 2})
	end
end})
T1:Button({Title = "清除所有 ESP", Callback = function()
	clearAllMarks()
	WindUI:Notify({Title = "ESP", Content = "已全部清除", Duration = 2})
end})

local T2 = Win:Tab({Title = "NPC 透视", Icon = "users"})
T2:Section({Title = "分类高亮（蓝色警察 / 橙色警卫 / 绿色平民 / 粉色狗）"})
T2:Toggle({Title = "警察 ESP", Value = false, Callback = function(v) state.cop = v end})
T2:Toggle({Title = "警卫 ESP", Value = false, Callback = function(v) state.guard = v end})
T2:Toggle({Title = "平民 ESP", Value = false, Callback = function(v) state.npc = v end})
T2:Toggle({Title = "狗 ESP", Value = false, Callback = function(v) state.dog = v end})

local T3 = Win:Tab({Title = "移动", Icon = "move"})
T3:Section({Title = "飞行"})
T3:Toggle({Title = "开启飞行", Value = false, Callback = function(v)
	state.fly = v
	if v then
		local ok, why = flyStart()
		if not ok then
			state.fly = false
			WindUI:Notify({Title = "飞行", Content = tostring(why), Duration = 3})
		end
	else
		flyStop()
	end
end})
T3:Dropdown({Title = "飞行方向", Values = {"视角前进（手机推荐）", "WASD 按键"}, Value = "视角前进（手机推荐）", Callback = function(v)
	state.flyMode = (v == "WASD 按键") and "wasd" or "cam"
end})
T3:Slider({Title = "飞行速度", Value = {Min = 20, Max = 220, Default = 70}, Callback = function(v)
	state.flySpeed = v
end})
T3:Section({Title = "移动辅助"})
T3:Toggle({Title = "穿墙（NoClip）", Value = false, Callback = function(v)
	state.noclip = v
	if v then noclipStart() else noclipStop() end
end})
T3:Toggle({Title = "空中连跳（飞行跳）", Value = false, Callback = function(v)
	state.flyJump = v
	if v then flyJumpStart() else flyJumpStop() end
end})
T3:Toggle({Title = "自由视角", Value = false, Callback = function(v)
	state.freecam = v
	if v then
		local ok, why = fcStart()
		if not ok then
			state.freecam = false
			WindUI:Notify({Title = "自由视角", Content = tostring(why), Duration = 3})
		end
	else
		fcStop()
	end
end})

local T4 = Win:Tab({Title = "抓捕", Icon = "handcuffs"})
T4:Section({Title = "自动扎带（靠近倒地 NPC 自动上扎带）"})
T4:Toggle({Title = "自动扎带", Value = false, Callback = function(v)
	state.autoZip = v
	if v then zipStart() else zipStop() end
end})
T4:Slider({Title = "扎带距离（格）", Value = {Min = 8, Max = 45, Default = 26}, Callback = function(v)
	state.zipDist = v
end})
T4:Button({Title = "刷新扎带目标", Callback = function()
	collectPrompts()
	WindUI:Notify({Title = "扎带", Content = "已扫描到 " .. #zipPrompts .. " 个可扎带目标", Duration = 3})
end})

local T4B = Win:Tab({Title = "自动拾取", Icon = "package"})
T4B:Section({Title = "优先拿贵的东西"})
T4B:Toggle({Title = "按价值从高到低拿", Value = true, Callback = function(v)
	state.preferValue = v
end})
T4B:Slider({Title = "最低价值（0 = 不限）", Value = {Min = 0, Max = 5000, Default = 0}, Callback = function(v)
	state.minValue = v
end})
T4B:Button({Title = "扫描前 8 个最值钱的东西", Callback = function()
	local list = grabList(true)
	local lines = {}
	for i2 = 1, math.min(8, #list) do
		local t = list[i2]
		lines[#lines + 1] = i2 .. ". " .. tostring(t.label) .. "  $" .. math.floor(t.value)
	end
	if #lines == 0 then
		WindUI:Notify({Title = "自动拾取", Content = "没扫描到可拾取的东西（可能地图上暂时没有战利品）", Duration = 5})
	else
		WindUI:Notify({Title = "自动拾取 · 共 " .. #list .. " 个", Content = table.concat(lines, "｜"), Duration = 8})
	end
end})
T4B:Section({Title = "抓取物品（范围内自动捡，不用走近）"})
T4B:Toggle({Title = "自动抓取附近物品", Value = false, Callback = function(v)
	state.grabNear = v
	if v then
		local list = grabList(true)
		WindUI:Notify({Title = "自动拾取", Content = "已开启，范围内发现 " .. #list .. " 个物品", Duration = 3})
		grabLoop()
	end
end})
T4B:Slider({Title = "抓取范围（格）", Value = {Min = 15, Max = 300, Default = 60}, Callback = function(v)
	state.grabRange = v
end})
T4B:Section({Title = "自动传送物品（自动飞过去把东西捡了）"})
T4B:Toggle({Title = "自动传送到战利品并拾取", Value = false, Callback = function(v)
	state.autoTp = v
	if v then
		grabList(true)
		WindUI:Notify({Title = "自动传送", Content = "已开启，会一直飞过去捡最值钱的东西", Duration = 3})
		grabLoop()
	end
end})
T4B:Slider({Title = "传送间隔（秒）", Value = {Min = 0.3, Max = 5, Default = 1}, Callback = function(v)
	state.tpDelay = v
end})
T4B:Section({Title = "批量"})
T4B:Button({Title = "一键收集全图（最多 80 个）", Callback = function()
	grabList(true)
	grabTries = {}
	state.collectLeft = 80
	state.collectAll = true
	WindUI:Notify({Title = "自动拾取", Content = "开始一键收集，按价值从高到低拿", Duration = 3})
	grabLoop()
end})
T4B:Button({Title = "停止一键收集 / 停止自动传送", Callback = function()
	state.collectAll = false
	state.autoTp = false
	WindUI:Notify({Title = "自动拾取", Content = "已停止", Duration = 2})
end})
T4B:Button({Title = "重新扫描拾取点", Callback = function()
	grabTries = {}
	local list = grabList(true)
	WindUI:Notify({Title = "自动拾取", Content = "扫描到 " .. #list .. " 个物品", Duration = 3})
end})
T4B:Paragraph({Title = "捡不起来怎么办", Content = "这个游戏一次只能扛一件东西，手里已经拿着东西时新的捡不起来——先去存掉再开。如果一直提示扫描到 0 个，说明物品的拾取点名字特殊，把靠近物品时屏幕上显示的按键文字告诉作者就能精确匹配。"})

local T5 = Win:Tab({Title = "战斗", Icon = "crosshair"})
T5:Section({Title = "范围攻击（拳头、刀、枪都能自动打）"})
T5:Toggle({Title = "范围攻击（Knockout Aura）", Value = false, Callback = function(v)
	state.aura = v
	if v then
		local ch = LP.Character
		local tool = ch and ch:FindFirstChildOfClass("Tool")
		if tool then
			WindUI:Notify({Title = "范围攻击", Content = "已开启，当前武器：" .. tostring(tool.Name), Duration = 3})
		else
			WindUI:Notify({Title = "范围攻击", Content = "已开启（空手也能打，子弹类武器建议先拿出来）", Duration = 4})
		end
	end
end})
T5:Toggle({Title = "自动转向目标", Value = true, Callback = function(v)
	state.auraFace = v
end})
T5:Slider({Title = "攻击范围（格）", Value = {Min = 8, Max = 60, Default = 22}, Callback = function(v)
	state.auraRange = v
end})
T5:Slider({Title = "出拳间隔（秒）", Value = {Min = 0.1, Max = 1.0, Default = 0.25}, Callback = function(v)
	state.auraDelay = v
end})
T5:Toggle({Title = "目标：警察", Value = true, Callback = function(v) auraTargets.cop = v end})
T5:Toggle({Title = "目标：警卫", Value = true, Callback = function(v) auraTargets.guard = v end})
T5:Toggle({Title = "目标：平民", Value = true, Callback = function(v) auraTargets.npc = v end})
T5:Toggle({Title = "目标：狗", Value = false, Callback = function(v) auraTargets.dog = v end})
T5:Section({Title = "枪械（实验功能，需要执行器支持 hookmetamethod）"})
T5:Toggle({Title = "静默自瞄（手枪 / AK47）", Value = false, Callback = function(v)
	state.aim = v
	if v then
		local ok = installAimHook()
		if not ok then
			state.aim = false
			WindUI:Notify({Title = "自瞄", Content = "当前执行器不支持，或没拿到枪械模块", Duration = 4})
		end
	end
end})
T5:Toggle({Title = "去除枪械扩散（更准）", Value = false, Callback = function(v)
	state.noSpread = v
	if not loadGun() then
		state.noSpread = false
		WindUI:Notify({Title = "枪械", Content = "没加载到枪械模块，进游戏对局后再开", Duration = 3})
		return
	end
	setSpread(v)
end})

local T6 = Win:Tab({Title = "说明", Icon = "info"})
T6:Section({Title = "使用提示"})
T6:Paragraph({Title = "怎么用", Content = "进游戏对局（不在大厅）后再开 ESP，大厅里没有战利品。飞行默认跟着视角走：手机直接拖屏幕转视角就会往前飞；PC 想用 WASD 就把飞行方向切成「WASD 按键」。自由视角点屏幕上的红色按钮退出。"})
T6:Section({Title = "功能来源"})
T6:Paragraph({Title = "关于", Content = "ESP / 飞行 / 穿墙 / 自动扎带 / 自瞄 参考社区开源脚本（sega1games12 Hub、Xain01），已统一到婴儿脚本界面；游戏更新后部分功能可能失效。"})
T6:Section({Title = "最近修复（v3）"})
T6:Paragraph({Title = "改了什么", Content = "拾取：不再靠猜拾取点名字，改成三路触发（执行器远程函数 + 按住按键 + 点击），Loot 文件夹里的东西无条件收。范围攻击：拳头/近战/枪械统一模拟鼠标左键，工具内部的攻击远程也会自动触发。新增按价值从高到低拾取，可设最低价值门槛。"})

WindUI:Notify({Title = "犯罪模拟器", Content = "脚本已加载，ESP 在「战利品 / NPC 透视」页", Duration = 5})

-- 退出清理
getgenv().CrimBabyStop = function()
	pcall(flyStop)
	pcall(noclipStop)
	pcall(flyJumpStop)
	pcall(zipStop)
	pcall(fcStop)
	pcall(clearAllMarks)
	for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
	conns = {}
	pcall(function() espGui:Destroy() end)
	getgenv().CrimBabyStop = nil
end
