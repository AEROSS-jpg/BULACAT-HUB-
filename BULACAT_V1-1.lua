-- ═══════════════════════════════════════════════════════════
--         BULACAT HUB V1
--         Game: Steal An Egg
--         by @Bulalo25 | discord.gg/nullstate
--
--  HOW TO USE:
--  1. Open Roblox > Join "Steal An Egg" game
--  2. Open Delta executor > Inject
--  3. Paste this script or loadstring it
--  4. Hit Execute
-- ═══════════════════════════════════════════════════════════

local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local TweenService   = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIS            = game:GetService("UserInputService")
local lp             = Players.LocalPlayer
local char           = lp.Character or lp.CharacterAdded:Wait()
local hrp            = char:WaitForChild("HumanoidRootPart")
local hum            = char:WaitForChild("Humanoid")

lp.CharacterAdded:Connect(function(c)
    char = c
    hrp  = c:WaitForChild("HumanoidRootPart")
    hum  = c:WaitForChild("Humanoid")
end)

-- ── Destroy old GUI ──────────────────────────────────────────
local coreGui = gethui and gethui() or game:GetService("CoreGui")
for _, g in ipairs(coreGui:GetChildren()) do
    if g.Name == "BULACAT_SAE" then g:Destroy() end
end

-- ════════════════════════════════════════════════════════════
--  GUI
-- ════════════════════════════════════════════════════════════
local gui = Instance.new("ScreenGui")
gui.Name           = "BULACAT_SAE"
gui.ResetOnSpawn   = false
gui.Parent         = coreGui

-- Main Frame
local main = Instance.new("Frame")
main.Size            = UDim2.new(0, 350, 0, 500)
main.Position        = UDim2.new(0.5, -175, 0.5, -250)
main.BackgroundColor3 = Color3.fromRGB(13, 13, 18)
main.BorderSizePixel = 0
main.Parent          = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)

local stroke = Instance.new("UIStroke", main)
stroke.Color     = Color3.fromRGB(255, 80, 80)
stroke.Thickness = 2

-- Draggable
local dragging, dragStart, startPos
main.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
    or i.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = i.Position
        startPos  = main.Position
    end
end)
UIS.InputChanged:Connect(function(i)
    if dragging and (
        i.UserInputType == Enum.UserInputType.MouseMovement or
        i.UserInputType == Enum.UserInputType.Touch
    ) then
        local d = i.Position - dragStart
        main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y
        )
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
    or i.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- ── Title Bar ────────────────────────────────────────────────
local titleBar = Instance.new("Frame")
titleBar.Size             = UDim2.new(1, 0, 0, 48)
titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
titleBar.BorderSizePixel  = 0
titleBar.Parent           = main
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 14)

local titleLbl = Instance.new("TextLabel")
titleLbl.Size               = UDim2.new(1, -50, 1, 0)
titleLbl.Position           = UDim2.new(0, 14, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text               = "🐱 BULACAT V1  •  STEAL AN EGG"
titleLbl.TextColor3         = Color3.fromRGB(255, 80, 80)
titleLbl.TextSize           = 14
titleLbl.Font               = Enum.Font.GothamBold
titleLbl.TextXAlignment     = Enum.TextXAlignment.Left
titleLbl.Parent             = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size             = UDim2.new(0, 28, 0, 28)
closeBtn.Position         = UDim2.new(1, -38, 0.5, -14)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
closeBtn.Text             = "✕"
closeBtn.TextColor3       = Color3.fromRGB(255,255,255)
closeBtn.TextSize         = 13
closeBtn.Font             = Enum.Font.GothamBold
closeBtn.BorderSizePixel  = 0
closeBtn.Parent           = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

-- ── Stats Bar ────────────────────────────────────────────────
local statsBar = Instance.new("Frame")
statsBar.Size             = UDim2.new(1, -20, 0, 50)
statsBar.Position         = UDim2.new(0, 10, 0, 56)
statsBar.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
statsBar.BorderSizePixel  = 0
statsBar.Parent           = main
Instance.new("UICorner", statsBar).CornerRadius = UDim.new(0, 10)

local stolenLbl = Instance.new("TextLabel")
stolenLbl.Size               = UDim2.new(0.5, 0, 1, 0)
stolenLbl.BackgroundTransparency = 1
stolenLbl.Text               = "🥚 Stolen: 0"
stolenLbl.TextColor3         = Color3.fromRGB(255, 200, 80)
stolenLbl.TextSize           = 13
stolenLbl.Font               = Enum.Font.GothamBold
stolenLbl.Parent             = statsBar

local statusLbl = Instance.new("TextLabel")
statusLbl.Size               = UDim2.new(0.5, 0, 1, 0)
statusLbl.Position           = UDim2.new(0.5, 0, 0, 0)
statusLbl.BackgroundTransparency = 1
statusLbl.Text               = "⚡ OFF"
statusLbl.TextColor3         = Color3.fromRGB(180,180,180)
statusLbl.TextSize           = 13
statusLbl.Font               = Enum.Font.GothamBold
statusLbl.Parent             = statsBar

-- ── Log Box ──────────────────────────────────────────────────
local logBox = Instance.new("ScrollingFrame")
logBox.Size                 = UDim2.new(1, -20, 0, 155)
logBox.Position             = UDim2.new(0, 10, 0, 115)
logBox.BackgroundColor3     = Color3.fromRGB(18, 18, 26)
logBox.BorderSizePixel      = 0
logBox.ScrollBarThickness   = 3
logBox.ScrollBarImageColor3 = Color3.fromRGB(255, 80, 80)
logBox.Parent               = main
Instance.new("UICorner", logBox).CornerRadius = UDim.new(0, 10)

local logLayout = Instance.new("UIListLayout", logBox)
logLayout.SortOrder = Enum.SortOrder.LayoutOrder
logLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    logBox.CanvasSize     = UDim2.new(0, 0, 0, logLayout.AbsoluteContentSize.Y + 8)
    logBox.CanvasPosition = Vector2.new(0, logLayout.AbsoluteContentSize.Y)
end)

local logCount = 0
local function log(msg, color)
    logCount += 1
    local l = Instance.new("TextLabel")
    l.Size               = UDim2.new(1, -10, 0, 20)
    l.BackgroundTransparency = 1
    l.Text               = "  " .. msg
    l.TextColor3         = color or Color3.fromRGB(200, 200, 200)
    l.TextSize           = 11
    l.Font               = Enum.Font.Gotham
    l.TextXAlignment     = Enum.TextXAlignment.Left
    l.LayoutOrder        = logCount
    l.Parent             = logBox
    if logCount > 50 then
        local kids = logBox:GetChildren()
        for _, k in ipairs(kids) do
            if k:IsA("TextLabel") then k:Destroy() break end
        end
    end
end

-- ── Buttons ──────────────────────────────────────────────────
local ctrlFrame = Instance.new("Frame")
ctrlFrame.Size               = UDim2.new(1, -20, 0, 220)
ctrlFrame.Position           = UDim2.new(0, 10, 0, 278)
ctrlFrame.BackgroundTransparency = 1
ctrlFrame.Parent             = main

local ctrlLayout = Instance.new("UIListLayout", ctrlFrame)
ctrlLayout.Padding = UDim.new(0, 8)

local function makeBtn(txt, col)
    local b = Instance.new("TextButton")
    b.Size             = UDim2.new(1, 0, 0, 44)
    b.BackgroundColor3 = col or Color3.fromRGB(255, 80, 80)
    b.Text             = txt
    b.TextColor3       = Color3.fromRGB(255, 255, 255)
    b.TextSize         = 14
    b.Font             = Enum.Font.GothamBold
    b.BorderSizePixel  = 0
    b.Parent           = ctrlFrame
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)

    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), {
            BackgroundColor3 = b.BackgroundColor3:Lerp(Color3.fromRGB(255,255,255), 0.15)
        }):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), {
            BackgroundColor3 = col or Color3.fromRGB(255, 80, 80)
        }):Play()
    end)
    return b
end

local autoStealBtn = makeBtn("🥚 AUTO STEAL EGG",  Color3.fromRGB(40, 180, 80))
local autoFarmBtn  = makeBtn("💰 AUTO FARM SP",    Color3.fromRGB(80, 80, 200))
local speedBtn     = makeBtn("⚡ SPEED BOOST x5",  Color3.fromRGB(180, 120, 20))
local stopBtn      = makeBtn("⏹  STOP ALL",        Color3.fromRGB(200, 50, 50))

-- Watermark
local wm = Instance.new("TextLabel")
wm.Size               = UDim2.new(1, 0, 0, 22)
wm.Position           = UDim2.new(0, 0, 1, -24)
wm.BackgroundTransparency = 1
wm.Text               = "🐱 BULACAT V1 | @Bulalo25 | discord.gg/nullstate"
wm.TextColor3         = Color3.fromRGB(90, 90, 110)
wm.TextSize           = 10
wm.Font               = Enum.Font.Gotham
wm.Parent             = main

-- ════════════════════════════════════════════════════════════
--  CORE LOGIC
-- ════════════════════════════════════════════════════════════
local stolen     = 0
local running    = { steal = false, farm = false, speed = false }
local conns      = {}

local function stopAll()
    for k, c in pairs(conns) do
        if c and typeof(c) == "RBXScriptConnection" then c:Disconnect() end
        conns[k] = nil
    end
    running.steal = false
    running.farm  = false
    running.speed = false
    if hum then hum.WalkSpeed = 16 end
    statusLbl.Text      = "⚡ OFF"
    statusLbl.TextColor3 = Color3.fromRGB(180, 180, 180)
    log("⏹ Stopped all.", Color3.fromRGB(200, 80, 80))
end

-- ── Helper: find nearest egg in workspace ────────────────────
local function getNearestEgg()
    local best, bestDist = nil, math.huge
    -- eggs are usually tagged or named "Egg" / "StealEgg" in workspace
    local searchFolders = {
        workspace:FindFirstChild("Eggs"),
        workspace:FindFirstChild("Interactables"),
        workspace:FindFirstChild("Map"),
        workspace,
    }
    for _, folder in ipairs(searchFolders) do
        if folder then
            for _, obj in ipairs(folder:GetDescendants()) do
                if obj:IsA("BasePart") or obj:IsA("Model") then
                    local name = obj.Name:lower()
                    if name:find("egg") or name:find("steal") then
                        local pos = obj:IsA("Model")
                            and (obj.PrimaryPart and obj.PrimaryPart.Position or obj:GetModelCFrame().Position)
                            or obj.Position
                        if hrp then
                            local dist = (hrp.Position - pos).Magnitude
                            if dist < bestDist then
                                bestDist = dist
                                best     = obj
                            end
                        end
                    end
                end
            end
        end
    end
    return best, bestDist
end

-- ── Helper: teleport to part ─────────────────────────────────
local function tpTo(target)
    if not hrp then return end
    local pos
    if target:IsA("Model") and target.PrimaryPart then
        pos = target.PrimaryPart.Position
    elseif target:IsA("BasePart") then
        pos = target.Position
    else
        pos = target:GetModelCFrame().Position
    end
    hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
end

-- ── Helper: fire remote to interact ──────────────────────────
local function tryFireRemote(remoteName, ...)
    local remotes = {
        ReplicatedStorage:FindFirstChild("Remotes"),
        ReplicatedStorage:FindFirstChild("Events"),
        ReplicatedStorage,
    }
    for _, folder in ipairs(remotes) do
        if folder then
            local r = folder:FindFirstChild(remoteName, true)
            if r and r:IsA("RemoteEvent") then
                r:FireServer(...)
                return true
            end
            if r and r:IsA("RemoteFunction") then
                r:InvokeServer(...)
                return true
            end
        end
    end
    return false
end

-- ════════════════════════════════════════════════════════════
--  AUTO STEAL EGG
-- ════════════════════════════════════════════════════════════
autoStealBtn.MouseButton1Click:Connect(function()
    if running.steal then
        log("Already running steal!", Color3.fromRGB(255,200,80))
        return
    end
    stopAll()
    running.steal        = true
    statusLbl.Text       = "🥚 STEALING..."
    statusLbl.TextColor3 = Color3.fromRGB(80, 220, 80)
    log("🥚 Auto steal started.", Color3.fromRGB(80, 220, 80))

    conns.steal = RunService.Heartbeat:Connect(function()
        if not running.steal then return end
        local egg, dist = getNearestEgg()
        if egg then
            -- Teleport close
            if dist > 8 then
                tpTo(egg)
                log("📍 TP to egg: " .. egg.Name, Color3.fromRGB(180,180,255))
            end
            -- Try known remote names for this game
            local fired = false
            for _, rName in ipairs({"StealEgg","Steal","CollectEgg","Collect","PickupEgg","Interact"}) do
                if tryFireRemote(rName, egg) then
                    fired = true
                    stolen += 1
                    stolenLbl.Text = "🥚 Stolen: " .. stolen
                    log("✅ Stole: " .. egg.Name, Color3.fromRGB(80,220,80))
                    break
                end
            end
            -- Fallback: touch the egg
            if not fired and hrp then
                hrp.CFrame = CFrame.new(
                    egg:IsA("Model") and egg:GetModelCFrame().Position
                    or egg.Position
                )
                task.wait(0.1)
                stolen += 1
                stolenLbl.Text = "🥚 Stolen: " .. stolen
                log("👆 Touched: " .. egg.Name, Color3.fromRGB(255,200,80))
            end
        else
            log("🔍 Searching for eggs...", Color3.fromRGB(160,160,160))
        end
        task.wait(0.5)
    end)
end)

-- ════════════════════════════════════════════════════════════
--  AUTO FARM SP (Coins / Score)
-- ════════════════════════════════════════════════════════════
autoFarmBtn.MouseButton1Click:Connect(function()
    if running.farm then
        log("Already farming!", Color3.fromRGB(255,200,80))
        return
    end
    stopAll()
    running.farm         = true
    statusLbl.Text       = "💰 FARMING SP..."
    statusLbl.TextColor3 = Color3.fromRGB(80, 120, 255)
    log("💰 Auto farm SP started.", Color3.fromRGB(80,120,255))

    conns.farm = RunService.Heartbeat:Connect(function()
        if not running.farm then return end
        -- Find SP pickups / coins
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") or obj:IsA("Model") then
                local name = obj.Name:lower()
                if name:find("sp") or name:find("coin") or name:find("point") or name:find("score") or name:find("cash") then
                    tpTo(obj)
                    for _, rName in ipairs({"CollectSP","Collect","PickupSP","ClaimSP","Pickup"}) do
                        tryFireRemote(rName, obj)
                    end
                    log("💰 Collected: " .. obj.Name, Color3.fromRGB(255,220,60))
                    task.wait(0.05)
                end
            end
        end
        task.wait(0.3)
    end)
end)

-- ════════════════════════════════════════════════════════════
--  SPEED BOOST
-- ════════════════════════════════════════════════════════════
speedBtn.MouseButton1Click:Connect(function()
    running.speed = not running.speed
    if running.speed then
        if hum then hum.WalkSpeed = 120 end
        statusLbl.Text       = "⚡ SPEED ON"
        statusLbl.TextColor3 = Color3.fromRGB(255,180,40)
        speedBtn.Text        = "⚡ SPEED BOOST [ON]"
        log("⚡ Speed boost ON (120)", Color3.fromRGB(255,180,40))

        -- Re-apply on respawn
        conns.speedRespawn = lp.CharacterAdded:Connect(function(c)
            local h = c:WaitForChild("Humanoid")
            if running.speed then h.WalkSpeed = 120 end
        end)
    else
        if hum then hum.WalkSpeed = 16 end
        if conns.speedRespawn then conns.speedRespawn:Disconnect() end
        statusLbl.Text       = "⚡ OFF"
        statusLbl.TextColor3 = Color3.fromRGB(180,180,180)
        speedBtn.Text        = "⚡ SPEED BOOST x5"
        log("⚡ Speed boost OFF", Color3.fromRGB(180,180,180))
    end
end)

-- ════════════════════════════════════════════════════════════
--  STOP ALL
-- ════════════════════════════════════════════════════════════
stopBtn.MouseButton1Click:Connect(stopAll)

-- ── Init log ─────────────────────────────────────────────────
log("🐱 BULACAT V1 loaded!", Color3.fromRGB(255,80,80))
log("📌 Game: Steal An Egg", Color3.fromRGB(200,200,200))
log("👑 by @Bulalo25", Color3.fromRGB(255,200,80))
log("─────────────────────────", Color3.fromRGB(60,60,80))
log("Press AUTO STEAL to begin.", Color3.fromRGB(160,160,160))
