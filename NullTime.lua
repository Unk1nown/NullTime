local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local nulltime = {}

local afkConns = {}
local afkRunning = true

do
	local VirtualUser = game:GetService("VirtualUser")

	local function silenceIdle()
		local ok, list = pcall(function()
			return getconnections(LocalPlayer.Idled)
		end)

		if not ok or type(list) ~= "table" then
			return
		end

		for _, connection in ipairs(list) do
			pcall(function()
				connection:Disable()
			end)
		end
	end

	local function nudge()
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector3.new())
		end)
	end

	silenceIdle()

	afkConns[#afkConns + 1] = LocalPlayer.Idled:Connect(nudge)

	task.spawn(function()
		while afkRunning do
			task.wait(60)

			if not afkRunning or not LocalPlayer.Parent then
				break
			end

			silenceIdle()
			nudge()
		end
	end)
end

local function resolveGuiRoot()
	local ok, hidden = pcall(function()
		return gethui()
	end)
	if ok and typeof(hidden) == "Instance" then
		return hidden
	end

	local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if playerGui then
		return playerGui
	end

	return LocalPlayer:WaitForChild("PlayerGui", 10) or CoreGui
end

local GuiRoot = resolveGuiRoot()

for _, container in ipairs({ GuiRoot, CoreGui }) do
	for _, name in ipairs({ "UniverseESPGui", "UniverseCrystalEsp" }) do
		pcall(function()
			local existing = container:FindFirstChild(name)
			if existing then
				existing:Destroy()
			end
		end)
	end
end

local function findRemote(name)
	local folder = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:WaitForChild("Remotes", 10)
	if not folder then
		return nil
	end
	return folder:FindFirstChild(name) or folder:WaitForChild(name, 5)
end

local SellRequest = findRemote("SellRequest")
local GoHome = findRemote("GoHome")
local HoldComplete = findRemote("CrystalHoldComplete")
local ToggleFavorite = findRemote("ToggleFavorite")

local ESP = {
	font = Enum.Font.GothamBold,
	sweep = 0.5,
	budget = 0.005,
	offset = Vector3.new(0, 3, 0),
	width = 250,
	height = 66,
	text = 16,
	ttl = 5,
}

pcall(function()
	ESP.font = Enum.Font.LuckiestGuy
end)

local PLAYER = {
	offset = Vector3.new(0, -8, 0),
	width = 220,
	height = 44,
	text = 15,
}

local PACE = {
	boost = 35,
	normal = 16,
	stats = 0.25,
	distance = 0.05,
}

local TP = {
	offset = Vector3.new(0, 4.5, 0),
	hold = 0.35,
	clear = {
		Vector3.new(0, 0, 0),
		Vector3.new(0, 3, 0),
		Vector3.new(0, 7, 0),
		Vector3.new(5, 3, 0),
		Vector3.new(-5, 3, 0),
		Vector3.new(0, 3, 5),
		Vector3.new(0, 3, -5),
		Vector3.new(0, 12, 0),
		Vector3.new(9, 6, 0),
		Vector3.new(-9, 6, 0),
		Vector3.new(0, 6, 9),
		Vector3.new(0, 6, -9),
		Vector3.new(0, 20, 0),
	},
}

local PICK = {
	aimRange = 5000,
	aimDot = 0.995,
	range = 13,
	cooldown = 0.04,
	restore = 0.2,
	burst = 8,
	retry = 0.15,
	forget = 5,
	pad = 4,
	instantRadius = 60,
	instantTick = 0.25,
}

local COLORS = {
	money = Color3.fromRGB(60, 255, 90),
	default = Color3.fromRGB(0, 225, 255),
	extra = Color3.fromRGB(255, 255, 255),
	player = Color3.fromRGB(255, 40, 140),
	stroke = Color3.fromRGB(0, 0, 0),
	hexDistance = "00E5FF",
	hexLuck = "FFC400",
}

local TIER_NAMES = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic" }

local LUCK = {
	rarity = { 1, 1.6, 2.6, 4.2, 7, 12 },
	base = 0.00045,
	exponent = 0.5,
	cap = 500,
	bomb = 3,
	blood = 4,
}

local MUTATION_LUCK = {
	Verdant = 15,
	Voltaic = 20,
	Gilded = 18,
	Onyx = 28,
	Terminus = 40,
	Frost = 1.4,
	Fire = 1.4,
	Thunder = 1.5,
	Starfall = 1.3,
	Aurora = 2.2,
	Radioactive = 2,
	Poison = 1.5,
	Wet = 1,
}

local WATCHED_ATTRIBUTES = {
	"Value",
	"Collected",
	"WeightKg",
	"Tier",
	"TierName",
	"CrystalName",
	"Mutation",
	"ExtraMutations",
}

local SUFFIXES = { "", "k", "M", "B", "T", "Qa" }
local PARSE_MULTIPLIERS = { k = 1e3, m = 1e6, b = 1e9, t = 1e12, qa = 1e15 }
local CONTAINER_NAMES = { "DroppedCrystals", "Crystals" }

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

local Window = Library:CreateWindow({
	Title = "Mine a Mountain",
	Footer = "Mine a Mountain",
	AutoShow = true,
	NotifySide = "Right",
	ShowCustomCursor = false,
})

local Tabs = {
	crystals = Window:AddTab("Crystals", "gem"),
	players = Window:AddTab("Players", "users"),
	boulders = Window:AddTab("Boulders", "mountain"),
	teleports = Window:AddTab("Teleports", "crosshair"),
	farming = Window:AddTab("Farming", "pickaxe"),
	movement = Window:AddTab("Movement", "zap"),
}

local SettingsTab = Window:AddTab("Settings", "sliders-horizontal")

local EspHolder = Instance.new("Folder")
EspHolder.Name = "UniverseCrystalEsp"
EspHolder.Parent = GuiRoot

local registry = {}
local registryCount = 0
local candidates = {}
local dirty = {}
local espCache = {}
local espCount = 0
local containerConns = {}
local playerCache = {}

local espActive = false
local playerEspActive = false
local aimTpEnabled = false
local minValue = 2000000
local valueFilter = true
local espScale = 0.7
local playerScale = 0.6
local boulderScale = 0.6
local rootPart
local lastReport = 0
local tpState
local sweepAccumulator = math.huge
local statsDirty = true

local statsAccumulator = 0
local distanceAccumulator = math.huge
local lastPickup = 0
local autoPickupActive = false
local autoFarmCrystalActive = false
local lastBagWarn = 0
local instantPromptActive = false
local instantPatched = {}
local instantAccumulator = math.huge

-- Variables para Nulltime Boost & Fly
nulltime.SpeedBoostEnabled = false
nulltime.SpeedValue = 35
nulltime.FlyEnabled = false
nulltime.FlySpeed = 50
nulltime.BoulderFarmEnabled = false
nulltime.BoulderESPEnabled = false

local flyBodyVelocity = nil
local flyBodyGyro = nil

local function reportError(context, err)
	local now = os.clock()
	if now - lastReport < 5 then
		return
	end
	lastReport = now
	warn(string.format("[Mine a Mountain] %s: %s", context, tostring(err)))
end

local function formatShort(n, prefix)
	n = tonumber(n) or 0
	prefix = prefix or ""

	local sign = n < 0 and "-" or ""
	n = math.abs(n)

	if n < 1000 then
		return string.format("%s%s%d", sign, prefix, math.floor(n + 0.5))
	end

	local index = 0
	while n >= 1000 and index < #SUFFIXES - 1 do
		n /= 1000
		index += 1
	end

	return string.format("%s%s%.2f%s", sign, prefix, n, SUFFIXES[index + 1])
end

local function formatWeight(kg)
	kg = tonumber(kg) or 0
	if kg >= 1000 then
		return formatShort(kg) .. "kg"
	end
	return string.format("%.1fkg", kg)
end

local function formatDistance(studs)
	studs = tonumber(studs) or 0
	if studs >= 1000 then
		return string.format("%.1fkm", studs / 1000)
	end
	return string.format("%dm", math.floor(studs + 0.5))
end

local function formatLuck(score)
	local pct = (tonumber(score) or 0) * 100

	if pct <= 0 then
		return "+0%"
	end
	if pct < 1 then
		return string.format("+%.2f%%", pct)
	end
	if pct < 10 then
		return string.format("+%.1f%%", pct)
	end
	return string.format("+%.0f%%", pct)
end

local function parseValue(text)
	if type(text) ~= "string" then
		return nil
	end

	local cleaned = text:lower():gsub("[%s,%$_]", "")
	if cleaned == "" then
		return 0
	end

	local number, suffix = cleaned:match("^(%d*%.?%d+)(%a*)$")
	if not number then
		return nil
	end

	local base = tonumber(number)
	if not base then
		return nil
	end

	if suffix == "" then
		return base
	end

	local multiplier = PARSE_MULTIPLIERS[suffix]
	if not multiplier then
		return nil
	end

	return base * multiplier
end

local function bindCharacter(character)
	if not character then
		rootPart = nil
		return
	end
	rootPart = character:FindFirstChild("HumanoidRootPart")
end

bindCharacter(LocalPlayer.Character)

local characterConn = LocalPlayer.CharacterAdded:Connect(function(character)
	rootPart = nil
	tpState = nil

	local waiter
	waiter = character.ChildAdded:Connect(function(child)
		if child.Name == "HumanoidRootPart" then
			rootPart = child
			waiter:Disconnect()
		end
	end)

	bindCharacter(character)
	if rootPart then
		waiter:Disconnect()
	end
end)

local function getRoot()
	if rootPart and rootPart.Parent then
		return rootPart
	end
	bindCharacter(LocalPlayer.Character)
	return rootPart
end

local function getAttr(inst, name)
	local ok, value = pcall(inst.GetAttribute, inst, name)
	if ok then
		return value
	end
	return nil
end

local function crystalValue(inst)
	return tonumber(getAttr(inst, "Value")) or 0
end

local function crystalWeight(inst)
	return tonumber(getAttr(inst, "WeightKg")) or 0
end

local function crystalTier(inst)
	return tonumber(getAttr(inst, "Tier")) or 0
end

local function crystalRarity(inst)
	local name = getAttr(inst, "TierName")
	if type(name) == "string" and name ~= "" then
		return name
	end
	return TIER_NAMES[crystalTier(inst)] or "Unknown"
end

local function crystalName(inst)
	local name = getAttr(inst, "CrystalName")
	if type(name) == "string" and name ~= "" then
		return name
	end
	return inst.Name
end

local function crystalColor(inst)
	local r = tonumber(getAttr(inst, "TierColorR"))
	local g = tonumber(getAttr(inst, "TierColorG"))
	local b = tonumber(getAttr(inst, "TierColorB"))
	if r and g and b then
		return Color3.fromRGB(r, g, b)
	end
	return COLORS.default
end

local function mutationLuck(name)
	if type(name) ~= "string" or name == "" then
		return 1
	end
	return MUTATION_LUCK[name] or 1
end

local function combinedLuckMult(inst)
	local mutation = getAttr(inst, "Mutation")
	local roll = tonumber(getAttr(inst, "MutationLuckRoll"))
	local multiplier = (roll and roll > 0) and roll or mutationLuck(mutation)

	local extra = getAttr(inst, "ExtraMutations")
	if type(extra) == "string" and extra ~= "" then
		for name in string.gmatch(extra, "[^,]+") do
			if name ~= "" then
				multiplier *= mutationLuck(name)
			end
		end
	end

	if getAttr(inst, "IsBloodCrystal") == true then
		multiplier *= LUCK.blood
	end

	if getAttr(inst, "AdminMutation") == "Radioactive" and mutation ~= "Radioactive" then
		local hasRadioactive = type(extra) == "string" and extra:find("Radioactive", 1, true) ~= nil
		if not hasRadioactive then
			multiplier *= mutationLuck("Radioactive")
		end
	end

	return multiplier
end

local function computeLuck(inst)
	local tier = crystalTier(inst)
	if tier <= 0 then
		return 0
	end

	local weight = math.max(0, crystalWeight(inst))
	local base = (LUCK.rarity[tier] or LUCK.rarity[1]) * math.min(weight, LUCK.cap) ^ LUCK.exponent * LUCK.base

	if getAttr(inst, "BombCrystal") == true then
		base *= LUCK.bomb
	end

	return base * combinedLuckMult(inst)
end

local function luckLabel(inst)
	local hover = inst:FindFirstChild("CrystalHover")
	if not hover then
		return nil
	end

	local label = hover:FindFirstChild("LuckBoost")
	if not label or not label:IsA("TextLabel") then
		return nil
	end

	return label
end

local function luckLabelText(inst)
	local label = luckLabel(inst)
	if not label then
		return nil
	end
	return label.Text
end

local function crystalLuck(inst)
	local text = luckLabelText(inst)
	if type(text) == "string" then
		local pct = tonumber(text:match("([%d%.]+)%s*%%"))
		if pct and pct > 0 then
			return pct / 100
		end
	end
	return computeLuck(inst)
end

local function meetsFilter(inst, value)
	if not valueFilter then
		return true
	end

	return (value or crystalValue(inst)) >= minValue
end

local function ownsGamepass(name)
	local folder = LocalPlayer:FindFirstChild("GamepassesOwned")
	if not folder then
		return false
	end

	local flag = folder:FindFirstChild(name)
	return flag ~= nil and flag:IsA("BoolValue") and flag.Value == true
end

local function realStat(name)
	local data = LocalPlayer:FindFirstChild("PlayerData")
	local stats = data and data:FindFirstChild("RealStats")
	local entry = stats and stats:FindFirstChild(name)
	if not entry then
		return nil
	end
	return tonumber(entry.Value)
end

local function hasActiveRune(keyword)
	local data = LocalPlayer:FindFirstChild("PlayerData")
	local plot = data and data:FindFirstChild("PlotData")
	local runes = plot and plot:FindFirstChild("Runes")
	if not runes then
		return false
	end

	for _, child in ipairs(runes:GetChildren()) do
		local runeName = child:GetAttribute("RuneName")
		if type(runeName) == "string" and runeName:find(keyword, 1, true) then
			if (tonumber(child:GetAttribute("Remaining")) or 0) > 0 then
				return true
			end
		end
	end

	return false
end

local function backpackCapacity()
	if LocalPlayer:GetAttribute("InfBackpack") == true then
		return math.huge
	end

	local base = realStat("CarryWeight") or 10
	if ownsGamepass("CarryKgPlus4") then
		base *= 4
	end

	local total = base + (realStat("CarryWeightBonus") or 0)

	if hasActiveRune("Weight") then
		return total * 2
	end

	return total
end

local function backpackWeight()
	local total = 0

	local function scan(container)
		if not container then
			return
		end
		for _, child in ipairs(container:GetChildren()) do
			if child:IsA("Tool") and getAttr(child, "Tier") ~= nil then
				local kg = tonumber(getAttr(child, "WeightKg"))
				if kg then
					total += kg
				end
			end
		end
	end

	scan(LocalPlayer:FindFirstChildOfClass("Backpack"))
	scan(LocalPlayer.Character)

	return total
end

local function backpackFree()
	local capacity = backpackCapacity()
	if capacity == math.huge then
		return math.huge
	end
	return capacity - backpackWeight()
end

local function looksLikeCrystal(inst)
	if not inst:IsA("BasePart") then
		return false
	end
	return inst.Name:find("Crystal", 1, true) ~= nil
end

local crystalFlags = setmetatable({}, { __mode = "k" })

local function isCrystal(inst)
	local cached = crystalFlags[inst]
	if cached ~= nil then
		return cached
	end

	local result = false

	if inst:IsA("BasePart") and getAttr(inst, "Value") ~= nil then
		result = getAttr(inst, "CrystalName") ~= nil or inst.Name:find("Crystal", 1, true) ~= nil
	end

	crystalFlags[inst] = result

	return result
end

local containerList = {}
local containerClock = 0

local function rebuildContainers()
	table.clear(containerList)

	local seen = {}

	local function push(container)
		if not container or seen[container] then
			return
		end
		seen[container] = true
		containerList[#containerList + 1] = container
	end

	push(Workspace)

	for _, name in ipairs(CONTAINER_NAMES) do
		push(Workspace:FindFirstChild(name))
	end

	local things = Workspace:FindFirstChild("Things")
	if things then
		for _, name in ipairs(CONTAINER_NAMES) do
			push(things:FindFirstChild(name))
		end
	end
end

local function eachContainer(fn)
	local now = os.clock()
	local stale = #containerList == 0 or now - containerClock >= 1

	if not stale then
		for _, container in ipairs(containerList) do
			if not container.Parent and container ~= Workspace then
				stale = true
				break
			end
		end
	end

	if stale then
		containerClock = now
		rebuildContainers()
	end

	for _, container in ipairs(containerList) do
		fn(container)
	end
end

local function newLabel(name, parent, order, total, color, rich, maxText)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Size = UDim2.new(1, 0, 1 / total, 0)
	label.Position = UDim2.new(0, 0, order / total, 0)
	label.Font = ESP.font
	label.TextScaled = true
	label.TextTransparency = 0
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = COLORS.stroke
	label.TextColor3 = color
	label.RichText = rich == true
	label.Text = ""
	label.Parent = parent

	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MaxTextSize = maxText
	constraint.Parent = label

	return label, constraint
end

local function crystalGuiSize()
	return UDim2.fromOffset(ESP.width * espScale, ESP.height * espScale)
end

local function crystalTextSize()
	return math.max(6, math.floor(ESP.text * espScale + 0.5))
end

local function playerGuiSize()
	return UDim2.fromOffset(PLAYER.width * playerScale, PLAYER.height * playerScale)
end

local function playerTextSize()
	return math.max(6, math.floor(PLAYER.text * playerScale + 0.5))
end

local function createEntry(inst)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "UniverseEsp"
	billboard.Adornee = inst
	billboard.AlwaysOnTop = true
	billboard.ResetOnSpawn = false
	billboard.LightInfluence = 0
	billboard.Size = crystalGuiSize()
	billboard.StudsOffsetWorldSpace = ESP.offset
	billboard.MaxDistance = math.huge
	billboard.Parent = EspHolder

	local textSize = crystalTextSize()
	local rarity, rarityConstraint = newLabel("Rarity", billboard, 0, 3, COLORS.default, false, textSize)
	local info, infoConstraint = newLabel("Info", billboard, 1, 3, COLORS.money, false, textSize)
	local extra, extraConstraint = newLabel("Extra", billboard, 2, 3, COLORS.extra, true, textSize)

	return {
		gui = billboard,
		rarity = rarity,
		info = info,
		extra = extra,
		constraints = { rarityConstraint, infoConstraint, extraConstraint },
		signature = false,
		luckText = "+0%",
		distanceText = false,
	}
end

local function destroyEntry(inst, entry)
	entry = entry or espCache[inst]
	if not entry then
		return
	end

	if entry.gui then
		entry.gui:Destroy()
	end

	espCache[inst] = nil
	espCount -= 1
	statsDirty = true
end

local function applyEspScale()
	local size = crystalGuiSize()
	local textSize = crystalTextSize()

	for _, entry in pairs(espCache) do
		if entry.gui then
			entry.gui.Size = size
		end
		for _, constraint in ipairs(entry.constraints) do
			constraint.MaxTextSize = textSize
		end
	end
end

local function applyPlayerScale()
	local size = playerGuiSize()
	local textSize = playerTextSize()

	for _, entry in pairs(playerCache) do
		if entry.gui then
			entry.gui.Size = size
		end
		for _, constraint in ipairs(entry.constraints) do
			constraint.MaxTextSize = textSize
		end
	end
end

local function applyExtra(entry, distanceText)
	entry.distanceText = distanceText
	entry.extra.Text = string.format(
		'<font color="#%s">%s</font>  \u{2022}  <font color="#%s">%s</font>',
		COLORS.hexDistance,
		distanceText,
		COLORS.hexLuck,
		entry.luckText
	)
end

local function buildTitle(inst)
	local rarity = crystalRarity(inst)
	local name = crystalName(inst)
	local mutation = getAttr(inst, "Mutation")

	if type(mutation) == "string" and mutation ~= "" then
		return string.format("[%s] %s (%s)", rarity, name, mutation)
	end
	return string.format("[%s] %s", rarity, name)
end

local function applyDetails(inst, entry, origin)
	local title = buildTitle(inst)
	local color = crystalColor(inst)
	local money = formatShort(crystalValue(inst), "$")
	local weight = formatWeight(crystalWeight(inst))

	local luckOk, luck = pcall(crystalLuck, inst)
	entry.luckText = formatLuck(luckOk and luck or 0)

	entry.rarity.Text = title
	entry.rarity.TextColor3 = color
	entry.info.Text = string.format("%s  \u{2022}  %s", money, weight)

	local distanceText = "--"
	if origin then
		distanceText = formatDistance((inst.Position - origin).Magnitude)
	end

	applyExtra(entry, distanceText)
end

local function crystalSignature(inst)
	return table.concat({
		tostring(getAttr(inst, "Tier")),
		tostring(getAttr(inst, "TierName")),
		tostring(getAttr(inst, "CrystalName")),
		tostring(getAttr(inst, "Value")),
		tostring(getAttr(inst, "WeightKg")),
		tostring(getAttr(inst, "Mutation")),
		tostring(getAttr(inst, "ExtraMutations")),
		tostring(luckLabelText(inst)),
	}, "|")
end

local function markDirty(inst)
	dirty[inst] = true
end

local function untrackCrystal(inst)
	local conns = registry[inst]
	if not conns then
		return
	end

	for _, connection in ipairs(conns) do
		connection:Disconnect()
	end

	registry[inst] = nil
	registryCount -= 1
	dirty[inst] = nil
	candidates[inst] = nil
	statsDirty = true

	destroyEntry(inst)
end

local function trackCrystal(inst)
	if registry[inst] then
		return
	end

	local conns = {}
	registry[inst] = conns
	registryCount += 1
	statsDirty = true

	local ok = pcall(function()
		conns[#conns + 1] = inst.Destroying:Connect(function()
			untrackCrystal(inst)
		end)

		conns[#conns + 1] = inst.AncestryChanged:Connect(function()
			if not inst:IsDescendantOf(Workspace) then
				untrackCrystal(inst)
			end
		end)

		for _, name in ipairs(WATCHED_ATTRIBUTES) do
			conns[#conns + 1] = inst:GetAttributeChangedSignal(name):Connect(function()
				markDirty(inst)
			end)
		end

		local label = luckLabel(inst)
		if label then
			conns[#conns + 1] = label:GetPropertyChangedSignal("Text"):Connect(function()
				markDirty(inst)
			end)
		end
	end)

	if not ok then
		untrackCrystal(inst)
		return
	end

	markDirty(inst)
end

local function syncCrystal(inst)
	dirty[inst] = nil

	if not registry[inst] then
		return
	end

	if not inst.Parent then
		untrackCrystal(inst)
		return
	end

	local entry = espCache[inst]
	local hidden = not espActive or getAttr(inst, "Collected") == true

	if not hidden then
		hidden = not meetsFilter(inst)
	end

	if hidden then
		if entry then
			destroyEntry(inst, entry)
		end
		return
	end

	if not entry then
		local built, result = pcall(createEntry, inst)
		if not built then
			reportError("billboard", result)
			return
		end

		entry = result
		espCache[inst] = entry
		espCount += 1
		statsDirty = true
	end

	local signature = crystalSignature(inst)
	if signature == entry.signature then
		return
	end

	local root = getRoot()
	local ok, err = pcall(applyDetails, inst, entry, root and root.Position or nil)
	if ok then
		entry.signature = signature
	else
		reportError("details", err)
	end
end

local sweepSeen = {}

local function sweep()
	local seen = sweepSeen
	table.clear(seen)

	eachContainer(function(container)
		for _, child in ipairs(container:GetChildren()) do
			if not seen[child] and isCrystal(child) then
				seen[child] = true
				if not registry[child] then
					trackCrystal(child)
				end
			end
		end
	end)

	local stale
	for inst in pairs(registry) do
		if not seen[inst] then
			stale = stale or {}
			stale[#stale + 1] = inst
		end
	end

	if stale then
		for _, inst in ipairs(stale) do
			untrackCrystal(inst)
		end
	end
end

local lastDistanceOrigin

local function updateDistances()
	local root = getRoot()
	if not root then
		return
	end

	local origin = root.Position

	if lastDistanceOrigin and (origin - lastDistanceOrigin).Magnitude < 1 then
		return
	end

	lastDistanceOrigin = origin

	for inst, entry in pairs(espCache) do
		if inst.Parent then
			local text = formatDistance((inst.Position - origin).Magnitude)
			if text ~= entry.distanceText then
				applyExtra(entry, text)
			end
		end
	end
end

local function clearEsp()
	for inst, entry in pairs(espCache) do
		destroyEntry(inst, entry)
	end
	espCache = {}
	espCount = 0
	statsDirty = true
end

local function clearRegistry()
	local all
	for inst in pairs(registry) do
		all = all or {}
		all[#all + 1] = inst
	end

	if all then
		for _, inst in ipairs(all) do
			untrackCrystal(inst)
		end
	end

	clearEsp()

	registry = {}
	candidates = {}
	dirty = {}
	registryCount = 0
	statsDirty = true
end

local function requestRefresh()
	for inst in pairs(registry) do
		dirty[inst] = true
	end
	sweepAccumulator = math.huge
end

local function trackingEnabled()
	return espActive
end

local function onContainerChild(child)
	if looksLikeCrystal(child) then
		candidates[child] = os.clock() + ESP.ttl
	end
end

local function watchContainers()
	for container, connection in pairs(containerConns) do
		if not container:IsDescendantOf(game) then
			connection:Disconnect()
			containerConns[container] = nil
		end
	end

	eachContainer(function(container)
		if containerConns[container] then
			return
		end
		containerConns[container] = container.ChildAdded:Connect(onContainerChild)
	end)
end

local function unwatchContainers()
	for container, connection in pairs(containerConns) do
		connection:Disconnect()
		containerConns[container] = nil
	end
end

local function updateTracking()
	if trackingEnabled() then
		sweepAccumulator = math.huge
		watchContainers()
		requestRefresh()
	else
		unwatchContainers()
		clearRegistry()
	end
end

local StatsLabel

local espConn = RunService.Heartbeat:Connect(function(deltaTime)
	if statsDirty and StatsLabel then
		statsDirty = false
		StatsLabel:SetText(string.format("Tracking: %d  |  Shown: %d", registryCount, espCount))
	end

	if not trackingEnabled() then
		return
	end

	local now = os.clock()

	for inst, expiry in pairs(candidates) do
		if not inst.Parent then
			candidates[inst] = nil
		elseif isCrystal(inst) then
			candidates[inst] = nil
			trackCrystal(inst)
		elseif now > expiry then
			candidates[inst] = nil
		end
	end

	local deadline = now + ESP.budget
	if next(dirty) ~= nil then
		for inst in pairs(dirty) do
			local ok, err = pcall(syncCrystal, inst)
			if not ok then
				dirty[inst] = nil
				reportError("sync", err)
			end
			if os.clock() > deadline then
				break
			end
		end
	end

	sweepAccumulator += deltaTime
	if sweepAccumulator >= ESP.sweep then
		sweepAccumulator = 0
		local ok, err = pcall(function()
			watchContainers()
			sweep()
		end)
		if not ok then
			reportError("sweep", err)
		end
	end

	distanceAccumulator += deltaTime
	if distanceAccumulator >= PACE.distance then
		distanceAccumulator = 0
		local ok, err = pcall(updateDistances)
		if not ok then
			reportError("distance", err)
		end
	end
end)

local function destroyPlayerEntry(player)
	local entry = playerCache[player]
	if not entry then
		return
	end

	if entry.gui then
		entry.gui:Destroy()
	end

	playerCache[player] = nil
end

local function createPlayerEntry(player)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "UniversePlayerEsp"
	billboard.AlwaysOnTop = true
	billboard.ResetOnSpawn = false
	billboard.LightInfluence = 0
	billboard.Size = playerGuiSize()
	billboard.StudsOffsetWorldSpace = PLAYER.offset
	billboard.MaxDistance = math.huge
	billboard.Parent = EspHolder

	local textSize = playerTextSize()
	local nameLabel, nameConstraint = newLabel("Name", billboard, 0, 2, COLORS.player, false, textSize)
	local distanceLabel, distanceConstraint = newLabel("Distance", billboard, 1, 2, COLORS.extra, false, textSize)

	nameLabel.Text = player.DisplayName

	return {
		gui = billboard,
		name = nameLabel,
		distance = distanceLabel,
		constraints = { nameConstraint, distanceConstraint },
		nameText = player.DisplayName,
		distanceText = false,
	}
end

local function clearPlayerEsp()
	for player in pairs(playerCache) do
		destroyPlayerEntry(player)
	end
	playerCache = {}
end

local function updatePlayerEsp()
	if not playerEspActive then
		return
	end

	local root = getRoot()
	local origin = root and root.Position or nil

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local character = player.Character
			local target = character and character:FindFirstChild("HumanoidRootPart")

			if target then
				local entry = playerCache[player]
				if not entry then
					local built, result = pcall(createPlayerEntry, player)
					if built then
						entry = result
						playerCache[player] = entry
					else
						reportError("player", result)
					end
				end

				if entry then
					if entry.gui.Adornee ~= target then
						entry.gui.Adornee = target
					end

					if entry.nameText ~= player.DisplayName then
						entry.nameText = player.DisplayName
						entry.name.Text = player.DisplayName
					end

					local text = origin and formatDistance((target.Position - origin).Magnitude) or "--"
					if text ~= entry.distanceText then
						entry.distanceText = text
						entry.distance.Text = text
					end
				end
			else
				destroyPlayerEntry(player)
			end
		end
	end

	local gone
	for player in pairs(playerCache) do
		if player == LocalPlayer or not player.Parent then
			gone = gone or {}
			gone[#gone + 1] = player
		end
	end

	if gone then
		for _, player in ipairs(gone) do
			destroyPlayerEntry(player)
		end
	end
end

local streamMark = 0
local streamSpot

local function requestStream(position)
	if typeof(position) ~= "Vector3" then
		return
	end

	local now = os.clock()

	if streamSpot and now - streamMark < 0.3 and (streamSpot - position).Magnitude < 32 then
		return
	end

	streamMark = now
	streamSpot = position

	task.spawn(function()
		pcall(function()
			LocalPlayer:RequestStreamAroundAsync(position, 1)
		end)
	end)
end

local function applyPivot(cframe)
	local character = LocalPlayer.Character
	if not character then
		return false
	end

	requestStream(cframe.Position)

	local root = getRoot()
	if not root then
		return false
	end

	local moved = pcall(function()
		character:PivotTo(cframe)
	end)

	if not moved then
		moved = pcall(function()
			root.CFrame = cframe
		end)
	end

	if not moved then
		return false
	end

	pcall(function()
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end)

	return true
end

local function findClearGoal(position, ignore)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	params.MaxParts = 1

	for _, offset in ipairs(TP.clear) do
		local candidate = position + offset
		local ok, hits = pcall(function()
			return Workspace:GetPartBoundsInRadius(candidate, 2.5, params)
		end)

		if ok and #hits == 0 then
			return candidate
		end
	end

	return position + TP.clear[#TP.clear]
end

local function finishTeleport()
	if not tpState then
		return
	end

	local root = getRoot()
	if root then
		pcall(function()
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end)
	end

	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		pcall(function()
			humanoid.PlatformStand = false
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
			humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end)
	end

	tpState = nil
end

local function teleportTo(target)
	local position
	if typeof(target) == "Vector3" then
		position = target
	elseif typeof(target) == "Instance" and target.Parent then
		position = target.Position
	end

	if not position then
		return false
	end

	local character = LocalPlayer.Character
	if not character then
		return false
	end

	local root = getRoot()
	if not root then
		return false
	end

	finishTeleport()

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		pcall(function()
			if humanoid.SeatPart or humanoid.Sit then
				humanoid.Sit = false
			end
			humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
		end)
	end

	local ignore = { character }
	if typeof(target) == "Instance" then
		ignore[#ignore + 1] = target
	end

	local goalFrame = CFrame.new(findClearGoal(position + TP.offset, ignore))

	if not applyPivot(goalFrame) then
		return false
	end

	tpState = {
		goal = goalFrame,
		holdUntil = os.clock() + TP.hold,
	}

	return true
end

local pendingActions = {}
local promptRestores = {}
local claimed = {}

local function schedule(delay, fn)
	pendingActions[#pendingActions + 1] = { at = os.clock() + delay, fn = fn }
end

local promptCache = setmetatable({}, { __mode = "k" })

local function crystalPrompt(inst)
	local cached = promptCache[inst]
	if cached and cached.Parent then
		return cached
	end

	local ok, prompt = pcall(inst.FindFirstChildOfClass, inst, "ProximityPrompt")

	if not (ok and prompt) then
		ok, prompt = pcall(inst.FindFirstChildWhichIsA, inst, "ProximityPrompt", true)
	end

	if ok and prompt then
		promptCache[inst] = prompt
		return prompt
	end

	promptCache[inst] = nil

	return nil
end

local function surfaceDistance(part, origin)
	local ok, distance = pcall(function()
		local point = part.CFrame:PointToObjectSpace(origin)
		local half = part.Size * 0.5
		local clamped = Vector3.new(
			math.clamp(point.X, -half.X, half.X),
			math.clamp(point.Y, -half.Y, half.Y),
			math.clamp(point.Z, -half.Z, half.Z)
		)
		return (point - clamped).Magnitude
	end)

	if ok and distance then
		return distance
	end

	return (part.Position - origin).Magnitude
end

local function firePrompt(prompt)
	if not promptRestores[prompt] then
		promptRestores[prompt] = {
			hold = prompt.HoldDuration,
			sight = prompt.RequiresLineOfSight,
			enabled = prompt.Enabled,
			range = prompt.MaxActivationDistance,
		}
	end

	pcall(function()
		prompt.HoldDuration = 0
		prompt.RequiresLineOfSight = false
		prompt.Enabled = true
		prompt.MaxActivationDistance = 1000
	end)

	local fired = false

	if typeof(fireproximityprompt) == "function" then
		fired = pcall(fireproximityprompt, prompt, 1)
		if not fired then
			fired = pcall(fireproximityprompt, prompt)
		end
	end

	if not fired then
		fired = pcall(function()
			prompt:InputHoldBegin()
			prompt:InputHoldEnd()
		end)
	end

	schedule(PICK.restore, function()
		local saved = promptRestores[prompt]
		if not saved then
			return
		end

		promptRestores[prompt] = nil

		if prompt.Parent then
			prompt.HoldDuration = saved.hold
			prompt.RequiresLineOfSight = saved.sight
			prompt.Enabled = saved.enabled
			prompt.MaxActivationDistance = saved.range
		end
	end)

	return fired
end

local pickupParams = OverlapParams.new()
pickupParams.FilterType = Enum.RaycastFilterType.Exclude

pcall(function()
	pickupParams.MaxParts = 300
	pickupParams.RespectCanCollide = false
end)

local pickupFound = {}
local pickupSeen = {}

local function pickupCandidates(free, origin)
	local found = pickupFound
	local seen = pickupSeen
	table.clear(found)
	table.clear(seen)
	local now = os.clock()

	local function consider(child)
		if not child or seen[child] then
			return
		end
		seen[child] = true

		if not child.Parent or not isCrystal(child) or getAttr(child, "Collected") == true then
			return
		end

		local claim = claimed[child]
		if claim and now - claim < PICK.retry then
			return
		end

		local value = crystalValue(child)
		if not meetsFilter(child, value) then
			return
		end

		local weight = crystalWeight(child)
		if weight > free then
			return
		end

		local distance = surfaceDistance(child, origin)
		if distance > PICK.range then
			return
		end

		found[#found + 1] = {
			inst = child,
			prompt = crystalPrompt(child),
			value = value,
			weight = weight,
			distance = distance,
		}
	end

	pickupParams.FilterDescendantsInstances = { LocalPlayer.Character or LocalPlayer }

	local ok, hits = pcall(function()
		return Workspace:GetPartBoundsInRadius(origin, PICK.range + PICK.pad, pickupParams)
	end)

	if ok and hits then
		for _, part in ipairs(hits) do
			consider(part)
		end
	end

	eachContainer(function(container)
		for _, child in ipairs(container:GetChildren()) do
			if child:IsA("BasePart") then
				consider(child)
			elseif child:IsA("Model") then
				for _, inner in ipairs(child:GetChildren()) do
					consider(inner)
				end
			end
		end
	end)

	for inst in pairs(registry) do
		consider(inst)
	end

	table.sort(found, function(a, b)
		if a.value == b.value then
			return a.distance < b.distance
		end
		return a.value > b.value
	end)

	return found
end

local function grabCrystal(inst, prompt)
	local sent = false

	if HoldComplete then
		sent = pcall(function()
			HoldComplete:FireServer(inst)
		end)
	end

	if not prompt then
		prompt = crystalPrompt(inst)
	end

	if prompt and prompt.Parent and firePrompt(prompt) then
		sent = true
	end

	if not sent and typeof(fireclickdetector) == "function" then
		local ok, detector = pcall(inst.FindFirstChildWhichIsA, inst, "ClickDetector", true)
		if ok and detector then
			sent = pcall(fireclickdetector, detector, 0)
		end
	end

	return sent
end

local function instantPromptPatch(prompt)
	if instantPatched[prompt] or promptRestores[prompt] then
		return
	end

	instantPatched[prompt] = {
		hold = prompt.HoldDuration,
		sight = prompt.RequiresLineOfSight,
		enabled = prompt.Enabled,
	}

	pcall(function()
		prompt.HoldDuration = 0
		prompt.RequiresLineOfSight = false
		prompt.Enabled = true
	end)
end

local function restoreInstantPrompts()
	for prompt, saved in pairs(instantPatched) do
		if prompt.Parent then
			pcall(function()
				prompt.HoldDuration = saved.hold
				prompt.RequiresLineOfSight = saved.sight
				prompt.Enabled = saved.enabled
			end)
		end
	end

	table.clear(instantPatched)
end

local function nearbyCrystalParts(origin, radius)
	pickupParams.FilterDescendantsInstances = { LocalPlayer.Character or LocalPlayer }

	local ok, hits = pcall(function()
		return Workspace:GetPartBoundsInRadius(origin, radius, pickupParams)
	end)

	if ok and hits then
		return hits
	end

	return nil
end

local function refreshInstantPrompts()
	local root = getRoot()
	if not root then
		return
	end

	for prompt in pairs(instantPatched) do
		if not prompt.Parent then
			instantPatched[prompt] = nil
		end
	end

	local hits = nearbyCrystalParts(root.Position, PICK.instantRadius)
	if not hits then
		return
	end

	for _, part in ipairs(hits) do
		if isCrystal(part) and getAttr(part, "Collected") ~= true then
			local prompt = crystalPrompt(part)
			if prompt then
				instantPromptPatch(prompt)
			end
		end
	end
end

local function setInstantPrompt(value)
	instantPromptActive = value
	instantAccumulator = math.huge

	if not value then
		restoreInstantPrompts()
	end
end

local function instantGrab()
	if not instantPromptActive then
		return
	end

	local root = getRoot()
	if not root then
		return
	end

	local hits = nearbyCrystalParts(root.Position, PICK.range + PICK.pad)
	if not hits then
		return
	end

	local best, bestPrompt, bestDistance

	for _, part in ipairs(hits) do
		if part.Parent and isCrystal(part) and getAttr(part, "Collected") ~= true then
			local distance = surfaceDistance(part, root.Position)
			if distance <= PICK.range and (not best or distance < bestDistance) then
				best = part
				bestPrompt = crystalPrompt(part)
				bestDistance = distance
			end
		end
	end

	if not best then
		return
	end

	if bestPrompt me then
		instantPromptPatch(bestPrompt)
	end

	if grabCrystal(best, bestPrompt) then
		claimed[best] = os.clock()
	end
end

local function pickupStep()
	local now = os.clock()
	if now - lastPickup < PICK.cooldown then
		return
	end

	local root = getRoot()
	if not root then
		return
	end

	local free = backpackFree()
	if free <= 0 then
		if now - lastBagWarn >= 8 then
			lastBagWarn = now
			Library:Notify("Backpack full", 2)
		end
		return
	end

	for inst, stamp in pairs(claimed) do
		if now - stamp >= PICK.forget or not inst.Parent then
			claimed[inst] = nil
		end
	end

	local candidates = pickupCandidates(free, root.Position)
	if #candidates == 0 then
		requestStream(root.Position)
		return
	end

	local budget = free
	local grabs = 0

	for _, entry in ipairs(candidates) do
		if grabs >= PICK.burst then
			break
		end

		if entry.weight <= budget then
			claimed[entry.inst] = now

			if grabCrystal(entry.inst, entry.prompt) then
				budget -= entry.weight
				grabs += 1
			end
		end
	end

	if grabs > 0 then
		lastPickup = now
	end
end

local BackpackLabel

local function updateBackpackLabel()
	if not BackpackLabel then
		return
	end

	local capacity = backpackCapacity()
	local used = backpackWeight()

	if capacity == math.huge then
		BackpackLabel:SetText(string.format("Bag %.1f / \u{221E} kg", used))
		return
	end

	local free = math.max(0, capacity - used)
	BackpackLabel:SetText(string.format("Bag %.1f / %.1f kg\nFree %.1f kg", used, capacity, free))
end

-- Funciones actualizadas de speedboost
nulltime.setSpeedBoost = function(enabled, speed)
	nulltime.SpeedBoostEnabled = enabled
	if speed then
		nulltime.SpeedValue = speed
	end
end

local function autoFarmCrystals()
	if not autoFarmCrystalActive then
		return
	end

	local root = getRoot()
	if not root then
		return
	end

	if backpackFree() <= 0 then
		return
	end

	for inst in pairs(registry) do
		if inst and inst.Parent and isCrystal(inst) and getAttr(inst, "Collected") ~= true then
			if meetsFilter(inst) then
				teleportTo(inst)
				grabCrystal(inst, crystalPrompt(inst))
				task.wait(0.1)
			end
		end
	end
end

local schedulerConn = RunService.Heartbeat:Connect(function(deltaTime)
	if tpState then
		local ok, err = pcall(function()
			if not applyPivot(tpState.goal) then
				finishTeleport()
				return
			end

			if os.clock() >= tpState.holdUntil then
				finishTeleport()
			end
		end)

		if not ok then
			finishTeleport()
			reportError("teleport", err)
		end
	end

	if autoPickupActive then
		local ok, err = pcall(pickupStep)
		if not ok then
			reportError("pickup", err)
		end
	end

	if autoFarmCrystalActive then
		pcall(autoFarmCrystals)
	end

	if instantPromptActive then
		instantAccumulator += deltaTime
		if instantAccumulator >= PICK.instantTick then
			instantAccumulator = 0
			local ok, err = pcall(refreshInstantPrompts)
			if not ok then
				reportError("instant", err)
			end
		end
	end

	-- Lógica de Speedboost de nulltime
	if nulltime.SpeedBoostEnabled then
		local char = LocalPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = nulltime.SpeedValue
		end
	end

	-- Lógica de Fly de nulltime
	if nulltime.FlyEnabled then
		local root = getRoot()
		local camera = Workspace.CurrentCamera
		if root and camera then
			if not flyBodyVelocity then
				flyBodyVelocity = Instance.new("BodyVelocity")
				flyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
				flyBodyVelocity.Parent = root
			end

			if not flyBodyGyro then
				flyBodyGyro = Instance.new("BodyGyro")
				flyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
				flyBodyGyro.P = 9e4
				flyBodyGyro.Parent = root
			end

			local moveDir = Vector3.zero
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += camera.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= camera.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += camera.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= camera.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.yAxis end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir -= Vector3.yAxis end

			if moveDir.Magnitude > 0 then
				flyBodyVelocity.Velocity = moveDir.Unit * nulltime.FlySpeed
			else
				flyBodyVelocity.Velocity = Vector3.zero
			end
			flyBodyGyro.CFrame = camera.CFrame
		end
	else
		if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
		if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
	end

	if playerEspActive then
		local ok, err = pcall(updatePlayerEsp)
		if not ok then
			reportError("playerEsp", err)
		end
	end

	statsAccumulator += deltaTime
	if statsAccumulator >= PACE.stats then
		statsAccumulator = 0
		local ok, err = pcall(updateBackpackLabel)
		if not ok then
			reportError("backpack", err)
		end
	end

	if #pendingActions == 0 then
		return
	end

	local now = os.clock()
	for index = #pendingActions, 1, -1 do
		local job = pendingActions[index]
		if now >= job.at then
			table.remove(pendingActions, index)
			local ok, err = pcall(job.fn)
			if not ok then
				reportError("action", err)
			end
		end
	end
end)

local function sortedByScore(scoreFn)
	local scored = {}
	local seen = {}

	local function consider(inst)
		if seen[inst] or not inst.Parent then
			return
		end

		if getAttr(inst, "Collected") == true then
			return
		end

		seen[inst] = true

		local ok, score = pcall(scoreFn, inst)
		scored[#scored + 1] = { inst = inst, score = ok and score or 0 }
	end

	for inst in pairs(registry) do
		consider(inst)
	end

	eachContainer(function(container)
		for _, child in ipairs(container:GetChildren()) do
			if isCrystal(child) then
				consider(child)
			end
		end
	end)

	table.sort(scored, function(a, b)
		return a.score > b.score
	end)

	return scored
end

local Mountain = {}
local mountainConn

local aimParams = RaycastParams.new()
aimParams.FilterType = Enum.RaycastFilterType.Exclude
aimParams.IgnoreWater = true

local function getAimedCrystal()
	local unitRay = Mouse.UnitRay
	local origin = unitRay.Origin
	local direction = unitRay.Direction.Unit

	local character = LocalPlayer.Character
	aimParams.FilterDescendantsInstances = character and { character } or {}

	local hit = Workspace:Raycast(origin, direction * PICK.aimRange, aimParams)
	if hit and hit.Instance and (registry[hit.Instance] or isCrystal(hit.Instance)) then
		return hit.Instance
	end

	local best, bestDot
	local seen = {}

	local function consider(inst)
		if seen[inst] or not inst.Parent then
			return
		end

		seen[inst] = true

		local offset = (inst.Position + ESP.offset) - origin
		local magnitude = offset.Magnitude
		if magnitude > 0 then
			local dot = direction:Dot(offset / magnitude)
			if not bestDot or dot > bestDot then
				bestDot = dot
				best = inst
			end
		end
	end

	for inst in pairs(espCache) do
		consider(inst)
	end

	eachContainer(function(container)
		for _, child in ipairs(container:GetChildren()) do
			if isCrystal(child) then
				consider(child)
			end
		end
	end)

	if best and bestDot and bestDot >= PICK.aimDot then
		return best
	end
	return nil
end

local function aimTeleport()
	if not espActive then
		Library:Notify("Enable Crystal ESP first", 3)
		return
	end

	local inst = getAimedCrystal()
	if not inst then
		Library:Notify("No crystal aimed", 2)
		return
	end

	if teleportTo(inst) then
		Library:Notify(string.format("TP -> %s", crystalName(inst)), 2)
	else
		Library:Notify("Teleport failed", 2)
	end
end

local function tpToRank(scoreFn, rank, formatter)
	local entry = sortedByScore(scoreFn)[rank]
	if not entry or entry.score <= 0 then
		Library:Notify(string.format("No crystal for #%d", rank), 3)
		return
	end

	if teleportTo(entry.inst) then
		Library:Notify(string.format("TP #%d %s (%s)", rank, crystalName(entry.inst), formatter(entry.inst, entry.score)), 3)
	else
		Library:Notify("Teleport failed", 3)
	end
end

local function fireRemote(remote, ...)
	if not remote then
		return false
	end

	local args = table.pack(...)
	local ok = pcall(function()
		remote:FireServer(table.unpack(args, 1, args.n))
	end)

	return ok
end

local function unfavoriteAll()
	local cleared = 0

	local function scan(container)
		if not container then
			return
		end

		for _, child in ipairs(container:GetChildren()) do
			if child:IsA("Tool") and child:GetAttribute("Favorited") == true then
				pcall(function()
					child:SetAttribute("Favorited", false)
				end)
				fireRemote(ToggleFavorite, child, false)
				cleared += 1
			end
		end
	end

	scan(LocalPlayer:FindFirstChildOfClass("Backpack"))
	scan(LocalPlayer.Character)

	return cleared
end

local sellClock = 0

local function doSell()
	local now = os.clock()
	if now - sellClock < 1.5 then
		return false
	end

	sellClock = now

	unfavoriteAll()
	fireRemote(GoHome, "sell")

	schedule(0.6, function()
		unfavoriteAll()
		fireRemote(SellRequest, "all")
	end)

	return true
end

do
	local function install()
		local BOULDER_INFO = {
			Mossite = {
				rarity = "Common",
				pickaxe = "Titanium Spike",
				crystals = "8-11",
				runes = "Luck / Haste",
				color = Color3.fromRGB(150, 220, 120),
			},
			Voltite = {
				rarity = "Uncommon",
				pickaxe = "Celestial Apex",
				crystals = "10-14",
				runes = "Storm / Weight",
				color = Color3.fromRGB(110, 190, 240),
			},
			Gildrite = {
				rarity = "Rare",
				pickaxe = "Eclipse Fang",
				crystals = "11-15",
				runes = "Fortune / Detonation",
				color = Color3.fromRGB(255, 200, 60),
			},
			Rimeveil = {
				rarity = "Epic",
				pickaxe = "Voidreign",
				crystals = "13-18",
				runes = "Preservation / Warmth",
				color = Color3.fromRGB(170, 100, 255),
			},
			Nocturnite = {
				rarity = "Legendary",
				pickaxe = "The Terminus",
				crystals = "16-22",
				runes = "Excavator / Colossus",
				color = Color3.fromRGB(255, 80, 180),
			},
		}

		local BOULDER_OFFSET = Vector3.new(0, 7, 0)
		local BOULDER_WIDTH = 300
		local BOULDER_HEIGHT = 78
		local BOULDER_STEP = 0.4

		local GRAB_RANGE = 20
		local GRAB_STEP = 0.15
		local GRAB_LIMIT = 4
		local GRAB_RETRY = 0.2

		local boulderEsp = false
		local autoGrab = false

		local boulderCache = {}
		local grabbed = {}

		local boulderClock = 0
		local grabClock = 0

		local scanParams = OverlapParams.new()
		scanParams.FilterType = Enum.RaycastFilterType.Exclude

		local function textSize()
			return math.max(6, math.floor(ESP.text * boulderScale + 0.5))
		end

		local function anchorPart(inst)
			if inst:IsA("BasePart") then
				return inst
			end
			if inst:IsA("Model") then
				return inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
			end
			return nil
		end

		local function createCard(anchor, offset, colors, width, height)
			local billboard = Instance.new("BillboardGui")
			billboard.Name = "UniverseMountainEsp"
			billboard.Adornee = anchor
			billboard.AlwaysOnTop = true
			billboard.ResetOnSpawn = false
			billboard.LightInfluence = 0
			billboard.Size = UDim2.fromOffset(width * boulderScale, height * boulderScale)
			billboard.StudsOffsetWorldSpace = offset
			billboard.MaxDistance = math.huge
			billboard.Parent = EspHolder

			local total = #colors
			local size = textSize()
			local labels = {}
			local constraints = {}

			for index, color in ipairs(colors) do
				local label, constraint = newLabel("Line" .. index, billboard, index - 1, total, color, false, size)
				labels[index] = label
				constraints[index] = constraint
			end

			return {
				gui = billboard,
				labels = labels,
				constraints = constraints,
				width = width,
				height = height,
				text = {},
			}
		end

		local function scaleCard(entry)
			entry.gui.Size = UDim2.fromOffset(entry.width * boulderScale, entry.height * boulderScale)

			local size = textSize()
			for _, constraint in ipairs(entry.constraints) do
				constraint.MaxTextSize = size
			end
		end

		local function setLine(entry, index, text)
			if entry.text[index] == text then
				return
			end
			entry.text[index] = text
			entry.labels[index].Text = text
		end

		local function dropCard(cache, key)
			local entry = cache[key]
			if not entry then
				return
			end

			if entry.gui then
				entry.gui:Destroy()
			end
			cache[key] = nil
		end

		local function clearCache(cache)
			for key in pairs(cache) do
				dropCard(cache, key)
			end
		end

		local function boulderKind(inst)
			for kind in pairs(BOULDER_INFO) do
				if inst.Name:find(kind, 1, true) then
					return kind
				end
			end
			return nil
		end

		local function boulderRoots()
			local roots = {}

			local decorations = Workspace:FindFirstChild("MountainDecorations")
			local folder = decorations and decorations:FindFirstChild("Boulders")
			if folder then
				roots[#roots + 1] = folder
			end

			local test = Workspace:FindFirstChild("BoulderTest")
			if test then
				roots[#roots + 1] = test
			end

			return roots
		end

		local function eachBoulder(fn)
			for _, container in ipairs(boulderRoots()) do
				for _, child in ipairs(container:GetChildren()) do
					local kind = boulderKind(child)
					if kind then
						fn(child, kind)
					end
				end
			end
		end

		local function syncBoulders()
			local root = getRoot()
			local origin = root and root.Position or nil
			local seen = {}

			eachBoulder(function(model, kind)
				local anchor = anchorPart(model)
				if not anchor then
					return
				end

				seen[model] = true
				local info = BOULDER_INFO[kind]
				local entry = boulderCache[model]

				if entry and not entry.gui.Parent then
					dropCard(boulderCache, model)
					entry = nil
				end

				if not entry then
					entry = createCard(
						anchor,
						BOULDER_OFFSET,
						{ info.color, COLORS.extra, COLORS.money },
						BOULDER_WIDTH,
						BOULDER_HEIGHT
					)
					boulderCache[model] = entry
				end

				if entry.gui.Adornee ~= anchor then
					entry.gui.Adornee = anchor
				end

				scaleCard(entry)
				setLine(entry, 1, string.format("[%s] %s", info.rarity, kind))
				setLine(entry, 2, string.format("%s  \u{2022}  %s crystals", info.pickaxe, info.crystals))

				local distance = origin and formatDistance((anchor.Position - origin).Magnitude) or "--"
				setLine(entry, 3, string.format("%s  \u{2022}  %s", info.runes, distance))
			end)

			local stale
			for model in pairs(boulderCache) do
				if not seen[model] then
					stale = stale or {}
					stale[#stale + 1] = model
				end
			end

			if stale then
				for _, model in ipairs(stale) do
					dropCard(boulderCache, model)
				end
			end
		end

		-- Nulltime Boulder Farm
		local function boulderFarmStep()
			if not nulltime.BoulderFarmEnabled then return end

			eachBoulder(function(model, kind)
				local anchor = anchorPart(model)
				if anchor then
					teleportTo(anchor)
					task.wait(0.1)
					local prompt = crystalPrompt(model) or anchor:FindFirstChildOfClass("ProximityPrompt")
					if prompt then
						firePrompt(prompt)
					end
				end
			end)
		end

		function Mountain.setBoulderEsp(value)
			boulderEsp = value
			nulltime.BoulderESPEnabled = value
			if value then
				boulderClock = math.huge
			else
				clearCache(boulderCache)
			end
		end

		function Mountain.boulderList()
			local list = {}
			for _, kind in ipairs({ "Mossite", "Voltite", "Gildrite", "Rimeveil", "Nocturnite" }) do
				local info = BOULDER_INFO[kind]
				list[#list + 1] = string.format("%s  \u{2022}  %s", kind, info.pickaxe)
			end
			return list
		end

		function Mountain.applyScale()
			for _, entry in pairs(boulderCache) do
				scaleCard(entry)
			end
		end

		mountainConn = RunService.Heartbeat:Connect(function(deltaTime)
			if boulderEsp or nulltime.BoulderESPEnabled then
				boulderClock += deltaTime
				if boulderClock >= BOULDER_STEP then
					boulderClock = 0
					pcall(syncBoulders)
				end
			end

			if nulltime.BoulderFarmEnabled then
				pcall(boulderFarmStep)
			end
		end)
	end

	install()
end

do
	local function install()
		local CrystalBox = Tabs.crystals:AddLeftGroupbox("Crystal ESP", "gem")

		CrystalBox:AddToggle("CrystalEsp", {
			Text = "Crystal ESP",
			Default = false,
			Callback = function(value)
				espActive = value
				if not value then
					clearEsp()
				end
				updateTracking()
			end,
		})

		CrystalBox:AddSlider("EspSize", {
			Text = "Crystal Size",
			Default = 70,
			Min = 40,
			Max = 250,
			Rounding = 0,
			Suffix = "%",
			Compact = false,
			Callback = function(value)
				espScale = value / 100
				applyEspScale()
			end,
		})

		CrystalBox:AddDivider()

		CrystalBox:AddLabel("Min Value hides and skips crystals worth less than this. Example: 500k, 2m, 1.5b. Empty shows everything", true)

		local function setMinValue(text)
			local parsed = parseValue(text)
			if not parsed then
				return
			end

			minValue = math.max(parsed, 0)
			valueFilter = minValue > 0
			requestRefresh()
		end

		CrystalBox:AddInput("EspMinValue", {
			Text = "Min Value",
			Default = "2m",
			Placeholder = "2m",
			Numeric = false,
			Finished = false,
			Callback = setMinValue,
		})

		StatsLabel = CrystalBox:AddLabel("Tracking: 0  |  Shown: 0")
	end

	install()
end

do
	local function install()
		local PlayerBox = Tabs.players:AddLeftGroupbox("Player ESP", "users")

		PlayerBox:AddToggle("PlayerEsp", {
			Text = "Player ESP",
			Default = false,
			Callback = function(value)
				playerEspActive = value
				if not value then
					clearPlayerEsp()
				end
			end,
		})

		PlayerBox:AddSlider("PlayerEspSize", {
			Text = "Player Size",
			Default = 60,
			Min = 40,
			Max = 250,
			Rounding = 0,
			Suffix = "%",
			Compact = false,
			Callback = function(value)
				playerScale = value / 100
				applyPlayerScale()
			end,
		})
	end

	install()
end

do
	local function install()
		local BoulderBox = Tabs.boulders:AddLeftGroupbox("Boulder ESP & Farm", "mountain")

		BoulderBox:AddToggle("BoulderEsp", {
			Text = "Boulder ESP",
			Default = false,
			Callback = Mountain.setBoulderEsp,
		})

		BoulderBox:AddToggle("BoulderFarm", {
			Text = "Boulder Auto Farm",
			Default = false,
			Callback = function(value)
				nulltime.BoulderFarmEnabled = value
			end,
		})

		BoulderBox:AddSlider("BoulderEspSize", {
			Text = "Boulder Size",
			Default = 60,
			Min = 40,
			Max = 250,
			Rounding = 0,
			Suffix = "%",
			Compact = false,
			Callback = function(value)
				boulderScale = value / 100
				Mountain.applyScale()
			end,
		})

		BoulderBox:AddDivider()

		for _, text in ipairs(Mountain.boulderList()) do
			BoulderBox:AddLabel(text, true)
		end
	end

	install()
end

do
	local function install()
		local FarmBox = Tabs.farming:AddLeftGroupbox("Crystal Farm", "pickaxe")

		FarmBox:AddToggle("AutoFarmCrystal", {
			Text = "Auto Farm Crystals",
			Default = false,
			Callback = function(value)
				autoFarmCrystalActive = value
			end,
		})

		FarmBox:AddToggle("AutoPickup", {
			Text = "Auto Pickup",
			Default = false,
			Callback = function(value)
				autoPickupActive = value
			end,
		})

		FarmBox:AddToggle("InstantPrompt", {
			Text = "Instant Prompts",
			Default = false,
			Callback = function(value)
				setInstantPrompt(value)
			end,
		})

		BackpackLabel = FarmBox:AddLabel("Bag 0.0 / 0.0 kg")
	end

	install()
end

do
	local function install()
		local MoveBox = Tabs.movement:AddLeftGroupbox("Movement", "zap")

		MoveBox:AddToggle("SpeedBoost", {
			Text = "Speed Boost",
			Default = false,
			Callback = function(value)
				nulltime.setSpeedBoost(value, nulltime.SpeedValue)
			end,
		})

		MoveBox:AddSlider("SpeedValue", {
			Text = "Speed",
			Default = 35,
			Min = 16,
			Max = 200,
			Rounding = 0,
			Callback = function(value)
				nulltime.SpeedValue = value
			end,
		})

		MoveBox:AddDivider()

		MoveBox:AddToggle("FlyToggle", {
			Text = "Fly",
			Default = false,
			Callback = function(value)
				nulltime.FlyEnabled = value
			end,
		})

		MoveBox:AddSlider("FlySpeed", {
			Text = "Fly Speed",
			Default = 50,
			Min = 10,
			Max = 300,
			Rounding = 0,
			Callback = function(value)
				nulltime.FlySpeed = value
			end,
		})
	end

	install()
end

do
	local function install()
		local TopBox = Tabs.teleports:AddLeftGroupbox("Top Crystals", "trophy")

		local function fmtValue(_, score)
			return formatShort(score, "$")
		end

		local function fmtLuck(_, score)
			return formatLuck(score)
		end

		local function fmtWeight(inst)
			return formatWeight(crystalWeight(inst))
		end

		for rank = 1, 3 do
			TopBox:AddButton(string.format("Top %d Value", rank), function()
				tpToRank(crystalValue, rank, fmtValue)
			end)
		end

		TopBox:AddDivider()

		for rank = 1, 3 do
			TopBox:AddButton(string.format("Top %d Luck", rank), function()
				tpToRank(crystalLuck, rank, fmtLuck)
			end)
		end

		TopBox:AddDivider()

		for rank = 1, 3 do
			TopBox:AddButton(string.format("Top %d Weight", rank), function()
				tpToRank(crystalWeight, rank, fmtWeight)
			end)
		end

		local TeleportBox = Tabs.teleports:AddRightGroupbox("Teleports", "crosshair")

		TeleportBox:AddToggle("AimTeleport", {
			Text = "Aim Teleport",
			Default = false,
			Callback = function(value)
				aimTpEnabled = value
			end,
		})

		TeleportBox:AddLabel("Aim Teleport"):AddKeyPicker("AimTeleportKey", {
			Default = "F",
			NoUI = false,
			Text = "Aim Teleport",
			Mode = "Always",
		})

		TeleportBox:AddDivider()

		TeleportBox:AddButton("TP Home", function()
			if fireRemote(GoHome, "home") then
				Library:Notify("Teleporting home", 2)
			else
				Library:Notify("Remote unavailable", 2)
			end
		end)

		TeleportBox:AddButton("Sell All", function()
			if doSell() then
				Library:Notify("Selling all crystals", 2)
			end
		end)
	end

	install()
end

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "AimTeleportKey" })
ThemeManager:SetFolder("MineAMountain")
SaveManager:SetFolder("MineAMountain/main")
SaveManager:BuildConfigSection(SettingsTab)
ThemeManager:ApplyToTab(SettingsTab)

SaveManager:LoadAutoloadConfig()
