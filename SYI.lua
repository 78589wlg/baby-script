-- ============================================================
-- 婴儿脚本 · 生存你的想法（Survive Your Ideas）
-- PlaceId: 77900175935766
-- 独立脚本，不依赖主面板、不依赖任何 Hub
-- 功能：词库分类浏览 / 搜索 / 一键填入并发送 / 玩家 ESP / 全亮
-- 纯明文，无外链、无密钥、无混淆
-- ============================================================

local P   = game:GetService("Players")
local LP  = P.LocalPlayer
local PG  = LP:WaitForChild("PlayerGui")
local L   = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")

local cfg = { autoSend = true, esp = false, bright = false }

-- ============================================================
-- 词库（分类取自公开词表，可自行增删）
-- ============================================================
local CATEGORIES = {
    {
        name  = "Disasters",
        icon  = "💥",
        color = Color3.fromRGB(240, 70, 70),
        words = {
            "Lava","Tsunami","acid","Black Hole","black_hole",
            "Earthquake","fire","flood","Meteor","apocalypse",
            "Fallout","satellite","Epidemic","epidemia","enxurrada",
            "rumbling","quicksand","supernova","titanic","Tornado",
            "volcano","zone","boulder","alien","Nuke"
        }
    },
    {
        name  = "Weather",
        icon  = "🌤️",
        color = Color3.fromRGB(70, 170, 250),
        words = {
            "BLACKOUT","Blind","clear","Dark","day","fog",
            "hail","heat","horror","ice","lightning","night",
            "rain","Sand Shower","sandstorm","sky","snow",
            "storm","sunset","wind"
        }
    },
    {
        name  = "Animals",
        icon  = "🐾",
        color = Color3.fromRGB(90, 210, 110),
        words = {
            "Dinosaur","Godzilla","King Kong","kingkong","Maxwell",
            "ant","bear","bees","capybara","cat","chicken",
            "cockroach","cow","crab","crocodile","dog","elephant",
            "fish","frog","goose","jellyfish","lion","locust",
            "monkey","moodeng","mosquito","octopus","penguin",
            "pig","rabbit","rat","shark","sheep","snake",
            "spider","whale","wolf","worm"
        }
    },
    {
        name  = "Monsters",
        icon  = "👾",
        color = Color3.fromRGB(180, 80, 240),
        words = {
            "Killer","Silent Head","Titan","Zombies","zombie",
            "angel","animatronic","clown","devil","dragon",
            "fairy","ghost","giant","gnome","herobrine",
            "invisible","kaiju","leprechaun","mahoraga","monster",
            "mummy","nextbot","ninja","noob","ogre","pirate",
            "reaper","robot","scp","seek","sirenhead","skeleton",
            "skinwalker","slenderman","slime","unicorn","vampire",
            "verity","werewolf","wizard"
        }
    },
    {
        name  = "Nature",
        icon  = "🌿",
        color = Color3.fromRGB(40, 200, 130),
        words = {
            "DESERT","autumn","bamboo","beach","beanstalk",
            "bush","cactus","cave","fireflies","flowers",
            "geyser","grass","island","jungle","mountain",
            "mud","oasis","prehistoric","pumpkin","savanna",
            "swamp","tree","tundra","underwater","water","waterfall"
        }
    },
    {
        name  = "Objects",
        icon  = "🛋️",
        color = Color3.fromRGB(240, 170, 60),
        words = {
            "Jack In The Box","jackbox","Lucky Block","lucky_block",
            "anvil","ball","balloons","bathtub","bed","bike",
            "boat","book","bouncy castle","bouncycastle","bowling",
            "box","btools","bubble","bus","button","car",
            "chair","chest","computer","cones","confetti",
            "conveyor","diamond","dominoes","door","duck",
            "exit","firefighter","fireworks","firetruck",
            "fountain","gift","glue","go kart","gokart",
            "hamster ball","hamster_ball","hat","helicopter",
            "jenga","kite","ladder","lamp","launchpad","lego",
            "magnet","medkit","money","oil","ok","paper",
            "parachute","pendulum","piano","picnic","pinata",
            "plane","poo","raft","rollercoaster","sandbags",
            "scarecrow","snowman","spikes","stairs","sussy",
            "table","tires","train","treasure","tv","umbrella",
            "wall","zipline"
        }
    },
    {
        name  = "Places",
        icon  = "🏠",
        color = Color3.fromRGB(250, 140, 50),
        words = {
            "Gas Station","gasstation","The Upside Down","upside_down",
            "Water Slide","waterslide","aquarium","backrooms",
            "barn","basketball","bridge","brookhaven","building",
            "camping","carousel","castle","christmas","church",
            "cinema","city","dream","easter","farm","festajunina",
            "ferris wheel","ferriswheel","graveyard","greenhouse",
            "halloween","heaven","hell","hospital","house",
            "igloo","jail","kitchen","lighthouse","mansion",
            "matrix","maze","moai","museum","neon","obby",
            "ohio","playground","pyramid","pyramidsofgeza",
            "roblox hq","safehouse","sandcastle","school",
            "skatepark","space","stadium","stonehenge",
            "supermarket","teacups","temple","tower","trash",
            "treehouse","western","windmill","zoo"
        }
    },
    {
        name  = "Food",
        icon  = "🍔",
        color = Color3.fromRGB(240, 200, 50),
        words = {
            "Bacon","Barbecue","Food","Potato","Tacos",
            "WATERMELON","banana","churrasco","icecreamtruck"
        }
    },
    {
        name  = "Weapons",
        icon  = "⚔️",
        color = Color3.fromRGB(220, 60, 60),
        words = {
            "Baseball Bat","Double Barrel","Flamethrower",
            "Frying Pan","G3","Katana","Knife","Luger",
            "Magnum","MP5","Pickaxe","Railgun","Rainbow Gun",
            "Remington","Revolver","Road Roller","roadroller",
            "RPG","Saw","Shield","Sniper","Snowball","Spencer",
            "Steamgun","Sword","airstrike","bomb","gun",
            "landmine","laser","melee","tank","Nuke"
        }
    },
    {
        name  = "Memes/Powers",
        icon  = "✨",
        color = Color3.fromRGB(255, 110, 190),
        words = {
            "Ballerina Cappuccina","Don't Stop","Falling Blocks",
            "falling_blocks","FORCEFIELD","GO","GOKU","GOD",
            "IDLE","POOP","RONALDO","Time Stop","time_stop",
            "Tung Tung Tung Sahur","Upside Down","SUKUNA","TOJI",
            "PICNIC+TREX","67","afk","angry","arise","aura",
            "baby","ballerina","bankai","ban","bonk","bruh",
            "chillguy","chimpanzini","crazy","cry","dad",
            "dance","darkclone","delete","die","dizzy",
            "domain","energy_blast","error","ez","fall",
            "fart","flash","fly","freeze","gg","gojo",
            "gravity","guest","hero","hi","hunger","idk",
            "jump","kaioken","kill","king","laugh","lirili",
            "love","luffy","me","minecraft","mom","mrbeast",
            "nani","naruto","neymar","nokia","normal","nothing",
            "nyan","oof","paint","patapim","peace","person",
            "pikachu","pillows","please","push","quiet",
            "rasengan","reset","retro","revive","rizz",
            "saitama","sans","santa","scream","sharingan",
            "shield","shrink","sigma","sit","siuuu","size",
            "skibidi","sky_letter","sleep","slow","snap",
            "sneeze","sorry","speed","spin","spiderman",
            "star","swap","tanjiro","teleport","tralalero",
            "trippi","troll","tung","up","upside","vomit",
            "walk","what","win","wow","Y"
        }
    },
    {
        name  = "Commands",
        icon  = "⚡",
        color = Color3.fromRGB(140, 90, 255),
        words = {
            "/double", "/secret", "/lag", "/undo", "/ghost", "/jackpot",
            "/admin", "/reset", "/chaos", "/god"
        }
    }
}

-- ============================================================
-- 基础工具
-- ============================================================
local function new(cls, props, parent)
	local o = Instance.new(cls)
	for k, v in pairs(props or {}) do
		o[k] = v
	end
	if parent then
		o.Parent = parent
	end
	return o
end

local function notify(text, dur)
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = "生存你的想法",
			Text = tostring(text),
			Duration = dur or 4,
		})
	end)
end

local dark   = Color3.fromRGB(18, 20, 26)
local panel  = Color3.fromRGB(28, 32, 42)
local accent = Color3.fromRGB(90, 160, 255)
local textC  = Color3.fromRGB(235, 240, 250)

-- ============================================================
-- 找游戏输入框 / 发送
-- ============================================================
local SELF_NAME = "SYI_PANEL"

local function isMine(obj)
	local p = obj
	while p do
		if p.Name == SELF_NAME then
			return true
		end
		p = p.Parent
	end
	return false
end

local function findBox()
	local focused = UIS:GetFocusedTextBox()
	if focused and focused.Visible and not isMine(focused) then
		return focused
	end
	local best
	for _, d in ipairs(PG:GetDescendants()) do
		if d:IsA("TextBox") and d.Visible and d.TextEditable and not isMine(d) then
			if d.AbsoluteSize.Y > 4 then
				best = d
				if string.find(string.lower(d.Name), "type") or string.find(string.lower(d.Name), "word") then
					return d
				end
			end
		end
	end
	return best
end

local function findSendButton()
	local best
	for _, d in ipairs(PG:GetDescendants()) do
		if d:IsA("TextButton") and d.Visible and not isMine(d) then
			local t = string.lower(d.Text or "")
			if t:find("send", 1, true) or t:find("submit", 1, true) or t:find("enter", 1, true) then
				best = d
			end
		end
	end
	return best
end

local function fireButton(btn)
	local ok = pcall(function()
		if getconnections then
			for _, c in ipairs(getconnections(btn.MouseButton1Click)) do
				c:Fire()
			end
			return true
		end
		return false
	end)
	if ok then
		return true
	end
	-- 兜底：模拟点击按钮中心
	local vim = game:GetService("VirtualInputManager")
	local pos = btn.AbsolutePosition + btn.AbsoluteSize / 2
	pcall(function()
		vim:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
		task.wait(0.03)
		vim:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
	end)
	return true
end

local function pressEnter()
	local vim = game:GetService("VirtualInputManager")
	pcall(function()
		vim:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
		task.wait(0.05)
		vim:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
	end)
end

local function sendWord(word)
	local box = findBox()
	if not box then
		notify("先点一下游戏里的输入框，让它弹出来，再点词", 6)
		return false
	end
	pcall(function()
		box:CaptureFocus()
	end)
	task.wait(0.05)
	pcall(function()
		box.Text = word
	end)
	task.wait(0.05)
	pcall(function()
		box:ReleaseFocus(true)
	end)

	if cfg.autoSend then
		task.delay(0.1, function()
			local btn = findSendButton()
			if btn then
				fireButton(btn)
			end
			task.delay(0.1, function()
				local btn2 = findSendButton()
				if not btn2 then
					pressEnter()
				end
			end)
		end)
	end
	notify("已填入：" .. word, 3)
	return true
end

-- ============================================================
-- 界面
-- ============================================================
local old = PG:FindFirstChild(SELF_NAME)
if old then
	old:Destroy()
end

local sg = new("ScreenGui", {
	Name = SELF_NAME,
	ResetOnSpawn = false,
	DisplayOrder = 999,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, PG)

local main = new("Frame", {
	Size = UDim2.new(0, 330, 0, 432),
	Position = UDim2.new(0, 18, 0, 110),
	BackgroundColor3 = dark,
	BorderSizePixel = 0,
}, sg)
new("UICorner", { CornerRadius = UDim.new(0, 12) }, main)
new("UIStroke", { Color = Color3.fromRGB(60, 70, 90), Thickness = 1 }, main)

local bar = new("Frame", {
	Size = UDim2.new(1, 0, 0, 40),
	BackgroundColor3 = panel,
	BorderSizePixel = 0,
}, main)
new("UICorner", { CornerRadius = UDim.new(0, 12) }, bar)

new("TextLabel", {
	Size = UDim2.new(1, -90, 1, 0),
	Position = UDim2.new(0, 12, 0, 0),
	BackgroundTransparency = 1,
	Text = "生存你的想法 · 词库",
	TextColor3 = textC,
	TextSize = 16,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
}, bar)

local foldBtn = new("TextButton", {
	Size = UDim2.new(0, 32, 0, 28),
	Position = UDim2.new(1, -40, 0, 6),
	BackgroundColor3 = Color3.fromRGB(50, 58, 74),
	Text = "—",
	TextColor3 = textC,
	TextSize = 18,
	Font = Enum.Font.GothamBold,
	BorderSizePixel = 0,
}, bar)
new("UICorner", { CornerRadius = UDim.new(0, 8) }, foldBtn)

local body = new("Frame", {
	Size = UDim2.new(1, 0, 1, -40),
	Position = UDim2.new(0, 0, 0, 40),
	BackgroundTransparency = 1,
}, main)

-- 分类栏
local catBar = new("ScrollingFrame", {
	Size = UDim2.new(1, -16, 0, 34),
	Position = UDim2.new(0, 8, 0, 8),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 0,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.X,
	ScrollingDirection = Enum.ScrollingDirection.X,
}, body)
new("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
	VerticalAlignment = Enum.VerticalAlignment.Center,
}, catBar)

-- 搜索框
local search = new("TextBox", {
	Size = UDim2.new(1, -16, 0, 30),
	Position = UDim2.new(0, 8, 0, 48),
	BackgroundColor3 = Color3.fromRGB(38, 43, 56),
	Text = "",
	PlaceholderText = "搜索词（英文，如 lava）",
	PlaceholderColor3 = Color3.fromRGB(140, 150, 170),
	TextColor3 = textC,
	TextSize = 14,
	Font = Enum.Font.Gotham,
	ClearTextOnFocus = false,
	BorderSizePixel = 0,
}, body)
new("UICorner", { CornerRadius = UDim.new(0, 8) }, search)
new("UIPadding", { PaddingLeft = UDim.new(0, 10) }, search)

-- 词列表
local list = new("ScrollingFrame", {
	Size = UDim2.new(1, -16, 1, -146),
	Position = UDim2.new(0, 8, 0, 86),
	BackgroundColor3 = Color3.fromRGB(23, 26, 34),
	BorderSizePixel = 0,
	ScrollBarThickness = 4,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, body)
new("UICorner", { CornerRadius = UDim.new(0, 8) }, list)
new("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, list)
new("UIPadding", {
	PaddingLeft = UDim.new(0, 4),
	PaddingRight = UDim.new(0, 4),
	PaddingTop = UDim.new(0, 4),
	PaddingBottom = UDim.new(0, 4),
}, list)

-- 底部状态 + 开关
local foot = new("Frame", {
	Size = UDim2.new(1, -16, 0, 52),
	Position = UDim2.new(0, 8, 1, -58),
	BackgroundTransparency = 1,
}, body)

local countLabel = new("TextLabel", {
	Size = UDim2.new(0.4, 0, 0, 20),
	BackgroundTransparency = 1,
	Text = "共 0 个词",
	TextColor3 = Color3.fromRGB(150, 160, 180),
	TextSize = 12,
	Font = Enum.Font.Gotham,
	TextXAlignment = Enum.TextXAlignment.Left,
}, foot)

local function makeToggle(text, x, get, set)
	local b = new("TextButton", {
		Size = UDim2.new(0, 96, 0, 26),
		Position = UDim2.new(x, 0, 0, 20),
		BackgroundColor3 = Color3.fromRGB(45, 52, 68),
		TextColor3 = textC,
		TextSize = 12,
		Font = Enum.Font.Gotham,
		BorderSizePixel = 0,
	}, foot)
	new("UICorner", { CornerRadius = UDim.new(0, 7) }, b)
	local function paint()
		b.Text = text .. (get() and " ✓" or " ✗")
		b.BackgroundColor3 = get() and Color3.fromRGB(40, 100, 70) or Color3.fromRGB(45, 52, 68)
	end
	b.MouseButton1Click:Connect(function()
		set(not get())
		paint()
	end)
	paint()
	return b
end

-- ============================================================
-- 列表渲染
-- ============================================================
local curCat = 0          -- 0 = 全部
local query = ""

local function clearList()
	for _, c in ipairs(list:GetChildren()) do
		if c:IsA("TextButton") then
			c:Destroy()
		end
	end
end

local function refreshList()
	clearList()
	local q = string.lower(query)
	local n = 0
	for _, cat in ipairs(CATEGORIES) do
		if curCat == 0 or cat.name == curCat then
			for _, w in ipairs(cat.words) do
				if q == "" or string.find(string.lower(w), q, 1, true) then
					n = n + 1
					local b = new("TextButton", {
						Size = UDim2.new(1, 0, 0, 28),
						BackgroundColor3 = Color3.fromRGB(34, 39, 51),
						Text = w,
						TextColor3 = Color3.fromRGB(225, 232, 245),
						TextSize = 14,
						Font = Enum.Font.GothamMedium,
						TextXAlignment = Enum.TextXAlignment.Left,
						BorderSizePixel = 0,
						LayoutOrder = n,
					}, list)
					new("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
					new("UIPadding", { PaddingLeft = UDim.new(0, 10) }, b)
					b.MouseButton1Click:Connect(function()
						sendWord(w)
					end)
				end
			end
		end
	end
	countLabel.Text = "共 " .. n .. " 个词"
end

-- 分类按钮
local function makeCat(text, key, order)
	local b = new("TextButton", {
		Size = UDim2.new(0, 0, 0, 28),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Color3.fromRGB(45, 52, 68),
		Text = text,
		TextColor3 = textC,
		TextSize = 13,
		Font = Enum.Font.Gotham,
		BorderSizePixel = 0,
		LayoutOrder = order,
	}, catBar)
	new("UICorner", { CornerRadius = UDim.new(0, 14) }, b)
	new("UIPadding", {
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
	}, b)
	b.MouseButton1Click:Connect(function()
		curCat = key
		for _, c in ipairs(catBar:GetChildren()) do
			if c:IsA("TextButton") then
				c.BackgroundColor3 = Color3.fromRGB(45, 52, 68)
			end
		end
		b.BackgroundColor3 = accent
		refreshList()
	end)
	return b
end

local allBtn = makeCat("全部", 0, 0)
allBtn.BackgroundColor3 = accent
for i, cat in ipairs(CATEGORIES) do
	makeCat(cat.name, cat.name, i)
end

search:GetPropertyChangedSignal("Text"):Connect(function()
	query = search.Text
	refreshList()
end)

-- ============================================================
-- ESP / 全亮
-- ============================================================
local espTag = {}

local function clearESP()
	for _, hl in pairs(espTag) do
		pcall(function()
			if hl and hl.Parent then
				hl:Destroy()
			end
		end)
	end
	espTag = {}
end

local function refreshESP()
	if not cfg.esp then
		clearESP()
		return
	end
	for _, pl in ipairs(P:GetPlayers()) do
		if pl ~= LP and pl.Character and not espTag[pl] then
			local hl = Instance.new("Highlight")
			hl.Name = "SYI_ESP"
			hl.FillColor = Color3.fromRGB(255, 90, 90)
			hl.FillTransparency = 0.55
			hl.OutlineColor = Color3.fromRGB(255, 255, 255)
			hl.Adornee = pl.Character
			hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			hl.Parent = pl.Character
			espTag[pl] = hl
		end
	end
	for pl, hl in pairs(espTag) do
		if not pl.Character or not pl.Parent or not hl.Parent then
			pcall(function() hl:Destroy() end)
			espTag[pl] = nil
		end
	end
end

local brightSave
local function setBright(on)
	if on then
		if not brightSave then
			brightSave = { b = L.Brightness, t = L.ClockTime, a = L.Ambient, o = L.OutdoorAmbient }
		end
		pcall(function()
			L.Brightness = 3
			L.ClockTime = 14
			L.Ambient = Color3.fromRGB(180, 180, 180)
			L.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
		end)
	else
		if brightSave then
			pcall(function()
				L.Brightness = brightSave.b
				L.ClockTime = brightSave.t
				L.Ambient = brightSave.a
				L.OutdoorAmbient = brightSave.o
			end)
			brightSave = nil
		end
	end
end

-- 底部开关
makeToggle("自动发送", 0, function() return cfg.autoSend end, function(v) cfg.autoSend = v end)
makeToggle("玩家ESP", 0.34, function() return cfg.esp end, function(v)
	cfg.esp = v
	refreshESP()
end)
makeToggle("全亮", 0.68, function() return cfg.bright end, function(v)
	cfg.bright = v
	setBright(v)
end)

task.spawn(function()
	while true do
		task.wait(1.5)
		pcall(refreshESP)
	end
end)

-- ============================================================
-- 拖动 / 折叠
-- ============================================================
local dragging, dragStart, startPos = false, nil, nil
bar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = main.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)
UIS.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		main.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end
end)

local folded = false
foldBtn.MouseButton1Click:Connect(function()
	folded = not folded
	if folded then
		main.Size = UDim2.new(0, 330, 0, 40)
		body.Visible = false
		foldBtn.Text = "+"
	else
		main.Size = UDim2.new(0, 330, 0, 432)
		body.Visible = true
		foldBtn.Text = "—"
	end
end)

refreshList()
notify("词库已加载：点词自动填入并发送（可关掉自动发送）", 5)
