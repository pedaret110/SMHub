-- ============================================================
--  SM Hub Combined  |  SM Hub + Aimbot + Fly
-- ============================================================

local Players          = game:GetService("Players")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player  = Players.LocalPlayer
local camera  = workspace.CurrentCamera

-- Remotes
local waveRemote      = ReplicatedStorage:WaitForChild("WaveRemote")
local bulletHitRemote = ReplicatedStorage:WaitForChild("BulletHit")
local gunConfigRemote = ReplicatedStorage:WaitForChild("GetGunConfig")

-- Zombie folder
local zombieFolder = workspace:WaitForChild("Zombies")

-- ============================================================
--  SETTINGS
-- ============================================================
local SETTINGS = {
    AutoSkip     = false,
    InfStamina   = false,
    Enabled      = false,
    FOV          = 200,
    Smoothness   = 0.12,
    TargetPart   = "Head",
    AutoShoot    = false,
    WallCheck    = true,
    PriorityMode = "Screen",
}

-- ============================================================
--  FOV CIRCLE (declared early so UI callbacks can reference it)
-- ============================================================
local fovCircle = Drawing.new("Circle")
fovCircle.Radius   = 200
fovCircle.Color    = Color3.fromRGB(120, 40, 200)
fovCircle.Thickness= 1.5
fovCircle.Filled   = false
fovCircle.NumSides = 64
fovCircle.Visible  = false

-- ============================================================
--  RAW KEY TRACKING  (Q = 81 toggles aimbot)
-- ============================================================
local heldKeys = {}
UserInputService.InputBegan:Connect(function(input, gpe)
    heldKeys[input.KeyCode.Value] = true
    if not gpe and input.KeyCode.Value == 81 then
        SETTINGS.Enabled = not SETTINGS.Enabled
        if aimbotToggleSync then aimbotToggleSync(SETTINGS.Enabled) end
    end
end)
UserInputService.InputEnded:Connect(function(input)
    heldKeys[input.KeyCode.Value] = false
end)

local aimbotToggleSync = nil

-- ============================================================
--  AIMBOT HELPERS
-- ============================================================
local bulletCount = 0
local function nextBulletId()
    bulletCount += 1
    return tostring(player.UserId) .. "_" .. tostring(bulletCount)
end

local gunConfig = nil
local function getGunConfig()
    local char = player.Character
    if not char then return nil end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return nil end
    local ok, result = pcall(function()
        return gunConfigRemote:InvokeServer(tool.Name)
    end)
    if ok and result then
        result.name = tool.Name
        return result
    end
    return nil
end

local function onCharAdded(char)
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            task.wait(0.1)
            gunConfig = getGunConfig()
        end
    end)
    char.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") then gunConfig = nil end
    end)
end

if player.Character then onCharAdded(player.Character) end
player.CharacterAdded:Connect(function(char)
    onCharAdded(char)
    SETTINGS.Enabled = false
    if aimbotToggleSync then aimbotToggleSync(false) end
end)

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
local function updateRayFilter(char)
    rayParams.FilterDescendantsInstances = {char, zombieFolder}
end
if player.Character then updateRayFilter(player.Character) end
player.CharacterAdded:Connect(updateRayFilter)

-- ============================================================
--  STAMINA HOOK
-- ============================================================
local staminaBar    = player.PlayerGui:WaitForChild("SprintGui").Frame.Frame
local originalColor = Color3.new(0.313726, 0.784314, 0.470588)

local oldIndex
oldIndex = hookmetamethod(game, "__newindex", function(self, key, value)
    if SETTINGS.InfStamina and self == staminaBar then
        if key == "Size" then
            return oldIndex(self, key, UDim2.new(1, 0, 1, 0))
        end
        if key == "BackgroundColor3" then
            return oldIndex(self, key, originalColor)
        end
    end
    return oldIndex(self, key, value)
end)

local smHumanoid = player.Character and player.Character:FindFirstChild("Humanoid")
player.CharacterAdded:Connect(function(char)
    smHumanoid = char:WaitForChild("Humanoid")
end)

-- ============================================================
--  FLY
-- ============================================================
local flying   = false
local bodyVel  = nil
local bodyGyro = nil
local FLY_SPEED = 60

local function startFly()
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end
    hum.PlatformStand = true
    bodyVel = Instance.new("BodyVelocity")
    bodyVel.Velocity  = Vector3.zero
    bodyVel.MaxForce  = Vector3.new(1e5, 1e5, 1e5)
    bodyVel.Parent    = hrp
    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    bodyGyro.P         = 1e4
    bodyGyro.CFrame    = hrp.CFrame
    bodyGyro.Parent    = hrp
    flying = true
end

local function stopFly()
    flying = false
    local char = player.Character
    local hum  = char and char:FindFirstChild("Humanoid")
    if hum then hum.PlatformStand = false end
    if bodyVel  then bodyVel:Destroy();  bodyVel  = nil end
    if bodyGyro then bodyGyro:Destroy(); bodyGyro = nil end
end

player.CharacterAdded:Connect(function()
    bodyVel  = nil
    bodyGyro = nil
    if flying then task.wait(0.5); startFly() end
end)

RunService.Heartbeat:Connect(function()
    if not flying or not bodyVel or not bodyGyro then return end
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local camCF = camera.CFrame
    local move  = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + camCF.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - camCF.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - camCF.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + camCF.RightVector end
    if move.Magnitude > 0 then
        bodyVel.Velocity = move.Unit * FLY_SPEED
        bodyGyro.CFrame  = CFrame.new(hrp.Position, hrp.Position + move)
    else
        bodyVel.Velocity = Vector3.zero
        bodyGyro.CFrame  = hrp.CFrame
    end
end)

-- ============================================================
--  GUI SETUP
-- ============================================================
local playerGui = player.PlayerGui
for _, name in ipairs({"SMHub", "AimbotUI", "CombinedHub"}) do
    if playerGui:FindFirstChild(name) then
        playerGui[name]:Destroy()
    end
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name          = "CombinedHub"
screenGui.ResetOnSpawn  = false
screenGui.ZIndexBehavior= Enum.ZIndexBehavior.Sibling
screenGui.Parent        = playerGui

-- ============================================================
--  MAIN WINDOW
-- ============================================================
local PURPLE  = Color3.fromRGB(120, 40, 200)
local DARK    = Color3.fromRGB(18, 18, 18)
local CARD    = Color3.fromRGB(28, 28, 28)
local DIVCLR  = Color3.fromRGB(50, 50, 50)
local WIN_W   = 260

local main = Instance.new("Frame")
main.Size            = UDim2.new(0, WIN_W, 0, 45)
main.Position        = UDim2.new(0, 20, 0.2, 0)
main.BackgroundColor3= DARK
main.BorderSizePixel = 0
main.Parent          = screenGui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

local shadow = Instance.new("Frame")
shadow.Size                  = UDim2.new(1, 10, 1, 10)
shadow.Position              = UDim2.new(0, -5, 0, -5)
shadow.BackgroundColor3      = Color3.fromRGB(0, 0, 0)
shadow.BackgroundTransparency= 0.6
shadow.BorderSizePixel       = 0
shadow.ZIndex                = main.ZIndex - 1
shadow.Parent                = main
Instance.new("UICorner", shadow).CornerRadius = UDim.new(0, 14)

local titleBar = Instance.new("Frame")
titleBar.Size            = UDim2.new(1, 0, 0, 45)
titleBar.BackgroundColor3= PURPLE
titleBar.BorderSizePixel = 0
titleBar.Parent          = main
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 12)

local titleFix = Instance.new("Frame")
titleFix.Size            = UDim2.new(1, 0, 0.5, 0)
titleFix.Position        = UDim2.new(0, 0, 0.5, 0)
titleFix.BackgroundColor3= PURPLE
titleFix.BorderSizePixel = 0
titleFix.Parent          = titleBar

local titleText = Instance.new("TextLabel")
titleText.Size               = UDim2.new(1, -50, 1, 0)
titleText.Position           = UDim2.new(0, 10, 0, 0)
titleText.BackgroundTransparency = 1
titleText.TextColor3         = Color3.fromRGB(255, 255, 255)
titleText.Text               = "⚡ SM Hub"
titleText.Font               = Enum.Font.GothamBold
titleText.TextSize           = 15
titleText.TextXAlignment     = Enum.TextXAlignment.Left
titleText.Parent             = titleBar

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size                 = UDim2.new(0, 30, 0, 30)
minimizeBtn.Position             = UDim2.new(1, -35, 0, 7)
minimizeBtn.BackgroundTransparency = 1
minimizeBtn.TextColor3           = Color3.fromRGB(255, 255, 255)
minimizeBtn.Text                 = "+"
minimizeBtn.Font                 = Enum.Font.GothamBold
minimizeBtn.TextSize             = 16
minimizeBtn.Parent               = titleBar

-- ============================================================
--  TAB BAR
-- ============================================================
local tabBar = Instance.new("Frame")
tabBar.Size            = UDim2.new(1, -20, 0, 32)
tabBar.Position        = UDim2.new(0, 10, 0, 50)
tabBar.BackgroundColor3= CARD
tabBar.BorderSizePixel = 0
tabBar.Visible         = false
tabBar.Parent          = main
Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0, 8)

local function makeTab(text, xScale, isActive)
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(0.5, -4, 1, -8)
    btn.Position         = UDim2.new(xScale, 4, 0, 4)
    btn.BackgroundColor3 = isActive and PURPLE or CARD
    btn.TextColor3       = Color3.fromRGB(255, 255, 255)
    btn.Text             = text
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = 12
    btn.BorderSizePixel  = 0
    btn.Parent           = tabBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

local tabSM     = makeTab("SM Hub", 0, true)
local tabAimbot = makeTab("🎯 Aimbot", 0.5, false)

-- ============================================================
--  SCROLL FRAME
-- ============================================================
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size                   = UDim2.new(1, 0, 0, 340)
scrollFrame.Position               = UDim2.new(0, 0, 0, 88)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel        = 0
scrollFrame.ScrollBarThickness     = 3
scrollFrame.ScrollBarImageColor3   = PURPLE
scrollFrame.Visible                = false
scrollFrame.Parent                 = main

-- ============================================================
--  HELPER BUILDERS
-- ============================================================
local function makeLabel(parent, text, yPos, color)
    local lbl = Instance.new("TextLabel")
    lbl.Size             = UDim2.new(1, -20, 0, 18)
    lbl.Position         = UDim2.new(0, 10, 0, yPos)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3       = color or Color3.fromRGB(150, 150, 150)
    lbl.Text             = text
    lbl.Font             = Enum.Font.GothamBold
    lbl.TextSize         = 11
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.Parent           = parent
    return lbl
end

local function makeDivider(parent, yPos)
    local d = Instance.new("Frame")
    d.Size            = UDim2.new(1, -20, 0, 1)
    d.Position        = UDim2.new(0, 10, 0, yPos)
    d.BackgroundColor3= DIVCLR
    d.BorderSizePixel = 0
    d.Parent          = parent
end

local function makeToggle(parent, labelText, yPos, default, callback)
    local frame = Instance.new("Frame")
    frame.Size            = UDim2.new(1, -20, 0, 40)
    frame.Position        = UDim2.new(0, 10, 0, yPos)
    frame.BackgroundColor3= CARD
    frame.BorderSizePixel = 0
    frame.Parent          = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size             = UDim2.new(1, -60, 1, 0)
    lbl.Position         = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3       = Color3.fromRGB(255, 255, 255)
    lbl.Text             = labelText
    lbl.Font             = Enum.Font.Gotham
    lbl.TextSize         = 13
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.Parent           = frame

    local btn = Instance.new("TextButton")
    btn.Size            = UDim2.new(0, 44, 0, 24)
    btn.Position        = UDim2.new(1, -54, 0.5, -12)
    btn.BackgroundColor3= default and PURPLE or Color3.fromRGB(60, 60, 60)
    btn.Text            = ""
    btn.BorderSizePixel = 0
    btn.Parent          = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

    local circle = Instance.new("Frame")
    circle.Size            = UDim2.new(0, 18, 0, 18)
    circle.Position        = default and UDim2.new(0, 23, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
    circle.BackgroundColor3= Color3.fromRGB(255, 255, 255)
    circle.BorderSizePixel = 0
    circle.Parent          = btn
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)

    local state = default

    local function setVisual(v)
        if v then
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = PURPLE}):Play()
            TweenService:Create(circle, TweenInfo.new(0.2), {Position = UDim2.new(0, 23, 0.5, -9)}):Play()
        else
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}):Play()
            TweenService:Create(circle, TweenInfo.new(0.2), {Position = UDim2.new(0, 3, 0.5, -9)}):Play()
        end
    end

    btn.MouseButton1Click:Connect(function()
        state = not state
        setVisual(state)
        callback(state)
    end)

    return function(v) state = v; setVisual(v) end
end

local function makeSlider(parent, labelText, yPos, min, max, default, displayMult, callback)
    local frame = Instance.new("Frame")
    frame.Size            = UDim2.new(1, -20, 0, 52)
    frame.Position        = UDim2.new(0, 10, 0, yPos)
    frame.BackgroundColor3= CARD
    frame.BorderSizePixel = 0
    frame.Parent          = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local function fmt(v) return tostring(math.floor(v * displayMult * 1000) / 1000) end

    local lbl = Instance.new("TextLabel")
    lbl.Size             = UDim2.new(1, -20, 0, 20)
    lbl.Position         = UDim2.new(0, 12, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3       = Color3.fromRGB(255, 255, 255)
    lbl.Text             = labelText .. ": " .. fmt(default)
    lbl.Font             = Enum.Font.Gotham
    lbl.TextSize         = 12
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.Parent           = frame

    local track = Instance.new("Frame")
    track.Size            = UDim2.new(1, -24, 0, 6)
    track.Position        = UDim2.new(0, 12, 0, 32)
    track.BackgroundColor3= DIVCLR
    track.BorderSizePixel = 0
    track.Parent          = frame
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size            = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3= PURPLE
    fill.BorderSizePixel = 0
    fill.Parent          = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size            = UDim2.new(0, 14, 0, 14)
    knob.Position        = UDim2.new((default - min) / (max - min), -7, 0.5, -7)
    knob.BackgroundColor3= Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent          = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local sliderDragging = false
    knob.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then sliderDragging = true end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then sliderDragging = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if sliderDragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local rel   = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local value = min + (max - min) * rel
            fill.Size       = UDim2.new(rel, 0, 1, 0)
            knob.Position   = UDim2.new(rel, -7, 0.5, -7)
            lbl.Text        = labelText .. ": " .. fmt(value)
            callback(value)
        end
    end)
end

local function makeDropdown(parent, labelText, yPos, options, default, callback)
    local frame = Instance.new("Frame")
    frame.Size            = UDim2.new(1, -20, 0, 40)
    frame.Position        = UDim2.new(0, 10, 0, yPos)
    frame.BackgroundColor3= CARD
    frame.BorderSizePixel = 0
    frame.Parent          = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size             = UDim2.new(0.5, 0, 1, 0)
    lbl.Position         = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3       = Color3.fromRGB(255, 255, 255)
    lbl.Text             = labelText
    lbl.Font             = Enum.Font.Gotham
    lbl.TextSize         = 13
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.Parent           = frame

    local idx = 1
    for i, v in ipairs(options) do if v == default then idx = i end end

    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(0, 100, 0, 26)
    btn.Position         = UDim2.new(1, -110, 0.5, -13)
    btn.BackgroundColor3 = PURPLE
    btn.TextColor3       = Color3.fromRGB(255, 255, 255)
    btn.Text             = default
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = 12
    btn.BorderSizePixel  = 0
    btn.Parent           = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    btn.MouseButton1Click:Connect(function()
        idx      = idx % #options + 1
        btn.Text = options[idx]
        callback(options[idx])
    end)
end

-- ============================================================
--  PAGE CONTAINERS
-- ============================================================
local SM_CANVAS     = 330
local AIMBOT_CANVAS = 480  -- shorter now keybind row removed

local smContent = Instance.new("Frame")
smContent.Size            = UDim2.new(1, 0, 0, SM_CANVAS)
smContent.BackgroundTransparency = 1
smContent.Parent          = scrollFrame

local aimbotContent = Instance.new("Frame")
aimbotContent.Size            = UDim2.new(1, 0, 0, AIMBOT_CANVAS)
aimbotContent.BackgroundTransparency = 1
aimbotContent.Visible         = false
aimbotContent.Parent          = scrollFrame

-- ============================================================
--  SM HUB PAGE
-- ============================================================
makeLabel(smContent, "WAVE", 8, PURPLE)

local lastVoted = false
makeToggle(smContent, "Auto Skip Wave", 28, false, function(v)
    SETTINGS.AutoSkip = v
end)

makeDivider(smContent, 76)
makeLabel(smContent, "PLAYER", 84, PURPLE)

makeToggle(smContent, "Infinite Stamina", 104, false, function(v)
    SETTINGS.InfStamina = v
end)

makeDivider(smContent, 152)
makeLabel(smContent, "MOVEMENT", 160, PURPLE)

makeToggle(smContent, "Fly", 180, false, function(v)
    if v then startFly() else stopFly() end
end)

makeDivider(smContent, 228)
makeLabel(smContent, "CAMERA", 236, PURPLE)

makeSlider(smContent, "Field of View", 256, 70, 120, 70, 1, function(v)
    camera.FieldOfView = v
end)

-- ============================================================
--  AIMBOT PAGE
-- ============================================================
makeLabel(aimbotContent, "AIMBOT", 8, PURPLE)

aimbotToggleSync = makeToggle(aimbotContent, "Enabled  [Q]", 28, false, function(v)
    SETTINGS.Enabled = v
    fovCircle.Visible = v and expanded
end)

makeDivider(aimbotContent, 76)
makeLabel(aimbotContent, "AIM SETTINGS", 84, PURPLE)

makeSlider(aimbotContent, "FOV", 104, 50, 500, 200, 1, function(v)
    SETTINGS.FOV = v
    fovCircle.Radius = v
end)
makeSlider(aimbotContent, "Smoothness", 164, 0.001, 0.3, 0.12, 1, function(v)
    SETTINGS.Smoothness = v
end)

makeDivider(aimbotContent, 224)
makeLabel(aimbotContent, "TARGET", 232, PURPLE)

makeDropdown(aimbotContent, "Target Part", 250, {"Head", "UpperTorso", "HumanoidRootPart"}, "Head", function(v)
    SETTINGS.TargetPart = v
end)

makeDropdown(aimbotContent, "Priority", 298, {"Screen", "Distance"}, "Screen", function(v)
    SETTINGS.PriorityMode = v
end)

makeDivider(aimbotContent, 346)
makeLabel(aimbotContent, "EXTRAS", 354, PURPLE)

makeToggle(aimbotContent, "Wall Check", 372, true, function(v)
    SETTINGS.WallCheck = v
end)

makeToggle(aimbotContent, "Auto Shoot", 420, false, function(v)
    SETTINGS.AutoShoot = v
    if v then gunConfig = getGunConfig() end
end)

-- ============================================================
--  TAB SWITCHING
-- ============================================================
local expanded   = false
local currentTab = "sm"

local function switchTab(tab)
    currentTab = tab
    if tab == "sm" then
        smContent.Visible     = true
        aimbotContent.Visible = false
        scrollFrame.CanvasSize= UDim2.new(0, 0, 0, SM_CANVAS)
        TweenService:Create(tabSM,     TweenInfo.new(0.15), {BackgroundColor3 = PURPLE}):Play()
        TweenService:Create(tabAimbot, TweenInfo.new(0.15), {BackgroundColor3 = CARD}):Play()
        titleText.Text = "⚡ SM Hub"
    else
        smContent.Visible     = false
        aimbotContent.Visible = true
        scrollFrame.CanvasSize= UDim2.new(0, 0, 0, AIMBOT_CANVAS)
        TweenService:Create(tabSM,     TweenInfo.new(0.15), {BackgroundColor3 = CARD}):Play()
        TweenService:Create(tabAimbot, TweenInfo.new(0.15), {BackgroundColor3 = PURPLE}):Play()
        titleText.Text = "🎯 Aimbot"
    end
end

tabSM.MouseButton1Click:Connect(function()     switchTab("sm") end)
tabAimbot.MouseButton1Click:Connect(function() switchTab("aimbot") end)

-- ============================================================
--  MINIMIZE / EXPAND
-- ============================================================
minimizeBtn.MouseButton1Click:Connect(function()
    expanded = not expanded
    if expanded then
        tabBar.Visible      = true
        scrollFrame.Visible = true
        TweenService:Create(main, TweenInfo.new(0.3), {Size = UDim2.new(0, WIN_W, 0, 440)}):Play()
        minimizeBtn.Text    = "—"
        if currentTab == "aimbot" then
            fovCircle.Visible = SETTINGS.Enabled
        end
    else
        tabBar.Visible      = false
        scrollFrame.Visible = false
        TweenService:Create(main, TweenInfo.new(0.3), {Size = UDim2.new(0, WIN_W, 0, 45)}):Play()
        minimizeBtn.Text    = "+"
        fovCircle.Visible   = false
    end
end)

-- ============================================================
--  DRAGGING
-- ============================================================
local dragging, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging  = true
        dragStart = input.Position
        startPos  = main.Position
    end
end)
titleBar.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local d = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                   startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)
titleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

-- ============================================================
--  AUTO SKIP LOOP
-- ============================================================
task.spawn(function()
    while task.wait(0.1) do
        if SETTINGS.AutoSkip then
            local found = false
            for _, gui in ipairs(player.PlayerGui:GetDescendants()) do
                if (gui:IsA("TextButton") or gui:IsA("ImageButton"))
                   and gui.Text:find("NEXT WAVE") and gui.Visible then
                    found = true; break
                end
            end
            if found and not lastVoted then
                lastVoted = true
                waveRemote:FireServer("VoteSkip")
                task.wait(1)
                lastVoted = false
            end
        end
    end
end)

-- ============================================================
--  INFINITE STAMINA LOOP
-- ============================================================
RunService.Heartbeat:Connect(function()
    if SETTINGS.InfStamina and smHumanoid then
        local shifting = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
                      or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
        if shifting and smHumanoid.WalkSpeed < 28.8 then
            smHumanoid.WalkSpeed = 28.8
        end
    end
end)

-- ============================================================
--  AIMBOT – wall check & closest zombie
-- ============================================================
local function hasLineOfSight(from, to)
    return workspace:Raycast(from, to - from, rayParams) == nil
end

local function getClosestZombie()
    local closest, closestDist = nil, math.huge
    local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    local camPos = camera.CFrame.Position
    local char   = player.Character
    local hrp    = char and char:FindFirstChild("HumanoidRootPart")

    for _, zombie in ipairs(zombieFolder:GetChildren()) do
        local humanoid = zombie:FindFirstChild("Humanoid")
        local target   = zombie:FindFirstChild(SETTINGS.TargetPart)
        if not humanoid or not target or humanoid.Health <= 0 then continue end
        if SETTINGS.WallCheck and not hasLineOfSight(camPos, target.Position) then continue end

        if SETTINGS.PriorityMode == "Distance" then
            -- Closest to character, no FOV restriction
            local dist = hrp
                and (hrp.Position - target.Position).Magnitude
                or  (camPos - target.Position).Magnitude
            if dist < closestDist then
                closestDist = dist
                closest     = target
            end
        else
            -- Closest to crosshair, must be within FOV circle
            local screenPos, onScreen = camera:WorldToViewportPoint(target.Position)
            if not onScreen then continue end
            local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
            if screenDist > SETTINGS.FOV then continue end
            if screenDist < closestDist then
                closestDist = screenDist
                closest     = target
            end
        end
    end
    return closest
end

-- ============================================================
--  AIMBOT – auto-fire
--  Fires as fast as the gun's fireRate allows.
--  Also fires at ALL piercing targets simultaneously per shot
--  so piercing weapons hit multiple zombies at once.
-- ============================================================
local shootCooldown = false

local function internalShoot(primaryTarget)
    if shootCooldown then return end
    if not gunConfig then
        gunConfig = getGunConfig()
        if not gunConfig then return end
    end
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    shootCooldown = true
    local bulletId  = nextBulletId()
    local origin    = root.Position
    local piercing  = gunConfig.piercing or 1

    -- Fire at up to `piercing` targets so multi-hit guns deal full damage
    local hit = 0
    for _, zombie in ipairs(zombieFolder:GetChildren()) do
        if hit >= piercing then break end
        local humanoid = zombie:FindFirstChild("Humanoid")
        local target   = zombie:FindFirstChild(SETTINGS.TargetPart)
        if not humanoid or not target or humanoid.Health <= 0 then continue end
        bulletHitRemote:FireServer(target, gunConfig.name, bulletId, origin, target.Position)
        hit += 1
    end

    -- Cooldown matches gun fire rate exactly for maximum speed
    task.delay(gunConfig.fireRate, function()
        shootCooldown = false
    end)
end

-- ============================================================
--  AIMBOT – main loop
-- ============================================================
RunService.Heartbeat:Connect(function()
    fovCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    if not SETTINGS.Enabled then return end

    local target = getClosestZombie()
    if not target then return end

    local camPos    = camera.CFrame.Position
    local targetPos = target.Position

    if SETTINGS.Smoothness <= 0.002 then
        camera.CFrame = CFrame.new(camPos, targetPos)
    else
        local currentLook  = camera.CFrame.LookVector
        local desiredLook  = (targetPos - camPos).Unit
        local smoothedLook = currentLook:Lerp(desiredLook, SETTINGS.Smoothness)
        camera.CFrame = CFrame.new(camPos, camPos + smoothedLook)
    end

    if SETTINGS.AutoShoot then
        internalShoot(target)
    end
end)

-- ============================================================
print("SM Hub Combined loaded!")
