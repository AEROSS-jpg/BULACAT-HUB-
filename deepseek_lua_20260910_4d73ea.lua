-- // ============================================
-- // 🪓 AXE'S HUB v1 — EXECUTOR-SAFE BUILD
-- // Pixel-Axe Logo | Gold Theme | Score Scanner
-- // Smooth Steal | No continue | pcall-wrapped
-- // ============================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CollectionService= game:GetService("CollectionService")
local CoreGui          = game:GetService("CoreGui")
local LocalPlayer      = Players.LocalPlayer

local function getChar()
    local c = LocalPlayer.Character
    if c then return c end
    return LocalPlayer.CharacterAdded:Wait()
end
local function getRoot()
    local c = getChar()
    return c:WaitForChild("HumanoidRootPart", 10)
end
local function getHuman()
    local c = getChar()
    return c:WaitForChild("Humanoid", 10)
end

local CFG = {
    STEAL_DELAY    = 0.05,
    SCAN_INTERVAL  = 0.4,
    FLY_SPEED      = 750,
    ARRIVE_DIST    = 2.0,
    HOVER_ABOVE    = 5,
    HOLD_HEIGHT    = 350,
    PARTICLE_COUNT = 20,
    MIN_CONFIDENCE = 3,
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
local function getRD(n)
    if RARITY_MAP[n] then return RARITY_MAP[n] end
    return RARITY_MAP["Common"]
end

-- // ─────────────────────────────────────────────
-- // UTIL
-- // ─────────────────────────────────────────────
local STRONG_WORDS = {"egg","crate","chest","hatch","capsule","fossil","present","gift","lootbox","reward"}
local WEAK_WORDS   = {"pet","animal","creature","prize","drop","roll","summon"}
local HATCH_ACTIONS= {"hatch","open","claim","collect","unlock","buy","spin","summon","roll"}

local BLACKLIST_NAMES = {
    door=true, gate=true, button=true, npc=true, sign=true,
    spawn=true, waypoint=true, teleport=true, portal=true,
    shrine=true, statue=true, decal=true, handle=true, ladder=true,
    chair=true, seat=true, vehicle=true,
}

local function containsAny(str, list)
    if not str then return false end
    for _,w in ipairs(list) do
        if str:find(w, 1, true) then return true end
    end
    return false
end

-- // ─────────────────────────────────────────────
-- // SCORING
-- // ─────────────────────────────────────────────
local function scoreEgg(obj)
    local score = 0

    local check = obj
    local depth = 0
    while check ~= nil and depth < 5 do
        if check:IsA("Model") then
            local h = check:FindFirstChildOfClass("Humanoid")
            if h then return 0 end
        end
        check = check.Parent
        depth = depth + 1
    end

    local top = obj
    local guard = 0
    while top ~= nil and top.Parent ~= nil and top.Parent ~= workspace and top.Parent ~= game and guard < 10 do
        top = top.Parent
        guard = guard + 1
    end
    if top ~= workspace then return 0 end

    local nm = string.lower(obj.Name)
    for bad,_ in pairs(BLACKLIST_NAMES) do
        if nm == bad then return 0 end
    end
    if containsAny(nm, STRONG_WORDS) then
        score = score + 4
    elseif containsAny(nm, WEAK_WORDS) then
        score = score + 1
    end

    local par = obj.Parent
    if par and par:IsA("Model") then
        local pn = string.lower(par.Name)
        if containsAny(pn, STRONG_WORDS) then score = score + 2 end
        if containsAny(pn, WEAK_WORDS)   then score = score + 1 end
    end

    local attrKeys = {"Egg","IsEgg","Type","Category","ObjectType","ItemType","Kind","Class","Tag"}
    for _,k in ipairs(attrKeys) do
        local ok, val = pcall(function() return obj:GetAttribute(k) end)
        if ok and val ~= nil then
            local vs = string.lower(tostring(val))
            if containsAny(vs, STRONG_WORDS) then score = score + 3 end
            if containsAny(vs, WEAK_WORDS)   then score = score + 1 end
        end
    end

    local ok2, tags = pcall(function() return CollectionService:GetTags(obj) end)
    if ok2 and tags then
        for _,tag in ipairs(tags) do
            local tl = string.lower(tag)
            if containsAny(tl, STRONG_WORDS) then score = score + 3 end
            if containsAny(tl, WEAK_WORDS)   then score = score + 1 end
        end
    end

    local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
    if prompt then
        local act = string.lower(prompt.ActionText or "")
        local otx = string.lower(prompt.ObjectText or "")
        for _,hw in ipairs(HATCH_ACTIONS) do
            if act:find(hw, 1, true) then
                score = score + 3
                break
            end
        end
        if containsAny(otx, STRONG_WORDS) then score = score + 2 end
        if containsAny(otx, WEAK_WORDS)   then score = score + 1 end
    end

    for _,v in ipairs(obj:GetChildren()) do
        if v:IsA("StringValue") then
            local val = string.lower(v.Value or "")
            if containsAny(val, STRONG_WORDS) then score = score + 2; break end
        elseif v:IsA("TextLabel") or v:IsA("TextButton") then
            local val = string.lower(v.Text or "")
            if containsAny(val, STRONG_WORDS) then score = score + 1; break end
        end
    end

    return score
end

-- // ─────────────────────────────────────────────
-- // EXTRACTORS
-- // ─────────────────────────────────────────────
local function cleanName(s)
    if not s then return nil end
    s = tostring(s)
    s = s:gsub("^%s+", ""):gsub("%s+$", ""):gsub("\n", " ")
    if #s < 2 or #s > 60 then return nil end
    if s:match("^%d+$") then return nil end
    local sl = string.lower(s)
    local bad = {
        egg=true, rarity=true, click=true, open=true, buy=true,
        hatch=true, steal=true, prompt=true, zone=true, button=true,
        label=true, frame=true, image=true, part=true, model=true,
        mesh=true, value=true, script=true, module=true, gui=true,
        pet=true, reward=true, item=true, unknown=true,
    }
    if bad[sl] then return nil end
    return s
end

local function extractPetName(obj)
    local attrList = {"PetName","petname","Pet","pet","Reward","reward","ItemName","itemname","Item","item","Prize","prize","Contains","contains","HatchResult","hatchresult","Name","name"}
    for _,k in ipairs(attrList) do
        local ok, val = pcall(function() return obj:GetAttribute(k) end)
        if ok and val ~= nil and type(val) == "string" then
            local c = cleanName(val)
            if c then
                local cl = string.lower(c)
                if not cl:find("egg") and not cl:find("rarity") then return c end
            end
        end
    end
    local desc = obj:GetDescendants()
    for _,v in ipairs(desc) do
        if v:IsA("StringValue") and v.Value ~= "" then
            local vn = string.lower(v.Name)
            if vn:find("pet") or vn:find("reward") or vn:find("name") or vn:find("item") or vn:find("prize") or vn:find("contain") then
                local c = cleanName(v.Value)
                if c then return c end
            end
        end
    end
    for _,v in ipairs(desc) do
        if v:IsA("ProximityPrompt") then
            local c = cleanName(v.ObjectText)
            if c and not string.lower(c):find("egg") then return c end
            c = cleanName(v.ActionText)
            if c and not string.lower(c):find("hatch") and not string.lower(c):find("open") and not string.lower(c):find("egg") and not string.lower(c):find("click") then
                return c
            end
        end
    end
    for _,v in ipairs(desc) do
        if v:IsA("TextLabel") or v:IsA("TextButton") then
            local c = cleanName(v.Text)
            if c then
                local cl = string.lower(c)
                if not cl:find("egg") and not cl:find("rarity") and not cl:find("hatch") and not cl:find("click") and not cl:find("open") and not cl:find("buy") then
                    return c
                end
            end
        end
    end
    if obj.Parent and obj.Parent:IsA("Model") then
        local c = cleanName(obj.Parent.Name)
        if c and not string.lower(c):find("egg") then return c end
    end
    local stripped = obj.Name:gsub("[Ee]gg",""):gsub("_"," "):gsub("%-"," ")
    stripped = stripped:match("^%s*(.-)%s*$")
    local c = cleanName(stripped)
    if c and #c > 1 then return c end
    return nil
end

local function extractRarity(obj)
    local sources = {}
    local attrList = {"Rarity","rarity","Tier","tier"}
    for _,k in ipairs(attrList) do
        local ok, val = pcall(function() return obj:GetAttribute(k) end)
        if ok and val ~= nil then table.insert(sources, string.lower(tostring(val))) end
    end
    local desc = obj:GetDescendants()
    for _,v in ipairs(desc) do
        if v:IsA("StringValue") then
            local vn = string.lower(v.Name)
            if vn:find("rar") or vn:find("tier") then
                table.insert(sources, string.lower(v.Value or ""))
            end
        end
        if v:IsA("TextLabel") or v:IsA("TextButton") then
            if v.Text ~= "" then table.insert(sources, string.lower(v.Text)) end
        end
    end
    table.insert(sources, string.lower(obj.Name))
    for _,v in ipairs(desc) do
        if v:IsA("StringValue") then
            table.insert(sources, string.lower(v.Value or ""))
        end
    end
    local joined = table.concat(sources, " ")
    local order  = {"divine","eternal","secret","cosmic","legendary","legend","epic","rare","uncommon","common"}
    local mapped = {"Divine","Eternal","Secret","Cosmic","Legendary","Legendary","Epic","Rare","Uncommon","Common"}
    for i = 1, #order do
        if joined:find(order[i], 1, true) then return mapped[i] end
    end
    return "Common"
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
        for _,v in ipairs(obj:GetDescendants()) do
            if v:IsA("BasePart") then table.insert(parts, v.Position) end
        end
        if #parts > 0 then
            local sum = Vector3.new(0, 0, 0)
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
    while p ~= nil and depth < 8 do
        if p ~= workspace and p.Parent == workspace and p.Name ~= "Camera" then
            local nm = p.Name
            if #nm >= 2 and #nm <= 30 and string.lower(nm) ~= "workspace" then
                return nm
            end
        end
        p = p.Parent
        depth = depth + 1
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
    if ScanStats.avgTime < 0.001 then ScanStats.avgTime = 0.001 end
    ScanStats.rate = 1 / ScanStats.avgTime
    ScanStats.elapsed = tick() - ScanStats.startTime
end

-- // ─────────────────────────────────────────────
-- // SCAN
-- // ─────────────────────────────────────────────
local function isScannable(obj)
    local cls = obj.ClassName
    if cls == "Part" or cls == "MeshPart" or cls == "UnionOperation"
    or cls == "Model" or cls == "SpawnLocation" or cls == "TrussPart" then
        return true
    end
    return false
end

local function scanEggs()
    local t0 = tick()
    local okR, Root = pcall(getRoot)
    if not okR or not Root then return {} end
    local rootPos = Root.Position
    local found = {}
    local seen = {}

    local all = workspace:GetDescendants()
    for _,obj in ipairs(all) do
        if not seen[obj] then
            seen[obj] = true
            if isScannable(obj) then
                local score = scoreEgg(obj)
                if score >= CFG.MIN_CONFIDENCE then
                    local center = getEggCenter(obj)
                    if center then
                        local rar    = extractRarity(obj)
                        local region = regionLabel(obj)
                        local pet    = extractPetName(obj)
                        if not pet then pet = region.." Egg" end
                        local dist   = math.floor((rootPos - center).Magnitude)
                        local eta    = dist / CFG.FLY_SPEED
                        table.insert(found, {
                            egg = obj, center = center, rarity = rar, pet = pet,
                            dist = dist, region = region, score = score, eta = eta,
                        })
                    end
                end
            end
        end
    end

    local players = Players:GetPlayers()
    for _,plr in ipairs(players) do
        local char = plr.Character
        if char then
            local desc = char:GetDescendants()
            for _,obj in ipairs(desc) do
                if not seen[obj] then
                    seen[obj] = true
                    if isScannable(obj) then
                        local score = scoreEgg(obj)
                        if score >= CFG.MIN_CONFIDENCE then
                            local center = getEggCenter(obj)
                            if center then
                                local rar    = extractRarity(obj)
                                local region = regionLabel(obj)
                                local pet    = extractPetName(obj)
                                if not pet then pet = region.." Egg" end
                                local dist   = math.floor((rootPos - center).Magnitude)
                                local eta    = dist / CFG.FLY_SPEED
                                table.insert(found, {
                                    egg = obj, center = center, rarity = rar, pet = pet,
                                    dist = dist, region = region, score = score, eta = eta,
                                })
                            end
                        end
                    end
                end
            end
        end
    end

    table.sort(found, function(a,b)
        if a.score ~= b.score then return a.score > b.score end
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
    local okC, char = pcall(getChar)
    if not okC or not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    hum.MaxHealth = math.huge
    hum.Health    = math.huge
    if godConn then pcall(function() godConn:Disconnect() end) end
    godConn = hum.HealthChanged:Connect(function(hp)
        if hp < hum.MaxHealth then hum.Health = math.huge end
    end)
    pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false) end)
    pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false) end)
    pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false) end)
    pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false) end)
    pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false) end)
    hum.AutoRotate = false
    for _,p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            pcall(function() p.CanCollide = false end)
            pcall(function() p.Massless = true end)
        end
    end
end

local function disableGodMode()
    if godConn then pcall(function() godConn:Disconnect() end); godConn = nil end
    local okC, char = pcall(getChar)
    if okC and char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.MaxHealth = 100
            hum.Health = 100
            pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true) end)
            pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true) end)
            pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true) end)
            pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true) end)
            pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true) end)
            hum.AutoRotate = true
        end
        for _,p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then
                pcall(function() p.CanCollide = true end)
                pcall(function() p.Massless = false end)
            end
        end
    end
end

-- // ─────────────────────────────────────────────
-- // FLY
-- // ─────────────────────────────────────────────
local flyState = {
    active = false,
    target = nil,
    speed = CFG.FLY_SPEED,
    arriveDist = CFG.ARRIVE_DIST,
    onArrive = nil,
}
local flyBV = nil
local flyBG = nil

local function ensureFlyBodies()
    local okR, Root = pcall(getRoot)
    if not okR or not Root then return false end
    if not flyBV then
        flyBV = Instance.new("BodyVelocity")
        flyBV.MaxForce = Vector3.new(1e7, 1e7, 1e7)
        flyBV.Velocity = Vector3.new(0, 0, 0)
        flyBV.Parent = Root
    end
    if not flyBG then
        flyBG = Instance.new("BodyGyro")
        flyBG.MaxTorque = Vector3.new(1e7, 1e7, 1e7)
        flyBG.P = 5e5
        flyBG.D = 500
        flyBG.Parent = Root
    end
    return true
end

local function killFlyBodies()
    pcall(function()
        if flyBV then flyBV:Destroy(); flyBV = nil end
    end)
    pcall(function()
        if flyBG then flyBG:Destroy(); flyBG = nil end
    end)
end

local function requestFly(targetPos, speed, onArrive)
    if not ensureFlyBodies() then
        if onArrive then task.spawn(onArrive) end
        return
    end
    flyState.active = true
    flyState.target = targetPos
    flyState.speed = speed or CFG.FLY_SPEED
    flyState.onArrive = onArrive
    local okH, hum = pcall(getHuman)
    if okH and hum then hum.PlatformStand = true end
end

local function cancelFly()
    flyState.active = false
    flyState.target = nil
    flyState.onArrive = nil
    killFlyBodies()
    local okH, hum = pcall(getHuman)
    if okH and hum then hum.PlatformStand = false end
end

RunService.Heartbeat:Connect(function()
    if not flyState.active then return end
    if not flyBV or not flyBG then return end
    local okR, Root = pcall(getRoot)
    if not okR or not Root then return end
    local diff = flyState.target - Root.Position
    local dist = diff.Magnitude
    if dist <= flyState.arriveDist then
        Root.CFrame = CFrame.new(flyState.target)
        Root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        flyBV.Velocity = Vector3.new(0, 0, 0)
        flyState.active = false
        local cb = flyState.onArrive
        flyState.onArrive = nil
        if cb then task.spawn(cb) end
        return
    end
    local dir = diff.Unit
    local s = flyState.speed
    if dist < 30 then
        s = math.clamp(dist * 15, 40, flyState.speed)
    end
    flyBV.Velocity = dir * s
    flyBG.CFrame = CFrame.new(Root.Position, Root.Position + dir)
end)

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
    local desc = egg:GetDescendants()
    for _,v in ipairs(desc) do
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
    local okR, Root = pcall(getRoot)
    if not okR or not Root then return false end
    local best, bd = nil, math.huge
    local rideKeywords = {"mount","monster","creature","ride","animal","dragon","beast","boss","mob"}
    local all = workspace:GetDescendants()
    for _,obj in ipairs(all) do
        if obj:IsA("BasePart") and obj ~= Root then
            local nm = string.lower(obj.Name)
            for _,kw in ipairs(rideKeywords) do
                if nm:find(kw, 1, true) then
                    local d = (Root.Position - obj.Position).Magnitude
                    if d < bd and d < 120 then bd = d; best = obj end
                    break
                end
            end
        end
    end
    if best then
        Root.CFrame = CFrame.new(best.Position + Vector3.new(0, best.Size.Y/2 + 3, 0))
        if rideWeld then pcall(function() rideWeld:Destroy() end); rideWeld = nil end
        rideWeld = Instance.new("WeldConstraint")
        rideWeld.Part0 = Root
        rideWeld.Part1 = best
        rideWeld.Parent = Root
        local okH, hum = pcall(getHuman)
        if okH and hum then hum.PlatformStand = true end
        task.delay(4, function()
            pcall(function()
                if rideWeld then rideWeld:Destroy(); rideWeld = nil end
                local okH2, hum2 = pcall(getHuman)
                if okH2 and hum2 then hum2.PlatformStand = false end
            end)
        end)
        return true
    end
    return false
end

-- // ─────────────────────────────────────────────
-- // STEAL
-- // ─────────────────────────────────────────────
local function stealEgg(egg, center, onDone)
    if not egg or not egg.Parent then
        if onDone then onDone(false) end
        return
    end
    local eggCenter = center
    if not eggCenter then eggCenter = getEggCenter(egg) end
    if not eggCenter then eggCenter = getEggPosition(egg) end
    if not eggCenter then
        if onDone then onDone(false) end
        return
    end
    local hoverPos = eggCenter + Vector3.new(0, CFG.HOVER_ABOVE, 0)
    enableGodMode()
    requestFly(hoverPos, CFG.FLY_SPEED, function()
        local okR, root = pcall(getRoot)
        if not okR or not root then
            cancelFly(); disableGodMode()
            if onDone then onDone(false) end
            return
        end
        burstInteract(egg, root)
        task.wait(0.05)
        burstInteract(egg, root)
        task.wait(0.05)
        burstInteract(egg, root)
        cancelFly()
        disableGodMode()
        rideNearestMonster()
        if onDone then onDone(true) end
    end)
end

-- // ─────────────────────────────────────────────
-- // HOLD
-- // ─────────────────────────────────────────────
local holdActive = false
local holdConn = nil
local holdBV = nil
local holdBG = nil

local function startHoldLongest(statusFn, dotFn)
    if holdActive then return end
    holdActive = true
    enableGodMode()
    local okR, Root = pcall(getRoot)
    if not okR or not Root then return end
    local skyPos = Root.Position + Vector3.new(0, CFG.HOLD_HEIGHT, 0)
    local okH, hum = pcall(getHuman)
    if okH and hum then hum.PlatformStand = true end

    holdBV = Instance.new("BodyVelocity", Root)
    holdBV.MaxForce = Vector3.new(1e7, 1e7, 1e7)
    holdBV.Velocity = Vector3.new(0, CFG.FLY_SPEED, 0)

    holdBG = Instance.new("BodyGyro", Root)
    holdBG.MaxTorque = Vector3.new(1e7, 1e7, 1e7)
    holdBG.CFrame = Root.CFrame

    local reached = false
    holdConn = RunService.Heartbeat:Connect(function()
        if not holdActive then return end
        local okR2, root = pcall(getRoot)
        if not okR2 or not root then return end
        if not reached and root.Position.Y >= (skyPos.Y - 10) then
            reached = true
            holdBV.Velocity = Vector3.new(0, 0, 0)
        end
        if reached then
            local diff = skyPos - root.Position
            if diff.Magnitude > 2 then
                holdBV.Velocity = diff.Unit * 60
            else
                holdBV.Velocity = Vector3.new(0, 0, 0)
            end
            local all = workspace:GetDescendants()
            for _,obj in ipairs(all) do
                if obj:IsA("BasePart") then
                    local nm = string.lower(obj.Name)
                    if nm:find("hold", 1, true) or nm:find("zone", 1, true) or nm:find("claim", 1, true) then
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
    if statusFn then statusFn("🪓 HOLD LONGEST — Flying up!") end
    if dotFn   then dotFn(Color3.fromRGB(255, 215, 0)) end
end

local function stopHoldLongest(statusFn, dotFn)
    holdActive = false
    if holdConn then pcall(function() holdConn:Disconnect() end); holdConn = nil end
    pcall(function() if holdBV then holdBV:Destroy(); holdBV = nil end end)
    pcall(function() if holdBG then holdBG:Destroy(); holdBG = nil end end)
    disableGodMode()
    local okH, hum = pcall(getHuman)
    if okH and hum then hum.PlatformStand = false end
    if statusFn then statusFn("⬛ Hold Longest — Stopped") end
    if dotFn   then dotFn(Color3.fromRGB(100, 100, 140)) end
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
-- // UI BUILD
-- // ─────────────────────────────────────────────
pcall(function()
    for _,n in ipairs({"BulacatHubV4","BulacatHubV5","BulacatHubV51","BulacatHubV52","BulacatHubV53","BulacatHubV6","BulacatHubV61","AxesHubV1"}) do
        local o = CoreGui:FindFirstChild(n)
        if o then o:Destroy() end
    end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name            = "AxesHubV1"
ScreenGui.ResetOnSpawn    = false
ScreenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder    = 999
ScreenGui.Parent          = CoreGui

-- // AXE PALETTE (gold / amber / charcoal)
local C = {
    bg       = Color3.fromRGB(18,16,12),
    panel    = Color3.fromRGB(28,24,16),
    card     = Color3.fromRGB(36,30,20),
    cardHi   = Color3.fromRGB(48,40,26),
    gold     = Color3.fromRGB(255,205,60),
    goldHi   = Color3.fromRGB(255,235,140),
    goldDim  = Color3.fromRGB(200,160,40),
    stone    = Color3.fromRGB(90,90,100),
    stoneHi  = Color3.fromRGB(140,140,150),
    wood     = Color3.fromRGB(120,70,30),
    woodHi   = Color3.fromRGB(160,100,50),
    blade    = Color3.fromRGB(230,180,40),
    bladeHi  = Color3.fromRGB(255,230,120),
    text     = Color3.fromRGB(240,235,210),
    subtext  = Color3.fromRGB(160,145,105),
    green    = Color3.fromRGB(120,220,120),
    red      = Color3.fromRGB(240,90,80),
    purple   = Color3.fromRGB(180,120,255),
    cyan     = Color3.fromRGB(80,220,220),
    orange   = Color3.fromRGB(255,150,50),
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

-- // ─────────────────────────────────────────────
-- // PIXEL AXE LOGO (14x14 pixel grid)
-- // 0 = transparent, G = gold bg, S = stone, W = wood, B = blade
-- // ─────────────────────────────────────────────
local LOGO_SIZE = 68
local LogoOuter = mk("Frame",{
    Size=UDim2.new(0,LOGO_SIZE,0,LOGO_SIZE),
    Position=UDim2.new(0,14,0.5,-LOGO_SIZE/2),
    BackgroundColor3=C.bg,
    BorderSizePixel=0,
    ClampDescendants=true,
    ZIndex=40,
},ScreenGui)
corner(10, LogoOuter)
stroke(C.gold, 2, LogoOuter)

-- Outer glow ring (animated)
local GlowRing = mk("Frame",{
    Size=UDim2.new(1,18,1,18),
    Position=UDim2.new(0,-9,0,-9),
    BackgroundTransparency=1,
    BorderSizePixel=0,
    ZIndex=39,
},LogoOuter)
corner(14, GlowRing)
local glowStroke = stroke(C.goldHi, 3, GlowRing)
glowStroke.Transparency = 0.4
TweenService:Create(glowStroke, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Transparency=0.85, Color=C.orange}):Play()

-- Pixel canvas
local PIXEL_COUNT = 14
local PixelFrame = mk("Frame",{
    Size=UDim2.new(1,-10,1,-10),
    Position=UDim2.new(0,5,0,5),
    BackgroundTransparency=1,
    ZIndex=41,
},LogoOuter)

local PIXEL_SIZE = (LOGO_SIZE - 10) / PIXEL_COUNT

-- Pixel art axe (based on the reference image)
-- Rows 1-14, each row 14 chars
local AXE_ART = {
    "GGGGGGGGGGGGGG",
    "GGSSSSSSSSSSGG",
    "GGS........SGG",
    "GGS...WW...SGG",
    "GGS..WWWW..SGG",
    "GGS.WWWBWW.SGG",
    "GGS.WWBBBB.SGG",
    "GGS.WBBBBB.SGG",
    "GGS.WBBBB..SGG",
    "GGS..BBB...SGG",
    "GGS...WW...SGG",
    "GGS........SGG",
    "GGSSSSSSSSSSGG",
    "GGGGGGGGGGGGGG",
}

local PIXEL_COLORS = {
    ["G"] = C.gold,       -- outer gold frame
    ["S"] = C.stone,      -- stone ring
    ["W"] = C.wood,       -- handle wood
    ["B"] = C.blade,      -- golden blade
    ["."] = nil,          -- transparent (dark background)
}

local pixelGrid = {}
for row = 1, #AXE_ART do
    local line = AXE_ART[row]
    pixelGrid[row] = {}
    for col = 1, #line do
        local ch = line:sub(col, col)
        local color = PIXEL_COLORS[ch]
        if color then
            local px = mk("Frame",{
                Size=UDim2.new(0, PIXEL_SIZE + 0.5, 0, PIXEL_SIZE + 0.5),
                Position=UDim2.new(0, (col-1) * PIXEL_SIZE, 0, (row-1) * PIXEL_SIZE),
                BackgroundColor3=color,
                BorderSizePixel=0,
                ZIndex=42,
            },PixelFrame)
            pixelGrid[row][col] = px
        end
    end
end

-- Animated shine sweep across the blade
task.spawn(function()
    while true do
        task.wait(2.4)
        for row, r in pairs(pixelGrid) do
            for col, px in pairs(r) do
                if px and px.Parent then
                    local bright = (row + col) % 6 == 0
                    if bright then
                        local orig = px.BackgroundColor3
                        TweenService:Create(px, TweenInfo.new(0.25, Enum.EasingStyle.Sine), {
                            BackgroundColor3 = Color3.fromRGB(
                                math.min(255, orig.R + 40),
                                math.min(255, orig.G + 40),
                                math.min(255, orig.B + 40)
                            )
                        }):Play()
                        task.delay(0.3, function()
                            pcall(function()
                                TweenService:Create(px, TweenInfo.new(0.5), {BackgroundColor3=orig}):Play()
                            end)
                        end)
                    end
                end
            end
        end
    end
end)

-- Orbiting particles around the logo
local ParticleFrame = mk("Frame",{
    Size=UDim2.new(1,0,1,0),
    BackgroundTransparency=1,
    ZIndex=43,
},LogoOuter)

local PARTICLE_COLORS = {C.goldHi, C.gold, C.orange, C.bladeHi, C.goldDim}
local particles = {}
for i = 1, CFG.PARTICLE_COUNT do
    local psize = math.random(2,4)
    local col = PARTICLE_COLORS[((i-1) % #PARTICLE_COLORS) + 1]
    local p = mk("Frame",{
        Size=UDim2.new(0,psize,0,psize),
        BackgroundColor3=col,
        BorderSizePixel=0,
        ZIndex=44,
    },ParticleFrame)
    corner(999, p)
    particles[i] = {
        frame = p,
        angle = math.rad((360 / CFG.PARTICLE_COUNT) * i),
        speed = 0.6 + math.random() * 1.0,
        radius = 36 + math.random() * 10,
        yOff = math.sin(i * 0.7) * 4,
    }
end

local logoTime0 = tick()
RunService.Heartbeat:Connect(function()
    local elapsed = tick() - logoTime0
    local cx = LogoOuter.AbsoluteSize.X / 2
    local cy = LogoOuter.AbsoluteSize.Y / 2
    for _,pt in ipairs(particles) do
        if pt.frame and pt.frame.Parent then
            local ang = pt.angle + elapsed * pt.speed
            local px = cx + math.cos(ang) * pt.radius - pt.frame.AbsoluteSize.X / 2
            local py = cy + math.sin(ang) * pt.radius + math.sin(elapsed * 1.4) * pt.yOff - pt.frame.AbsoluteSize.Y / 2
            pt.frame.Position = UDim2.new(0, px, 0, py)
        end
    end
end)

-- Label below logo
mk("TextLabel",{
    Size=UDim2.new(1,0,0,12),
    Position=UDim2.new(0,0,1,3),
    BackgroundTransparency=1,
    Text="AXE'S HUB",
    TextSize=8,
    Font=Enum.Font.GothamBold,
    TextColor3=C.goldHi,
    TextXAlignment=Enum.TextXAlignment.Center,
    ZIndex=45,
},LogoOuter)

-- Drag handle for logo
local logoDragBtn = mk("TextButton",{
    Size=UDim2.new(1,0,1,0),
    BackgroundTransparency=1,
    Text="",
    ZIndex=50,
},LogoOuter)
makeDraggable(LogoOuter, logoDragBtn)

-- // ─────────────────────────────────────────────
-- // MAIN PANEL
-- // ─────────────────────────────────────────────
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
local mainStroke = stroke(C.gold, 1.2, Main)
TweenService:Create(mainStroke, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Color=C.goldHi}):Play()

-- Header
local Header = mk("Frame",{
    Size=UDim2.new(1,0,0,46),
    BackgroundColor3=C.panel,
    BorderSizePixel=0,
    ZIndex=11,
},Main)
corner(14,Header)
mk("Frame",{Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,1,-14),BackgroundColor3=C.panel,BorderSizePixel=0,ZIndex=11},Header)

local HeadGlow = mk("Frame",{
    Size=UDim2.new(1,0,0,2),
    Position=UDim2.new(0,0,1,-2),
    BackgroundColor3=C.gold,
    BorderSizePixel=0,
    ZIndex=13,
},Header)
TweenService:Create(HeadGlow, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {BackgroundColor3=C.orange}):Play()

mk("TextLabel",{
    Size=UDim2.new(0,30,0,30),
    Position=UDim2.new(0,10,0.5,-15),
    BackgroundTransparency=1,
    Text="🪓",
    TextSize=20,
    Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Center,
    ZIndex=12,
},Header)
mk("TextLabel",{
    Size=UDim2.new(0,200,0,20),
    Position=UDim2.new(0,44,0,4),
    BackgroundTransparency=1,
    Text="AXE'S HUB",
    TextColor3=C.goldHi,
    TextSize=14,
    Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left,
    ZIndex=12,
},Header)
mk("TextLabel",{
    Size=UDim2.new(0,200,0,12),
    Position=UDim2.new(0,44,0,26),
    BackgroundTransparency=1,
    Text="Egg Stealer • Pixel Edition",
    TextColor3=C.subtext,
    TextSize=9,
    Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left,
    ZIndex=12,
},Header)

local HeadStat = mk("TextLabel",{
    Size=UDim2.new(0,90,0,14),
    Position=UDim2.new(1,-120,0.5,-7),
    BackgroundTransparency=1,
    Text="0/s",
    TextColor3=C.gold,
    TextSize=9,
    Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Right,
    ZIndex=12,
},Header)

local CloseBtn = mk("TextButton",{
    Size=UDim2.new(0,22,0,22),
    Position=UDim2.new(1,-30,0.5,-11),
    BackgroundColor3=C.red,
    Text="✕",
    TextColor3=Color3.new(1,1,1),
    TextSize=11,
    Font=Enum.Font.GothamBold,
    BorderSizePixel=0,
    ZIndex=13,
},Header)
corner(999,CloseBtn)

makeDraggable(Main, Header)

-- Body
local Body = mk("Frame",{
    Size=UDim2.new(1,-12,1,-52),
    Position=UDim2.new(0,6,0,50),
    BackgroundTransparency=1,
    ZIndex=11,
},Main)
mk("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},Body)

-- Status
local StatusCard = mk("Frame",{
    Size=UDim2.new(1,0,0,34),
    BackgroundColor3=C.card,
    BorderSizePixel=0,
    LayoutOrder=1,
    ZIndex=11,
},Body)
corner(8,StatusCard)
stroke(C.goldDim, 0.8, StatusCard)
local StatusDot = mk("Frame",{
    Size=UDim2.new(0,8,0,8),
    Position=UDim2.new(0,10,0.5,-4),
    BackgroundColor3=C.subtext,
    BorderSizePixel=0,
    ZIndex=12,
},StatusCard)
corner(999,StatusDot)
local StatusTxt = mk("TextLabel",{
    Size=UDim2.new(1,-28,1,0),
    Position=UDim2.new(0,24,0,0),
    BackgroundTransparency=1,
    Text="Ready",
    TextColor3=C.text,
    TextSize=10,
    Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left,
    ZIndex=12,
},StatusCard)

local function setStatus(txt, dotColor)
    StatusTxt.Text = txt
    StatusDot.BackgroundColor3 = dotColor or C.subtext
end

-- Stats
local StatsCard = mk("Frame",{
    Size=UDim2.new(1,0,0,46),
    BackgroundColor3=C.card,
    BorderSizePixel=0,
    LayoutOrder=2,
    ZIndex=11,
},Body)
corner(8,StatsCard)
stroke(C.goldDim, 0.8, StatsCard)
pad(8,8,4,4,StatsCard)

local function makeStat(parent, xOff, label, col)
    local f = mk("Frame",{
        Size=UDim2.new(0,0.33,1,0),
        Position=UDim2.new(xOff,0,0,0),
        BackgroundTransparency=1,
        ZIndex=12,
    },parent)
    local val = mk("TextLabel",{
        Size=UDim2.new(1,0,0,18),
        Position=UDim2.new(0,0,0,2),
        BackgroundTransparency=1,
        Text="0",
        TextColor3=col,
        TextSize=13,
        Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Center,
        ZIndex=13,
    },f)
    mk("TextLabel",{
        Size=UDim2.new(1,0,0,12),
        Position=UDim2.new(0,0,0,24),
        BackgroundTransparency=1,
        Text=label,
        TextColor3=C.subtext,
        TextSize=8,
        Font=Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Center,
        ZIndex=13,
    },f)
    return val
end

local StatRate    = makeStat(StatsCard, 0,    "SCAN/S", C.gold)
local StatEggs    = makeStat(StatsCard, 0.33, "EGGS",   C.goldHi)
local StatElapsed = makeStat(StatsCard, 0.66, "UPTIME", C.green)

-- Hold button
local HoldCard = mk("Frame",{
    Size=UDim2.new(1,0,0,52),
    BackgroundColor3=C.card,
    BorderSizePixel=0,
    LayoutOrder=3,
    ZIndex=11,
},Body)
corner(8,HoldCard)
stroke(C.purple, 0.8, HoldCard)
pad(8,8,6,6,HoldCard)
mk("TextLabel",{
    Size=UDim2.new(1,0,0,12),
    BackgroundTransparency=1,
    Text="👑 ADMIN ABUSE",
    TextColor3=C.subtext,
    TextSize=9,
    Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left,
    ZIndex=12,
},HoldCard)
local HoldBtn = mk("TextButton",{
    Size=UDim2.new(1,0,0,28),
    Position=UDim2.new(0,0,0,16),
    BackgroundColor3=C.purple,
    Text="👑  HOLD LONGEST  —  START",
    TextColor3=Color3.new(1,1,1),
    TextSize=11,
    Font=Enum.Font.GothamBold,
    BorderSizePixel=0,
    ZIndex=12,
},HoldCard)
corner(8,HoldBtn)
stroke(Color3.fromRGB(220,150,255), 1, HoldBtn)

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

-- Filter card
local FilterCard = mk("Frame",{
    Size=UDim2.new(1,0,0,66),
    BackgroundColor3=C.card,
    BorderSizePixel=0,
    LayoutOrder=4,
    ZIndex=11,
},Body)
corner(8,FilterCard)
stroke(C.goldDim, 0.8, FilterCard)
pad(8,8,4,4,FilterCard)
mk("TextLabel",{
    Size=UDim2.new(1,0,0,12),
    BackgroundTransparency=1,
    Text="⚡ FILTER RARITY",
    TextColor3=C.subtext,
    TextSize=9,
    Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left,
    ZIndex=12,
},FilterCard)

local FR1 = mk("Frame",{Size=UDim2.new(1,0,0,22),Position=UDim2.new(0,0,0,16),BackgroundTransparency=1,ZIndex=12},FilterCard)
mk("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,4),VerticalAlignment=Enum.VerticalAlignment.Center},FR1)
local FR2 = mk("Frame",{Size=UDim2.new(1,0,0,22),Position=UDim2.new(0,0,0,40),BackgroundTransparency=1,ZIndex=12},FilterCard)
mk("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,4),VerticalAlignment=Enum.VerticalAlignment.Center},FR2)

local FILTER_DATA = {
    {name="Divine",   emoji="🟨", row=FR1},
    {name="Eternal",  emoji="🌌", row=FR1},
    {name="Secret",   emoji="⬛", row=FR1},
    {name="Cosmic",   emoji="🟪", row=FR2},
    {name="Legendary",emoji="🔶", row=FR2},
    {name="Epic",     emoji="🔷", row=FR2},
}
for _,fd in ipairs(FILTER_DATA) do
    local rd = getRD(fd.name)
    local fb = mk("TextButton",{
        Size=UDim2.new(0,74,0,20),
        BackgroundColor3=rd.color,
        Text=fd.emoji.." "..fd.name,
        TextColor3=Color3.new(1,1,1),
        TextSize=9,
        Font=Enum.Font.GothamBold,
        BorderSizePixel=0,
        ZIndex=13,
    },fd.row)
    corner(6,fb)
    fb.MouseButton1Click:Connect(function()
        State.selectedRar[fd.name] = not State.selectedRar[fd.name]
        fb.BackgroundTransparency = State.selectedRar[fd.name] and 0 or 0.65
        fb.TextTransparency       = State.selectedRar[fd.name] and 0 or 0.4
    end)
end

-- Toggles
local function makeToggle(parent, xOff, label, accentColor)
    local frame = mk("Frame",{
        Size=UDim2.new(0,166,0,42),
        Position=UDim2.new(0,xOff,0,0),
        BackgroundTransparency=1,
        ZIndex=12,
    },parent)
    local track = mk("Frame",{
        Size=UDim2.new(0,42,0,20),
        Position=UDim2.new(0,8,0.5,-10),
        BackgroundColor3=Color3.fromRGB(50,42,26),
        BorderSizePixel=0,
        ZIndex=13,
    },frame)
    corner(999,track); stroke(accentColor,1,track)
    local thumb = mk("Frame",{
        Size=UDim2.new(0,16,0,16),
        Position=UDim2.new(0,2,0.5,-8),
        BackgroundColor3=C.subtext,
        BorderSizePixel=0,
        ZIndex=14,
    },track)
    corner(999,thumb)
    mk("TextLabel",{
        Size=UDim2.new(0,110,0,20),
        Position=UDim2.new(0,54,0.5,-10),
        BackgroundTransparency=1,
        Text=label,
        TextColor3=C.text,
        TextSize=10,
        Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Left,
        ZIndex=13,
    },frame)
    local togBtn = mk("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=15},frame)
    local on = false
    local function setOn(v)
        on = v
        local goal = v and UDim2.new(0,24,0.5,-8) or UDim2.new(0,2,0.5,-8)
        TweenService:Create(thumb,TweenInfo.new(0.15),{Position=goal,BackgroundColor3=v and accentColor or C.subtext}):Play()
        TweenService:Create(track,TweenInfo.new(0.15),{BackgroundColor3=v and Color3.fromRGB(50,42,26) or Color3.fromRGB(30,26,18)}):Play()
    end
    togBtn.MouseButton1Click:Connect(function() setOn(not on) end)
    return togBtn, function() return on end, setOn
end

local CtrlCard = mk("Frame",{
    Size=UDim2.new(1,0,0,42),
    BackgroundColor3=C.card,
    BorderSizePixel=0,
    LayoutOrder=5,
    ZIndex=11,
},Body)
corner(8,CtrlCard)
stroke(C.goldDim, 0.8, CtrlCard)

local getAutoOn, setAutoOn, getOnceOn, setOnceOn
do
    local _,g1,s1 = makeToggle(CtrlCard,0,"Auto Steal",C.gold)
    getAutoOn, setAutoOn = g1, s1
    local _,g2,s2 = makeToggle(CtrlCard,180,"Steal Once",C.orange)
    getOnceOn, setOnceOn = g2, s2
end

-- List card
local ListCard = mk("Frame",{
    Size=UDim2.new(1,0,0,220),
    BackgroundColor3=C.card,
    BorderSizePixel=0,
    LayoutOrder=6,
    ZIndex=11,
},Body)
corner(8,ListCard)
stroke(C.goldDim, 0.8, ListCard)

local ListHeader = mk("Frame",{
    Size=UDim2.new(1,0,0,22),
    BackgroundColor3=C.cardHi,
    BorderSizePixel=0,
    ZIndex=12,
},ListCard)
corner(8,ListHeader)
mk("Frame",{
    Size=UDim2.new(1,0,0,8),
    Position=UDim2.new(0,0,1,-8),
    BackgroundColor3=C.cardHi,
    BorderSizePixel=0,
    ZIndex=12,
},ListHeader)
mk("TextLabel",{
    Size=UDim2.new(0.5,0,1,0),
    Position=UDim2.new(0,8,0,0),
    BackgroundTransparency=1,
    Text="🌍 ALL MAP EGGS",
    TextColor3=C.subtext,
    TextSize=9,
    Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left,
    ZIndex=13,
},ListHeader)
local EggCountLbl = mk("TextLabel",{
    Size=UDim2.new(0.5,0,1,0),
    Position=UDim2.new(0.5,0,0,0),
    BackgroundTransparency=1,
    Text="0 found",
    TextColor3=C.gold,
    TextSize=9,
    Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Right,
    ZIndex=13,
},ListHeader)
pad(0,8,0,0,EggCountLbl)

local Scroll = mk("ScrollingFrame",{
    Size=UDim2.new(1,-6,1,-26),
    Position=UDim2.new(0,3,0,24),
    BackgroundTransparency=1,
    BorderSizePixel=0,
    ScrollBarThickness=2,
    ScrollBarImageColor3=C.gold,
    CanvasSize=UDim2.new(0,0,0,0),
    AutomaticCanvasSize=Enum.AutomaticSize.Y,
    ZIndex=12,
},ListCard)
mk("UIListLayout",{Padding=UDim.new(0,3),SortOrder=Enum.SortOrder.LayoutOrder},Scroll)
pad(2,2,2,2,Scroll)

local function buildRow(data, idx)
    local rd = getRD(data.rarity)
    local row = mk("TextButton",{
        Size=UDim2.new(1,-2,0,44),
        BackgroundColor3=Color3.fromRGB(28,24,16),
        BorderSizePixel=0,
        Text="",
        LayoutOrder=idx,
        ZIndex=13,
    },Scroll)
    corner(7,row)
    stroke(rd.color, 0.6, row)
    row.MouseEnter:Connect(function()
        TweenService:Create(row,TweenInfo.new(0.12),{BackgroundColor3=Color3.fromRGB(44,38,24)}):Play()
    end)
    row.MouseLeave:Connect(function()
        TweenService:Create(row,TweenInfo.new(0.12),{BackgroundColor3=Color3.fromRGB(28,24,16)}):Play()
    end)

    local stripe = mk("Frame",{
        Size=UDim2.new(0,3,1,-6),
        Position=UDim2.new(0,3,0,3),
        BackgroundColor3=rd.color,
        BorderSizePixel=0,
        ZIndex=14,
    },row)
    corner(3,stripe)

    mk("TextLabel",{
        Size=UDim2.new(0,22,0,22),
        Position=UDim2.new(0,9,0.5,-11),
        BackgroundTransparency=1,
        Text=rd.emoji,
        TextSize=14,
        Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Center,
        ZIndex=14,
    },row)

    mk("TextLabel",{
        Size=UDim2.new(1,-108,0,14),
        Position=UDim2.new(0,34,0,5),
        BackgroundTransparency=1,
        Text=data.pet,
        TextColor3=C.text,
        TextSize=11,
        Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd,
        ZIndex=14,
    },row)

    mk("TextLabel",{
        Size=UDim2.new(1,-108,0,10),
        Position=UDim2.new(0,34,0,19),
        BackgroundTransparency=1,
        Text=data.rarity.." • "..data.region.." • score "..tostring(data.score),
        TextColor3=rd.color,
        TextSize=8,
        Font=Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd,
        ZIndex=14,
    },row)

    local etaTxt = data.eta < 1 and string.format("%.2fs", data.eta) or string.format("%.1fs", data.eta)
    mk("TextLabel",{
        Size=UDim2.new(1,-108,0,10),
        Position=UDim2.new(0,34,0,30),
        BackgroundTransparency=1,
        Text=data.dist.." studs • ETA "..etaTxt,
        TextColor3=C.subtext,
        TextSize=8,
        Font=Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Left,
        ZIndex=14,
    },row)

    local stBtn = mk("TextButton",{
        Size=UDim2.new(0,50,0,24),
        Position=UDim2.new(1,-56,0.5,-12),
        BackgroundColor3=C.gold,
        Text="STEAL",
        TextColor3=C.bg,
        TextSize=9,
        Font=Enum.Font.GothamBold,
        BorderSizePixel=0,
        ZIndex=15,
    },row)
    corner(6,stBtn)
    stroke(C.goldHi, 0.6, stBtn)
    stBtn.MouseEnter:Connect(function() TweenService:Create(stBtn,TweenInfo.new(0.1),{BackgroundColor3=C.goldHi}):Play() end)
    stBtn.MouseLeave:Connect(function() TweenService:Create(stBtn,TweenInfo.new(0.1),{BackgroundColor3=C.gold}):Play() end)

    stBtn.MouseButton1Click:Connect(function()
        if State.stealing then return end
        State.stealing = true
        setStatus("🪓 → "..data.pet, C.gold)
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
        mk("TextLabel",{
            Size=UDim2.new(1,0,0,30),
            BackgroundTransparency=1,
            Text="No eggs matching filter",
            TextColor3=C.subtext,
            TextSize=10,
            Font=Enum.Font.Gotham,
            TextXAlignment=Enum.TextXAlignment.Center,
            ZIndex=13,
        },Scroll)
    end
end

-- // Auto steal tick
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
                setStatus("🪓 [ONCE] → "..target.pet, C.gold)
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
        setStatus("🪓 Auto → "..target.pet.." ["..target.rarity.."]", C.gold)
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

-- Logo click toggle
do
    local LogoBtn = mk("TextButton",{
        Size=UDim2.new(1,0,1,0),
        BackgroundTransparency=1,
        Text="",
        ZIndex=51,
    },LogoOuter)
    local downAt
    LogoBtn.MouseButton1Down:Connect(function()
        downAt = UserInputService:GetMouseLocation()
    end)
    LogoBtn.MouseButton1Up:Connect(function()
        local cur = UserInputService:GetMouseLocation()
        if downAt and (cur - downAt).Magnitude < 6 then
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
    cancelFly()
    if holdActive then pcall(stopHoldLongest) end
    if rideWeld then pcall(function() rideWeld:Destroy(); rideWeld = nil end) end
    setStatus("🔄 Respawned — ready", C.subtext)
end)

print("🪓 AXE'S HUB v1 — Executor-safe. Click the axe logo!")