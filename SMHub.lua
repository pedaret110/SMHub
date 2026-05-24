-- Survive Monster [Beta] Hub

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local waveRemote = ReplicatedStorage:WaitForChild("WaveRemote")
local player = Players.LocalPlayer

-- GUI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SMHub"
screenGui.ResetOnSpawn = false
screenGui.Parent = player.PlayerGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 220, 0, 110)
main.Position = UDim2.new(0.5, -110, 0, 20)
main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
main.BorderSizePixel = 0
main.Parent = screenGui

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 200)
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Text = "Survive Monster Hub"
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Parent = main

Instance.new("UICorner", title).CornerRadius = UDim.new(0, 10)

-- Auto Skip Toggle
local autoSkip = false
local lastVoted = false

local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 180, 0, 40)
button.Position = UDim2.new(0.5, -90, 0, 55)
button.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Text = "Auto Skip: OFF"
button.Font = Enum.Font.GothamBold
button.TextSize = 14
button.Parent = main

Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)

button.MouseButton1Click:Connect(function()
    autoSkip = not autoSkip
    if autoSkip then
        button.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        button.Text = "Auto Skip: ON"
    else
        button.Backgroun
