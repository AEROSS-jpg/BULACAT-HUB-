-- // ============================================
-- // 🐱 BULACAT HUB v4.1 — Nono Edition (FIXED)
-- // All-Map Scan | Particle Logo | Monster Ride
-- // Unknockable Steal | Real Pet Predict
-- // Draggable Logo + UI | Smooth Loop
-- // FIXED: Auto Steal loop, 100% accurate scan
-- // ============================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local CollectionService= game:GetService("CollectionService")
local CoreGui          = game:GetService("CoreGui")
local LocalPlayer      = Players.LocalPlayer

local function getChar()  return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait() end
local function getRoot()  return getChar():WaitForChild("HumanoidRootPart") end
local function getHuman() return getChar():WaitForChild("Humanoid") end

-- // ─────────────────────────────────────────────
-- // CONFIG
-- // ─────────────────────────────────────────────
local CFG = {
    EGG_KEYWORDS  = {"egg","Egg","crate","Crate","chest","hatch"},
    STEAL_DELAY   = 0.25,
    SCAN_INTERVAL = 0.6,
    FLY_HEIGHT    = 90,
    FLY_SPEED     = 200,
    WALK_SPEED    = 80,
    HOLD_HEIGHT   = 350,
    ALL_MAP_RANGE = 99999,
    PARTICLE_COUNT= 28,
}

-- // ─────────────────────────────────────────────
-- // RARITY TABLE
-- // ─────────────────────────────────────────────
local RARITY = {
    {name="Divine",   emoji="🟨", color=Color3.fromRGB(255,215,0),   rank=1},
    {name="Eternal",  emoji="🌌", color=Color3.fromRGB(180,0,255),   rank=2},
    {name="Secret",   emoji="⬛", color=Color3.fromRGB(50,50,50),    rank=3},
    {name="Cosmic",   emoji="🟪", color=Color3.fromRGB(160,0,255),   rank=4},
    {name="Legendary",emoji="🔶", color=Color3.fromRGB(255,140,0),   rank=5},
    {name="Epic",     emoji="🔷", color=Color3.fromRGB(100,50,255),  rank=6},
    {name="Rare",     emoji="🔵", color=Color3.fromRGB(0,120,255),   rank=7},
    {name="Uncommon", emoji="🟢", color=Color3.fromRGB(0,200,80),    rank=8},
    {name="Common",   emoji="⚪", color=Color3.fromRGB(180,180,180), rank=9},
}
local RARITY_MAP = {}
for _,r in ipairs(RARITY) do RARITY_MAP[r.name] = r end
local function getRD(n) return RARITY_MAP[n] or RARITY_MAP["Common"] end

-- // ─────────────────────────────────────────────
-- // SOURCE TEXT COLLECTOR (deep scan)
-- // ─────────────────────────────────────────────
local function collectSourceText(obj)
    local src = obj.Name:lower()
    for _,attr in ipairs({"Rarity","rarity","Tier","tier","Type","type","Egg","egg"}) do
        local ok,val = pcall(function() return obj:GetAttribute(attr) end)
        if ok and val then src = src .. " " .. tostring(val):lower() end
    end
    for _,v in ipairs(obj:GetDescendants()) do
        src = src .. " " .. v.Name:lower()
        if v:IsA("StringValue") then src = src .. " " .. (v.Value or ""):lower() end
        if v:IsA("TextLabel") or v:IsA("TextButton") then src = src .. " " .. (v.Text or ""):lower() end
        if v:IsA("ToolTip") then src = src .. " " .. (v.Text or ""):lower() end
        if v:IsA("ProximityPrompt") then
            src = src .. " " .. (v.ActionText or ""):lower() .. " " .. (v.ObjectText or ""):lower()
        end
    end
    local p = obj.Parent
    local depth = 0
    while p and depth < 3 do
        src = src .. " " .. p.Name:lower()
        p = p.Parent
        depth = depth + 1
    end
    return src
end

-- // ─────────────────────────────────────────────
-- // REAL PET PREDICT
-- // ─────────────────────────────────────────────
local PET_KEYWORDS = {"pet","reward","hatch","item","prize","animal","creature","give","contain"}

local function predictRarity(egg)
    local src = collectSourceText(egg)
    local order = {"divine","eternal","secret","cosmic","legendary","legend","epic","rare","uncommon","common"}
    local mapped = {"Divine","Eternal","Secret","Cosmic","Legendary","Legendary","Epic","Rare","Uncommon","Common"}
    for i,rk in ipairs(order) do
        if src:find(rk, 1, true) then return mapped[i] end
    end
    return "Common"
end

local function predictPet(egg)
    -- 1. Attributes
    for _,attr in ipairs({"Pet","pet","Reward","reward","Item","item","Prize","prize","Contains","contains","PetName","petname"}) do
        local ok,val = pcall(function() return egg:GetAttribute(attr) end)
        if ok and val and tostring(val) ~= "" and #tostring(val) < 60 then
            return tostring(val)
        end
    end
    -- 2. StringValues
    for _,v in ipairs(egg:GetDescendants()) do
        if v:IsA("StringValue") and v.Value ~= "" and #v.Value < 60 then
            local nm = v.Name:lower()
            for _,k in ipairs(PET_KEYWORDS) do
                if nm:find(k,1,true) then return v.Value end
            end
        end
    end
    -- 3. TextLabels
    for _,v in ipairs(egg:GetDescendants()) do
        if (v:IsA("TextLabel") or v:IsA("TextButton")) and v.Text ~= "" and #v.Text < 50 then
            local t = v.Text
            local tl = t:lower()
            if not t:match("^%d+$") and not tl:find("egg") and not tl:find("rarity")
               and not tl:find("click") and not tl:find("open") and not tl:find("buy") then
                return t
            end
        end
    end
    -- 4. Parent model
    if egg.Parent and egg.Parent:IsA("Model") then
        local mn = egg.Parent.Name
        if not mn:lower():find("egg") and #mn < 40 then return mn end
    end
    -- 5. Fallback
    local stripped = egg.Name:gsub("[Ee]gg",""):gsub("_"," "):gsub("%-"," "):match("^%s*(.-)%s*$")
    if stripped and #stripped > 1 then return stripped .. " Pet 🐾" end
    return "Mystery Pet 🐾"
end

-- // ─────────────────────────────────────────────
-- // EGG DETECTION HELPERS
-- // ─────────────────────────────────────────────
local function isEggObject(obj)
    local nm = obj.Name:lower()
    for _,kw in ipairs(CFG.EGG_KEYWORDS) do
        if nm:find(kw:lower(), 1, true) then return true end
    end
    for _,attr in ipairs({"Egg","IsEgg","egg","Type","Category","ObjectType","ItemType"}) do
        local ok, val = pcall(function() return obj:GetAttribute(attr) end)
        if ok and val then
            local vs = tostring(val):lower()
            for _,kw in ipairs(CFG.EGG_KEYWORDS) do
                if vs:find(kw:lower(), 1, true) then return true end
            end
        end
    end
    for _,tag in ipairs(CollectionService:GetTags(obj)) do
        local tl = tag:lower()
        for _,kw in ipairs(CFG.EGG_KEYWORDS) do
            if tl:find(kw:lower(), 1, true) then return true end
        end
    end
    if obj:FindFirstChildOfClass("ProximityPrompt") then
        local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
        local act = (prompt.ActionText or ""):lower()
        local objName = (prompt.ObjectText or ""):lower()
        for _,kw in ipairs(CFG.EGG_KEYWORDS) do
            if act:find(kw:lower(),1,true) or objName:find(kw:lower(),1,true) then return true end
        end
    end
    return false
end

local function getEggPosition(obj)
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Model") then
        local ok, cf = pcall(function() return obj:GetPivot() end)
        if ok and cf then return cf.Position end
        local pp = obj:FindFirstChildWhichIsA("BasePart", true)
        if pp then return pp.Position end
    end
    if obj:IsA("Attachment") then return obj.WorldPosition end
    return nil
end

-- // ─────────────────────────────────────────────
-- // ALL-MAP EGG SCAN v2 (100% ACCURATE)
-- // ─────────────────────────────────────────────
local function scanEggs()
    local Root = getRoot()
    local found, seen = {}, {}

    for _,obj in ipairs(workspace:GetDescendants()) do
        if seen[obj] then continue end
        seen[obj] = true

        local valid = obj:IsA("BasePart") or obj:IsA("Model")
            or obj:IsA("Attachment") or obj:IsA("ProximityPrompt")
            or obj:IsA("ClickDetector")

        if not valid then continue end

        if isEggObject(obj) then
            local pos = getEggPosition(obj)
            if pos then
                local rar = predictRarity(obj)
                local pet = predictPet(obj)
                local dist = math.floor((Root.Position - pos).Magnitude)
                table.insert(found, {egg=obj, pos=pos, rarity=rar, pet=pet, dist=dist})
            end
        end
    end

    for _,plr in ipairs(Players:GetPlayers()) do
        local char = plr.Character
        if char then
            for _,obj in ipairs(char:GetDescendants()) do
                if not seen[obj] then
                    seen[obj] = true
                    if isEggObject(obj) then
                        local pos = getEggPosition(obj)
                        if pos then
                            local rar = predictRarity(obj)
                            local pet = predictPet(obj)
                            local dist = math.floor((Root.Position - pos).Magnitude)
                            table.insert(found, {egg=obj, pos=pos, rarity=rar, pet=pet, dist=dist})
                        end
                    end
                end
            end
        end
    end

    table.sort(found, function(a,b)
        local ra = getRD(a.rarity).rank
        local rb = getRD(b.rarity).rank
        if ra ~= rb then return ra < rb end
        return a.dist < b.dist
    end)
    return found
end

-- // ─────────────────────────────────────────────
-- // GOD / UNKNOCKABLE MODE
-- // ─────────────────────────────────────────────
local godConn = nil
local function enableGodMode()
    local char = getChar()
    local hum  = getHuman()
    hum.MaxHealth = math.huge
    hum.Health    = math.huge
    if godConn then godConn:Disconnect() end
    godConn = hum.HealthChanged:Connect(function(hp)
        if hp < hum.MaxHealth then hum.Health = math.huge end
    end)
    hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
    hum.AutoRotate = false
    for _,p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            p.CanCollide = false
            p.Massless   = true
        end
    end
end

local function disableGodMode()
    if godConn then godConn:Disconnect() godConn = nil end
    local ok, hum = pcall(getHuman)
    if ok and hum then
        hum.MaxHealth = 100
        hum.Health    = 100
        hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        hum.AutoRotate = true
    end
    local ok2, char = pcall(getChar)
    if ok2 and char then
        for _,p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide = true
                p.Massless   = false
            end
        end
    end
end

-- // ─────────────────────────────────────────────
-- // FLY ENGINE
-- // ─────────────────────────────────────────────
local flyConn = nil
local bodyVel  = nil
local bodyGyro = nil
local flying   = false

local function stopFly()
    flying = false
    if flyConn then flyConn:Disconnect() flyConn = nil end
    pcall(function() if bodyVel  then bodyVel:Destroy()  bodyVel  = nil end end)
    pcall(function() if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end end)
    pcall(function() getHuman().PlatformStand = false end)
end

local function flyTo(targetPos, speed, onArrived)
    stopFly()
    flying = true
    local Root  = getRoot()
    local Human = getHuman()
    Human.PlatformStand = true

    bodyVel = Instance.new("BodyVelocity", Root)
    bodyVel.MaxForce = Vector3.new(1e7, 1e7, 1e7)
    bodyVel.Velocity = Vector3.new(0,0,0)

    bodyGyro = Instance.new("BodyGyro", Root)
    bodyGyro.MaxTorque = Vector3.new(1e7, 1e7, 1e7)
    bodyGyro.P = 1e5
    bodyGyro.D = 100

    flyConn = RunService.Heartbeat:Connect(function()
        if not flying then return end
        local ok, root = pcall(getRoot)
        if not ok then stopFly() return end
        local diff = targetPos - root.Position
        local dist = diff.Magnitude
        if dist < 2.5 then
            stopFly()
            if onArrived then onArrived() end
            return
        end
        local dir = diff.Unit
        local s = math.clamp(dist * 0.6, 20, speed or CFG.FLY_SPEED)
        bodyVel.Velocity = dir * s
        bodyGyro.CFrame  = CFrame.new(root.Position, root.Position + dir)
    end)
end

-- // ─────────────────────────────────────────────
-- // HOVER ENGINE
-- // ─────────────────────────────────────────────
local hoverConn = nil
local hoverBV   = nil
local hoverBG   = nil
local isHovering = false

local function startHover(pos)
    isHovering = true
    stopFly()
    local Root = getRoot()
    getHuman().PlatformStand = true

    hoverBV = Instance.new("BodyVelocity", Root)
    hoverBV.MaxForce = Vector3.new(1e7, 1e7, 1e7)
    hoverBV.Velocity = Vector3.new(0,0,0)

    hoverBG = Instance.new("BodyGyro", Root)
    hoverBG.MaxTorque = Vector3.new(1e7, 1e7, 1e7)
    hoverBG.CFrame = Root.CFrame

    hoverConn = RunService.Heartbeat:Connect(function()
        if not isHovering then return end
        local ok, root = pcall(getRoot)
        if not ok then return end
        local diff = pos - root.Position
        local d    = diff.Magnitude
        if d > 1 then
            hoverBV.Velocity = diff.Unit * math.clamp(d * 2, 5, 80)
        else
            hoverBV.Velocity = Vector3.new(0,0,0)
        end
    end)
end

local function stopHover()
    isHovering = false
    if hoverConn then hoverConn:Disconnect() hoverConn = nil end
    pcall(function() if hoverBV then hoverBV:Destroy() hoverBV = nil end end)
    pcall(function() if hoverBG then hoverBG:Destroy() hoverBG = nil end end)
    pcall(function() getHuman().PlatformStand = false end)
end

-- // ─────────────────────────────────────────────
-- // MONSTER RIDE
-- // ─────────────────────────────────────────────
local rideWeld = nil
local function rideNearestMonster()
    local Root = getRoot()
    local best, bd = nil, math.huge
    local rideKeywords = {"mount","monster","creature","ride","animal","pet","dragon","beast","boss","mob"}
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj ~= Root then
            local nm = obj.Name:lower()
            for _,kw in ipairs(rideKeywords) do
                if nm:find(kw) then
                    local d = (Root.Position - obj.Position).Magnitude
                    if d < bd and d < 120 then
                        bd = d
                        best = obj
                    end
                    break
                end
            end
        end
    end
    if best then
        Root.CFrame = CFrame.new(best.Position + Vector3.new(0, best.Size.Y/2 + 3, 0))
        task.wait(0.05)
        if rideWeld then pcall(function() rideWeld:Destroy() end) rideWeld = nil end
        rideWeld = Instance.new("WeldConstraint")
        rideWeld.Part0 = Root
        rideWeld.Part1 = best
        rideWeld.Parent = Root
        getHuman().PlatformStand = true
        task.delay(6, function()
            pcall(function()
                if rideWeld then rideWeld:Destroy() rideWeld = nil end
                getHuman().PlatformStand = false
            end)
        end)
        return true
    end
    return false
end

-- // ─────────────────────────────────────────────
-- // STEAL ENGINE (FIXED for Models)
-- // ─────────────────────────────────────────────
local function stealEgg(egg, onDone)
    if not egg or not egg.Parent then
        if onDone then onDone(false) end return
    end

    local eggPos
    if egg:IsA("BasePart") then
        eggPos = egg.Position
    elseif egg:IsA("Model") then
        local ok, cf = pcall(function() return egg:GetPivot() end)
        if ok and cf then eggPos = cf.Position
        else
            local pp = egg:FindFirstChildWhichIsA("BasePart", true)
            if pp then eggPos = pp.Position end
        end
    elseif egg:IsA("ProximityPrompt") then
        eggPos = egg.Parent and egg.Parent:IsA("BasePart") and egg.Parent.Position or nil
    end

    if not eggPos then
        if onDone then onDone(false) end return
    end

    enableGodMode()

    local highPos = eggPos + Vector3.new(0, CFG.FLY_HEIGHT, 0)

    flyTo(highPos, CFG.FLY_SPEED, function()
        startHover(highPos)

        local ok2, root = pcall(getRoot)
        if not ok2 then
            stopHover(); disableGodMode()
            if onDone then onDone(false) end return
        end

        local targets = {egg}
        if egg.Parent then table.insert(targets, egg.Parent) end

        for _,t in ipairs(targets) do
            local touch = t:FindFirstChildOfClass("TouchTransmitter")
            if touch then
                pcall(firetouchinterest, root, t, 0)
                task.wait(0.06)
                pcall(firetouchinterest, root, t, 1)
            end
            local click = t:FindFirstChildOfClass("ClickDetector")
            if click then pcall(fireclickdetector, click) end
            local prompt = t:FindFirstChildOfClass("ProximityPrompt")
            if prompt then pcall(fireproximityprompt, prompt) end
        end

        for _,v in ipairs(egg:GetDescendants()) do
            if v:IsA("ProximityPrompt") then pcall(fireproximityprompt, v) end
            if v:IsA("ClickDetector")   then pcall(fireclickdetector, v) end
            if v:IsA("TouchTransmitter") then
                pcall(firetouchinterest, root, v.Parent, 0)
                task.wait(0.05)
                pcall(firetouchinterest, root, v.Parent, 1)
            end
        end

        task.wait(0.35)
        stopHover()
        disableGodMode()

        local rode = rideNearestMonster()
        if not rode then
            local hum = getHuman()
            local prev = hum.WalkSpeed
            hum.WalkSpeed = CFG.WALK_SPEED
            task.delay(3, function() pcall(function() hum.WalkSpeed = prev end) end)
        end

        if onDone then onDone(true) end
    end)
end

-- // ─────────────────────────────────────────────
-- // HOLD LONGEST
-- // ─────────────────────────────────────────────
local holdActive = false
local holdConn   = nil
local holdBV     = nil
local holdBG     = nil

local function startHoldLongest(statusFn, dotFn)
    if holdActive then return end
    holdActive = true
    enableGodMode()

    local Root   = getRoot()
    local skyPos = Root.Position + Vector3.new(0, CFG.HOLD_HEIGHT, 0)

    getHuman().PlatformStand = true

    holdBV = Instance.new("BodyVelocity", Root)
    holdBV.MaxForce = Vector3.new(1e7,1e7,1e7)
    holdBV.Velocity = Vector3.new(0, CFG.FLY_SPEED, 0)

    holdBG = Instance.new("BodyGyro", Root)
    holdBG.MaxTorque = Vector3.new(1e7,1e7,1e7)
    holdBG.CFrame    = Root.CFrame

    local reached = false
    holdConn = RunService.Heartbeat:Connect(function()
        if not holdActive then return end
        local ok, root = pcall(getRoot)
        if not ok then return end

        if not reached and root.Position.Y >= (skyPos.Y - 10) then
            reached = true
            holdBV.Velocity = Vector3.new(0,0,0)
        end

        if reached then
            local diff = skyPos - root.Position
            holdBV.Velocity = diff.Magnitude > 2 and diff.Unit * 50 or Vector3.new(0,0,0)

            for _,obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    local nm = obj.Name:lower()
                    if nm:find("hold") or nm:find("zone") or nm:find("claim") or nm:find("admin") then
                        local t = obj:FindFirstChildOfClass("TouchTransmitter")
                        if t then pcall(firetouchinterest, root, obj, 0) end
                        local c = obj:FindFirstChildOfClass("ClickDetector")
                        if c then pcall(fireclickdetector, c) end
                        local p = obj:FindFirstChildOfClass("ProximityPrompt")
                        if p then pcall(fireproximityprompt, p) end
                    end
                end
            end
        end
    end)

    if statusFn then statusFn("🌌 HOLD LONGEST — Flying up!") end
    if dotFn   then dotFn(Color3.fromRGB(255,215,0)) end
end

local function stopHoldLongest(statusFn, dotFn)
    holdActive = false
    if holdConn then holdConn:Disconnect() holdConn = nil end
    pcall(function() if holdBV then holdBV:Destroy() holdBV = nil end end)
    pcall(function() if holdBG then holdBG:Destroy() holdBG = nil end end)
    disableGodMode()
    pcall(function() getHuman().PlatformStand = false end)
    if statusFn then statusFn("⬛ Hold Longest — Stopped") end
    if dotFn   then dotFn(Color3.fromRGB(100,100,140)) end
end

-- // ─────────────────────────────────────────────
-- // STATE
-- // ─────────────────────────────────────────────
local State = {
    autoSteal     = false,
    stealing      = false,
    stealOnceFlag = false,
    selectedRar   = {Divine=true, Eternal=true, Secret=true, Cosmic=true, Legendary=true, Epic=true},
}

-- // ─────────────────────────────────────────────
-- // UI SETUP
-- // ─────────────────────────────────────────────
pcall(function()
    local old = CoreGui:FindFirstChild("BulacatHubV4")
    if old then old:Destroy() end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name            = "BulacatHubV4"
ScreenGui.ResetOnSpawn    = false
ScreenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder    = 999
ScreenGui.Parent          = CoreGui

local C = {
    bg       = Color3.fromRGB(5,7,18),
    panel    = Color3.fromRGB(10,13,30),
    card     = Color3.fromRGB(14,18,40),
    cardHi   = Color3.fromRGB(18,24,52),
    accent   = Color3.fromRGB(40,130,255),
    accentHi = Color3.fromRGB(100,180,255),
    text     = Color3.fromRGB(225,235,255),
    subtext  = Color3.fromRGB(110,130,180),
    green    = Color3.fromRGB(50,230,120),
    red      = Color3.fromRGB(255,65,65),
    gold     = Color3.fromRGB(255,205,50),
    purple   = Color3.fromRGB(170,80,255),
    cyan     = Color3.fromRGB(50,220,255),
}

local function mk(class, props, parent)
    local i = Instance.new(class)
    for k,v in pairs(props) do i[k] = v end
    if parent then i.Parent = parent end
    return i
end
local function corner(r, p)  return mk("UICorner",{CornerRadius=UDim.new(0,r)},p) end
local function stroke(c,t,p) return mk("UIStroke",{Color=c,Thickness=t},p) end
local function pad(l,r,t,b,p)
    local u = Instance.new("UIPadding")
    u.PaddingLeft=UDim.new(0,l) u.PaddingRight=UDim.new(0,r)
    u.PaddingTop=UDim.new(0,t) u.PaddingBottom=UDim.new(0,b)
    u.Parent = p; return u
end

-- // ─────────────────────────────────────────────
-- // PARTICLE LOGO
-- // ─────────────────────────────────────────────
local LogoOuter = mk("Frame",{
    Size=UDim2.new(0,80,0,80),
    Position=UDim2.new(0,14,0.5,-40),
    BackgroundColor3=Color3.fromRGB(5,7,18),
    BorderSizePixel=0,
    ZIndex=20,
},ScreenGui)
corner(999, LogoOuter)
stroke(C.accentHi, 2.5, LogoOuter)

local GlowRing = mk("Frame",{
    Size=UDim2.new(1,18,1,18),
    Position=UDim2.new(0,-9,0,-9),
    BackgroundTransparency=1,
    BorderSizePixel=0,
    ZIndex=19,
},LogoOuter)
corner(999, GlowRing)
local gs = stroke(C.accent, 8, GlowRing)
gs.Transparency = 0.6
TweenService:Create(gs, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Transparency=0.9}):Play()
TweenService:Create(gs, TweenInfo.new(2.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Color=C.cyan}):Play()

local ParticleFrame = mk("Frame",{
    Size=UDim2.new(1,0,1,0),
    BackgroundTransparency=1,
    ZIndex=21,
},LogoOuter)

local PARTICLE_COLORS = {C.accentHi, C.cyan, C.purple, C.gold, C.green}
local particles = {}
for i = 1, CFG.PARTICLE_COUNT do
    local psize = math.random(3,7)
    local p = mk("Frame",{
        Size=UDim2.new(0,psize,0,psize),
        BackgroundColor3=PARTICLE_COLORS[((i-1)%#PARTICLE_COLORS)+1],
        BorderSizePixel=0,
        ZIndex=22,
    },ParticleFrame)
    corner(999,p)
    particles[i] = {
        frame=p,
        angle=math.rad((360/CFG.PARTICLE_COUNT)*i),
        speed=0.6 + math.random()*0.8,
        radius=28 + math.random()*14,
        yOff=math.sin(i*0.7)*6,
    }
end

mk("TextLabel",{
    Size=UDim2.new(1,0,0,44),
    Position=UDim2.new(0,0,0,8),
    BackgroundTransparency=1,
    Text="🐱",
    TextSize=32,
    Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Center,
    ZIndex=23,
},LogoOuter)

mk("TextLabel",{
    Size=UDim2.new(1,0,0,14),
    Position=UDim2.new(0,0,1,-16),
    BackgroundTransparency=1,
    Text="BH v4.1",
    TextSize=9,
    Font=Enum.Font.GothamBold,
    TextColor3=C.accentHi,
    TextXAlignment=Enum.TextXAlignment.Center,
    ZIndex=23,
},LogoOuter)

local t0 = tick()
RunService.Heartbeat:Connect(function()
    local elapsed = tick() - t0
    local cx = LogoOuter.AbsoluteSize.X / 2
    local cy = LogoOuter.AbsoluteSize.Y / 2
    for _,pt in ipairs(particles) do
        local ang = pt.angle + elapsed * pt.speed
        local px = cx + math.cos(ang) * pt.radius - pt.frame.AbsoluteSize.X/2
        local py = cy + math.sin(ang) * pt.radius + math.sin(elapsed*1.2)*pt.yOff - pt.frame.AbsoluteSize.Y/2
        pt.frame.Position = UDim2.new(0, px, 0, py)
    end
end)

do
    local dragging, dragStart, startPos2
    local logoBtn = mk("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=30},LogoOuter)
    logoBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = inp.Position
            startPos2 = LogoOuter.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local d = inp.Position - dragStart
            LogoOuter.Position = UDim2.new(startPos2.X.Scale, startPos2.X.Offset+d.X, startPos2.Y.Scale, startPos2.Y.Offset+d.Y)
        end
    end)
end

-- // ─────────────────────────────────────────────
-- // MAIN PANEL
-- // ─────────────────────────────────────────────
local Main = mk("Frame",{
    Size=UDim2.new(0,450,0,640),
    Position=UDim2.new(0,108,0.5,-320),
    BackgroundColor3=C.bg,
    BorderSizePixel=0,
    Visible=false,
    ClipsDescendants=true,
    ZIndex=10,
},ScreenGui)
corner(18,Main)
stroke(C.accent,1.5,Main)

TweenService:Create(
    Main:FindFirstChildOfClass("UIStroke"),
    TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    {Color=C.cyan}
):Play()

local Header = mk("Frame",{
    Size=UDim2.new(1,0,0,56),
    BackgroundColor3=C.panel,
    BorderSizePixel=0,
    ZIndex=11,
},Main)
corner(18,Header)
mk("Frame",{Size=UDim2.new(1,0,0,18),Position=UDim2.new(0,0,1,-18),BackgroundColor3=C.panel,BorderSizePixel=0,ZIndex=11},Header)

mk("TextLabel",{Size=UDim2.new(0,38,0,38),Position=UDim2.new(0,12,0.5,-19),BackgroundTransparency=1,Text="🐱",TextSize=28,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=12},Header)
mk("TextLabel",{Size=UDim2.new(0,220,0,26),Position=UDim2.new(0,54,0,8),BackgroundTransparency=1,Text="BULACAT HUB",TextColor3=C.accentHi,TextSize=18,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=12},Header)
mk("TextLabel",{Size=UDim2.new(0,220,0,16),Position=UDim2.new(0,54,0,32),BackgroundTransparency=1,Text="Egg Stealer v4.1 — All Map",TextColor3=C.subtext,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=12},Header)

local VerBadge = mk("Frame",{Size=UDim2.new(0,44,0,20),Position=UDim2.new(1,-92,0.5,-10),BackgroundColor3=C.accent,BorderSizePixel=0,ZIndex=12},Header)
corner(6,VerBadge)
mk("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="v4.1",TextColor3=Color3.new(1,1,1),TextSize=10,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=13},VerBadge)

local CloseBtn = mk("TextButton",{Size=UDim2.new(0,26,0,26),Position=UDim2.new(1,-38,0.5,-13),BackgroundColor3=C.red,Text="✕",TextColor3=Color3.new(1,1,1),TextSize=13,Font=Enum.Font.GothamBold,BorderSizePixel=0,ZIndex=13},Header)
corner(999,CloseBtn)

local Body = mk("Frame",{Size=UDim2.new(1,-16,1,-64),Position=UDim2.new(0,8,0,62),BackgroundTransparency=1,ZIndex=11},Main)
mk("UIListLayout",{Padding=UDim.new(0,7),SortOrder=Enum.SortOrder.LayoutOrder},Body)

local StatusCard = mk("Frame",{Size=UDim2.new(1,0,0,36),BackgroundColor3=C.card,BorderSizePixel=0,LayoutOrder=1,ZIndex=11},Body)
corner(10,StatusCard)
local StatusDot = mk("Frame",{Size=UDim2.new(0,10,0,10),Position=UDim2.new(0,12,0.5,-5),BackgroundColor3=C.subtext,BorderSizePixel=0,ZIndex=12},StatusCard)
corner(999,StatusDot)
local StatusTxt = mk("TextLabel",{Size=UDim2.new(1,-32,1,0),Position=UDim2.new(0,28,0,0),BackgroundTransparency=1,Text="Idle — BULACAT HUB v4.1 ready",TextColor3=C.text,TextSize=12,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=12},StatusCard)

local function setStatus(txt, dotColor)
    StatusTxt.Text = txt
    StatusDot.BackgroundColor3 = dotColor or C.subtext
end

-- // HOLD LONGEST
local HoldCard = mk("Frame",{Size=UDim2.new(1,0,0,64),BackgroundColor3=C.card,BorderSizePixel=0,LayoutOrder=2,ZIndex=11},Body)
corner(10,HoldCard)
pad(10,10,8,8,HoldCard)
mk("TextLabel",{Size=UDim2.new(1,0,0,14),BackgroundTransparency=1,Text="ADMIN ABUSE",TextColor3=C.subtext,TextSize=10,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=12},HoldCard)
local HoldBtn = mk("TextButton",{Size=UDim2.new(1,0,0,36),Position=UDim2.new(0,0,0,18),BackgroundColor3=C.purple,Text="👑  HOLD LONGEST  —  START",TextColor3=Color3.new(1,1,1),TextSize=13,Font=Enum.Font.GothamBold,BorderSizePixel=0,ZIndex=12},HoldCard)
corner(10,HoldBtn)
stroke(Color3.fromRGB(200,120,255),1.2,HoldBtn)

local holdOn = false
HoldBtn.MouseButton1Click:Connect(function()
    holdOn = not holdOn
    if holdOn then
        HoldBtn.Text = "👑  HOLD LONGEST  —  STOP"
        HoldBtn.BackgroundColor3 = C.red
        startHoldLongest(function(t) setStatus(t,C.gold) end, function(c) StatusDot.BackgroundColor3=c end)
    else
        HoldBtn.Text = "👑  HOLD LONGEST  —  START"
        HoldBtn.BackgroundColor3 = C.purple
        stopHoldLongest(function(t) setStatus(t,C.subtext) end, function(c) StatusDot.BackgroundColor3=c end)
    end
end)

-- // RARITY FILTER
local FilterCard = mk("Frame",{Size=UDim2.new(1,0,0,80),BackgroundColor3=C.card,BorderSizePixel=0,LayoutOrder=3,ZIndex=11},Body)
corner(10,FilterCard)
pad(10,10,6,6,FilterCard)
mk("TextLabel",{Size=UDim2.new(1,0,0,16),BackgroundTransparency=1,Text="FILTER BY RARITY",TextColor3=C.subtext,TextSize=10,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=12},FilterCard)

local FR1 = mk("Frame",{Size=UDim2.new(1,0,0,28),Position=UDim2.new(0,0,0,20),BackgroundTransparency=1,ZIndex=12},FilterCard)
mk("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,5),VerticalAlignment=Enum.VerticalAlignment.Center},FR1)
local FR2 = mk("Frame",{Size=UDim2.new(1,0,0,28),Position=UDim2.new(0,0,0,50),BackgroundTransparency=1,ZIndex=12},FilterCard)
mk("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,5),VerticalAlignment=Enum.VerticalAlignment.Center},FR2)

local FILTER_DATA = {
    {name="Divine",  emoji="🟨",row=FR1},
    {name="Eternal", emoji="🌌",row=FR1},
    {name="Secret",  emoji="⬛",row=FR1},
    {name="Cosmic",  emoji="🟪",row=FR2},
    {name="Legendary",emoji="🔶",row=FR2},
    {name="Epic",    emoji="🔷",row=FR2},
}
for _,fd in ipairs(FILTER_DATA) do
    local rd = getRD(fd.name)
    local fb = mk("TextButton",{Size=UDim2.new(0,95,0,26),BackgroundColor3=rd.color,Text=fd.emoji.." "..fd.name,TextColor3=Color3.new(1,1,1),TextSize=10,Font=Enum.Font.GothamBold,BorderSizePixel=0,ZIndex=13},fd.row)
    corner(7,fb)
    fb.MouseButton1Click:Connect(function()
        State.selectedRar[fd.name] = not State.selectedRar[fd.name]
        fb.BackgroundTransparency = State.selectedRar[fd.name] and 0 or 0.65
        fb.TextTransparency       = State.selectedRar[fd.name] and 0 or 0.4
    end)
end

-- // TOGGLE HELPER
local function makeToggle(parent,xOff,label,accentColor)
    local frame = mk("Frame",{Size=UDim2.new(0,205,0,50),Position=UDim2.new(0,xOff,0,0),BackgroundTransparency=1,ZIndex=12},parent)
    local track = mk("Frame",{Size=UDim2.new(0,48,0,24),Position=UDim2.new(0,10,0.5,-12),BackgroundColor3=Color3.fromRGB(25,30,58),BorderSizePixel=0,ZIndex=13},frame)
    corner(999,track) stroke(accentColor,1,track)
    local thumb = mk("Frame",{Size=UDim2.new(0,19,0,19),Position=UDim2.new(0,3,0.5,-9.5),BackgroundColor3=C.subtext,BorderSizePixel=0,ZIndex=14},track)
    corner(999,thumb)
    mk("TextLabel",{Size=UDim2.new(0,140,0,20),Position=UDim2.new(0,60,0.5,-10),BackgroundTransparency=1,Text=label,TextColor3=C.text,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=13},frame)
    local togBtn = mk("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=15},frame)
    local on = false
    local function setOn(v)
        on = v
        local goal = v and UDim2.new(0,26,0.5,-9.5) or UDim2.new(0,3,0.5,-9.5)
        TweenService:Create(thumb,TweenInfo.new(0.15),{Position=goal,BackgroundColor3=v and accentColor or C.subtext}):Play()
        TweenService:Create(track,TweenInfo.new(0.15),{BackgroundColor3=v and Color3.fromRGB(18,38,80) or Color3.fromRGB(25,30,58)}):Play()
    end
    togBtn.MouseButton1Click:Connect(function() setOn(not on) end)
    return togBtn, function() return on end, setOn
end

-- // CONTROLS (declare refs FIRST so loop captures valid functions)
local CtrlCard = mk("Frame",{Size=UDim2.new(1,0,0,50),BackgroundColor3=C.card,BorderSizePixel=0,LayoutOrder=4,ZIndex=11},Body)
corner(10,CtrlCard)

local getAutoOn, setAutoOn
local getOnceOn, setOnceOn
do
    local _,g1,s1 = makeToggle(CtrlCard,0,"Auto Steal",C.accentHi)
    getAutoOn, setAutoOn = g1, s1
    local _,g2,s2 = makeToggle(CtrlCard,215,"Steal Once",C.gold)
    getOnceOn, setOnceOn = g2, s2
end

-- // EGG LIST
local ListCard = mk("Frame",{Size=UDim2.new(1,0,0,310),BackgroundColor3=C.card,BorderSizePixel=0,LayoutOrder=5,ZIndex=11},Body)
corner(10,ListCard)

local ListHeader = mk("Frame",{Size=UDim2.new(1,0,0,26),BackgroundColor3=C.cardHi,BorderSizePixel=0,ZIndex=12},ListCard)
corner(10,ListHeader)
mk("Frame",{Size=UDim2.new(1,0,0,10),Position=UDim2.new(0,0,1,-10),BackgroundColor3=C.cardHi,BorderSizePixel=0,ZIndex=12},ListHeader)
mk("TextLabel",{Size=UDim2.new(0.5,0,1,0),Position=UDim2.new(0,8,0,0),BackgroundTransparency=1,Text="🌍 ALL MAP EGGS",TextColor3=C.subtext,TextSize=10,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=13},ListHeader)

local EggCountLbl = mk("TextLabel",{Size=UDim2.new(0.5,0,1,0),Position=UDim2.new(0.5,0,0,0),BackgroundTransparency=1,Text="",TextColor3=C.accentHi,TextSize=10,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Right,ZIndex=13},ListHeader)
pad(0,8,0,0,EggCountLbl)

local Scroll = mk("ScrollingFrame",{
    Size=UDim2.new(1,-8,1,-30),
    Position=UDim2.new(0,4,0,28),
    BackgroundTransparency=1,
    BorderSizePixel=0,
    ScrollBarThickness=3,
    ScrollBarImageColor3=C.accent,
    CanvasSize=UDim2.new(0,0,0,0),
    AutomaticCanvasSize=Enum.AutomaticSize.Y,
    ZIndex=12,
},ListCard)
mk("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder},Scroll)
pad(2,2,2,4,Scroll)

-- // EGG ROW BUILDER
local function buildRow(data, idx)
    local rd  = getRD(data.rarity)
    local row = mk("TextButton",{Size=UDim2.new(1,-4,0,54),BackgroundColor3=Color3.fromRGB(12,16,36),BorderSizePixel=0,Text="",LayoutOrder=idx,ZIndex=13},Scroll)
    corner(9,row)

    row.MouseEnter:Connect(function()
        TweenService:Create(row,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(18,24,52)}):Play()
    end)
    row.MouseLeave:Connect(function()
        TweenService:Create(row,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(12,16,36)}):Play()
    end)

    local stripe = mk("Frame",{Size=UDim2.new(0,4,1,-8),Position=UDim2.new(0,4,0,4),BackgroundColor3=rd.color,BorderSizePixel=0,ZIndex=14},row)
    corner(4,stripe)

    mk("TextLabel",{Size=UDim2.new(0,28,0,28),Position=UDim2.new(0,12,0.5,-14),BackgroundTransparency=1,Text=rd.emoji,TextSize=18,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=14},row)

    mk("TextLabel",{Size=UDim2.new(1,-138,0,20),Position=UDim2.new(0,44,0,8),BackgroundTransparency=1,Text=data.pet,TextColor3=C.text,TextSize=13,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=14},row)

    mk("TextLabel",{Size=UDim2.new(1,-138,0,14),Position=UDim2.new(0,44,0,30),BackgroundTransparency=1,Text=data.rarity.."  ·  "..data.dist.." studs",TextColor3=rd.color,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=14},row)

    local stBtn = mk("TextButton",{Size=UDim2.new(0,62,0,30),Position=UDim2.new(1,-68,0.5,-15),BackgroundColor3=C.accent,Text="STEAL",TextColor3=Color3.new(1,1,1),TextSize=11,Font=Enum.Font.GothamBold,BorderSizePixel=0,ZIndex=15},row)
    corner(8,stBtn)
    stBtn.MouseEnter:Connect(function() TweenService:Create(stBtn,TweenInfo.new(0.1),{BackgroundColor3=C.accentHi}):Play() end)
    stBtn.MouseLeave:Connect(function() TweenService:Create(stBtn,TweenInfo.new(0.1),{BackgroundColor3=C.accent}):Play() end)

    stBtn.MouseButton1Click:Connect(function()
        if State.stealing then return end
        State.stealing = true
        setStatus("🚀 Flying to: "..data.pet, C.accentHi)
        stealEgg(data.egg, function(ok)
            State.stealing = false
            setStatus(ok and "✅ Stolen: "..data.pet or "❌ Failed", ok and C.green or C.red)
        end)
    end)
end

-- // LIST REFRESH
local function refreshList()
    for _,c in ipairs(Scroll:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
        if c:IsA("TextLabel") then c:Destroy() end
    end
    local eggs = scanEggs()
    local added = 0
    for i,data in ipairs(eggs) do
        if State.selectedRar[data.rarity] then
            buildRow(data, i)
            added = added + 1
        end
    end
    EggCountLbl.Text = added.." found"
    if added == 0 then
        mk("TextLabel",{Size=UDim2.new(1,0,0,40),BackgroundTransparency=1,Text="No eggs matching filter found",TextColor3=C.subtext,TextSize=12,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=13},Scroll)
    end
end

-- // AUTO STEAL LOOP v2 (FIXED)
local stealOnceArmed = false
task.spawn(function()
    while true do
        task.wait(CFG.STEAL_DELAY)

        local autoOn = getAutoOn and getAutoOn() or false
        local onceOn = getOnceOn and getOnceOn() or false

        if autoOn and not State.stealing then
            if onceOn and stealOnceArmed then
                stealOnceArmed = false
                setAutoOn(false)
                setStatus("✅ Steal Once complete", C.green)
            elseif onceOn and not stealOnceArmed then
                stealOnceArmed = true
            end

            local ok, eggs = pcall(scanEggs)
            if ok and eggs and #eggs > 0 then
                local target = nil
                for _,data in ipairs(eggs) do
                    if State.selectedRar[data.rarity] and data.egg and data.egg.Parent then
                        target = data
                        break
                    end
                end

                if target then
                    State.stealing = true
                    setStatus("🚀 Auto → "..target.pet.." ["..target.rarity.."]", C.accentHi)

                    task.spawn(function()
                        stealEgg(target.egg, function(success)
                            State.stealing = false
                            setStatus(success and ("✅ Got: "..target.pet) or ("❌ Missed: "..target.pet),
                                      success and C.green or C.red)
                        end)
                    end)
                else
                    setStatus("🔍 No eggs matching filter", C.subtext)
                end
            end
        end

        if not autoOn then
            stealOnceArmed = false
        end
    end
end)

-- // SCAN LOOP (refresh list)
task.spawn(function()
    while true do
        task.wait(CFG.SCAN_INTERVAL)
        if Main.Visible then
            pcall(refreshList)
        end
    end
end)

-- // LOGO toggle main panel
do
    local LogoBtn = mk("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=30},LogoOuter)
    local downAt
    LogoBtn.MouseButton1Down:Connect(function() downAt = UserInputService:GetMouseLocation() end)
    LogoBtn.MouseButton1Up:Connect(function()
        local cur = UserInputService:GetMouseLocation()
        if downAt and (cur-downAt).Magnitude < 8 then
            Main.Visible = not Main.Visible
            if Main.Visible then pcall(refreshList) end
        end
    end)
end

CloseBtn.MouseButton1Click:Connect(function() Main.Visible = false end)

-- // MAIN PANEL DRAG
do
    local dragging, dragInput2, dragStart2, startPos2
    Header.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart2 = inp.Position
            startPos2  = Main.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    Header.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement then dragInput2 = inp end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if inp == dragInput2 and dragging then
            local d = inp.Position - dragStart2
            Main.Position = UDim2.new(startPos2.X.Scale, startPos2.X.Offset+d.X, startPos2.Y.Scale, startPos2.Y.Offset+d.Y)
        end
    end)
end

-- // RESPAWN CLEANUP
LocalPlayer.CharacterAdded:Connect(function()
    State.stealing = false
    pcall(stopFly)
    pcall(stopHover)
    if holdActive then pcall(stopHoldLongest) end
    if rideWeld then pcall(function() rideWeld:Destroy() rideWeld = nil end) end
    setStatus("🔄 Respawned — ready", C.subtext)
end)

print("🐱 BULACAT HUB v4.1 (FIXED) — Click the particle logo!")