-- 婴儿脚本 · 被追捕（HUNTED）V5
-- 门透视 / 碎片透视 / 穿墙 / 速度 / 全亮 / 自动开门 / 传送
-- 适配：HUNTED [HALLOWEEN EVENT] (PlaceId 136431686349723)
-- V5 自动吃水晶：吃到即走，单个目标最多占 0.9 秒

local P = game:GetService("Players")
local LP = P.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local WS = game:GetService("Workspace")
local L = game:GetService("Lighting")
local RUN = game:GetService("RunService")

-- ================= 反踢出（启动即生效） =================
local AK = {on = false, blocked = 0}
local function installHooks()
	local done = false
	pcall(function()
		local gm = getrawmetatable(game)
		if not gm then return end
		local old = gm.__namecall
		if not old then return end
		local hooked = function(self, ...)
			local m = ""
			pcall(function() m = getnamecallmethod() end)
			if m == "Kick" or m == "kick" or m == "KickPlayer" then
				local okc, cc = pcall(function() return checkcaller() end)
				if not okc or cc == false then
					AK.blocked = AK.blocked + 1
					return nil
				end
			end
			return old(self, ...)
		end
		local fn = hooked
		pcall(function() if newcclosure then fn = newcclosure(hooked) end end)
		pcall(function() setreadonly(gm, false) end)
		gm.__namecall = fn
		pcall(function() setreadonly(gm, true) end)
		done = true
	end)
	if not done then
		pcall(function()
			local old
			old = hookmetamethod(game, "__namecall", function(self, ...)
				local m = ""
				pcall(function() m = getnamecallmethod() end)
				if m == "Kick" or m == "kick" or m == "KickPlayer" then
					local okc, cc = pcall(function() return checkcaller() end)
					if not okc or cc == false then
						AK.blocked = AK.blocked + 1
						return nil
					end
				end
				return old(self, ...)
			end)
			done = true
		end)
	end
	AK.on = done
	return done
end
pcall(installHooks)

-- ================= 界面 =================
local WindUI = loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/Footagesus/WindUI@main/dist/main.lua"))()
local Win = WindUI:CreateWindow({Title = "被追捕 · HUNTED"})
local T1 = Win:Tab({Title = "透视", Icon = "eye"})
local T2 = Win:Tab({Title = "移动", Icon = "zap"})
local T3 = Win:Tab({Title = "工具", Icon = "wrench"})

-- ================= 配置 =================
local cfg = {
	doorOn = true,
	lootOn = false,
	crystalOn = false,
	playerOn = false,
	distOn = true,
	autoDoor = false,
	noclip = false,
}

local DOOR_FOLDER_KW = {"halloweendoor", "door"}
local LOOT_KW = {"shard", "soul", "crystal", "candy", "treat", "pickup", "coin", "gem", "collectible", "relic", "orb"}
local SKIP_KW = {"effect", "sound", "particle", "gui", "camera", "hint", "prompt", "trigger"}

-- ================= ESP 基础 =================
local tags = {}     -- [part] = {hl=,bb=,tl=,kind=,name=}
local usedDoor = {}

local function isPlayerModel(inst)
	local m = inst
	if not m:IsA("Model") then m = inst:FindFirstAncestorOfClass("Model") end
	if not m then return false end
	return P:GetPlayerFromCharacter(m) ~= nil
end

local function hasKW(name, list)
	local low = string.lower(name)
	for _, k in ipairs(list) do
		if string.find(low, k, 1, true) then return true end
	end
	return false
end

local function pickPart(obj)
	if obj:IsA("BasePart") then return obj end
	if not obj:IsA("Model") then
		local d = obj:FindFirstChildWhichIsA("BasePart", true)
		return d
	end
	for _, n in ipairs({"Door", "Panel", "Main", "Handle", "Root", "HumanoidRootPart", "Torso"}) do
		local p = obj:FindFirstChild(n, true)
		if p and p:IsA("BasePart") then return p end
	end
	local best, size = nil, 0
	for _, d in ipairs(obj:GetDescendants()) do
		if d:IsA("BasePart") then
			local s = d.Size.X * d.Size.Y * d.Size.Z
			if s > size then best, size = d, s end
		end
	end
	return best
end

local function makeTag(part, text, color)
	local hl = Instance.new("Highlight")
	hl.Name = "PursuedHL"
	hl.Adornee = part
	hl.FillColor = color
	hl.FillTransparency = 0.6
	hl.OutlineColor = color
	hl.OutlineTransparency = 0
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Parent = part

	local bb = Instance.new("BillboardGui")
	bb.Name = "PursuedBB"
	bb.Adornee = part
	bb.Size = UDim2.new(0, 190, 0, 34)
	bb.StudsOffset = Vector3.new(0, 2.6, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 300
	bb.Parent = part

	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.new(1, 0, 1, 0)
	tl.BackgroundTransparency = 1
	tl.Text = text
	tl.TextColor3 = color
	tl.TextStrokeColor3 = Color3.new(0, 0, 0)
	tl.TextStrokeTransparency = 0.25
	tl.Font = Enum.Font.GothamBold
	tl.TextScaled = true
	tl.Parent = bb

	return {hl = hl, bb = bb, tl = tl}
end

local function killTag(t)
	if not t then return end
	pcall(function() if t.hl then t.hl:Destroy() end end)
	pcall(function() if t.bb then t.bb:Destroy() end end)
end

local function setTag(part, kind, text, color)
	local t = tags[part]
	if not t then
		local made = makeTag(part, text, color)
		tags[part] = {hl = made.hl, bb = made.bb, tl = made.tl, kind = kind, name = text}
		return
	end
	t.kind = kind
	if t.tl and t.tl.Text ~= text then t.tl.Text = text end
end

local function sweep(wanted)
	for part, t in pairs(tags) do
		if not wanted[part] then
			killTag(t)
			tags[part] = nil
			usedDoor[part] = nil
		end
	end
end

-- ================= 找门 =================
local function findDoorRoot()
	for _, k in ipairs(DOOR_FOLDER_KW) do
		for _, o in ipairs(WS:GetChildren()) do
			if string.find(string.lower(o.Name), k, 1, true) then return o end
		end
	end
	return nil
end

local function collectDoors()
	local out = {}
	local root = findDoorRoot()
	if not root then return out end
	for _, d in ipairs(root:GetChildren()) do
		local part = pickPart(d)
		if part then
			out[#out + 1] = {part = part, label = (d.Name ~= "" and d.Name or "门"), obj = d}
		end
	end
	return out
end

-- ================= 找目标 =================
local function scanInto(root, depth, kws, out, limit)
	if depth < 0 then return end
	for _, o in ipairs(root:GetChildren()) do
		if #out >= limit then return end
		if not hasKW(o.Name, SKIP_KW) and not isPlayerModel(o) then
			if hasKW(o.Name, kws) and (o:IsA("Model") or o:IsA("BasePart") or o:IsA("Folder")) then
				local part = pickPart(o)
				if part then out[#out + 1] = {part = part, label = o.Name, obj = o} end
			elseif o:IsA("Model") or o:IsA("Folder") then
				scanInto(o, depth - 1, kws, out, limit)
			end
		end
	end
end

local function collectByKW(kws, limit)
	local raw = {}
	pcall(function() scanInto(WS, 2, kws, raw, limit * 3) end)
	-- 同一个 Model / Folder 只保留一条，否则一个水晶的多个零件会被当成多个目标
	local seen, out = {}, {}
	for _, o in ipairs(raw) do
		local key = o.obj
		if key and not seen[key] then
			seen[key] = true
			out[#out + 1] = o
		end
	end
	for i = #out, limit + 1, -1 do
		out[i] = nil
	end
	return out
end

-- ================= 刷新循环 =================
local nearestDoor, nearestLoot
local lootCache = {}
local stats = {doors = 0, loot = 0}

local function refresh()
	local wanted = {}

	local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")

	if cfg.doorOn then
		local doors = collectDoors()
		stats.doors = #doors
		nearestDoor = nil
		local best = math.huge
		for _, d in ipairs(doors) do
			local part = d.part
			if part and part.Parent then
				local used = usedDoor[part]
				local col = used and Color3.fromRGB(60, 255, 90) or Color3.fromRGB(255, 60, 60)
				local txt = d.label .. (used and " [已用]" or "")
				if cfg.distOn and root then
					local dist = math.floor((root.Position - part.Position).Magnitude)
					txt = txt .. " [" .. dist .. "]"
					if dist < best then best, nearestDoor = dist, part end
				end
				setTag(part, "door", txt, col)
				wanted[part] = true
			end
		end
	end

	lootCache = {}
	if cfg.lootOn or cfg.crystalOn then
		local loots = collectByKW(LOOT_KW, 120)
		lootCache = loots
		stats.loot = #loots
		nearestLoot = nil
		local best = math.huge
		for _, o in ipairs(loots) do
			local part = o.part
			if part and part.Parent then
				local txt = o.label
				if cfg.distOn and root then
					local dist = math.floor((root.Position - part.Position).Magnitude)
					txt = txt .. " [" .. dist .. "]"
					if dist < best then best, nearestLoot = dist, part end
				end
				if cfg.lootOn then
					setTag(part, "loot", txt, Color3.fromRGB(255, 220, 60))
					wanted[part] = true
				end
			end
		end
	else
		stats.loot = 0
	end

	if cfg.playerOn and root then
		for _, pl in ipairs(P:GetPlayers()) do
			if pl ~= LP and pl.Character then
				local ch = pl.Character
				local hrp = ch:FindFirstChild("HumanoidRootPart")
				if hrp then
					local dist = math.floor((root.Position - hrp.Position).Magnitude)
					setTag(hrp, "player", pl.Name .. (cfg.distOn and (" [" .. dist .. "]") or ""), Color3.fromRGB(120, 200, 255))
					wanted[hrp] = true
				end
			end
		end
	end

	sweep(wanted)
end

-- ================= 门被使用后变绿 =================
local hookConn = {}
local function hookDoorsForUsed()
	for _, c in ipairs(hookConn) do pcall(function() c:Disconnect() end) end
	hookConn = {}
	local root = findDoorRoot()
	if not root then return end
	for _, d in ipairs(root:GetChildren()) do
		local part = pickPart(d)
		if part then
			for _, x in ipairs(d:GetDescendants()) do
				if x:IsA("ClickDetector") then
					local c = x.MouseClick:Connect(function() usedDoor[part] = true end)
					hookConn[#hookConn + 1] = c
				elseif x:IsA("ProximityPrompt") then
					local c = x.Triggered:Connect(function() usedDoor[part] = true end)
					hookConn[#hookConn + 1] = c
				end
			end
		end
	end
end

-- ================= 自动开门 =================
task.spawn(function()
	while true do
		task.wait(0.7)
		if cfg.autoDoor then
			local ok = pcall(function()
				local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
				if not root then return end
				local dr = findDoorRoot()
				if not dr then return end
				for _, x in ipairs(dr:GetDescendants()) do
					if x:IsA("ProximityPrompt") and x.Enabled then
						local part = x.Parent
						if part and part:IsA("BasePart") then
							local d = (root.Position - part.Position).Magnitude
							if d <= 18 then
								if fireproximityprompt then fireproximityprompt(x, 0) end
							end
						end
					end
				end
			end)
			if not ok then end
		end
	end
end)

-- ================= 自动吃水晶（V4） =================
-- V3 的问题：自己重新扫一遍、自己再造一套门控，结果「立即吃」也不动；而手动传送按钮一直好用。
-- V4 完全复用手动按钮的数据源（refresh 生成的 lootCache）和传送方式（+4 格），
--     只在其上叠加「吃不到就换下一个」，不再引入第二套逻辑。
local pickR = 8
local skipUntil = setmetatable({}, { __mode = "k" })   -- [part] = 到期时间
local failCnt = setmetatable({}, { __mode = "k" })     -- [part] = 失败次数
local pickName, pickDist, skippedCount = "无", 0, 0
local dbg = { tick = 0, hits = 0, got = 0, scanned = 0, lastErr = "" }

-- Roblox 的 os.clock() 是 CPU 时间，空等时不走，必须用真实秒数
local clock = 0
RUN.Heartbeat:Connect(function(dt) clock = clock + dt end)
local function nowT() return clock end

local function resetPickState()
	skipUntil = setmetatable({}, { __mode = "k" })
	failCnt = setmetatable({}, { __mode = "k" })
	pickName, pickDist, skippedCount = "无", 0, 0
	dbg.hits, dbg.got, dbg.lastErr = 0, 0, ""
end

-- 和「传送到最近的碎片」按钮完全一样的传送写法
local function hopTo(part)
	local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
	if not root or not part or not part.Parent then return false end
	return pcall(function()
		root.CFrame = CFrame.new(part.Position + Vector3.new(0, 4, 0))
	end)
end

local function triggerPickups(part)
	pcall(function()
		local m = part:FindFirstAncestorOfClass("Model") or part
		for _, x in ipairs(m:GetDescendants()) do
			if x:IsA("ProximityPrompt") and x.Enabled then
				if fireproximityprompt then
					pcall(function() fireproximityprompt(x, x.HoldDuration or 0.2) end)
				end
			elseif x:IsA("ClickDetector") then
				if fireclickdetector then pcall(function() fireclickdetector(x) end) end
			end
		end
	end)
end

-- 由 lootCache（手动按钮用的同一份数据）生成按距离升序的候选表
local function candidates(root)
	local list = {}
	for _, o in ipairs(lootCache) do
		local p = o and o.part
		if p and p.Parent then
			list[#list + 1] = { part = p, d = (root.Position - p.Position).Magnitude, label = o.label }
		end
	end
	table.sort(list, function(a, b) return a.d < b.d end)
	return list
end

-- 一次「飞过去 → 触发 → 确认吃到」：吃到立即返回（约 0.2~0.4 秒），
-- 不再固定等 1.8 秒；吃不到最多占 0.9 秒。
local function eatOne(target)
	local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
	if not root or not target or not target.Parent then return false end
	local d = (root.Position - target.Position).Magnitude
	pickName, pickDist = tostring(target.Name), math.floor(d)
	dbg.hits = dbg.hits + 1

	hopTo(target)
	if d <= pickR then triggerPickups(target) end

	local hum = root.Parent and root.Parent:FindFirstChildOfClass("Humanoid")
	if hum then pcall(function() hum:MoveTo(target.Position) end) end

	local t0 = nowT()
	local stage = 0
	while nowT() - t0 < 0.9 do
		if not target.Parent then return true end
		local el = nowT() - t0
		if stage == 0 and el > 0.15 then
			stage = 1
			pcall(function()
				local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
				if r and target.Parent then r.CFrame = CFrame.new(target.Position) end
			end)
			triggerPickups(target)
		elseif stage == 1 and el > 0.45 then
			stage = 2
			triggerPickups(target)
		end
		task.wait(0.05)
	end
	return target.Parent == nil
end

-- 候选表每 0.4 秒重建一次，避免每轮都排序 100 多项
local candCache, candAt = {}, 0

task.spawn(function()
	while true do
		task.wait(cfg.crystalOn and 0.05 or 0.4)
		dbg.tick = dbg.tick + 1
		if cfg.crystalOn then
			local ok, err = pcall(function()
				local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
				if not root then
					dbg.lastErr = "角色还没加载好"
					return
				end
				local now = nowT()
				if now - candAt > 0.4 then
					candCache = candidates(root)
					candAt = now
				end
				local list = candCache
				dbg.scanned = #list
				if #list == 0 then
					dbg.lastErr = "扫不到目标：先把「碎片透视」打开一下"
					return
				end

				local target
				for _, c in ipairs(list) do
					if (skipUntil[c.part] or 0) < now then
						target = c.part
						break
					end
				end
				if not target then
					dbg.lastErr = "所有目标都在跳过冷却里，点「清空跳过记录」"
					task.wait(0.2)
					return
				end

				dbg.lastErr = ""
				if eatOne(target) then
					failCnt[target] = nil
					dbg.got = dbg.got + 1
				else
					local n = (failCnt[target] or 0) + 1
					failCnt[target] = n
					skippedCount = skippedCount + 1
					-- 吃不到：2、4、6…最多 20 秒后再来，不永久拉黑
					skipUntil[target] = nowT() + math.min(20, 2 * n)
				end
			end)
			if not ok then
				dbg.lastErr = "报错：" .. tostring(err)
			end
		end
	end
end)

-- ================= 主循环 =================
task.spawn(function()
	refresh()
	hookDoorsForUsed()
	local acc = 0
	while true do
		local dt = RUN.Heartbeat:Wait()
		acc = acc + dt
		if acc >= 0.8 then
			acc = 0
			pcall(refresh)
		end
	end
end)

-- ================= 移动增强 =================
local sp, jp = 16, 50
local ncParts = {}

local function applyHum()
	local ch = LP.Character
	local h = ch and ch:FindFirstChildOfClass("Humanoid")
	if not h then return end
	pcall(function()
		h.WalkSpeed = sp
		h.UseJumpPower = true
		h.JumpPower = jp
	end)
end

LP.CharacterAdded:Connect(function()
	task.wait(0.6)
	pcall(applyHum)
end)

task.spawn(function()
	while true do
		task.wait(1)
		if cfg.noclip then
			local ch = LP.Character
			if ch then
				for _, p in ipairs(ch:GetDescendants()) do
					if p:IsA("BasePart") and p.CanCollide then
						ncParts[p] = true
						p.CanCollide = false
					end
				end
			end
		end
	end
end)

local function stopNoclip()
	for p in pairs(ncParts) do
		pcall(function() if p and p.Parent then p.CanCollide = true end end)
	end
	ncParts = {}
end

-- ================= 全亮 =================
local lightSave = nil
local function fullbright(on)
	if on then
		if lightSave then return end
		lightSave = {
			Brightness = L.Brightness,
			Ambient = L.Ambient,
			OutdoorAmbient = L.OutdoorAmbient,
			ClockTime = L.ClockTime,
		}
		pcall(function()
			L.Brightness = 3
			L.Ambient = Color3.fromRGB(190, 190, 190)
			L.OutdoorAmbient = Color3.fromRGB(190, 190, 190)
			L.ClockTime = 12
		end)
	else
		if not lightSave then return end
		pcall(function()
			L.Brightness = lightSave.Brightness
			L.Ambient = lightSave.Ambient
			L.OutdoorAmbient = lightSave.OutdoorAmbient
			L.ClockTime = lightSave.ClockTime
		end)
		lightSave = nil
	end
end

-- ================= 传送 =================
local function tpTo(part)
	if not part then
		WindUI:Notify({Title = "传送", Content = "没有目标，先开对应的透视", Duration = 4})
		return
	end
	local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	pcall(function()
		root.CFrame = CFrame.new(part.Position + Vector3.new(0, 4, 0))
	end)
end

-- ================= UI =================
T1:Section({Title = "门（HalloweenDoors）"})
T1:Toggle({Title = "门透视（红色 / 已用变绿）", Value = true, Callback = function(v)
	cfg.doorOn = v
	if not v then
		for part, t in pairs(tags) do
			if t.kind == "door" then killTag(t) tags[part] = nil end
		end
	end
end})
T1:Toggle({Title = "显示距离", Value = true, Callback = function(v) cfg.distOn = v end})

T1:Section({Title = "目标"})
T1:Toggle({Title = "碎片 / 糖果透视（黄色）", Value = false, Callback = function(v)
	cfg.lootOn = v
	if not v then
		for part, t in pairs(tags) do
			if t.kind == "loot" then killTag(t) tags[part] = nil end
		end
	end
end})
T1:Toggle({Title = "玩家透视（蓝色）", Value = false, Callback = function(v)
	cfg.playerOn = v
	if not v then
		for part, t in pairs(tags) do
			if t.kind == "player" then killTag(t) tags[part] = nil end
		end
	end
end})

T1:Toggle({Title = "自动吃水晶（自动飞过去拾取）", Value = false, Callback = function(v)
	cfg.crystalOn = v
	if v then
		resetPickState()
		scanAt = 0
		task.defer(function() pcall(refresh) end)
	end
	WindUI:Notify({Title = "自动吃水晶", Content = v and "已开启：吃不到会自动换下一个" or "已关闭", Duration = 4})
end})
T1:Slider({Title = "拾取范围（触发 prompt 的距离）", Value = {Min = 2, Max = 20, Default = 8}, Callback = function(v)
	pickR = v
end})
T1:Button({Title = "自动吃水晶诊断（不传送也能看）", Callback = function()
	local withP, withC = 0, 0
	for _, o in ipairs(lootCache) do
		if o.part and o.part.Parent then
			pcall(function()
				local m = o.part:FindFirstAncestorOfClass("Model") or o.part
				if m:FindFirstChildWhichIsA("ProximityPrompt", true) then withP = withP + 1 end
				if m:FindFirstChildWhichIsA("ClickDetector", true) then withC = withC + 1 end
			end)
		end
	end
	WindUI:Notify({
		Title = "自动吃水晶 · 运行状态",
		Content = "开关：" .. tostring(cfg.crystalOn)
			.. "\n目标总数：" .. dbg.scanned .. " 个（缓存 " .. #lootCache .. "）"
			.. "\n其中带提示键：" .. withP .. " 个｜带点击器：" .. withC .. " 个"
			.. "\n已出手次数：" .. dbg.hits
			.. "\n已吃到：" .. dbg.got .. " 个"
			.. "\n当前锁定：" .. pickName .. "（" .. pickDist .. " 格）"
			.. "\n已跳过：" .. skippedCount
			.. "\n心跳计数：" .. dbg.tick
			.. "\n说明：" .. (dbg.lastErr ~= "" and dbg.lastErr or "运行正常"),
		Duration = 14,
	})
end})

T1:Section({Title = "说明"})
T1:Button({Title = "碎片透视扫不到东西？点这里看原因", Callback = function()
	WindUI:Notify({Title = "透视说明", Content = "碎片是按名字关键字扫的，不同章节可能改名。把开关关掉再打开会重新扫描一次。", Duration = 7})
end})

T2:Section({Title = "移动"})
T2:Slider({Title = "移动速度", Value = {Min = 16, Max = 300, Default = 16}, Callback = function(v)
	sp = v
	applyHum()
end})
T2:Slider({Title = "跳跃力", Value = {Min = 50, Max = 300, Default = 50}, Callback = function(v)
	jp = v
	applyHum()
end})
T2:Toggle({Title = "无碰撞（穿墙）", Value = false, Callback = function(v)
	cfg.noclip = v
	if not v then stopNoclip() end
end})
T2:Toggle({Title = "全亮（全图变亮）", Value = false, Callback = function(v)
	fullbright(v)
end})

T3:Section({Title = "快捷操作"})
T3:Button({Title = "传送到最近的门", Callback = function()
	if not nearestDoor then
		WindUI:Notify({Title = "传送", Content = "附近没有门，先打开门透视", Duration = 4})
		return
	end
	tpTo(nearestDoor)
end})
T3:Button({Title = "传送到最近的碎片", Callback = function()
	if not nearestLoot then
		WindUI:Notify({Title = "传送", Content = "没有碎片数据，先打开碎片透视", Duration = 4})
		return
	end
	tpTo(nearestLoot)
end})
T3:Button({Title = "立刻吃最近的一个（手动）", Callback = function()
	local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		WindUI:Notify({Title = "手动吃", Content = "角色还没加载好", Duration = 4})
		return
	end
	pcall(refresh)
	local list = candidates(root)
	if #list == 0 then
		WindUI:Notify({Title = "手动吃", Content = "没有碎片数据，先打开「碎片透视」或「自动吃水晶」", Duration = 6})
		return
	end
	local now = nowT()
	local target
	for _, c in ipairs(list) do
		if (skipUntil[c.part] or 0) < now then target = c.part break end
	end
	if not target then target = list[1].part end
	local d = (root.Position - target.Position).Magnitude
	eatOne(target)
	WindUI:Notify({Title = "手动吃", Content = "已飞向 " .. tostring(target.Name) .. "（" .. math.floor(d) .. " 格）", Duration = 5})
end})
T3:Button({Title = "清空跳过记录（卡住不动就点这个）", Callback = function()
	resetPickState()
	WindUI:Notify({Title = "自动吃水晶", Content = "跳过记录已清空，现在会重新从最近的一个开始", Duration = 5})
end})
T3:Toggle({Title = "自动开门（靠近自动触发）", Value = false, Callback = function(v)
	cfg.autoDoor = v
	WindUI:Notify({Title = "自动开门", Content = v and "已开启，靠近门会自动触发" or "已关闭", Duration = 3})
end})
T3:Button({Title = "重新扫描地图", Callback = function()
	pcall(refresh)
	pcall(hookDoorsForUsed)
	WindUI:Notify({Title = "扫描", Content = "门 " .. stats.doors .. " 个｜目标 " .. stats.loot .. " 个", Duration = 5})
end})
T3:Button({Title = "看看扫到了哪些目标（前 10 个）", Callback = function()
	if #lootCache == 0 then
		WindUI:Notify({Title = "扫描结果", Content = "一个都没扫到：先打开「自动吃水晶」或「碎片透视」再点这里", Duration = 7})
		return
	end
	local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
	local lines = {}
	for i = 1, math.min(10, #lootCache) do
		local o = lootCache[i]
		local d = "?"
		if root and o.part and o.part.Parent then
			d = tostring(math.floor((root.Position - o.part.Position).Magnitude))
		end
		local mark = ""
		pcall(function()
			if o.obj:FindFirstChildWhichIsA("ProximityPrompt", true) then mark = mark .. "P" end
			if o.obj:FindFirstChildWhichIsA("ClickDetector", true) then mark = mark .. "C" end
			if o.obj:IsA("BasePart") and o.obj.Transparency >= 0.98 then mark = mark .. "隐" end
		end)
		lines[#lines + 1] = i .. ". " .. tostring(o.label) .. " [" .. d .. "]" .. (mark ~= "" and (" " .. mark) or "")
	end
	WindUI:Notify({Title = "扫描结果（前 " .. #lines .. " 个｜P=提示键 C=点击）", Content = table.concat(lines, "\n"), Duration = 12})
end})
T3:Button({Title = "查看反踢出状态", Callback = function()
	WindUI:Notify({Title = "反踢出", Content = AK.on and ("已启用，已拦截 " .. AK.blocked .. " 次") or "挂载失败，执行器不支持", Duration = 5})
end})

-- ================= 启动提示 =================
task.delay(1, function()
	pcall(function()
		WindUI:Notify({Title = "被追捕 · HUNTED", Content = "门透视已开｜反踢出" .. (AK.on and "已启用" or "不可用"), Duration = 5})
	end)
end)
