local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local zombieFolder = workspace:WaitForChild("Zombies")
local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
local humanoidRef = player.Character and player.Character:FindFirstChild("Humanoid")
player.CharacterAdded:Connect(function(char)
    rootPart    = char:WaitForChild("HumanoidRootPart")
    humanoidRef = char:WaitForChild("Humanoid")
end)

local SETTINGS_AUTORUN = {
    Enabled       = false,
    SafeDistance  = 20, -- studs
}

local SETTINGS = {
    Enabled    = false,
    FOV        = 200,
    Smoothness = 0.3,
    TargetPart = "Head",
    WallCheck  = false,
    AutoShoot  = false,
}

-- V2 settings (camera-lock style, fixed from theirs)
local SETTINGS_V2 = {
    Enabled          = false,
    ToggleActive     = false,
    FovEnabled       = false,
    FOV              = 150,
    WallCheck        = false,
    TriggerBot       = false,
    WorldMode        = false,
    TrackWhileMoving = false,
}

local cameraModeLocked = false -- track if we set first person, so we only do it once

-- ============================================================
--  FOV CIRCLE
-- ============================================================
local fovCircle = Drawing.new("Circle")
fovCircle.Radius    = SETTINGS.FOV
fovCircle.Color     = Color3.fromRGB(120, 40, 200)
fovCircle.Thickness = 1.5
fovCircle.Filled    = false
fovCircle.NumSides  = 64
fovCircle.Visible   = false

-- V2 FOV circle
local fovCircleV2 = Drawing.new("Circle")
fovCircleV2.Radius    = SETTINGS_V2.FOV
fovCircleV2.Color     = Color3.fromRGB(255, 80, 80)
fovCircleV2.Thickness = 1.5
fovCircleV2.Filled    = false
fovCircleV2.NumSides  = 64
fovCircleV2.Visible   = false

-- ============================================================
--  WALL CHECK
-- ============================================================
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function updateFilter()
    local char = player.Character
    rayParams.FilterDescendantsInstances = char and {char, zombieFolder} or {zombieFolder}
end
updateFilter()
player.CharacterAdded:Connect(updateFilter)

local function hasLineOfSight(from, to)
    return workspace:Raycast(from, to - from, rayParams) == nil
end

-- ============================================================
--  CLOSEST ZOMBIE
-- ============================================================
local function getClosestZombie()
    local closest, closestDist = nil, SETTINGS.FOV
    local mousePos = UserInputService:GetMouseLocation()
    local camPos = camera.CFrame.Position

    for _, zombie in ipairs(zombieFolder:GetChildren()) do
        local humanoid = zombie:FindFirstChild("Humanoid")
        local target   = zombie:FindFirstChild(SETTINGS.TargetPart)
        if not humanoid or not target or humanoid.Health <= 0 then continue end
        if SETTINGS.WallCheck and not hasLineOfSight(camPos, target.Position) then continue end

        local screenPos, onScreen = camera:WorldToViewportPoint(target.Position)
        if not onScreen then continue end

        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
        if dist < closestDist then
            closestDist = dist
            closest = target
        end
    end

    return closest
end

-- ============================================================
--  WINDOW
-- ============================================================
local Window = Library:CreateWindow({
    Title = "Aimbot",
    Footer = "PvE Solo",
    ShowCustomCursor = true,
    NotifySide = "Right",
})

local Tabs = {
    Main = Window:AddTab("Aimbot", "crosshair"),
    V2 = Window:AddTab("Aimbot V2", "crosshair"),
    ["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

local AimGroup = Tabs.Main:AddLeftGroupbox("Aimbot")
local ConfigGroup = Tabs.Main:AddRightGroupbox("Settings")

-- ============================================================
--  AIMBOT TOGGLE + KEYBIND
-- ============================================================
AimGroup:AddToggle("AimbotEnabled", {
    Text    = "Enable Aimbot",
    Default = false,
    Tooltip = "Toggle aimbot on or off",
    Callback = function(v)
        SETTINGS.Enabled = v
        fovCircle.Visible = v
    end,
}):AddKeyPicker("AimbotKey", {
    Default = "MB2",
    Mode    = "Toggle",
    Text    = "Aimbot Toggle Key",
    SyncToggleState = true,
    Callback = function(v)
        SETTINGS.Enabled = v
        fovCircle.Visible = v
    end,
})

-- ============================================================
--  AUTO SHOOT + KEYBIND
-- ============================================================
AimGroup:AddToggle("AutoShoot", {
    Text    = "Auto Shoot",
    Default = false,
    Tooltip = "Automatically clicks when locked onto target",
    Callback = function(v)
        SETTINGS.AutoShoot = v
    end,
}):AddKeyPicker("AutoShootKey", {
    Default = "MB1",
    Mode    = "Hold",
    Text    = "Auto Shoot Key",
    NoUI    = true,
})

-- ============================================================
--  WALL CHECK
-- ============================================================
AimGroup:AddToggle("WallCheck", {
    Text    = "Wall Check",
    Default = false,
    Tooltip = "Only lock onto visible targets",
    Callback = function(v)
        SETTINGS.WallCheck = v
    end,
})

-- ============================================================
--  FOV SLIDER
-- ============================================================
ConfigGroup:AddSlider("FOVSlider", {
    Text    = "FOV",
    Default = 200,
    Min     = 50,
    Max     = 600,
    Rounding = 0,
    Tooltip = "Aimbot detection radius in pixels",
    Callback = function(v)
        SETTINGS.FOV = v
        fovCircle.Radius = v
    end,
})

-- ============================================================
--  SMOOTHNESS SLIDER
-- ============================================================
ConfigGroup:AddSlider("SmoothnessSlider", {
    Text    = "Smoothness",
    Default = 30,
    Min     = 1,
    Max     = 100,
    Rounding = 0,
    Tooltip = "Higher = smoother, Lower = snappier",
    Callback = function(v)
        SETTINGS.Smoothness = v / 100
    end,
})

-- ============================================================
--  TARGET PART DROPDOWN
-- ============================================================
ConfigGroup:AddDropdown("TargetPart", {
    Text    = "Target Part",
    Values  = {"Head", "UpperTorso", "HumanoidRootPart"},
    Default = 1,
    Tooltip = "Which part of the zombie to aim at",
    Callback = function(v)
        SETTINGS.TargetPart = v
    end,
})

-- ============================================================
--  FOV CIRCLE COLOR
-- ============================================================
ConfigGroup:AddLabel("FOV Circle Color"):AddColorPicker("FOVColor", {
    Default = Color3.fromRGB(120, 40, 200),
    Callback = function(v)
        fovCircle.Color = v
    end,
})

-- ============================================================
--  UI SETTINGS
-- ============================================================
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu")
MenuGroup:AddLabel("Menu Keybind"):AddKeyPicker("MenuKeybind", {
    Default = "RightShift",
    NoUI    = true,
    Text    = "Menu keybind",
})
MenuGroup:AddButton("Unload", function()
    Library:Unload()
end)

Library.ToggleKeybind = Options.MenuKeybind
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})
ThemeManager:SetFolder("AimbotHub")
SaveManager:SetFolder("AimbotHub/game")
SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])

-- ============================================================
--  MAIN LOOP
-- ============================================================
local shootCooldown = false

RunService.Heartbeat:Connect(function()
    fovCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    if not SETTINGS.Enabled then return end

    local target = getClosestZombie()
    if not target then return end

    local screenPos, onScreen = camera:WorldToViewportPoint(target.Position)
    if not onScreen then return end

    local targetScreen = Vector2.new(screenPos.X, screenPos.Y)
    local mousePos     = UserInputService:GetMouseLocation()
    local delta        = targetScreen - mousePos

    mousemoverel(delta.X * SETTINGS.Smoothness, delta.Y * SETTINGS.Smoothness)

    if SETTINGS.AutoShoot and not shootCooldown then
        local dist = delta.Magnitude
        if dist < 15 then
            shootCooldown = true
            mouse1click()
            task.delay(0.1, function()
                shootCooldown = false
            end)
        end
    end
end)

-- ============================================================
--  V2 CLOSEST ZOMBIE (supports world mode + FOV mode)
-- ============================================================
local function getClosestZombieV2()
    local zombies = workspace:FindFirstChild("Zombies")
    if not zombies then return nil end

    local closest, closestDist = nil, math.huge
    local camPos = camera.CFrame.Position
    local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)

    for _, zombie in ipairs(zombies:GetChildren()) do
        local humanoid = zombie:FindFirstChildOfClass("Humanoid")
        local head     = zombie:FindFirstChild("Head") or zombie:FindFirstChild("HumanoidRootPart")
        if not humanoid or not head or humanoid.Health <= 0 then continue end
        if SETTINGS_V2.WallCheck and not hasLineOfSight(camPos, head.Position) then continue end

        if SETTINGS_V2.WorldMode then
            -- world distance mode
            local dist = (camPos - head.Position).Magnitude
            if dist < closestDist then
                closestDist = dist
                closest = zombie
            end
        else
            -- screen distance mode (closest to crosshair)
            local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
            if not onScreen then continue end
            local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
            if SETTINGS_V2.FovEnabled and dist > SETTINGS_V2.FOV then continue end
            if dist < closestDist then
                closestDist = dist
                closest = zombie
            end
        end
    end

    return closest
end

-- ============================================================
--  V2 TAB UI
-- ============================================================
local V2AimGroup    = Tabs.V2:AddLeftGroupbox("Aimbot V2")
local V2ConfigGroup = Tabs.V2:AddRightGroupbox("Settings")

V2AimGroup:AddToggle("V2Enabled", {
    Text    = "Enable V2 Aimbot",
    Default = false,
    Tooltip = "Master switch for V2 aimbot (use Toggle Keybind to activate)",
    Callback = function(v)
        SETTINGS_V2.Enabled = v
        if not v then
            -- restore camera on disable
            if cameraModeLocked then
                player.CameraMode = Enum.CameraMode.Classic
                cameraModeLocked = false
            end
        end
    end,
})

V2AimGroup:AddToggle("V2TriggerBot", {
    Text    = "Trigger Bot",
    Default = false,
    Tooltip = "Auto clicks when locked onto a zombie",
    Callback = function(v)
        SETTINGS_V2.TriggerBot = v
    end,
})

V2AimGroup:AddToggle("V2WallCheck", {
    Text    = "Wall Check",
    Default = false,
    Tooltip = "Only lock onto visible zombies",
    Callback = function(v)
        SETTINGS_V2.WallCheck = v
    end,
})

V2AimGroup:AddToggle("V2WorldMode", {
    Text    = "World Distance Mode",
    Default = false,
    Tooltip = "Target closest zombie by world distance instead of crosshair",
    Callback = function(v)
        SETTINGS_V2.WorldMode = v
    end,
})

V2AimGroup:AddLabel("Toggle Keybind"):AddKeyPicker("V2ToggleKey", {
    Default  = "E",
    Mode     = "Toggle",
    Text     = "V2 Toggle Key",
    Tooltip  = "Press to toggle V2 aimbot on/off",
    Callback = function(v)
        SETTINGS_V2.ToggleActive = v
        -- restore camera if toggled off
        if not v and cameraModeLocked then
            player.CameraMode = Enum.CameraMode.Classic
            cameraModeLocked = false
        end
    end,
})

V2ConfigGroup:AddToggle("V2FovEnabled", {
    Text    = "Enable FOV Limit",
    Default = false,
    Tooltip = "Only target zombies within the FOV circle",
    Callback = function(v)
        SETTINGS_V2.FovEnabled = v
        fovCircleV2.Visible = v and SETTINGS_V2.Enabled
    end,
})

V2ConfigGroup:AddSlider("V2FOVSlider", {
    Text     = "FOV Size",
    Default  = 150,
    Min      = 50,
    Max      = 600,
    Rounding = 0,
    Tooltip  = "V2 detection radius in pixels",
    Callback = function(v)
        SETTINGS_V2.FOV = v
        fovCircleV2.Radius = v
    end,
})

V2ConfigGroup:AddLabel("FOV Circle Color"):AddColorPicker("V2FOVColor", {
    Default = Color3.fromRGB(255, 80, 80),
    Callback = function(v)
        fovCircleV2.Color = v
    end,
})

V2ConfigGroup:AddToggle("V2TrackWhileMoving", {
    Text    = "Track While Moving",
    Default = false,
    Tooltip = "Re-locks aim after each auto-run step so you keep hitting while moving",
    Callback = function(v)
        SETTINGS_V2.TrackWhileMoving = v
    end,
})

-- ============================================================
--  V2 MAIN LOOP (RenderStepped, fixed freeze issues)
-- ============================================================
local v2ShootCooldown = false

RunService.RenderStepped:Connect(function()
    -- update V2 FOV circle position
    fovCircleV2.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)

    if not SETTINGS_V2.Enabled or not SETTINGS_V2.ToggleActive then return end

    local zombie = getClosestZombieV2()
    if not zombie then return end

    local head = zombie:FindFirstChild("Head") or zombie:FindFirstChild("HumanoidRootPart")
    if not head then return end

    local humanoid = zombie:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end

    -- lock first person ONCE when activating, not every frame
    if not cameraModeLocked then
        player.CameraMode = Enum.CameraMode.LockFirstPerson
        cameraModeLocked = true
    end

    -- only update camera CFrame if target moved enough (prevents freeze from constant updates)
    local targetPos = head.Position
    local currentLook = camera.CFrame.LookVector
    local toTarget = (targetPos - camera.CFrame.Position).Unit
    if currentLook:Dot(toTarget) < 0.9999 then
        camera.CFrame = CFrame.lookAt(camera.CFrame.Position, targetPos)
    end

    -- trigger bot
    if SETTINGS_V2.TriggerBot and not v2ShootCooldown then
        v2ShootCooldown = true
        mouse1press()
        task.delay(0.1, function()
            mouse1release()
            v2ShootCooldown = false
        end)
    end
end)


-- ============================================================
--  ESP TAB
-- ============================================================
local ESPTab         = Window:AddTab("ESP", "eye")
local ZombieESPGroup = ESPTab:AddLeftGroupbox("Zombie ESP")
local PlayerESPGroup = ESPTab:AddRightGroupbox("Player ESP")

local SETTINGS_ESP = {
    ZombieESP = false,
    PlayerESP = false,
}

-- Storage for created ESP objects so we can clean them up
local zombieESPData  = {} -- [model] = { highlight, billboard, originalColor, originalMaterial, originalTransparency }
local playerDrawings = {} -- [player] = Drawing text

-- ============================================================
--  ZOMBIE ESP HELPERS
-- ============================================================
local function removeZombieESP(model)
    local data = zombieESPData[model]
    if not data then return end
    -- restore HumanoidRootPart appearance
    pcall(function()
        local hrp = model:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.BrickColor     = data.originalColor
            hrp.Material       = data.originalMaterial
            hrp.Transparency   = data.originalTransparency
            hrp.CanCollide     = true
        end
    end)
    pcall(function()
        if data.highlight and data.highlight.Parent then
            data.highlight:Destroy()
        end
    end)
    pcall(function()
        if data.billboard and data.billboard.Parent then
            data.billboard:Destroy()
        end
    end)
    zombieESPData[model] = nil
end

local function addZombieESP(model)
    if not model:IsA("Model") then return end
    if zombieESPData[model] then return end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local hrp      = model:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp or humanoid.Health <= 0 then return end

    local data = {
        originalColor        = hrp.BrickColor,
        originalMaterial     = hrp.Material,
        originalTransparency = hrp.Transparency,
    }

    -- Highlight
    pcall(function()
        local hl = Instance.new("Highlight")
        hl.Name               = "_ESP_HL"
        hl.Adornee            = model
        hl.FillColor          = Color3.fromRGB(255, 50, 50)
        hl.OutlineColor       = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency   = 0.4
        hl.OutlineTransparency = 0
        hl.DepthMode          = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent             = model
        data.highlight        = hl
    end)

    -- Billboard health label
    pcall(function()
        local bb = Instance.new("BillboardGui")
        bb.Name         = "_ESP_BB"
        bb.Adornee      = hrp
        bb.AlwaysOnTop  = true
        bb.Size         = UDim2.new(0, 150, 0, 44)
        bb.StudsOffset  = Vector3.new(0, 3, 0)
        bb.Parent       = hrp

        local lbl = Instance.new("TextLabel")
        lbl.Name                 = "Label"
        lbl.Size                 = UDim2.fromScale(1, 1)
        lbl.BackgroundTransparency = 1
        lbl.Font                 = Enum.Font.GothamBold
        lbl.TextSize             = 13
        lbl.TextColor3           = Color3.new(1, 1, 1)
        lbl.TextStrokeColor3     = Color3.new(0, 0, 0)
        lbl.TextStrokeTransparency = 0.3
        lbl.Parent               = bb

        data.billboard = bb
        data.label     = lbl
    end)

    zombieESPData[model] = data

    humanoid.Died:Connect(function()
        task.wait(0.5)
        removeZombieESP(model)
    end)
end

local function clearAllZombieESP()
    for model in pairs(zombieESPData) do
        removeZombieESP(model)
    end
end

local function initZombieESP()
    local folder = workspace:FindFirstChild("Zombies")
    if not folder then return end
    for _, child in ipairs(folder:GetChildren()) do
        addZombieESP(child)
    end
end

-- Hook zombie folder for new spawns
local zombieFolder2 = workspace:FindFirstChild("Zombies")
local function hookZombieFolder(folder)
    folder.ChildAdded:Connect(function(child)
        if SETTINGS_ESP.ZombieESP then
            task.wait(0.2)
            addZombieESP(child)
        end
    end)
    folder.ChildRemoved:Connect(function(child)
        removeZombieESP(child)
    end)
end

if zombieFolder2 then
    hookZombieFolder(zombieFolder2)
else
    workspace.ChildAdded:Connect(function(child)
        if child.Name == "Zombies" then
            hookZombieFolder(child)
        end
    end)
end

-- Update health labels every heartbeat
RunService.Heartbeat:Connect(function()
    if not SETTINGS_ESP.ZombieESP then return end
    for model, data in pairs(zombieESPData) do
        if not data.label then continue end
        local humanoid = model:FindFirstChildOfClass("Humanoid")
        local hrp      = model:FindFirstChild("HumanoidRootPart")
        if not humanoid or not hrp then continue end
        local dist = math.floor((camera.CFrame.Position - hrp.Position).Magnitude)
        data.label.Text = string.format("%s\n❤ %d/%d  •  %dm", model.Name, math.ceil(humanoid.Health), math.ceil(humanoid.MaxHealth), dist)
    end
end)

-- ============================================================
--  PLAYER ESP HELPERS
-- ============================================================
local function removePlayerESP(p)
    local drawing = playerDrawings[p]
    if drawing then
        pcall(function() drawing:Remove() end)
        playerDrawings[p] = nil
    end
end

local function clearAllPlayerESP()
    for p in pairs(playerDrawings) do
        removePlayerESP(p)
    end
end

Players.PlayerRemoving:Connect(removePlayerESP)

RunService.RenderStepped:Connect(function()
    if not SETTINGS_ESP.PlayerESP then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p == player then continue end
        if not p.Character then continue end
        local head = p.Character:FindFirstChild("Head")
        if not head then continue end

        local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)

        if not playerDrawings[p] then
            local d = Drawing.new("Text")
            d.Visible      = false
            d.Size         = 14
            d.Color        = Color3.fromRGB(0, 255, 180)
            d.Transparency = 1
            d.ZIndex       = 2
            d.Center       = true
            d.Font         = 3
            d.Outline      = true
            d.OutlineColor = Color3.new(0, 0, 0)
            playerDrawings[p] = d
        end

        local d = playerDrawings[p]
        d.Visible = onScreen
        if onScreen then
            local dist = math.floor((camera.CFrame.Position - head.Position).Magnitude)
            d.Position = Vector2.new(screenPos.X, screenPos.Y - 20)
            d.Text     = string.format("%s [%dm]", p.Name, dist)
        end
    end
end)

-- ============================================================
--  ESP UI
-- ============================================================
ZombieESPGroup:AddToggle("ZombieESP", {
    Text    = "Zombie ESP",
    Default = false,
    Tooltip = "Highlight zombies with health labels through walls",
    Callback = function(v)
        SETTINGS_ESP.ZombieESP = v
        if v then initZombieESP() else clearAllZombieESP() end
    end,
})

PlayerESPGroup:AddToggle("PlayerESP", {
    Text    = "Player ESP",
    Default = false,
    Tooltip = "Show player names and distance",
    Callback = function(v)
        SETTINGS_ESP.PlayerESP = v
        if not v then clearAllPlayerESP() end
    end,
})

-- ============================================================
--  AUTO RUN LOGIC
-- ============================================================
local autoRunRayParams = RaycastParams.new()
autoRunRayParams.FilterType = Enum.RaycastFilterType.Exclude

local function updateAutoRunFilter()
    local char = player.Character
    local zombies = workspace:FindFirstChild("Zombies")
    autoRunRayParams.FilterDescendantsInstances = char and zombies and {char, zombies} or {workspace}
end
updateAutoRunFilter()
player.CharacterAdded:Connect(updateAutoRunFilter)

local function getEscapeDirection()
    local zombies = workspace:FindFirstChild("Zombies")
    if not zombies or not rootPart then return nil end

    local myPos = rootPart.Position
    local threat = Vector3.new(0, 0, 0)
    local count  = 0

    for _, zombie in ipairs(zombies:GetChildren()) do
        local hrp = zombie:FindFirstChild("HumanoidRootPart")
        local hum = zombie:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then continue end
        local dist = (myPos - hrp.Position).Magnitude
        if dist <= SETTINGS_AUTORUN.SafeDistance then
            -- weight closer zombies more heavily
            local weight = 1 / math.max(dist, 0.1)
            threat = threat + (myPos - hrp.Position).Unit * weight
            count  = count + 1
        end
    end

    if count == 0 then return nil end
    return threat.Unit
end

local function findClearDirection(baseDir)
    if not rootPart then return nil end
    local origin  = rootPart.Position
    local checkDist = 5 -- studs ahead to check for walls

    -- try base direction first, then fan out in steps
    local angles = {0, 30, -30, 60, -60, 90, -90, 120, -120, 150, -150, 180}
    for _, angle in ipairs(angles) do
        local rad = math.rad(angle)
        local rotated = Vector3.new(
            baseDir.X * math.cos(rad) - baseDir.Z * math.sin(rad),
            0,
            baseDir.X * math.sin(rad) + baseDir.Z * math.cos(rad)
        ).Unit

        local result = workspace:Raycast(origin, rotated * checkDist, autoRunRayParams)
        if not result then
            return rotated
        end
    end
    return nil -- fully surrounded / no clear path
end

RunService.Heartbeat:Connect(function()
    if not SETTINGS_AUTORUN.Enabled then return end
    if not rootPart or not humanoidRef then return end
    if humanoidRef.Health <= 0 then return end

    local escapeDir = getEscapeDirection()
    if not escapeDir then return end -- no zombies nearby, do nothing

    local clearDir = findClearDirection(escapeDir)
    if not clearDir then return end -- fully boxed in, don't fight it

    -- move by setting CFrame directly so it's smooth and doesn't fight player input
    rootPart.CFrame = rootPart.CFrame + clearDir * (humanoidRef.WalkSpeed * 0.05)

    -- re-lock aim after movement if TrackWhileMoving is on
    if SETTINGS_V2.Enabled and SETTINGS_V2.ToggleActive and SETTINGS_V2.TrackWhileMoving then
        local zombie = getClosestZombieV2()
        if zombie then
            local head = zombie:FindFirstChild("Head") or zombie:FindFirstChild("HumanoidRootPart")
            if head then
                local targetPos  = head.Position
                local currentLook = camera.CFrame.LookVector
                local toTarget    = (targetPos - camera.CFrame.Position).Unit
                if currentLook:Dot(toTarget) < 0.9999 then
                    camera.CFrame = CFrame.lookAt(camera.CFrame.Position, targetPos)
                end
            end
        end
    end
end)

-- ============================================================
--  MISC TAB
-- ============================================================
local MiscTab        = Window:AddTab("Misc", "settings")
local MiscGroup      = MiscTab:AddLeftGroupbox("Utilities")
local MiscWorldGroup = MiscTab:AddRightGroupbox("World")

-- Collect Power-Ups
local collectingPowerUps = false

local function collectPowerUpsLoop()
    while collectingPowerUps do
        task.wait(0.1)
        if not rootPart then continue end
        local ignore = workspace:FindFirstChild("Ignore")
        local powerUps = ignore and ignore:FindFirstChild("PowerUps")
        if powerUps then
            for _, pu in ipairs(powerUps:GetChildren()) do
                pcall(function()
                    firetouchinterest(rootPart, pu, 0)
                    task.wait()
                    firetouchinterest(rootPart, pu, 1)
                end)
            end
        end
    end
end

-- Anti-AFK
local VirtualUser  = game:GetService("VirtualUser")
local antiAFKConn  = nil

MiscGroup:AddToggle("AntiAFK", {
    Text    = "Anti-AFK",
    Default = false,
    Tooltip = "Prevents getting kicked for being idle",
    Callback = function(v)
        if v then
            antiAFKConn = player.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        else
            if antiAFKConn then
                antiAFKConn:Disconnect()
                antiAFKConn = nil
            end
        end
    end,
})

MiscGroup:AddToggle("CollectPowerUps", {
    Text    = "Collect Power-Ups",
    Default = false,
    Tooltip = "Automatically collects power-ups from the map",
    Callback = function(v)
        collectingPowerUps = v
        if v then task.spawn(collectPowerUpsLoop) end
    end,
})

-- Remove Fog (Atmosphere-based)
local atmosphere     = Lighting:FindFirstChildOfClass("Atmosphere")
local origDensity    = atmosphere and atmosphere.Density or 0
local origOffset     = atmosphere and atmosphere.Offset or 0
local origFogStart   = Lighting.FogStart
local origFogEnd     = Lighting.FogEnd

MiscWorldGroup:AddToggle("RemoveFog", {
    Text    = "Remove Fog",
    Default = false,
    Tooltip = "Removes Atmosphere fog for better visibility",
    Callback = function(v)
        if atmosphere then
            atmosphere.Density = v and 0 or origDensity
            atmosphere.Offset  = v and 0 or origOffset
        end
        Lighting.FogStart = v and math.huge or origFogStart
        Lighting.FogEnd   = v and math.huge or origFogEnd
    end,
})

-- Fullbright
local colorCorrection = Lighting:FindFirstChild("ColorCorrection")
local bloom           = Lighting:FindFirstChild("Bloom")
local origBrightness  = colorCorrection and colorCorrection.Brightness or 0
local origAmbient     = Lighting.Ambient
local origBrightVal   = Lighting.Brightness

MiscWorldGroup:AddToggle("Fullbright", {
    Text    = "Fullbright",
    Default = false,
    Tooltip = "Makes the map fully bright — no dark areas",
    Callback = function(v)
        if colorCorrection then
            colorCorrection.Brightness = v and 1 or origBrightness
        end
        Lighting.Ambient    = v and Color3.new(1, 1, 1) or origAmbient
        Lighting.Brightness = v and 10 or origBrightVal
        if bloom then bloom.Enabled = not v end
    end,
})

MiscGroup:AddToggle("AutoRun", {
    Text    = "Auto Run (from Zombies)",
    Default = false,
    Tooltip = "Automatically runs away from nearby zombies",
    Callback = function(v)
        SETTINGS_AUTORUN.Enabled = v
    end,
})

MiscGroup:AddSlider("SafeDistance", {
    Text     = "Safe Distance (studs)",
    Default  = 20,
    Min      = 5,
    Max      = 50,
    Rounding = 0,
    Tooltip  = "How close a zombie needs to be before you run",
    Callback = function(v)
        SETTINGS_AUTORUN.SafeDistance = v
    end,
})

-- ============================================================
--  UNLOAD
-- ============================================================
Library:OnUnload(function()
    fovCircle:Remove()
    fovCircleV2:Remove()
    clearAllZombieESP()
    clearAllPlayerESP()
    collectingPowerUps = false
    if antiAFKConn then antiAFKConn:Disconnect() end
    if atmosphere then
        atmosphere.Density = origDensity
        atmosphere.Offset  = origOffset
    end
    Lighting.FogStart   = origFogStart
    Lighting.FogEnd     = origFogEnd
    if colorCorrection then colorCorrection.Brightness = origBrightness end
    Lighting.Ambient    = origAmbient
    Lighting.Brightness = origBrightVal
    if bloom then bloom.Enabled = true end
    RunService:UnbindFromRenderStep("Aimbot")
end)

print("Aimbot loaded! RightShift to toggle menu.")
