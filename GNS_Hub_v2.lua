-- // ============================================
-- // ⚡ GNS HUB v2 — Full Clean Rewrite
-- // Game: Steal An Egg
-- // Executor: KRNL / Synapse X / Fluxus / Delta
-- // ============================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer      = Players.LocalPlayer

-- // SAFE GETTERS
local function getChar()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end
local function getRoot()
    local ok, c = pcall(getChar)
    if not ok or not c then return nil end
    return c:FindFirstChild("HumanoidRootPart")
end
local function getHuman()
    local ok, c = pcall(getChar)
    if not ok or not c then return nil end
    return c:FindFirstChildOfClass("Humanoid")
end

-- // COLORS
local C = {
    bg       = Color3.fromRGB(8,10,20),
    sidebar  = Color3.fromRGB(12,14,28),
    panel    = Color3.fromRGB(16,18,36),
    card     = Color3.fromRGB(20,24,46),
    accent   = Color3.fromRGB(50,130,255),
    accentHi = Color3.fromRGB(100,175,255),
    accentDim= Color3.fromRGB(30,70,160),
    text     = Color3.fromRGB(220,228,245),
    subtext  = Color3.fromRGB(120,135,170),
    dim      = Color3.fromRGB(70,82,115),
    green    = Color3.fromRGB(60,220,130),
    red      = Color3.fromRGB(255,70,70),
    gold     = Color3.fromRGB(255,205,50),
    purple   = Color3.fromRGB(155,75,255),
    cyan     = Color3.fromRGB(0,215,255),
    border   = Color3.fromRGB(30,36,64),
}

-- // RARITY
local RARITY_DATA = {
    {name="Cosmic",    color=Color3.fromRGB(160,80,255),  rank=1},
    {name="Divine",    color=Color3.fromRGB(255,215,0),   rank=2},
    {name="Eternal",   color=Color3.fromRGB(180,60,255),  rank=3},
    {name="Secret",    color=Color3.fromRGB(255,60,60),   rank=4},
    {name="Mythic",    color=Color3.fromRGB(255,140,0),   rank=5},
    {name="Legendary", color=Color3.fromRGB(255,200,0),   rank=6},
    {name="Epic",      color=Color3.fromRGB(140,0,255),   rank=7},
    {name="Rare",      color=Color3.fromRGB(0,120,255),   rank=8},
    {name="Uncommon",  color=Color3.fromRGB(0,200,80),    rank=9},
    {name="Common",    color=Color3.fromRGB(160,160,160), rank=10},
}
local RARITY_MAP = {}
for _, r in ipairs(RARITY_DATA) do RARITY_MAP[r.name] = r end
local function getRD(n) return RARITY_MAP[n] or RARITY_MAP["Common"] end

-- // ─────────────────────────────────────────────
-- // UI HELPERS
-- // ─────────────────────────────────────────────
local function mk(class, props, parent)
    local i = Instance.new(class)
    for k, v in pairs(props) do i[k] = v end
    if parent then i.Parent = parent end
    return i
end
local function corner(r, p)
    mk("UICorner", {CornerRadius=UDim.new(0,r)}, p)
end
local function pad(l, r, t, b, p)
    local u = Instance.new("UIPadding")
    u.PaddingLeft=UDim.new(0,l) u.PaddingRight=UDim.new(0,r)
    u.PaddingTop=UDim.new(0,t)  u.PaddingBottom=UDim.new(0,b)
    u.Parent = p
end

-- // DRAG — threshold so click still fires
local function makeDraggable(handle, target)
    local dragging = false
    local didDrag  = false
    local startPos, startMouse = nil, nil
    local THRESH = 5

    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging   = true
            didDrag    = false
            startMouse = inp.Position
            startPos   = target.Position
        end
    end)

    handle.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseMovement
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = inp.Position - startMouse
        if delta.Magnitude >= THRESH then
            didDrag = true
        end
        if didDrag then
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    return function() return didDrag end
end

-- // ─────────────────────────────────────────────
-- // SCANNERS
-- // ─────────────────────────────────────────────
local function predictRarity(obj)
    local keys   = {"cosmic","divine","eternal","secret","mythic","legendary","epic","rare","uncommon"}
    local mapped = {"Cosmic","Divine","Eternal","Secret","Mythic","Legendary","Epic","Rare","Uncommon"}
    local nm = obj.Name:lower()
    for i, kw in ipairs(keys) do if nm:find(kw) then return mapped[i] end end
    for _, v in ipairs(obj:GetDescendants()) do
        local t = ""
        if v:IsA("StringValue") then
            local vn = v.Name:lower()
            t = (v.Value or ""):lower()
            for i, kw in ipairs(keys) do if vn:find(kw) or t:find(kw) then return mapped[i] end end
        elseif v:IsA("TextLabel") or v:IsA("TextButton") then
            t = (v.Text or ""):lower()
            for i, kw in ipairs(keys) do if t:find(kw) then return mapped[i] end end
        elseif v:IsA("IntValue") and v.Name:lower():find("rar") then
            local m={[1]="Cosmic",[2]="Divine",[3]="Eternal",[4]="Secret",[5]="Mythic",[6]="Legendary",[7]="Epic",[8]="Rare",[9]="Uncommon"}
            if m[v.Value] then return m[v.Value] end
        end
    end
    if obj.Parent then
        local pnm = obj.Parent.Name:lower()
        for i, kw in ipairs(keys) do if pnm:find(kw) then return mapped[i] end end
    end
    return "Common"
end

local PET_KEYS = {"pet","reward","hatch","item","name","prize","animal","give"}
local function predictPet(obj)
    for _, v in ipairs(obj:GetDescendants()) do
        if v:IsA("StringValue") and v.Value ~= "" and #v.Value < 60 then
            local vn = v.Name:lower()
            for _, k in ipairs(PET_KEYS) do if vn:find(k) then return v.Value end end
        end
    end
    for _, v in ipairs(obj:GetDescendants()) do
        if v:IsA("TextLabel") and v.Text ~= "" and #v.Text < 50 then
            local t = v.Text:lower()
            if not t:find("click") and not t:find("press") and not t:find("open") and not t:find("buy") then
                return v.Text
            end
        end
    end
    if obj.Parent then
        for _, v in ipairs(obj.Parent:GetChildren()) do
            if v:IsA("StringValue") and v.Value ~= "" then
                local vn = v.Name:lower()
                for _, k in ipairs(PET_KEYS) do if vn:find(k) then return v.Value end end
            end
        end
    end
    local nm = obj.Name:gsub("[Ee]gg",""):gsub("^%s+",""):gsub("%s+$","")
    return (nm ~= "") and (nm.." Pet") or "Unknown Pet"
end

local function getEggValue(obj)
    for _, v in ipairs(obj:GetDescendants()) do
        if v:IsA("NumberValue") or v:IsA("IntValue") then
            local nm = v.Name:lower()
            if (nm:find("value") or nm:find("coin") or nm:find("price") or nm:find("worth")) and v.Value > 0 then
                local val = v.Value
                if val >= 1e9 then return string.format("%.1fB",val/1e9)
                elseif val >= 1e6 then return string.format("%.1fM",val/1e6)
                elseif val >= 1e3 then return string.format("%.1fK",val/1e3) end
                return tostring(val)
            end
        end
    end
    return ""
end

local function scanAllEggs()
    local root = getRoot()
    if not root then return {} end
    local found, seen = {}, {}
    local function recurse(folder)
        local ok, children = pcall(function() return folder:GetChildren() end)
        if not ok then return end
        for _, obj in ipairs(children) do
            if not seen[obj] then
                seen[obj] = true
                local nm = obj.Name:lower()
                if nm:find("egg") then
                    local pos = nil
                    if obj:IsA("BasePart") then
                        pos = obj.Position
                    elseif obj:IsA("Model") then
                        local ok2, cf = pcall(function() return obj:GetModelCFrame() end)
                        if ok2 and cf then pos = cf.Position end
                    end
                    if pos then
                        table.insert(found, {
                            obj    = obj,
                            rarity = predictRarity(obj),
                            pet    = predictPet(obj),
                            value  = getEggValue(obj),
                            dist   = math.floor((root.Position - pos).Magnitude),
                            pos    = pos,
                        })
                    end
                end
                pcall(recurse, obj)
            end
        end
    end
    recurse(workspace)
    table.sort(found, function(a, b)
        local ra = getRD(a.rarity).rank
        local rb = getRD(b.rarity).rank
        if ra ~= rb then return ra < rb end
        return a.dist < b.dist
    end)
    return found
end

-- // ─────────────────────────────────────────────
-- // GOD MODE
-- // ─────────────────────────────────────────────
local godConn = nil
local function enableGodMode()
    pcall(function()
        local hum = getHuman()
        if not hum then return end
        hum.MaxHealth = math.huge
        hum.Health    = math.huge
        if godConn then godConn:Disconnect() end
        godConn = hum.HealthChanged:Connect(function(hp)
            pcall(function()
                if hp < math.huge then hum.Health = math.huge end
            end)
        end)
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead,false) end)
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown,false) end)
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,false) end)
        local c = getChar()
        if c then
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then pcall(function() p.CanCollide=false end) end
            end
        end
    end)
end

local function disableGodMode()
    if godConn then godConn:Disconnect() godConn = nil end
    pcall(function()
        local hum = getHuman()
        if not hum then return end
        hum.MaxHealth = 100
        hum.Health    = 100
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead,true) end)
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown,true) end)
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,true) end)
        local c = getChar()
        if c then
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then pcall(function() p.CanCollide=true end) end
            end
        end
    end)
end

-- // ─────────────────────────────────────────────
-- // FLY ENGINE — clean, no backing
-- // ─────────────────────────────────────────────
local flyConn = nil
local flyBV   = nil
local flyBG   = nil
local isFly   = false

local function stopFly()
    isFly = false
    if flyConn then flyConn:Disconnect() flyConn = nil end
    pcall(function() if flyBV then flyBV:Destroy() flyBV = nil end end)
    pcall(function() if flyBG then flyBG:Destroy() flyBG = nil end end)
    pcall(function()
        local h = getHuman()
        if h then h.PlatformStand = false end
    end)
end

local function flyTo(targetPos, speed, onDone)
    stopFly()
    local root  = getRoot()
    local human = getHuman()
    if not root or not human then
        if onDone then task.spawn(onDone) end
        return
    end

    isFly = true
    human.PlatformStand = true

    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    flyBV.Velocity = Vector3.new(0, 0, 0)
    flyBV.Parent   = root

    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    flyBG.P         = 1e6
    flyBG.CFrame    = CFrame.new(root.Position, targetPos)
    flyBG.Parent    = root

    flyConn = RunService.Heartbeat:Connect(function()
        if not isFly then return end
        local r = getRoot()
        if not r then stopFly() return end
        local diff = targetPos - r.Position
        local dist = diff.Magnitude
        if dist < 3 then
            stopFly()
            if onDone then task.spawn(onDone) end
            return
        end
        local dir = diff.Unit
        flyBV.Velocity = dir * (speed or 200)
        flyBG.CFrame   = CFrame.new(r.Position, r.Position + dir)
    end)
end

-- // ─────────────────────────────────────────────
-- // HOLD LONGEST — fixed no backing
-- // Uses BodyPosition instead of velocity so it locks in place
-- // ─────────────────────────────────────────────
local holdActive = false
local holdConn   = nil
local holdBP     = nil  -- BodyPosition (holds position, no drift)
local holdBG2    = nil

local function stopHoldLongest()
    holdActive = false
    if holdConn then holdConn:Disconnect() holdConn = nil end
    pcall(function() if holdBP  then holdBP:Destroy()  holdBP  = nil end end)
    pcall(function() if holdBG2 then holdBG2:Destroy() holdBG2 = nil end end)
    disableGodMode()
    pcall(function()
        local h = getHuman()
        if h then h.PlatformStand = false end
    end)
end

local function startHoldLongest()
    if holdActive then return end
    local root = getRoot()
    if not root then return end

    holdActive = true
    enableGodMode()

    local human = getHuman()
    if human then human.PlatformStand = true end

    local skyPos = root.Position + Vector3.new(0, 300, 0)

    -- Fly up first
    flyTo(skyPos, 300, function()
        -- Once at sky position, switch to BodyPosition to LOCK in place (no backing)
        local r2 = getRoot()
        if not r2 or not holdActive then return end

        holdBP = Instance.new("BodyPosition")
        holdBP.MaxForce  = Vector3.new(1e9, 1e9, 1e9)
        holdBP.P         = 1e5
        holdBP.D         = 1e4
        holdBP.Position  = r2.Position  -- lock exactly here
        holdBP.Parent    = r2

        holdBG2 = Instance.new("BodyGyro")
        holdBG2.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        holdBG2.P         = 1e6
        holdBG2.CFrame    = r2.CFrame
        holdBG2.Parent    = r2

        holdConn = RunService.Heartbeat:Connect(function()
            if not holdActive then return end
            local r3 = getRoot()
            if not r3 then return end

            -- Spam all hold/zone interactions
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    local nm = obj.Name:lower()
                    if nm:find("hold") or nm:find("zone") or nm:find("claim") or nm:find("admin") or nm:find("platform") or nm:find("longest") then
                        pcall(firetouchinterest, r3, obj, 0)
                        pcall(function()
                            local cl = obj:FindFirstChildOfClass("ClickDetector")
                            if cl then fireclickdetector(cl) end
                        end)
                        pcall(function()
                            local pr = obj:FindFirstChildOfClass("ProximityPrompt")
                            if pr then fireproximityprompt(pr) end
                        end)
                    end
                end
            end
        end)
    end)
end

-- // ─────────────────────────────────────────────
-- // RIDE BACK (Miranda style)
-- // ─────────────────────────────────────────────
local rideWeld = nil
local function rideBack()
    if rideWeld then pcall(function() rideWeld:Destroy() end) rideWeld = nil end
    local root = getRoot()
    if not root then return end
    local best, bd = nil, math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local nm = obj.Name:lower()
            for _, kw in ipairs({"mount","monster","creature","ride","mob","boss","npc","dinosaur","animal","miranda"}) do
                if nm:find(kw) then
                    local d = (root.Position - obj.Position).Magnitude
                    if d < bd and d < 120 then bd = d best = obj end
                    break
                end
            end
        end
    end
    if best then
        root.CFrame = CFrame.new(best.Position + Vector3.new(0, best.Size.Y/2 + 3, 0))
        task.wait(0.05)
        local w = Instance.new("WeldConstraint")
        w.Part0  = root
        w.Part1  = best
        w.Parent = root
        rideWeld = w
        task.delay(6, function()
            pcall(function() if rideWeld then rideWeld:Destroy() rideWeld = nil end end)
        end)
    else
        pcall(function()
            local h = getHuman()
            if not h then return end
            local prev = h.WalkSpeed
            h.WalkSpeed = 80
            task.delay(4, function() pcall(function() h.WalkSpeed = prev end) end)
        end)
    end
end

-- // ─────────────────────────────────────────────
-- // STEAL EGG
-- // ─────────────────────────────────────────────
local function stealEgg(data, onDone)
    if not data or not data.obj then if onDone then onDone(false) end return end
    if not data.obj.Parent then if onDone then onDone(false) end return end

    enableGodMode()
    local highPos = data.pos + Vector3.new(0, 80, 0)

    flyTo(highPos, 220, function()
        local root = getRoot()
        if not root then
            disableGodMode()
            if onDone then onDone(false) end
            return
        end

        -- Teleport on top of egg
        root.CFrame = CFrame.new(data.pos + Vector3.new(0, 3, 0))
        task.wait(0.06)

        local obj = data.obj
        -- Touch
        pcall(function()
            local tt = obj:FindFirstChildOfClass("TouchTransmitter")
            if tt then
                firetouchinterest(root, obj, 0)
                task.wait(0.05)
                firetouchinterest(root, obj, 1)
            end
        end)
        -- Click
        pcall(function()
            local cl = obj:FindFirstChildOfClass("ClickDetector")
            if cl then fireclickdetector(cl) end
        end)
        -- Prompt
        pcall(function()
            local pr = obj:FindFirstChildOfClass("ProximityPrompt")
                or (obj.Parent and obj.Parent:FindFirstChildOfClass("ProximityPrompt"))
            if pr then fireproximityprompt(pr) end
        end)
        -- Children
        for _, child in ipairs(obj:GetChildren()) do
            pcall(function()
                local ct = child:FindFirstChildOfClass("TouchTransmitter")
                if ct then firetouchinterest(root, child, 0) task.wait(0.03) firetouchinterest(root, child, 1) end
            end)
            pcall(function()
                local cc = child:FindFirstChildOfClass("ClickDetector")
                if cc then fireclickdetector(cc) end
            end)
            pcall(function()
                local cp = child:FindFirstChildOfClass("ProximityPrompt")
                if cp then fireproximityprompt(cp) end
            end)
        end
        -- RemoteEvents
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("RemoteEvent") then
                local nm = v.Name:lower()
                if nm:find("hatch") or nm:find("collect") or nm:find("open") or nm:find("egg") or nm:find("claim") then
                    pcall(function() v:FireServer() end)
                end
            end
        end

        task.wait(0.2)
        disableGodMode()
        rideBack()
        if onDone then onDone(true) end
    end)
end

-- // ─────────────────────────────────────────────
-- // ESP SYSTEM — Billboard labels on all eggs
-- // ─────────────────────────────────────────────
local espBills   = {}
local espEnabled = false

local function clearESP()
    for _, b in ipairs(espBills) do
        pcall(function() b:Destroy() end)
    end
    espBills = {}
end

local function updateESP(eggs)
    clearESP()
    if not espEnabled then return end
    for _, data in ipairs(eggs) do
        pcall(function()
            local obj = data.obj
            local part = obj:IsA("BasePart") and obj
                or (obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildOfClass("BasePart")))
            if not part then return end

            local rd = getRD(data.rarity)

            local bill = Instance.new("BillboardGui")
            bill.Size           = UDim2.new(0, 130, 0, 44)
            bill.StudsOffset    = Vector3.new(0, 3, 0)
            bill.AlwaysOnTop    = true
            bill.LightInfluence = 0
            bill.Adornee        = part
            bill.Parent         = part

            local bg = mk("Frame", {
                Size             = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = Color3.fromRGB(8, 10, 20),
                BorderSizePixel  = 0,
            }, bill)
            corner(6, bg)
            mk("UIStroke", {Color=rd.color, Thickness=1.5}, bg)

            -- Rarity stripe
            local stripe = mk("Frame", {
                Size=UDim2.new(0,3,1,-4), Position=UDim2.new(0,2,0,2),
                BackgroundColor3=rd.color, BorderSizePixel=0,
            }, bg)
            corner(2, stripe)

            mk("TextLabel", {
                Size=UDim2.new(1,-10,0,20), Position=UDim2.new(0,8,0,2),
                BackgroundTransparency=1, Text=data.pet,
                TextColor3=Color3.new(1,1,1), TextSize=11,
                Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left,
                TextTruncate=Enum.TextTruncate.AtEnd,
            }, bg)

            mk("TextLabel", {
                Size=UDim2.new(1,-10,0,16), Position=UDim2.new(0,8,0,22),
                BackgroundTransparency=1,
                Text=data.rarity.." • "..data.dist.."m",
                TextColor3=rd.color, TextSize=9,
                Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left,
            }, bg)

            table.insert(espBills, bill)
        end)
    end
end

-- // ─────────────────────────────────────────────
-- // STATE
-- // ─────────────────────────────────────────────
local State = {
    loopActive   = false,
    stealing     = false,
    eggList      = {},
    selectedRar  = {},
    currentTab   = "autoSteal",
}
-- default all rarities ON
for _, r in ipairs(RARITY_DATA) do State.selectedRar[r.name] = true end

-- // ─────────────────────────────────────────────
-- // SCREEN GUI
-- // ─────────────────────────────────────────────
local CoreGui = game:GetService("CoreGui")
pcall(function()
    local old = CoreGui:FindFirstChild("GNS_HubUI")
    if old then old:Destroy() end
end)

local Screen = Instance.new("ScreenGui")
Screen.Name           = "GNS_HubUI"
Screen.ResetOnSpawn   = false
Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Screen.DisplayOrder   = 999
Screen.IgnoreGuiInset = true
Screen.Parent         = CoreGui

-- // ─────────────────────────────────────────────
-- // GNS ICON — 58px, logo visible, drag+click separated
-- // ─────────────────────────────────────────────
local IC = 58
local IconWrap = mk("Frame", {
    Size             = UDim2.new(0,IC,0,IC),
    Position         = UDim2.new(0,14,0.5,-(IC/2)),
    BackgroundColor3 = Color3.fromRGB(8,11,26),
    BorderSizePixel  = 0,
    ZIndex           = 5,
}, Screen)
corner(999, IconWrap)
mk("UIStroke", {Color=C.accent, Thickness=2}, IconWrap)

-- Pulse ring 1
local pr1 = mk("Frame",{Size=UDim2.new(1,18,1,18),Position=UDim2.new(0,-9,0,-9),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=1},IconWrap)
corner(999,pr1)
local prs1 = mk("UIStroke",{Color=C.accent,Thickness=6},pr1)
prs1.Transparency=0.55
TweenService:Create(prs1,TweenInfo.new(1.4,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Transparency=0.93}):Play()

-- Pulse ring 2
local pr2 = mk("Frame",{Size=UDim2.new(1,32,1,32),Position=UDim2.new(0,-16,0,-16),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=1},IconWrap)
corner(999,pr2)
local prs2 = mk("UIStroke",{Color=C.cyan,Thickness=3},pr2)
prs2.Transparency=0.75
TweenService:Create(prs2,TweenInfo.new(2.2,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Transparency=0.97}):Play()

-- Orbit dots parented to Screen so they show outside the circle
local orbitDots = {}
for i = 1, 8 do
    local sz = math.random(3,5)
    local d  = mk("Frame",{
        Size=UDim2.new(0,sz,0,sz),
        BackgroundColor3=({C.accent,C.accentHi,C.cyan,C.gold,C.purple})[math.random(1,5)],
        BorderSizePixel=0, ZIndex=20,
        Position=UDim2.new(0,-99,0,-99),
    }, Screen)
    corner(999,d)
    orbitDots[i] = {dot=d, angle=math.rad((i-1)*45), speed=0.8+math.random()*0.7}
end

-- GNS text — ZIndex 10 so it's always on top inside circle
local GNSLabel = mk("TextLabel",{
    Size=UDim2.new(1,0,0,32), Position=UDim2.new(0,0,0,6),
    BackgroundTransparency=1, Text="GNS",
    TextColor3=C.accentHi, TextSize=18,
    Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Center,
    ZIndex=10,
}, IconWrap)

mk("TextLabel",{
    Size=UDim2.new(1,0,0,12), Position=UDim2.new(0,0,1,-14),
    BackgroundTransparency=1, Text="HUB",
    TextColor3=C.subtext, TextSize=8,
    Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Center,
    ZIndex=10,
}, IconWrap)

-- Color cycle on GNS
local gnsColors = {C.accentHi, C.cyan, C.gold, C.purple}
local gnsIdx    = 1
task.spawn(function()
    while task.wait(1.2) do
        gnsIdx = gnsIdx % #gnsColors + 1
        TweenService:Create(GNSLabel,TweenInfo.new(0.5),{TextColor3=gnsColors[gnsIdx]}):Play()
    end
end)

-- Invisible button — ZIndex must be above text (11)
local IconBtn = mk("TextButton",{
    Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
    Text="", ZIndex=11,
}, IconWrap)

local iconWasDragged = makeDraggable(IconBtn, IconWrap)

-- Orbit animation — uses AbsolutePosition to follow dragging
local orbitT = 0
RunService.Heartbeat:Connect(function(dt)
    orbitT = orbitT + dt
    local abs = IconWrap.AbsolutePosition
    local cx  = abs.X + IC/2
    local cy  = abs.Y + IC/2
    local R   = IC/2 + 12
    for _, p in ipairs(orbitDots) do
        local a  = p.angle + orbitT * p.speed
        local px = cx + math.cos(a)*R - 2
        local py = cy + math.sin(a)*R - 2
        p.dot.Position = UDim2.new(0,px,0,py)
        p.dot.BackgroundTransparency = 0.1 + 0.6*math.abs(math.sin(orbitT*1.3+p.angle))
    end
end)

-- // ─────────────────────────────────────────────
-- // MAIN WINDOW
-- // ─────────────────────────────────────────────
local Window = mk("Frame",{
    Size=UDim2.new(0,860,0,580),
    Position=UDim2.new(0.5,-430,0.5,-290),
    BackgroundColor3=C.bg, BorderSizePixel=0,
    Visible=false, ClipsDescendants=true,
}, Screen)
corner(14, Window)
mk("UIStroke",{Color=C.border,Thickness=1.2}, Window)

-- // TITLE BAR
local TitleBar = mk("Frame",{
    Size=UDim2.new(1,0,0,42),
    BackgroundColor3=C.sidebar, BorderSizePixel=0,
}, Window)
mk("Frame",{Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,1,-14),BackgroundColor3=C.sidebar,BorderSizePixel=0},TitleBar)

local function trafficLight(x,col)
    local f=mk("Frame",{Size=UDim2.new(0,13,0,13),Position=UDim2.new(0,x,0.5,-6),BackgroundColor3=col,BorderSizePixel=0},TitleBar)
    corner(999,f) return f
end
trafficLight(12, Color3.fromRGB(255,95,87))
trafficLight(30, Color3.fromRGB(255,189,46))
trafficLight(48, Color3.fromRGB(40,200,64))

mk("TextLabel",{Size=UDim2.new(0,100,1,0),Position=UDim2.new(0,68,0,0),BackgroundTransparency=1,Text="⚡ GNS HUB",TextColor3=C.accentHi,TextSize=13,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},TitleBar)

local TabTitle = mk("TextLabel",{
    Size=UDim2.new(0,200,1,0),Position=UDim2.new(0.5,-100,0,0),
    BackgroundTransparency=1,Text="Auto Steal",
    TextColor3=C.text,TextSize=13,Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Center,
},TitleBar)

local titleWasDragged = makeDraggable(TitleBar, Window)

-- // SIDEBAR
local Sidebar = mk("Frame",{
    Size=UDim2.new(0,210,1,-42),Position=UDim2.new(0,0,0,42),
    BackgroundColor3=C.sidebar, BorderSizePixel=0,
},Window)

local HubBlock = mk("Frame",{Size=UDim2.new(1,0,0,68),BackgroundColor3=C.panel,BorderSizePixel=0},Sidebar)
pad(14,14,10,10,HubBlock)
mk("TextLabel",{Size=UDim2.new(1,0,0,26),BackgroundTransparency=1,Text="⚡ GNS Hub",TextColor3=C.accentHi,TextSize=17,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},HubBlock)
mk("TextLabel",{Size=UDim2.new(1,0,0,16),Position=UDim2.new(0,0,0,28),BackgroundTransparency=1,Text="Steal an Egg • v2.0",TextColor3=C.subtext,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},HubBlock)

local SideScroll = mk("ScrollingFrame",{
    Size=UDim2.new(1,0,1,-68),Position=UDim2.new(0,0,0,68),
    BackgroundTransparency=1,BorderSizePixel=0,
    ScrollBarThickness=2,ScrollBarImageColor3=C.accent,
    CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,
},Sidebar)
mk("UIListLayout",{Padding=UDim.new(0,2),SortOrder=Enum.SortOrder.LayoutOrder},SideScroll)
pad(10,10,8,8,SideScroll)

local function sideHeader(text, order)
    local f = mk("Frame",{Size=UDim2.new(1,0,0,22),BackgroundTransparency=1,LayoutOrder=order},SideScroll)
    local d = mk("Frame",{Size=UDim2.new(0,5,0,5),Position=UDim2.new(0,0,0.5,-2),BackgroundColor3=C.accent,BorderSizePixel=0},f)
    corner(999,d)
    mk("TextLabel",{Size=UDim2.new(1,-12,1,0),Position=UDim2.new(0,12,0,0),BackgroundTransparency=1,Text=text,TextColor3=C.subtext,TextSize=9,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},f)
end

local navBtns       = {}
local ContentFrames = {}

local function sideNav(label, icon, tabId, order)
    local btn = mk("TextButton",{
        Size=UDim2.new(1,0,0,34),BackgroundTransparency=1,
        Text="",BorderSizePixel=0,LayoutOrder=order,
    },SideScroll)
    local bar = mk("Frame",{Size=UDim2.new(0,3,0,22),Position=UDim2.new(0,0,0.5,-11),BackgroundColor3=C.accent,BorderSizePixel=0,Visible=false},btn)
    corner(999,bar)
    mk("TextLabel",{Size=UDim2.new(0,22,1,0),Position=UDim2.new(0,10,0,0),BackgroundTransparency=1,Text=icon,TextSize=14,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center},btn)
    local lbl = mk("TextLabel",{Size=UDim2.new(1,-36,1,0),Position=UDim2.new(0,36,0,0),BackgroundTransparency=1,Text=label,TextColor3=C.subtext,TextSize=12,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},btn)

    local function setActive(v)
        bar.Visible = v
        lbl.TextColor3 = v and C.text or C.subtext
        lbl.Font = v and Enum.Font.GothamBold or Enum.Font.Gotham
        btn.BackgroundTransparency = v and 0 or 1
        if v then btn.BackgroundColor3=C.card corner(8,btn) end
    end
    btn.MouseButton1Click:Connect(function()
        for _, nb in ipairs(navBtns) do nb.setActive(false) end
        setActive(true)
        for id, cf in pairs(ContentFrames) do cf.Visible=(id==tabId) end
        TabTitle.Text    = label
        State.currentTab = tabId
    end)
    table.insert(navBtns,{setActive=setActive,tabId=tabId})
    return {setActive=setActive}
end

sideHeader("EGGS",1)
local navAutoSteal  = sideNav("Auto Steal",   "◎","autoSteal",  2)
local navEggPredict = sideNav("Egg Predictor","☯","eggPredict", 3)
local navEggESP     = sideNav("Egg ESP",      "◈","eggESP",     4)
sideHeader("GAMEPLAY",5)
local navTreadmill  = sideNav("Treadmill",    "⇄","treadmill",  6)
local navRift       = sideNav("The Rift",     "⬡","rift",       7)
sideHeader("ADMIN ABUSE",8)
local navAdmin      = sideNav("Admin Abuse",  "👑","adminAbuse", 9)

-- // CONTENT AREA
local ContentArea = mk("Frame",{
    Size=UDim2.new(1,-210,1,-42),Position=UDim2.new(0,210,0,42),
    BackgroundTransparency=1,
},Window)

local function makeContent(id)
    local f = mk("ScrollingFrame",{
        Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
        BorderSizePixel=0,ScrollBarThickness=3,
        ScrollBarImageColor3=C.accent,
        CanvasSize=UDim2.new(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y,
        Visible=false,
    },ContentArea)
    mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},f)
    ContentFrames[id]=f
    return f
end

local function makeSection(parent, title, titleCol, order)
    local wrap = mk("Frame",{
        Size=UDim2.new(1,0,0,0),BackgroundColor3=C.card,
        BorderSizePixel=0,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=order,
    },parent)
    local hdr = mk("Frame",{Size=UDim2.new(1,0,0,36),BackgroundColor3=C.panel,BorderSizePixel=0},wrap)
    pad(16,16,0,0,hdr)
    mk("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=title,TextColor3=titleCol or C.text,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},hdr)
    local body = mk("Frame",{Size=UDim2.new(1,0,0,0),Position=UDim2.new(0,0,0,36),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},wrap)
    return body
end

local function divLine(parent, lo)
    mk("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=C.border,BorderSizePixel=0,LayoutOrder=lo or 99},parent)
end

-- Toggle helper
local function makeRowToggle(parent, label, defaultOn, order, accentColor)
    local row = mk("Frame",{Size=UDim2.new(1,0,0,44),BackgroundTransparency=1,LayoutOrder=order},parent)
    pad(16,16,0,0,row)
    mk("TextLabel",{Size=UDim2.new(1,-60,1,0),BackgroundTransparency=1,Text=label,TextColor3=C.text,TextSize=12,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},row)
    local ac = accentColor or C.accent
    local track = mk("Frame",{
        Size=UDim2.new(0,44,0,22),Position=UDim2.new(1,-44,0.5,-11),
        BackgroundColor3=defaultOn and C.accentDim or Color3.fromRGB(35,40,65),
        BorderSizePixel=0,
    },row)
    corner(999,track)
    mk("UIStroke",{Color=C.border,Thickness=1},track)
    local thumb = mk("Frame",{
        Size=UDim2.new(0,16,0,16),
        Position=defaultOn and UDim2.new(0,25,0.5,-8) or UDim2.new(0,3,0.5,-8),
        BackgroundColor3=defaultOn and ac or C.dim,BorderSizePixel=0,
    },track)
    corner(999,thumb)
    local togBtn = mk("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=5},track)
    local on = defaultOn or false
    local cbs = {}
    local function setOn(v)
        on = v
        TweenService:Create(thumb,TweenInfo.new(0.15),{
            Position=v and UDim2.new(0,25,0.5,-8) or UDim2.new(0,3,0.5,-8),
            BackgroundColor3=v and ac or C.dim,
        }):Play()
        TweenService:Create(track,TweenInfo.new(0.15),{
            BackgroundColor3=v and C.accentDim or Color3.fromRGB(35,40,65),
        }):Play()
        for _, cb in ipairs(cbs) do pcall(cb,v) end
    end
    togBtn.MouseButton1Click:Connect(function() setOn(not on) end)
    return {setOn=setOn, getOn=function() return on end, onChange=function(cb) table.insert(cbs,cb) end}
end

local function makeRowButton(parent, label, order, col)
    local row = mk("Frame",{Size=UDim2.new(1,0,0,50),BackgroundTransparency=1,LayoutOrder=order},parent)
    pad(16,16,6,6,row)
    local btn = mk("TextButton",{
        Size=UDim2.new(1,0,0,36),BackgroundColor3=col or C.accentDim,
        Text=label,TextColor3=Color3.new(1,1,1),
        TextSize=12,Font=Enum.Font.GothamBold,BorderSizePixel=0,
    },row)
    corner(10,btn)
    mk("UIStroke",{Color=C.accent,Thickness=1},btn)
    btn.MouseEnter:Connect(function() TweenService:Create(btn,TweenInfo.new(0.1),{BackgroundColor3=C.accent}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn,TweenInfo.new(0.1),{BackgroundColor3=col or C.accentDim}):Play() end)
    return btn
end

local function makeDropdown(parent, label, placeholder, order)
    local row = mk("Frame",{Size=UDim2.new(1,0,0,56),BackgroundTransparency=1,LayoutOrder=order},parent)
    pad(16,16,6,6,row)
    mk("TextLabel",{Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,Text=label,TextColor3=C.subtext,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},row)
    local dd = mk("TextButton",{
        Size=UDim2.new(1,0,0,28),Position=UDim2.new(0,0,0,20),
        BackgroundColor3=C.panel,Text=placeholder,
        TextColor3=C.dim,TextSize=11,Font=Enum.Font.Gotham,BorderSizePixel=0,
    },row)
    corner(6,dd)
    mk("UIStroke",{Color=C.border,Thickness=1},dd)
    mk("TextLabel",{Size=UDim2.new(0,16,0,16),Position=UDim2.new(1,-22,0.5,-8),BackgroundTransparency=1,Text="▾",TextColor3=C.dim,TextSize=12,Font=Enum.Font.GothamBold},dd)
    return dd
end

-- // ─────────────────────────────────────────────
-- // TAB: AUTO STEAL
-- // ─────────────────────────────────────────────
local cfAS = makeContent("autoSteal")
local asCols = mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1},cfAS)
local asL = mk("Frame",{Size=UDim2.new(0.5,-1,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},asCols)
mk("Frame",{Size=UDim2.new(0,1,1,0),Position=UDim2.new(0.5,0,0,0),BackgroundColor3=C.border,BorderSizePixel=0},asCols)
local asR = mk("Frame",{Size=UDim2.new(0.5,-1,0,0),Position=UDim2.new(0.5,1,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},asCols)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},asL)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},asR)

local asLBody = makeSection(asL,"Auto Steal Settings",C.accentHi,1)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},asLBody)
local togAutoSteal = makeRowToggle(asLBody,"Enable Auto Steal",false,1)
divLine(asLBody,2)
local togStealOnce = makeRowToggle(asLBody,"Steal Once Only",false,3)
divLine(asLBody,4)
local togGod  = makeRowToggle(asLBody,"God Mode",true,5)
divLine(asLBody,6)
local togRide = makeRowToggle(asLBody,"Ride Mount After Steal",true,7)
divLine(asLBody,8)

-- Rarity filters
local asRarBody = makeSection(asL,"Target Rarities",C.accentHi,2)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},asRarBody)

local rarToggles = {}
for i, r in ipairs(RARITY_DATA) do
    local row = mk("Frame",{Size=UDim2.new(1,0,0,40),BackgroundTransparency=1,LayoutOrder=i},asRarBody)
    pad(16,16,0,0,row)
    local dot = mk("Frame",{Size=UDim2.new(0,8,0,8),Position=UDim2.new(0,0,0.5,-4),BackgroundColor3=r.color,BorderSizePixel=0},row)
    corner(999,dot)
    mk("TextLabel",{Size=UDim2.new(1,-60,1,0),Position=UDim2.new(0,16,0,0),BackgroundTransparency=1,Text=r.name,TextColor3=r.color,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},row)

    local track = mk("Frame",{
        Size=UDim2.new(0,44,0,22),Position=UDim2.new(1,-44,0.5,-11),
        BackgroundColor3=C.accentDim,BorderSizePixel=0,
    },row)
    corner(999,track)
    mk("UIStroke",{Color=C.border,Thickness=1},track)
    local thumb = mk("Frame",{Size=UDim2.new(0,16,0,16),Position=UDim2.new(0,25,0.5,-8),BackgroundColor3=r.color,BorderSizePixel=0},track)
    corner(999,thumb)
    local tb2 = mk("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=5},track)

    local on2 = true
    tb2.MouseButton1Click:Connect(function()
        on2 = not on2
        State.selectedRar[r.name] = on2
        TweenService:Create(thumb,TweenInfo.new(0.15),{
            Position=on2 and UDim2.new(0,25,0.5,-8) or UDim2.new(0,3,0.5,-8),
            BackgroundColor3=on2 and r.color or C.dim,
        }):Play()
        TweenService:Create(track,TweenInfo.new(0.15),{
            BackgroundColor3=on2 and C.accentDim or Color3.fromRGB(35,40,65),
        }):Play()
    end)
    rarToggles[r.name]={getOn=function() return on2 end}
    if i<#RARITY_DATA then divLine(asRarBody,i+100) end
end

-- Egg list on right
local asRBody = makeSection(asR,"Detected Eggs — Rarest First",C.accentHi,1)
mk("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder},asRBody)
pad(6,6,6,6,asRBody)

local statusLbl = mk("TextLabel",{
    Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,
    Text="● Idle",TextColor3=C.subtext,TextSize=11,
    Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=0,
},asRBody)

local function setStatus(txt, col)
    statusLbl.Text       = txt
    statusLbl.TextColor3 = col or C.subtext
end

local function buildEggRow(data, idx, parent)
    local rd  = getRD(data.rarity)
    local row = mk("Frame",{
        Size=UDim2.new(1,0,0,58),BackgroundColor3=C.panel,
        BorderSizePixel=0,LayoutOrder=idx,
    },parent)
    corner(10,row)
    mk("UIStroke",{Color=Color3.fromRGB(28,34,60),Thickness=1},row)
    local stripe=mk("Frame",{Size=UDim2.new(0,3,1,-8),Position=UDim2.new(0,4,0,4),BackgroundColor3=rd.color,BorderSizePixel=0},row)
    corner(4,stripe)
    mk("TextLabel",{Size=UDim2.new(1,-120,0,22),Position=UDim2.new(0,16,0,7),BackgroundTransparency=1,Text=data.pet,TextColor3=C.text,TextSize=13,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},row)
    mk("TextLabel",{Size=UDim2.new(1,-120,0,16),Position=UDim2.new(0,16,0,32),BackgroundTransparency=1,Text=data.rarity..(data.value~="" and " • 💰"..data.value or "").." • 📍"..data.dist.."m",TextColor3=rd.color,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},row)
    local stBtn=mk("TextButton",{Size=UDim2.new(0,64,0,34),Position=UDim2.new(1,-70,0.5,-17),BackgroundColor3=C.accent,Text="STEAL",TextColor3=Color3.new(1,1,1),TextSize=11,Font=Enum.Font.GothamBold,BorderSizePixel=0},row)
    corner(9,stBtn)
    stBtn.MouseEnter:Connect(function() TweenService:Create(stBtn,TweenInfo.new(0.1),{BackgroundColor3=C.accentHi}):Play() end)
    stBtn.MouseLeave:Connect(function() TweenService:Create(stBtn,TweenInfo.new(0.1),{BackgroundColor3=C.accent}):Play() end)
    stBtn.MouseButton1Click:Connect(function()
        if State.stealing then return end
        State.stealing=true
        setStatus("🚀 Stealing → "..data.pet.." ["..data.rarity.."]",C.accentHi)
        stBtn.Text="..." stBtn.BackgroundTransparency=0.5
        stealEgg(data,function(ok)
            State.stealing=false
            stBtn.Text="STEAL" stBtn.BackgroundTransparency=0
            setStatus(ok and "✅ Got: "..data.pet or "❌ Failed",ok and C.green or C.red)
        end)
    end)
end

-- // ─────────────────────────────────────────────
-- // TAB: EGG PREDICTOR
-- // ─────────────────────────────────────────────
local cfEP=makeContent("eggPredict")
local epCols=mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1},cfEP)
local epL=mk("Frame",{Size=UDim2.new(0.5,-1,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},epCols)
mk("Frame",{Size=UDim2.new(0,1,1,0),Position=UDim2.new(0.5,0,0,0),BackgroundColor3=C.border,BorderSizePixel=0},epCols)
local epR=mk("Frame",{Size=UDim2.new(0.5,-1,0,0),Position=UDim2.new(0.5,1,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},epCols)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},epL)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},epR)
local epLBody=makeSection(epL,"Prediction Settings",C.accentHi,1)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},epLBody)
makeRowToggle(epLBody,"Show Pet Name",true,1); divLine(epLBody,2)
makeRowToggle(epLBody,"Show Rarity",true,3);   divLine(epLBody,4)
makeRowToggle(epLBody,"Auto Hatch Rarest",false,5)

local epRBody=makeSection(epR,"Live Predictions",C.accentHi,1)
mk("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder},epRBody)
pad(6,6,6,6,epRBody)

local function buildPredictRow(data,idx,parent)
    local rd=getRD(data.rarity)
    local row=mk("Frame",{Size=UDim2.new(1,0,0,50),BackgroundColor3=C.panel,BorderSizePixel=0,LayoutOrder=idx},parent)
    corner(10,row)
    mk("UIStroke",{Color=Color3.fromRGB(28,34,60),Thickness=1},row)
    local stripe=mk("Frame",{Size=UDim2.new(0,3,1,-8),Position=UDim2.new(0,4,0,4),BackgroundColor3=rd.color,BorderSizePixel=0},row)
    corner(4,stripe)
    mk("TextLabel",{Size=UDim2.new(0.72,0,0,20),Position=UDim2.new(0,16,0,6),BackgroundTransparency=1,Text=data.pet,TextColor3=C.text,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},row)
    mk("TextLabel",{Size=UDim2.new(0.72,0,0,14),Position=UDim2.new(0,16,0,28),BackgroundTransparency=1,Text=data.rarity.." • "..data.dist.."m",TextColor3=rd.color,TextSize=9,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},row)
    mk("TextLabel",{Size=UDim2.new(0.26,0,1,0),Position=UDim2.new(0.74,0,0,0),BackgroundTransparency=1,Text="🐾",TextSize=22,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center},row)
end

-- // ─────────────────────────────────────────────
-- // TAB: EGG ESP
-- // ─────────────────────────────────────────────
local cfESP=makeContent("eggESP")
local espCols=mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1},cfESP)
local espL=mk("Frame",{Size=UDim2.new(0.5,-1,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},espCols)
mk("Frame",{Size=UDim2.new(0,1,1,0),Position=UDim2.new(0.5,0,0,0),BackgroundColor3=C.border,BorderSizePixel=0},espCols)
local espR=mk("Frame",{Size=UDim2.new(0.5,-1,0,0),Position=UDim2.new(0.5,1,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},espCols)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},espL)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},espR)

local espLBody=makeSection(espL,"ESP Settings",C.accentHi,1)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},espLBody)

-- ESP master toggle — actually controls the system
local togESP = makeRowToggle(espLBody,"Enable ESP",false,1)
divLine(espLBody,2)
makeRowToggle(espLBody,"Show Egg Names",true,3);   divLine(espLBody,4)
makeRowToggle(espLBody,"Show Rarity Tags",true,5);  divLine(espLBody,6)
makeRowToggle(espLBody,"Show Distance",true,7);     divLine(espLBody,8)
makeRowToggle(espLBody,"Highlight Rare+",true,9)

togESP.onChange(function(v)
    espEnabled = v
    if not v then clearESP() end
end)

-- Live status panel
local espRBody=makeSection(espR,"Live Nearest Egg",C.accentHi,1)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},espRBody)
pad(16,16,8,8,espRBody)
local lrStatus=mk("TextLabel",{
    Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
    BackgroundTransparency=1,Text="Scanning...",
    TextColor3=C.subtext,TextSize=11,Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,LayoutOrder=1,
},espRBody)

-- // ─────────────────────────────────────────────
-- // TAB: TREADMILL
-- // ─────────────────────────────────────────────
local cfTM=makeContent("treadmill")
local tmCols=mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1},cfTM)
local tmL=mk("Frame",{Size=UDim2.new(0.5,-1,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},tmCols)
mk("Frame",{Size=UDim2.new(0,1,1,0),Position=UDim2.new(0.5,0,0,0),BackgroundColor3=C.border,BorderSizePixel=0},tmCols)
local tmR=mk("Frame",{Size=UDim2.new(0.5,-1,0,0),Position=UDim2.new(0.5,1,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},tmCols)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},tmL)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},tmR)
local tmLBody=makeSection(tmL,"Treadmill Settings",C.accentHi,1)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},tmLBody)
local tmDesc=mk("TextLabel",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Text="Auto-walks the treadmill to earn eggs faster.",TextColor3=C.accentHi,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,LayoutOrder=1},tmLBody)
pad(16,16,8,8,tmDesc)
makeRowToggle(tmLBody,"Auto Treadmill",false,2); divLine(tmLBody,3)
makeDropdown(tmLBody,"Speed","Normal",4)

local tmRBody=makeSection(tmR,"Treadmill Status",C.accentHi,1)
pad(16,16,8,8,tmRBody)
mk("TextLabel",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Text="Status: Idle",TextColor3=C.dim,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=1},tmRBody)

-- // ─────────────────────────────────────────────
-- // TAB: THE RIFT
-- // ─────────────────────────────────────────────
local cfRF=makeContent("rift")
local rfCols=mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1},cfRF)
local rfL=mk("Frame",{Size=UDim2.new(0.5,-1,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},rfCols)
mk("Frame",{Size=UDim2.new(0,1,1,0),Position=UDim2.new(0.5,0,0,0),BackgroundColor3=C.border,BorderSizePixel=0},rfCols)
local rfR=mk("Frame",{Size=UDim2.new(0.5,-1,0,0),Position=UDim2.new(0.5,1,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},rfCols)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},rfL)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},rfR)
local rfLBody=makeSection(rfL,"Rift Farm Settings",C.accentHi,1)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},rfLBody)
local rfDesc=mk("TextLabel",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Text="Three pets become one Rift egg.\nSubmitting permanently consumes the three offered pets.",TextColor3=C.accentHi,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,LayoutOrder=1},rfLBody)
pad(16,16,8,8,rfDesc)
makeDropdown(rfLBody,"Rift Banner","Any Banner",2)
makeRowToggle(rfLBody,"Farm Missing Rift Pets",false,3)
makeRowToggle(rfLBody,"Auto Submit & Claim",false,4)
local rfRBody=makeSection(rfR,"Recipe & Progress",C.accentHi,1)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},rfRBody)
local rfRecipe=mk("TextLabel",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Text="The Rift\nBanner: Shattered Rift\nPty: 0/50\nTrades: 0",TextColor3=C.dim,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,LayoutOrder=1},rfRBody)
pad(16,16,8,8,rfRecipe)
makeRowButton(rfRBody,"Refresh Requirements",2)
makeRowButton(rfRBody,"Submit / Claim Reward",3)

-- // ─────────────────────────────────────────────
-- // TAB: ADMIN ABUSE
-- // ─────────────────────────────────────────────
local cfAA=makeContent("adminAbuse")
local aaCols=mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1},cfAA)
local aaL=mk("Frame",{Size=UDim2.new(0.5,-1,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},aaCols)
mk("Frame",{Size=UDim2.new(0,1,1,0),Position=UDim2.new(0.5,0,0,0),BackgroundColor3=C.border,BorderSizePixel=0},aaCols)
local aaR=mk("Frame",{Size=UDim2.new(0.5,-1,0,0),Position=UDim2.new(0.5,1,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},aaCols)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},aaL)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},aaR)

local aaLBody=makeSection(aaL,"Dragon Event Auto Farm",C.accentHi,1)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},aaLBody)
local aaDesc=mk("TextLabel",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Text="Dragon event only. Targets dragon-tier eggs.",TextColor3=C.accentHi,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,LayoutOrder=1},aaLBody)
pad(16,16,8,8,aaDesc)
makeDropdown(aaLBody,"Dragon Event Eggs","Dragon Event Eggs...",2)
makeRowToggle(aaLBody,"Auto Farm Dragon Event",false,3)

-- HOLD LONGEST section
local hlBody=makeSection(aaL,"Hold Longest Admin Abuse",C.accentHi,2)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},hlBody)
local hlDesc=mk("TextLabel",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Text="Flies 300 studs into the sky, locks position with BodyPosition (no drift/backing), god mode on, spams all hold interactions.",TextColor3=C.subtext,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,LayoutOrder=1},hlBody)
pad(16,16,8,4,hlDesc)
local hlBtnWrap=mk("Frame",{Size=UDim2.new(1,0,0,52),BackgroundTransparency=1,LayoutOrder=2},hlBody)
pad(16,16,4,8,hlBtnWrap)
local hlBtn=mk("TextButton",{
    Size=UDim2.new(1,0,0,38),BackgroundColor3=C.accentDim,
    Text="👑  HOLD LONGEST — START",
    TextColor3=Color3.new(1,1,1),TextSize=13,Font=Enum.Font.GothamBold,BorderSizePixel=0,
},hlBtnWrap)
corner(10,hlBtn)
mk("UIStroke",{Color=C.accentHi,Thickness=1},hlBtn)

local holdOn=false
hlBtn.MouseButton1Click:Connect(function()
    holdOn=not holdOn
    if holdOn then
        hlBtn.Text="👑  HOLD LONGEST — STOP"
        hlBtn.BackgroundColor3=C.red
        startHoldLongest()
    else
        hlBtn.Text="👑  HOLD LONGEST — START"
        hlBtn.BackgroundColor3=C.accentDim
        stopHoldLongest()
    end
end)

-- Right side: dragon detection
local aaRBody=makeSection(aaR,"Dragon Egg Detection",C.accentHi,1)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},aaRBody)
local dlTitle=mk("TextLabel",{Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,Text="Available Dragon Eggs",TextColor3=C.accentHi,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=1},aaRBody)
pad(16,16,8,4,dlTitle)
local dragonList=mk("TextLabel",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Text="Scanning...",TextColor3=C.dim,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,LayoutOrder=2},aaRBody)
pad(16,16,0,8,dragonList)

local lsBody=makeSection(aaR,"Live Event State",C.accentHi,2)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},lsBody)
local liveStateLbl=mk("TextLabel",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Text="Dragon event: Inactive\nPhase: Inactive\nZone: Waiting",TextColor3=C.dim,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,LayoutOrder=1},lsBody)
pad(16,16,8,8,liveStateLbl)

-- // ─────────────────────────────────────────────
-- // SCAN LOOP — 0.5s, updates all tabs
-- // ─────────────────────────────────────────────
task.spawn(function()
    while true do
        task.wait(0.5)
        local ok, eggs = pcall(scanAllEggs)
        if not ok or not eggs then continue end
        State.eggList = eggs

        -- Auto steal tab egg list
        if State.currentTab == "autoSteal" then
            for _, c in ipairs(asRBody:GetChildren()) do
                if c:IsA("Frame") then c:Destroy() end
            end
            local shown = 0
            for i, data in ipairs(eggs) do
                if State.selectedRar[data.rarity] then
                    buildEggRow(data, i, asRBody)
                    shown = shown + 1
                    if shown >= 15 then break end
                end
            end
            if shown == 0 then
                mk("TextLabel",{
                    Size=UDim2.new(1,0,0,40),BackgroundTransparency=1,
                    Text="No matching eggs found on map",TextColor3=C.subtext,
                    TextSize=11,Font=Enum.Font.Gotham,
                    TextXAlignment=Enum.TextXAlignment.Center,LayoutOrder=1,
                },asRBody)
            end
        end

        -- Egg predictor
        if State.currentTab == "eggPredict" then
            for _, c in ipairs(epRBody:GetChildren()) do
                if c:IsA("Frame") then c:Destroy() end
            end
            for i, data in ipairs(eggs) do
                buildPredictRow(data, i, epRBody)
                if i >= 12 then break end
            end
        end

        -- ESP update
        if espEnabled then
            updateESP(eggs)
        end

        -- ESP live status
        if #eggs > 0 then
            local e = eggs[1]
            lrStatus.Text       = "Best: "..e.pet.." ["..e.rarity.."] — "..e.dist.."m away"
            lrStatus.TextColor3 = getRD(e.rarity).color
        else
            lrStatus.Text       = "No eggs detected"
            lrStatus.TextColor3 = C.subtext
        end

        -- Dragon list
        local dragonEggs = {}
        for _, data in ipairs(eggs) do
            if data.rarity=="Secret" or data.rarity=="Eternal" or data.rarity=="Mythic" or data.rarity=="Cosmic" then
                table.insert(dragonEggs, data.pet.." • "..data.rarity)
            end
        end
        dragonList.Text = #dragonEggs>0 and table.concat(dragonEggs,"\n") or "No dragon-tier eggs detected"
    end
end)

-- // AUTO STEAL LOOP
local stealOnceFlag = false
task.spawn(function()
    while true do
        task.wait(0.15)
        if not togAutoSteal.getOn() then stealOnceFlag=false continue end
        if State.stealing then continue end
        if togStealOnce.getOn() and stealOnceFlag then
            togAutoSteal.setOn(false)
            setStatus("✅ Steal Once complete!",C.green)
            stealOnceFlag=false
            continue
        end
        local eggs   = State.eggList
        if not eggs or #eggs==0 then continue end
        local target = nil
        for _, data in ipairs(eggs) do
            if State.selectedRar[data.rarity] then target=data break end
        end
        if not target then continue end
        State.stealing = true
        setStatus("🚀 Auto → "..target.pet.." ["..target.rarity.."]",C.accentHi)
        stealEgg(target, function(ok)
            State.stealing = false
            if togStealOnce.getOn() then stealOnceFlag=true end
            setStatus(ok and "✅ Got: "..target.pet or "❌ Missed",ok and C.green or C.red)
        end)
    end
end)

-- // ─────────────────────────────────────────────
-- // WINDOW OPEN / CLOSE
-- // ─────────────────────────────────────────────
IconBtn.MouseButton1Click:Connect(function()
    if iconWasDragged() then return end  -- ignore drag release
    Window.Visible = not Window.Visible
    if Window.Visible then
        Window.Size = UDim2.new(0,860,0,0)
        TweenService:Create(Window,TweenInfo.new(0.22,Enum.EasingStyle.Back),{Size=UDim2.new(0,860,0,580)}):Play()
        for _, nb in ipairs(navBtns) do nb.setActive(false) end
        navAutoSteal.setActive(true)
        for id, cf in pairs(ContentFrames) do cf.Visible=(id=="autoSteal") end
        TabTitle.Text    = "Auto Steal"
        State.currentTab = "autoSteal"
    else
        TweenService:Create(Window,TweenInfo.new(0.15),{Size=UDim2.new(0,860,0,0)}):Play()
        task.delay(0.16,function() Window.Size=UDim2.new(0,860,0,580) end)
    end
end)

-- Set default tab visible
for _, nb in ipairs(navBtns) do nb.setActive(false) end
navAutoSteal.setActive(true)
for id, cf in pairs(ContentFrames) do cf.Visible=(id=="autoSteal") end

-- // RESPAWN
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    State.stealing = false
    pcall(stopFly)
    if rideWeld then pcall(function() rideWeld:Destroy() rideWeld=nil end) end
    if holdActive then
        stopHoldLongest()
        holdOn=false
        hlBtn.Text="👑  HOLD LONGEST — START"
        hlBtn.BackgroundColor3=C.accentDim
    end
    setStatus("🔄 Respawned — ready",C.subtext)
end)

print("⚡ GNS HUB v2 Loaded — Click the GNS circle to open!")
