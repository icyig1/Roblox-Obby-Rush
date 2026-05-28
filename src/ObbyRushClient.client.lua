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
shopTitle.Size = UDim2.fromOffset(240, 32)
shopTitle.Font = Enum.Font.GothamBlack
shopTitle.Text = "Obby Shop"
shopTitle.TextColor3 = Color3.fromRGB(15, 23, 42)
shopTitle.TextSize = 22
shopTitle.TextXAlignment = Enum.TextXAlignment.Left
shopTitle.Parent = shopFrame

local closeShop = makeButton(shopFrame, "Close", "X", UDim2.new(1, -48, 0, 10), UDim2.fromOffset(32, 32))
closeShop.BackgroundColor3 = Color3.fromRGB(239, 68, 68)

local function promptGamePass(passId)
	if passId == 0 then
		showMessage("Create this gamepass, then put its ID in ObbyRushConfig.")
		return
	end
	MarketplaceService:PromptGamePassPurchase(player, passId)
end

local function promptProduct(productId)
	if productId == 0 then
		showMessage("Create this product, then put its ID in ObbyRushConfig.")
		return
	end
	MarketplaceService:PromptProductPurchase(player, productId)
end

local shopButtons = {
	{
		text = "2x Coins",
		y = 56,
		color = Color3.fromRGB(37, 99, 235),
		action = function()
			promptGamePass(Config.GamePassIds.DoubleCoins)
		end,
	},
	{
		text = "VIP Trail",
		y = 112,
		color = Color3.fromRGB(147, 51, 234),
		action = function()
			promptGamePass(Config.GamePassIds.VIPTrail)
		end,
	},
	{
		text = "Speed Boost",
		y = 168,
		color = Color3.fromRGB(5, 150, 105),
		action = function()
			promptGamePass(Config.GamePassIds.SpeedBoost)
		end,
	},
	{
		text = "Skip Room",
		y = 224,
		color = Color3.fromRGB(234, 88, 12),
		action = function()
			promptProduct(Config.ProductIds.SkipRoom)
		end,
	},
	{
		text = "250 Coins",
		y = 280,
		color = Color3.fromRGB(202, 138, 4),
		action = function()
			promptProduct(Config.ProductIds.SmallCoinPack)
		end,
	},
}

for _, item in ipairs(shopButtons) do
	local button = makeButton(shopFrame, item.text:gsub("%s+", ""), item.text, UDim2.fromOffset(16, item.y), UDim2.fromOffset(284, 42))
	button.BackgroundColor3 = item.color
	button.Activated:Connect(item.action)
end

shopButton.Activated:Connect(function()
	shopFrame.Visible = not shopFrame.Visible
end)

closeShop.Activated:Connect(function()
	shopFrame.Visible = false
end)

openShopEvent.OnClientEvent:Connect(function()
	shopFrame.Visible = true
end)

showMessage = function(text)
	messageLabel.Text = text
	messageLabel.Visible = true
	messageLabel.TextTransparency = 0
	messageLabel.BackgroundTransparency = 0.08

	local tween = TweenService:Create(
		messageLabel,
		TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 2.4),
		{ TextTransparency = 1, BackgroundTransparency = 1 }
	)
	tween:Play()
	tween.Completed:Once(function()
		messageLabel.Visible = false
	end)
end

local function formatBest(bestTime)
	if not bestTime or bestTime == 0 then
		return "--"
	end
	return tostring(bestTime) .. "s"
end

playerDataEvent.OnClientEvent:Connect(function(data)
	statsLabel.Text = ("Coins: %d | Wins: %d | Level: %d"):format(data.Coins or 0, data.Wins or 0, data.Level or 1)
	progressLabel.Text = "Best: " .. formatBest(data.BestTime)
end)

roundStateEvent.OnClientEvent:Connect(function(state)
	local phase = state.phase or "Loading"
	local timeLeft = state.timeLeft or 0

	if phase == "Queue" then
		timerLabel.Text = ("Queue: %d/%d"):format(state.queueCount or 0, state.maxPlayers or 10)
		timerLabel.BackgroundColor3 = Color3.fromRGB(30, 64, 175)
	elseif phase == "Countdown" then
		timerLabel.Text = ("Starting: %ds"):format(timeLeft)
		timerLabel.BackgroundColor3 = Color3.fromRGB(30, 64, 175)
	elseif phase == "Round" then
		timerLabel.Text = ("Race: %ds"):format(timeLeft)
		timerLabel.BackgroundColor3 = timeLeft <= 10 and Color3.fromRGB(185, 28, 28) or Color3.fromRGB(15, 23, 42)
	elseif phase == "Ended" then
		timerLabel.Text = "Round over"
		timerLabel.BackgroundColor3 = Color3.fromRGB(22, 101, 52)
	else
		timerLabel.Text = phase
	end
end)

messageEvent.OnClientEvent:Connect(showMessage)

local function scaleForSmallScreens()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	local width = camera.ViewportSize.X
	if width < 760 then
		statsLabel.Position = UDim2.fromOffset(0, 66)
		progressLabel.Position = UDim2.fromOffset(0, 132)
		shopButton.Position = UDim2.new(1, -124, 0, 16)
		shopFrame.Position = UDim2.new(0.5, -158, 0, 96)
	else
		statsLabel.Position = UDim2.fromOffset(252, 0)
		progressLabel.Position = UDim2.fromOffset(594, 0)
		shopButton.Position = UDim2.new(1, -128, 0, 98)
		shopFrame.Position = UDim2.new(1, -336, 0, 152)
	end
end

scaleForSmallScreens()
local function connectCamera()
	local camera = workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(scaleForSmallScreens)
		scaleForSmallScreens()
	end
end

connectCamera()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(connectCamera)
