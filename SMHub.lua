-- Survive Monster [Beta] Hub

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

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
main.Parent = screenGui

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

local shadow = Instance.new("Frame")
shadow.Size = UDim2.new(1, 10, 1, 10)
shadow.Position = UDim2.new(0, -5, 0, -5)
shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
shadow.BackgroundTransparency = 0.6
shadow.BorderSizePixel = 0
shadow.ZIndex = main.ZIndex - 1
shadow.Parent = main

Instance.new("UICorner", shadow).CornerRadius = UDim.new(0, 14)

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

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
minimizeBtn.Position = UDim2.new(1, -35, 0, 7)
minimizeBtn.BackgroundTransparency = 1
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.Text = "+"
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 16
minimizeBtn.Parent = titleBar

-- Content (hidden by default)
local content = Instance.new("Frame")
content.Size = UDim2.new(1, 0, 0, 220)
content.Position = UDim2.new(0, 0, 0, 45)
content.BackgroundTransparency = 1
content.Visible = false
content.Parent = main

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

local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, -20, 0, 1)
divider.Position = UDim2.new(0, 10, 0, 35)
divider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
divider.BorderSizePixel = 0
divider.Parent = content

-- WAVE Section
local waveLabel = Instance.new("TextLabel")
waveLabel.Size = UDim2.new(1, -20, 0, 20)
waveLabel.Position = UDim2.new(0, 10, 0, 45)
waveLabel.BackgroundTransparency = 1
waveLabel.TextColor3 = Color3.fromRGB(120, 40, 200)
waveLabel.Text = "WAVE"
waveLabel.Font = Enum.Font.GothamBold
waveLabel.TextSize = 11
waveLabel.TextXAlignment = Enum.TextXAlignment.Left
waveLabel.Parent = content

-- Auto Skip Toggle
local autoSkip = false
local lastVoted = false

local skipFrame = Instance.new("Frame")
skipFrame.Size = UDim2.new(1, -20, 0, 45)
skipFrame.Position = UDim2.new(0, 10, 0, 68)
skipFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
skipFrame.BorderSizePixel = 0
skipFrame.Parent = content

Instance.new("UICorner", skipFrame).CornerRadius = UDim.new(0, 8)

local skipLabel = Instance.new("TextLabel")
skipLabel.Size = UDim2.new(1, -60, 1, 0)
skipLabel.Position = UDim2.new(0, 12, 0, 0)
skipLabel.BackgroundTransparency = 1
skipLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
skipLabel.Text = "Auto Skip Wave"
skipLabel.Font = Enum.Font.Gotham
skipLabel.TextSize = 13
skipLabel.TextXAlignment = Enum.TextXAlignment.Left
skipLabel.Parent = skipFrame

local skipBtn = Instance.new("TextButton")
skipBtn.Size = UDim2.new(0, 44, 0, 24)
skipBtn.Position = UDim2.new(1, -54, 0.5, -12)
skipBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
skipBtn.Text = ""
skipBtn.BorderSizePixel = 0
skipBtn.Parent = skipFrame

Instance.new("UICorner", skipBtn).CornerRadius = UDim.new(1, 0)

local skipCircle = Instance.new("Frame")
skipCircle.Size = UDim2.new(0, 18, 0, 18)
skipCircle.Position = UDim2.new(0, 3, 0.5, -9)
skipCircle.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
skipCircle.BorderSizePixel = 0
skipCircle.Parent = skipBtn

Instance.new("UICorner", skipCircle).CornerRadius = UDim.new(1, 0)

skipBtn.MouseButton1Click:Connect(function()
    autoSkip = not autoSkip
    if autoSkip then
        TweenService:Create(skipBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(120, 40, 200)}):Play()
        TweenService:Create(skipCircle, TweenInfo.new(0.2), {Position = UDim2.new(0, 23, 0.5, -9), BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
    else
        TweenService:Create(skipBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}):Play()
        TweenService:Create(skipCircle, TweenInfo.new(0.2), {Position = UDim2.new(0, 3, 0.5, -9), BackgroundColor3 = Color3.fromRGB(180, 180, 180)}):Play()
    end
end)

-- PLAYER Section
local divider2 = Instance.new("Frame")
divider2.Size = UDim2.new(1, -20, 0, 1)
divider2.Position = UDim2.new(0, 10, 0, 122)
divider2.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
divider2.BorderSizePixel = 0
divider2.Parent = content

local playerLabel = Instance.new("TextLabel")
playerLabel.Size = UDim2.new(1, -20, 0, 20)
playerLabel.Position = UDim2.new(0, 10, 0, 132)
playerLabel.BackgroundTransparency = 1
playerLabel.TextColor3 = Color3.fromRGB(120, 40, 200)
playerLabel.Text = "PLAYER"
playerLabel.Font = Enum.Font.GothamBold
playerLabel.TextSize = 11
playerLabel.TextXAlignment = Enum.TextXAlignment.Left
playerLabel.Parent = content

-- Infinite Stamina Toggle
local infStamina = false
local staminaBar = player.PlayerGui:WaitForChild("SprintGui").Frame.Frame
local originalColor = Color3.new(0.313726, 0.784314, 0.470588)

local staminaFrame = Instance.new("Frame")
staminaFrame.Size = UDim2.new(1, -20, 0, 45)
staminaFrame.Position = UDim2.new(0, 10, 0, 155)
staminaFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
staminaFrame.BorderSizePixel = 0
staminaFrame.Parent = content

Instance.new("UICorner", staminaFrame).CornerRadius = UDim.new(0, 8)

local staminaLabel = Instance.new("TextLabel")
staminaLabel.Size = UDim2.new(1, -60, 1, 0)
staminaLabel.Position = UDim2.new(0, 12, 0, 0)
staminaLabel.BackgroundTransparency = 1
staminaLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
staminaLabel.Text = "Infinite Stamina"
staminaLabel.Font = Enum.Font.Gotham
staminaLabel.TextSize = 13
staminaLabel.TextXAlignment = Enum.TextXAlignment.Left
staminaLabel.Parent = staminaFrame

local staminaBtn = Instance.new("TextButton")
staminaBtn.Size = UDim2.new(0, 44, 0, 24)
staminaBtn.Position = UDim2.new(1, -54, 0.5, -12)
staminaBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
staminaBtn.Text = ""
staminaBtn.BorderSizePixel = 0
staminaBtn.Parent = staminaFrame

Instance.new("UICorner", staminaBtn).CornerRadius = UDim.new(1, 0)

local staminaCircle = Instance.new("Frame")
staminaCircle.Size = UDim2.new(0, 18, 0, 18)
staminaCircle.Position = UDim2.new(0, 3, 0.5, -9)
staminaCircle.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
staminaCircle.BorderSizePixel = 0
staminaCircle.Parent = staminaBtn

Instance.new("UICorner", staminaCircle).CornerRadius = UDim.new(1, 0)

staminaBtn.MouseButton1Click:Connect(function()
    infStamina = not infStamina
    if infStamina then
        TweenService:Create(staminaBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(120, 40, 200)}):Play()
        TweenService:Create(staminaCircle, TweenInfo.new(0.2), {Position = UDim2.new(0, 23, 0.5, -9), BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
    else
        TweenService:Create(staminaBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}):Play()
        TweenService:Create(staminaCircle, TweenInfo.new(0.2), {Position = UDim2.new(0, 3, 0.5, -9), BackgroundColor3 = Color3.fromRGB(180, 180, 180)}):Play()
    end
end)

-- Minimize Logic
local minimized = true

minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        content.Visible = false
        TweenService:Create(main, TweenInfo.new(0.3), {Size = UDim2.new(0, 240, 0, 45)}):Play()
        minimizeBtn.Text = "+"
    else
        content.Visible = true
        TweenService:Create(main, TweenInfo.new(0.3), {Size = UDim2.new(0, 240, 0, 265)}):Play()
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

-- Infinite Stamina Loop
local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")

player.CharacterAdded:Connect(function(char)
    humanoid = char:WaitForChild("Humanoid")
end)

local oldIndex
oldIndex = hookmetamethod(game, "__newindex", function(self, key, value)
    if infStamina and self == staminaBar then
        if key == "Size" then
            return oldIndex(self, key, UDim2.new(1, 0, 1, 0))
        end
        if key == "BackgroundColor3" then
            return oldIndex(self, key, originalColor)
        end
    end
    return oldIndex(self, key, value)
end)

RunService.Heartbeat:Connect(function()
    if infStamina and humanoid then
        local shifting = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
        if shifting and humanoid.WalkSpeed < 28.8 then
            humanoid.WalkSpeed = 28.8
        end
    end
end)

print("SM Hub loaded!")
