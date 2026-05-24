-- ============================================================
--  SM Hub v2  |  Obsidian UI  |  SM Hub + Aimbot
-- ============================================================

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

-- ============================================================
--  SERVICES
-- ============================================================
local Players          = game:GetService("Players")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player  = Players.LocalPlayer
local camera  = workspace.CurrentCamera

-- ============================================================
--  REMOTES
-- ============================================================
local waveRemote      = ReplicatedStorage:WaitForChild("WaveRemote")
local bulletHitRemote = ReplicatedStorage:WaitForChild("BulletHit")
local gunEquipRemote  = ReplicatedStorage:WaitForChild("GunEquipped")

-- ============================================================
--  ZOMBIE FOLDER
-- ============================================================
local zombieFolder = workspace:WaitForChild("Zombies")

-- ============================================================
--  SETTINGS
-- ============================================================
local SETTINGS = {
    AutoSkip   = false,
    InfStamina = false,
    Enabled    = false,
    FOV        = 200,
    Smoothness = 0.05,
    TargetPart = "Head",
    WallCheck  = true,
    AutoShoot  = false,
    Fly        = false,
    FlySpeed   = 40,
}

-- ============================================================
--  GUN CONFIG  (tracked via GunEquipped remote)
-- ============================================================
local currentGunName = nil
local bulletCount    = 0

local function nextBulletId()
    bulletCount += 1
    return tostring(player.UserId) .. "_" .. tostring(bulletCount)
end

-- Hook GunEquipped to track current gun name
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    if method == "FireServer" and self == gunEquipRemote then
        local args = {...}
        if args[1] then
            currentGunName = tostring(args[1])
        end
    end
    return oldNamecall(self, ...)
end)

-- Also check current equipped tool
local function getCurrentGunName()
    if currentGunName then return currentGunName end
    local char = player.Character
    if not char then return nil end
    local tool = char:FindFirstChildOfClass("Tool")
    return tool and tool.Name or nil
end

local function onCharAdded(char)
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            currentGunName = child.Name
        end
    end)
    char.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") then
            currentGunName = nil
        end
    end)
end

if player.Character then onCharAdded(player.Character) end
player.CharacterAdded:Connect(function(char)
    onCharAdded(char)
    SETTINGS.Enabled = false
end)

-- ============================================================
--  RAYCAST PARAMS
-- ============================================================
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

local oldIndexHook
oldIndexHook = hookmetamethod(game, "__newindex", function(self, key, value)
    if SETTINGS.InfStamina and self == staminaBar then
        if key == "Size" then
            return oldIndexHook(self, key, UDim2.new(1, 0, 1, 0))
        end
        if key == "BackgroundColor3" then
            return oldIndexHook(self, key, originalColor)
        end
    end
    return oldIndexHook(self, key, value)
end)

local smHumanoid = player.Character and player.Character:FindFirstChild("Humanoid")
player.CharacterAdded:Connect(function(char)
    smHumanoid = char:WaitForChild("Humanoid")
end)

-- Forward declare fly functions (defined later)
local startFly, stopFly

-- ============================================================
--  WINDOW
-- ============================================================
local Window = Library:CreateWindow({
    Title           = "⚡ SM Hub",
    Footer          = "v2.0",
    ShowCustomCursor= true,
    NotifySide      = "Right",
})

local Tabs = {
    SMHub  = Window:AddTab("SM Hub",  "shield"),
    Aimbot = Window:AddTab("Aimbot",  "crosshair"),
    UI     = Window:AddTab("UI",      "settings"),
}

-- ============================================================
--  SM HUB TAB
-- ============================================================
local WaveGroup   = Tabs.SMHub:AddLeftGroupbox("Wave", "waves")
local PlayerGroup = Tabs.SMHub:AddLeftGroupbox("Player", "user")
local CameraGroup = Tabs.SMHub:AddRightGroupbox("Camera", "camera")

-- Auto Skip Wave
WaveGroup:AddToggle("AutoSkip", {
    Text    = "Auto Skip Wave",
    Default = false,
    Tooltip = "Automatically votes to skip to the next wave",
    Callback = function(v)
        SETTINGS.AutoSkip = v
    end,
})

-- Infinite Stamina
PlayerGroup:AddToggle("InfStamina", {
    Text    = "Infinite Stamina",
    Default = false,
    Tooltip = "Keeps your stamina bar full while sprinting",
    Callback = function(v)
        SETTINGS.InfStamina = v
    end,
})

-- FOV Slider
CameraGroup:AddSlider("CameraFOV", {
    Text    = "Field of View",
    Default = 70,
    Min     = 70,
    Max     = 120,
    Rounding= 0,
    Tooltip = "Adjusts camera field of view",
    Callback = function(v)
        camera.FieldOfView = v
    end,
})

local MovGroup = Tabs.SMHub:AddRightGroupbox("Movement", "move")

MovGroup:AddToggle("FlyToggle", {
    Text    = "Fly",
    Default = false,
    Tooltip = "Toggle fly mode (WASD to move, Space/Shift for up/down)",
    Callback = function(v)
        SETTINGS.Fly = v
        if v then startFly() else stopFly() end
    end,
})

MovGroup:AddSlider("FlySpeedSlider", {
    Text     = "Fly Speed",
    Default  = 40,
    Min      = 10,
    Max      = 150,
    Rounding = 0,
    Callback = function(v)
        SETTINGS.FlySpeed = v
    end,
})

-- ============================================================
--  FOV CIRCLE  (must be created before aimbot UI callbacks reference it)
-- ============================================================
local fovCircle = Drawing.new("Circle")
fovCircle.Radius   = SETTINGS.FOV
fovCircle.Color    = Color3.fromRGB(120, 40, 200)
fovCircle.Thickness= 1.5
fovCircle.Filled   = false
fovCircle.NumSides = 64
fovCircle.Visible  = false

-- ============================================================
--  AIMBOT TAB
-- ============================================================
local AimGroup    = Tabs.Aimbot:AddLeftGroupbox("Aimbot", "crosshair")
local SettGroup   = Tabs.Aimbot:AddRightGroupbox("Settings", "sliders-horizontal")

-- Aimbot Enabled
AimGroup:AddToggle("AimbotEnabled", {
    Text    = "Enabled",
    Default = false,
    Tooltip = "Toggle aimbot on/off",
    Callback = function(v)
        SETTINGS.Enabled = v
        fovCircle.Visible = v
    end,
})

-- Wall Check
AimGroup:AddToggle("WallCheck", {
    Text    = "Wall Check",
    Default = true,
    Tooltip = "Only target zombies visible through walls",
    Callback = function(v)
        SETTINGS.WallCheck = v
    end,
})

-- Auto Shoot
AimGroup:AddToggle("AutoShoot", {
    Text    = "Auto Shoot",
    Default = false,
    Tooltip = "Automatically fires at the closest zombie",
    Callback = function(v)
        SETTINGS.AutoShoot = v
    end,
})

-- FOV Slider
SettGroup:AddSlider("AimbotFOV", {
    Text     = "FOV",
    Default  = 200,
    Min      = 50,
    Max      = 500,
    Rounding = 0,
    Tooltip  = "Aimbot field of view radius in pixels",
    Callback = function(v)
        SETTINGS.FOV = v
        fovCircle.Radius = v
    end,
})

-- Smoothness Slider
SettGroup:AddSlider("Smoothness", {
    Text     = "Smoothness",
    Default  = 5,
    Min      = 1,
    Max      = 30,
    Rounding = 0,
    Tooltip  = "Lower = faster aim, Higher = smoother/slower (1 = near instant)",
    Callback = function(v)
        SETTINGS.Smoothness = v / 100
    end,
})

-- Target Part Dropdown
SettGroup:AddDropdown("TargetPart", {
    Text    = "Target Part",
    Values  = {"Head", "Torso", "HumanoidRootPart", "Left Arm", "Right Arm", "Left Leg", "Right Leg"},
    Default = 1,
    Tooltip = "Which body part to aim at",
    Callback = function(v)
        SETTINGS.TargetPart = v
    end,
})

-- ============================================================
--  UI SETTINGS TAB
-- ============================================================
local MenuGroup = Tabs.UI:AddLeftGroupbox("Menu", "wrench")

MenuGroup:AddToggle("ShowCustomCursor", {
    Text    = "Custom Cursor",
    Default = true,
    Callback = function(v)
        Library.ShowCustomCursor = v
    end,
})

MenuGroup:AddDropdown("NotifSide", {
    Values  = {"Left", "Right"},
    Default = "Right",
    Text    = "Notification Side",
    Callback = function(v)
        Library:SetNotifySide(v)
    end,
})

MenuGroup:AddDivider()
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
ThemeManager:SetFolder("SMHub")
SaveManager:SetFolder("SMHub/survive-monster")
SaveManager:BuildConfigSection(Tabs.UI)
ThemeManager:ApplyToTab(Tabs.UI)

-- ============================================================
--  AUTO SKIP LOOP
-- ============================================================
local lastVoted = false
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
--  AIMBOT HELPERS
-- ============================================================
local function hasLineOfSight(from, to)
    return workspace:Raycast(from, to - from, rayParams) == nil
end

local function getClosestZombie()
    local closest, closestDist = nil, SETTINGS.FOV
    local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    local camPos = camera.CFrame.Position

    for _, zombie in ipairs(zombieFolder:GetChildren()) do
        local humanoid = zombie:FindFirstChild("Humanoid")
        local target   = zombie:FindFirstChild(SETTINGS.TargetPart)
        if not humanoid or not target or humanoid.Health <= 0 then continue end
        if SETTINGS.WallCheck and not hasLineOfSight(camPos, target.Position) then continue end
        local screenPos, onScreen = camera:WorldToViewportPoint(target.Position)
        if not onScreen then continue end
        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
        if dist < closestDist then closestDist = dist; closest = target end
    end
    return closest
end

-- ============================================================
--  AUTO SHOOT
-- ============================================================
local shootCooldown = false
local FIRE_RATE     = 0.08

local function internalShoot(targetPart)
    if shootCooldown then return end
    -- Always get gun from character first, fallback to tracked name
    local char = player.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    local gunName = (tool and tool.Name) or currentGunName
    if not gunName then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    shootCooldown = true
    bulletHitRemote:FireServer(
        targetPart.Name,
        gunName,
        nextBulletId(),
        root.Position,
        targetPart.Position
    )
    task.delay(FIRE_RATE, function()
        shootCooldown = false
    end)
end

-- ============================================================
--  FLY
-- ============================================================
local heldKeys = {}
UserInputService.InputBegan:Connect(function(input)
    heldKeys[input.KeyCode.Value] = true
end)
UserInputService.InputEnded:Connect(function(input)
    heldKeys[input.KeyCode.Value] = false
end)

local flyConnection = nil

startFly = function()
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid then return end
    humanoid.PlatformStand = true

    local bp = Instance.new("BodyPosition")
    bp.Name     = "FlyBP"
    bp.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bp.Position = root.Position
    bp.D        = 1000
    bp.P        = 10000
    bp.Parent   = root

    local bg = Instance.new("BodyGyro")
    bg.Name      = "FlyBG"
    bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    bg.D         = 400
    bg.CFrame    = camera.CFrame
    bg.Parent    = root

    if flyConnection then flyConnection:Disconnect() end
    flyConnection = RunService.Heartbeat:Connect(function(dt)
        if not SETTINGS.Fly then stopFly() return end
        local c = player.Character
        if not c then return end
        local r = c:FindFirstChild("HumanoidRootPart")
        if not r then return end
        local flyBP = r:FindFirstChild("FlyBP")
        local flyBG = r:FindFirstChild("FlyBG")
        if not flyBP or not flyBG then return end
        local speed   = SETTINGS.FlySpeed
        local camCF   = camera.CFrame
        local moveDir = Vector3.zero
        -- W=87 S=83 A=65 D=68 Space=32 LeftShift=304
        if heldKeys[87]  then moveDir += camCF.LookVector end
        if heldKeys[83]  then moveDir -= camCF.LookVector end
        if heldKeys[65]  then moveDir -= camCF.RightVector end
        if heldKeys[68]  then moveDir += camCF.RightVector end
        if heldKeys[32]  then moveDir += Vector3.new(0,1,0) end
        if heldKeys[304] then moveDir -= Vector3.new(0,1,0) end
        if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end
        flyBP.Position = r.Position + moveDir * speed * dt * 10
        flyBG.CFrame   = camCF
    end)
end

stopFly = function()
    if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
    local char = player.Character
    if not char then return end
    local root     = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if root then
        local bp = root:FindFirstChild("FlyBP")
        local bg = root:FindFirstChild("FlyBG")
        if bp then bp:Destroy() end
        if bg then bg:Destroy() end
    end
    if humanoid then humanoid.PlatformStand = false end
end

player.CharacterAdded:Connect(function()
    SETTINGS.Fly = false
    stopFly()
end)

-- ============================================================
--  AIMBOT MAIN LOOP
-- ============================================================
RunService.Heartbeat:Connect(function()
    fovCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    if not SETTINGS.Enabled then return end

    local target = getClosestZombie()
    if not target then return end

    local camPos    = camera.CFrame.Position
    local targetPos = target.Position

    if SETTINGS.Smoothness <= 0.01 then
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
print("SM Hub v2 loaded!")
