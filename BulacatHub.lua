-- // ============================================
-- // BULACAT HUB - Egg Stealer
-- // Executor: KRNL / Synapse X / Fluxus
-- // Safe: Client-only, no server flags
-- // ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Root = Character:WaitForChild("HumanoidRootPart")

-- // CONFIG
local EGG_NAME_KEYWORDS = {"Egg"}
local STEAL_DELAY = 0.8
local SCAN_INTERVAL = 1

-- // RARITY COLORS
local RARITY_COLORS = {
    Divine   = Color3.fromRGB(255, 215, 0),
    Eternal  = Color3.fromRGB(180, 0, 255),
    Secret   = Color3.fromRGB(255, 50, 50),
    Cosmic   = Color3.fromRGB(0, 200, 255),
    Rare     = Color3.fromRGB(0, 120, 255),
    Uncommon = Color3.fromRGB(0, 200, 80),
    Common   = Color3.fromRGB(200, 200, 200),
}

local RARITY_ORDER = {"Divine","Eternal","Secret","Cosmic","Rare","Uncommon","Common"}

-- // PREDICT RARITY
local function predictRarity(egg)
    local name = egg.Name:lower()
    if name:find("divine")   then return "Divine"   end
    if name:find("eternal")  then return "Eternal"  end
    if name:find("secret")   then return "Secret"   end
    if name:find("cosmic")   then return "Cosmic"   end
    if name:find("rare")     then return "Rare"     end
    if name:find("uncommon") then return "Uncommon" end
    for _, v in ipairs(egg:GetDescendants()) do
        if v:IsA("StringValue") or v:IsA("TextLabel") then
            local t = (v.Value or v.Text or ""):lower()
            if t:find("divine")   then return "Divine"   end
            if t:find("eternal")  then return "Eternal"  end
            if t:find("secret")   then return "Secret"   end
            if t:find("cosmic")   then return "Cosmic"   end
            if t:find("rare")     then return "Rare"     end
            if t:find("uncommon") then return "Uncommon" end
        end
    end
    return "Common"
end

-- // PREDICT PET
local function predictPet(egg)
    for _, v in ipairs(egg:GetDescendants()) do
        if v:IsA("StringValue") and (
            v.Name:lower():find("pet") or
            v.Name:lower():find("reward") or
            v.Name:lower():find("hatch") or
            v.Name:lower():find("item")
        ) then
            return v.Value ~= "" and v.Value or "Unknown Pet"
        end
        if v:IsA("TextLabel") and v.Text ~= "" then
            return v.Text
        end
    end
    return "Mystery Pet 🐾"
end

-- // SCAN EGGS
local function scanEggs()
    local found = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        for _, kw in ipairs(EGG_NAME_KEYWORDS) do
            if obj.Name:lower():find(kw:lower()) and obj:IsA("BasePart") and obj.Parent then
                local rarity = predictRarity(obj)
                local pet    = predictPet(obj)
                local dist   = math.floor((Root.Position - obj.Position).Magnitude)
                table.insert(found, { egg = obj, rarity = rarity, pet = pet, dist = dist })
                break
            end
        end
    end
    local order = {}
    for i, v in ipairs(RARITY_ORDER) do order[v] = i end
    table.sort(found, function(a, b)
        return (order[a.rarity] or 99) < (order[b.rarity] or 99)
    end)
    return found
end

-- // STEAL EGG
local function stealEgg(egg)
    if not egg or not egg.Parent then return end
    Root.CFrame = CFrame.new(egg.Position + Vector3.new(0, 3, 0))
    task.wait(0.15)
    local touch = egg:FindFirstChildOfClass("TouchTransmitter")
    if touch then
        firetouchinterest(Root, egg, 0)
        task.wait(0.1)
        firetouchinterest(Root, egg, 1)
    end
    local click = egg:FindFirstChildOfClass("ClickDetector")
    if click then fireclickdetector(click) end
    local prompt = egg:FindFirstChildOfClass("ProximityPrompt")
        or egg.Parent:FindFirstChildOfClass("ProximityPrompt")
    if prompt then fireproximityprompt(prompt) end
end

-- // ─────────────────────────────────────────────
-- // UI
-- // ─────────────────────────────────────────────

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BulacatHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui")

-- // Circle Toggle Button (BULACAT HUB Logo)
local CircleBtn = Instance.new("TextButton")
CircleBtn.Size = UDim2.new(0, 64, 0, 64)
CircleBtn.Position = UDim2.new(0, 16, 0.5, -32)
CircleBtn.BackgroundColor3 = Color3.fromRGB(10, 10, 22)
CircleBtn.Text = ""
CircleBtn.BorderSizePixel = 0
CircleBtn.Parent = ScreenGui
Instance.new("UICorner", CircleBtn).CornerRadius = UDim.new(1, 0)
local circleStroke = Instance.new("UIStroke", CircleBtn)
circleStroke.Color = Color3.fromRGB(0, 200, 255)
circleStroke.Thickness = 2.5

-- Cat emoji (logo icon)
local CircleCat = Instance.new("TextLabel")
CircleCat.Size = UDim2.new(1, 0, 0, 32)
CircleCat.Position = UDim2.new(0, 0, 0, 4)
CircleCat.BackgroundTransparency = 1
CircleCat.Text = "🐱"
CircleCat.TextSize = 26
CircleCat.Font = Enum.Font.GothamBold
CircleCat.TextXAlignment = Enum.TextXAlignment.Center
CircleCat.Parent = CircleBtn

-- "BH" text under cat
local CircleText = Instance.new("TextLabel")
CircleText.Size = UDim2.new(1, 0, 0, 18)
CircleText.Position = UDim2.new(0, 0, 1, -20)
CircleText.BackgroundTransparency = 1
CircleText.Text = "BH"
CircleText.TextSize = 10
CircleText.Font = Enum.Font.GothamBold
CircleText.TextColor3 = Color3.fromRGB(0, 200, 255)
CircleText.TextXAlignment = Enum.TextXAlignment.Center
CircleText.Parent = CircleBtn

-- // Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 420, 0, 540)
MainFrame.Position = UDim2.new(0, 90, 0.5, -270)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)
local mainStroke = Instance.new("UIStroke", MainFrame)
mainStroke.Color = Color3.fromRGB(0, 200, 255)
mainStroke.Thickness = 1.5

-- // Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 12)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -50, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🐱 BULACAT HUB"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 18
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

-- // Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -38, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(1, 0)

-- // Rarity Filter Bar
local FilterBar = Instance.new("Frame")
FilterBar.Size = UDim2.new(1, -20, 0, 36)
FilterBar.Position = UDim2.new(0, 10, 0, 48)
FilterBar.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
FilterBar.BorderSizePixel = 0
FilterBar.Parent = MainFrame
Instance.new("UICorner", FilterBar).CornerRadius = UDim.new(0, 8)
local filterLayout = Instance.new("UIListLayout", FilterBar)
filterLayout.FillDirection = Enum.FillDirection.Horizontal
filterLayout.Padding = UDim.new(0, 4)
filterLayout.VerticalAlignment = Enum.VerticalAlignment.Center
Instance.new("UIPadding", FilterBar).PaddingLeft = UDim.new(0, 6)

local selectedRarities = {Divine=true, Eternal=true, Secret=true, Cosmic=true}
local filterBtns = {}

-- Rarity emoji map
local RARITY_EMOJI = {
    Divine  = "🟨",
    Eternal = "🌌",
    Secret  = "⬛",
    Cosmic  = "🟪",
}

for _, rar in ipairs({"Divine","Eternal","Secret","Cosmic"}) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 90, 0, 26)
    btn.BackgroundColor3 = RARITY_COLORS[rar]
    btn.Text = (RARITY_EMOJI[rar] or "") .. " " .. rar
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Parent = FilterBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    filterBtns[rar] = btn

    btn.MouseButton1Click:Connect(function()
        selectedRarities[rar] = not selectedRarities[rar]
        btn.BackgroundTransparency = selectedRarities[rar] and 0 or 0.6
    end)
end

-- // Egg List ScrollFrame
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -20, 0, 310)
ScrollFrame.Position = UDim2.new(0, 10, 0, 92)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 200, 255)
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollFrame.Parent = MainFrame
Instance.new("UICorner", ScrollFrame).CornerRadius = UDim.new(0, 8)
local listLayout = Instance.new("UIListLayout", ScrollFrame)
listLayout.Padding = UDim.new(0, 4)
Instance.new("UIPadding", ScrollFrame).PaddingTop = UDim.new(0, 4)

-- // Bottom Controls
local ControlBar = Instance.new("Frame")
ControlBar.Size = UDim2.new(1, -20, 0, 90)
ControlBar.Position = UDim2.new(0, 10, 0, 440)
ControlBar.BackgroundTransparency = 1
ControlBar.Parent = MainFrame

-- AUTO STEAL Checkbox
local AutoFrame = Instance.new("Frame")
AutoFrame.Size = UDim2.new(0.5, -5, 0, 36)
AutoFrame.Position = UDim2.new(0, 0, 0, 0)
AutoFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
AutoFrame.BorderSizePixel = 0
AutoFrame.Parent = ControlBar
Instance.new("UICorner", AutoFrame).CornerRadius = UDim.new(0, 8)

local AutoCheck = Instance.new("TextButton")
AutoCheck.Size = UDim2.new(0, 22, 0, 22)
AutoCheck.Position = UDim2.new(0, 8, 0.5, -11)
AutoCheck.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
AutoCheck.Text = ""
AutoCheck.BorderSizePixel = 0
AutoCheck.Parent = AutoFrame
Instance.new("UICorner", AutoCheck).CornerRadius = UDim.new(0, 4)
Instance.new("UIStroke", AutoCheck).Color = Color3.fromRGB(0, 200, 255)

local AutoCheckInner = Instance.new("Frame")
AutoCheckInner.Size = UDim2.new(0, 14, 0, 14)
AutoCheckInner.Position = UDim2.new(0.5, -7, 0.5, -7)
AutoCheckInner.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
AutoCheckInner.BorderSizePixel = 0
AutoCheckInner.Visible = false
AutoCheckInner.Parent = AutoCheck
Instance.new("UICorner", AutoCheckInner).CornerRadius = UDim.new(0, 3)

local AutoLabel = Instance.new("TextLabel")
AutoLabel.Size = UDim2.new(1, -38, 1, 0)
AutoLabel.Position = UDim2.new(0, 36, 0, 0)
AutoLabel.BackgroundTransparency = 1
AutoLabel.Text = "Auto Steal"
AutoLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
AutoLabel.TextSize = 13
AutoLabel.Font = Enum.Font.GothamBold
AutoLabel.TextXAlignment = Enum.TextXAlignment.Left
AutoLabel.Parent = AutoFrame

-- STEAL ONCE Checkbox
local OnceFrame = Instance.new("Frame")
OnceFrame.Size = UDim2.new(0.5, -5, 0, 36)
OnceFrame.Position = UDim2.new(0.5, 5, 0, 0)
OnceFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
OnceFrame.BorderSizePixel = 0
OnceFrame.Parent = ControlBar
Instance.new("UICorner", OnceFrame).CornerRadius = UDim.new(0, 8)

local OnceCheck = Instance.new("TextButton")
OnceCheck.Size = UDim2.new(0, 22, 0, 22)
OnceCheck.Position = UDim2.new(0, 8, 0.5, -11)
OnceCheck.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
OnceCheck.Text = ""
OnceCheck.BorderSizePixel = 0
OnceCheck.Parent = OnceFrame
Instance.new("UICorner", OnceCheck).CornerRadius = UDim.new(0, 4)
Instance.new("UIStroke", OnceCheck).Color = Color3.fromRGB(255, 180, 0)

local OnceCheckInner = Instance.new("Frame")
OnceCheckInner.Size = UDim2.new(0, 14, 0, 14)
OnceCheckInner.Position = UDim2.new(0.5, -7, 0.5, -7)
OnceCheckInner.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
OnceCheckInner.BorderSizePixel = 0
OnceCheckInner.Visible = false
OnceCheckInner.Parent = OnceCheck
Instance.new("UICorner", OnceCheckInner).CornerRadius = UDim.new(0, 3)

local OnceLabel = Instance.new("TextLabel")
OnceLabel.Size = UDim2.new(1, -38, 1, 0)
OnceLabel.Position = UDim2.new(0, 36, 0, 0)
OnceLabel.BackgroundTransparency = 1
OnceLabel.Text = "Steal Once"
OnceLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
OnceLabel.TextSize = 13
OnceLabel.Font = Enum.Font.GothamBold
OnceLabel.TextXAlignment = Enum.TextXAlignment.Left
OnceLabel.Parent = OnceFrame

-- Status Label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 24)
StatusLabel.Position = UDim2.new(0, 0, 0, 44)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "⬛ BULACAT HUB — Idle"
StatusLabel.TextColor3 = Color3.fromRGB(140, 140, 180)
StatusLabel.TextSize = 12
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Center
StatusLabel.Parent = ControlBar

-- // ─────────────────────────────────────────────
-- // STATE
-- // ─────────────────────────────────────────────

local autoStealOn  = false
local stealOnce    = false
local selectedEgg  = nil
local stealOnceDidIt = false

-- // Checkbox logic
AutoCheck.MouseButton1Click:Connect(function()
    autoStealOn = not autoStealOn
    AutoCheckInner.Visible = autoStealOn
    StatusLabel.Text = autoStealOn and "🟢 Auto Steal ON" or "⬛ BULACAT HUB — Idle"
    stealOnceDidIt = false
end)

OnceCheck.MouseButton1Click:Connect(function()
    stealOnce = not stealOnce
    OnceCheckInner.Visible = stealOnce
    stealOnceDidIt = false
end)

-- // Circle Toggle
CircleBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

-- // Build Egg Row
local function buildEggRow(data)
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, -8, 0, 54)
    row.BackgroundColor3 = Color3.fromRGB(22, 22, 36)
    row.BorderSizePixel = 0
    row.Text = ""
    row.Parent = ScrollFrame
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local rarColor = RARITY_COLORS[data.rarity] or Color3.fromRGB(200,200,200)

    local rarBar = Instance.new("Frame")
    rarBar.Size = UDim2.new(0, 4, 1, -10)
    rarBar.Position = UDim2.new(0, 6, 0, 5)
    rarBar.BackgroundColor3 = rarColor
    rarBar.BorderSizePixel = 0
    rarBar.Parent = row
    Instance.new("UICorner", rarBar).CornerRadius = UDim.new(0, 4)

    local petLabel = Instance.new("TextLabel")
    petLabel.Size = UDim2.new(1, -80, 0, 22)
    petLabel.Position = UDim2.new(0, 18, 0, 6)
    petLabel.BackgroundTransparency = 1
    petLabel.Text = "🐾 " .. data.pet
    petLabel.TextColor3 = Color3.fromRGB(240, 240, 255)
    petLabel.TextSize = 13
    petLabel.Font = Enum.Font.GothamBold
    petLabel.TextXAlignment = Enum.TextXAlignment.Left
    petLabel.TextTruncate = Enum.TextTruncate.AtEnd
    petLabel.Parent = row

    local rarLabel = Instance.new("TextLabel")
    rarLabel.Size = UDim2.new(1, -80, 0, 18)
    rarLabel.Position = UDim2.new(0, 18, 0, 28)
    rarLabel.BackgroundTransparency = 1
    rarLabel.Text = data.rarity .. "  •  " .. data.dist .. " studs"
    rarLabel.TextColor3 = rarColor
    rarLabel.TextSize = 11
    rarLabel.Font = Enum.Font.Gotham
    rarLabel.TextXAlignment = Enum.TextXAlignment.Left
    rarLabel.Parent = row

    local stealBtn = Instance.new("TextButton")
    stealBtn.Size = UDim2.new(0, 60, 0, 30)
    stealBtn.Position = UDim2.new(1, -68, 0.5, -15)
    stealBtn.BackgroundColor3 = rarColor
    stealBtn.Text = "STEAL"
    stealBtn.TextColor3 = Color3.fromRGB(255,255,255)
    stealBtn.TextSize = 11
    stealBtn.Font = Enum.Font.GothamBold
    stealBtn.BorderSizePixel = 0
    stealBtn.Parent = row
    Instance.new("UICorner", stealBtn).CornerRadius = UDim.new(0, 6)

    row.MouseButton1Click:Connect(function()
        selectedEgg = data.egg
        StatusLabel.Text = "👆 Selected: " .. data.pet
        for _, r in ipairs(ScrollFrame:GetChildren()) do
            if r:IsA("TextButton") then
                r.BackgroundColor3 = Color3.fromRGB(22, 22, 36)
            end
        end
        row.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
    end)

    stealBtn.MouseButton1Click:Connect(function()
        StatusLabel.Text = "🔄 Stealing: " .. data.pet
        stealEgg(data.egg)
        task.wait(0.5)
        StatusLabel.Text = "✅ Stolen: " .. data.pet
    end)
end

-- // Refresh Egg List
local function refreshList()
    for _, c in ipairs(ScrollFrame:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    local eggs = scanEggs()
    for _, data in ipairs(eggs) do
        if selectedRarities[data.rarity] then
            buildEggRow(data)
        end
    end
end

-- // Scan Loop
task.spawn(function()
    while true do
        task.wait(SCAN_INTERVAL)
        if MainFrame.Visible then
            refreshList()
        end
    end
end)

-- // Auto Steal Loop
task.spawn(function()
    while true do
        task.wait(STEAL_DELAY)
        if autoStealOn then
            if stealOnce and stealOnceDidIt then
                autoStealOn = false
                AutoCheckInner.Visible = false
                StatusLabel.Text = "✅ Steal Once Done"
            else
                local eggs = scanEggs()
                for _, data in ipairs(eggs) do
                    if selectedRarities[data.rarity] then
                        StatusLabel.Text = "🔄 Auto: " .. data.pet
                        stealEgg(data.egg)
                        if stealOnce then
                            stealOnceDidIt = true
                        end
                        break
                    end
                end
            end
        end
    end
end)

-- // Draggable
local dragging, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

print("🐱 BULACAT HUB Loaded — Click the egg circle to open!")
