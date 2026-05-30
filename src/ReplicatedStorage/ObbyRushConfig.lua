local Config = {}

Config.RoundLength = 60
Config.QueueCountdown = 15
Config.MinPlayersToStart = 1 -- Use 1 for solo testing. Change back to 2 before public testing.
Config.MaxPlayersPerRound = 10
Config.RoomsPerRound = 8
Config.RoomLength = 86
Config.CourseWidth = 34
Config.RoomHeight = 28
Config.RoomShellPadding = 18

Config.PointPositions = {
	LobbySpawn = Vector3.new(0, 2, -108),
	QueuePad = Vector3.new(0, 2, -82),
	ShopPad = Vector3.new(-28, 2, -88),
	RoundExitPad = Vector3.new(36, 2, -72),
	WaitingCenter = Vector3.new(0, 4, -198),
	LeaveQueuePad = Vector3.new(0, 4, -188),
	FinisherWaitingCenter = Vector3.new(82, 4, -198),
}

-- Hazards only trigger from these body parts. This avoids unfair deaths from hats,
-- arms, or accessories barely brushing a red part.
Config.HazardTouchPartNames = {
	HumanoidRootPart = true,
	LowerTorso = true,
	UpperTorso = true,
	Torso = true,
	LeftFoot = true,
	RightFoot = true,
	LeftLowerLeg = true,
	RightLowerLeg = true,
	["Left Leg"] = true,
	["Right Leg"] = true,
}

Config.WalkSpeed = 18
Config.SpeedPassWalkSpeed = 22
Config.JumpPower = 52
Config.JumpHeight = 7.5

Config.Rewards = {
	CheckpointCoins = 3,
	FinishCoins = 35,
	FirstFinishBonus = 20,
	RoomCoinValue = 2,
	FinishXP = 40,
	CheckpointXP = 5,
}

Config.Levels = {
	BaseXP = 100,
	Scale = 35,
}

-- Replace 0 with real Roblox IDs after creating passes/products.
Config.GamePassIds = {
	DoubleCoins = 0,
	VIPTrail = 0,
	SpeedBoost = 0,
}

Config.ProductIds = {
	SkipRoom = 0,
	SmallCoinPack = 0,
	Revive = 0,
}

Config.ProductRewards = {
	SmallCoinPackCoins = 250,
}

Config.Colors = {
	Lobby = Color3.fromRGB(245, 247, 250),
	Start = Color3.fromRGB(69, 170, 242),
	Checkpoint = Color3.fromRGB(46, 213, 115),
	Finish = Color3.fromRGB(255, 212, 59),
	Hazard = Color3.fromRGB(255, 71, 87),
	Coin = Color3.fromRGB(255, 190, 11),
}

return Config
