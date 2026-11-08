-- 婴儿脚本 · Blade Ball V16
-- 重写依据：多个公开开源源码（Tora / BobloScript / delta-scripts / gist E3vning）
-- 统一做法：workspace.Balls 里 realBall 的 zoomies.VectorVelocity 算剩余飞行时间，
--           Distance/Speed <= 0.75 时用 VirtualInputManager 点一下 (0,0)，每颗球只点一次。
-- V16 同时去掉之前自己加的「连击冷却/反应延迟/失误率」——那些是漏挡和被踢的主因。
-- 被踢兜底：GuiService.ErrorMessageChanged → 自动重连同一服务器（真·防踢做不到，只能重进）

local P = game:GetService("Players")
local LP = P.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local WS = game:GetService("Workspace")
local RUN = game:GetService("RunService")
local VIM = game:GetService("VirtualInputManager")
local TS = game:GetService("TeleportService")

local cfg = {
	on = false,
	lead = 0.75,        -- 剩余飞行时间 <= 这个值就点（开源默认 0.75）
	pingComp = 0.00,    -- 网络补偿，卡就调大（0.05 ~ 0.15）
	minGap = 0.10,      -- 两次点击最小间隔，防频率检测
	clickMode = "mouse",-- mouse / key / button
	ballESP = true,
	distTag = true,
	keyName = Enum.KeyCode.F,
}

local S = { fires = 0, lastFire = 0, eta = 0, dist = 0, speed = 0, myOK = 0, taps = 0, lastErr = "未点击" }

-- ================= 找球 =================
local function ballFolder()
	local f = WS:FindFirstChild("Balls")
	if f then return f end
	for _, d in ipairs(WS:GetChildren()) do
		if d:IsA("Folder") and string.find(string.lower(d.Name), "ball") then return d end
	end
	return nil
end

local function ballSpeed(b)
	local z = b:FindFirstChild("zoomies")
	if z then
		local ok, v = pcall(function() return z.VectorVelocity end)
		if ok and v then return v.Magnitude end
		local ok2, v2 = pcall(function() return z.AssemblyLinearVelocity end)
		if ok2 and v2 then return v2.Magnitude end
	end
	local ok3, v3 = pcall(function() return b.AssemblyLinearVelocity end)
	return (ok3 and v3) and v3.Magnitude or 0
end

-- 只挑锁定我的球，多球时取最快到达的那颗
local function myBall(hrp)
	local f = ballFolder()
	if not f then return nil end
	local best, bestEta = nil, nil
	for _, b in ipairs(f:GetChildren()) do
		if b:GetAttribute("target") == LP.Name then
			local sp = ballSpeed(b)
			if sp > 1 then
				local eta = (hrp.Position - b.Position).Magnitude / sp
				if not bestEta or eta < bestEta then best, bestEta = b, eta end
			elseif not best then
				best = b
			end
		end
	end
	return best
end

-- ================= 触发 =================
local consumed, watched = setmetatable({}, { __mode = "k" }), setmetatable({}, { __mode = "k" })

local function fire(reason)
	local now = os.clock()
	if now - (S.lastFire or 0) < cfg.minGap then return false end
	S.lastFire = now
	S.fires = S.fires + 1

	local ok, err = false, "?"
	if cfg.clickMode == "key" then
		ok = pcall(function()
			VIM:SendKeyEvent(true, cfg.keyName, false, game)
			VIM:SendKeyEvent(false, cfg.keyName, false, game)
		end)
		err = "按键 " .. tostring(cfg.keyName)
	elseif cfg.clickMode == "button" then
		ok = false
		local pg = LP:FindFirstChild("PlayerGui")
		local btn = pg and pg:FindFirstChild("Hotbar") and pg.Hotbar:FindFirstChild("Block")
		if btn and typeof(getconnections) == "function" then
			local sig = btn.Activated
			local okc, conns = pcall(getconnections, sig)
			if okc and conns then
				for _, c in pairs(conns) do
					if pcall(function() c:Fire() end) then ok = true end
				end
			end
		end
		err = "按钮连接"
	else
		ok = pcall(function()
			VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
			VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
		end)
		err = "虚拟鼠标(0,0)"
	end

	S.taps = S.taps + 1
	S.lastErr = err .. (ok and " ✓" or " ✗")
	return ok
end

local function watch(b)
	if watched[b] then return end
	watched[b] = true
	pcall(function()
		b:GetAttributeChangedSignal("target"):Connect(function()
			consumed[b] = nil
		end)
	end)
end

-- ================= 主循环：每帧算剩余时间 =================
RUN.PreSimulation:Connect(function()
	if not cfg.on then return end
	pcall(function()
		local ch = LP.Character
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
		local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum or hum.Health <= 0 then return end

		local b = myBall(hrp)
		if not b then return end
		watch(b)

		local sp = ballSpeed(b)
		if sp < 1 then return end
		local dist = (hrp.Position - b.Position).Magnitude
		local eta = dist / sp

		S.eta, S.dist, S.speed = eta, dist, sp

		if eta <= cfg.lead + cfg.pingComp and not consumed[b] then
			consumed[b] = true
			fire("eta=" .. string.format("%.2f", eta))
		end
	end)
end)

-- ================= 格挡成功统计 =================
task.spawn(function()
	local r = RS:WaitForChild("Remotes", 25)
	if not r then return end
	local ev = r:FindFirstChild("ParrySuccessAll") or r:FindFirstChild("ParrySuccess")
	if not ev then return end
	ev.OnClientEvent:Connect(function(...)
		local a = table.pack(...)
		for i = 1, a.n do
			if a[i] == LP then
				S.myOK = S.myOK + 1
				break
			end
		end
	end)
end)

-- ================= 被踢 → 自动重连 =================
pcall(function()
	game:GetService("GuiService").ErrorMessageChanged:Connect(function(msg)
		if not msg or msg == "" then return end
		task.wait(0.4)
		pcall(function()
			if #P:GetPlayers() <= 1 then
				TS:Teleport(game.PlaceId, LP)
			else
				TS:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
			end
		end)
	end)
end)

LP.CharacterAdded:Connect(function()
	consumed = setmetatable({}, { __mode = "k" })
	watched = setmetatable({}, { __mode = "k" })
	S.eta, S.dist, S.speed = 0, 0, 0
end)

-- ================= 界面 =================
local WindUI = loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/Footagesus/WindUI@main/dist/main.lua"))()
local Win = WindUI:CreateWindow({ Title = "Blade Ball V16" })
local T1 = Win:Tab({ Title = "格挡", Icon = "shield" })
local T2 = Win:Tab({ Title = "视觉", Icon = "eye" })
local T3 = Win:Tab({ Title = "移动", Icon = "zap" })

T1:Section({ Title = "自动格挡" })

local mainBtn, mainTitle
mainTitle = function()
	if cfg.on then return "■ 已开启 · 点此关闭" end
	return "▶ 开启自动格挡"
end

local function paint()
	if not mainBtn then return end
	pcall(function() mainBtn:SetTitle(mainTitle()) end)
end

mainBtn = T1:Button({
	Title = mainTitle(),
	Desc = "球锁定你、快到时自动点一下",
	Callback = function()
		cfg.on = not cfg.on
		paint()
		WindUI:Notify({
			Title = cfg.on and "自动格挡：开" or "自动格挡：关",
			Content = cfg.on and "球快到时自动点击（每颗球只点一次）" or "已停止",
			Duration = 3,
		})
	end,
})

task.spawn(function()
	while true do
		task.wait(0.5)
		if mainBtn then
			local d
			if cfg.on then
				d = string.format("剩余 %.2fs｜距离 %d 格｜球速 %d｜点击 %d｜成功 %d",
					S.eta, S.dist, S.speed, S.fires, S.myOK)
			else
				d = "球锁定你、快到时自动点一下"
			end
			pcall(function() mainBtn:SetDesc(d) end)
		end
	end
end)

T1:Section({ Title = "参数（默认就能用）" })
T1:Slider({ Title = "提前量（0.40–1.20 秒，越大越早点）", Value = { Min = 40, Max = 120, Default = 75 }, Callback = function(v)
	cfg.lead = v / 100
end})
T1:Slider({ Title = "网络补偿（0–300 毫秒，卡就加）", Value = { Min = 0, Max = 300, Default = 0 }, Callback = function(v)
	cfg.pingComp = v / 1000
end})
T1:Slider({ Title = "最小点击间隔（60–300 毫秒，防踢）", Value = { Min = 60, Max = 300, Default = 100 }, Callback = function(v)
	cfg.minGap = v / 1000
end})

T1:Section({ Title = "点击方式（一般不用改）" })
T1:Button({ Title = "① 虚拟鼠标 (0,0)｜开源同款，推荐", Callback = function()
	cfg.clickMode = "mouse"
	WindUI:Notify({ Title = "点击方式", Content = "虚拟鼠标 (0,0)，和开源脚本一致", Duration = 3 })
end})
T1:Button({ Title = "② 模拟按键 F", Callback = function()
	cfg.clickMode = "key"
	WindUI:Notify({ Title = "点击方式", Content = "模拟按 F 键（PC 端更稳）", Duration = 3 })
end})
T1:Button({ Title = "③ 直连格挡按钮连接", Callback = function()
	cfg.clickMode = "button"
	WindUI:Notify({ Title = "点击方式", Content = "直接 Fire 按钮的 Activated 连接", Duration = 3 })
end})

T1:Section({ Title = "自检" })
T1:Button({ Title = "测试点一下（看游戏有没有反应）", Callback = function()
	local ok = fire("手动测试")
	WindUI:Notify({
		Title = ok and "点击已发出" or "点击失败",
		Content = S.lastErr .. "｜看人物有没有格挡动作",
		Duration = 6,
	})
end})
T1:Button({ Title = "诊断（自动复制）", Callback = function()
	local f = ballFolder()
	local txt = "【状态】" .. (cfg.on and "开" or "关")
		.. " | 球数=" .. tostring(f and #f:GetChildren() or 0)
		.. " | 剩余=" .. string.format("%.2f", S.eta)
		.. "s 距离=" .. tostring(math.floor(S.dist)) .. " 球速=" .. tostring(math.floor(S.speed))
		.. "\n【点击】次数=" .. tostring(S.fires)
		.. " | 方式=" .. cfg.clickMode .. " | 上次=" .. tostring(S.lastErr)
		.. " | 成功=" .. tostring(S.myOK)
		.. "\n【结构】Balls=" .. (f and "有" or "无")
		.. " | zoomies=" .. (function()
			local b = f and f:FindFirstChildOfClass("Part")
			return b and (b:FindFirstChild("zoomies") and "有" or "无") or "无球"
		end)()
	if setclipboard then pcall(setclipboard, txt) end
	WindUI:Notify({ Title = "诊断（已复制）", Content = txt, Duration = 10 })
end})

T2:Section({ Title = "透视" })
T2:Toggle({ Title = "球透视（★ 是锁定你的球）", Value = true, Callback = function(v) cfg.ballESP = v end})
T2:Toggle({ Title = "显示距离", Value = true, Callback = function(v) cfg.distTag = v end})

T3:Section({ Title = "移动" })
local sp = 16
T3:Slider({ Title = "移动速度", Value = { Min = 16, Max = 120, Default = 16 }, Callback = function(v)
	sp = v
	local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
	if h then pcall(function() h.WalkSpeed = sp end) end
end})

-- ================= 球透视 =================
local tags = {}
task.spawn(function()
	while true do
		task.wait(0.15)
		local f = ballFolder()
		local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
		if cfg.ballESP and f then
			for _, b in ipairs(f:GetChildren()) do
				if b:IsA("BasePart") then
					local t = tags[b]
					if not t then
						local hl = Instance.new("Highlight")
						hl.Adornee = b
						hl.FillColor = Color3.fromRGB(255, 70, 70)
						hl.FillTransparency = 0.45
						hl.OutlineColor = Color3.new(1, 1, 1)
						hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
						hl.Parent = b

						local bb = Instance.new("BillboardGui")
						bb.Adornee = b
						bb.Size = UDim2.new(0, 150, 0, 28)
						bb.StudsOffset = Vector3.new(0, 1.8, 0)
						bb.AlwaysOnTop = true
						bb.Parent = b

						local tl = Instance.new("TextLabel")
						tl.Size = UDim2.fromScale(1, 1)
						tl.BackgroundTransparency = 1
						tl.Font = Enum.Font.GothamBold
						tl.TextScaled = true
						tl.TextStrokeTransparency = 0.2
						tl.TextColor3 = Color3.fromRGB(255, 140, 140)
						tl.Parent = bb

						t = { hl = hl, bb = bb, tl = tl }
						tags[b] = t
					end
					if t.tl then
						local mine = b:GetAttribute("target") == LP.Name
						local txt = mine and "★ 球" or "球"
						if cfg.distTag and root then
							txt = txt .. " " .. tostring(math.floor((b.Position - root.Position).Magnitude))
						end
						t.tl.Text = txt
						t.tl.TextColor3 = mine and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(255, 170, 170)
					end
				end
			end
		end
		for b, t in pairs(tags) do
			if not cfg.ballESP or not b.Parent then
				pcall(function() t.hl:Destroy() end)
				pcall(function() t.bb:Destroy() end)
				tags[b] = nil
			end
		end
	end
end)

task.delay(1, function()
	pcall(function()
		WindUI:Notify({
			Title = "Blade Ball V16",
			Content = "点「▶ 开启自动格挡」开始｜每颗球只点一次",
			Duration = 6,
		})
	end)
end)
