-- // ============================================
-- // ⚡ GNS HUB — Full Rewrite
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
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHuman()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
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
-- // UI HELPERS — defined FIRST before any use
-- // ─────────────────────────────────────────────
local function mk(class, props, parent)
    local i = Instance.new(class)
    for k, v in pairs(props) do i[k] = v end
    if parent then i.Parent = parent end
    return i
end
local function corner(r, p)
    mk("UICorner", {CornerRadius = UDim.new(0, r)}, p)
end
local function stroke(col, thick, p)
    mk("UIStroke", {Color = col, Thickness = thick}, p)
end
local function pad(l, r, t, b, p)
    local u = Instance.new("UIPadding")
    u.PaddingLeft   = UDim.new(0, l)
    u.PaddingRight  = UDim.new(0, r)
    u.PaddingTop    = UDim.new(0, t)
    u.PaddingBottom = UDim.new(0, b)
    u.Parent = p
end
local function makeDraggable(handle, target)
    local drag, ds, sp = false, nil, nil
    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            drag = true
            ds   = inp.Position
            sp   = target.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then
                    drag = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if drag and (
            inp.UserInputType == Enum.UserInputType.MouseMovement or
            inp.UserInputType == Enum.UserInputType.Touch
        ) then
            local d = inp.Position - ds
            target.Position = UDim2.new(
                sp.X.Scale, sp.X.Offset + d.X,
                sp.Y.Scale, sp.Y.Offset + d.Y
            )
        end
    end)
end

-- // ─────────────────────────────────────────────
-- // SCANNERS
-- // ─────────────────────────────────────────────
local function predictRarity(obj)
    local checks = {"cosmic","divine","eternal","secret","mythic","legendary","epic","rare","uncommon"}
    local mapped  = {"Cosmic","Divine","Eternal","Secret","Mythic","Legendary","Epic","Rare","Uncommon"}
    local nm = obj.Name:lower()
    for i, kw in ipairs(checks) do
        if nm:find(kw) then return mapped[i] end
    end
    for _, v in ipairs(obj:GetDescendants()) do
        local t = ""
        if v:IsA("StringValue") then
            t = (v.Value or ""):lower()
            local vn = v.Name:lower()
            for i, kw in ipairs(checks) do
                if vn:find(kw) or t:find(kw) then return mapped[i] end
            end
        elseif v:IsA("TextLabel") or v:IsA("TextButton") then
            t = (v.Text or ""):lower()
            for i, kw in ipairs(checks) do
                if t:find(kw) then return mapped[i] end
            end
        elseif v:IsA("IntValue") and v.Name:lower():find("rar") then
            local m = {[1]="Cosmic",[2]="Divine",[3]="Eternal",[4]="Secret",[5]="Mythic",[6]="Legendary",[7]="Epic",[8]="Rare",[9]="Uncommon"}
            if m[v.Value] then return m[v.Value] end
        end
    end
    if obj.Parent then
        local pnm = obj.Parent.Name:lower()
        for i, kw in ipairs(checks) do
            if pnm:find(kw) then return mapped[i] end
        end
    end
    return "Common"
end

local PET_KEYS = {"pet","reward","hatch","item","name","prize","animal","give"}

local function predictPet(obj)
    for _, v in ipairs(obj:GetDescendants()) do
        if v:IsA("StringValue") and v.Value ~= "" and #v.Value < 60 then
            local vn = v.Name:lower()
            for _, k in ipairs(PET_KEYS) do
                if vn:find(k) then return v.Value end
            end
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
                for _, k in ipairs(PET_KEYS) do
                    if vn:find(k) then return v.Value end
                end
            end
        end
    end
    local nm = obj.Name:gsub("[Ee]gg",""):gsub("^%s+",""):gsub("%s+$","")
    return (nm ~= "") and (nm .. " Pet") or "Unknown Pet"
end

local function getEggValue(obj)
    for _, v in ipairs(obj:GetDescendants()) do
        if v:IsA("NumberValue") or v:IsA("IntValue") then
            local nm = v.Name:lower()
            if (nm:find("value") or nm:find("coin") or nm:find("price") or nm:find("worth")) and v.Value > 0 then
                local val = v.Value
                if val >= 1e9 then return string.format("%.2fB", val/1e9)
                elseif val >= 1e6 then return string.format("%.2fM", val/1e6)
                elseif val >= 1e3 then return string.format("%.1fK", val/1e3) end
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
                        if ok2 then pos = cf.Position end
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
            if hp < hum.MaxHealth then
                pcall(function() hum.Health = math.huge end)
            end
        end)
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead,        false) end)
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown,  false) end)
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,      false) end)
        for _, p in ipairs(getChar():GetDescendants()) do
            if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end
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
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead,       true) end)
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true) end)
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,     true) end)
        for _, p in ipairs(getChar():GetDescendants()) do
            if p:IsA("BasePart") then pcall(function() p.CanCollide = true end) end
        end
    end)
end

-- // ─────────────────────────────────────────────
-- // FLY ENGINE
-- // ─────────────────────────────────────────────
local flyConn, bVel, bGyro, isFly = nil, nil, nil, false
local function stopFly()
    isFly = false
    if flyConn then flyConn:Disconnect() flyConn = nil end
    pcall(function() if bVel  then bVel:Destroy()  bVel  = nil end end)
    pcall(function() if bGyro then bGyro:Destroy() bGyro = nil end end)
    pcall(function()
        local h = getHuman()
        if h then h.PlatformStand = false end
    end)
end
local function flyTo(pos, speed, cb)
    stopFly()
    isFly = true
    pcall(function()
        local root  = getRoot()
        local human = getHuman()
        if not root or not human then
            if cb then task.spawn(cb) end
            return
        end
        human.PlatformStand = true
        bVel = Instance.new("BodyVelocity", root)
        bVel.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        bVel.Velocity = Vector3.new(0, 0, 0)
        bGyro = Instance.new("BodyGyro", root)
        bGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        bGyro.P = 1e5
        flyConn = RunService.Heartbeat:Connect(function()
            if not isFly then return end
            local r = getRoot()
            if not r then stopFly() return end
            local diff = pos - r.Position
            if diff.Magnitude < 3 then
                stopFly()
                if cb then task.spawn(cb) end
                return
            end
            local dir = diff.Unit
            bVel.Velocity  = dir * (speed or 180)
            bGyro.CFrame   = CFrame.new(r.Position, r.Position + dir)
        end)
    end)
end

-- // RIDE BACK (Miranda style)
local rideWeld = nil
local function rideBack()
    if rideWeld then pcall(function() rideWeld:Destroy() end) rideWeld = nil end
    local root = getRoot()
    if not root then return end
    local best, bd = nil, math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            for _, kw in ipairs({"mount","monster","creature","ride","mob","boss","npc","dinosaur","animal"}) do
                if obj.Name:lower():find(kw) then
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
    if not data or not data.obj or not data.obj.Parent then
        if onDone then onDone(false) end
        return
    end
    enableGodMode()
    local highPos = data.pos + Vector3.new(0, 80, 0)
    flyTo(highPos, 220, function()
        local root = getRoot()
        if not root then
            disableGodMode()
            if onDone then onDone(false) end
            return
        end
        root.CFrame = CFrame.new(data.pos + Vector3.new(0, 3, 0))
        task.wait(0.05)
        local obj = data.obj
        -- Touch
        local touch = obj:FindFirstChildOfClass("TouchTransmitter")
        if touch then
            pcall(firetouchinterest, root, obj, 0)
            task.wait(0.05)
            pcall(firetouchinterest, root, obj, 1)
        end
        -- Click
        local click = obj:FindFirstChildOfClass("ClickDetector")
        if click then pcall(fireclickdetector, click) end
        -- Prompt
        local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
            or (obj.Parent and obj.Parent:FindFirstChildOfClass("ProximityPrompt"))
        if prompt then pcall(fireproximityprompt, prompt) end
        -- Children
        for _, child in ipairs(obj:GetChildren()) do
            local ct = child:FindFirstChildOfClass("TouchTransmitter")
            if ct then
                pcall(firetouchinterest, root, child, 0)
                task.wait(0.03)
                pcall(firetouchinterest, root, child, 1)
            end
            local cc = child:FindFirstChildOfClass("ClickDetector")
            if cc then pcall(fireclickdetector, cc) end
            local cp = child:FindFirstChildOfClass("ProximityPrompt")
            if cp then pcall(fireproximityprompt, cp) end
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
-- // HOLD LONGEST
-- // ─────────────────────────────────────────────
local holdActive = false
local holdConn, holdBV, holdBG = nil, nil, nil
local function startHoldLongest()
    if holdActive then return end
    holdActive = true
    enableGodMode()
    pcall(function()
        local root = getRoot()
        if not root then return end
        local skyY   = root.Position.Y + 300
        local skyPos = Vector3.new(root.Position.X, skyY, root.Position.Z)
        local human  = getHuman()
        if human then human.PlatformStand = true end
        holdBV = Instance.new("BodyVelocity", root)
        holdBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        holdBV.Velocity = Vector3.new(0, 200, 0)
        holdBG = Instance.new("BodyGyro", root)
        holdBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        holdBG.CFrame = root.CFrame
        local reached = false
        holdConn = RunService.Heartbeat:Connect(function()
            if not holdActive then return end
            local r = getRoot()
            if not r then return end
            if not reached and r.Position.Y >= skyY - 10 then
                reached = true
                holdBV.Velocity = Vector3.new(0, 0, 0)
            end
            if reached then
                local diff = skyPos - r.Position
                holdBV.Velocity = diff.Magnitude > 2 and diff.Unit * 50 or Vector3.new(0, 0, 0)
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") then
                        local nm = obj.Name:lower()
                        if nm:find("hold") or nm:find("zone") or nm:find("claim") or nm:find("admin") or nm:find("platform") then
                            local tt = obj:FindFirstChildOfClass("TouchTransmitter")
                            if tt then pcall(firetouchinterest, r, obj, 0) end
                            local cl = obj:FindFirstChildOfClass("ClickDetector")
                            if cl then pcall(fireclickdetector, cl) end
                            local pr = obj:FindFirstChildOfClass("ProximityPrompt")
                            if pr then pcall(fireproximityprompt, pr) end
                        end
                    end
                end
            end
        end)
    end)
end
local function stopHoldLongest()
    holdActive = false
    if holdConn then holdConn:Disconnect() holdConn = nil end
    pcall(function() if holdBV then holdBV:Destroy() holdBV = nil end end)
    pcall(function() if holdBG then holdBG:Destroy() holdBG = nil end end)
    disableGodMode()
    pcall(function()
        local h = getHuman()
        if h then h.PlatformStand = false end
    end)
end

-- // ─────────────────────────────────────────────
-- // STATE
-- // ─────────────────────────────────────────────
local State = {
    loopActive  = false,
    stealing    = false,
    eggList     = {},
    selectedRar = {Cosmic=true, Divine=true, Eternal=true, Secret=true, Mythic=true, Legendary=true},
    currentTab  = "autoSteal",
}

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
-- // GNS LOGO ICON (draggable, animated)
-- // ─────────────────────────────────────────────
local IconWrap = mk("Frame", {
    Size             = UDim2.new(0, 82, 0, 82),
    Position         = UDim2.new(0, 14, 0.5, -41),
    BackgroundColor3 = C.sidebar,
    BorderSizePixel  = 0,
}, Screen)
corner(999, IconWrap)
stroke(C.accent, 2, IconWrap)

-- Outer glow pulse ring
local GlowRing = mk("Frame", {
    Size                   = UDim2.new(1, 20, 1, 20),
    Position               = UDim2.new(0, -10, 0, -10),
    BackgroundTransparency = 1,
    BorderSizePixel        = 0,
}, IconWrap)
corner(999, GlowRing)
local gs1 = stroke(C.accent, 8, GlowRing)
gs1.Transparency = 0.65
TweenService:Create(gs1, TweenInfo.new(1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Transparency = 0.92}):Play()

local GlowRing2 = mk("Frame", {
    Size                   = UDim2.new(1, 36, 1, 36),
    Position               = UDim2.new(0, -18, 0, -18),
    BackgroundTransparency = 1,
    BorderSizePixel        = 0,
}, IconWrap)
corner(999, GlowRing2)
local gs2 = stroke(C.cyan, 4, GlowRing2)
gs2.Transparency = 0.80
TweenService:Create(gs2, TweenInfo.new(2.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Transparency = 0.96}):Play()

-- Orbiting particles
local ORBIT_COUNT = 12
local orbitParticles = {}
for i = 1, ORBIT_COUNT do
    local sz  = math.random(3, 6)
    local dot = mk("Frame", {
        Size             = UDim2.new(0, sz, 0, sz),
        BackgroundColor3 = ({C.accent, C.accentHi, C.cyan, C.gold, C.purple})[math.random(1,5)],
        BorderSizePixel  = 0,
        ZIndex           = 3,
    }, IconWrap)
    corner(999, dot)
    local angle  = math.rad((i-1) * (360 / ORBIT_COUNT))
    local radius = 36 + math.random(-4, 4)
    orbitParticles[i] = {dot = dot, angle = angle, radius = radius, speed = 0.9 + math.random() * 0.6}
end

local orbitTime = 0
RunService.Heartbeat:Connect(function(dt)
    orbitTime = orbitTime + dt
    for _, p in ipairs(orbitParticles) do
        local a  = p.angle + orbitTime * p.speed
        local cx = 41 + math.cos(a) * p.radius - p.dot.AbsoluteSize.X / 2
        local cy = 41 + math.sin(a) * p.radius - p.dot.AbsoluteSize.Y / 2
        p.dot.Position = UDim2.new(0, cx, 0, cy)
        p.dot.BackgroundTransparency = 0.2 + 0.5 * math.abs(math.sin(orbitTime * 1.2 + p.angle))
    end
end)

-- GNS Text Logo
local GNSLabel = mk("TextLabel", {
    Size                = UDim2.new(1, 0, 0, 38),
    Position            = UDim2.new(0, 0, 0, 10),
    BackgroundTransparency = 1,
    Text                = "GNS",
    TextColor3          = C.accentHi,
    TextSize            = 24,
    Font                = Enum.Font.GothamBold,
    TextXAlignment      = Enum.TextXAlignment.Center,
    ZIndex              = 5,
}, IconWrap)

-- Animated color shift on GNS text
local gnsColors = {C.accentHi, C.cyan, C.gold, C.purple, C.accentHi}
local gnsIdx = 1
task.spawn(function()
    while true do
        task.wait(1.2)
        gnsIdx = gnsIdx % (#gnsColors - 1) + 1
        TweenService:Create(GNSLabel, TweenInfo.new(0.6), {TextColor3 = gnsColors[gnsIdx]}):Play()
    end
end)

local HubSubLabel = mk("TextLabel", {
    Size                   = UDim2.new(1, 0, 0, 14),
    Position               = UDim2.new(0, 0, 1, -18),
    BackgroundTransparency = 1,
    Text                   = "HUB",
    TextColor3             = C.subtext,
    TextSize               = 9,
    Font                   = Enum.Font.GothamBold,
    TextXAlignment         = Enum.TextXAlignment.Center,
    ZIndex                 = 5,
}, IconWrap)

local IconBtn = mk("TextButton", {
    Size               = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text               = "",
    ZIndex             = 10,
}, IconWrap)
makeDraggable(IconBtn, IconWrap)

-- // ─────────────────────────────────────────────
-- // MAIN WINDOW
-- // ─────────────────────────────────────────────
local Window = mk("Frame", {
    Size             = UDim2.new(0, 860, 0, 580),
    Position         = UDim2.new(0.5, -430, 0.5, -290),
    BackgroundColor3 = C.bg,
    BorderSizePixel  = 0,
    Visible          = false,
    ClipsDescendants = true,
}, Screen)
corner(14, Window)
stroke(C.border, 1.2, Window)

-- // TITLE BAR
local TitleBar = mk("Frame", {
    Size             = UDim2.new(1, 0, 0, 42),
    BackgroundColor3 = C.sidebar,
    BorderSizePixel  = 0,
}, Window)
-- bottom fill
mk("Frame", {Size=UDim2.new(1,0,0,14), Position=UDim2.new(0,0,1,-14), BackgroundColor3=C.sidebar, BorderSizePixel=0}, TitleBar)

-- Traffic lights
local function trafficLight(x, col)
    local f = mk("Frame", {Size=UDim2.new(0,13,0,13), Position=UDim2.new(0,x,0.5,-6), BackgroundColor3=col, BorderSizePixel=0}, TitleBar)
    corner(999, f)
    return f
end
trafficLight(12, Color3.fromRGB(255,95,87))
trafficLight(30, Color3.fromRGB(255,189,46))
trafficLight(48, Color3.fromRGB(40,200,64))

-- GNS branding in titlebar
mk("TextLabel", {
    Size=UDim2.new(0,90,1,0), Position=UDim2.new(0,68,0,0),
    BackgroundTransparency=1, Text="⚡ GNS HUB",
    TextColor3=C.accentHi, TextSize=13, Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left,
}, TitleBar)

-- Tab title center
local TabTitle = mk("TextLabel", {
    Size=UDim2.new(0,200,1,0), Position=UDim2.new(0.5,-100,0,0),
    BackgroundTransparency=1, Text="Auto Steal",
    TextColor3=C.text, TextSize=13, Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Center,
}, TitleBar)

-- Search bar
local SearchBar = mk("Frame", {
    Size=UDim2.new(0,180,0,26), Position=UDim2.new(1,-220,0.5,-13),
    BackgroundColor3=C.panel, BorderSizePixel=0,
}, TitleBar)
corner(6, SearchBar)
stroke(C.border, 1, SearchBar)
mk("TextLabel", {Size=UDim2.new(0,20,1,0), Position=UDim2.new(0,6,0,0), BackgroundTransparency=1, Text="🔍", TextSize=11, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Center}, SearchBar)
mk("TextBox", {
    Size=UDim2.new(1,-28,1,0), Position=UDim2.new(0,24,0,0),
    BackgroundTransparency=1, Text="", PlaceholderText="Search...",
    TextColor3=C.text, PlaceholderColor3=C.dim,
    TextSize=11, Font=Enum.Font.Gotham, ClearTextOnFocus=false,
}, SearchBar)

makeDraggable(TitleBar, Window)

-- // ─────────────────────────────────────────────
-- // SIDEBAR
-- // ─────────────────────────────────────────────
local Sidebar = mk("Frame", {
    Size=UDim2.new(0,210,1,-42), Position=UDim2.new(0,0,0,42),
    BackgroundColor3=C.sidebar, BorderSizePixel=0,
}, Window)

-- Hub name block
local HubNameBlock = mk("Frame", {Size=UDim2.new(1,0,0,68), BackgroundColor3=C.panel, BorderSizePixel=0}, Sidebar)
pad(14,14,10,10, HubNameBlock)
mk("TextLabel", {
    Size=UDim2.new(1,0,0,26), BackgroundTransparency=1,
    Text="⚡ GNS Hub", TextColor3=C.accentHi, TextSize=17,
    Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left,
}, HubNameBlock)
mk("TextLabel", {
    Size=UDim2.new(1,0,0,16), Position=UDim2.new(0,0,0,28),
    BackgroundTransparency=1, Text="Steal an Egg • v1.0",
    TextColor3=C.subtext, TextSize=10,
    Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left,
}, HubNameBlock)

local SideBody = mk("ScrollingFrame", {
    Size=UDim2.new(1,0,1,-68), Position=UDim2.new(0,0,0,68),
    BackgroundTransparency=1, BorderSizePixel=0,
    ScrollBarThickness=2, ScrollBarImageColor3=C.accent,
    CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
}, Sidebar)
mk("UIListLayout", {Padding=UDim.new(0,2), SortOrder=Enum.SortOrder.LayoutOrder}, SideBody)
pad(10,10,8,8, SideBody)

local function sectionHeader(text, parent, order)
    local f = mk("Frame", {Size=UDim2.new(1,0,0,22), BackgroundTransparency=1, LayoutOrder=order}, parent)
    local dot = mk("Frame", {Size=UDim2.new(0,5,0,5), Position=UDim2.new(0,0,0.5,-2), BackgroundColor3=C.accent, BorderSizePixel=0}, f)
    corner(999, dot)
    mk("TextLabel", {
        Size=UDim2.new(1,-12,1,0), Position=UDim2.new(0,12,0,0),
        BackgroundTransparency=1, Text=text, TextColor3=C.subtext,
        TextSize=9, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left,
    }, f)
end

-- Nav system
local navBtns      = {}
local ContentFrames = {}

local function sideNavBtn(label, icon, tabId, order)
    local btn = mk("TextButton", {
        Size=UDim2.new(1,0,0,34), BackgroundTransparency=1,
        Text="", BorderSizePixel=0, LayoutOrder=order,
    }, SideBody)
    local indicator = mk("Frame", {
        Size=UDim2.new(0,3,0,22), Position=UDim2.new(0,0,0.5,-11),
        BackgroundColor3=C.accent, BorderSizePixel=0, Visible=false,
    }, btn)
    corner(999, indicator)
    mk("TextLabel", {
        Size=UDim2.new(0,22,1,0), Position=UDim2.new(0,10,0,0),
        BackgroundTransparency=1, Text=icon, TextSize=14,
        Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Center,
    }, btn)
    local textLbl = mk("TextLabel", {
        Size=UDim2.new(1,-36,1,0), Position=UDim2.new(0,36,0,0),
        BackgroundTransparency=1, Text=label, TextColor3=C.subtext,
        TextSize=12, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left,
    }, btn)
    local function setActive(v)
        indicator.Visible     = v
        textLbl.TextColor3    = v and C.text or C.subtext
        textLbl.Font          = v and Enum.Font.GothamBold or Enum.Font.Gotham
        btn.BackgroundTransparency = v and 0 or 1
        if v then
            btn.BackgroundColor3 = C.card
            corner(8, btn)
        end
    end
    btn.MouseButton1Click:Connect(function()
        for _, nb in ipairs(navBtns) do nb.setActive(false) end
        setActive(true)
        for id, cf in pairs(ContentFrames) do cf.Visible = (id == tabId) end
        TabTitle.Text    = label
        State.currentTab = tabId
    end)
    table.insert(navBtns, {setActive=setActive, tabId=tabId})
    return {setActive=setActive, btn=btn}
end

sectionHeader("EGGS", SideBody, 1)
local navAutoSteal  = sideNavBtn("Auto Steal",    "◎", "autoSteal",  2)
local navEggPredict = sideNavBtn("Egg Predictor", "☯", "eggPredict", 3)
local navEggESP     = sideNavBtn("Egg ESP",       "◈", "eggESP",     4)
sectionHeader("GAMEPLAY", SideBody, 5)
local navTreadmill  = sideNavBtn("Treadmill",     "⇄", "treadmill",  6)
local navRift       = sideNavBtn("The Rift",      "⬡", "rift",       7)
sectionHeader("ADMIN ABUSE", SideBody, 8)
local navAdminAbuse = sideNavBtn("Admin Abuse",   "👑","adminAbuse", 9)

-- // ─────────────────────────────────────────────
-- // CONTENT AREA
-- // ─────────────────────────────────────────────
local ContentArea = mk("Frame", {
    Size=UDim2.new(1,-210,1,-42), Position=UDim2.new(0,210,0,42),
    BackgroundTransparency=1, BorderSizePixel=0,
}, Window)

local function makeContent(id)
    local f = mk("ScrollingFrame", {
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
        BorderSizePixel=0, ScrollBarThickness=3,
        ScrollBarImageColor3=C.accent, CanvasSize=UDim2.new(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y, Visible=false,
    }, ContentArea)
    mk("UIListLayout", {Padding=UDim.new(0,0), SortOrder=Enum.SortOrder.LayoutOrder}, f)
    ContentFrames[id] = f
    return f
end

local function makeSection(parent, title, titleColor, order)
    local wrap = mk("Frame", {
        Size=UDim2.new(1,0,0,0), BackgroundColor3=C.card,
        BorderSizePixel=0, AutomaticSize=Enum.AutomaticSize.Y, LayoutOrder=order,
    }, parent)
    local header = mk("Frame", {Size=UDim2.new(1,0,0,36), BackgroundColor3=C.panel, BorderSizePixel=0}, wrap)
    pad(16,16,0,0, header)
    mk("TextLabel", {
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
        Text=title, TextColor3=titleColor or C.text,
        TextSize=12, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left,
    }, header)
    local body = mk("Frame", {
        Size=UDim2.new(1,0,0,0), Position=UDim2.new(0,0,0,36),
        BackgroundTransparency=1, AutomaticSize=Enum.AutomaticSize.Y,
    }, wrap)
    return body, wrap
end

local function divider(parent, lo)
    mk("Frame", {Size=UDim2.new(1,0,0,1), BackgroundColor3=C.border, BorderSizePixel=0, LayoutOrder=lo or 99}, parent)
end

local function rowToggle(parent, label, defaultOn, order)
    local row = mk("Frame", {Size=UDim2.new(1,0,0,44), BackgroundTransparency=1, LayoutOrder=order}, parent)
    pad(20,20,0,0, row)
    mk("TextLabel", {
        Size=UDim2.new(1,-60,1,0), BackgroundTransparency=1,
        Text=label, TextColor3=C.text, TextSize=12,
        Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left,
    }, row)
    local track = mk("Frame", {
        Size=UDim2.new(0,44,0,22), Position=UDim2.new(1,-44,0.5,-11),
        BackgroundColor3=defaultOn and C.accentDim or Color3.fromRGB(35,40,65),
        BorderSizePixel=0,
    }, row)
    corner(999, track)
    stroke(C.border, 1, track)
    local thumb = mk("Frame", {
        Size=UDim2.new(0,16,0,16),
        Position=defaultOn and UDim2.new(0,25,0.5,-8) or UDim2.new(0,3,0.5,-8),
        BackgroundColor3=defaultOn and C.accent or C.dim, BorderSizePixel=0,
    }, track)
    corner(999, thumb)
    local togBtn = mk("TextButton", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", ZIndex=5}, track)
    local on = defaultOn or false
    local function setOn(v)
        on = v
        TweenService:Create(thumb, TweenInfo.new(0.15), {
            Position=v and UDim2.new(0,25,0.5,-8) or UDim2.new(0,3,0.5,-8),
            BackgroundColor3=v and C.accent or C.dim,
        }):Play()
        TweenService:Create(track, TweenInfo.new(0.15), {
            BackgroundColor3=v and C.accentDim or Color3.fromRGB(35,40,65),
        }):Play()
    end
    local cbs = {}
    togBtn.MouseButton1Click:Connect(function()
        setOn(not on)
        for _, cb in ipairs(cbs) do pcall(cb, on) end
    end)
    return {setOn=setOn, getOn=function() return on end, onChanged=function(cb) table.insert(cbs,cb) end}
end

local function rowButton(parent, label, order)
    local row = mk("Frame", {Size=UDim2.new(1,0,0,48), BackgroundTransparency=1, LayoutOrder=order}, parent)
    pad(20,20,6,6, row)
    local btn = mk("TextButton", {
        Size=UDim2.new(1,0,0,34), BackgroundColor3=C.accentDim,
        Text=label, TextColor3=Color3.new(1,1,1),
        TextSize=12, Font=Enum.Font.GothamBold, BorderSizePixel=0,
    }, row)
    corner(10, btn)
    stroke(C.accent, 1, btn)
    btn.MouseEnter:Connect(function() TweenService:Create(btn,TweenInfo.new(0.12),{BackgroundColor3=C.accent}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn,TweenInfo.new(0.12),{BackgroundColor3=C.accentDim}):Play() end)
    return btn
end

local function dropdownRow(parent, label, placeholder, order)
    local row = mk("Frame", {Size=UDim2.new(1,0,0,56), BackgroundTransparency=1, LayoutOrder=order}, parent)
    pad(20,20,6,6, row)
    mk("TextLabel", {
        Size=UDim2.new(1,0,0,18), BackgroundTransparency=1,
        Text=label, TextColor3=C.subtext, TextSize=10,
        Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left,
    }, row)
    local dd = mk("TextButton", {
        Size=UDim2.new(1,0,0,28), Position=UDim2.new(0,0,0,20),
        BackgroundColor3=C.panel, Text=placeholder,
        TextColor3=C.dim, TextSize=11, Font=Enum.Font.Gotham,
        BorderSizePixel=0,
    }, row)
    corner(6, dd)
    stroke(C.border, 1, dd)
    mk("TextLabel", {
        Size=UDim2.new(0,16,0,16), Position=UDim2.new(1,-22,0.5,-8),
        BackgroundTransparency=1, Text="▾", TextColor3=C.dim,
        TextSize=12, Font=Enum.Font.GothamBold,
    }, dd)
    return dd
end

-- // ─────────────────────────────────────────────
-- // TAB: AUTO STEAL
-- // ─────────────────────────────────────────────
local cfAutoSteal = makeContent("autoSteal")
local asCols = mk("Frame", {
    Size=UDim2.new(1,0,0,0), BackgroundTransparency=1,
    AutomaticSize=Enum.AutomaticSize.Y, LayoutOrder=1,
}, cfAutoSteal)

local asLeft = mk("Frame", {
    Size=UDim2.new(0.5,-1,0,0), BackgroundTransparency=1,
    AutomaticSize=Enum.AutomaticSize.Y,
}, asCols)
mk("Frame", {
    Size=UDim2.new(0,1,1,0), Position=UDim2.new(0.5,0,0,0),
    BackgroundColor3=C.border, BorderSizePixel=0,
}, asCols)
local asRight = mk("Frame", {
    Size=UDim2.new(0.5,-1,0,0), Position=UDim2.new(0.5,1,0,0),
    BackgroundTransparency=1, AutomaticSize=Enum.AutomaticSize.Y,
}, asCols)
mk("UIListLayout", {Padding=UDim.new(0,0), SortOrder=Enum.SortOrder.LayoutOrder}, asLeft)
mk("UIListLayout", {Padding=UDim.new(0,0), SortOrder=Enum.SortOrder.LayoutOrder}, asRight)

-- LEFT: Settings
local asLBody = (function()
    local b, _ = makeSection(asLeft, "Auto Steal Settings", C.accentHi, 1)
    mk("UIListLayout", {Padding=UDim.new(0,0), SortOrder=Enum.SortOrder.LayoutOrder}, b)
    return b
end)()

local togAutoSteal = rowToggle(asLBody, "Enable Auto Steal", false, 1)
divider(asLBody, 2)
local togStealOnce = rowToggle(asLBody, "Steal Once Only", false, 3)
divider(asLBody, 4)
local togGodMode   = rowToggle(asLBody, "God Mode (Unkillable)", true, 5)
divider(asLBody, 6)
local togRideBack  = rowToggle(asLBody, "Ride Mount After Steal", true, 7)
divider(asLBody, 8)

-- Rarity filter
local asRarBody = (function()
    local b, _ = makeSection(asLeft, "Target Rarities", C.accentHi, 2)
    mk("UIListLayout", {Padding=UDim.new(0,0), SortOrder=Enum.SortOrder.LayoutOrder}, b)
    return b
end)()

local rarityToggles = {}
for i, r in ipairs(RARITY_DATA) do
    local row = mk("Frame", {Size=UDim2.new(1,0,0,36), BackgroundTransparency=1, LayoutOrder=i}, asRarBody)
    pad(16,16,0,0, row)
    local dot = mk("Frame", {
        Size=UDim2.new(0,8,0,8), Position=UDim2.new(0,0,0.5,-4),
        BackgroundColor3=r.color, BorderSizePixel=0,
    }, row)
    corner(999, dot)
    mk("TextLabel", {
        Size=UDim2.new(1,-60,1,0), Position=UDim2.new(0,16,0,0),
        BackgroundTransparency=1, Text=r.name,
        TextColor3=r.color, TextSize=12,
        Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left,
    }, row)
    local defaultOn = State.selectedRar[r.name] == true
    local tg = rowToggle(asRarBody, "", defaultOn, i)
    -- reposition toggle inside the row
    local track = mk("Frame", {
        Size=UDim2.new(0,44,0,22), Position=UDim2.new(1,-44,0.5,-11),
        BackgroundColor3=defaultOn and C.accentDim or Color3.fromRGB(35,40,65),
        BorderSizePixel=0,
    }, row)
    corner(999, track)
    stroke(C.border, 1, track)
    local thumb = mk("Frame", {
        Size=UDim2.new(0,16,0,16),
        Position=defaultOn and UDim2.new(0,25,0.5,-8) or UDim2.new(0,3,0.5,-8),
        BackgroundColor3=defaultOn and r.color or C.dim, BorderSizePixel=0,
    }, track)
    corner(999, thumb)
    local togBtn2 = mk("TextButton", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", ZIndex=5}, track)
    local on2 = defaultOn
    togBtn2.MouseButton1Click:Connect(function()
        on2 = not on2
        State.selectedRar[r.name] = on2
        TweenService:Create(thumb, TweenInfo.new(0.15), {
            Position=on2 and UDim2.new(0,25,0.5,-8) or UDim2.new(0,3,0.5,-8),
            BackgroundColor3=on2 and r.color or C.dim,
        }):Play()
        TweenService:Create(track, TweenInfo.new(0.15), {
            BackgroundColor3=on2 and C.accentDim or Color3.fromRGB(35,40,65),
        }):Play()
    end)
    rarityToggles[r.name] = {getOn=function() return on2 end}
    if i < #RARITY_DATA then divider(asRarBody, i + 100) end
end

-- RIGHT: Egg list
local asRBody = (function()
    local b, _ = makeSection(asRight, "Detected Eggs (Sorted by Rarity)", C.accentHi, 1)
    mk("UIListLayout", {Padding=UDim.new(0,4), SortOrder=Enum.SortOrder.LayoutOrder}, b)
    pad(8,8,6,6, b)
    return b
end)()

-- Status
local asStatus = mk("TextLabel", {
    Size=UDim2.new(1,0,0,30), BackgroundTransparency=1,
    Text="● Idle — waiting", TextColor3=C.subtext,
    TextSize=11, Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=0,
}, asRBody)
pad(4,0,0,0, asStatus)

local function setStatus(txt, col)
    asStatus.Text       = txt
    asStatus.TextColor3 = col or C.subtext
end

-- Build egg row
local function buildEggRow(data, idx, parent)
    local rd  = getRD(data.rarity)
    local row = mk("Frame", {
        Size=UDim2.new(1,0,0,58), BackgroundColor3=C.panel,
        BorderSizePixel=0, LayoutOrder=idx,
    }, parent)
    corner(10, row)
    stroke(Color3.fromRGB(28,34,60), 1, row)

    -- Rarity stripe
    local stripe = mk("Frame", {
        Size=UDim2.new(0,3,1,-8), Position=UDim2.new(0,4,0,4),
        BackgroundColor3=rd.color, BorderSizePixel=0,
    }, row)
    corner(4, stripe)

    mk("TextLabel", {
        Size=UDim2.new(1,-120,0,22), Position=UDim2.new(0,16,0,8),
        BackgroundTransparency=1, Text=data.pet,
        TextColor3=C.text, TextSize=13,
        Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd,
    }, row)
    mk("TextLabel", {
        Size=UDim2.new(1,-120,0,16), Position=UDim2.new(0,16,0,32),
        BackgroundTransparency=1,
        Text=data.rarity .. (data.value~="" and ("  •  💰 "..data.value) or "") .. "  •  📍 "..data.dist.."m",
        TextColor3=rd.color, TextSize=10,
        Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left,
    }, row)

    local stBtn = mk("TextButton", {
        Size=UDim2.new(0,64,0,34), Position=UDim2.new(1,-72,0.5,-17),
        BackgroundColor3=C.accent, Text="STEAL",
        TextColor3=Color3.new(1,1,1), TextSize=11,
        Font=Enum.Font.GothamBold, BorderSizePixel=0,
    }, row)
    corner(9, stBtn)
    stBtn.MouseEnter:Connect(function() TweenService:Create(stBtn,TweenInfo.new(0.1),{BackgroundColor3=C.accentHi}):Play() end)
    stBtn.MouseLeave:Connect(function() TweenService:Create(stBtn,TweenInfo.new(0.1),{BackgroundColor3=C.accent}):Play() end)

    stBtn.MouseButton1Click:Connect(function()
        if State.stealing then return end
        State.stealing = true
        setStatus("🚀 Stealing → " .. data.pet .. " [" .. data.rarity .. "]", C.accentHi)
        stBtn.Text = "..."
        stBtn.BackgroundTransparency = 0.5
        stealEgg(data, function(ok)
            State.stealing = false
            stBtn.Text = "STEAL"
            stBtn.BackgroundTransparency = 0
            setStatus(ok and "✅ Got: "..data.pet or "❌ Failed", ok and C.green or C.red)
        end)
    end)
end

-- // ─────────────────────────────────────────────
-- // TAB: EGG PREDICTOR
-- // ─────────────────────────────────────────────
local cfEggPredict = makeContent("eggPredict")
local epCols = mk("Frame", {
    Size=UDim2.new(1,0,0,0), BackgroundTransparency=1,
    AutomaticSize=Enum.AutomaticSize.Y, LayoutOrder=1,
}, cfEggPredict)
local epLeft = mk("Frame", {Size=UDim2.new(0.5,-1,0,0), BackgroundTransparency=1, AutomaticSize=Enum.AutomaticSize.Y}, epCols)
mk("Frame", {Size=UDim2.new(0,1,1,0), Position=UDim2.new(0.5,0,0,0), BackgroundColor3=C.border, BorderSizePixel=0}, epCols)
local epRight = mk("Frame", {Size=UDim2.new(0.5,-1,0,0), Position=UDim2.new(0.5,1,0,0), BackgroundTransparency=1, AutomaticSize=Enum.AutomaticSize.Y}, epCols)
mk("UIListLayout", {Padding=UDim.new(0,0), SortOrder=Enum.SortOrder.LayoutOrder}, epLeft)
mk("UIListLayout", {Padding=UDim.new(0,0), SortOrder=Enum.SortOrder.LayoutOrder}, epRight)

local epLBody = (function()
    local b, _ = makeSection(epLeft, "Prediction Settings", C.accentHi, 1)
    mk("UIListLayout", {Padding=UDim.new(0,0), SortOrder=Enum.SortOrder.LayoutOrder}, b)
    return b
end)()
rowToggle(epLBody, "Auto Hatch Rarest", false, 1)
divider(epLBody, 2)
rowToggle(epLBody, "Show Pet Preview", true, 3)
divider(epLBody, 4)
dropdownRow(epLBody, "Sort By", "Sort By • Rarity", 5)

local epRBody = (function()
    local b, _ = makeSection(epRight, "Live Egg Predictions", C.accentHi, 1)
    mk("UIListLayout", {Padding=UDim.new(0,4), SortOrder=Enum.SortOrder.LayoutOrder}, b)
    pad(8,8,6,6, b)
    return b
end)()

local function buildPredictRow(data, idx, parent)
    local rd  = getRD(data.rarity)
    local row = mk("Frame", {
        Size=UDim2.new(1,0,0,50), BackgroundColor3=C.panel,
        BorderSizePixel=0, LayoutOrder=idx,
    }, parent)
    corner(10, row)
    stroke(Color3.fromRGB(28,34,60), 1, row)
    local stripe = mk("Frame", {
        Size=UDim2.new(0,3,1,-8), Position=UDim2.new(0,4,0,4),
        BackgroundColor3=rd.color, BorderSizePixel=0,
    }, row)
    corner(4, stripe)
    mk("TextLabel", {
        Size=UDim2.new(0.7,0,0,20), Position=UDim2.new(0,16,0,6),
        BackgroundTransparency=1, Text=data.pet,
        TextColor3=C.text, TextSize=12, Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd,
    }, row)
    mk("TextLabel", {
        Size=UDim2.new(0.7,0,0,14), Position=UDim2.new(0,16,0,28),
        BackgroundTransparency=1, Text=data.rarity .. "  •  " .. data.dist .. "m",
        TextColor3=rd.color, TextSize=9, Font=Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Left,
    }, row)
    mk("TextLabel", {
        Size=UDim2.new(0.28,0,0,40), Position=UDim2.new(0.72,0,0.5,-20),
        BackgroundTransparency=1, Text="🐾",
        TextSize=22, Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Center,
    }, row)
end

-- // ─────────────────────────────────────────────
-- // TAB: EGG ESP
-- // ─────────────────────────────────────────────
local cfEggESP = makeContent("eggESP")
local espCols  = mk("Frame", {Size=UDim2.new(1,0,0,0), BackgroundTransparency=1, AutomaticSize=Enum.AutomaticSize.Y, LayoutOrder=1}, cfEggESP)
local espLeft  = mk("Frame", {Size=UDim2.new(0.5,-1,0,0), BackgroundTransparency=1, AutomaticSize=Enum.AutomaticSize.Y}, espCols)
mk("Frame", {Size=UDim2.new(0,1,1,0), Position=UDim2.new(0.5,0,0,0), BackgroundColor3=C.border, BorderSizePixel=0}, espCols)
local espRight = mk("Frame", {Size=UDim2.new(0.5,-1,0,0), Position=UDim2.new(0.5,1,0,0), BackgroundTransparency=1, AutomaticSize=Enum.AutomaticSize.Y}, espCols)
mk("UIListLayout", {Padding=UDim.new(0,0), SortOrder=Enum.SortOrder.LayoutOrder}, espLeft)
mk("UIListLayout", {Padding=UDim.new(0,0), SortOrder=Enum.SortOrder.LayoutOrder}, espRight)

local espLBody = (function()
    local b, _ = makeSection(espLeft, "ESP Settings", C.accentHi, 1)
    mk("UIListLayout", {Padding=UDim.new(0,0), SortOrder=Enum.SortOrder.LayoutOrder}, b)
    return b
end)()
rowToggle(espLBody, "Show Egg Names",    true,  1); divider(espLBody,2)
rowToggle(espLBody, "Show Rarity Tags",  true,  3); divider(espLBody,4)
rowToggle(espLBody, "Show Distance",     true,  5); divider(espLBody,6)
rowToggle(espLBody, "Highlight Rare+",   true,  7); divider(espLBody,8)
rowToggle(espLBody, "Show Boxes",        false, 9)

local espRBody = (function()
    local b, _ = makeSection(espRight, "Live Result", C.accentHi, 1)
    mk("UIListLayout", {Padding=UDim.new(0,0), SortOrder=Enum.SortOrder.LayoutOrder}, b)
    pad(16,16,8,8, b)
    return b
end)()
local lrStatus = mk("TextLabel", {
    Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
    BackgroundTransparency=1, Text="Scanning...",
    TextColor3=C.subtext, TextSize=11, Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true, LayoutOrder=1,
}, espRBody)

-- // ─────────────────────────────────────────────
-- // TAB: TREADMILL
-- // ─────────────────────────────────────────────
local cfTreadmill = makeContent("treadmill")
local tmCols  = mk("Frame", {Size=UDim2.new(1,0,0,0), BackgroundTransparency=1, AutomaticSize=Enum.AutomaticSize.Y, LayoutOrder=1}, cfTreadmill)
local tmLeft  = mk("Frame", {Size=UDim2.new(0.5,-1,0,0), BackgroundTransparency=1, AutomaticSize=Enum.AutomaticSize.Y}, tmCols)
mk("Frame", {Size=UDim2.new(0,1,1,0), Position=UDim2.new(0.5,0,0,0), BackgroundColor3=C.border, BorderSizePixel=0}, tmCols)
local tmRight = mk("Frame", {Size=UDim2.new(0.5,-1,0,0), Position=UDim2.new(0.5,1,0,0), BackgroundTransparency=1, AutomaticSize=Enum.AutomaticSize.Y}, tmCols)
mk("UIListLayout", {Padding=UDim.new(0,0), SortOrder=Enum.SortOrder.LayoutOrder}, tmLeft)
mk("UIListLayout", {Padding=UDim.new(0,0), SortOrder=Enum.SortOrder.LayoutOrder}, tmRight)

local tmLBody = (function()
    local b, _ = makeSection(tmLeft, "Treadmill Settings", C.accentHi, 1)
    mk("UIListLayout", {Padding=UDim.new(0,0), SortOrder=Enum.SortOrder.LayoutOrder}, b)
    return b
end)()
local descTm = mk("TextLabel", {
    Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
    BackgroundTransparency=1, Text="Auto-walks the treadmill to earn eggs faster.",
    TextColor3=C.accentHi, TextSize=11, Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true, LayoutOrder=1,
}, tmLBody)
pad(20,20,8,8, descTm)
rowToggle(tmLBody, "Auto Treadmill", false, 2)
divider(tmLBody, 3)
dropdownRow(tmLBody, "Treadmill Speed", "Normal", 4)

local tmRBody = (function()
    local b, _ = makeSection(tmRight, "Treadmill Status", C.accentHi, 1)
    mk("UIListLayout", {Padding=UDim.new(0,0), SortOrder=Enum.SortOrder.LayoutOrder}, b)
    pad(16,16,8,8, b)
    return b
end)()
mk("TextLabel", {
    Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
    BackgroundTransparency=1, Text="Status: Idle",
    TextColor3=C.dim, TextSize=11, Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true, LayoutOrder=1,
}, tmRBody)

-- // ─────────────────────────────────────────────
-- // TAB: THE RIFT
-- // ─────────────────────────────────────────────
local cfRift  = makeContent("rift")
local trCols  = mk("Frame", {Size=UDim2.new(1,0,0,0), BackgroundTransparency=1, AutomaticSize=Enum.AutomaticSize.Y, LayoutOrder=1}, cfRift)
local trLeft  = mk("Frame", {Size=UDim2.new(0.5,-1,0,0), BackgroundTransparency=1, AutomaticSize=Enum.AutomaticSize.Y}, trCols)
mk("Frame", {Size=UDim2.new(0,1,1,0), Position=UDim2.new(0.5,0,0,0), BackgroundColor3=C.border, BorderSizePixel=0}, trCols)
local trRight = mk("Frame", {Size=UDim2.new(0.5,-1,0,0), Position=UDim2.new(0.5,1,0,0), BackgroundTransparency=1, AutomaticSize=Enum.AutomaticSize.Y}, trCols)
mk("UIListLayout", {Padding=UDim.new(0,0), SortOrder=Enum.SortOrder.LayoutOrder}, trLeft)
mk("UIListLayout", {Padding=UDim.new(0,0), SortOrder=Enum.SortOrder.LayoutOrder}, trRight)

local trLBody = (function()
    local b, _ = makeSection(trLeft, "Rift Farm Settings", C.accentHi, 1)
    mk("UIListLayout", {Padding=UDim.new(0,0), SortOrder=Enum.SortOrder.LayoutOrder}, b)
    return b
end)()
local trDesc = mk("TextLabel", {
    Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
    BackgroundTransparency=1,
    Text="Three pets become one Rift egg.\nSubmitting permanently consumes the three offered pets.",
    TextColor3=C.accentHi, TextSize=11, Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true, LayoutOrder=1,
}, trLBody)
pad(20,20,8,8, trDesc)
dropdownRow(trLBody, "Rift Banner to Farm", "Any Banner", 2)
rowToggle(trLBody, "Farm Missing Rift Pets", false, 3)
rowToggle(trLBody, "Auto Submit & Claim Rift Egg", false, 4)

local trRBody = (function()
    local b, _ = makeSection(trRight, "Current Recipe & Progress", C.accentHi, 1)
    mk("UIListLayout", {Padding=UDim.new(0,0), SortOrder=Enum.SortOrder.LayoutOrder}, b)
    return b
end)()
local trRecipe = mk("TextLabel", {
    Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
    BackgroundTransparency=1,
    Text="The Rift\nBanner: Shattered Rift\nPty: 0/50\nTrades this session: 0\n1. Salamander — own 0\n2. Snowy Owl — own 0\n3. Bladehide — own 0",
    TextColor3=C.dim, TextSize=10, Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true, LayoutOrder=1,
}, trRBody)
pad(20,20,8,8, trRecipe)
rowButton(trRBody, "Refresh Requirements", 2)
rowButton(trRBody, "Submit One Set / Claim Reward", 3)

-- // ─────────────────────────────────────────────
-- // TAB: ADMIN ABUSE
-- // ─────────────────────────────────────────────
local cfAdminAbuse = makeContent("adminAbuse")
local aaCols  = mk("Frame", {Size=UDim2.new(1,0,0,0), BackgroundTransparency=1, AutomaticSize=Enum.AutomaticSize.Y, LayoutOrder=1}, cfAdminAbuse)
local aaLeft  = mk("Frame", {Size=UDim2.new(0.5,-1,0,0), BackgroundTransparency=1, AutomaticSize=Enum.AutomaticSize.Y}, aaCols)
mk("Frame", {Size=UDim2.new(0,1,1,0), Position=UDim2.new(0.5,0,0,0), BackgroundColor3=C.border, BorderSizePixel=0}, aaCols)
local aaRight = mk("Frame", {Size=UDim2.new(0.5,-1,0,0), Position=UDim2.new(0.5,1,0,0), BackgroundTransparency=1, AutomaticSize=Enum.AutomaticSize.Y}, aaCols)
mk("UIListLayout", {Padding=UDim.new(0,0), SortOrder=Enum.SortOrder.LayoutOrder}, aaLeft)
mk("UIListLayout", {Padding=UDim.new(0,0), SortOrder=Enum.SortOrder.LayoutOrder}, aaRight)

local aaLBody = (function()
    local b, _ = makeSection(aaLeft, "Dragon Event Auto Farm", C.accentHi, 1)
    mk("UIListLayout", {Padding=UDim.new(0,0), SortOrder=Enum.SortOrder.LayoutOrder}, b)
    return b
end)()
local aaDesc = mk("TextLabel", {
    Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
    BackgroundTransparency=1, Text="Dragon event only. Selects dragon-tier eggs. Only DragonEggEvent categories appear here.",
    TextColor3=C.accentHi, TextSize=11, Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true, LayoutOrder=1,
}, aaLBody)
pad(20,20,8,8, aaDesc)
dropdownRow(aaLBody, "Dragon Event Eggs", "Dragon Event Eggs...", 2)
rowToggle(aaLBody, "Auto Farm Dragon Event Egg", false, 3)

-- HOLD LONGEST
local hlBody = (function()
    local b, _ = makeSection(aaLeft, "Hold Longest Admin Abuse", C.accentHi, 2)
    mk("UIListLayout", {Padding=UDim.new(0,0), SortOrder=Enum.SortOrder.LayoutOrder}, b)
    return b
end)()
local hlDesc = mk("TextLabel", {
    Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
    BackgroundTransparency=1, Text="Flies 300 studs into the sky, enables god mode, spams all hold/zone/admin interactions. Unkillable.",
    TextColor3=C.subtext, TextSize=11, Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true, LayoutOrder=1,
}, hlBody)
pad(20,20,8,4, hlDesc)

local hlBtnWrap = mk("Frame", {Size=UDim2.new(1,0,0,52), BackgroundTransparency=1, LayoutOrder=2}, hlBody)
pad(20,20,4,8, hlBtnWrap)
local hlBtn = mk("TextButton", {
    Size=UDim2.new(1,0,0,38), BackgroundColor3=C.accentDim,
    Text="👑  HOLD LONGEST — START",
    TextColor3=Color3.new(1,1,1), TextSize=13,
    Font=Enum.Font.GothamBold, BorderSizePixel=0,
}, hlBtnWrap)
corner(10, hlBtn)
stroke(C.accentHi, 1, hlBtn)

local holdOn = false
hlBtn.MouseButton1Click:Connect(function()
    holdOn = not holdOn
    if holdOn then
        hlBtn.Text            = "👑  HOLD LONGEST — STOP"
        hlBtn.BackgroundColor3 = C.red
        startHoldLongest()
    else
        hlBtn.Text            = "👑  HOLD LONGEST — START"
        hlBtn.BackgroundColor3 = C.accentDim
        stopHoldLongest()
    end
end)

local aaRBody = (function()
    local b, _ = makeSection(aaRight, "Dragon Egg Detection", C.accentHi, 1)
    mk("UIListLayout", {Padding=UDim.new(0,0), SortOrder=Enum.SortOrder.LayoutOrder}, b)
    return b
end)()
local availTitle = mk("TextLabel", {
    Size=UDim2.new(1,0,0,20), BackgroundTransparency=1,
    Text="Available Dragon Eggs", TextColor3=C.accentHi,
    TextSize=12, Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=1,
}, aaRBody)
pad(20,20,8,4, availTitle)
local dragonList = mk("TextLabel", {
    Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
    BackgroundTransparency=1, Text="Scanning...",
    TextColor3=C.dim, TextSize=10, Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true, LayoutOrder=2,
}, aaRBody)
pad(20,20,0,8, dragonList)

local liveStateBody = (function()
    local b, _ = makeSection(aaRight, "Live Event State", C.accentHi, 2)
    mk("UIListLayout", {Padding=UDim.new(0,0), SortOrder=Enum.SortOrder.LayoutOrder}, b)
    return b
end)()
local liveStateLbl = mk("TextLabel", {
    Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
    BackgroundTransparency=1,
    Text="Dragon event: Inactive\nPhase: Inactive | Spawned eggs: 0\nZone: Waiting",
    TextColor3=C.dim, TextSize=10, Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true, LayoutOrder=1,
}, liveStateBody)
pad(20,20,8,8, liveStateLbl)

-- // ─────────────────────────────────────────────
-- // SCAN LOOP
-- // ─────────────────────────────────────────────
task.spawn(function()
    while true do
        task.wait(0.5)
        local ok, eggs = pcall(scanAllEggs)
        if ok and eggs then
            State.eggList = eggs

            -- Auto steal tab egg list refresh
            if State.currentTab == "autoSteal" then
                for _, c in ipairs(asRBody:GetChildren()) do
                    if c:IsA("Frame") then c:Destroy() end
                end
                local shown = 0
                for i, data in ipairs(eggs) do
                    if State.selectedRar[data.rarity] then
                        buildEggRow(data, i, asRBody)
                        shown = shown + 1
                    end
                    if shown >= 12 then break end
                end
                if shown == 0 then
                    local lbl = mk("TextLabel", {
                        Size=UDim2.new(1,0,0,40), BackgroundTransparency=1,
                        Text="No matching eggs found", TextColor3=C.subtext,
                        TextSize=11, Font=Enum.Font.Gotham,
                        TextXAlignment=Enum.TextXAlignment.Center, LayoutOrder=99,
                    }, asRBody)
                end
            end

            -- Egg predictor refresh
            if State.currentTab == "eggPredict" then
                for _, c in ipairs(epRBody:GetChildren()) do
                    if c:IsA("Frame") then c:Destroy() end
                end
                for i, data in ipairs(eggs) do
                    buildPredictRow(data, i, epRBody)
                    if i >= 10 then break end
                end
            end

            -- Dragon detection
            local dragonEggs = {}
            for _, data in ipairs(eggs) do
                if data.rarity=="Secret" or data.rarity=="Eternal" or data.rarity=="Mythic" or data.rarity=="Cosmic" then
                    table.insert(dragonEggs, data.pet .. " • " .. data.rarity)
                end
            end
            dragonList.Text = #dragonEggs > 0 and table.concat(dragonEggs,"\n") or "No dragon-tier eggs detected"

            -- ESP live result
            if #eggs > 0 then
                local e = eggs[1]
                lrStatus.Text       = "Best: " .. e.pet .. " [" .. e.rarity .. "] — " .. e.dist .. "m"
                lrStatus.TextColor3 = getRD(e.rarity).color
            end
        end
    end
end)

-- // AUTO STEAL LOOP — smooth, no jitter
local stealOnceFlag = false
task.spawn(function()
    while true do
        task.wait(0.15)
        if not togAutoSteal.getOn() then
            stealOnceFlag = false
            continue
        end
        if State.stealing then continue end
        if togStealOnce.getOn() and stealOnceFlag then
            togAutoSteal.setOn(false)
            setStatus("✅ Steal Once done!", C.green)
            stealOnceFlag = false
            continue
        end
        local eggs   = State.eggList
        if not eggs or #eggs == 0 then continue end
        local target = nil
        for _, data in ipairs(eggs) do
            if State.selectedRar[data.rarity] then
                target = data
                break
            end
        end
        if not target then continue end
        State.stealing = true
        setStatus("🚀 Auto → " .. target.pet .. " [" .. target.rarity .. "]", C.accentHi)
        local useGod  = togGodMode.getOn()
        local useRide = togRideBack.getOn()
        if useGod then enableGodMode() end
        stealEgg(target, function(ok)
            State.stealing = false
            if not useGod then disableGodMode() end
            if togStealOnce.getOn() then stealOnceFlag = true end
            setStatus(
                ok and "✅ Got: "..target.pet or "❌ Missed",
                ok and C.green or C.red
            )
        end)
    end
end)

-- // ─────────────────────────────────────────────
-- // WINDOW TOGGLE
-- // ─────────────────────────────────────────────
IconBtn.MouseButton1Click:Connect(function()
    Window.Visible = not Window.Visible
    if Window.Visible then
        Window.Size = UDim2.new(0, 860, 0, 0)
        TweenService:Create(Window, TweenInfo.new(0.22, Enum.EasingStyle.Back), {Size=UDim2.new(0,860,0,580)}):Play()
        -- Activate default tab
        for _, nb in ipairs(navBtns) do nb.setActive(false) end
        navAutoSteal.setActive(true)
        for id, cf in pairs(ContentFrames) do cf.Visible = (id == "autoSteal") end
        TabTitle.Text    = "Auto Steal"
        State.currentTab = "autoSteal"
    else
        TweenService:Create(Window, TweenInfo.new(0.15), {Size=UDim2.new(0,860,0,0)}):Play()
        task.delay(0.16, function() Window.Size = UDim2.new(0,860,0,580) end)
    end
end)

-- default tab visible on load (hidden)
for _, nb in ipairs(navBtns) do nb.setActive(false) end
navAutoSteal.setActive(true)
for id, cf in pairs(ContentFrames) do cf.Visible = (id == "autoSteal") end

-- // RESPAWN HANDLER
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    State.stealing = false
    pcall(stopFly)
    if rideWeld then pcall(function() rideWeld:Destroy() rideWeld = nil end) end
    if holdActive then
        stopHoldLongest()
        holdOn = false
        hlBtn.Text             = "👑  HOLD LONGEST — START"
        hlBtn.BackgroundColor3 = C.accentDim
    end
    setStatus("🔄 Respawned — ready", C.subtext)
end)

print("⚡ GNS HUB Loaded — Click the logo to open!")
