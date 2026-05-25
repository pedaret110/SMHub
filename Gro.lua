-- ============================================================
-- SM Hub Combined v3.7 | Very Strong Fly + Faster Auto Shoot
-- ============================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local waveRemote = ReplicatedStorage:WaitForChild("WaveRemote")
local bulletHitRemote = ReplicatedStorage:WaitForChild("BulletHit")
local gunConfigRemote = ReplicatedStorage:WaitForChild("GetGunConfig")
local zombieFolder = workspace:WaitForChild("Zombies")

-- SETTINGS
local SETTINGS = {
    AutoSkip = false, InfStamina = false, AntiAFK = false,
    Enabled = false, FOV = 200, Smoothness = 0.12,
    TargetPart = "Head", AimbotKey = 81,
    AutoShoot = false, WallCheck = true, RapidFire = false,
    Fly = false, FlySpeed = 40,
}

-- KEY TRACKING
local heldKeys = {}
local aimbotToggleSync = nil
local flyToggleSync = nil

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    heldKeys[input.KeyCode.Value] = true
    if input.KeyCode.Value == SETTINGS.AimbotKey then
        SETTINGS.Enabled = not SETTINGS.Enabled
        if aimbotToggleSync then aimbotToggleSync(SETTINGS.Enabled) end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    heldKeys[input.KeyCode.Value] = false
end)

-- GUN CONFIG
local bulletCount = 0
local function nextBulletId()
    bulletCount += 1
    return tostring(player.UserId) .. "_" .. bulletCount
end

local gunConfig = nil
local function getGunConfig()
    local char = player.Character
    if not char then return nil end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return nil end
    local ok, result = pcall(function() return gunConfigRemote:InvokeServer(tool.Name) end)
    if ok and result then result.name = tool.Name return result end
    return nil
end

local function onCharAdded(char)
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then task.wait(0.1) gunConfig = getGunConfig() end
    end)
    char.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") then gunConfig = nil end
    end)
end

if player.Character then onCharAdded(player.Character) end
player.CharacterAdded:Connect(onCharAdded)

-- RAYCAST
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
local function updateRayFilter(char)
    rayParams.FilterDescendantsInstances = {char, zombieFolder}
end
if player.Character then updateRayFilter(player.Character) end
player.CharacterAdded:Connect(updateRayFilter)

local function hasLineOfSight(from, to)
    return workspace:Raycast(from, to - from, rayParams) == nil
end

-- VERY STRONG FLY (max anti-slide)
local flyConnection = nil
local function startFly()
    local char = player.Character if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    hum.PlatformStand = true
    for _, v in {"FlyBP","FlyBG"} do local old = root:FindFirstChild(v) if old then old:Destroy() end end

    local bp = Instance.new("BodyPosition")
    bp.Name = "FlyBP"
    bp.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    bp.D = 200
    bp.P = 25000
    bp.Position = root.Position
    bp.Parent = root

    local bg = Instance.new("BodyGyro")
    bg.Name = "FlyBG"
    bg.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    bg.D = 600
    bg.P = 20000
    bg.CFrame = camera.CFrame
    bg.Parent = root

    flyConnection = RunService.Heartbeat:Connect(function(dt)
        if not SETTINGS.Fly then return end
        local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not r then return end
        local flyBP = r:FindFirstChild("FlyBP")
        local flyBG = r:FindFirstChild("FlyBG")
        if not flyBP or not flyBG then return end

        local moveDir = Vector3.zero
        local camCF = camera.CFrame

        if heldKeys[Enum.KeyCode.W.Value] then moveDir += camCF.LookVector end
        if heldKeys[Enum.KeyCode.S.Value] then moveDir -= camCF.LookVector end
        if heldKeys[Enum.KeyCode.A.Value] then moveDir -= camCF.RightVector end
        if heldKeys[Enum.KeyCode.D.Value] then moveDir += camCF.RightVector end
        if heldKeys[Enum.KeyCode.Space.Value] then moveDir += Vector3.new(0,1,0) end
        if heldKeys[Enum.KeyCode.LeftShift.Value] or heldKeys[Enum.KeyCode.RightShift.Value] then moveDir -= Vector3.new(0,1,0) end

        if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end

        flyBP.Position = r.Position + moveDir * SETTINGS.FlySpeed * dt * 22
        flyBG.CFrame = CFrame.new(r.Position, r.Position + Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z))
    end)
end

local function stopFly()
    if flyConnection then flyConnection:Disconnect() flyConnection = nil end
    local char = player.Character if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if root then
        for _,v in {"FlyBP","FlyBG"} do local obj = root:FindFirstChild(v) if obj then obj:Destroy() end end
    end
    if hum then hum.PlatformStand = false end
end

-- SAFE STAMINA + ANTI-AFK
local staminaBar = player.PlayerGui:WaitForChild("SprintGui").Frame.Frame
local originalColor = Color3.new(0.313726, 0.784314, 0.470588)

RunService.Heartbeat:Connect(function()
    if SETTINGS.InfStamina and staminaBar then
        staminaBar.Size = UDim2.new(1,0,1,0)
        staminaBar.BackgroundColor3 = originalColor
    end
end)

task.spawn(function()
    while task.wait(35) do
        if SETTINGS.AntiAFK then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end
    end
end)

-- GUI
local playerGui = player.PlayerGui
for _, name in {"SMHub","AimbotUI","CombinedHub"} do
    if playerGui:FindFirstChild(name) then playerGui[name]:Destroy() end
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CombinedHub"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local PURPLE = Color3.fromRGB(120,40,200)
local DARK = Color3.fromRGB(18,18,18)
local CARD = Color3.fromRGB(28,28,28)
local DIVCLR = Color3.fromRGB(50,50,50)
local WIN_W = 260

local main = Instance.new("Frame")
main.Size = UDim2.new(0, WIN_W, 0, 45)
main.Position = UDim2.new(0,20,0.2,0)
main.BackgroundColor3 = DARK
main.BorderSizePixel = 0
main.Parent = screenGui
Instance.new("UICorner", main).CornerRadius = UDim.new(0,12)

local shadow = Instance.new("Frame") shadow.Size = UDim2.new(1,10,1,10) shadow.Position = UDim2.new(0,-5,0,-5) shadow.BackgroundColor3 = Color3.fromRGB(0,0,0) shadow.BackgroundTransparency = 0.6 shadow.ZIndex = main.ZIndex-1 shadow.Parent = main Instance.new("UICorner", shadow).CornerRadius = UDim.new(0,14)

local titleBar = Instance.new("Frame") titleBar.Size = UDim2.new(1,0,0,45) titleBar.BackgroundColor3 = PURPLE titleBar.BorderSizePixel = 0 titleBar.Parent = main Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0,12)

local titleText = Instance.new("TextLabel") titleText.Size = UDim2.new(1,-50,1,0) titleText.Position = UDim2.new(0,10,0,0) titleText.BackgroundTransparency = 1 titleText.TextColor3 = Color3.new(1,1,1) titleText.Text = "⚡ SM Hub" titleText.Font = Enum.Font.GothamBold titleText.TextSize = 15 titleText.TextXAlignment = Enum.TextXAlignment.Left titleText.Parent = titleBar

local minimizeBtn = Instance.new("TextButton") minimizeBtn.Size = UDim2.new(0,30,0,30) minimizeBtn.Position = UDim2.new(1,-35,0,7) minimizeBtn.BackgroundTransparency = 1 minimizeBtn.TextColor3 = Color3.new(1,1,1) minimizeBtn.Text = "+" minimizeBtn.Font = Enum.Font.GothamBold minimizeBtn.TextSize = 16 minimizeBtn.Parent = titleBar

local tabBar = Instance.new("Frame") tabBar.Size = UDim2.new(1,-20,0,32) tabBar.Position = UDim2.new(0,10,0,50) tabBar.BackgroundColor3 = CARD tabBar.BorderSizePixel = 0 tabBar.Visible = false tabBar.Parent = main Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0,8)

local function makeTab(text, xScale, isActive)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.333,-4,1,-8)
    btn.Position = UDim2.new(xScale,4,0,4)
    btn.BackgroundColor3 = isActive and PURPLE or CARD
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.BorderSizePixel = 0
    btn.Parent = tabBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    return btn
end

local tabSM = makeTab("SM Hub", 0, true)
local tabAimbot = makeTab("🎯 Aimbot", 0.333, false)
local tabFly = makeTab("✈️ Fly", 0.666, false)

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1,0,0,340)
scrollFrame.Position = UDim2.new(0,0,0,88)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 3
scrollFrame.ScrollBarImageColor3 = PURPLE
scrollFrame.Visible = false
scrollFrame.Parent = main

local expanded = false
local currentTab = "sm"

-- Helper Functions (makeLabel, makeDivider, makeToggle, makeSlider, makeDropdown)
local function makeLabel(parent, text, yPos, color)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-20,0,18) lbl.Position = UDim2.new(0,10,0,yPos)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = color or Color3.fromRGB(150,150,150)
    lbl.Text = text
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = parent
    return lbl
end

local function makeDivider(parent, yPos)
    local d = Instance.new("Frame")
    d.Size = UDim2.new(1,-20,0,1) d.Position = UDim2.new(0,10,0,yPos)
    d.BackgroundColor3 = DIVCLR d.BorderSizePixel = 0 d.Parent = parent
end

local function makeToggle(parent, labelText, yPos, default, callback)
    local frame = Instance.new("Frame") frame.Size = UDim2.new(1,-20,0,40) frame.Position = UDim2.new(0,10,0,yPos) frame.BackgroundColor3 = CARD frame.BorderSizePixel = 0 frame.Parent = parent Instance.new("UICorner", frame).CornerRadius = UDim.new(0,8)
    local lbl = Instance.new("TextLabel") lbl.Size = UDim2.new(1,-60,1,0) lbl.Position = UDim2.new(0,12,0,0) lbl.BackgroundTransparency = 1 lbl.TextColor3 = Color3.new(1,1,1) lbl.Text = labelText lbl.Font = Enum.Font.Gotham lbl.TextSize = 13 lbl.TextXAlignment = Enum.TextXAlignment.Left lbl.Parent = frame
    local btn = Instance.new("TextButton") btn.Size = UDim2.new(0,44,0,24) btn.Position = UDim2.new(1,-54,0.5,-12) btn.BackgroundColor3 = default and PURPLE or Color3.fromRGB(60,60,60) btn.Text = "" btn.BorderSizePixel = 0 btn.Parent = frame Instance.new("UICorner", btn).CornerRadius = UDim.new(1,0)
    local circle = Instance.new("Frame") circle.Size = UDim2.new(0,18,0,18) circle.Position = default and UDim2.new(0,23,0.5,-9) or UDim2.new(0,3,0.5,-9) circle.BackgroundColor3 = Color3.new(1,1,1) circle.BorderSizePixel = 0 circle.Parent = btn Instance.new("UICorner", circle).CornerRadius = UDim.new(1,0)
    local state = default
    local function setVisual(v)
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = v and PURPLE or Color3.fromRGB(60,60,60)}):Play()
        TweenService:Create(circle, TweenInfo.new(0.2), {Position = v and UDim2.new(0,23,0.5,-9) or UDim2.new(0,3,0.5,-9)}):Play()
    end
    btn.MouseButton1Click:Connect(function()
        state = not state
        setVisual(state)
        callback(state)
    end)
    return function(v) state = v setVisual(v) end
end

local function makeSlider(parent, labelText, yPos, min, max, default, displayMult, callback)
    local frame = Instance.new("Frame") frame.Size = UDim2.new(1,-20,0,52) frame.Position = UDim2.new(0,10,0,yPos) frame.BackgroundColor3 = CARD frame.BorderSizePixel = 0 frame.Parent = parent Instance.new("UICorner", frame).CornerRadius = UDim.new(0,8)
    local function fmt(v) return string.format("%.2f", v) end
    local lbl = Instance.new("TextLabel") lbl.Size = UDim2.new(1,-20,0,20) lbl.Position = UDim2.new(0,12,0,4) lbl.BackgroundTransparency = 1 lbl.TextColor3 = Color3.new(1,1,1) lbl.Text = labelText .. ": " .. fmt(default) lbl.Font = Enum.Font.Gotham lbl.TextSize = 12 lbl.TextXAlignment = Enum.TextXAlignment.Left lbl.Parent = frame
    local track = Instance.new("Frame") track.Size = UDim2.new(1,-24,0,6) track.Position = UDim2.new(0,12,0,32) track.BackgroundColor3 = DIVCLR track.BorderSizePixel = 0 track.Parent = frame Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)
    local fill = Instance.new("Frame") fill.Size = UDim2.new((default-min)/(max-min),0,1,0) fill.BackgroundColor3 = PURPLE fill.BorderSizePixel = 0 fill.Parent = track Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)
    local knob = Instance.new("Frame") knob.Size = UDim2.new(0,14,0,14) knob.Position = UDim2.new((default-min)/(max-min),-7,0.5,-7) knob.BackgroundColor3 = Color3.new(1,1,1) knob.BorderSizePixel = 0 knob.Parent = track Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)
    local dragging = false
    knob.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local value = min + (max-min) * rel
            fill.Size = UDim2.new(rel,0,1,0)
            knob.Position = UDim2.new(rel,-7,0.5,-7)
            lbl.Text = labelText .. ": " .. fmt(value)
            callback(value)
        end
    end)
end

local function makeDropdown(parent, labelText, yPos, options, default, callback)
    local frame = Instance.new("Frame") frame.Size = UDim2.new(1,-20,0,40) frame.Position = UDim2.new(0,10,0,yPos) frame.BackgroundColor3 = CARD frame.BorderSizePixel = 0 frame.Parent = parent Instance.new("UICorner", frame).CornerRadius = UDim.new(0,8)
    local lbl = Instance.new("TextLabel") lbl.Size = UDim2.new(0.5,0,1,0) lbl.Position = UDim2.new(0,12,0,0) lbl.BackgroundTransparency = 1 lbl.TextColor3 = Color3.new(1,1,1) lbl.Text = labelText lbl.Font = Enum.Font.Gotham lbl.TextSize = 13 lbl.TextXAlignment = Enum.TextXAlignment.Left lbl.Parent = frame
    local idx = 1 for i,v in ipairs(options) do if v == default then idx = i end end
    local btn = Instance.new("TextButton") btn.Size = UDim2.new(0,100,0,26) btn.Position = UDim2.new(1,-110,0.5,-13) btn.BackgroundColor3 = PURPLE btn.TextColor3 = Color3.new(1,1,1) btn.Text = default btn.Font = Enum.Font.GothamBold btn.TextSize = 12 btn.BorderSizePixel = 0 btn.Parent = frame Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    btn.MouseButton1Click:Connect(function()
        idx = idx % #options + 1
        btn.Text = options[idx]
        callback(options[idx])
    end)
end

-- FOV Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Radius = SETTINGS.FOV
fovCircle.Color = PURPLE
fovCircle.Thickness = 1.5
fovCircle.Filled = false
fovCircle.NumSides = 64
fovCircle.Visible = false

-- Pages
local SM_CANVAS = 320
local AIMBOT_CANVAS = 520
local FLY_CANVAS = 140

local smContent = Instance.new("Frame") smContent.Size = UDim2.new(1,0,0,SM_CANVAS) smContent.BackgroundTransparency = 1 smContent.Parent = scrollFrame
local aimbotContent = Instance.new("Frame") aimbotContent.Size = UDim2.new(1,0,0,AIMBOT_CANVAS) aimbotContent.BackgroundTransparency = 1 aimbotContent.Visible = false aimbotContent.Parent = scrollFrame
local flyContent = Instance.new("Frame") flyContent.Size = UDim2.new(1,0,0,FLY_CANVAS) flyContent.BackgroundTransparency = 1 flyContent.Visible = false flyContent.Parent = scrollFrame

-- Fill content
makeLabel(smContent, "WAVE", 8, PURPLE)
local lastVoted = false
makeToggle(smContent, "Auto Skip Wave", 28, false, function(v) SETTINGS.AutoSkip = v end)
makeDivider(smContent, 76)
makeLabel(smContent, "PLAYER", 84, PURPLE)
makeToggle(smContent, "Infinite Stamina", 104, false, function(v) SETTINGS.InfStamina = v end)
makeToggle(smContent, "Anti-AFK", 144, false, function(v) SETTINGS.AntiAFK = v end)
makeDivider(smContent, 192)
makeLabel(smContent, "CAMERA", 200, PURPLE)
makeSlider(smContent, "Field of View", 220, 70, 120, 70, 1, function(v) camera.FieldOfView = v end)

makeLabel(aimbotContent, "AIMBOT", 8, PURPLE)
aimbotToggleSync = makeToggle(aimbotContent, "Enabled", 28, false, function(v)
    SETTINGS.Enabled = v
    fovCircle.Visible = v and expanded
end)
makeDivider(aimbotContent, 76)
makeLabel(aimbotContent, "AIM SETTINGS", 84, PURPLE)
makeSlider(aimbotContent, "FOV", 104, 50, 600, 200, 1, function(v) SETTINGS.FOV = v fovCircle.Radius = v end)
makeSlider(aimbotContent, "Smoothness", 164, 0, 1, 0.12, 1, function(v) SETTINGS.Smoothness = v end)
makeDivider(aimbotContent, 224)
makeLabel(aimbotContent, "TARGET", 232, PURPLE)
makeDropdown(aimbotContent, "Target Part", 250, {"Head","UpperTorso","HumanoidRootPart"}, "Head", function(v) SETTINGS.TargetPart = v end)
makeDivider(aimbotContent, 298)
makeLabel(aimbotContent, "EXTRAS", 306, PURPLE)
makeToggle(aimbotContent, "Wall Check", 326, true, function(v) SETTINGS.WallCheck = v end)
makeToggle(aimbotContent, "Auto Shoot", 366, false, function(v) SETTINGS.AutoShoot = v if v then gunConfig = getGunConfig() end end)
makeToggle(aimbotContent, "Rapid Fire", 406, false, function(v) SETTINGS.RapidFire = v end)

makeLabel(flyContent, "FLY", 8, PURPLE)
flyToggleSync = makeToggle(flyContent, "Enable Fly", 28, false, function(v)
    SETTINGS.Fly = v
    if v then startFly() else stopFly() end
end)
makeDivider(flyContent, 76)
makeSlider(flyContent, "Fly Speed", 84, 10, 200, 40, 1, function(v) SETTINGS.FlySpeed = v end)

-- Tab Switching, Minimize, Dragging, Auto Skip (same as before)
local function switchTab(tab)
    currentTab = tab
    smContent.Visible = tab == "sm"
    aimbotContent.Visible = tab == "aimbot"
    flyContent.Visible = tab == "fly"
    local canvases = {sm = SM_CANVAS, aimbot = AIMBOT_CANVAS, fly = FLY_CANVAS}
    scrollFrame.CanvasSize = UDim2.new(0,0,0,canvases[tab])

    TweenService:Create(tabSM, TweenInfo.new(0.15), {BackgroundColor3 = tab=="sm" and PURPLE or CARD}):Play()
    TweenService:Create(tabAimbot, TweenInfo.new(0.15), {BackgroundColor3 = tab=="aimbot" and PURPLE or CARD}):Play()
    TweenService:Create(tabFly, TweenInfo.new(0.15), {BackgroundColor3 = tab=="fly" and PURPLE or CARD}):Play()

    local titles = {sm = "⚡ SM Hub", aimbot = "🎯 Aimbot", fly = "✈️ Fly"}
    titleText.Text = titles[tab]
    fovCircle.Visible = (tab == "aimbot" and SETTINGS.Enabled and expanded)
end

tabSM.MouseButton1Click:Connect(function() switchTab("sm") end)
tabAimbot.MouseButton1Click:Connect(function() switchTab("aimbot") end)
tabFly.MouseButton1Click:Connect(function() switchTab("fly") end)

minimizeBtn.MouseButton1Click:Connect(function()
    expanded = not expanded
    if expanded then
        tabBar.Visible = true
        scrollFrame.Visible = true
        TweenService:Create(main, TweenInfo.new(0.3), {Size = UDim2.new(0, WIN_W, 0, 440)}):Play()
        minimizeBtn.Text = "—"
        if currentTab == "aimbot" then fovCircle.Visible = SETTINGS.Enabled end
    else
        tabBar.Visible = false
        scrollFrame.Visible = false
        TweenService:Create(main, TweenInfo.new(0.3), {Size = UDim2.new(0, WIN_W, 0, 45)}):Play()
        minimizeBtn.Text = "+"
        fovCircle.Visible = false
    end
end)

-- Dragging
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
        local d = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)
titleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

-- Auto Skip
task.spawn(function()
    while task.wait(0.1) do
        if SETTINGS.AutoSkip then
            local found = false
            for _, gui in ipairs(player.PlayerGui:GetDescendants()) do
                if (gui:IsA("TextButton") or gui:IsA("ImageButton")) and gui.Text:find("NEXT WAVE") and gui.Visible then
                    found = true break
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

-- AIMBOT (with ultra fast rapid fire)
local function getClosestZombie()
    local closest, closestDist = nil, SETTINGS.FOV
    local center = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
    local camPos = camera.CFrame.Position
    for _, zombie in ipairs(zombieFolder:GetChildren()) do
        local hum = zombie:FindFirstChild("Humanoid")
        local target = zombie:FindFirstChild(SETTINGS.TargetPart)
        if not hum or not target or hum.Health <= 0 then continue end
        if SETTINGS.WallCheck and not hasLineOfSight(camPos, target.Position) then continue end
        local screenPos, onScreen = camera:WorldToViewportPoint(target.Position)
        if not onScreen then continue end
        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
        if dist < closestDist then closestDist = dist closest = target end
    end
    return closest
end

local shootCooldown = false
local function internalShoot(targetPart)
    if shootCooldown then return end
    if not gunConfig then gunConfig = getGunConfig() if not gunConfig then return end end
    local char = player.Character if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart") if not root then return end

    shootCooldown = true
    bulletHitRemote:FireServer(targetPart, gunConfig.name, nextBulletId(), root.Position, targetPart.Position)

    local delay = SETTINGS.RapidFire and 0.035 or (gunConfig.fireRate or 0.1)
    task.delay(delay, function() shootCooldown = false end)
end

RunService.Heartbeat:Connect(function()
    fovCircle.Position = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
    if not SETTINGS.Enabled then return end

    local target = getClosestZombie()
    if not target then return end

    local camPos = camera.CFrame.Position
    local targetPos = target.Position

    if SETTINGS.Smoothness <= 0.002 then
        camera.CFrame = CFrame.new(camPos, targetPos)
    else
        local current = camera.CFrame.LookVector
        local desired = (targetPos - camPos).Unit
        local smoothed = current:Lerp(desired, SETTINGS.Smoothness)
        camera.CFrame = CFrame.new(camPos, camPos + smoothed)
    end

    if SETTINGS.AutoShoot then
        internalShoot(target)
    end
end)

print("SM Hub v3.7 loaded! (Very strong fly + ultra fast rapid fire)")
