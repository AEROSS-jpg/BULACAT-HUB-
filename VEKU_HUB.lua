--[[
    VEKU HUB - Advanced Smooth Egg Stealer
    Ultra-polished LocalScript / Executor version
    Blue theme • Continuous smooth movement • Priority targeting
]]

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local CoreGui           = game:GetService("CoreGui")
local StarterGui        = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Character, Humanoid, Root

local function refreshCharacter()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    Humanoid  = Character:WaitForChild("Humanoid", 8)
    Root      = Character:WaitForChild("HumanoidRootPart", 8)
end
refreshCharacter()
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.75)
    refreshCharacter()
    stopMovement()
end)

----------------------------------------------------------------
-- CONFIG
----------------------------------------------------------------
local CONFIG = {
    Name            = "VEKU HUB",
    ScanRadius      = 350,
    StealRange      = 8.5,
    MoveSpeed       = 32,              -- higher = faster approach
    TurnSpeed       = 14,
    PriorityAttr    = "Value",
    EggTags         = {"Egg", "CollectableEgg", "PetEgg", "EggModel", "Collectable"},
    Blacklist       = {"spawn", "lobby", "safe", "base", "shop", "npc", "vendor"},
    MaxPerCycle     = 15,
    Cooldown        = 0.18,
    AutoFarm        = true,
    ShowGUI         = true,
    Notify          = true,
    Smoothness      = 0.18,            -- lower = silkier camera/position lerp
}

----------------------------------------------------------------
-- STATE
----------------------------------------------------------------
local lastSteal     = 0
local isBusy        = false
local stolenTotal   = 0
local currentTarget = nil
local moveConnection = nil
local gui, statusLabel, countLabel, titleLabel

----------------------------------------------------------------
-- CLEAN GUI (Blue Theme)
----------------------------------------------------------------
local function createGUI()
    pcall(function()
        local old = CoreGui:FindFirstChild("VEKU_HUB_GUI")
        if old then old:Destroy() end
    end)

    local screen = Instance.new("ScreenGui")
    screen.Name = "VEKU_HUB_GUI"
    screen.ResetOnSpawn = false
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screen.IgnoreGuiInset = true
    screen.Parent = CoreGui

    -- Main frame
    local frame = Instance.new("Frame")
    frame.Name = "Main"
    frame.Size = UDim2.new(0, 280, 0, 128)
    frame.Position = UDim2.new(0, 18, 0.5, -64)
    frame.BackgroundColor3 = Color3.fromRGB(8, 12, 22)
    frame.BorderSizePixel = 0
    frame.Parent = screen

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(60, 140, 255)
    stroke.Thickness = 1.8
    stroke.Transparency = 0.15
    stroke.Parent = frame

    -- Accent bar
    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(1, 0, 0, 3)
    accent.Position = UDim2.new(0, 0, 0, 0)
    accent.BackgroundColor3 = Color3.fromRGB(50, 130, 255)
    accent.BorderSizePixel = 0
    accent.Parent = frame

    local accentCorner = Instance.new("UICorner")
    accentCorner.CornerRadius = UDim.new(0, 12)
    accentCorner.Parent = accent

    -- Title
    titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -70, 0, 30)
    titleLabel.Position = UDim2.new(0, 14, 0, 12)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "VEKU HUB"
    titleLabel.TextColor3 = Color3.fromRGB(90, 170, 255)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 22
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = frame

    -- Status
    statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "Status"
    statusLabel.Size = UDim2.new(1, -20, 0, 22)
    statusLabel.Position = UDim2.new(0, 14, 0, 48)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Status: Ready"
    statusLabel.TextColor3 = Color3.fromRGB(180, 200, 230)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 14
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = frame

    -- Count
    countLabel = Instance.new("TextLabel")
    countLabel.Name = "Count"
    countLabel.Size = UDim2.new(1, -20, 0, 22)
    countLabel.Position = UDim2.new(0, 14, 0, 74)
    countLabel.BackgroundTransparency = 1
    countLabel.Text = "Stolen: 0"
    countLabel.TextColor3 = Color3.fromRGB(100, 220, 160)
    countLabel.Font = Enum.Font.GothamMedium
    countLabel.TextSize = 14
    countLabel.TextXAlignment = Enum.TextXAlignment.Left
    countLabel.Parent = frame

    -- Keybind hint
    local hint = Instance.new("TextLabel")
    hint.Size = UDim2.new(1, -20, 0, 18)
    hint.Position = UDim2.new(0, 14, 0, 100)
    hint.BackgroundTransparency = 1
    hint.Text = "[P] Toggle  •  Smooth Mode"
    hint.TextColor3 = Color3.fromRGB(100, 120, 160)
    hint.Font = Enum.Font.Gotham
    hint.TextSize = 12
    hint.TextXAlignment = Enum.TextXAlignment.Left
    hint.Parent = frame

    -- Logo placeholder (replace with your Goku/Vegeta asset)
    local logo = Instance.new("ImageLabel")
    logo.Name = "Logo"
    logo.Size = UDim2.new(0, 46, 0, 46)
    logo.Position = UDim2.new(1, -58, 0, 14)
    logo.BackgroundTransparency = 1
    logo.Image = "rbxassetid://0" -- ← PUT YOUR IMAGE ASSET ID HERE
    logo.ScaleType = Enum.ScaleType.Fit
    logo.Parent = frame

    return screen
end

gui = createGUI()

local function setStatus(text)
    if statusLabel then
        statusLabel.Text = "Status: " .. text
    end
end

local function updateCount()
    if countLabel then
        countLabel.Text = "Stolen: " .. tostring(stolenTotal)
    end
end

----------------------------------------------------------------
-- UTILITIES
----------------------------------------------------------------
local function isBlacklisted(name)
    name = string.lower(name)
    for _, bad in ipairs(CONFIG.Blacklist) do
        if string.find(name, bad) then return true end
    end
    return false
end

local function isValidEgg(obj)
    if not obj or not obj.Parent then return false end
    if isBlacklisted(obj.Name) then return false end

    for _, tag in ipairs(CONFIG.EggTags) do
        if CollectionService:HasTag(obj, tag) then return true end
    end

    local n = string.lower(obj.Name)
    if string.find(n, "egg") then return true end
    return false
end

local function getPrimary(obj)
    if obj:IsA("BasePart") then return obj end
    return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
end

local function getValue(egg)
    local attrs = {CONFIG.PriorityAttr, "Price", "RarityValue", "Worth", "Cost", "Value"}
    for _, a in ipairs(attrs) do
        local v = egg:GetAttribute(a)
        if typeof(v) == "number" then return v end
    end
    return 1
end

----------------------------------------------------------------
-- ULTRA SMOOTH MOVEMENT
----------------------------------------------------------------
function stopMovement()
    if moveConnection then
        moveConnection:Disconnect()
        moveConnection = nil
    end
    currentTarget = nil
    if Humanoid and Humanoid.Parent then
        Humanoid:Move(Vector3.zero)
    end
end

local function smoothMoveTo(targetPart, onArrive)
    stopMovement()
    if not Root or not Humanoid or not targetPart or not targetPart.Parent then
        if onArrive then onArrive(false) end
        return
    end

    currentTarget = targetPart
    local eggName = targetPart.Parent and targetPart.Parent.Name or targetPart.Name
    setStatus("Moving → " .. eggName)

    moveConnection = RunService.Heartbeat:Connect(function(dt)
        if not Root or not Root.Parent or not Humanoid or Humanoid.Health <= 0 then
            stopMovement()
            return
        end
        if not targetPart or not targetPart.Parent then
            stopMovement()
            if onArrive then onArrive(false) end
            return
        end

        local myPos = Root.Position
        local goal  = targetPart.Position + Vector3.new(0, 2.8, 0)
        local offset = goal - myPos
        local dist  = offset.Magnitude

        if dist <= CONFIG.StealRange then
            stopMovement()
            if onArrive then onArrive(true) end
            return
        end

        -- Continuous smooth walk
        local dir = offset.Unit
        Humanoid:Move(dir)

        -- Silky rotation
        local flatGoal = Vector3.new(goal.X, myPos.Y, goal.Z)
        local lookCF = CFrame.lookAt(myPos, flatGoal)
        Root.CFrame = Root.CFrame:Lerp(lookCF, math.clamp(dt * CONFIG.TurnSpeed, 0, 1))
    end)
end

----------------------------------------------------------------
-- STEAL
----------------------------------------------------------------
local function attemptSteal(egg)
    if isBusy or (tick() - lastSteal) < CONFIG.Cooldown then return false end
    local part = getPrimary(egg)
    if not part then return false end

    isBusy = true
    lastSteal = tick()
    setStatus("Stealing " .. egg.Name)

    -- Broad remote search
    local function fireRemote(rem)
        if not rem then return end
        if rem:IsA("RemoteEvent") then
            pcall(function() rem:FireServer(egg) end)
            pcall(function() rem:FireServer(part) end)
            pcall(function() rem:FireServer(egg.Name) end)
        elseif rem:IsA("RemoteFunction") then
            pcall(function() rem:InvokeServer(egg) end)
        end
    end

    -- Direct children
    for _, child in ipairs(ReplicatedStorage:GetChildren()) do
        if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
            local n = string.lower(child.Name)
            if string.find(n, "steal") or string.find(n, "collect") or string.find(n, "pickup") or string.find(n, "claim") or string.find(n, "egg") then
                fireRemote(child)
            end
        end
    end

    -- Nested folders
    local folders = {"RemoteEvents", "Remotes", "Events", "Network"}
    for _, folderName in ipairs(folders) do
        local folder = ReplicatedStorage:FindFirstChild(folderName)
        if folder then
            for _, child in ipairs(folder:GetDescendants()) do
                if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                    local n = string.lower(child.Name)
                    if string.find(n, "steal") or string.find(n, "collect") or string.find(n, "pickup") or string.find(n, "claim") or string.find(n, "egg") then
                        fireRemote(child)
                    end
                end
            end
        end
    end

    -- Prompt / Click fallback
    local prompt = part:FindFirstChildOfClass("ProximityPrompt") or egg:FindFirstChildOfClass("ProximityPrompt")
    if prompt then
        pcall(function() fireproximityprompt(prompt) end)
    end

    local click = part:FindFirstChildOfClass("ClickDetector") or egg:FindFirstChildOfClass("ClickDetector")
    if click then
        pcall(function() fireclickdetector(click) end)
    end

    stolenTotal += 1
    updateCount()

    if CONFIG.Notify then
        print(string.format("[VEKU HUB] ✓ %s | Value: %s | Total: %d", egg.Name, getValue(egg), stolenTotal))
    end

    task.wait(0.07)
    isBusy = false
    setStatus("Idle")
    return true
end

----------------------------------------------------------------
-- SCANNER
----------------------------------------------------------------
local function scanEggs()
    local list = {}
    if not Root or not Root.Parent then return list end
    local origin = Root.Position

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isValidEgg(obj) then
            local part = getPrimary(obj)
            if part and part.Parent then
                local dist = (part.Position - origin).Magnitude
                if dist <= CONFIG.ScanRadius then
                    table.insert(list, {
                        Object   = obj,
                        Part     = part,
                        Distance = dist,
                        Value    = getValue(obj)
                    })
                end
            end
        end
    end

    table.sort(list, function(a, b)
        if a.Value == b.Value then
            return a.Distance < b.Distance
        end
        return a.Value > b.Value
    end)

    return list
end

----------------------------------------------------------------
-- MAIN LOOP
----------------------------------------------------------------
local function farmCycle()
    if not CONFIG.AutoFarm or isBusy or currentTarget then return end
    if not Root or not Humanoid or Humanoid.Health <= 0 then return end

    local eggs = scanEggs()
    if #eggs == 0 then
        setStatus("Scanning...")
        return
    end

    local best = eggs[1]
    if best then
        smoothMoveTo(best.Part, function(arrived)
            if arrived and best.Object and best.Object.Parent then
                attemptSteal(best.Object)
            end
        end)
    end
end

RunService.Heartbeat:Connect(function()
    if CONFIG.AutoFarm and not isBusy and not currentTarget then
        farmCycle()
    end
end)

----------------------------------------------------------------
-- TOGGLE
----------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.P then
        CONFIG.AutoFarm = not CONFIG.AutoFarm
        if not CONFIG.AutoFarm then
            stopMovement()
            setStatus("Paused")
        else
            setStatus("Running")
        end
        print("[VEKU HUB] AutoFarm:", CONFIG.AutoFarm and "ON" or "OFF")
    end
end)

----------------------------------------------------------------
-- INIT
----------------------------------------------------------------
print("════════════════════════════════════════")
print("  VEKU HUB  •  Smooth Egg Stealer")
print("  Press P to toggle")
print("  Blue UI loaded")
print("  Replace rbxassetid://0 with your logo")
print("════════════════════════════════════════")
setStatus("Ready")
updateCount()
