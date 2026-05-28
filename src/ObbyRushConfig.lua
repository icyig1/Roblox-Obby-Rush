local Config = {}

Config.RoundLength = 60
Config.IntermissionLength = 15
Config.RoomsPerRound = 8
Config.RoomLength = 72
Config.CourseWidth = 34

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
