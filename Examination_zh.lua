-- wind ui initialization
local windUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- localization
windUI:Localization({
	Enabled = true,
	Prefix = "l:",
	DefaultLanguage = "zh",
	Translations = {
		["en"] = {
			["openButton"] = "Open UI",
			["mainTab"] = "Main",
			["movementTab"] = "Movement",
			["teleportTab"] = "Teleports",
			["guiTab"] = "Interface",
			["aboutTab"] = "About",
			["loadSuccess_title"] = "Examination hub loaded successfully!",
			["loadSuccess_desc"] = "Thanks for using Examination hub, please leave a feedback on script's page if you want it to be improved in future!",
			["lang_title"] = "Choose your language",
			["lang_desc"] = "This will set the UI language.",
			["lang_chinese"] = "中文",
			["lang_english"] = "English",
			["buttons_title"] = "Buttons",
			["values_title"] = "Values",
			["map_title"] = "Map",
            ["changelog"] = "Change-log",
            ["settings"] = "Settings",
            ["lang_switch"] = "Switch language",
			["suicideButton_title"] = "Suicide",
			["suicideButton_desc"] = "Kill yourself.",
			["suicideBind_title"] = "Suicide (keybind)",
			["suicideBind_desc"] = "Keybind to kill yourself.",
			["hunter_title"] = "Hunter mode",
			["hunter_desc"] = "Toggles the hunter mode that is speeding you up.",
			["thirdperson_title"] = "Third person",
			["thirdperson_desc"] = "Toggles the camera third person mode.",
			["chat_title"] = "Chat history",
			["chat_desc"] = "Toggles the chat history.",
			["elephant_foot"] = "Remove elephant's foot",
			["arabic_man"] = "Remove arabic dude",
			["console_tp"] = "Remove console teleport",
			["radiation"] = "Remove radiation",
			["speed_title"] = "Speed",
			["speed_desc"] = "Speed multiplier.",
			["jump_title"] = "Jump",
			["jump_desc"] = "Jump multiplier.",
			["sector1"] = "Sector 1",
			["sector2"] = "Sector 2",
			["sector3"] = "Sector 3",
			["out-of-map"] = "Out of map",
			["sectorEntrance"] = "Sector entrance",
			["keycard"] = "Keycard",
			["spawn"] = "Spawn",
			["gen1"] = "Generator 1",
			["reactor4"] = "Reactor 4",
			["mutant"] = "Mutant-crawler",
			["valve"] = "Valve",
			["gen2"] = "Generator 2",
			["russmanOffice"] = "Russman's office",
			["armory"] = "Armory",
			["steve"] = "Steve Remington",
			["crate_1-3"] = "Weapon crates 1-3",
			["crate_4"] = "Weapon crate 4",
			["crate_5"] = "Weapon crate 5",
			["crate_6"] = "Weapon crate 6",
			["c4_1"] = "C4 crate 1",
			["c4_2"] = "C4 crate 2",
			["c4_3"] = "C4 crate 3",
			["c4_4"] = "C4 crate 4",
			["baseplate"] = "Baseplate",
			["esp_desc"] = "Toggles the ESP.",
			["infection_title"] = "Controllable infected UI",
			["infection_desc"] = "Toggles the controllable infected UI.",
			["gasmask_title"] = "Remove gasmask UI",
			["death_title"] = "Remove death UI",
			["chimera_title"] = "Remove Chimera's terror UI",
			["gilbert_title"] = "Remove Gilbert's terror UI",
			["changelog_date_1"] = "v2.1 February 26",
			["changelog_text_1"] = "Fixed a bug that could cause the new characters being respawned without ESP even when it's turned on.",
            ["changelog_date_2"] = "v2.0 February 24",
            ["changelog_text_2"] = "Script got completely rewritten: added more optimization, more animations, moved to WindUI. Lighting is temporary unavailable",
            ["windKeybind_title"] = "WindUI keybind",
			["windKeybind_desc"] = "Keybind to open/close WindUI.",
			["windDestroy_title"] = "Destroy WindUI",
			["windDestroy_desc"] = "Destroys UI and its connections."
		},
		["zh"] = {
			["openButton"] = "打开界面",
			["mainTab"] = "主要",
			["movementTab"] = "移动",
			["teleportTab"] = "传送",
			["guiTab"] = "界面",
			["aboutTab"] = "关于",
			["loadSuccess_title"] = "试炼脚本已加载",
			["loadSuccess_desc"] = "祝你玩得开心",
			["lang_title"] = "选择语言",
			["lang_desc"] = "设置界面显示的语言。",
			["lang_english"] = "英文",
			["lang_chinese"] = "中文",
			["buttons_title"] = "按钮",
			["values_title"] = "开关",
			["map_title"] = "地图",
			["changelog"] = "更新日志",
			["settings"] = "设置",
			["lang_switch"] = "切换语言",
			["suicideButton_title"] = "自杀",
			["suicideButton_desc"] = "直接杀死自己。",
			["suicideBind_title"] = "自杀快捷键",
			["suicideBind_desc"] = "按一下就能自杀。",
			["hunter_title"] = "猎人模式",
			["hunter_desc"] = "开启后移动速度变快。",
			["thirdperson_title"] = "第三人称",
			["thirdperson_desc"] = "切换第三人称视角。",
			["chat_title"] = "聊天历史",
			["chat_desc"] = "显示聊天历史记录。",
			["elephant_foot"] = "移除大象脚",
			["arabic_man"] = "移除录像带男",
			["console_tp"] = "移除控制台传送",
			["radiation"] = "移除辐射",
			["speed_title"] = "移动速度",
			["speed_desc"] = "速度倍率。",
			["jump_title"] = "跳跃",
			["jump_desc"] = "跳跃倍率。",
			["sector1"] = "区域 1",
			["sector2"] = "区域 2",
			["sector3"] = "区域 3",
			["out-of-map"] = "地图外",
			["sectorEntrance"] = "区域入口",
			["keycard"] = "钥匙卡",
			["spawn"] = "出生点",
			["gen1"] = "发电机 1",
			["reactor4"] = "反应堆 4",
			["mutant"] = "变异爬行者",
			["valve"] = "阀门",
			["gen2"] = "发电机 2",
			["russmanOffice"] = "拉斯曼办公室",
			["armory"] = "军械库",
			["steve"] = "史蒂夫",
			["crate_1-3"] = "武器箱 1-3",
			["crate_4"] = "武器箱 4",
			["crate_5"] = "武器箱 5",
			["crate_6"] = "武器箱 6",
			["c4_1"] = "C4 箱 1",
			["c4_2"] = "C4 箱 2",
			["c4_3"] = "C4 箱 3",
			["c4_4"] = "C4 箱 4",
			["baseplate"] = "底板",
			["esp_desc"] = "透视所有感染体和士兵。",
			["infection_title"] = "感染体界面",
			["infection_desc"] = "显示可控感染体的界面。",
			["gasmask_title"] = "移除防毒面具界面",
			["death_title"] = "移除死亡界面",
			["chimera_title"] = "移除奇美拉惊吓界面",
			["gilbert_title"] = "移除吉尔伯特惊吓界面",
			["changelog_date_1"] = "v2.1 2月26日",
			["changelog_text_1"] = "修复了重生后透视可能失效的问题。",
			["changelog_date_2"] = "v2.0 2月24日",
			["changelog_text_2"] = "脚本完全重写，优化更多，动画更全，改用 WindUI。",
			["windKeybind_title"] = "界面快捷键",
			["windKeybind_desc"] = "打开或关闭界面的按键。",
			["windDestroy_title"] = "关闭界面",
			["windDestroy_desc"] = "销毁界面及其所有连接。"
		}
	}
})

-- window
local window = windUI:CreateWindow({
	Title = "试炼",
	Author = "婴儿脚本",
	Folder = "Examination",
	ScrollBarEnabled = true
})

window:EditOpenButton({
	Title = "l:openButton",
	CornerRadius = UDim.new(0,16),
	StrokeThickness = 1,
	Enabled = true,
	Draggable = true
})

-- configuration manager
local cfgManager = window.ConfigManager
local examCfg = cfgManager:CreateConfig("examCfg")

-- tabs
local mainTab = window:Tab({Title = "l:mainTab", Icon = "house"})
local movementTab = window:Tab({Title = "l:movementTab", Icon = "footprints"})
local teleportTab = window:Tab({Title = "l:teleportTab", Icon = "fast-forward"})
local guiTab = window:Tab({Title = "l:guiTab", Icon = "gamepad-2"})
local aboutTab = window:Tab({Title = "l:aboutTab", Icon = "badge-info"})

-- optimization
local chatService = game:GetService("TextChatService")
local runService = game:GetService("RunService")
local lighting = game:GetService("Lighting")
local players = game:GetService("Players")
local plr = players.LocalPlayer
local plrGui = plr.PlayerGui

-- default values
local thirdPersonEnabled = false
local chatEnabled = false
local baseSpeed = 8
local speedMultiplier = 1
local speedEnabled = false
local jumpMultiplier = 1
local jumpEnabled = false
local charsFolder = workspace.Characters
local espEnabled = false
local plrColor = Color3.fromHex("#506d54")
local npcColor = Color3.fromHex("#750000")

-- tables
local highlights = {}
local animationTracks = {}
local activeToggles = {}

-- functions
local function applyCam()
	if thirdPersonEnabled then
		plr.CameraMode = Enum.CameraMode.Classic
		plr.CameraMaxZoomDistance = 15
	else
		plr.CameraMode = Enum.CameraMode.LockFirstPerson
	end
end

local function apply(cfg)
	if not cfg then return end
	cfg.Enabled = chatEnabled
	cfg:GetPropertyChangedSignal("Enabled"):Connect(function()
		if chatEnabled and not cfg.Enabled then
			cfg.Enabled = true
		end
	end)
end

local function init()
	apply(chatService:FindFirstChild("ChatWindowConfiguration"))
end

chatService.ChildAdded:Connect(function(c)
	if c.Name == "ChatWindowConfiguration" then apply(c) end
end)

local function removeObject(name)
	local obj = workspace:FindFirstChild(name, true)
	if obj then
		pcall(function()
			obj:Destroy()
		end)
	end
end

runService.RenderStepped:Connect(function()
	local char = plr.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	local current = hum.WalkSpeed
	local expected = baseSpeed * speedMultiplier
	if math.abs(current - expected) > 0.05 then
		baseSpeed = current
	end
	if speedEnabled then
		hum.WalkSpeed = baseSpeed * speedMultiplier
	end
end)

runService.RenderStepped:Connect(function()
	if not jumpEnabled then return end
	local char = plr.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	hum.UseJumpPower = false
	hum.JumpHeight = 1 * jumpMultiplier
end)

local function teleportTo(position)
	plr.Character.HumanoidRootPart.CFrame = CFrame.new(position)
end

local function createHealth(character)
	local hum = character:FindFirstChildOfClass("Humanoid")
	local head = character:FindFirstChild("Head")
	if not hum or not head then return end
	if head:FindFirstChild("espHealth") then return end
	local bb = Instance.new("BillboardGui")
	bb.Name = "espHealth"
	bb.Size = UDim2.new(4, 0, 0.6, 0)
	bb.StudsOffset = Vector3.new(0, 2.5, 0)
	bb.AlwaysOnTop = false
	bb.Parent = head
	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.new(0, 0, 0)
	bg.BorderSizePixel = 0
	bg.Parent = bb
	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.BorderSizePixel = 0
	bar.Parent = bg

	local function update()
		local ratio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
		bar.Size = UDim2.new(ratio, 0, 1, 0)
		local r = 1 - ratio
		local g = ratio
		bar.BackgroundColor3 = Color3.new(r, g, 0)
	end

	update()
	hum.HealthChanged:Connect(update)
end

local function createESP(character)
	if highlights[character] or not espEnabled then return end
	if not character:FindFirstChildOfClass("Humanoid") then return end
	local hl = Instance.new("Highlight")
	hl.Name = "espHighlight"
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.FillTransparency = 0.5
	hl.OutlineTransparency = 0.1
	hl.Parent = character
	if character:FindFirstChild("Humanoid") then
        if game.Players:GetPlayerFromCharacter(character) then
		    hl.FillColor = plrColor
		    hl.OutlineColor = plrColor
	    else
		    hl.FillColor = npcColor
		    hl.OutlineColor = npcColor
	    end
    end
	createHealth(character)
	highlights[character] = hl
end

charsFolder.ChildAdded:Connect(function(character)
	if character:IsA("Model") then
        wait(0.5)
		createESP(character)
	end
end)

local function getHumanoid()
	local char = plr.Character
	if not char then return end
	return char:FindFirstChildOfClass("Humanoid")
end

local function playToggleAnim(name, id, state)
	local hum = getHumanoid()
	if not hum then return end

	if state then
		if not animationTracks[name] then
			local anim = Instance.new("Animation")
			anim.AnimationId = id

			local track = hum:LoadAnimation(anim)
			track.Priority = Enum.AnimationPriority.Action
			track.Looped = true
			track:Play()

			animationTracks[name] = track
		end
		activeToggles[name] = true
	else
		if animationTracks[name] then
			animationTracks[name]:Stop()
			animationTracks[name]:Destroy()
			animationTracks[name] = nil
		end
		activeToggles[name] = nil
	end
end

local function playButtonAnim(id)
	local hum = getHumanoid()
	if not hum then return end
	local anim = Instance.new("Animation")
	anim.AnimationId = id
	local track = hum:LoadAnimation(anim)
	track.Priority = Enum.AnimationPriority.Action
	track.Looped = false
	track:Play()
	track.Stopped:Connect(function()
		track:Destroy()
	end)
end

plr.CharacterAdded:Connect(function()
	animationTracks = {}
	activeToggles = {}
end)

-- main tab
mainTab:Section({Title = "l:buttons_title"})

mainTab:Button({
	Title = "l:suicideButton_title",
	Desc = "l:suicideButton_desc",
	Locked = false,
	Icon = "smile",
	Callback = function()
		plr.Character.Humanoid.Health = 0
	end
})

mainTab:Keybind({
	Title = "l:suicideBind_title",
	Desc = "l:suicideBind_desc",
	Value = "Period",
	Callback = function()
		plr.Character.Humanoid.Health = 0
	end
})

mainTab:Section({Title = "l:values_title"})

mainTab:Toggle({
	Title = "l:thirdperson_title",
	Desc = "l:thirdperson_desc",
	Type = "Checkbox",
	Value = false,
	Callback = function(v)
		thirdPersonEnabled = v
		applyCam()
	end
})

runService.RenderStepped:Connect(function()
	if thirdPersonEnabled then
		if plr.CameraMode ~= Enum.CameraMode.Classic then
			plr.CameraMode = Enum.CameraMode.Classic
		end
		if plr.CameraMaxZoomDistance < 15 then
			plr.CameraMaxZoomDistance = 15
		end
	end
end)

plr.CharacterAdded:Connect(function()
	task.wait(0.1)
	applyCam()
end)

mainTab:Toggle({
	Title = "l:chat_title",
	Desc = "l:chat_desc",
	Type = "Checkbox",
	Value = false,
	Callback = function(v)
		chatEnabled = v
		init()
	end
})

mainTab:Section({Title = "l:map_title"})

mainTab:Button({
	Title = "l:elephant_foot",
	Callback = function()
		removeObject("LookAtMe")
	end
})

mainTab:Button({
	Title = "l:arabic_man",
	Callback = function()
		removeObject("LookAtHim")
	end
})

mainTab:Button({
	Title = "l:console_tp",
	Callback = function()
		removeObject("ConsoleTeleport")
	end
})

mainTab:Button({
	Title = "l:radiation",
	Callback = function()
		removeObject("Radiation")
	end
})

-- movement tab
movementTab:Slider({
	Title = "l:speed_title",
	Desc = "l:speed_desc",
	Step = 0.05,
	Value = {Min = 1, Max = 2, Default = 1},
	Callback = function(v)
		speedMultiplier = v
		speedEnabled = (v ~= 1)
	end
})

movementTab:Slider({
	Title = "l:jump_title",
	Desc = "l:jump_desc",
	Step = 0.1,
	Value = {Min = 1, Max = 50, Default = 1},
	Callback = function(v)
		jumpMultiplier = v
		jumpEnabled = (v ~= 1)
	end
})

-- teleports tab
local teleportPoints = {
	["l:sector1"] = {
		{"l:spawn", Vector3.new(-55, -33, -1410)},
		{"l:gen1", Vector3.new(135, -30, -1225)},
		{"l:reactor4", Vector3.new(-230, -30, -1428)},
		{"l:mutant", Vector3.new(-155, -33, -1565)},
		{"l:valve", Vector3.new(-225, -35, -1635)},
		{"l:gen2", Vector3.new(-140, -30, -1145)},
	},
	["l:sector2"] = {
		{"l:sectorEntrance", Vector3.new(-110, -10, -825)},
		{"l:russmanOffice", Vector3.new(38, -10, -917)},
		{"l:armory", Vector3.new(-45, -10, -894)},
		{"l:keycard", Vector3.new(50, -10, -1054)},
		{"l:steve", Vector3.new(-30, 0, -1058)},
	},
	["l:sector3"] = {
		{"l:sectorEntrance", Vector3.new(208, -31, -1171)},
		{"l:crate_1-3", Vector3.new(289, -31, -1216)},
		{"l:crate_4", Vector3.new(676, -31, -1342)},
		{"l:crate_5", Vector3.new(597, -49, -1395)},
		{"l:crate_6", Vector3.new(471, -50, -1293)},
		{"l:c4_1", Vector3.new(462, -31, -1004)},
		{"l:c4_2", Vector3.new(349, -31, -817)},
		{"l:c4_3", Vector3.new(636, -31, -754)},
		{"l:c4_4", Vector3.new(843, -18, -1060)},
		{"l:keycard", Vector3.new(774, -31, -857)},
	},
	["l:out-of-map"] = {
		{"l:baseplate", Vector3.new(-200, -2, -75)}
	},
}

for sectorName, points in pairs(teleportPoints) do
	teleportTab:Section({Title = sectorName})
	for _, data in ipairs(points) do
		local name, pos = unpack(data)
		teleportTab:Button({Title = name, Callback = function() teleportTo(pos) end})
	end
end

-- gui tab
guiTab:Toggle({
	Title = "ESP",
	Desc = "l:esp_desc",
	Type = "Checkbox",
	Value = false,
	Callback = function(v)
		espEnabled = v
		if v then
			for _, character in ipairs(charsFolder:GetChildren()) do
				if character:IsA("Model") then
					createESP(character)
				end
			end
		else
			for character, _ in pairs(highlights) do
				removeESP(character)
			end
		end
	end
})

local infSound = plrGui.Gasmask.MaskHole.ACTIVATE
local infMusic = plrGui.Gasmask.MaskHole.HATRED_OSTS.HATRED
local infAnim = Instance.new("Animation")
infAnim.AnimationId = "rbxassetid://136775254837264"
local infTrack
local infCC = lighting:FindFirstChild("InfectionColorCorrection") or Instance.new("ColorCorrectionEffect")
infCC.Name = "InfectionColorCorrection"
infCC.Parent = lighting
infCC.Enabled = false
infCC.TintColor = Color3.fromRGB(255, 0, 0)

guiTab:Toggle({
	Title = "l:infection_title",
	Desc = "l:infection_desc",
	Value = false,
	Callback = function(enabled)
		local char = plr.Character or plr.CharacterAdded:Wait()
		local hum = char:FindFirstChildOfClass("Humanoid")
		local head = char:FindFirstChild("Head")

		if hum then
			local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
			if enabled then
				if not infTrack then
					infTrack = animator:LoadAnimation(infAnim)
				end
				infTrack:Play()
			else
				if infTrack then
					infTrack:Stop()
					infTrack:Destroy()
					infTrack = nil
				end
			end
		end

		infSound.Playing = enabled
		infMusic.Playing = enabled
		infCC.Enabled = enabled

		if head then
			for _, side in ipairs({"InfectedLeft", "InfectedRight"}) do
				local emitterObj = head:FindFirstChild(side)
				if emitterObj and emitterObj:FindFirstChildOfClass("ParticleEmitter") then
					emitterObj.ParticleEmitter.Enabled = enabled
				end
			end
		end
	end
})

guiTab:Button({
	Title = "l:gasmask_title",
	Locked = false,
	Callback = function()
		local ui = plrGui.Gasmask
		if ui then ui:Destroy() end
	end
})

guiTab:Button({
	Title = "l:death_title",
	Locked = false,
	Callback = function()
		local ui = plrGui.Death
		if ui then ui:Destroy() end
	end
})

guiTab:Button({
	Title = "l:chimera_title",
	Locked = false,
	Callback = function()
		local ui = plrGui.ChimeraRad
		if ui then ui:Destroy() end
	end
})

guiTab:Button({
	Title = "l:gilbert_title",
	Locked = false,
	Callback = function()
		local ui = plrGui.GilbertRad
		if ui then ui:Destroy() end
	end
})

-- about tab
aboutTab:Section({Title = "l:settings"})

aboutTab:Keybind({
	Title = "l:windKeybind_title",
	Desc = "l:windKeybind_desc",
	Value = "K",
	Callback = function(v)
		window:SetToggleKey(Enum.KeyCode[v])
	end
})

aboutTab:Section({Title = "l:lang_switch"})

aboutTab:Button({
	Title = "l:lang_chinese",
	Icon = "languages",
	Callback = function()
		windUI:SetLanguage("zh")
	end
})

aboutTab:Button({
	Title = "l:lang_english",
	Icon = "languages",
	Callback = function()
		windUI:SetLanguage("en")
	end
})

windUI:Notify({
	Title = "l:loadSuccess_title",
	Content = "l:loadSuccess_desc",
	Duration = 5,
	Icon = "smile"
})

-- load configuration
examCfg:Save()
examCfg:Load()
