-- Survive Monster [Beta] Hub

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local waveRemote = ReplicatedStorage:WaitForChild("WaveRemote")
local player = Players.LocalPlayer

if player.PlayerGui:FindFirstChild("SMHub") then
    player.PlayerGui.SMHub:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SMHub"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player.PlayerGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 240, 0, 45)
main.Position = UDim2.new(0, 20, 0.3, 0)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = screenGui

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

-- Drop Shadow
local shadow = Instance.new("Frame")
shadow.Size = UDim2.new(1, 10, 1, 10)
shadow.Position = UDim2.new(0, -5, 0, -5)
shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
shadow.BackgroundTransparency = 0.6
shadow.BorderSizePixel = 0
shadow.ZIndex = main.ZIndex - 1
shadow.Parent = main

Instance.new("UICorner", shadow).CornerRadius = UDim.new(0, 14)

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 45)
titleBar.BackgroundColor3 = Color3.fromRGB(120, 40, 200)
titleBar.BorderSizePixel = 0
titleBar.Parent = main

Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 12)

local titleFix = Instance.new("Frame")
titleFix.Size = UDim2.new(1, 0, 0.5, 0)
titleFix.Position = UDim2.new(0, 0, 0.5, 0)
titleFix.BackgroundColor3 = Color3.fromRGB(120, 40, 200)
titleFix.BorderSizePixel = 0
titleFix.Parent = titleBar

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -50, 1, 0)
titleText.Position = UDim2.new(0, 10, 0, 0)
titleText.BackgroundTransparency = 1
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.Text = "⚡ SM Hub"
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 16
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

-- Minimize Button
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
minimizeBtn.Position = UDim2.new(1, -35, 0, 7)
minimizeBtn.BackgroundTransparency = 1
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.Text = "+"
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 16
minimizeBtn.Parent = titleBar

-- Content Frame (everything below title)
local content = Instance.new("Frame")
content.Size = UDim2.new(1, 0, 1, -45)
content.Position = UDim2.new(0, 0, 0, 45)
content.BackgroundTransparency = 1
content.Parent = main

-- Subtitle
local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -10, 0, 20)
subtitle.Position = UDim2.new(0, 10, 0, 8)
subtitle.BackgroundTransparency = 1
subtitle.TextColor3 = Color3.fromRGB(150, 150, 150)
subtitle.Text = "Survive Monster [Beta]"
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 11
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = content

-- Divider
local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, -20, 0, 1)
divider.Position = UDim2.new(0, 10, 0, 35)
divider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
divider.BorderSizePixel = 0
divider.Parent = content

-- Section Label
local sectionLabel = Instance.new("TextLabel")
sectionLabel.Size = UDim2.new(1, -20, 0, 20)
sectionLabel.Position = UDim2.new(0, 10, 0, 45)
sectionLabel.BackgroundTransparency = 1
sectionLabel.TextColor3 = Color3.fromRGB(120, 40, 200)
sectionLabel.Text = "WAVE"
sectionLabel.Font = Enum.Font.GothamBold
sectionLabel.TextSize = 11
sectionLabel.TextXAlignment = Enum.TextXAlignment.Left
sectionLabel.Parent = content

-- Auto Skip Toggle
local autoSkip = false
local lastVoted = false

local toggleFrame = Instance.new("Frame")
toggleFrame.Size = UDim2.new(1, -20, 0, 45)
toggleFrame.Position = UDim2.new(0, 10, 0, 68)
toggleFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
toggleFrame.BorderSizePixel = 0
toggleFrame.Parent = content

Instance.new("UICorner", toggleFrame).CornerRadius = UDim.new(0, 8)

local toggleLabel = Instance.new("TextLabel")
toggleLabel.Size = UDim2.new(1, -60, 1, 0)
toggleLabel.Position = UDim2.new(0, 12, 0, 0)
toggleLabel.BackgroundTransparency = 1
toggleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleLabel.Text = "Auto Skip Wave"
toggleLabel.Font = Enum.Font.Gotham
toggleLabel.TextSize = 13
toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
toggleLabel.Parent = toggleFrame

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 44, 0, 24)
toggleBtn.Position = UDim2.new(1, -54, 0.5, -12)
toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
toggleBtn.Text = ""
toggleBtn.BorderSizePixel = 0
toggleBtn.Parent = toggleFrame

Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)

local toggleCircle = Instance.new("Frame")
toggleCircle.Size = UDim2.new(0, 18, 0, 18)
toggleCircle.Position = UDim2.new(0, 3, 0.5, -9)
toggleCircle.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
toggleCircle.BorderSizePixel = 0
toggleCircle.Parent = toggleBtn

Instance.new("UICorner", toggleCircle).CornerRadius = UDim.new(1, 0)

toggleBtn.MouseButton1Click:Connect(function()
    autoSkip = not autoSkip
    if autoSkip then
        TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(120, 40, 200)}):Play()
        TweenService:Create(toggleCircle, TweenInfo.new(0.2), {Position = UDim2.new(0, 23, 0.5, -9), BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
    else
        TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}):Play()
        TweenService:Create(toggleCircle, TweenInfo.new(0.2), {Position = UDim2.new(0, 3, 0.5, -9), BackgroundColor3 = Color3.fromRGB(180, 180, 180)}):Play()
    end
end)

-- Minimize Logic
local minimized = true

minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        TweenService:Create(main, TweenInfo.new(0.3), {Size = UDim2.new(0, 240, 0, 45)}):Play()
        minimizeBtn.Text = "+"
    else
        TweenService:Create(main, TweenInfo.new(0.3), {Size = UDim2.new(0, 240, 0, 175)}):Play()
        minimizeBtn.Text = "—"
    end
end)

-- Draggable
local dragging, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
    end
end)

titleBar.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

titleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- Auto Skip Loop
task.spawn(function()
    while task.wait(0.1) do
        if autoSkip then
            local buttonFound = false
            for _, gui in ipairs(player.PlayerGui:GetDescendants()) do
                if (gui:IsA("TextButton") or gui:IsA("ImageButton")) and gui.Text:find("NEXT WAVE") and gui.Visible then
                    buttonFound = true
                    break
                end
            end

            if buttonFound and not lastVoted then
                lastVoted = true
                waveRemote:FireServer("VoteSkip")
                print("Voted to skip wave!")
                task.wait(1)
                lastVoted = false
            end
        end
    end
end)

print("SM Hub loaded!")
