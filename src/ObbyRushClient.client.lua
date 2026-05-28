local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("ObbyRushConfig"))
local remotes = ReplicatedStorage:WaitForChild("ObbyRushRemotes")
local roundStateEvent = remotes:WaitForChild("RoundState")
local playerDataEvent = remotes:WaitForChild("PlayerData")
local messageEvent = remotes:WaitForChild("Message")
local openShopEvent = remotes:WaitForChild("OpenShop")
local showMessage

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ObbyRushHud"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = player:WaitForChild("PlayerGui")

local function makeCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = parent
end

local function makeStroke(parent, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Color3.fromRGB(226, 232, 240)
	stroke.Thickness = thickness or 1
	stroke.Parent = parent
end

local function makeLabel(parent, name, text, position, size, textSize)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
	label.BackgroundTransparency = 0.08
	label.Position = position
	label.Size = size
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextColor3 = Color3.fromRGB(248, 250, 252)
	label.TextSize = textSize or 18
	label.TextWrapped = true
	label.Parent = parent
	makeCorner(label, 8)
	makeStroke(label, Color3.fromRGB(51, 65, 85), 1)
	return label
end

local function makeButton(parent, name, text, position, size)
	local button = Instance.new("TextButton")
	button.Name = name
	button.BackgroundColor3 = Color3.fromRGB(37, 99, 235)
	button.Position = position
	button.Size = size
	button.AutoButtonColor = true
	button.Font = Enum.Font.GothamBlack
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 16
	button.TextWrapped = true
	button.Parent = parent
	makeCorner(button, 8)
	makeStroke(button, Color3.fromRGB(147, 197, 253), 1)
	return button
end

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.BackgroundTransparency = 1
topBar.Position = UDim2.new(0, 16, 0, 16)
topBar.Size = UDim2.new(1, -32, 0, 76)
topBar.Parent = screenGui

local timerLabel = makeLabel(topBar, "Timer", "Loading...", UDim2.fromOffset(0, 0), UDim2.fromOffset(240, 60), 24)
local statsLabel = makeLabel(topBar, "Stats", "Coins: 0 | Wins: 0 | Level: 1", UDim2.fromOffset(252, 0), UDim2.fromOffset(330, 60), 17)
local progressLabel = makeLabel(topBar, "Progress", "Best: --", UDim2.fromOffset(594, 0), UDim2.fromOffset(190, 60), 17)

local shopButton = makeButton(screenGui, "ShopButton", "SHOP", UDim2.new(1, -128, 0, 98), UDim2.fromOffset(108, 44))

local messageLabel = makeLabel(screenGui, "Message", "", UDim2.new(0.5, -190, 0, 98), UDim2.fromOffset(380, 54), 18)
messageLabel.Visible = false
messageLabel.BackgroundColor3 = Color3.fromRGB(22, 101, 52)

local shopFrame = Instance.new("Frame")
shopFrame.Name = "Shop"
shopFrame.BackgroundColor3 = Color3.fromRGB(248, 250, 252)
shopFrame.Position = UDim2.new(1, -336, 0, 152)
shopFrame.Size = UDim2.fromOffset(316, 342)
shopFrame.Visible = false
shopFrame.Parent = screenGui
makeCorner(shopFrame, 8)
makeStroke(shopFrame, Color3.fromRGB(148, 163, 184), 1)

local shopTitle = Instance.new("TextLabel")
shopTitle.Name = "Title"
shopTitle.BackgroundTransparency = 1
shopTitle.Position = UDim2.fromOffset(16, 10)
