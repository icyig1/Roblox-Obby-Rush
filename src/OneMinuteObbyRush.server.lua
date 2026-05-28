local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("ObbyRushConfig"))

local DATASTORE_NAME = "OneMinuteObbyRush_PlayerData_v1"
local SAVE_RETRY_COUNT = 3

StarterPlayer.CharacterWalkSpeed = Config.WalkSpeed
StarterPlayer.CharacterJumpPower = Config.JumpPower
StarterPlayer.CharacterJumpHeight = Config.JumpHeight
pcall(function()
	StarterPlayer.CharacterUseJumpPower = true
end)
local playerStore = DataStoreService:GetDataStore(DATASTORE_NAME)
local rng = Random.new()

local worldFolder = workspace:FindFirstChild("ObbyRushWorld") or Instance.new("Folder")
worldFolder.Name = "ObbyRushWorld"
worldFolder.Parent = workspace

local storageFolder = ServerStorage:FindFirstChild("ObbyRushStorage") or Instance.new("Folder")
storageFolder.Name = "ObbyRushStorage"
storageFolder.Parent = ServerStorage

local remotesFolder = ReplicatedStorage:FindFirstChild("ObbyRushRemotes") or Instance.new("Folder")
remotesFolder.Name = "ObbyRushRemotes"
remotesFolder.Parent = ReplicatedStorage

local roundStateEvent = remotesFolder:FindFirstChild("RoundState") or Instance.new("RemoteEvent")
roundStateEvent.Name = "RoundState"
roundStateEvent.Parent = remotesFolder

local playerDataEvent = remotesFolder:FindFirstChild("PlayerData") or Instance.new("RemoteEvent")
playerDataEvent.Name = "PlayerData"
playerDataEvent.Parent = remotesFolder

local messageEvent = remotesFolder:FindFirstChild("Message") or Instance.new("RemoteEvent")
messageEvent.Name = "Message"
messageEvent.Parent = remotesFolder

local playerData = {}
local playerPasses = {}
local roundProgress = {}
local touchDebounces = {}
local currentRound = {
	id = 0,
	phase = "Loading",
	startedAt = 0,
	firstFinisher = nil,
	checkpointCFrames = {},
	startCFrame = CFrame.new(0, 8, 0),
	finishCFrame = CFrame.new(0, 8, 0),
}

local function makePart(parent, name, size, cframe, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = true
	part.CanTouch = true
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function makeTextBillboard(parent, text, sizeOffset)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.fromOffset(260, 80)
	billboard.StudsOffset = sizeOffset or Vector3.new(0, 5, 0)
	billboard.Parent = parent

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBlack
	label.Text = text
	label.TextColor3 = Color3.fromRGB(17, 24, 39)
	label.TextScaled = true
	label.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.25
	label.Parent = billboard
end

local function playerFromHit(hit)
	local character = hit and hit:FindFirstAncestorOfClass("Model")
	if not character then
		return nil
	end
	return Players:GetPlayerFromCharacter(character)
end

local function teleportCharacter(player, cframe)
	local character = player.Character
	if not character then
		return
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then
		return
	end

	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	root.CFrame = cframe * CFrame.new(0, 4, 0)
	humanoid:ChangeState(Enum.HumanoidStateType.Running)
end

local function getDefaultData()
	return {
		Coins = 0,
		Wins = 0,
		BestTime = 0,
		XP = 0,
		Level = 1,
	}
end

local function xpForNextLevel(level)
	return Config.Levels.BaseXP + ((level - 1) * Config.Levels.Scale)
end

local function syncLeaderstats(player)
	local data = playerData[player]
	if not data then
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local function setValue(name, className, value)
		local stat = leaderstats:FindFirstChild(name)
		if not stat then
			stat = Instance.new(className)
			stat.Name = name
			stat.Parent = leaderstats
		end
		stat.Value = value
	end

	setValue("Wins", "IntValue", data.Wins)
	setValue("Coins", "IntValue", data.Coins)
	setValue("Level", "IntValue", data.Level)
	setValue("Best", "IntValue", data.BestTime)
end

local function sendPlayerData(player)
	local data = playerData[player]
	if data then
		playerDataEvent:FireClient(player, data)
	end
end

local function addXP(player, amount)
	local data = playerData[player]
	if not data then
		return
	end

	data.XP += amount

	local leveled = false
	while data.XP >= xpForNextLevel(data.Level) do
		data.XP -= xpForNextLevel(data.Level)
		data.Level += 1
		data.Coins += 25
		leveled = true
	end

	if leveled then
		messageEvent:FireClient(player, "Level up! +25 bonus coins")
	end
end

local function hasPass(player, passName)
	local passes = playerPasses[player]
	return passes and passes[passName] == true
end

local function addCoins(player, amount)
	local data = playerData[player]
	if not data then
		return
	end

	local finalAmount = amount
	if hasPass(player, "DoubleCoins") then
		finalAmount *= 2
	end

	data.Coins += finalAmount
	syncLeaderstats(player)
	sendPlayerData(player)
end

local function savePlayerData(player)
	local data = playerData[player]
	if not data then
		return
	end

	for attempt = 1, SAVE_RETRY_COUNT do
		local ok, err = pcall(function()
			playerStore:SetAsync(tostring(player.UserId), data)
		end)
		if ok then
			return
		end
		warn(("Save failed for %s attempt %d: %s"):format(player.Name, attempt, tostring(err)))
		task.wait(attempt)
	end
end

local function loadPlayerData(player)
	local data = getDefaultData()

	local ok, saved = pcall(function()
		return playerStore:GetAsync(tostring(player.UserId))
	end)

	if ok and typeof(saved) == "table" then
		for key, value in pairs(data) do
			if saved[key] ~= nil then
				data[key] = saved[key]
			else
				data[key] = value
			end
		end
	elseif not ok then
		warn(("DataStore load failed for %s. Using session data."):format(player.Name))
	end

	playerData[player] = data
	syncLeaderstats(player)
	sendPlayerData(player)
end

local function refreshPasses(player)
	local passes = {
		DoubleCoins = false,
		VIPTrail = false,
		SpeedBoost = false,
	}

	for passName, passId in pairs(Config.GamePassIds) do
		if passId ~= 0 then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
			end)
			passes[passName] = ok and owns == true
		end
	end

	playerPasses[player] = passes
end

local function applyCharacterPerks(player, character)
	local humanoid = character:WaitForChild("Humanoid", 8)
	local root = character:WaitForChild("HumanoidRootPart", 8)
	if humanoid then
		pcall(function()
			humanoid.UseJumpPower = true
		end)
		humanoid.WalkSpeed = hasPass(player, "SpeedBoost") and Config.SpeedPassWalkSpeed or Config.WalkSpeed
		humanoid.JumpPower = Config.JumpPower
		humanoid.JumpHeight = Config.JumpHeight
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
	end

	if root and hasPass(player, "VIPTrail") then
		local existing = root:FindFirstChild("VIPTrail")
		if existing then
			existing:Destroy()
		end

		local a0 = Instance.new("Attachment")
		a0.Name = "TrailTop"
		a0.Position = Vector3.new(0, 1.2, 0)
		a0.Parent = root

		local a1 = Instance.new("Attachment")
		a1.Name = "TrailBottom"
		a1.Position = Vector3.new(0, -1.2, 0)
		a1.Parent = root

		local trail = Instance.new("Trail")
		trail.Name = "VIPTrail"
		trail.Attachment0 = a0
		trail.Attachment1 = a1
		trail.Lifetime = 0.5
		trail.MinLength = 0.1
		trail.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 212, 59)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(69, 170, 242)),
		})
		trail.Parent = root
	end
end

local function setupLobby()
	worldFolder:ClearAllChildren()

	local lobby = Instance.new("Folder")
	lobby.Name = "Lobby"
	lobby.Parent = worldFolder

	local base = makePart(
		lobby,
		"LobbyPlatform",
		Vector3.new(96, 3, 70),
		CFrame.new(0, 0, -92),
		Config.Colors.Lobby,
		Enum.Material.SmoothPlastic
	)
	makeTextBillboard(base, "ONE-MINUTE OBBY RUSH", Vector3.new(0, 8, 0))

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Anchored = true
	spawn.CanCollide = true
	spawn.Neutral = true
	spawn.AllowTeamChangeOnTouch = false
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.CFrame = CFrame.new(0, 3, -105)
	spawn.Color = Color3.fromRGB(46, 213, 115)
	spawn.Material = Enum.Material.Neon
	spawn.Parent = lobby

	local shopPad = makePart(
		lobby,
		"ShopPad",
		Vector3.new(16, 1, 16),
		CFrame.new(-28, 3, -88),
		Color3.fromRGB(69, 170, 242),
		Enum.Material.Neon
	)
	makeTextBillboard(shopPad, "SHOP", Vector3.new(0, 5, 0))

	local leaderboardWall = makePart(
		lobby,
		"LeaderboardWall",
		Vector3.new(36, 20, 2),
		CFrame.new(28, 12, -124),
		Color3.fromRGB(31, 41, 55),
		Enum.Material.SmoothPlastic
	)
	makeTextBillboard(leaderboardWall, "Finish rounds fast. Earn coins. Beat friends.", Vector3.new(0, 2, 0))
end

local function ensureLobbyOnly()
	setupLobby()
end

local function checkpointCFrame(index)
	return currentRound.checkpointCFrames[index] or currentRound.startCFrame
end

local function respawnAtCheckpoint(player)
	local progress = roundProgress[player]
	if not progress or not progress.inRound then
		teleportCharacter(player, CFrame.new(0, 5, -105))
		return
	end

	if progress.finished then
		teleportCharacter(player, currentRound.finishCFrame)
		return
	end

	teleportCharacter(player, checkpointCFrame(progress.checkpointIndex))
end

local function connectHazard(part)
	part.Touched:Connect(function(hit)
		local player = playerFromHit(hit)
		if not player then
			return
		end

		local now = os.clock()
		if touchDebounces[player] and now - touchDebounces[player] < 0.8 then
			return
		end
		touchDebounces[player] = now
		respawnAtCheckpoint(player)
		messageEvent:FireClient(player, "Careful! Back to your last checkpoint.")
	end)
end

local function connectCoin(part)
	local collectedByUserId = {}

	part.Touched:Connect(function(hit)
		local player = playerFromHit(hit)
		if not player or collectedByUserId[player.UserId] then
			return
		end

		collectedByUserId[player.UserId] = true
		addCoins(player, Config.Rewards.RoomCoinValue)
	end)

	task.spawn(function()
		while part.Parent do
			part.CFrame *= CFrame.Angles(0, math.rad(3), 0)
			task.wait(0.04)
		end
	end)
end

local function addRoomCoin(parent, position)
	local coin = makePart(
		parent,
		"Coin",
		Vector3.new(2.2, 2.2, 0.5),
		CFrame.new(position) * CFrame.Angles(math.rad(90), 0, 0),
		Config.Colors.Coin,
		Enum.Material.Neon
	)
	coin.Shape = Enum.PartType.Cylinder
	coin.CanCollide = false
	connectCoin(coin)
end

local function addCheckpoint(parent, index, x)
	local part = makePart(
		parent,
		"Checkpoint_" .. index,
		Vector3.new(18, 1, 18),
		CFrame.new(x, 4, 0),
		Config.Colors.Checkpoint,
		Enum.Material.Neon
	)
	makeTextBillboard(part, "ROOM " .. index, Vector3.new(0, 4, 0))
	currentRound.checkpointCFrames[index] = part.CFrame

	part.Touched:Connect(function(hit)
		local player = playerFromHit(hit)
		local progress = player and roundProgress[player]
		if not progress or not progress.inRound or progress.finished then
			return
		end

		if index > progress.checkpointIndex then
			progress.checkpointIndex = index
			progress.roomsCleared[index] = true
			addCoins(player, Config.Rewards.CheckpointCoins)
			addXP(player, Config.Rewards.CheckpointXP)
			syncLeaderstats(player)
			sendPlayerData(player)
			messageEvent:FireClient(player, "Checkpoint reached! +" .. Config.Rewards.CheckpointCoins .. " coins")
		end
	end)
end

local function addFinish(parent, x)
	local finish = makePart(
		parent,
		"FinishPad",
		Vector3.new(28, 2, 24),
		CFrame.new(x, 5, 0),
		Config.Colors.Finish,
		Enum.Material.Neon
	)
	makeTextBillboard(finish, "FINISH", Vector3.new(0, 5, 0))
	currentRound.finishCFrame = finish.CFrame

	finish.Touched:Connect(function(hit)
		local player = playerFromHit(hit)
		local progress = player and roundProgress[player]
		local data = player and playerData[player]
		if not progress or not data or not progress.inRound or progress.finished then
			return
		end

		progress.finished = true
		local finishTime = math.max(1, math.floor(os.clock() - currentRound.startedAt))
		local reward = Config.Rewards.FinishCoins

		if not currentRound.firstFinisher then
			currentRound.firstFinisher = player.UserId
			reward += Config.Rewards.FirstFinishBonus
			messageEvent:FireAllClients(player.DisplayName .. " finished first!")
		end

		data.Wins += 1
		if data.BestTime == 0 or finishTime < data.BestTime then
			data.BestTime = finishTime
			messageEvent:FireClient(player, "New best time: " .. finishTime .. "s")
		else
			messageEvent:FireClient(player, "Finished in " .. finishTime .. "s!")
		end

		addCoins(player, reward)
		addXP(player, Config.Rewards.FinishXP)
		syncLeaderstats(player)
		sendPlayerData(player)
	end)
end

local function addSideRails(parent, startX, endX)
	local railLength = endX - startX
	for _, z in ipairs({ -Config.CourseWidth / 2 - 2, Config.CourseWidth / 2 + 2 }) do
		makePart(
			parent,
			"GuideRail",
			Vector3.new(railLength, 2, 1),
			CFrame.new(startX + railLength / 2, 5, z),
			Color3.fromRGB(203, 213, 225),
			Enum.Material.SmoothPlastic
		)
	end
end

local function buildGapRoom(parent, startX)
	for i = 0, 5 do
		local x = startX + 8 + i * 10
		makePart(
			parent,
			"GapPlatform",
			Vector3.new(7, 2, 16),
			CFrame.new(x, 4, 0),
			Color3.fromRGB(69, 170, 242),
			Enum.Material.SmoothPlastic
		)
		if i % 2 == 1 then
			addRoomCoin(parent, Vector3.new(x, 7, 0))
		end
	end
end

local function buildLavaStripeRoom(parent, startX)
	makePart(
		parent,
		"StripeFloor",
		Vector3.new(62, 2, 24),
		CFrame.new(startX + 32, 4, 0),
		Color3.fromRGB(241, 245, 249),
		Enum.Material.SmoothPlastic
	)

	for i = 1, 6 do
		local hazard = makePart(
			parent,
			"LavaStripe",
			Vector3.new(3, 1.2, 25),
			CFrame.new(startX + 6 + i * 8, 5.8, 0),
			Config.Colors.Hazard,
			Enum.Material.Neon
		)
		connectHazard(hazard)
	end

	for i = 1, 4 do
		addRoomCoin(parent, Vector3.new(startX + 9 + i * 11, 8, rng:NextInteger(-8, 8)))
	end
end

local function buildBeamRoom(parent, startX)
	for i = 0, 3 do
		local z = (i % 2 == 0) and -8 or 8
		makePart(
			parent,
			"BalanceBeam",
			Vector3.new(17, 2, 4),
			CFrame.new(startX + 12 + i * 15, 5 + i * 0.4, z),
			Color3.fromRGB(56, 189, 248),
			Enum.Material.SmoothPlastic
		)
		addRoomCoin(parent, Vector3.new(startX + 12 + i * 15, 8 + i * 0.4, z))
	end
end

local function buildStepRoom(parent, startX)
	for i = 0, 7 do
		local height = 4 + i * 1.2
		makePart(
			parent,
			"RisingStep",
			Vector3.new(8, 2, 18),
			CFrame.new(startX + 6 + i * 8, height, 0),
			Color3.fromRGB(167, 139, 250),
			Enum.Material.SmoothPlastic
		)
		if i == 2 or i == 5 then
			addRoomCoin(parent, Vector3.new(startX + 6 + i * 8, height + 3, 0))
		end
	end
end

local function buildSpinnerRoom(parent, startX)
	local platform = makePart(
		parent,
		"SpinnerPlatform",
		Vector3.new(60, 2, 26),
		CFrame.new(startX + 32, 4, 0),
		Color3.fromRGB(240, 253, 244),
		Enum.Material.SmoothPlastic
	)

	local spinner = makePart(
		parent,
		"SpinnerHazard",
		Vector3.new(42, 1.4, 2),
		CFrame.new(startX + 32, 7, 0),
		Config.Colors.Hazard,
		Enum.Material.Neon
	)
	connectHazard(spinner)

	task.spawn(function()
		while spinner.Parent and platform.Parent do
			spinner.CFrame *= CFrame.Angles(0, math.rad(3), 0)
			task.wait(0.03)
		end
	end)

	for i = -1, 1 do
		addRoomCoin(parent, Vector3.new(startX + 32, 8, i * 8))
	end
end

local function buildDisappearingRoom(parent, startX)
	for i = 0, 8 do
		local tile = makePart(
			parent,
			"BlinkTile",
			Vector3.new(6, 2, 14),
			CFrame.new(startX + 5 + i * 7, 4, 0),
			Color3.fromRGB(125, 211, 252),
			Enum.Material.SmoothPlastic
		)
		addRoomCoin(parent, Vector3.new(startX + 5 + i * 7, 7, 0))

		task.spawn(function()
			task.wait((i % 3) * 0.55)
			while tile.Parent do
				tile.Transparency = 0.55
				tile.CanCollide = false
				task.wait(0.75)
				tile.Transparency = 0
				tile.CanCollide = true
				task.wait(1.45)
			end
		end)
	end
end

local function buildChoiceRoom(parent, startX)
	local safeLane = rng:NextInteger(1, 3)
	for lane = 1, 3 do
		local z = (lane - 2) * 9
		local color = lane == safeLane and Color3.fromRGB(134, 239, 172) or Color3.fromRGB(254, 202, 202)
		local lanePart = makePart(
			parent,
			"ChoiceLane",
			Vector3.new(58, 2, 7),
			CFrame.new(startX + 32, 4, z),
			color,
			Enum.Material.SmoothPlastic
		)

		if lane ~= safeLane then
			local hazard = makePart(
				parent,
				"HiddenHeat",
				Vector3.new(54, 0.7, 5),
				CFrame.new(startX + 32, 5.6, z),
				Config.Colors.Hazard,
				Enum.Material.Neon
			)
			hazard.Transparency = 0.2
			connectHazard(hazard)
		else
			addRoomCoin(parent, Vector3.new(startX + 32, 8, z))
		end

		makeTextBillboard(lanePart, lane == safeLane and "SAFE" or "HOT", Vector3.new(0, 3, 0))
	end
end

local function buildJumpPadRoom(parent, startX)
	for i = 0, 5 do
		local x = startX + 7 + i * 11
		makePart(
			parent,
			"JumpPlatform",
			Vector3.new(8, 2, 16),
			CFrame.new(x, 4 + (i % 2) * 3, 0),
			Color3.fromRGB(196, 181, 253),
			Enum.Material.SmoothPlastic
		)

		local pad = makePart(
			parent,
			"JumpPad",
			Vector3.new(5, 0.5, 5),
			CFrame.new(x, 5.3 + (i % 2) * 3, 0),
			Color3.fromRGB(251, 191, 36),
			Enum.Material.Neon
		)
		pad.Touched:Connect(function(hit)
			local player = playerFromHit(hit)
			local character = player and player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root then
				root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 74, root.AssemblyLinearVelocity.Z)
			end
		end)
	end
end

local roomBuilders = {
	buildGapRoom,
	buildLavaStripeRoom,
	buildBeamRoom,
	buildStepRoom,
	buildSpinnerRoom,
	buildDisappearingRoom,
	buildChoiceRoom,
	buildJumpPadRoom,
}

local function buildCourse()
	setupLobby()

	local course = Instance.new("Folder")
	course.Name = "Course_" .. currentRound.id
	course.Parent = worldFolder

	currentRound.checkpointCFrames = {}

	local startPad = makePart(
		course,
		"StartPad",
		Vector3.new(28, 2, 24),
		CFrame.new(0, 5, 0),
		Config.Colors.Start,
		Enum.Material.Neon
	)
	makeTextBillboard(startPad, "GO!", Vector3.new(0, 5, 0))
	currentRound.startCFrame = startPad.CFrame
	currentRound.checkpointCFrames[0] = startPad.CFrame

	local killFloor = makePart(
		course,
		"VoidReset",
		Vector3.new(Config.RoomLength * (Config.RoomsPerRound + 2), 1, 120),
		CFrame.new((Config.RoomLength * Config.RoomsPerRound) / 2, -18, 0),
		Config.Colors.Hazard,
		Enum.Material.Neon
	)
	killFloor.Transparency = 0.25
	connectHazard(killFloor)

	for roomIndex = 1, Config.RoomsPerRound do
		local startX = (roomIndex - 1) * Config.RoomLength + 22
		local roomFolder = Instance.new("Folder")
		roomFolder.Name = "Room_" .. roomIndex
		roomFolder.Parent = course

		local builder = roomBuilders[rng:NextInteger(1, #roomBuilders)]
		builder(roomFolder, startX)
		addSideRails(roomFolder, startX, startX + Config.RoomLength - 8)
		addCheckpoint(roomFolder, roomIndex, startX + Config.RoomLength - 5)
	end

	addFinish(course, (Config.RoomsPerRound * Config.RoomLength) + 42)
end

local function beginPlayerRound(player)
	roundProgress[player] = {
		roundId = currentRound.id,
		inRound = true,
		finished = false,
		checkpointIndex = 0,
		roomsCleared = {},
	}
	teleportCharacter(player, currentRound.startCFrame)
end

local function broadcastRoundState(timeLeft)
	roundStateEvent:FireAllClients({
		phase = currentRound.phase,
		timeLeft = timeLeft,
		roundId = currentRound.id,
		roomsPerRound = Config.RoomsPerRound,
	})
end

local function runIntermission()
	currentRound.phase = "Intermission"
	for remaining = Config.IntermissionLength, 0, -1 do
		broadcastRoundState(remaining)
		task.wait(1)
	end
end

local function runRound()
	currentRound.id += 1
	currentRound.phase = "Round"
	currentRound.startedAt = os.clock()
	currentRound.firstFinisher = nil

	buildCourse()

	for _, player in ipairs(Players:GetPlayers()) do
		beginPlayerRound(player)
	end

	for remaining = Config.RoundLength, 0, -1 do
		broadcastRoundState(remaining)
		task.wait(1)
	end

	currentRound.phase = "Ended"
	broadcastRoundState(0)

	for _, player in ipairs(Players:GetPlayers()) do
		local progress = roundProgress[player]
		if progress then
			progress.inRound = false
		end
		teleportCharacter(player, CFrame.new(0, 5, -105))
	end

	task.wait(4)
	ensureLobbyOnly()
end

local function skipRoom(player)
	local progress = roundProgress[player]
	if not progress or not progress.inRound or progress.finished then
		return false
	end

	local nextIndex = math.clamp(progress.checkpointIndex + 1, 1, Config.RoomsPerRound)
	progress.checkpointIndex = nextIndex
	teleportCharacter(player, checkpointCFrame(nextIndex))
	messageEvent:FireClient(player, "Room skipped!")
	return true
end

local function handleProduct(player, productId)
	if productId == Config.ProductIds.SmallCoinPack and productId ~= 0 then
		local data = playerData[player]
		if data then
			data.Coins += Config.ProductRewards.SmallCoinPackCoins
			syncLeaderstats(player)
			sendPlayerData(player)
			messageEvent:FireClient(player, "+" .. Config.ProductRewards.SmallCoinPackCoins .. " coins added!")
			return true
		end
	elseif productId == Config.ProductIds.SkipRoom and productId ~= 0 then
		if skipRoom(player) then
			return true
		end
		addCoins(player, Config.Rewards.FinishCoins)
		messageEvent:FireClient(player, "Skip converted to bonus coins.")
		return true
	elseif productId == Config.ProductIds.Revive and productId ~= 0 then
		respawnAtCheckpoint(player)
		messageEvent:FireClient(player, "Revived at checkpoint!")
		return true
	end

	return false
end

MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local granted = handleProduct(player, receiptInfo.ProductId)
	if granted then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
	if not purchased then
		return
	end

	for passName, configuredId in pairs(Config.GamePassIds) do
		if configuredId == passId then
			playerPasses[player] = playerPasses[player] or {}
			playerPasses[player][passName] = true
			messageEvent:FireClient(player, passName .. " unlocked!")
			if player.Character then
				applyCharacterPerks(player, player.Character)
			end
		end
	end
end)

Players.PlayerAdded:Connect(function(player)
	refreshPasses(player)
	loadPlayerData(player)

	player.CharacterAdded:Connect(function(character)
		applyCharacterPerks(player, character)
		task.wait(0.5)
		if currentRound.phase == "Round" then
			respawnAtCheckpoint(player)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	savePlayerData(player)
	playerData[player] = nil
	playerPasses[player] = nil
	roundProgress[player] = nil
	touchDebounces[player] = nil
end)

game:BindToClose(function()
	if RunService:IsStudio() then
		task.wait(1)
		return
	end

	for _, player in ipairs(Players:GetPlayers()) do
		savePlayerData(player)
	end
	task.wait(2)
end)

ensureLobbyOnly()
task.spawn(function()
	while true do
		runIntermission()
		runRound()
	end
end)
