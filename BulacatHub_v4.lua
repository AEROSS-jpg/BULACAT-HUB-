-- // ============================================
-- // 🐱 BULACAT HUB v4 — Lennon Style, Blue Theme
-- // Executor: KRNL / Synapse X / Fluxus
-- // UPGRADES: Unkillable God Mode during steal
-- //           Hold Longest has own dedicated card
-- //           Auto Steal inside Hold Longest mode
-- //           Fly-up untouchable during auto steal
-- // ============================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer      = Players.LocalPlayer

local function getChar()  return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait() end
local function getRoot()  return getChar():WaitForChild("HumanoidRootPart") end
local function getHuman() return getChar():WaitForChild("Humanoid") end

-- // ─────────────────────────────────────────────
-- // CONFIG
-- // ─────────────────────────────────────────────
local CFG = {
    EGG_KEYWORDS      = {"Egg","egg"},
    STEAL_DELAY       = 0.3,
    SCAN_INTERVAL     = 0.8,
    FLY_HEIGHT        = 100,   -- studs HIGH during steal (deep untouchable zone)
    FLY_SPEED         = 180,
    WALK_SPEED        = 80,
    HOLD_HEIGHT       = 320,   -- sky height for Hold Longest
    HOLD_AUTO_DELAY   = 0.35,  -- how often to attempt steal while in hold mode
    GOD_RESTORE_DELAY = 0.5,   -- how long after steal to keep god on before restore
}

-- // ─────────────────────────────────────────────
-- // RARITY
-- // ─────────────────────────────────────────────
local RARITY = {
    {name="Divine",  emoji="🟨",color=Color3.fromRGB(255,215,0),  rank=1},
    {name="Eternal", emoji="🌌",color=Color3.fromRGB(180,0,255),  rank=2},
    {name="Secret",  emoji="⬛",color=Color3.fromRGB(50,50,50),   rank=3},
    {name="Cosmic",  emoji="🟪",color=Color3.fromRGB(160,0,255),  rank=4},
    {name="Rare",    emoji="🔵",color=Color3.fromRGB(0,120,255),  rank=5},
    {name="Uncommon",emoji="🟢",color=Color3.fromRGB(0,200,80),   rank=6},
    {name="Common",  emoji="⚪",color=Color3.fromRGB(180,180,180),rank=7},
}
local RARITY_MAP = {}
for _,r in ipairs(RARITY) do RARITY_MAP[r.name]=r end
local function getRD(n) return RARITY_MAP[n] or RARITY_MAP["Common"] end

local function predictRarity(egg)
    local checks = {"divine","eternal","secret","cosmic","rare","uncommon"}
    local mapped  = {"Divine","Eternal","Secret","Cosmic","Rare","Uncommon"}
    local nm = egg.Name:lower()
    for i,kw in ipairs(checks) do if nm:find(kw) then return mapped[i] end end
    for _,v in ipairs(egg:GetDescendants()) do
        local t=""
        if v:IsA("StringValue") then t=(v.Value or ""):lower()
        elseif v:IsA("TextLabel") then t=(v.Text or ""):lower() end
        for i,kw in ipairs(checks) do if t:find(kw) then return mapped[i] end end
    end
    return "Common"
end

local function predictPet(egg)
    for _,v in ipairs(egg:GetDescendants()) do
        if v:IsA("StringValue") then
            for _,k in ipairs({"pet","reward","hatch","item"}) do
                if v.Name:lower():find(k) and v.Value~="" then return v.Value end
            end
        end
        if v:IsA("TextLabel") and v.Text~="" and #v.Text<40 then return v.Text end
    end
    return "Mystery Pet 🐾"
end

-- // ─────────────────────────────────────────────
-- // SCAN EGGS
-- // ─────────────────────────────────────────────
local function scanEggs()
    local Root=getRoot()
    local found,seen={},{}
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not seen[obj] then
            for _,kw in ipairs(CFG.EGG_KEYWORDS) do
                if obj.Name:lower():find(kw:lower()) then
                    seen[obj]=true
                    local rar=predictRarity(obj)
                    local pet=predictPet(obj)
                    local dist=math.floor((Root.Position-obj.Position).Magnitude)
                    table.insert(found,{egg=obj,rarity=rar,pet=pet,dist=dist})
                    break
                end
            end
        end
    end
    table.sort(found,function(a,b)
        local ra=getRD(a.rarity).rank
        local rb=getRD(b.rarity).rank
        if ra~=rb then return ra<rb end
        return a.dist<b.dist
    end)
    return found
end

-- // ─────────────────────────────────────────────
-- // GOD MODE ENGINE (HARDCORE — truly unkillable)
-- // ─────────────────────────────────────────────
local godConn       = nil
local godLoopConn   = nil
local godActive     = false

local function enableGodMode()
    if godActive then return end
    godActive = true

    local function applyGod()
        pcall(function()
            local char  = getChar()
            local hum   = getHuman()

            -- nuke health cap
            hum.MaxHealth = math.huge
            hum.Health    = math.huge

            -- instant restore on any damage
            if godConn then godConn:Disconnect() end
            godConn = hum.HealthChanged:Connect(function(hp)
                if godActive and hp < hum.MaxHealth then
                    hum.Health = math.huge
                end
            end)

            -- kill states off
            hum:SetStateEnabled(Enum.HumanoidStateType.Dead,        false)
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown,  false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,      false)

            -- no collision — attacks pass through
            for _,p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.CanCollide = false
                end
            end
        end)
    end

    applyGod()

    -- heartbeat loop: re-apply every frame so no exploit can strip it
    if godLoopConn then godLoopConn:Disconnect() end
    godLoopConn = RunService.Heartbeat:Connect(function()
        if not godActive then return end
        pcall(function()
            local hum = getHuman()
            if hum.Health < hum.MaxHealth then
                hum.Health = math.huge
            end
            -- keep death state off every frame
            hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        end)
    end)
end

local function disableGodMode()
    godActive = false
    if godConn     then godConn:Disconnect()     godConn     = nil end
    if godLoopConn then godLoopConn:Disconnect() godLoopConn = nil end
    pcall(function()
        local hum = getHuman()
        hum.MaxHealth = 100
        hum.Health    = 100
        hum:SetStateEnabled(Enum.HumanoidStateType.Dead,        true)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown,  true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,      true)
        local char = getChar()
        for _,p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = true end
        end
    end)
end

-- // ─────────────────────────────────────────────
-- // FLY ENGINE
-- // ─────────────────────────────────────────────
local flying   = false
local flyConn  = nil
local bodyVel  = nil
local bodyGyro = nil

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
    bodyVel.MaxForce = Vector3.new(1e6,1e6,1e6)
    bodyVel.Velocity = Vector3.new(0,0,0)

    bodyGyro = Instance.new("BodyGyro", Root)
    bodyGyro.MaxTorque = Vector3.new(1e6,1e6,1e6)
    bodyGyro.P = 1e4

    flyConn = RunService.Heartbeat:Connect(function()
        if not flying then return end
        local root = getRoot()
        local diff = targetPos - root.Position
        local dist = diff.Magnitude
        if dist < 2.5 then
            stopFly()
            if onArrived then onArrived() end
            return
        end
        local dir = diff.Unit
        bodyVel.Velocity  = dir * (speed or CFG.FLY_SPEED)
        bodyGyro.CFrame   = CFrame.new(root.Position, root.Position + dir)
    end)
end

-- // ─────────────────────────────────────────────
-- // HOVER IN PLACE
-- // ─────────────────────────────────────────────
local hoverConn  = nil
local hoverBV    = nil
local hoverBG    = nil
local isHovering = false

local function startHover(pos)
    isHovering = true
    stopFly()
    local Root = getRoot()

    hoverBV = Instance.new("BodyVelocity", Root)
    hoverBV.MaxForce = Vector3.new(1e6,1e6,1e6)
    hoverBV.Velocity = Vector3.new(0,0,0)

    hoverBG = Instance.new("BodyGyro", Root)
    hoverBG.MaxTorque = Vector3.new(1e6,1e6,1e6)
    hoverBG.CFrame = Root.CFrame

    getHuman().PlatformStand = true

    hoverConn = RunService.Heartbeat:Connect(function()
        if not isHovering then return end
        local root = getRoot()
        local diff = pos - root.Position
        if diff.Magnitude > 1 then
            hoverBV.Velocity = diff.Unit * 60
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
-- // STEAL EGG — God Mode ON entire time, fly high, interact, stay locked
-- // ─────────────────────────────────────────────
local function stealEgg(egg, onDone)
    if not egg or not egg.Parent then
        if onDone then onDone(false) end return
    end

    -- GOD MODE FIRST — before any movement
    enableGodMode()

    local highPos = egg.Position + Vector3.new(0, CFG.FLY_HEIGHT, 0)

    flyTo(highPos, CFG.FLY_SPEED, function()
        -- hover locked at untouchable altitude
        startHover(highPos)

        -- fire all interaction methods
        local root  = getRoot()
        local touch = egg:FindFirstChildOfClass("TouchTransmitter")
        if touch then
            pcall(firetouchinterest, root, egg, 0)
            task.wait(0.08)
            pcall(firetouchinterest, root, egg, 1)
        end
        local click = egg:FindFirstChildOfClass("ClickDetector")
        if click then pcall(fireclickdetector, click) end
        local prompt = egg:FindFirstChildOfClass("ProximityPrompt")
            or (egg.Parent and egg.Parent:FindFirstChildOfClass("ProximityPrompt"))
        if prompt then pcall(fireproximityprompt, prompt) end

        -- keep god mode on while interaction settles
        task.wait(CFG.GOD_RESTORE_DELAY)
        stopHover()

        -- brief hover stay so server registers steal before we move
        task.wait(0.3)

        -- now disable god and land
        disableGodMode()

        -- speed boost or mount after landing
        local Root = getRoot()
        local best, bd = nil, math.huge
        for _,obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                for _,kw in ipairs({"mount","pet","monster","creature","ride","animal"}) do
                    if obj.Name:lower():find(kw) then
                        local d = (Root.Position - obj.Position).Magnitude
                        if d < bd and d < 60 then bd=d; best=obj end
                        break
                    end
                end
            end
        end
        if best then
            Root.CFrame = CFrame.new(best.Position + Vector3.new(0,4,0))
            local w = Instance.new("WeldConstraint")
            w.Part0 = Root; w.Part1 = best; w.Parent = Root
            task.delay(5, function() pcall(function() w:Destroy() end) end)
        else
            local h = getHuman()
            local prev = h.WalkSpeed; h.WalkSpeed = CFG.WALK_SPEED
            task.delay(3, function() pcall(function() h.WalkSpeed = prev end) end)
        end

        if onDone then onDone(true) end
    end)
end

-- // ─────────────────────────────────────────────
-- // HOLD LONGEST ENGINE
-- // ─────────────────────────────────────────────
local holdActive  = false
local holdConn    = nil
local holdBV      = nil
local holdBG      = nil

local holdAutoSteal       = false  -- toggle: auto steal while holding
local holdAutoStealConn   = nil
local holdStealing        = false

local function startHoldLongest(statusFn, dotFn)
    if holdActive then return end
    holdActive = true
    enableGodMode()

    local Root   = getRoot()
    local skyPos = Root.Position + Vector3.new(0, CFG.HOLD_HEIGHT, 0)

    getHuman().PlatformStand = true

    holdBV = Instance.new("BodyVelocity", Root)
    holdBV.MaxForce = Vector3.new(1e6,1e6,1e6)
    holdBV.Velocity = Vector3.new(0, CFG.FLY_SPEED, 0)

    holdBG = Instance.new("BodyGyro", Root)
    holdBG.MaxTorque = Vector3.new(1e6,1e6,1e6)
    holdBG.CFrame = Root.CFrame

    local reached = false
    holdConn = RunService.Heartbeat:Connect(function()
        if not holdActive then return end
        local root   = getRoot()
        local height = root.Position.Y

        if not reached and height >= (skyPos.Y - 10) then
            reached = true
            holdBV.Velocity = Vector3.new(0,0,0)
        end

        if reached then
            local diff = skyPos - root.Position
            if diff.Magnitude > 2 then
                holdBV.Velocity = diff.Unit * 50
            else
                holdBV.Velocity = Vector3.new(0,0,0)
            end

            -- spam all hold/zone/claim/admin triggers every frame
            for _,obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    local nm = obj.Name:lower()
                    if nm:find("hold") or nm:find("zone") or nm:find("claim") or nm:find("admin") then
                        local touch = obj:FindFirstChildOfClass("TouchTransmitter")
                        if touch then pcall(firetouchinterest, root, obj, 0) end
                        local click = obj:FindFirstChildOfClass("ClickDetector")
                        if click then pcall(fireclickdetector, click) end
                        local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
                        if prompt then pcall(fireproximityprompt, prompt) end
                    end
                end
            end
        end
    end)

    if statusFn then statusFn("🌌 HOLD LONGEST — Flying up! God mode ON") end
    if dotFn   then dotFn(Color3.fromRGB(255,215,0)) end
end

local function stopHoldLongest(statusFn, dotFn)
    holdActive = false
    holdStealing = false
    if holdConn then holdConn:Disconnect() holdConn = nil end
    if holdAutoStealConn then holdAutoStealConn:Disconnect() holdAutoStealConn = nil end
    pcall(function() if holdBV then holdBV:Destroy() holdBV = nil end end)
    pcall(function() if holdBG then holdBG:Destroy() holdBG = nil end end)
    disableGodMode()
    pcall(function() getHuman().PlatformStand = false end)
    if statusFn then statusFn("⬛ Hold Longest — Stopped") end
    if dotFn   then dotFn(Color3.fromRGB(100,100,140)) end
end

-- // ─────────────────────────────────────────────
-- // HOLD AUTO STEAL (steal while floating untouchable)
-- // steals egg, flies back up, keeps holding zone
-- // ─────────────────────────────────────────────
local function startHoldAutoSteal(statusFn, dotFn, selectedRar)
    if holdAutoStealConn then holdAutoStealConn:Disconnect() holdAutoStealConn = nil end

    holdAutoStealConn = task.spawn(function()
        while holdActive and holdAutoSteal do
            task.wait(CFG.HOLD_AUTO_DELAY)
            if holdStealing then continue end

            local eggs   = scanEggs()
            local target = nil
            for _,data in ipairs(eggs) do
                if selectedRar[data.rarity] then
                    target = data; break
                end
            end

            if target then
                holdStealing = true
                if statusFn then statusFn("🥚 [HOLD] Auto stealing: " .. target.pet .. " [" .. target.rarity .. "]") end

                -- god already on from hold mode, just fire interactions from sky
                local root = getRoot()
                local egg  = target.egg
                if egg and egg.Parent then
                    -- fly TO egg height untouchable zone
                    local stealPos = egg.Position + Vector3.new(0, CFG.FLY_HEIGHT, 0)

                    -- temporarily break out of hold hover, go to egg
                    stopHover()

                    flyTo(stealPos, CFG.FLY_SPEED, function()
                        startHover(stealPos)

                        local touch = egg:FindFirstChildOfClass("TouchTransmitter")
                        if touch then
                            pcall(firetouchinterest, root, egg, 0)
                            task.wait(0.08)
                            pcall(firetouchinterest, root, egg, 1)
                        end
                        local click = egg:FindFirstChildOfClass("ClickDetector")
                        if click then pcall(fireclickdetector, click) end
                        local prompt = egg:FindFirstChildOfClass("ProximityPrompt")
                            or (egg.Parent and egg.Parent:FindFirstChildOfClass("ProximityPrompt"))
                        if prompt then pcall(fireproximityprompt, prompt) end

                        task.wait(0.4)
                        stopHover()

                        -- fly back up to hold zone
                        if holdActive then
                            local Root   = getRoot()
                            local skyPos = Root.Position + Vector3.new(0, CFG.HOLD_HEIGHT - Root.Position.Y + Root.Position.Y, 0)
                            -- simpler: just shoot back up to hold height Y
                            local backUp = Vector3.new(Root.Position.X, Root.Position.Y + CFG.HOLD_HEIGHT, Root.Position.Z)
                            flyTo(backUp, CFG.FLY_SPEED, function()
                                startHover(backUp)
                                holdStealing = false
                                if statusFn then statusFn("✅ [HOLD] Got: " .. target.pet .. " — back in sky") end
                                if dotFn then dotFn(Color3.fromRGB(50,220,120)) end
                            end)
                        else
                            holdStealing = false
                        end
                    end)
                else
                    holdStealing = false
                end
            end
        end
    end)
end

-- // ─────────────────────────────────────────────
-- // STATE
-- // ─────────────────────────────────────────────
local State = {
    autoSteal   = false,
    stealOnce   = false,
    doneOnce    = false,
    stealing    = false,
    selectedRar = {Divine=true,Eternal=true,Secret=true,Cosmic=true},
}

-- // ─────────────────────────────────────────────
-- // UI
-- // ─────────────────────────────────────────────
local CoreGui = game:GetService("CoreGui")
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
    bg       = Color3.fromRGB(8,10,20),
    panel    = Color3.fromRGB(13,17,35),
    card     = Color3.fromRGB(18,23,48),
    accent   = Color3.fromRGB(30,120,255),
    accentHi = Color3.fromRGB(80,170,255),
    text     = Color3.fromRGB(220,230,255),
    subtext  = Color3.fromRGB(120,140,190),
    green    = Color3.fromRGB(50,220,120),
    red      = Color3.fromRGB(255,70,70),
    gold     = Color3.fromRGB(255,200,50),
    purple   = Color3.fromRGB(160,80,255),
    orange   = Color3.fromRGB(255,140,30),
}

local function mk(class,props,parent)
    local i = Instance.new(class)
    for k,v in pairs(props) do i[k]=v end
    if parent then i.Parent=parent end
    return i
end
local function corner(r,p)     return mk("UICorner",{CornerRadius=UDim.new(0,r)},p) end
local function stroke(c,t,p)   return mk("UIStroke",{Color=c,Thickness=t},p) end
local function pad(l,r,t,b,p)
    local u = Instance.new("UIPadding")
    u.PaddingLeft=UDim.new(0,l); u.PaddingRight=UDim.new(0,r)
    u.PaddingTop=UDim.new(0,t);  u.PaddingBottom=UDim.new(0,b)
    u.Parent=p; return u
end

-- // ── CIRCLE BUTTON ─────────────────────────────
local CircleOuter = mk("Frame",{
    Size=UDim2.new(0,72,0,72),
    Position=UDim2.new(0,14,0.5,-36),
    BackgroundColor3=C.bg,
    BorderSizePixel=0,
},ScreenGui)
corner(999,CircleOuter)
stroke(C.accentHi,2.5,CircleOuter)

local GlowRing = mk("Frame",{
    Size=UDim2.new(1,14,1,14),
    Position=UDim2.new(0,-7,0,-7),
    BackgroundTransparency=1,
    BorderSizePixel=0,
},CircleOuter)
corner(999,GlowRing)
local glowStroke = stroke(C.accent,7,GlowRing)
glowStroke.Transparency = 0.65

TweenService:Create(glowStroke,TweenInfo.new(1.2,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),
    {Transparency=0.88}):Play()

mk("TextLabel",{
    Size=UDim2.new(1,0,0,38), Position=UDim2.new(0,0,0,5),
    BackgroundTransparency=1, Text="🐱", TextSize=30,
    Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Center,
},CircleOuter)
mk("TextLabel",{
    Size=UDim2.new(1,0,0,16), Position=UDim2.new(0,0,1,-18),
    BackgroundTransparency=1, Text="BH",
    TextSize=10, Font=Enum.Font.GothamBold,
    TextColor3=C.accentHi, TextXAlignment=Enum.TextXAlignment.Center,
},CircleOuter)

local CircleBtn = mk("TextButton",{
    Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=10,
},CircleOuter)

-- // ── MAIN FRAME ────────────────────────────────
local Main = mk("Frame",{
    Size=UDim2.new(0,440,0,680),
    Position=UDim2.new(0,100,0.5,-340),
    BackgroundColor3=C.bg,
    BorderSizePixel=0,
    Visible=false,
    ClipsDescendants=true,
},ScreenGui)
corner(16,Main)
stroke(C.accent,1.5,Main)

-- // ── HEADER ────────────────────────────────────
local Header = mk("Frame",{
    Size=UDim2.new(1,0,0,54),
    BackgroundColor3=C.panel,
    BorderSizePixel=0,
},Main)
corner(16,Header)
mk("Frame",{Size=UDim2.new(1,0,0,16),Position=UDim2.new(0,0,1,-16),BackgroundColor3=C.panel,BorderSizePixel=0},Header)
mk("TextLabel",{Size=UDim2.new(0,38,0,38),Position=UDim2.new(0,12,0.5,-19),BackgroundTransparency=1,Text="🐱",TextSize=28,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center},Header)
mk("TextLabel",{Size=UDim2.new(0,220,0,26),Position=UDim2.new(0,54,0,8),BackgroundTransparency=1,Text="BULACAT HUB",TextColor3=C.accentHi,TextSize=18,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},Header)
mk("TextLabel",{Size=UDim2.new(0,220,0,16),Position=UDim2.new(0,54,0,32),BackgroundTransparency=1,Text="Egg Stealer v4 — God Mode Edition",TextColor3=C.subtext,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},Header)
local VerBadge = mk("Frame",{Size=UDim2.new(0,42,0,20),Position=UDim2.new(1,-88,0.5,-10),BackgroundColor3=C.accent,BorderSizePixel=0},Header)
corner(6,VerBadge)
mk("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="v4.0",TextColor3=Color3.new(1,1,1),TextSize=10,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center},VerBadge)
local CloseBtn = mk("TextButton",{Size=UDim2.new(0,26,0,26),Position=UDim2.new(1,-36,0.5,-13),BackgroundColor3=C.red,Text="✕",TextColor3=Color3.new(1,1,1),TextSize=13,Font=Enum.Font.GothamBold,BorderSizePixel=0},Header)
corner(999,CloseBtn)

-- // ── BODY ──────────────────────────────────────
local Body = mk("Frame",{Size=UDim2.new(1,-16,1,-62),Position=UDim2.new(0,8,0,60),BackgroundTransparency=1},Main)
mk("UIListLayout",{Padding=UDim.new(0,7),SortOrder=Enum.SortOrder.LayoutOrder},Body)

-- // ── STATUS ────────────────────────────────────
local StatusCard = mk("Frame",{Size=UDim2.new(1,0,0,34),BackgroundColor3=C.card,BorderSizePixel=0,LayoutOrder=1},Body)
corner(10,StatusCard)
local StatusDot  = mk("Frame",{Size=UDim2.new(0,10,0,10),Position=UDim2.new(0,12,0.5,-5),BackgroundColor3=C.subtext,BorderSizePixel=0},StatusCard)
corner(999,StatusDot)
local StatusTxt  = mk("TextLabel",{Size=UDim2.new(1,-30,1,0),Position=UDim2.new(0,28,0,0),BackgroundTransparency=1,Text="Idle — BULACAT HUB v4 ready",TextColor3=C.text,TextSize=12,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},StatusCard)

local function setStatus(txt,dotColor)
    StatusTxt.Text = txt
    StatusDot.BackgroundColor3 = dotColor or C.subtext
end

-- // ══════════════════════════════════════════════
-- // 👑  HOLD LONGEST — OWN DEDICATED CARD
-- // ══════════════════════════════════════════════
local HoldCard = mk("Frame",{
    Size=UDim2.new(1,0,0,148),
    BackgroundColor3=C.card,
    BorderSizePixel=0,
    LayoutOrder=2,
},Body)
corner(12,HoldCard)
stroke(Color3.fromRGB(200,120,255),1.2,HoldCard)
pad(10,10,8,8,HoldCard)

-- section label
mk("TextLabel",{
    Size=UDim2.new(1,0,0,14),
    BackgroundTransparency=1,
    Text="👑  HOLD LONGEST  —  ADMIN ABUSE",
    TextColor3=C.purple,
    TextSize=11,
    Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left,
},HoldCard)

mk("TextLabel",{
    Size=UDim2.new(1,0,0,12),
    Position=UDim2.new(0,0,0,16),
    BackgroundTransparency=1,
    Text="Flies to " .. CFG.HOLD_HEIGHT .. " studs high · God Mode · Spams zone/claim/admin triggers",
    TextColor3=C.subtext,
    TextSize=10,
    Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left,
},HoldCard)

-- HOLD START/STOP button
local HoldBtn = mk("TextButton",{
    Size=UDim2.new(1,0,0,36),
    Position=UDim2.new(0,0,0,32),
    BackgroundColor3=C.purple,
    Text="▶  START HOLD LONGEST",
    TextColor3=Color3.new(1,1,1),
    TextSize=13,
    Font=Enum.Font.GothamBold,
    BorderSizePixel=0,
},HoldCard)
corner(10,HoldBtn)

-- AUTO STEAL INSIDE HOLD — own button
local HoldAutoStealBtn = mk("TextButton",{
    Size=UDim2.new(1,0,0,36),
    Position=UDim2.new(0,0,0,74),
    BackgroundColor3=C.orange,
    Text="🥚  AUTO STEAL (while holding)  —  OFF",
    TextColor3=Color3.new(1,1,1),
    TextSize=12,
    Font=Enum.Font.GothamBold,
    BorderSizePixel=0,
},HoldCard)
corner(10,HoldAutoStealBtn)
stroke(Color3.fromRGB(255,180,60),1.2,HoldAutoStealBtn)

-- indicators row
local HoldIndicatorRow = mk("Frame",{
    Size=UDim2.new(1,0,0,18),
    Position=UDim2.new(0,0,0,116),
    BackgroundTransparency=1,
},HoldCard)
mk("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,10),VerticalAlignment=Enum.VerticalAlignment.Center},HoldIndicatorRow)

local function makeIndicator(label,color,parent)
    local dot = mk("Frame",{Size=UDim2.new(0,8,0,8),BackgroundColor3=Color3.fromRGB(60,60,80),BorderSizePixel=0},parent)
    corner(999,dot)
    mk("TextLabel",{Size=UDim2.new(0,90,0,14),BackgroundTransparency=1,Text=label,TextColor3=C.subtext,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},parent)
    return dot
end

local HoldDot      = makeIndicator("Holding",   C.purple, HoldIndicatorRow)
local HoldGodDot   = makeIndicator("God Mode",  C.green,  HoldIndicatorRow)
local HoldStealDot = makeIndicator("Auto Steal",C.orange, HoldIndicatorRow)

local holdOn = false

HoldBtn.MouseButton1Click:Connect(function()
    holdOn = not holdOn
    if holdOn then
        HoldBtn.Text             = "⏹  STOP HOLD LONGEST"
        HoldBtn.BackgroundColor3 = C.red
        HoldDot.BackgroundColor3    = C.purple
        HoldGodDot.BackgroundColor3 = C.green
        startHoldLongest(
            function(t) setStatus(t, C.gold) end,
            function(c) StatusDot.BackgroundColor3 = c end
        )
        -- restart auto steal loop if it was toggled on
        if holdAutoSteal then
            startHoldAutoSteal(
                function(t) setStatus(t, C.orange) end,
                function(c) StatusDot.BackgroundColor3 = c end,
                State.selectedRar
            )
        end
    else
        HoldBtn.Text             = "▶  START HOLD LONGEST"
        HoldBtn.BackgroundColor3 = C.purple
        HoldDot.BackgroundColor3    = Color3.fromRGB(60,60,80)
        HoldGodDot.BackgroundColor3 = Color3.fromRGB(60,60,80)
        HoldStealDot.BackgroundColor3 = Color3.fromRGB(60,60,80)
        stopHoldLongest(
            function(t) setStatus(t, C.subtext) end,
            function(c) StatusDot.BackgroundColor3 = c end
        )
    end
end)

HoldAutoStealBtn.MouseButton1Click:Connect(function()
    holdAutoSteal = not holdAutoSteal
    if holdAutoSteal then
        HoldAutoStealBtn.Text             = "🥚  AUTO STEAL (while holding)  —  ON"
        HoldAutoStealBtn.BackgroundColor3 = C.green
        HoldStealDot.BackgroundColor3     = C.orange
        if holdOn then
            startHoldAutoSteal(
                function(t) setStatus(t, C.orange) end,
                function(c) StatusDot.BackgroundColor3 = c end,
                State.selectedRar
            )
        end
        setStatus("🥚 Hold Auto Steal — ON (toggles with Hold)", C.orange)
    else
        HoldAutoStealBtn.Text             = "🥚  AUTO STEAL (while holding)  —  OFF"
        HoldAutoStealBtn.BackgroundColor3 = C.orange
        HoldStealDot.BackgroundColor3     = Color3.fromRGB(60,60,80)
        holdStealing = false
        if holdAutoStealConn then
            -- signal loop to stop
            holdAutoSteal = false
        end
        setStatus("🥚 Hold Auto Steal — OFF", C.subtext)
    end
end)

-- // ── RARITY FILTER ─────────────────────────────
local FilterCard = mk("Frame",{Size=UDim2.new(1,0,0,72),BackgroundColor3=C.card,BorderSizePixel=0,LayoutOrder=3},Body)
corner(10,FilterCard)
pad(10,10,6,6,FilterCard)
mk("TextLabel",{Size=UDim2.new(1,0,0,16),BackgroundTransparency=1,Text="FILTER BY RARITY",TextColor3=C.subtext,TextSize=10,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},FilterCard)

local FilterRow = mk("Frame",{Size=UDim2.new(1,0,0,32),Position=UDim2.new(0,0,0,22),BackgroundTransparency=1},FilterCard)
mk("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,6),VerticalAlignment=Enum.VerticalAlignment.Center},FilterRow)

local FILTER_DATA = {{name="Divine",emoji="🟨"},{name="Eternal",emoji="🌌"},{name="Secret",emoji="⬛"},{name="Cosmic",emoji="🟪"}}
for _,fd in ipairs(FILTER_DATA) do
    local rd = getRD(fd.name)
    local fb = mk("TextButton",{Size=UDim2.new(0,88,0,28),BackgroundColor3=rd.color,Text=fd.emoji.." "..fd.name,TextColor3=Color3.new(1,1,1),TextSize=11,Font=Enum.Font.GothamBold,BorderSizePixel=0},FilterRow)
    corner(8,fb)
    fb.MouseButton1Click:Connect(function()
        State.selectedRar[fd.name] = not State.selectedRar[fd.name]
        fb.BackgroundTransparency  = State.selectedRar[fd.name] and 0 or 0.65
        fb.TextTransparency        = State.selectedRar[fd.name] and 0 or 0.4
    end)
end

-- // ── TOGGLE HELPER ─────────────────────────────
local function makeToggle(parent, xOff, label, accentColor)
    local frame  = mk("Frame",{Size=UDim2.new(0,195,0,50),Position=UDim2.new(0,xOff,0,0),BackgroundTransparency=1},parent)
    local track  = mk("Frame",{Size=UDim2.new(0,46,0,24),Position=UDim2.new(0,10,0.5,-12),BackgroundColor3=Color3.fromRGB(30,35,60),BorderSizePixel=0},frame)
    corner(999,track); stroke(accentColor,1,track)
    local thumb  = mk("Frame",{Size=UDim2.new(0,18,0,18),Position=UDim2.new(0,3,0.5,-9),BackgroundColor3=C.subtext,BorderSizePixel=0},track)
    corner(999,thumb)
    mk("TextLabel",{Size=UDim2.new(0,130,0,20),Position=UDim2.new(0,58,0.5,-10),BackgroundTransparency=1,Text=label,TextColor3=C.text,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},frame)
    local togBtn = mk("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=5},frame)
    local on = false
    local function setOn(v)
        on = v
        local goal = v and UDim2.new(0,25,0.5,-9) or UDim2.new(0,3,0.5,-9)
        TweenService:Create(thumb,TweenInfo.new(0.15),{Position=goal,BackgroundColor3=v and accentColor or C.subtext}):Play()
        TweenService:Create(track,TweenInfo.new(0.15),{BackgroundColor3=v and Color3.fromRGB(20,40,80) or Color3.fromRGB(30,35,60)}):Play()
    end
    togBtn.MouseButton1Click:Connect(function() setOn(not on) end)
    return togBtn, function() return on end, setOn
end

-- // ── CONTROLS ──────────────────────────────────
local CtrlCard = mk("Frame",{Size=UDim2.new(1,0,0,50),BackgroundColor3=C.card,BorderSizePixel=0,LayoutOrder=4},Body)
corner(10,CtrlCard)
local _,getAutoOn,setAutoOn = makeToggle(CtrlCard,0,"Auto Steal",C.accentHi)
local _,getOnceOn,setOnceOn = makeToggle(CtrlCard,205,"Steal Once",C.gold)

-- // ── EGG LIST ──────────────────────────────────
local ListCard = mk("Frame",{Size=UDim2.new(1,0,0,240),BackgroundColor3=C.card,BorderSizePixel=0,LayoutOrder=5},Body)
corner(10,ListCard)
mk("TextLabel",{Size=UDim2.new(1,-16,0,20),Position=UDim2.new(0,8,0,6),BackgroundTransparency=1,Text="EGGS NEARBY",TextColor3=C.subtext,TextSize=10,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},ListCard)

local Scroll = mk("ScrollingFrame",{
    Size=UDim2.new(1,-8,1,-30),Position=UDim2.new(0,4,0,26),
    BackgroundTransparency=1,BorderSizePixel=0,
    ScrollBarThickness=3,ScrollBarImageColor3=C.accent,
    CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,
},ListCard)
mk("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder},Scroll)
pad(2,2,2,4,Scroll)

local function buildRow(data,idx)
    local rd  = getRD(data.rarity)
    local row = mk("TextButton",{Size=UDim2.new(1,-4,0,52),BackgroundColor3=Color3.fromRGB(14,18,38),BorderSizePixel=0,Text="",LayoutOrder=idx},Scroll)
    corner(8,row)
    local stripe = mk("Frame",{Size=UDim2.new(0,4,1,-8),Position=UDim2.new(0,4,0,4),BackgroundColor3=rd.color,BorderSizePixel=0},row)
    corner(4,stripe)
    mk("TextLabel",{Size=UDim2.new(0,28,0,28),Position=UDim2.new(0,12,0.5,-14),BackgroundTransparency=1,Text=rd.emoji,TextSize=18,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center},row)
    mk("TextLabel",{Size=UDim2.new(1,-130,0,20),Position=UDim2.new(0,44,0,7),BackgroundTransparency=1,Text=data.pet,TextColor3=C.text,TextSize=13,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},row)
    mk("TextLabel",{Size=UDim2.new(1,-130,0,16),Position=UDim2.new(0,44,0,28),BackgroundTransparency=1,Text=data.rarity.."  ·  "..data.dist.." studs",TextColor3=rd.color,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},row)

    local stBtn = mk("TextButton",{Size=UDim2.new(0,58,0,30),Position=UDim2.new(1,-66,0.5,-15),BackgroundColor3=C.accent,Text="STEAL",TextColor3=Color3.new(1,1,1),TextSize=11,Font=Enum.Font.GothamBold,BorderSizePixel=0},row)
    corner(8,stBtn)

    stBtn.MouseButton1Click:Connect(function()
        if State.stealing then return end
        State.stealing = true
        setStatus("🚀 Flying to: " .. data.pet, C.accentHi)
        stealEgg(data.egg, function(ok)
            State.stealing = false
            setStatus(ok and "✅ Stolen: " .. data.pet or "❌ Failed", ok and C.green or C.red)
        end)
    end)
end

local function refreshList()
    for _,c in ipairs(Scroll:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    local eggs  = scanEggs()
    local added = 0
    for i,data in ipairs(eggs) do
        if State.selectedRar[data.rarity] then
            buildRow(data,i); added = added + 1
        end
    end
    if added == 0 then
        mk("TextLabel",{Size=UDim2.new(1,0,0,40),BackgroundTransparency=1,Text="No eggs found nearby",TextColor3=C.subtext,TextSize=12,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Center},Scroll)
    end
end

-- // ── AUTO STEAL LOOP ───────────────────────────
local stealOnceDidIt = false
task.spawn(function()
    while true do
        task.wait(CFG.STEAL_DELAY)
        if getAutoOn() and not State.stealing then
            if getOnceOn() and stealOnceDidIt then
                setAutoOn(false)
                setStatus("✅ Steal Once done!", C.green)
                stealOnceDidIt = false
                continue
            end
            local eggs   = scanEggs()
            local target = nil
            for _,data in ipairs(eggs) do
                if State.selectedRar[data.rarity] then target=data; break end
            end
            if target then
                State.stealing = true
                setStatus("🚀 Auto → " .. target.pet .. " [" .. target.rarity .. "]", C.accentHi)
                stealEgg(target.egg, function(ok)
                    State.stealing = false
                    if getOnceOn() then stealOnceDidIt = true end
                    setStatus(ok and "✅ Got: " .. target.pet or "❌ Missed", ok and C.green or C.red)
                end)
            end
        end
        if not getAutoOn() then stealOnceDidIt = false end
    end
end)

-- // ── SCAN LOOP ─────────────────────────────────
task.spawn(function()
    while true do
        task.wait(CFG.SCAN_INTERVAL)
        if Main.Visible then refreshList() end
    end
end)

-- // ── TOGGLES ───────────────────────────────────
CircleBtn.MouseButton1Click:Connect(function()
    Main.Visible = not Main.Visible
    if Main.Visible then refreshList() end
end)
CloseBtn.MouseButton1Click:Connect(function() Main.Visible = false end)

-- // ── DRAG ──────────────────────────────────────
local dragging,dragInput,dragStart,startPos
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging=true; dragStart=input.Position; startPos=Main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging=false end
        end)
    end
end)
Header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput=input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+delta.X, startPos.Y.Scale, startPos.Y.Offset+delta.Y)
    end
end)

-- // ── RESPAWN HANDLER ───────────────────────────
LocalPlayer.CharacterAdded:Connect(function()
    State.stealing = false
    holdStealing   = false
    stopFly(); stopHover()
    if holdActive then
        stopHoldLongest(
            function(t) setStatus(t, C.subtext) end,
            function(c) StatusDot.BackgroundColor3 = c end
        )
        holdOn = false
        HoldBtn.Text             = "▶  START HOLD LONGEST"
        HoldBtn.BackgroundColor3 = C.purple
        HoldDot.BackgroundColor3    = Color3.fromRGB(60,60,80)
        HoldGodDot.BackgroundColor3 = Color3.fromRGB(60,60,80)
        HoldStealDot.BackgroundColor3 = Color3.fromRGB(60,60,80)
    end
    setStatus("🔄 Respawned — ready", C.subtext)
end)

print("🐱 BULACAT HUB v4 — God Mode Edition loaded! Click the circle!")
