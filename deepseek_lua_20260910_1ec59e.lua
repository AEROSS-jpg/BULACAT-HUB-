-- // ============================================
-- // 🐱 BULACAT HUB v5.3 — Scanner Fixed
-- // Two-Pass Deep Scan | Smooth Steal | 5-Stud Hover
-- // ============================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CollectionService= game:GetService("CollectionService")
local CoreGui          = game:GetService("CoreGui")
local LocalPlayer      = Players.LocalPlayer

local function getChar()  return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait() end
local function getRoot()  return getChar():WaitForChild("HumanoidRootPart") end
local function getHuman() return getChar():WaitForChild("Humanoid") end

local CFG = {
    EGG_KEYWORDS   = {"egg","Egg","crate","Crate","chest","hatch","Hatch","capsule","Capsule","reward","Reward","prize","Prize"},
    STEAL_DELAY    = 0.05,
    SCAN_INTERVAL  = 0.3,
    FLY_SPEED      = 750,
    APPROACH_DIST  = 2.5,
    HOVER_ABOVE    = 5,
    HOLD_HEIGHT    = 350,
    PARTICLE_COUNT = 22,
}

-- // ─────────────────────────────────────────────
-- // RARITY
-- // ─────────────────────────────────────────────
local RARITY = {
    {name="Divine",   emoji="🟨", color=Color3.fromRGB(255,215,0),   rank=1},
    {name="Eternal",  emoji="🌌", color=Color3.fromRGB(180,0,255),   rank=2},
    {name="Secret",   emoji="⬛", color=Color3.fromRGB(150,150,150), rank=3},
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
-- // NAME EXTRACTION
-- // ─────────────────────────────────────────────
local function cleanName(s)
    if not s then return nil end
    s = tostring(s):gsub("^%s+",""):gsub("%s+$",""):gsub("\n"," ")
    if #s < 2 or #s > 60 then return nil end
    if s:match("^%d+$") then return nil end
    local sl = s:lower()
    local exactBad = {
        ["egg"]=true,["rarity"]=true,["click"]=true,["open"]=true,["buy"]=true,
        ["hatch"]=true,["steal"]=true,["prompt"]=true,["zone"]=true,["button"]=true,
        ["label"]=true,["frame"]=true,["image"]=true,["part"]=true,["model"]=true,
        ["mesh"]=true,["value"]=true,["script"]=true,["module"]=true,["gui"]=true,
        ["pet"]=true,["reward"]=true,["item"]=true,["unknown"]=true,
    }
    if exactBad[sl] then return nil end
    return s
end

local function extractPetName(obj)
    for _,k in ipairs({"PetName","petname","Pet","pet","Reward","reward","ItemName","itemname","Item","item","Prize","prize","Contains","contains","HatchResult","hatchresult","Name","name"}) do
        local ok,val = pcall(function() return obj:GetAttribute(k) end)
        if ok and val and type(val) == "string" then
            local c = cleanName(val)
            if c and not c:lower():find("egg") and not c:lower():find("rarity") then return c end
        end
    end
    for _,v in ipairs(obj:GetDescendants()) do
        if v:IsA("StringValue") and v.Value ~= "" then
            local vn = v.Name:lower()
            if vn:find("pet") or vn:find("reward") or vn:find("name") or vn:find("item") or vn:find("prize") or vn:find("contain") then
                local c = cleanName(v.Value); if c then return c end
            end
        end
    end
    for _,v in ipairs(obj:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local c = cleanName(v.ObjectText)
            if c and not c:lower():find("egg") then return c end
            c = cleanName(v.ActionText)
            if c and not c:lower():find("hatch") and not c:lower():find("open") and not c:lower():find("egg") and not c:lower():find("click") then return c end
        end
    end
    for _,v in ipairs(obj:GetDescendants()) do
        if v:IsA("TextLabel") or v:IsA("TextButton") then
            local c = cleanName(v.Text)
            if c and not c:lower():find("egg") and not c:lower():find("rarity") and not c:lower():find("hatch") and not c:lower():find("click") and not c:lower():find("open") and not c:lower():find("buy") then return c end
        end
    end
    for _,v in ipairs(obj:GetDescendants()) do
        if v:IsA("ToolTip") then local c = cleanName(v.Text); if c then return c end end
    end
    if obj.Parent and obj.Parent:IsA("Model") then
        local c = cleanName(obj.Parent.Name)
        if c and not c:lower():find("egg") then return c end
    end
    local stripped = obj.Name:gsub("[Ee]gg",""):gsub("_"," "):gsub("%-"," "):match("^%s*(.-)%s*$")
    local c = cleanName(stripped)
    if c and #c > 1 then return c end
    return nil
end

local function extractRarity(obj)
    local sources = {}
    for _,k in ipairs({"Rarity","rarity","Tier","tier"}) do
        local ok,val = pcall(function() return obj:GetAttribute(k) end)
        if ok and val then table.insert(sources, tostring(val):lower()) end
    end
    for _,v in ipairs(obj:GetDescendants()) do
        if v:IsA("StringValue") and (v.Name:lower():find("rar") or v.Name:lower():find("tier")) then
            table.insert(sources, (v.Value or ""):lower())
        end
        if (v:IsA("TextLabel") or v:IsA("TextButton")) and v.Text ~= "" then
            table.insert(sources, v.Text:lower())
        end
    end
    table.insert(sources, obj.Name:lower())
    for _,v in ipairs(obj:GetDescendants()) do
        if v:IsA("StringValue") then table.insert(sources, (v.Value or ""):lower()) end
    end
    local joined = table.concat(sources, " ")
    local order  = {"divine","eternal","secret","cosmic","legendary","legend","epic","rare","uncommon","common"}
    local mapped = {"Divine","Eternal","Secret","Cosmic","Legendary","Legendary","Epic","Rare","Uncommon","Common"}
    for i,rk in ipairs(order) do
        if joined:find(rk, 1, true) then return mapped[i] end
    end
    return "Common"
end

-- // ─────────────────────────────────────────────
-- // EGG DETECTION — TWO PASS
-- // ─────────────────────────────────────────────
local HATCH_WORDS = {"hatch","Hatch","open","Open","claim","Claim","collect","Collect","buy","Buy","unlock","Unlock","spin","Spin"}

local function nameMatch(obj)
    local nm = obj.Name:lower()
    for _,kw in ipairs(CFG.EGG_KEYWORDS) do
        if nm:find(kw:lower(), 1, true) then return true end
    end
    return false
end

local function attributeMatch(obj)
    for _,attr in ipairs({"Egg","IsEgg","egg","Type","Category","ObjectType","ItemType","Kind","Class"}) do
        local ok, val = pcall(function() return obj:GetAttribute(attr) end)
        if ok and val then
            local vs = tostring(val):lower()
            for _,kw in ipairs(CFG.EGG_KEYWORDS) do
                if vs:find(kw:lower(),1,true) then return true end
            end
        end
    end
    return false
end

local function tagMatch(obj)
    for _,tag in ipairs(CollectionService:GetTags(obj)) do
        local tl = tag:lower()
        for _,kw in ipairs(CFG.EGG_KEYWORDS) do
            if tl:find(kw:lower(),1,true) then return true end
        end
    end
    return false
end

local function promptMatch(obj)
    -- check own prompt OR any descendant prompt
    local prompts = {}
    local own = obj:FindFirstChildOfClass("ProximityPrompt")
    if own then table.insert(prompts, own) end
    for _,v in ipairs(obj:GetDescendants()) do
        if v:IsA("ProximityPrompt") then table.insert(prompts, v) end
    end
    for _,p in ipairs(prompts) do
        local a = (p.ActionText or ""):lower()
        local o = (p.ObjectText or ""):lower()
        for _,kw in ipairs(CFG.EGG_KEYWORDS) do
            if a:find(kw:lower(),1,true) or o:find(kw:lower(),1,true) then return true end
        end
        for _,hw in ipairs(HATCH_WORDS) do
            if a:find(hw:lower(),1,true) then return true end
        end
    end
    return false
end

local function descendantTextMatch(obj)
    -- dig for strings mentioning egg/crate/hatch/etc (2 levels deep max for speed)
    for _,v in ipairs(obj:GetChildren()) do
        local vn = v.Name:lower()
        for _,kw in ipairs(CFG.EGG_KEYWORDS) do
            if vn:find(kw:lower(),1,true) then return true end
        end
        if v:IsA("StringValue") then
            local val = (v.Value or ""):lower()
            for _,kw in ipairs(CFG.EGG_KEYWORDS) do
                if val:find(kw:lower(),1,true) then return true end
            end
        end
        if v:IsA("TextLabel") or v:IsA("TextButton") then
            local val = (v.Text or ""):lower()
            for _,kw in ipairs(CFG.EGG_KEYWORDS) do
                if val:find(kw:lower(),1,true) then return true end
            end
        end
    end
    return false
end

local function isEggObject(obj)
    -- Pass 1: fast checks
    if nameMatch(obj)      then return true end
    if attributeMatch(obj) then return true end
    if tagMatch(obj)       then return true end
    -- Pass 2: deeper checks
    if promptMatch(obj)    then return true end
    if descendantTextMatch(obj) then return true end
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

local function getEggCenter(obj)
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Model") then
        local parts = {}
        for _,v in ipairs(obj:GetDescendants()) do if v:IsA("BasePart") then table.insert(parts, v.Position) end end
        if #parts > 0 then
            local sum = Vector3.zero
            for _,p in ipairs(parts) do sum = sum + p end
            return sum / #parts
        end
        local ok, cf = pcall(function() return obj:GetPivot() end)
        if ok and cf then return cf.Position end
    end
    return getEggPosition(obj)
end

local function regionLabel(obj)
    local p = obj
    local depth = 0
    while p and depth < 8 do
        if p ~= workspace and p.Parent == workspace and p.Name ~= "Camera" then
            local nm = p.Name
            if #nm >= 2 and #nm <= 30 and nm:lower() ~= "workspace" then return nm end
        end
        p = p.Parent; depth = depth + 1
    end
    return "Map"
end

-- // ─────────────────────────────────────────────
-- // STATS
-- // ─────────────────────────────────────────────
local ScanStats = { rate=0, lastEggs=0, totalScans=0, startTime=tick(), avgTime=0, elapsed=0 }
local _scanSamples = {}
local function recordScan(dt, eggCount)
    ScanStats.totalScans = ScanStats.totalScans + 1
    ScanStats.lastEggs = eggCount
    table.insert(_scanSamples, dt)
    if #_scanSamples > 20 then table.remove(_scanSamples, 1) end
    local sum = 0
    for _,v in ipairs(_scanSamples) do sum = sum + v end
    ScanStats.avgTime = sum / #_scanSamples
    ScanStats.rate = 1 / math.max(ScanStats.avgTime, 0.001)
    ScanStats.elapsed = tick() - ScanStats.startTime
end

-- // ─────────────────────────────────────────────
-- // SCAN — WIDE NET
-- // ─────────────────────────────────────────────
local function scanEggs()
    local t0 = tick()
    local Root = getRoot()
    local rootPos = Root.Position
    local found, seen = {}, {}

    -- classify: don't scan into character limbs (huge perf hit)
    local function isScannable(obj)
        local cls = obj.ClassName
        return cls == "Part" or cls == "MeshPart" or cls == "UnionOperation"
            or cls == "Model" or cls == "Attachment"
            or cls == "ProximityPrompt" or cls == "ClickDetector"
            or cls == "SpawnLocation" or cls == "TrussPart" or cls == "WedgePart"
    end

    for _,obj in ipairs(workspace:GetDescendants()) do
        if seen[obj] then continue end
        seen[obj] = true
        if not isScannable(obj) then continue end

        -- skip if inside a character (avoid false positives from players carrying items)
        local isChar = false
        local check = obj
        local depth = 0
        while check and depth < 3 do
            if check.Parent and check.Parent:IsA("Model") and check.Parent:FindFirstChildOfClass("Humanoid") then
                isChar = true; break
            end
            check = check.Parent; depth = depth + 1
        end
        if isChar then continue end

        if isEggObject(obj) then
            local center = getEggCenter(obj)
            if center then
                local rar    = extractRarity(obj)
                local region = regionLabel(obj)
                local pet    = extractPetName(obj) or (region.." Egg")
                local dist   = math.floor((rootPos - center).Magnitude)
                table.insert(found, {egg=obj, center=center, rarity=rar, pet=pet, dist=dist, region=region, eta=dist/CFG.FLY_SPEED})
            end
        end
    end

    -- also scan player characters (eggs carried/placed on players)
    for _,plr in ipairs(Players:GetPlayers()) do
        local char = plr.Character
        if char then
            for _,obj in ipairs(char:GetDescendants()) do
                if not seen[obj] then
                    seen[obj] = true
                    if isScannable(obj) and isEggObject(obj) then
                        local center = getEggCenter(obj)
                        if center then
                            local rar    = extractRarity(obj)
                            local region = regionLabel(obj)
                            local pet    = extractPetName(obj) or (region.." Egg")
                            local dist   = math.floor((rootPos - center).Magnitude)
                            table.insert(found, {egg=obj, center=center, rarity=rar, pet=pet, dist=dist, region=region, eta=dist/CFG.FLY_SPEED})
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
    recordScan(tick() - t0, #found)
    return found
end

-- // ─────────────────────────────────────────────
-- // GOD MODE
-- // ─────────────────────────────────────────────
local godConn = nil
local function enableGodMode()
    local char = getChar()
    local hum  = getHuman()
    hum.MaxHealth = math.huge
    hum.Health    = math.huge
    if godConn then godConn:Disconnect() end
    godConn = hum.HealthChanged:Connect(function(hp) if hp < hum.MaxHealth then hum.Health = math.huge end end)
    hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
    hum.AutoRotate = false
    for _,p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false; p.Massless = true end
    end
end
local function disableGodMode()
    if godConn then godConn:Disconnect() godConn = nil end
    local ok, hum = pcall(getHuman)
    if ok and hum then
        hum.MaxHealth = 100; hum.Health = 100
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
            if p:IsA("BasePart") then p.CanCollide = true; p.Massless = false end
        end
    end
end

-- // ─────────────────────────────────────────────
-- // FLIGHT
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
    bodyGyro.P = 5e5
    bodyGyro.D = 500

    local arrived = false

    flyConn = RunService.Heartbeat:Connect(function()
        if arrived or not flying then return end
        local ok, root = pcall(getRoot)
        if not ok then stopFly() return end
        local diff = targetPos - root.Position
        local dist = diff.Magnitude
        if dist <= CFG.APPROACH_DIST then
            arrived = true
            root.CFrame = CFrame.new(targetPos)
            if bodyVel then bodyVel.Velocity = Vector3.new(0,0,0) end
            flying = false
            if flyConn then flyConn:Disconnect() flyConn = nil end
            pcall(function() if bodyVel  then bodyVel:Destroy()  bodyVel  = nil end end)
            pcall(function() if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end end)
            if onArrived then task.spawn(onArrived) end
            return
        end
        local dir = diff.Unit
        local s = speed or CFG.FLY_SPEED
        if dist < 30 then s = math.clamp(dist * 15, 40, speed) end
        bodyVel.Velocity = dir * s
        bodyGyro.CFrame  = CFrame.new(root.Position, root.Position + dir)
    end)
end

local hoverConn = nil
local hoverAnchor = nil
local function startHover(pos)
    stopFly()
    hoverAnchor = pos
    local Root = getRoot()
    getHuman().PlatformStand = true
    hoverConn = RunService.Heartbeat:Connect(function()
        if not hoverAnchor then return end
        local ok, root = pcall(getRoot)
        if not ok then return end
        local diff = hoverAnchor - root.Position
        if diff.Magnitude > 0.4 then
            root.CFrame = CFrame.new(root.Position + diff * 0.35)
        else
            root.CFrame = CFrame.new(hoverAnchor)
            root.AssemblyLinearVelocity = Vector3.zero
        end
    end)
end
local function stopHover()
    hoverAnchor = nil
    if hoverConn then hoverConn:Disconnect() hoverConn = nil end
end

-- // ─────────────────────────────────────────────
-- // INTERACT
-- // ─────────────────────────────────────────────
local function burstInteract(egg, root)
    if not egg or not egg.Parent then return end
    local targets = {egg, egg.Parent}
    for _,t in ipairs(targets) do
        if t then
            local touch = t:FindFirstChildOfClass("TouchTransmitter")
            if touch then
                pcall(firetouchinterest, root, t, 0)
                pcall(firetouchinterest, root, t, 1)
            end
            local click = t:FindFirstChildOfClass("ClickDetector")
            if click then pcall(fireclickdetector, click) end
            local prompt = t:FindFirstChildOfClass("ProximityPrompt")
            if prompt then pcall(fireproximityprompt, prompt) end
        end
    end
    for _,v in ipairs(egg:GetDescendants()) do
        if v:IsA("ProximityPrompt") then pcall(fireproximityprompt, v) end
        if v:IsA("ClickDetector")   then pcall(fireclickdetector, v) end
        if v:IsA("TouchTransmitter") and v.Parent then
            pcall(firetouchinterest, root, v.Parent, 0)
            pcall(firetouchinterest, root, v.Parent, 1)
        end
    end
end

-- // ─────────────────────────────────────────────
-- // MONSTER RIDE
-- // ─────────────────────────────────────────────
local rideWeld = nil
local function rideNearestMonster()
    local Root = getRoot()
    local best, bd = nil, math.huge
    local rideKeywords = {"mount","monster","creature","ride","animal","dragon","beast","boss","mob"}
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj ~= Root then
            local nm = obj.Name:lower()
            for _,kw in ipairs(rideKeywords) do
                if nm:find(kw) then
                    local d = (Root.Position - obj.Position).Magnitude
                    if d < bd and d < 120 then bd = d; best = obj end
                    break
                end
            end
        end
    end
    if best then
        Root.CFrame = CFrame.new(best.Position + Vector3.new(0, best.Size.Y/2 + 3, 0))
        if rideWeld then pcall(function() rideWeld:Destroy() end) rideWeld = nil end
        rideWeld = Instance.new("WeldConstraint")
        rideWeld.Part0 = Root; rideWeld.Part1 = best; rideWeld.Parent = Root
        getHuman().PlatformStand = true
        task.delay(4, function()
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
-- // STEAL — 5 STUDS ABOVE
-- // ─────────────────────────────────────────────
local function stealEgg(egg, center, onDone)
    if not egg or not egg.Parent then
        if onDone then onDone(false) end
        return
    end
    local eggCenter = center or getEggCenter(egg) or getEggPosition(egg)
    if not eggCenter then
        if onDone then onDone(false) end
        return
    end
    local hoverPos = eggCenter + Vector3.new(0, CFG.HOVER_ABOVE, 0)
    enableGodMode()
    flyTo(hoverPos, CFG.FLY_SPEED, function()
        startHover(hoverPos)
        local ok2, root = pcall(getRoot)
        if not ok2 then
            stopHover(); disableGodMode()
            if onDone then onDone(false) end
            return
        end
        burstInteract(egg, root)
        task.wait(0.06)
        burstInteract(egg, root)
        task.wait(0.06)
        burstInteract(egg, root)
        stopHover()
        disableGodMode()
        rideNearestMonster()
        if onDone then onDone(true) end
    end)
end

-- // ─────────────────────────────────────────────
-- // HOLD
-- // ─────────────────────────────────────────────
local holdActive=false; local holdConn=nil; local holdBV=nil; local holdBG=nil
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
        local ok, root = pcall(getRoot); if not ok then return end
        if not reached and root.Position.Y >= (skyPos.Y - 10) then
            reached = true; holdBV.Velocity = Vector3.new(0,0,0)
        end
        if reached then
            local diff = skyPos - root.Position
            holdBV.Velocity = diff.Magnitude > 2 and diff.Unit * 60 or Vector3.new(0,0,0)
            for _,obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    local nm = obj.Name:lower()
                    if nm:find("hold") or nm:find("zone") or nm:find("claim") then
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
    autoSteal   = false,
    stealing    = false,
    selectedRar = {Divine=true, Eternal=true, Secret=true, Cosmic=true, Legendary=true, Epic=true},
}

-- // ─────────────────────────────────────────────
-- // UI
-- // ─────────────────────────────────────────────
pcall(function()
    for _,n in ipairs({"BulacatHubV4","BulacatHubV5","BulacatHubV51","BulacatHubV52","BulacatHubV53"}) do
        local o = CoreGui:FindFirstChild(n); if o then o:Destroy() end
    end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name            = "BulacatHubV53"
ScreenGui.ResetOnSpawn    = false
ScreenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder    = 999
ScreenGui.Parent          = CoreGui

local C = {
    bg=Color3.fromRGB(4,6,16), panel=Color3.fromRGB(8,11,24),
    card=Color3.fromRGB(12,16,34), cardHi=Color3.fromRGB(18,24,52),
    accent=Color3.fromRGB(40,130,255), accentHi=Color3.fromRGB(100,190,255),
    text=Color3.fromRGB(230,240,255), subtext=Color3.fromRGB(110,130,180),
    green=Color3.fromRGB(50,230,120), red=Color3.fromRGB(255,65,65),
    gold=Color3.fromRGB(255,205,50), purple=Color3.fromRGB(170,80,255),
    cyan=Color3.fromRGB(60,225,255), pink=Color3.fromRGB(255,80,180),
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
local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                     or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)
end

-- LOGO
local LOGO_SIZE = 62
local LogoOuter = mk("Frame",{
    Size=UDim2.new(0,LOGO_SIZE,0,LOGO_SIZE),
    Position=UDim2.new(0,14,0.5,-31),
    BackgroundColor3=Color3.fromRGB(4,6,16),
    BorderSizePixel=0, ZIndex=40,
},ScreenGui)
corner(999, LogoOuter)
stroke(C.accentHi, 2, LogoOuter)

local Ring1 = mk("Frame",{Size=UDim2.new(1,14,1,14),Position=UDim2.new(0,-7,0,-7),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=39},LogoOuter)
corner(999, Ring1)
local r1s = stroke(C.accent, 4, Ring1)
r1s.Transparency = 0.4
TweenService:Create(r1s, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Transparency=0.85, Color=C.cyan}):Play()

local Ring2 = mk("Frame",{Size=UDim2.new(1,26,1,26),Position=UDim2.new(0,-13,0,-13),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=38},LogoOuter)
corner(999, Ring2)
local r2s = stroke(C.purple, 2, Ring2)
r2s.Transparency = 0.75
TweenService:Create(r2s, TweenInfo.new(2.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Transparency=0.95, Color=C.pink}):Play()

local Hex = mk("Frame",{Size=UDim2.new(0,44,0,44),Position=UDim2.new(0.5,-22,0.5,-22),BackgroundColor3=C.panel,BorderSizePixel=0,Rotation=45,ZIndex=41},LogoOuter)
corner(10, Hex)
local hexStroke = stroke(C.accentHi, 1.5, Hex)
TweenService:Create(hexStroke, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Color=C.cyan}):Play()

local Core = mk("Frame",{Size=UDim2.new(0,32,0,32),Position=UDim2.new(0.5,-16,0.5,-16),BackgroundColor3=C.bg,BorderSizePixel=0,Rotation=45,ZIndex=42},LogoOuter)
corner(8, Core)
stroke(C.accent, 1, Core)

mk("TextLabel",{Size=UDim2.new(1,0,1,0),Position=UDim2.new(0,0,0,0),BackgroundTransparency=1,Text="🐱",TextSize=26,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center,TextYAlignment=Enum.TextYAlignment.Center,ZIndex=43},LogoOuter)
mk("TextLabel",{Size=UDim2.new(1,0,0,12),Position=UDim2.new(0,0,1,2),BackgroundTransparency=1,Text="BH v5.3",TextSize=8,Font=Enum.Font.GothamBold,TextColor3=C.accentHi,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=43},LogoOuter)

local ParticleFrame = mk("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,ZIndex=44},LogoOuter)
local PARTICLE_COLORS = {C.accentHi, C.cyan, C.purple, C.gold, C.green, C.pink}
local particles = {}
for i = 1, CFG.PARTICLE_COUNT do
    local psize = math.random(2,5)
    local col = PARTICLE_COLORS[((i-1)%#PARTICLE_COLORS)+1]
    local trail = mk("Frame",{Size=UDim2.new(0,psize*2,0,psize*2),BackgroundColor3=col,BackgroundTransparency=0.75,BorderSizePixel=0,ZIndex=44},ParticleFrame)
    corner(999,trail)
    local p = mk("Frame",{Size=UDim2.new(0,psize,0,psize),BackgroundColor3=col,BorderSizePixel=0,ZIndex=45},ParticleFrame)
    corner(999,p)
    mk("UIStroke",{Color=col,Thickness=1.5,Transparency=0.5},p)
    particles[i] = {frame=p, trail=trail, angle=math.rad((360/CFG.PARTICLE_COUNT)*i), speed=0.7+math.random()*1.1, radius=24+math.random()*10, yOff=math.sin(i*0.7)*4}
end
local t0 = tick()
RunService.Heartbeat:Connect(function()
    local elapsed = tick() - t0
    local cx = LogoOuter.AbsoluteSize.X / 2
    local cy = LogoOuter.AbsoluteSize.Y / 2
    LogoOuter.BackgroundColor3 = Color3.fromRGB(4 + math.sin(elapsed*2)*3, 6 + math.sin(elapsed*2.3)*3, 16 + math.sin(elapsed*2.6)*5)
    for _,pt in ipairs(particles) do
        local ang = pt.angle + elapsed * pt.speed
        local px = cx + math.cos(ang) * pt.radius - pt.frame.AbsoluteSize.X/2
        local py = cy + math.sin(ang) * pt.radius + math.sin(elapsed*1.4)*pt.yOff - pt.frame.AbsoluteSize.Y/2
        pt.frame.Position = UDim2.new(0, px, 0, py)
        local ang2 = ang - 0.22
        local tx = cx + math.cos(ang2) * pt.radius - pt.trail.AbsoluteSize.X/2
        local ty = cy + math.sin(ang2) * pt.radius + math.sin((elapsed-0.06)*1.4)*pt.yOff - pt.trail.AbsoluteSize.Y/2
        pt.trail.Position = UDim2.new(0, tx, 0, ty)
    end
end)

local logoDragBtn = mk("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=50},LogoOuter)
makeDraggable(LogoOuter, logoDragBtn)

-- MAIN PANEL
local PANEL_W, PANEL_H = 360, 520
local Main = mk("Frame",{
    Size=UDim2.new(0,PANEL_W,0,PANEL_H),
    Position=UDim2.new(0,90,0.5,-PANEL_H/2),
    BackgroundColor3=C.bg,
    BorderSizePixel=0,
    Visible=false,
    ClipsDescendants=true,
    ZIndex=10,
},ScreenGui)
corner(14,Main)
local mainStroke = stroke(C.accent,1.2,Main)
TweenService:Create(mainStroke, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Color=C.cyan}):Play()

local Header = mk("Frame",{Size=UDim2.new(1,0,0,42),BackgroundColor3=C.panel,BorderSizePixel=0,ZIndex=11},Main)
corner(14,Header)
mk("Frame",{Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,1,-14),BackgroundColor3=C.panel,BorderSizePixel=0,ZIndex=11},Header)
local HeadGlow = mk("Frame",{Size=UDim2.new(1,0,0,2),Position=UDim2.new(0,0,1,-2),BackgroundColor3=C.accentHi,BorderSizePixel=0,ZIndex=13},Header)
TweenService:Create(HeadGlow, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {BackgroundColor3=C.cyan}):Play()
mk("TextLabel",{Size=UDim2.new(0,30,0,30),Position=UDim2.new(0,10,0.5,-15),BackgroundTransparency=1,Text="🐱",TextSize=20,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=12},Header)
mk("TextLabel",{Size=UDim2.new(0,200,0,20),Position=UDim2.new(0,44,0,4),BackgroundTransparency=1,Text="BULACAT HUB",TextColor3=C.accentHi,TextSize=14,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=12},Header)
mk("TextLabel",{Size=UDim2.new(0,200,0,12),Position=UDim2.new(0,44,0,24),BackgroundTransparency=1,Text="Egg Stealer v5.3 • Scanner Fixed",TextColor3=C.subtext,TextSize=9,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=12},Header)
local HeadStat = mk("TextLabel",{Size=UDim2.new(0,90,0,14),Position=UDim2.new(1,-120,0.5,-7),BackgroundTransparency=1,Text="0/s",TextColor3=C.cyan,TextSize=9,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Right,ZIndex=12},Header)
local CloseBtn = mk("TextButton",{Size=UDim2.new(0,22,0,22),Position=UDim2.new(1,-30,0.5,-11),BackgroundColor3=C.red,Text="✕",TextColor3=Color3.new(1,1,1),TextSize=11,Font=Enum.Font.GothamBold,BorderSizePixel=0,ZIndex=13},Header)
corner(999,CloseBtn)
makeDraggable(Main, Header)

local Body = mk("Frame",{Size=UDim2.new(1,-12,1,-48),Position=UDim2.new(0,6,0,46),BackgroundTransparency=1,ZIndex=11},Main)
mk("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},Body)

local StatusCard = mk("Frame",{Size=UDim2.new(1,0,0,34),BackgroundColor3=C.card,BorderSizePixel=0,LayoutOrder=1,ZIndex=11},Body)
corner(8,StatusCard); stroke(C.accent,0.8,StatusCard)
local StatusDot = mk("Frame",{Size=UDim2.new(0,8,0,8),Position=UDim2.new(0,10,0.5,-4),BackgroundColor3=C.subtext,BorderSizePixel=0,ZIndex=12},StatusCard)
corner(999,StatusDot)
local StatusTxt = mk("TextLabel",{Size=UDim2.new(1,-28,1,0),Position=UDim2.new(0,24,0,0),BackgroundTransparency=1,Text="Ready",TextColor3=C.text,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=12},StatusCard)
local function setStatus(txt, dotColor)
    StatusTxt.Text = txt
    StatusDot.BackgroundColor3 = dotColor or C.subtext
end

local StatsCard = mk("Frame",{Size=UDim2.new(1,0,0,44),BackgroundColor3=C.card,BorderSizePixel=0,LayoutOrder=2,ZIndex=11},Body)
corner(8,StatsCard); stroke(C.purple,0.8,StatsCard)
pad(8,8,4,4,StatsCard)
local function makeStat(parent, xOff, label, col)
    local f = mk("Frame",{Size=UDim2.new(0,0.33,1,0),Position=UDim2.new(xOff,0,0,0),BackgroundTransparency=1,ZIndex=12},parent)
    local val = mk("TextLabel",{Size=UDim2.new(1,0,0,18),Position=UDim2.new(0,0,0,2),BackgroundTransparency=1,Text="0",TextColor3=col,TextSize=13,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=13},f)
    mk("TextLabel",{Size=UDim2.new(1,0,0,12),Position=UDim2.new(0,0,0,22),BackgroundTransparency=1,Text=label,TextColor3=C.subtext,TextSize=8,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=13},f)
    return val
end
local StatRate   = makeStat(StatsCard, 0,    "SCAN/S",  C.cyan)
local StatEggs   = makeStat(StatsCard, 0.33, "EGGS",    C.gold)
local StatElapsed= makeStat(StatsCard, 0.66, "UPTIME",  C.green)

local HoldCard = mk("Frame",{Size=UDim2.new(1,0,0,52),BackgroundColor3=C.card,BorderSizePixel=0,LayoutOrder=3,ZIndex=11},Body)
corner(8,HoldCard); stroke(C.purple,0.8,HoldCard)
pad(8,8,6,6,HoldCard)
mk("TextLabel",{Size=UDim2.new(1,0,0,12),BackgroundTransparency=1,Text="👑 ADMIN ABUSE",TextColor3=C.subtext,TextSize=9,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=12},HoldCard)
local HoldBtn = mk("TextButton",{Size=UDim2.new(1,0,0,28),Position=UDim2.new(0,0,0,16),BackgroundColor3=C.purple,Text="👑  HOLD LONGEST  —  START",TextColor3=Color3.new(1,1,1),TextSize=11,Font=Enum.Font.GothamBold,BorderSizePixel=0,ZIndex=12},HoldCard)
corner(8,HoldBtn)
stroke(Color3.fromRGB(220,150,255),1,HoldBtn)

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

local FilterCard = mk("Frame",{Size=UDim2.new(1,0,0,66),BackgroundColor3=C.card,BorderSizePixel=0,LayoutOrder=4,ZIndex=11},Body)
corner(8,FilterCard); stroke(C.accent,0.8,FilterCard)
pad(8,8,4,4,FilterCard)
mk("TextLabel",{Size=UDim2.new(1,0,0,12),BackgroundTransparency=1,Text="⚡ FILTER RARITY",TextColor3=C.subtext,TextSize=9,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=12},FilterCard)
local FR1 = mk("Frame",{Size=UDim2.new(1,0,0,22),Position=UDim2.new(0,0,0,16),BackgroundTransparency=1,ZIndex=12},FilterCard)
mk("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,4),VerticalAlignment=Enum.VerticalAlignment.Center},FR1)
local FR2 = mk("Frame",{Size=UDim2.new(1,0,0,22),Position=UDim2.new(0,0,0,40),BackgroundTransparency=1,ZIndex=12},FilterCard)
mk("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,4),VerticalAlignment=Enum.VerticalAlignment.Center},FR2)
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
    local fb = mk("TextButton",{Size=UDim2.new(0,74,0,20),BackgroundColor3=rd.color,Text=fd.emoji.." "..fd.name,TextColor3=Color3.new(1,1,1),TextSize=9,Font=Enum.Font.GothamBold,BorderSizePixel=0,ZIndex=13},fd.row)
    corner(6,fb)
    fb.MouseButton1Click:Connect(function()
        State.selectedRar[fd.name] = not State.selectedRar[fd.name]
        fb.BackgroundTransparency = State.selectedRar[fd.name] and 0 or 0.65
        fb.TextTransparency       = State.selectedRar[fd.name] and 0 or 0.4
    end)
end

local function makeToggle(parent,xOff,label,accentColor)
    local frame = mk("Frame",{Size=UDim2.new(0,166,0,42),Position=UDim2.new(0,xOff,0,0),BackgroundTransparency=1,ZIndex=12},parent)
    local track = mk("Frame",{Size=UDim2.new(0,42,0,20),Position=UDim2.new(0,8,0.5,-10),BackgroundColor3=Color3.fromRGB(20,25,50),BorderSizePixel=0,ZIndex=13},frame)
    corner(999,track); stroke(accentColor,1,track)
    local thumb = mk("Frame",{Size=UDim2.new(0,16,0,16),Position=UDim2.new(0,2,0.5,-8),BackgroundColor3=C.subtext,BorderSizePixel=0,ZIndex=14},track)
    corner(999,thumb)
    mk("TextLabel",{Size=UDim2.new(0,110,0,20),Position=UDim2.new(0,54,0.5,-10),BackgroundTransparency=1,Text=label,TextColor3=C.text,TextSize=10,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=13},frame)
    local togBtn = mk("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=15},frame)
    local on = false
    local function setOn(v)
        on = v
        local goal = v and UDim2.new(0,24,0.5,-8) or UDim2.new(0,2,0.5,-8)
        TweenService:Create(thumb,TweenInfo.new(0.15),{Position=goal,BackgroundColor3=v and accentColor or C.subtext}):Play()
        TweenService:Create(track,TweenInfo.new(0.15),{BackgroundColor3=v and Color3.fromRGB(15,35,75) or Color3.fromRGB(20,25,50)}):Play()
    end
    togBtn.MouseButton1Click:Connect(function() setOn(not on) end)
    return togBtn, function() return on end, setOn
end

local CtrlCard = mk("Frame",{Size=UDim2.new(1,0,0,42),BackgroundColor3=C.card,BorderSizePixel=0,LayoutOrder=5,ZIndex=11},Body)
corner(8,CtrlCard); stroke(C.gold,0.8,CtrlCard)
local getAutoOn, setAutoOn, getOnceOn, setOnceOn
do
    local _,g1,s1 = makeToggle(CtrlCard,0,"Auto Steal",C.accentHi)
    getAutoOn, setAutoOn = g1, s1
    local _,g2,s2 = makeToggle(CtrlCard,180,"Steal Once",C.gold)
    getOnceOn, setOnceOn = g2, s2
end

local ListCard = mk("Frame",{Size=UDim2.new(1,0,0,220),BackgroundColor3=C.card,BorderSizePixel=0,LayoutOrder=6,ZIndex=11},Body)
corner(8,ListCard); stroke(C.cyan,0.8,ListCard)
local ListHeader = mk("Frame",{Size=UDim2.new(1,0,0,22),BackgroundColor3=C.cardHi,BorderSizePixel=0,ZIndex=12},ListCard)
corner(8,ListHeader)
mk("Frame",{Size=UDim2.new(1,0,0,8),Position=UDim2.new(0,0,1,-8),BackgroundColor3=C.cardHi,BorderSizePixel=0,ZIndex=12},ListHeader)
mk("TextLabel",{Size=UDim2.new(0.5,0,1,0),Position=UDim2.new(0,8,0,0),BackgroundTransparency=1,Text="🌍 ALL MAP EGGS",TextColor3=C.subtext,TextSize=9,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=13},ListHeader)
local EggCountLbl = mk("TextLabel",{Size=UDim2.new(0.5,0,1,0),Position=UDim2.new(0.5,0,0,0),BackgroundTransparency=1,Text="0 found",TextColor3=C.cyan,TextSize=9,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Right,ZIndex=13},ListHeader)
pad(0,8,0,0,EggCountLbl)
local Scroll = mk("ScrollingFrame",{
    Size=UDim2.new(1,-6,1,-26), Position=UDim2.new(0,3,0,24),
    BackgroundTransparency=1, BorderSizePixel=0,
    ScrollBarThickness=2, ScrollBarImageColor3=C.accent,
    CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
    ZIndex=12,
},ListCard)
mk("UIListLayout",{Padding=UDim.new(0,3),SortOrder=Enum.SortOrder.LayoutOrder},Scroll)
pad(2,2,2,2,Scroll)

local function buildRow(data, idx)
    local rd = getRD(data.rarity)
    local row = mk("TextButton",{Size=UDim2.new(1,-2,0,44),BackgroundColor3=Color3.fromRGB(10,14,30),BorderSizePixel=0,Text="",LayoutOrder=idx,ZIndex=13},Scroll)
    corner(7,row); stroke(rd.color, 0.6, row)
    row.MouseEnter:Connect(function() TweenService:Create(row,TweenInfo.new(0.12),{BackgroundColor3=Color3.fromRGB(16,22,46)}):Play() end)
    row.MouseLeave:Connect(function() TweenService:Create(row,TweenInfo.new(0.12),{BackgroundColor3=Color3.fromRGB(10,14,30)}):Play() end)
    local stripe = mk("Frame",{Size=UDim2.new(0,3,1,-6),Position=UDim2.new(0,3,0,3),BackgroundColor3=rd.color,BorderSizePixel=0,ZIndex=14},row)
    corner(3,stripe)
    mk("TextLabel",{Size=UDim2.new(0,22,0,22),Position=UDim2.new(0,9,0.5,-11),BackgroundTransparency=1,Text=rd.emoji,TextSize=14,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=14},row)
    mk("TextLabel",{Size=UDim2.new(1,-108,0,14),Position=UDim2.new(0,34,0,5),BackgroundTransparency=1,Text=data.pet,TextColor3=C.text,TextSize=11,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=14},row)
    mk("TextLabel",{Size=UDim2.new(1,-108,0,10),Position=UDim2.new(0,34,0,19),BackgroundTransparency=1,Text=data.rarity.." • "..data.region,TextColor3=rd.color,TextSize=8,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=14},row)
    local etaTxt = data.eta < 1 and string.format("%.2fs", data.eta) or string.format("%.1fs", data.eta)
    mk("TextLabel",{Size=UDim2.new(1,-108,0,10),Position=UDim2.new(0,34,0,30),BackgroundTransparency=1,Text=data.dist.." studs • ETA "..etaTxt,TextColor3=C.subtext,TextSize=8,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=14},row)
    local stBtn = mk("TextButton",{Size=UDim2.new(0,50,0,24),Position=UDim2.new(1,-56,0.5,-12),BackgroundColor3=C.accent,Text="STEAL",TextColor3=Color3.new(1,1,1),TextSize=9,Font=Enum.Font.GothamBold,BorderSizePixel=0,ZIndex=15},row)
    corner(6,stBtn); stroke(C.accentHi,0.6,stBtn)
    stBtn.MouseEnter:Connect(function() TweenService:Create(stBtn,TweenInfo.new(0.1),{BackgroundColor3=C.accentHi}):Play() end)
    stBtn.MouseLeave:Connect(function() TweenService:Create(stBtn,TweenInfo.new(0.1),{BackgroundColor3=C.accent}):Play() end)
    stBtn.MouseButton1Click:Connect(function()
        if State.stealing then return end
        State.stealing = true
        setStatus("🚀 → "..data.pet, C.accentHi)
        stealEgg(data.egg, data.center, function(ok)
            State.stealing = false
            setStatus(ok and ("✅ "..data.pet) or ("❌ Failed"), ok and C.green or C.red)
        end)
    end)
end

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
    HeadStat.Text = string.format("%.1f scan/s", ScanStats.rate)
    StatRate.Text = string.format("%.1f", ScanStats.rate)
    StatEggs.Text = tostring(added)
    if added == 0 then
        mk("TextLabel",{Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,Text="No eggs matching filter",TextColor3=C.subtext,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=13},Scroll)
    end
end

-- // STEAL ONCE + AUTO
local stealOnceBusy = false
local stealOnceDone = false

local function runAutoStealTick()
    local autoOn = getAutoOn and getAutoOn() or false
    local onceOn = getOnceOn and getOnceOn() or false
    if not autoOn then
        stealOnceBusy = false
        stealOnceDone = false
        return
    end
    if State.stealing then return end
    if onceOn then
        if stealOnceDone or stealOnceBusy then return end
        stealOnceBusy = true
        local ok, eggs = pcall(scanEggs)
        if ok and eggs and #eggs > 0 then
            local target = nil
            for _,data in ipairs(eggs) do
                if State.selectedRar[data.rarity] and data.egg and data.egg.Parent then
                    target = data; break
                end
            end
            if target then
                State.stealing = true
                setStatus("🚀 [ONCE] → "..target.pet, C.accentHi)
                stealEgg(target.egg, target.center, function(success)
                    State.stealing = false
                    stealOnceBusy = false
                    stealOnceDone = true
                    setAutoOn(false)
                    setOnceOn(false)
                    setStatus(success and ("✅ [ONCE] "..target.pet) or ("❌ [ONCE] failed"), success and C.green or C.red)
                end)
            else
                stealOnceBusy = false
                setStatus("🔍 No eggs matching filter", C.subtext)
            end
        else
            stealOnceBusy = false
        end
        return
    end
    local ok, eggs = pcall(scanEggs)
    if not ok or not eggs or #eggs == 0 then
        setStatus("🔍 No eggs matching filter", C.subtext)
        return
    end
    local target = nil
    for _,data in ipairs(eggs) do
        if State.selectedRar[data.rarity] and data.egg and data.egg.Parent then
            target = data; break
        end
    end
    if target then
        State.stealing = true
        setStatus("🚀 Auto → "..target.pet.." ["..target.rarity.."]", C.accentHi)
        stealEgg(target.egg, target.center, function(success)
            State.stealing = false
            setStatus(success and ("✅ Got: "..target.pet) or ("❌ Missed: "..target.pet), success and C.green or C.red)
        end)
    end
end

task.spawn(function()
    while true do
        task.wait(CFG.STEAL_DELAY)
        pcall(runAutoStealTick)
    end
end)

task.spawn(function()
    while true do
        task.wait(CFG.SCAN_INTERVAL)
        if Main.Visible then pcall(refreshList) end
        local up = math.floor(ScanStats.elapsed)
        StatElapsed.Text = string.format("%02d:%02d", math.floor(up/60), up%60)
    end
end)

do
    local LogoBtn = mk("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=51},LogoOuter)
    local downAt
    LogoBtn.MouseButton1Down:Connect(function() downAt = UserInputService:GetMouseLocation() end)
    LogoBtn.MouseButton1Up:Connect(function()
        local cur = UserInputService:GetMouseLocation()
        if downAt and (cur-downAt).Magnitude < 6 then
            Main.Visible = not Main.Visible
            if Main.Visible then pcall(refreshList) end
        end
    end)
end

CloseBtn.MouseButton1Click:Connect(function() Main.Visible = false end)

LocalPlayer.CharacterAdded:Connect(function()
    State.stealing = false
    stealOnceBusy = false
    stealOnceDone = false
    pcall(stopFly)
    pcall(stopHover)
    if holdActive then pcall(stopHoldLongest) end
    if rideWeld then pcall(function() rideWeld:Destroy() rideWeld = nil end) end
    setStatus("🔄 Respawned — ready", C.subtext)
end)

print("🐱 BULACAT HUB v5.3 — Scanner Fixed. Click the logo!")