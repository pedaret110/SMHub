-- ============================================================
--  SM Hub  |  Wave + Stamina + Fly + Aimbot
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local waveRemote   = ReplicatedStorage:WaitForChild("WaveRemote")
local zombieFolder = workspace:WaitForChild("Zombies")

-- ============================================================
--  SETTINGS
-- ============================================================
local SETTINGS = {
    AutoSkip       = false,
    InfStamina     = false,
    Enabled        = false,
    Smoothness     = 0.12,
    TargetPart     = "Head",
    ActivationMode = "Hold",
    HoldKey        = Enum.KeyCode.Q,
    WallCheck      = true,
}

-- ============================================================
--  TOGGLE STATE
-- ============================================================
local toggleActive    = false
local aimbotToggleSync = nil

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == SETTINGS.HoldKey then
        if SETTINGS.ActivationMode == "Toggle" then
            toggleActive = not toggleActive
        end
    end
end)

-- ============================================================
--  RAYCAST FILTER
-- ============================================================
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
local function updateRayFilter(char)
    rayParams.FilterDescendantsInstances = {char, zombieFolder}
end
if player.Character then updateRayFilter(player.Character) end
player.CharacterAdded:Connect(function(char)
    updateRayFilter(char)
    SETTINGS.Enabled = false
    toggleActive = false
    if aimbotToggleSync then aimbotToggleSync(false) end
end)

-- ============================================================
--  STAMINA HOOK
-- ============================================================
local staminaBar    = player.PlayerGui:WaitForChild("SprintGui").Frame.Frame
local originalColor = Color3.new(0.313726, 0.784314, 0.470588)
local oldIndex
oldIndex = hookmetamethod(game, "__newindex", function(self, key, value)
    if SETTINGS.InfStamina and self == staminaBar then
        if key == "Size"             then return oldIndex(self, key, UDim2.new(1,0,1,0)) end
        if key == "BackgroundColor3" then return oldIndex(self, key, originalColor) end
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
local flying    = false
local bodyVel   = nil
local bodyGyro  = nil
local FLY_SPEED = 60

local function startFly()
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end
    hum.PlatformStand  = true
    bodyVel            = Instance.new("BodyVelocity")
    bodyVel.Velocity   = Vector3.zero
    bodyVel.MaxForce   = Vector3.new(1e5,1e5,1e5)
    bodyVel.Parent     = hrp
    bodyGyro           = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(1e5,1e5,1e5)
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
    bodyVel = nil; bodyGyro = nil
    if flying then task.wait(0.5); startFly() end
end)

RunService.Heartbeat:Connect(function()
    if not flying or not bodyVel or not bodyGyro then return end
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local move = Vector3.zero
    local cf   = camera.CFrame
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cf.LookVector  end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cf.LookVector  end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cf.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cf.RightVector end
    if move.Magnitude > 0 then
        bodyVel.Velocity = move.Unit * FLY_SPEED
        bodyGyro.CFrame  = CFrame.new(hrp.Position, hrp.Position + move)
    else
        bodyVel.Velocity = Vector3.zero
        bodyGyro.CFrame  = hrp.CFrame
    end
end)

-- ============================================================
--  GUI
-- ============================================================
local playerGui = player.PlayerGui
for _, n in ipairs({"SMHub","AimbotUI","CombinedHub"}) do
    if playerGui:FindFirstChild(n) then playerGui[n]:Destroy() end
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "CombinedHub"
screenGui.ResetOnSpawn   = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent         = playerGui

local PURPLE = Color3.fromRGB(120,40,200)
local DARK   = Color3.fromRGB(18,18,18)
local CARD   = Color3.fromRGB(28,28,28)
local DIVC   = Color3.fromRGB(50,50,50)
local WIN_W  = 260

local main = Instance.new("Frame")
main.Size             = UDim2.new(0,WIN_W,0,45)
main.Position         = UDim2.new(0,20,0.2,0)
main.BackgroundColor3 = DARK
main.BorderSizePixel  = 0
main.Parent           = screenGui
Instance.new("UICorner",main).CornerRadius = UDim.new(0,12)

local shadow = Instance.new("Frame")
shadow.Size                   = UDim2.new(1,10,1,10)
shadow.Position               = UDim2.new(0,-5,0,-5)
shadow.BackgroundColor3       = Color3.fromRGB(0,0,0)
shadow.BackgroundTransparency = 0.6
shadow.BorderSizePixel        = 0
shadow.ZIndex                 = main.ZIndex - 1
shadow.Parent                 = main
Instance.new("UICorner",shadow).CornerRadius = UDim.new(0,14)

local titleBar = Instance.new("Frame")
titleBar.Size             = UDim2.new(1,0,0,45)
titleBar.BackgroundColor3 = PURPLE
titleBar.BorderSizePixel  = 0
titleBar.Parent           = main
Instance.new("UICorner",titleBar).CornerRadius = UDim.new(0,12)

Instance.new("Frame", titleBar).Size             = UDim2.new(1,0,0.5,0)
local tf = titleBar:FindFirstChildOfClass("Frame")
tf.Position         = UDim2.new(0,0,0.5,0)
tf.BackgroundColor3 = PURPLE
tf.BorderSizePixel  = 0

local titleText = Instance.new("TextLabel")
titleText.Size                   = UDim2.new(1,-50,1,0)
titleText.Position               = UDim2.new(0,10,0,0)
titleText.BackgroundTransparency = 1
titleText.TextColor3             = Color3.fromRGB(255,255,255)
titleText.Text                   = "⚡ SM Hub"
titleText.Font                   = Enum.Font.GothamBold
titleText.TextSize               = 15
titleText.TextXAlignment         = Enum.TextXAlignment.Left
titleText.Parent                 = titleBar

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size                   = UDim2.new(0,30,0,30)
minimizeBtn.Position               = UDim2.new(1,-35,0,7)
minimizeBtn.BackgroundTransparency = 1
minimizeBtn.TextColor3             = Color3.fromRGB(255,255,255)
minimizeBtn.Text                   = "+"
minimizeBtn.Font                   = Enum.Font.GothamBold
minimizeBtn.TextSize               = 16
minimizeBtn.Parent                 = titleBar

-- Tabs
local tabBar = Instance.new("Frame")
tabBar.Size             = UDim2.new(1,-20,0,32)
tabBar.Position         = UDim2.new(0,10,0,50)
tabBar.BackgroundColor3 = CARD
tabBar.BorderSizePixel  = 0
tabBar.Visible          = false
tabBar.Parent           = main
Instance.new("UICorner",tabBar).CornerRadius = UDim.new(0,8)

local function makeTabBtn(text, xScale, active)
    local b = Instance.new("TextButton")
    b.Size             = UDim2.new(0.5,-4,1,-8)
    b.Position         = UDim2.new(xScale,4,0,4)
    b.BackgroundColor3 = active and PURPLE or CARD
    b.TextColor3       = Color3.fromRGB(255,255,255)
    b.Text             = text
    b.Font             = Enum.Font.GothamBold
    b.TextSize         = 12
    b.BorderSizePixel  = 0
    b.Parent           = tabBar
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,6)
    return b
end
local tabSM     = makeTabBtn("⚡ SM Hub", 0, true)
local tabAimbot = makeTabBtn("🎯 Aimbot", 0.5, false)

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size                   = UDim2.new(1,0,0,340)
scrollFrame.Position               = UDim2.new(0,0,0,88)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel        = 0
scrollFrame.ScrollBarThickness     = 3
scrollFrame.ScrollBarImageColor3   = PURPLE
scrollFrame.Visible                = false
scrollFrame.Parent                 = main

-- ============================================================
--  UI HELPERS
-- ============================================================
local function makeLabel(p, text, y, color)
    local l = Instance.new("TextLabel")
    l.Size               = UDim2.new(1,-20,0,18)
    l.Position           = UDim2.new(0,10,0,y)
    l.BackgroundTransparency = 1
    l.TextColor3         = color or Color3.fromRGB(150,150,150)
    l.Text               = text
    l.Font               = Enum.Font.GothamBold
    l.TextSize           = 11
    l.TextXAlignment     = Enum.TextXAlignment.Left
    l.Parent             = p
end

local function makeDivider(p, y)
    local d = Instance.new("Frame")
    d.Size             = UDim2.new(1,-20,0,1)
    d.Position         = UDim2.new(0,10,0,y)
    d.BackgroundColor3 = DIVC
    d.BorderSizePixel  = 0
    d.Parent           = p
end

local function makeToggle(p, text, y, default, cb)
    local f = Instance.new("Frame")
    f.Size             = UDim2.new(1,-20,0,40)
    f.Position         = UDim2.new(0,10,0,y)
    f.BackgroundColor3 = CARD
    f.BorderSizePixel  = 0
    f.Parent           = p
    Instance.new("UICorner",f).CornerRadius = UDim.new(0,8)

    local l = Instance.new("TextLabel")
    l.Size               = UDim2.new(1,-60,1,0)
    l.Position           = UDim2.new(0,12,0,0)
    l.BackgroundTransparency = 1
    l.TextColor3         = Color3.fromRGB(255,255,255)
    l.Text               = text
    l.Font               = Enum.Font.Gotham
    l.TextSize           = 13
    l.TextXAlignment     = Enum.TextXAlignment.Left
    l.Parent             = f

    local b = Instance.new("TextButton")
    b.Size             = UDim2.new(0,44,0,24)
    b.Position         = UDim2.new(1,-54,0.5,-12)
    b.BackgroundColor3 = default and PURPLE or Color3.fromRGB(60,60,60)
    b.Text             = ""
    b.BorderSizePixel  = 0
    b.Parent           = f
    Instance.new("UICorner",b).CornerRadius = UDim.new(1,0)

    local c = Instance.new("Frame")
    c.Size             = UDim2.new(0,18,0,18)
    c.Position         = default and UDim2.new(0,23,0.5,-9) or UDim2.new(0,3,0.5,-9)
    c.BackgroundColor3 = Color3.fromRGB(255,255,255)
    c.BorderSizePixel  = 0
    c.Parent           = b
    Instance.new("UICorner",c).CornerRadius = UDim.new(1,0)

    local state = default
    local function setV(v)
        if v then
            TweenService:Create(b,TweenInfo.new(0.2),{BackgroundColor3=PURPLE}):Play()
            TweenService:Create(c,TweenInfo.new(0.2),{Position=UDim2.new(0,23,0.5,-9)}):Play()
        else
            TweenService:Create(b,TweenInfo.new(0.2),{BackgroundColor3=Color3.fromRGB(60,60,60)}):Play()
            TweenService:Create(c,TweenInfo.new(0.2),{Position=UDim2.new(0,3,0.5,-9)}):Play()
        end
    end
    b.MouseButton1Click:Connect(function()
        state = not state; setV(state); cb(state)
    end)
    return function(v) state = v; setV(v) end
end

local function makeSlider(p, text, y, min, max, default, mult, cb)
    local f = Instance.new("Frame")
    f.Size             = UDim2.new(1,-20,0,52)
    f.Position         = UDim2.new(0,10,0,y)
    f.BackgroundColor3 = CARD
    f.BorderSizePixel  = 0
    f.Parent           = p
    Instance.new("UICorner",f).CornerRadius = UDim.new(0,8)

    local fmt = function(v) return tostring(math.floor(v*mult*1000)/1000) end

    local l = Instance.new("TextLabel")
    l.Size               = UDim2.new(1,-20,0,20)
    l.Position           = UDim2.new(0,12,0,4)
    l.BackgroundTransparency = 1
    l.TextColor3         = Color3.fromRGB(255,255,255)
    l.Text               = text..": "..fmt(default)
    l.Font               = Enum.Font.Gotham
    l.TextSize           = 12
    l.TextXAlignment     = Enum.TextXAlignment.Left
    l.Parent             = f

    local track = Instance.new("Frame")
    track.Size             = UDim2.new(1,-24,0,6)
    track.Position         = UDim2.new(0,12,0,32)
    track.BackgroundColor3 = DIVC
    track.BorderSizePixel  = 0
    track.Parent           = f
    Instance.new("UICorner",track).CornerRadius = UDim.new(1,0)

    local fill = Instance.new("Frame")
    fill.Size             = UDim2.new((default-min)/(max-min),0,1,0)
    fill.BackgroundColor3 = PURPLE
    fill.BorderSizePixel  = 0
    fill.Parent           = track
    Instance.new("UICorner",fill).CornerRadius = UDim.new(1,0)

    local knob = Instance.new("Frame")
    knob.Size             = UDim2.new(0,14,0,14)
    knob.Position         = UDim2.new((default-min)/(max-min),-7,0.5,-7)
    knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
    knob.BorderSizePixel  = 0
    knob.Parent           = track
    Instance.new("UICorner",knob).CornerRadius = UDim.new(1,0)

    local drag = false
    knob.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = true end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local val = min + (max-min) * rel
            fill.Size     = UDim2.new(rel,0,1,0)
            knob.Position = UDim2.new(rel,-7,0.5,-7)
            l.Text        = text..": "..fmt(val)
            cb(val)
        end
    end)
end

local function makeDropdown(p, text, y, options, default, cb)
    local f = Instance.new("Frame")
    f.Size             = UDim2.new(1,-20,0,40)
    f.Position         = UDim2.new(0,10,0,y)
    f.BackgroundColor3 = CARD
    f.BorderSizePixel  = 0
    f.Parent           = p
    Instance.new("UICorner",f).CornerRadius = UDim.new(0,8)

    local l = Instance.new("TextLabel")
    l.Size               = UDim2.new(0.5,0,1,0)
    l.Position           = UDim2.new(0,12,0,0)
    l.BackgroundTransparency = 1
    l.TextColor3         = Color3.fromRGB(255,255,255)
    l.Text               = text
    l.Font               = Enum.Font.Gotham
    l.TextSize           = 13
    l.TextXAlignment     = Enum.TextXAlignment.Left
    l.Parent             = f

    local idx = 1
    for i,v in ipairs(options) do if v == default then idx = i end end

    local b = Instance.new("TextButton")
    b.Size             = UDim2.new(0,100,0,26)
    b.Position         = UDim2.new(1,-110,0.5,-13)
    b.BackgroundColor3 = PURPLE
    b.TextColor3       = Color3.fromRGB(255,255,255)
    b.Text             = default
    b.Font             = Enum.Font.GothamBold
    b.TextSize         = 12
    b.BorderSizePixel  = 0
    b.Parent           = f
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,6)

    b.MouseButton1Click:Connect(function()
        idx = idx % #options + 1
        b.Text = options[idx]
        cb(options[idx])
    end)
end

local function makeKeybind(p, text, y, default, cb)
    local f = Instance.new("Frame")
    f.Size             = UDim2.new(1,-20,0,40)
    f.Position         = UDim2.new(0,10,0,y)
    f.BackgroundColor3 = CARD
    f.BorderSizePixel  = 0
    f.Parent           = p
    Instance.new("UICorner",f).CornerRadius = UDim.new(0,8)

    local l = Instance.new("TextLabel")
    l.Size               = UDim2.new(0.5,0,1,0)
    l.Position           = UDim2.new(0,12,0,0)
    l.BackgroundTransparency = 1
    l.TextColor3         = Color3.fromRGB(255,255,255)
    l.Text               = text
    l.Font               = Enum.Font.Gotham
    l.TextSize           = 13
    l.TextXAlignment     = Enum.TextXAlignment.Left
    l.Parent             = f

    local listening = false
    local b = Instance.new("TextButton")
    b.Size             = UDim2.new(0,100,0,26)
    b.Position         = UDim2.new(1,-110,0.5,-13)
    b.BackgroundColor3 = PURPLE
    b.TextColor3       = Color3.fromRGB(255,255,255)
    b.Text             = default.Name
    b.Font             = Enum.Font.GothamBold
    b.TextSize         = 12
    b.BorderSizePixel  = 0
    b.Parent           = f
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,6)

    b.MouseButton1Click:Connect(function()
        listening          = true
        b.Text             = "..."
        b.BackgroundColor3 = Color3.fromRGB(200,150,0)
    end)

    UserInputService.InputBegan:Connect(function(input)
        if listening and input.UserInputType == Enum.UserInputType.Keyboard then
            listening          = false
            b.Text             = input.KeyCode.Name
            b.BackgroundColor3 = PURPLE
            cb(input.KeyCode)
        end
    end)
end

-- ============================================================
--  PAGE CONTAINERS
-- ============================================================
local SM_CANVAS     = 340
local AIMBOT_CANVAS = 310

local smContent = Instance.new("Frame")
smContent.Size                = UDim2.new(1,0,0,SM_CANVAS)
smContent.BackgroundTransparency = 1
smContent.Parent              = scrollFrame

local aimbotContent = Instance.new("Frame")
aimbotContent.Size                = UDim2.new(1,0,0,AIMBOT_CANVAS)
aimbotContent.BackgroundTransparency = 1
aimbotContent.Visible             = false
aimbotContent.Parent              = scrollFrame

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
makeSlider(smContent, "Fly Speed", 228, 10, 200, 60, 1, function(v)
    FLY_SPEED = v
end)

makeDivider(smContent, 288)
makeLabel(smContent, "CAMERA", 296, PURPLE)
makeSlider(smContent, "Field of View", 314, 70, 120, 70, 1, function(v)
    camera.FieldOfView = v
end)

-- ============================================================
--  AIMBOT PAGE
-- ============================================================
makeLabel(aimbotContent, "AIMBOT", 8, PURPLE)
aimbotToggleSync = makeToggle(aimbotContent, "Enabled", 28, false, function(v)
    SETTINGS.Enabled = v
    if not v then toggleActive = false end
end)

makeDivider(aimbotContent, 76)
makeLabel(aimbotContent, "AIM SETTINGS", 84, PURPLE)
makeSlider(aimbotContent, "Smoothness", 104, 0.001, 0.3, 0.12, 1, function(v)
    SETTINGS.Smoothness = v
end)

makeDivider(aimbotContent, 164)
makeLabel(aimbotContent, "TARGET", 172, PURPLE)
makeDropdown(aimbotContent, "Target Part", 190, {"Head","UpperTorso","HumanoidRootPart"}, "Head", function(v)
    SETTINGS.TargetPart = v
end)

makeDivider(aimbotContent, 238)
makeLabel(aimbotContent, "KEYBIND", 246, PURPLE)
makeKeybind(aimbotContent, "Trigger Key", 264, Enum.KeyCode.Q, function(v)
    SETTINGS.HoldKey = v
end)
makeDropdown(aimbotContent, "Mode", 312, {"Hold","Toggle"}, "Hold", function(v)
    SETTINGS.ActivationMode = v
    toggleActive = false
end)

-- ============================================================
--  TAB SWITCHING
-- ============================================================
local function switchTab(tab)
    if tab == "sm" then
        smContent.Visible      = true
        aimbotContent.Visible  = false
        scrollFrame.CanvasSize = UDim2.new(0,0,0,SM_CANVAS)
        TweenService:Create(tabSM,    TweenInfo.new(0.15),{BackgroundColor3=PURPLE}):Play()
        TweenService:Create(tabAimbot,TweenInfo.new(0.15),{BackgroundColor3=CARD}):Play()
        titleText.Text = "⚡ SM Hub"
    else
        smContent.Visible      = false
        aimbotContent.Visible  = true
        scrollFrame.CanvasSize = UDim2.new(0,0,0,AIMBOT_CANVAS)
        TweenService:Create(tabSM,    TweenInfo.new(0.15),{BackgroundColor3=CARD}):Play()
        TweenService:Create(tabAimbot,TweenInfo.new(0.15),{BackgroundColor3=PURPLE}):Play()
        titleText.Text = "🎯 Aimbot"
    end
end

tabSM.MouseButton1Click:Connect(function()     switchTab("sm") end)
tabAimbot.MouseButton1Click:Connect(function() switchTab("aimbot") end)

-- ============================================================
--  MINIMIZE
-- ============================================================
local expanded = false
minimizeBtn.MouseButton1Click:Connect(function()
    expanded = not expanded
    if expanded then
        tabBar.Visible      = true
        scrollFrame.Visible = true
        TweenService:Create(main,TweenInfo.new(0.3),{Size=UDim2.new(0,WIN_W,0,440)}):Play()
        minimizeBtn.Text    = "—"
    else
        tabBar.Visible      = false
        scrollFrame.Visible = false
        TweenService:Create(main,TweenInfo.new(0.3),{Size=UDim2.new(0,WIN_W,0,45)}):Play()
        minimizeBtn.Text    = "+"
    end
end)

-- ============================================================
--  DRAG
-- ============================================================
local dragging, dragStart, startPos
titleBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = i.Position; startPos = main.Position
    end
end)
titleBar.InputChanged:Connect(function(i)
    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = i.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)
titleBar.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

-- ============================================================
--  AUTO SKIP LOOP
-- ============================================================
task.spawn(function()
    while task.wait(0.1) do
        if SETTINGS.AutoSkip then
            local found = false
            for _, gui in ipairs(player.PlayerGui:GetDescendants()) do
                if gui:IsA("TextButton") and gui.Text:find("NEXT WAVE") and gui.Visible then
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
--  STAMINA LOOP
-- ============================================================
RunService.Heartbeat:Connect(function()
    if SETTINGS.InfStamina and smHumanoid then
        local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
                   or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
        if shift and smHumanoid.WalkSpeed < 28.8 then
            smHumanoid.WalkSpeed = 28.8
        end
    end
end)

-- ============================================================
--  AIMBOT
-- ============================================================
local function getClosestZombie()
    local closest, closestDist = nil, math.huge
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    for _, zombie in ipairs(zombieFolder:GetChildren()) do
        local hum = zombie:FindFirstChild("Humanoid")
        local tgt = zombie:FindFirstChild(SETTINGS.TargetPart)
        if not hum or not tgt or hum.Health <= 0 then continue end
        if SETTINGS.WallCheck then
            local result = workspace:Raycast(hrp.Position, tgt.Position - hrp.Position, rayParams)
            if result then continue end
        end
        local dist = (hrp.Position - tgt.Position).Magnitude
        if dist < closestDist then
            closestDist = dist
            closest     = tgt
        end
    end
    return closest
end

RunService.Heartbeat:Connect(function()
    if not SETTINGS.Enabled then return end

    local shouldAim = (SETTINGS.ActivationMode == "Hold" and UserInputService:IsKeyDown(SETTINGS.HoldKey))
                   or (SETTINGS.ActivationMode == "Toggle" and toggleActive)
    if not shouldAim then return end

    local target = getClosestZombie()
    if not target then return end

    local camPos    = camera.CFrame.Position
    local targetPos = target.Position

    if SETTINGS.Smoothness <= 0.002 then
        camera.CFrame = CFrame.new(camPos, targetPos)
    else
        local cur     = camera.CFrame.LookVector
        local des     = (targetPos - camPos).Unit
        local smooth  = cur:Lerp(des, SETTINGS.Smoothness)
        camera.CFrame = CFrame.new(camPos, camPos + smooth)
    end
end)

print("✅ SM Hub loaded!")
