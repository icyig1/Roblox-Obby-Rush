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

local openShopEvent = remotesFolder:FindFirstChild("OpenShop") or Instance.new("RemoteEvent")
openShopEvent.Name = "OpenShop"
openShopEvent.Parent = remotesFolder

local LOBBY_SPAWN_CFRAME = CFrame.new(0, 5, -108)
local EXIT_SPAWN_CFRAME = CFrame.new(36, 5, -72)
local WAITING_CENTER_CFRAME = CFrame.new(0, 6, -198)

local playerData = {}
local playerPasses = {}
local roundProgress = {}
local queuedPlayers = {}
local queuedByPlayer = {}
local activeRoundPlayers = {}
local touchDebounces = {}
local padDebounces = {}
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
