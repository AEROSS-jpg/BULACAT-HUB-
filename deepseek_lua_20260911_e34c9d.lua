-- // ============================================================
-- // ⚡ GNS HUB v4.1 — FULL FIX (Nono Edition)
-- // Game: Steal An Egg
-- // Executor: KRNL / Synapse X / Fluxus / Delta
-- // FIXES v4.1 (only the requested changes):
-- //   ✅ Smooth physics flight (LinearVelocity) — no more teleport look
-- //   ✅ 4-phase loop: center → egg → steal → back
-- //   ✅ Monster ride on RETURN leg (not after)
-- //   ✅ God mode enforced during every phase — no dying, no backing
-- //   ✅ Egg-drop watcher — auto re-steals when egg respawns
-- //   ✅ Everything else preserved from v4
-- // ============================================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local LocalPlayer      = Players.LocalPlayer

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

-- ─────────────────────────────────────────────────────────────
-- COLORS
-- ─────────────────────────────────────────────────────────────
local C = {
    bg       = Color3.fromRGB(6, 8, 18),
    sidebar  = Color3.fromRGB(10, 12, 24),
    panel    = Color3.fromRGB(14, 17, 34),
    card     = Color3.fromRGB(18, 22, 44),
    accent   = Color3.fromRGB(50, 130, 255),
    accentHi = Color3.fromRGB(110, 185, 255),
    accentDim= Color3.fromRGB(25, 60, 150),
    text     = Color3.fromRGB(225, 232, 250),
    subtext  = Color3.fromRGB(115, 132, 172),
    dim      = Color3.fromRGB(60, 75, 110),
    green    = Color3.fromRGB(55, 225, 130),
    red      = Color3.fromRGB(255, 65, 65),
    gold     = Color3.fromRGB(255, 210, 50),
    purple   = Color3.fromRGB(160, 75, 255),
    cyan     = Color3.fromRGB(0, 220, 255),
    pink     = Color3.fromRGB(255, 80, 180),
    border   = Color3.fromRGB(28, 34, 62),
}

-- ─────────────────────────────────────────────────────────────
-- RARITY TABLE
-- ─────────────────────────────────────────────────────────────
local RARITY_DATA = {
    {name="Cosmic",    color=Color3.fromRGB(160,80,255),  rank=1,  emoji=""},
    {name="Divine",    color=Color3.fromRGB(255,215,0),   rank=2,  emoji=""},
    {name="Eternal",   color=Color3.fromRGB(200,50,255),  rank=3,  emoji=""},
    {name="Secret",    color=Color3.fromRGB(255,55,55),   rank=4,  emoji=""},
    {name="Mythic",    color=Color3.fromRGB(255,135,0),   rank=5,  emoji=""},
    {name="Legendary", color=Color3.fromRGB(255,200,0),   rank=6,  emoji=""},
    {name="Epic",      color=Color3.fromRGB(130,0,255),   rank=7,  emoji=""},
    {name="Rare",      color=Color3.fromRGB(0,120,255),   rank=8,  emoji=""},
    {name="Uncommon",  color=Color3.fromRGB(0,200,80),    rank=9,  emoji=""},
    {name="Common",    color=Color3.fromRGB(155,155,155), rank=10, emoji=""},
}
local RARITY_MAP = {}
for _,r in ipairs(RARITY_DATA) do RARITY_MAP[r.name] = r end
local function getRD(n) return RARITY_MAP[n] or RARITY_MAP["Common"] end

-- ─────────────────────────────────────────────────────────────
-- RARITY PREDICTION
-- ─────────────────────────────────────────────────────────────
local RAR_KEYS = {
    {"cosmic","Cosmic"},{"divine","Divine"},{"eternal","Eternal"},
    {"secret","Secret"},{"mythic","Mythic"},{"legendary","Legendary"},
    {"epic","Epic"},{"rare","Rare"},{"uncommon","Uncommon"},
}
local function matchRarity(s)
    if not s or s == "" then return nil end
    local low = s:lower()
    for _,pair in ipairs(RAR_KEYS) do
        if low:find(pair[1],1,true) then return pair[2] end
    end
    return nil
end
local function predictRarity(obj)
    local hit = matchRarity(obj.Name)
    if hit then return hit end
    if obj.Parent then
        hit = matchRarity(obj.Parent.Name)
        if hit then return hit end
        if obj.Parent.Parent then
            hit = matchRarity(obj.Parent.Parent.Name)
            if hit then return hit end
        end
    end
    for _,v in ipairs(obj:GetDescendants()) do
        if v:IsA("StringValue") then
            hit = matchRarity(v.Name) or matchRarity(v.Value)
            if hit then return hit end
        elseif v:IsA("TextLabel") or v:IsA("TextButton") then
            hit = matchRarity(v.Text)
            if hit then return hit end
        elseif v:IsA("IntValue") and v.Name:lower():find("rar") then
            local m={"Cosmic","Divine","Eternal","Secret","Mythic","Legendary","Epic","Rare","Uncommon","Common"}
            if m[v.Value] then return m[v.Value] end
        end
    end
    local ok,attrs = pcall(function() return obj:GetAttributes() end)
    if ok and attrs then
        for k,val in pairs(attrs) do
            hit = matchRarity(tostring(k)) or matchRarity(tostring(val))
            if hit then return hit end
        end
    end
    if obj.Parent then
        for _,sib in ipairs(obj.Parent:GetChildren()) do
            if sib ~= obj then
                hit = matchRarity(sib.Name)
                if hit then return hit end
                if sib:IsA("StringValue") then
                    hit = matchRarity(sib.Value)
                    if hit then return hit end
                end
            end
        end
    end
    return "Common"
end

-- ─────────────────────────────────────────────────────────────
-- PET PREDICTION
-- ─────────────────────────────────────────────────────────────
local PET_KEYS = {"pet","reward","hatch","item","name","prize","animal","give","drop","contain","unlock","creature"}

local function looksLikePetName(s)
    if not s or #s < 2 or #s > 50 then return false end
    local low = s:lower()
    if low:find("click") or low:find("press") or low:find("open")
    or low:find("buy")   or low:find("steal") or low:find("collect")
    or low:find("touch") or low:find("hold")  or low:find("cost")
    or low:find("timer") or low:find("price") then return false end
    for _,pair in ipairs(RAR_KEYS) do if low == pair[1] then return false end end
    if low:match("^%d") then return false end
    return true
end

local function predictPet(obj)
    for _,v in ipairs(obj:GetDescendants()) do
        if v:IsA("StringValue") and v.Value ~= "" then
            local nl = v.Name:lower()
            for _,k in ipairs(PET_KEYS) do
                if nl:find(k,1,true) and looksLikePetName(v.Value) then
                    return v.Value
                end
            end
        end
    end
    for _,v in ipairs(obj:GetDescendants()) do
        if v:IsA("BillboardGui") then
            for _,lbl in ipairs(v:GetDescendants()) do
                if lbl:IsA("TextLabel") and looksLikePetName(lbl.Text) then
                    return lbl.Text
                end
            end
        end
    end
    for _,v in ipairs(obj:GetDescendants()) do
        if (v:IsA("TextLabel") or v:IsA("TextButton")) and v.Text ~= "" then
            if looksLikePetName(v.Text) then return v.Text end
        end
    end
    local ok,attrs = pcall(function() return obj:GetAttributes() end)
    if ok and attrs then
        for k,val in pairs(attrs) do
            local kl = k:lower()
            for _,pk in ipairs(PET_KEYS) do
                if kl:find(pk,1,true) then
                    local sv = tostring(val)
                    if looksLikePetName(sv) then return sv end
                end
            end
        end
    end
    if obj.Parent then
        for _,sib in ipairs(obj.Parent:GetChildren()) do
            if sib:IsA("StringValue") and sib.Value ~= "" then
                local nl = sib.Name:lower()
                for _,k in ipairs(PET_KEYS) do
                    if nl:find(k,1,true) and looksLikePetName(sib.Value) then
                        return sib.Value
                    end
                end
            end
        end
    end
    local stripped = obj.Name
        :gsub("[Ee][Gg][Gg]","")
        :gsub("[Ss]pawn","")
        :gsub("[Pp]art","")
        :gsub("_"," ")
        :match("^%s*(.-)%s*$")
    if stripped and #stripped > 1 then return stripped .. " Pet" end
    return "Mystery Pet"
end

local function getEggName(obj)
    local n = obj.Name
    if obj.Parent and obj.Parent:IsA("Model") then
        n = obj.Parent.Name
    end
    n = n:gsub("_"," "):gsub("(%l)(%u)","%1 %2")
    return n
end

-- ─────────────────────────────────────────────────────────────
-- MONEY/s PREDICTION
-- ─────────────────────────────────────────────────────────────
local MONEY_KEYS = {"coin","cash","money","earn","value","worth","reward","gold","gem","currency","income","profit","rate","per","credit"}
local function predictMoney(obj)
    local best = 0
    local function checkNum(nm,val)
        if val <= 0 or val > 1e12 then return end
        local nl = nm:lower()
        for _,k in ipairs(MONEY_KEYS) do
            if nl:find(k,1,true) and val > best then best = val end
        end
    end
    for _,v in ipairs(obj:GetDescendants()) do
        if v:IsA("NumberValue") or v:IsA("IntValue") then
            pcall(checkNum, v.Name, v.Value)
        end
    end
    local ok,attrs = pcall(function() return obj:GetAttributes() end)
    if ok and attrs then
        for k,val in pairs(attrs) do
            if type(val)=="number" then pcall(checkNum,k,val) end
        end
    end
    if best <= 0 then return "" end
    if best >= 1e9 then return string.format("%.1fB/s",best/1e9) end
    if best >= 1e6 then return string.format("%.1fM/s",best/1e6) end
    if best >= 1e3 then return string.format("%.1fK/s",best/1e3) end
    return tostring(math.floor(best)).."/s"
end

-- ─────────────────────────────────────────────────────────────
-- LINE CENTER (home position)
-- ─────────────────────────────────────────────────────────────
local lineCenterCache = nil
local function findLineCenter()
    if lineCenterCache then return lineCenterCache end
    local root = getRoot()
    if not root then return nil end
    local keywords = {"line","start","spawn","center","queue","waiting","begin","base","home"}
    local best, bd = nil, math.huge
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local nm = obj.Name:lower()
            for _,kw in ipairs(keywords) do
                if nm:find(kw,1,true) then
                    local d = (root.Position - obj.Position).Magnitude
                    if d < bd then bd=d; best=obj end
                    break
                end
            end
        end
    end
    if best then
        lineCenterCache = best.Position + Vector3.new(0,3,0)
        return lineCenterCache
    end
    return root.Position
end

-- ─────────────────────────────────────────────────────────────
-- EGG SCANNER
-- ─────────────────────────────────────────────────────────────
local function getEggPart(obj)
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then
        if obj.PrimaryPart then return obj.PrimaryPart end
        return obj:FindFirstChildOfClass("BasePart")
    end
    return nil
end

local function scanAllEggs()
    local root = getRoot()
    if not root then return {} end
    local found,seenModel = {},{}
    local function tryAdd(obj)
        local key = (obj.Parent and (obj.Parent:IsA("Model") or obj.Parent:IsA("Folder")))
            and obj.Parent or obj
        if seenModel[key] then return end
        seenModel[key] = true
        seenModel[obj]  = true
        local part = getEggPart(obj)
        if not part then return end
        local pos = part.Position
        table.insert(found,{
            obj    = obj,
            part   = part,
            rarity = predictRarity(obj),
            pet    = predictPet(obj),
            money  = predictMoney(obj),
            dist   = math.floor((root.Position-pos).Magnitude),
            pos    = pos,
            name   = getEggName(obj),
        })
    end
    local function recurse(parent)
        local ok,children = pcall(function() return parent:GetChildren() end)
        if not ok then return end
        for _,obj in ipairs(children) do
            if not seenModel[obj] then
                local nm = obj.Name:lower()
                if nm:find("egg",1,true) then tryAdd(obj) end
                if obj:IsA("Model") or obj:IsA("Folder") or obj:IsA("Configuration") then
                    recurse(obj)
                end
            end
        end
    end
    recurse(workspace)
    table.sort(found,function(a,b)
        local ra=getRD(a.rarity).rank
        local rb=getRD(b.rarity).rank
        if ra~=rb then return ra<rb end
        return a.dist<b.dist
    end)
    return found
end

-- ─────────────────────────────────────────────────────────────
-- GOD MODE — Heartbeat-enforced, truly unkillable
-- ─────────────────────────────────────────────────────────────
local godHBConn  = nil
local godDmgConn = nil
local godActive  = false

local function enableGodMode()
    if godActive then return end
    godActive = true
    pcall(function()
        local hum  = getHuman()
        local char = getChar()
        if not hum then return end
        hum.MaxHealth = math.huge
        hum.Health    = math.huge
        if godDmgConn then godDmgConn:Disconnect() end
        godDmgConn = hum.HealthChanged:Connect(function(hp)
            pcall(function()
                if godActive and hp < math.huge then hum.Health = math.huge end
            end)
        end)
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead,        false) end)
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown,  false) end)
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,      false) end)
        if char then
            for _,p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then pcall(function() p.CanCollide=false end) end
            end
        end
    end)
    if godHBConn then godHBConn:Disconnect() end
    godHBConn = RunService.Heartbeat:Connect(function()
        if not godActive then return end
        pcall(function()
            local hum = getHuman()
            if not hum then return end
            if hum.Health < math.huge then hum.Health = math.huge end
            hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        end)
    end)
end

local function disableGodMode()
    godActive = false
    if godHBConn  then godHBConn:Disconnect()  godHBConn  = nil end
    if godDmgConn then godDmgConn:Disconnect() godDmgConn = nil end
    pcall(function()
        local hum  = getHuman()
        local char = getChar()
        if not hum then return end
        hum.MaxHealth = 100
        hum.Health    = 100
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead,        true) end)
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown,  true) end)
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,      true) end)
        if char then
            for _,p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then pcall(function() p.CanCollide=true end) end
            end
        end
    end)
end

-- ─────────────────────────────────────────────────────────────
-- SMOOTH PHYSICS FLIGHT  ← NEW (replaces CFrame snap for steal)
-- Uses LinearVelocity so Roblox physics eases accel/decel = "running"
-- ─────────────────────────────────────────────────────────────
local flyConn = nil
local flyLV   = nil
local flyBG   = nil
local flyAtt  = nil
local isFly   = false

local function stopFly()
    isFly = false
    if flyConn then flyConn:Disconnect() flyConn = nil end
    pcall(function() if flyLV  then flyLV:Destroy()  flyLV  = nil end end)
    pcall(function() if flyBG  then flyBG:Destroy()  flyBG  = nil end end)
    pcall(function() if flyAtt then flyAtt:Destroy() flyAtt = nil end end)
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

    -- Attachment + LinearVelocity = smooth physics glide
    flyAtt = Instance.new("Attachment")
    flyAtt.Parent = root

    flyLV = Instance.new("LinearVelocity")
    flyLV.MaxForce          = 1e6
    flyLV.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    flyLV.ForceLimitMode    = Enum.ForceLimitMode.Magnitude
    flyLV.RelativeTo        = Enum.ActuatorRelativeTo.World
    flyLV.Attachment0       = flyAtt
    flyLV.VectorVelocity    = Vector3.new(0,0,0)
    flyLV.Parent            = root

    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1e9,1e9,1e9)
    flyBG.P         = 1e6
    flyBG.D         = 800
    flyBG.CFrame    = CFrame.new(root.Position, targetPos)
    flyBG.Parent    = root

    local arrived = false
    flyConn = RunService.Heartbeat:Connect(function()
        if not isFly then return end
        local r = getRoot()
        if not r or not flyLV or not flyBG then stopFly() return end

        local diff = targetPos - r.Position
        local dist = diff.Magnitude

        if not arrived and dist < 3.5 then
            arrived = true
            flyLV.VectorVelocity = Vector3.new(0,0,0)
            isFly = false
            if flyConn then flyConn:Disconnect() flyConn = nil end
            task.spawn(function()
                task.wait(0.02)
                pcall(function() if flyLV  then flyLV:Destroy()  flyLV  = nil end end)
                pcall(function() if flyBG  then flyBG:Destroy()  flyBG  = nil end end)
                pcall(function() if flyAtt then flyAtt:Destroy() flyAtt = nil end end)
                if onDone then task.spawn(onDone) end
            end)
            return
        end
        if not arrived then
            local spd = math.clamp(dist*8, 60, speed or 320)
            flyLV.VectorVelocity = diff.Unit * spd
            flyBG.CFrame = CFrame.new(r.Position, r.Position + diff.Unit)
        end
    end)
end

-- ─────────────────────────────────────────────────────────────
-- HOLD LONGEST (unchanged — uses flyTo above)
-- ─────────────────────────────────────────────────────────────
local holdActive = false
local holdConn   = nil
local holdBP     = nil
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
    local h = getHuman()
    if h then h.PlatformStand = true end
    local skyPos = root.Position + Vector3.new(0,300,0)
    flyTo(skyPos, 350, function()
        local r2 = getRoot()
        if not r2 or not holdActive then return end
        holdBP = Instance.new("BodyPosition")
        holdBP.MaxForce = Vector3.new(1e9,1e9,1e9)
        holdBP.P        = 1e5
        holdBP.D        = 1e4
        holdBP.Position = r2.Position
        holdBP.Parent   = r2
        holdBG2 = Instance.new("BodyGyro")
        holdBG2.MaxTorque = Vector3.new(1e9,1e9,1e9)
        holdBG2.P         = 1e6
        holdBG2.CFrame    = r2.CFrame
        holdBG2.Parent    = r2
        holdConn = RunService.Heartbeat:Connect(function()
            if not holdActive then return end
            local r3 = getRoot()
            if not r3 then return end
            for _,obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    local nm = obj.Name:lower()
                    if nm:find("hold") or nm:find("zone") or nm:find("claim")
                    or nm:find("admin") or nm:find("platform") or nm:find("longest") then
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

-- ─────────────────────────────────────────────────────────────
-- RIDE MONSTER
-- ─────────────────────────────────────────────────────────────
local rideWeld = nil
local MOUNT_KW = {"mount","monster","creature","ride","mob","boss","npc","dinosaur","animal","miranda","dragon","beast","phoenix"}

local function findNearestMount(fromPos, maxDist)
    maxDist = maxDist or 150
    local best, bd = nil, math.huge
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local isPlayer = false
            for _,plr in ipairs(Players:GetPlayers()) do
                if plr.Character and obj:IsDescendantOf(plr.Character) then
                    isPlayer = true; break
                end
            end
            if not isPlayer then
                local nm = obj.Name:lower()
                for _,kw in ipairs(MOUNT_KW) do
                    if nm:find(kw,1,true) then
                        local d = (fromPos - obj.Position).Magnitude
                        if d < bd and d < maxDist then bd=d; best=obj end
                        break
                    end
                end
            end
        end
    end
    return best
end

local function rideBack(targetMount)
    if rideWeld then pcall(function() rideWeld:Destroy() end) rideWeld = nil end
    local root = getRoot()
    if not root then return end
    local mount = targetMount or findNearestMount(root.Position, 150)
    if mount and mount.Parent then
        -- smooth fly to seat position
        local seat = mount.Position + Vector3.new(0, mount.Size.Y/2 + 3.5, 0)
        flyTo(seat, 600, function()
            local r = getRoot()
            if not r then return end
            pcall(function()
                local w = Instance.new("WeldConstraint")
                w.Part0  = r
                w.Part1  = mount
                w.Parent = r
                rideWeld = w
            end)
            task.delay(6, function()
                pcall(function() if rideWeld then rideWeld:Destroy() rideWeld = nil end end)
            end)
        end)
    else
        pcall(function()
            local hum = getHuman()
            if not hum then return end
            local prev = hum.WalkSpeed
            hum.WalkSpeed = 80
            task.delay(4, function() pcall(function() hum.WalkSpeed = prev end) end)
        end)
    end
end

-- ─────────────────────────────────────────────────────────────
-- FIRE ALL INTERACTIONS
-- ─────────────────────────────────────────────────────────────
local function fireAllInteractions(obj, root)
    pcall(function()
        local tt = obj:FindFirstChildOfClass("TouchTransmitter")
        if tt then
            firetouchinterest(root, obj, 0)
            task.wait(0.03)
            firetouchinterest(root, obj, 1)
            task.wait(0.03)
            firetouchinterest(root, obj, 0)
        end
    end)
    pcall(function()
        local cl = obj:FindFirstChildOfClass("ClickDetector")
            or (obj.Parent and obj.Parent:FindFirstChildOfClass("ClickDetector"))
        if cl then fireclickdetector(cl) end
    end)
    pcall(function()
        local pr = obj:FindFirstChildOfClass("ProximityPrompt")
            or (obj.Parent and obj.Parent:FindFirstChildOfClass("ProximityPrompt"))
        if pr then fireproximityprompt(pr) end
    end)
    for _,child in ipairs(obj:GetDescendants()) do
        pcall(function()
            local ct = child:FindFirstChildOfClass("TouchTransmitter")
            if ct then
                firetouchinterest(root, child, 0)
                task.wait(0.02)
                firetouchinterest(root, child, 1)
            end
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
    for _,v in ipairs(workspace:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            local nm = v.Name:lower()
            if nm:find("hatch") or nm:find("collect") or nm:find("open")
            or nm:find("egg")   or nm:find("claim")   or nm:find("steal") then
                pcall(function() v:FireServer() end)
            end
        end
    end
end

-- ─────────────────────────────────────────────────────────────
-- FORWARD DECLARE (so stealEgg can reference togRideMount)
-- ─────────────────────────────────────────────────────────────
local togRideMount = nil

-- ─────────────────────────────────────────────────────────────
-- STEAL EGG v4.1 — 4-PHASE SMOOTH LOOP
--   Phase 1: fly to center (smooth)
--   Phase 2: fly to egg (smooth, 5 studs above)
--   Phase 3: fire all interactions 3x
--   Phase 4: fly back to center, ride monster on return leg
-- ─────────────────────────────────────────────────────────────
local homePos   = nil
local stealBusy = false

local function stealEgg(data, onDone)
    if not data or not data.obj then
        if onDone then onDone(false) end
        return
    end
    if not data.obj.Parent then
        if onDone then onDone(false) end
        return
    end
    if stealBusy then return end
    stealBusy = true

    enableGodMode()

    if not homePos then
        homePos = findLineCenter() or (getRoot() and getRoot().Position)
    end

    local eggPos = data.pos
    local hover  = eggPos + Vector3.new(0, 5, 0)

    -- pre-find the mount BEFORE we start flying (so we don't stall on return)
    local targetMount = findNearestMount(homePos or eggPos, 150)

    -- Phase 1: fly to center
    flyTo(homePos, 420, function()
        -- Phase 2: fly to egg (5 studs above)
        flyTo(hover, 500, function()
            -- Phase 3: fire all interactions
            local root = getRoot()
            if root then
                fireAllInteractions(data.obj, root)
                task.wait(0.06)
                fireAllInteractions(data.obj, root)
                task.wait(0.06)
                fireAllInteractions(data.obj, root)

                if data.obj:IsA("BasePart") and data.obj.Parent and data.obj.Parent:IsA("Model") then
                    fireAllInteractions(data.obj.Parent, root)
                end
            end

            -- Phase 4: fly back to center, ride mount on the way
            flyTo(homePos, 500, function()
                if togRideMount and togRideMount.getOn and togRideMount.getOn() then
                    rideBack(targetMount)
                end
                task.wait(0.1)
                disableGodMode()
                stealBusy = false
                if onDone then onDone(true) end
            end)
        end)
    end)
end

-- ─────────────────────────────────────────────────────────────
-- STATE
-- ─────────────────────────────────────────────────────────────
local State = {
    loopActive  = false,
    stealing    = false,
    eggList     = {},
    selectedRar = {},
    currentTab  = "autoSteal",
    espEnabled  = false,
    lastSteal   = nil,
    stealQueued = false,
}
for _,r in ipairs(RARITY_DATA) do State.selectedRar[r.name] = true end

-- ─────────────────────────────────────────────────────────────
-- DESTROY OLD UI
-- ─────────────────────────────────────────────────────────────
pcall(function()
    for _,name in ipairs({"GNS_HubUI_v4","GNS_HubUI_v3","GNS_HubUI","GNS_HubUI_v41"}) do
        local old = CoreGui:FindFirstChild(name)
        if old then old:Destroy() end
    end
end)

local Screen = Instance.new("ScreenGui")
Screen.Name           = "GNS_HubUI_v41"
Screen.ResetOnSpawn   = false
Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Screen.DisplayOrder   = 999
Screen.IgnoreGuiInset = true
Screen.Parent         = CoreGui

-- ─────────────────────────────────────────────────────────────
-- UI HELPERS
-- ─────────────────────────────────────────────────────────────
local function mk(class, props, parent)
    local i = Instance.new(class)
    for k,v in pairs(props) do i[k] = v end
    if parent then i.Parent = parent end
    return i
end
local function corner(r,p)    mk("UICorner",{CornerRadius=UDim.new(0,r)},p) end
local function uistroke(col,th,p) mk("UIStroke",{Color=col,Thickness=th},p) end
local function pad(l,r,t,b,p)
    local u = Instance.new("UIPadding")
    u.PaddingLeft=UDim.new(0,l); u.PaddingRight=UDim.new(0,r)
    u.PaddingTop=UDim.new(0,t);  u.PaddingBottom=UDim.new(0,b)
    u.Parent = p
end

local function makeDraggable(handle, target)
    local dragging,didDrag,startMouse,startPos = false,false,nil,nil
    local THRESH = 6
    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging=true; didDrag=false
            startMouse=inp.Position; startPos=target.Position
        end
    end)
    handle.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1
        or inp.UserInputType==Enum.UserInputType.Touch then
            dragging=false
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseMovement
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = inp.Position - startMouse
        if delta.Magnitude >= THRESH then didDrag = true end
        if didDrag then
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset+delta.X,
                startPos.Y.Scale, startPos.Y.Offset+delta.Y
            )
        end
    end)
    return function() return didDrag end
end

-- ─────────────────────────────────────────────────────────────
-- ICON / LOGO — animated orbit dots + color-cycling GNS text
-- (kept exactly as v4)
-- ─────────────────────────────────────────────────────────────
local IC = 62
local IconWrap = mk("Frame",{
    Size=UDim2.new(0,IC,0,IC),
    Position=UDim2.new(0,14,0.5,-(IC/2)),
    BackgroundColor3=Color3.fromRGB(6,9,22),
    BorderSizePixel=0, ZIndex=5,
},Screen)
corner(999,IconWrap)
uistroke(C.accent,2,IconWrap)

local shimFrame = mk("Frame",{
    Size=UDim2.new(1,0,0.5,0), Position=UDim2.new(0,0,0,0),
    BackgroundColor3=Color3.fromRGB(255,255,255),
    BackgroundTransparency=0.93, BorderSizePixel=0, ZIndex=6,
},IconWrap)
corner(999,shimFrame)

local pr1 = mk("Frame",{Size=UDim2.new(1,20,1,20),Position=UDim2.new(0,-10,0,-10),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=1},IconWrap)
corner(999,pr1)
local prs1 = mk("UIStroke",{Color=C.accent,Thickness=6},pr1)
prs1.Transparency = 0.55
TweenService:Create(prs1,TweenInfo.new(1.4,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Transparency=0.94}):Play()

local pr2 = mk("Frame",{Size=UDim2.new(1,36,1,36),Position=UDim2.new(0,-18,0,-18),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=1},IconWrap)
corner(999,pr2)
local prs2 = mk("UIStroke",{Color=C.cyan,Thickness=3},pr2)
prs2.Transparency = 0.78
TweenService:Create(prs2,TweenInfo.new(2.4,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Transparency=0.97}):Play()

local orbitDots = {}
local ORBIT_COLORS = {C.accent,C.accentHi,C.cyan,C.gold,C.purple,C.pink,C.green}
for i=1,10 do
    local sz  = math.random(3,6)
    local dot = mk("Frame",{
        Size=UDim2.new(0,sz,0,sz),
        BackgroundColor3=ORBIT_COLORS[(i-1)%#ORBIT_COLORS+1],
        BorderSizePixel=0, ZIndex=20,
        Position=UDim2.new(0,-99,0,-99),
    },Screen)
    corner(999,dot)
    orbitDots[i] = {dot=dot, angle=math.rad((i-1)*36), speed=0.7+math.random()*0.9, r=IC/2+14+math.random()*6, sz=sz}
end

local GNSLabel = mk("TextLabel",{
    Size=UDim2.new(1,0,0,34), Position=UDim2.new(0,0,0,5),
    BackgroundTransparency=1, Text="GNS",
    TextColor3=C.accentHi, TextSize=20,
    Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Center, ZIndex=10,
},IconWrap)
mk("TextLabel",{
    Size=UDim2.new(1,0,0,12), Position=UDim2.new(0,0,1,-14),
    BackgroundTransparency=1, Text="HUB",
    TextColor3=C.subtext, TextSize=8,
    Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Center, ZIndex=10,
},IconWrap)

local gnsColorList = {C.accentHi,C.cyan,C.gold,C.purple,C.pink,C.green}
local gnsIdx = 1
task.spawn(function()
    while task.wait(1.1) do
        gnsIdx = gnsIdx % #gnsColorList + 1
        TweenService:Create(GNSLabel,TweenInfo.new(0.45),{TextColor3=gnsColorList[gnsIdx]}):Play()
        TweenService:Create(prs1,TweenInfo.new(0.45),{Color=gnsColorList[gnsIdx]}):Play()
    end
end)

local IconBtn = mk("TextButton",{
    Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=12,
},IconWrap)
local iconWasDragged = makeDraggable(IconBtn,IconWrap)

local orbitT = 0
RunService.Heartbeat:Connect(function(dt)
    orbitT = orbitT + dt
    local abs = IconWrap.AbsolutePosition
    local cx  = abs.X + IC/2
    local cy  = abs.Y + IC/2
    for _,p in ipairs(orbitDots) do
        local a  = p.angle + orbitT*p.speed
        local px = cx + math.cos(a)*p.r - p.sz/2
        local py = cy + math.sin(a)*p.r - p.sz/2
        p.dot.Position = UDim2.new(0,px,0,py)
        p.dot.BackgroundTransparency = 0.1 + 0.55*math.abs(math.sin(orbitT*1.5+p.angle))
        p.dot.BackgroundColor3 = Color3.fromHSV((orbitT*0.04+p.angle*0.1)%1, 0.88, 1)
    end
end)

-- ─────────────────────────────────────────────────────────────
-- MAIN WINDOW
-- ─────────────────────────────────────────────────────────────
local Window = mk("Frame",{
    Size=UDim2.new(0,880,0,590),
    Position=UDim2.new(0.5,-440,0.5,-295),
    BackgroundColor3=C.bg,
    BorderSizePixel=0, Visible=false,
    ClipsDescendants=true,
},Screen)
corner(16,Window)
uistroke(C.border,1.2,Window)

local topShine = mk("Frame",{
    Size=UDim2.new(0.6,0,0,1), Position=UDim2.new(0.2,0,0,0),
    BackgroundColor3=C.accentHi, BackgroundTransparency=0.4, BorderSizePixel=0,
},Window)
corner(1,topShine)

-- TITLE BAR
local TitleBar = mk("Frame",{
    Size=UDim2.new(1,0,0,44),
    BackgroundColor3=C.sidebar, BorderSizePixel=0,
},Window)
mk("Frame",{Size=UDim2.new(1,0,0,16),Position=UDim2.new(0,0,1,-16),BackgroundColor3=C.sidebar,BorderSizePixel=0},TitleBar)

local function tlight(x,col)
    local f = mk("Frame",{Size=UDim2.new(0,13,0,13),Position=UDim2.new(0,x,0.5,-6),BackgroundColor3=col,BorderSizePixel=0},TitleBar)
    corner(999,f); return f
end
tlight(12, Color3.fromRGB(255,95,87))
tlight(30, Color3.fromRGB(255,189,46))
tlight(48, Color3.fromRGB(40,200,64))

mk("TextLabel",{
    Size=UDim2.new(0,120,1,0), Position=UDim2.new(0,68,0,0),
    BackgroundTransparency=1, Text="GNS HUB v4.1",
    TextColor3=C.accentHi, TextSize=13,
    Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left,
},TitleBar)

local vBadge = mk("Frame",{Size=UDim2.new(0,46,0,20),Position=UDim2.new(0,190,0.5,-10),BackgroundColor3=C.accentDim,BorderSizePixel=0},TitleBar)
corner(6,vBadge)
mk("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="v4.1",TextColor3=C.accentHi,TextSize=10,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center},vBadge)

local TabTitle = mk("TextLabel",{
    Size=UDim2.new(0,220,1,0), Position=UDim2.new(0.5,-110,0,0),
    BackgroundTransparency=1, Text="Auto Steal",
    TextColor3=C.text, TextSize=13,
    Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Center,
},TitleBar)

local liveDot = mk("Frame",{Size=UDim2.new(0,8,0,8),Position=UDim2.new(1,-60,0.5,-4),BackgroundColor3=C.green,BorderSizePixel=0},TitleBar)
corner(999,liveDot)
mk("TextLabel",{Size=UDim2.new(0,44,1,0),Position=UDim2.new(1,-50,0,0),BackgroundTransparency=1,Text="LIVE",TextColor3=C.green,TextSize=9,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},TitleBar)
TweenService:Create(liveDot,TweenInfo.new(0.9,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{BackgroundTransparency=0.7}):Play()

local titleWasDragged = makeDraggable(TitleBar,Window)

-- SIDEBAR
local Sidebar = mk("Frame",{
    Size=UDim2.new(0,215,1,-44), Position=UDim2.new(0,0,0,44),
    BackgroundColor3=C.sidebar, BorderSizePixel=0,
},Window)
mk("Frame",{Size=UDim2.new(0,1,1,0),Position=UDim2.new(1,-1,0,0),BackgroundColor3=C.border,BorderSizePixel=0},Sidebar)

local HubBlock = mk("Frame",{Size=UDim2.new(1,0,0,72),BackgroundColor3=C.panel,BorderSizePixel=0},Sidebar)
pad(14,14,10,10,HubBlock)
mk("TextLabel",{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,Text="GNS Hub",TextColor3=C.accentHi,TextSize=18,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},HubBlock)
mk("TextLabel",{Size=UDim2.new(1,0,0,16),Position=UDim2.new(0,0,0,30),BackgroundTransparency=1,Text="Steal an Egg • v4.1",TextColor3=C.subtext,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},HubBlock)

local SideScroll = mk("ScrollingFrame",{
    Size=UDim2.new(1,0,1,-72), Position=UDim2.new(0,0,0,72),
    BackgroundTransparency=1, BorderSizePixel=0,
    ScrollBarThickness=2, ScrollBarImageColor3=C.accent,
    CanvasSize=UDim2.new(0,0,0,0),
},Sidebar)
mk("UIListLayout",{Padding=UDim.new(0,2),SortOrder=Enum.SortOrder.LayoutOrder},SideScroll)
pad(10,10,8,8,SideScroll)

local function sideHeader(text,order)
    local f = mk("Frame",{Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,LayoutOrder=order},SideScroll)
    local d = mk("Frame",{Size=UDim2.new(0,4,0,4),Position=UDim2.new(0,0,0.5,-2),BackgroundColor3=C.accent,BorderSizePixel=0},f)
    corner(999,d)
    mk("TextLabel",{Size=UDim2.new(1,-12,1,0),Position=UDim2.new(0,12,0,0),BackgroundTransparency=1,Text=text,TextColor3=C.subtext,TextSize=9,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},f)
end

local navBtns       = {}
local ContentFrames = {}

local function sideNav(label,icon,tabId,order)
    local btn = mk("TextButton",{
        Size=UDim2.new(1,0,0,36), BackgroundTransparency=1,
        Text="", BorderSizePixel=0, LayoutOrder=order,
    },SideScroll)
    local activeBg = mk("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=C.card,BackgroundTransparency=1,BorderSizePixel=0},btn)
    corner(10,activeBg)
    local bar = mk("Frame",{Size=UDim2.new(0,3,0,20),Position=UDim2.new(0,0,0.5,-10),BackgroundColor3=C.accent,BorderSizePixel=0,Visible=false},btn)
    corner(999,bar)
    mk("TextLabel",{Size=UDim2.new(0,24,1,0),Position=UDim2.new(0,10,0,0),BackgroundTransparency=1,Text=icon,TextSize=14,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center},btn)
    local lbl = mk("TextLabel",{Size=UDim2.new(1,-40,1,0),Position=UDim2.new(0,38,0,0),BackgroundTransparency=1,Text=label,TextColor3=C.subtext,TextSize=12,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},btn)
    local function setActive(v)
        bar.Visible = v
        lbl.TextColor3 = v and C.text or C.subtext
        lbl.Font = v and Enum.Font.GothamBold or Enum.Font.Gotham
        TweenService:Create(activeBg,TweenInfo.new(0.12),{BackgroundTransparency=v and 0 or 1}):Play()
    end
    btn.MouseButton1Click:Connect(function()
        for _,nb in ipairs(navBtns) do nb.setActive(false) end
        setActive(true)
        for id,cf in pairs(ContentFrames) do cf.Visible=(id==tabId) end
        TabTitle.Text    = label
        State.currentTab = tabId
    end)
    btn.MouseEnter:Connect(function()
        if not bar.Visible then TweenService:Create(activeBg,TweenInfo.new(0.1),{BackgroundTransparency=0.7}):Play() end
    end)
    btn.MouseLeave:Connect(function()
        if not bar.Visible then TweenService:Create(activeBg,TweenInfo.new(0.1),{BackgroundTransparency=1}):Play() end
    end)
    table.insert(navBtns,{setActive=setActive,tabId=tabId})
    return {setActive=setActive}
end

sideHeader("EGGS",1)
local navAutoSteal  = sideNav("Auto Steal",    ">","autoSteal",  2)
local navEggPredict = sideNav("Egg Predictor", "o","eggPredict", 3)
local navEggESP     = sideNav("Egg ESP",       "*","eggESP",     4)
sideHeader("GAMEPLAY",5)
local navTreadmill  = sideNav("Treadmill",     "=","treadmill",  6)
local navRift       = sideNav("The Rift",      "#","rift",       7)
sideHeader("ADMIN ABUSE",8)
local navAdmin      = sideNav("Admin Abuse",   "A","adminAbuse", 9)

-- CONTENT AREA
local ContentArea = mk("Frame",{
    Size=UDim2.new(1,-215,1,-44), Position=UDim2.new(0,215,0,44),
    BackgroundTransparency=1,
},Window)

local function makeContent(id)
    local f = mk("ScrollingFrame",{
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
        BorderSizePixel=0, ScrollBarThickness=3,
        ScrollBarImageColor3=C.accent,
        CanvasSize=UDim2.new(0,0,0,0),
        Visible=false,
    },ContentArea)
    mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},f)
    ContentFrames[id] = f
    return f
end

local function makeSection(parent,title,titleCol,order)
    local wrap = mk("Frame",{
        Size=UDim2.new(1,0,0,0), BackgroundColor3=C.card,
        BorderSizePixel=0, AutomaticSize=Enum.AutomaticSize.Y, LayoutOrder=order,
    },parent)
    local hdr = mk("Frame",{Size=UDim2.new(1,0,0,38),BackgroundColor3=C.panel,BorderSizePixel=0},wrap)
    mk("Frame",{Size=UDim2.new(0,3,0,22),Position=UDim2.new(0,0,0.5,-11),BackgroundColor3=titleCol or C.accent,BorderSizePixel=0},hdr)
    pad(18,16,0,0,hdr)
    mk("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=title,TextColor3=titleCol or C.text,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},hdr)
    local body = mk("Frame",{Size=UDim2.new(1,0,0,0),Position=UDim2.new(0,0,0,38),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},wrap)
    return body
end

local function divLine(parent,lo)
    mk("Frame",{Size=UDim2.new(1,-32,0,1),Position=UDim2.new(0,16,0,0),BackgroundColor3=C.border,BorderSizePixel=0,LayoutOrder=lo or 99},parent)
end

local function makeRowToggle(parent,label,defaultOn,order,accentColor)
    local row = mk("Frame",{Size=UDim2.new(1,0,0,44),BackgroundTransparency=1,LayoutOrder=order},parent)
    pad(16,16,0,0,row)
    mk("TextLabel",{Size=UDim2.new(1,-60,1,0),BackgroundTransparency=1,Text=label,TextColor3=C.text,TextSize=12,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},row)
    local ac    = accentColor or C.accent
    local track = mk("Frame",{
        Size=UDim2.new(0,46,0,24), Position=UDim2.new(1,-46,0.5,-12),
        BackgroundColor3=defaultOn and C.accentDim or Color3.fromRGB(30,36,62),
        BorderSizePixel=0,
    },row)
    corner(999,track)
    uistroke(C.border,1,track)
    local thumb = mk("Frame",{
        Size=UDim2.new(0,18,0,18),
        Position=defaultOn and UDim2.new(0,25,0.5,-9) or UDim2.new(0,3,0.5,-9),
        BackgroundColor3=defaultOn and ac or C.dim,
        BorderSizePixel=0,
    },track)
    corner(999,thumb)
    local togBtn = mk("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=5},track)
    local on = defaultOn or false
    local cbs = {}
    local function setOn(v)
        on = v
        TweenService:Create(thumb,TweenInfo.new(0.15),{
            Position=v and UDim2.new(0,25,0.5,-9) or UDim2.new(0,3,0.5,-9),
            BackgroundColor3=v and ac or C.dim,
        }):Play()
        TweenService:Create(track,TweenInfo.new(0.15),{
            BackgroundColor3=v and C.accentDim or Color3.fromRGB(30,36,62),
        }):Play()
        for _,cb in ipairs(cbs) do pcall(cb,v) end
    end
    togBtn.MouseButton1Click:Connect(function() setOn(not on) end)
    return {setOn=setOn, getOn=function() return on end, onChange=function(cb) table.insert(cbs,cb) end}
end

local function makeRowButton(parent,label,order,col)
    local row = mk("Frame",{Size=UDim2.new(1,0,0,52),BackgroundTransparency=1,LayoutOrder=order},parent)
    pad(16,16,6,6,row)
    local btn = mk("TextButton",{
        Size=UDim2.new(1,0,0,38),
        BackgroundColor3=col or C.accentDim,
        Text=label, TextColor3=Color3.new(1,1,1),
        TextSize=12, Font=Enum.Font.GothamBold, BorderSizePixel=0,
    },row)
    corner(10,btn)
    uistroke(C.accent,1,btn)
    btn.MouseEnter:Connect(function() TweenService:Create(btn,TweenInfo.new(0.1),{BackgroundColor3=C.accent}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn,TweenInfo.new(0.1),{BackgroundColor3=col or C.accentDim}):Play() end)
    return btn
end

-- ─────────────────────────────────────────────────────────────
-- TAB: AUTO STEAL
-- ─────────────────────────────────────────────────────────────
local cfAS   = makeContent("autoSteal")
local asCols = mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1},cfAS)
local asL    = mk("Frame",{Size=UDim2.new(0.42,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},asCols)
mk("Frame",{Size=UDim2.new(0,1,1,0),Position=UDim2.new(0.42,0,0,0),BackgroundColor3=C.border,BorderSizePixel=0},asCols)
local asR    = mk("Frame",{Size=UDim2.new(0.58,-2,0,0),Position=UDim2.new(0.42,2,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},asCols)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},asL)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},asR)

local asLBody = makeSection(asL,"Auto Steal Settings",C.accentHi,1)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},asLBody)
local togAutoSteal = makeRowToggle(asLBody,"Enable Auto Steal",false,1)
divLine(asLBody,2)
local togStealOnce = makeRowToggle(asLBody,"Steal Once Only",false,3)
divLine(asLBody,4)
local togGodMode   = makeRowToggle(asLBody,"God Mode",true,5,C.green)
divLine(asLBody,6)
togRideMount       = makeRowToggle(asLBody,"Ride Mount on Return",true,7,C.purple)
divLine(asLBody,8)

-- rarity filters
local asRarBody = makeSection(asL,"Target Rarities",C.accentHi,2)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},asRarBody)
for i,r in ipairs(RARITY_DATA) do
    local row = mk("Frame",{Size=UDim2.new(1,0,0,38),BackgroundTransparency=1,LayoutOrder=i},asRarBody)
    pad(16,16,0,0,row)
    local dot = mk("Frame",{Size=UDim2.new(0,8,0,8),Position=UDim2.new(0,0,0.5,-4),BackgroundColor3=r.color,BorderSizePixel=0},row)
    corner(999,dot)
    mk("TextLabel",{
        Size=UDim2.new(1,-62,1,0), Position=UDim2.new(0,14,0,0),
        BackgroundTransparency=1, Text=r.name,
        TextColor3=r.color, TextSize=12,
        Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left,
    },row)
    local track2 = mk("Frame",{
        Size=UDim2.new(0,46,0,24), Position=UDim2.new(1,-46,0.5,-12),
        BackgroundColor3=C.accentDim, BorderSizePixel=0,
    },row)
    corner(999,track2)
    uistroke(C.border,1,track2)
    local thumb2 = mk("Frame",{
        Size=UDim2.new(0,18,0,18), Position=UDim2.new(0,25,0.5,-9),
        BackgroundColor3=r.color, BorderSizePixel=0,
    },track2)
    corner(999,thumb2)
    local tb2 = mk("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=5},track2)
    local on2 = true
    tb2.MouseButton1Click:Connect(function()
        on2 = not on2
        State.selectedRar[r.name] = on2
        TweenService:Create(thumb2,TweenInfo.new(0.15),{
            Position=on2 and UDim2.new(0,25,0.5,-9) or UDim2.new(0,3,0.5,-9),
            BackgroundColor3=on2 and r.color or C.dim,
        }):Play()
        TweenService:Create(track2,TweenInfo.new(0.15),{
            BackgroundColor3=on2 and C.accentDim or Color3.fromRGB(30,36,62),
        }):Play()
    end)
    if i < #RARITY_DATA then divLine(asRarBody,i+100) end
end

-- RIGHT: egg list + status
local asRBody = makeSection(asR,"Detected Eggs — Rarest First (Full Map)",C.accentHi,1)
mk("UIListLayout",{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder},asRBody)
pad(8,8,6,6,asRBody)

local statusRow = mk("Frame",{
    Size=UDim2.new(1,0,0,32), BackgroundColor3=C.panel,
    BorderSizePixel=0, LayoutOrder=0,
},asRBody)
corner(8,statusRow)
local statusDot = mk("Frame",{
    Size=UDim2.new(0,8,0,8), Position=UDim2.new(0,10,0.5,-4),
    BackgroundColor3=C.subtext, BorderSizePixel=0,
},statusRow)
corner(999,statusDot)
local statusLbl = mk("TextLabel",{
    Size=UDim2.new(1,-26,1,0), Position=UDim2.new(0,24,0,0),
    BackgroundTransparency=1, Text="Idle — ready",
    TextColor3=C.subtext, TextSize=11,
    Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left,
},statusRow)

local function setStatus(txt,col)
    statusLbl.Text       = txt
    statusLbl.TextColor3 = col or C.subtext
    statusDot.BackgroundColor3 = col or C.subtext
end

local function buildEggRow(data,idx,parent)
    local rd  = getRD(data.rarity)
    local row = mk("Frame",{
        Size=UDim2.new(1,0,0,66),
        BackgroundColor3=C.panel,
        BorderSizePixel=0, LayoutOrder=idx,
    },parent)
    corner(10,row)
    uistroke(rd.color,0.8,row)

    local stripe = mk("Frame",{Size=UDim2.new(0,4,1,-8),Position=UDim2.new(0,4,0,4),BackgroundColor3=rd.color,BorderSizePixel=0},row)
    corner(4,stripe)

    mk("TextLabel",{
        Size=UDim2.new(1,-140,0,16), Position=UDim2.new(0,42,0,4),
        BackgroundTransparency=1, Text="Egg: "..data.name,
        TextColor3=C.subtext, TextSize=9,
        Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd,
    },row)

    mk("TextLabel",{
        Size=UDim2.new(1,-140,0,18), Position=UDim2.new(0,42,0,20),
        BackgroundTransparency=1, Text="Pet: "..data.pet,
        TextColor3=C.text, TextSize=12,
        Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd,
    },row)

    local moneyStr = data.money ~= "" and ("  Money: "..data.money) or ""
    mk("TextLabel",{
        Size=UDim2.new(1,-140,0,14), Position=UDim2.new(0,42,0,42),
        BackgroundTransparency=1,
        Text=data.rarity.."  "..data.dist.."m"..moneyStr,
        TextColor3=rd.color, TextSize=9,
        Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left,
    },row)

    local stBtn = mk("TextButton",{
        Size=UDim2.new(0,68,0,36), Position=UDim2.new(1,-76,0.5,-18),
        BackgroundColor3=C.accent, Text="STEAL",
        TextColor3=Color3.new(1,1,1), TextSize=11,
        Font=Enum.Font.GothamBold, BorderSizePixel=0,
    },row)
    corner(9,stBtn)
    uistroke(C.accentHi,0.8,stBtn)
    stBtn.MouseEnter:Connect(function() TweenService:Create(stBtn,TweenInfo.new(0.1),{BackgroundColor3=C.accentHi}):Play() end)
    stBtn.MouseLeave:Connect(function() TweenService:Create(stBtn,TweenInfo.new(0.1),{BackgroundColor3=C.accent}):Play() end)

    stBtn.MouseButton1Click:Connect(function()
        if State.stealing then return end
        State.stealing = true
        setStatus("Stealing: "..data.pet.." ["..data.rarity.."]", C.accentHi)
        stBtn.Text="..." stBtn.BackgroundTransparency=0.5
        stealEgg(data, function(ok)
            State.stealing = false
            stBtn.Text="STEAL" stBtn.BackgroundTransparency=0
            setStatus(ok and "Got: "..data.pet or "Failed", ok and C.green or C.red)
        end)
    end)
end

-- ─────────────────────────────────────────────────────────────
-- TAB: EGG PREDICTOR
-- ─────────────────────────────────────────────────────────────
local cfEP   = makeContent("eggPredict")
local epCols = mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1},cfEP)
local epL    = mk("Frame",{Size=UDim2.new(0.42,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},epCols)
mk("Frame",{Size=UDim2.new(0,1,1,0),Position=UDim2.new(0.42,0,0,0),BackgroundColor3=C.border,BorderSizePixel=0},epCols)
local epR    = mk("Frame",{Size=UDim2.new(0.58,-2,0,0),Position=UDim2.new(0.42,2,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},epCols)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},epL)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},epR)
local epLBody = makeSection(epL,"Prediction Settings",C.accentHi,1)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},epLBody)
makeRowToggle(epLBody,"Show Pet Name",true,1);  divLine(epLBody,2)
makeRowToggle(epLBody,"Show Rarity",true,3);    divLine(epLBody,4)
makeRowToggle(epLBody,"Show Money/s",true,5);   divLine(epLBody,6)
makeRowToggle(epLBody,"Auto Hatch Rarest",false,7)
local epRBody = makeSection(epR,"Live Predictions — All Eggs Full Map",C.accentHi,1)
mk("UIListLayout",{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder},epRBody)
pad(8,8,6,6,epRBody)

local function buildPredictRow(data,idx,parent)
    local rd  = getRD(data.rarity)
    local row = mk("Frame",{Size=UDim2.new(1,0,0,68),BackgroundColor3=C.panel,BorderSizePixel=0,LayoutOrder=idx},parent)
    corner(10,row)
    uistroke(rd.color,0.8,row)
    local stripe=mk("Frame",{Size=UDim2.new(0,4,1,-8),Position=UDim2.new(0,4,0,4),BackgroundColor3=rd.color,BorderSizePixel=0},row)
    corner(4,stripe)
    mk("TextLabel",{Size=UDim2.new(1,-20,0,14),Position=UDim2.new(0,14,0,3),BackgroundTransparency=1,Text="Egg: "..data.name,TextColor3=C.subtext,TextSize=9,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},row)
    mk("TextLabel",{Size=UDim2.new(1,-20,0,18),Position=UDim2.new(0,14,0,18),BackgroundTransparency=1,Text="Pet: "..data.pet,TextColor3=C.text,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},row)
    local monStr = data.money ~= "" and ("  Money: "..data.money) or ""
    mk("TextLabel",{Size=UDim2.new(1,-20,0,14),Position=UDim2.new(0,14,0,38),BackgroundTransparency=1,Text=data.rarity.."  "..data.dist.."m"..monStr,TextColor3=rd.color,TextSize=9,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},row)
    mk("TextLabel",{Size=UDim2.new(1,-20,0,12),Position=UDim2.new(0,14,0,52),BackgroundTransparency=1,Text="Obj: "..data.obj.Name,TextColor3=C.dim,TextSize=8,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},row)
end

-- ─────────────────────────────────────────────────────────────
-- TAB: EGG ESP
-- ─────────────────────────────────────────────────────────────
local cfESP  = makeContent("eggESP")
local espCols= mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1},cfESP)
local espL   = mk("Frame",{Size=UDim2.new(0.42,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},espCols)
mk("Frame",{Size=UDim2.new(0,1,1,0),Position=UDim2.new(0.42,0,0,0),BackgroundColor3=C.border,BorderSizePixel=0},espCols)
local espR   = mk("Frame",{Size=UDim2.new(0.58,-2,0,0),Position=UDim2.new(0.42,2,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},espCols)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},espL)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},espR)
local espLBody = makeSection(espL,"ESP Settings",C.accentHi,1)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},espLBody)
local togESP = makeRowToggle(espLBody,"Enable ESP",false,1,C.cyan)
divLine(espLBody,2)
makeRowToggle(espLBody,"Show Egg Names",true,3);   divLine(espLBody,4)
makeRowToggle(espLBody,"Show Rarity Tags",true,5); divLine(espLBody,6)
makeRowToggle(espLBody,"Show Distance",true,7);    divLine(espLBody,8)
makeRowToggle(espLBody,"Show Pet Name",true,9);    divLine(espLBody,10)
makeRowToggle(espLBody,"Show Money/s",true,11);    divLine(espLBody,12)
makeRowToggle(espLBody,"Highlight Rare+",true,13)
local espRBody = makeSection(espR,"Live Nearest Egg",C.accentHi,1)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},espRBody)
pad(16,16,8,8,espRBody)
local lrStatus = mk("TextLabel",{
    Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
    BackgroundTransparency=1, Text="Scanning...",
    TextColor3=C.subtext, TextSize=11,
    Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left,
    TextWrapped=true, LayoutOrder=1,
},espRBody)

local espBoards = {}
local function clearESP()
    for _,bd in pairs(espBoards) do pcall(function() bd.bill:Destroy() end) end
    espBoards = {}
end
local function buildESPBill(data)
    local part = data.part
    if not part or not part.Parent then return end
    if espBoards[part] then return end
    local rd   = getRD(data.rarity)
    local bill = Instance.new("BillboardGui")
    bill.Size=UDim2.new(0,145,0,68); bill.StudsOffset=Vector3.new(0,5,0)
    bill.AlwaysOnTop=true; bill.LightInfluence=0
    bill.Adornee=part; bill.Parent=part
    local bg=mk("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.fromRGB(6,8,18),BackgroundTransparency=0.18,BorderSizePixel=0},bill)
    corner(8,bg); uistroke(rd.color,1.8,bg)
    local stripe=mk("Frame",{Size=UDim2.new(0,3,1,-6),Position=UDim2.new(0,2,0,3),BackgroundColor3=rd.color,BorderSizePixel=0},bg)
    corner(2,stripe)
    local nameLbl=mk("TextLabel",{Size=UDim2.new(1,-10,0,13),Position=UDim2.new(0,9,0,2),BackgroundTransparency=1,Text="Egg: "..data.name,TextColor3=C.subtext,TextSize=8,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},bg)
    local petLbl=mk("TextLabel",{Size=UDim2.new(1,-10,0,16),Position=UDim2.new(0,9,0,15),BackgroundTransparency=1,Text="Pet: "..data.pet,TextColor3=Color3.new(1,1,1),TextSize=11,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},bg)
    local rarLbl=mk("TextLabel",{Size=UDim2.new(1,-10,0,13),Position=UDim2.new(0,9,0,31),BackgroundTransparency=1,Text=data.rarity,TextColor3=rd.color,TextSize=9,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},bg)
    local monLbl=mk("TextLabel",{Size=UDim2.new(1,-10,0,12),Position=UDim2.new(0,9,0,52),BackgroundTransparency=1,Text="",TextColor3=C.gold,TextSize=8,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},bg)
    local moneyStr = data.money ~= "" and ("Money: "..data.money) or ""
    monLbl.Text = moneyStr
    espBoards[part]={bill=bill,bg=bg,stripe=stripe,nameLbl=nameLbl,petLbl=petLbl,rarLbl=rarLbl,monLbl=monLbl,lastDist="",lastMoney=moneyStr}
end
local function refreshESPText(data)
    local bd = espBoards[data.part]
    if not bd then return end
    local rd=getRD(data.rarity)
    local distStr=data.dist.."m"
    local moneyStr=data.money ~= "" and ("Money: "..data.money) or ""
    if bd.lastDist~=distStr then
        bd.rarLbl.Text=rd.name.."  "..distStr
        bd.lastDist=distStr
    end
    if bd.lastMoney~=moneyStr then bd.monLbl.Text=moneyStr; bd.lastMoney=moneyStr end
end
togESP.onChange(function(v)
    State.espEnabled=v
    if not v then clearESP() end
end)

-- ─────────────────────────────────────────────────────────────
-- TAB: TREADMILL
-- ─────────────────────────────────────────────────────────────
local cfTM   = makeContent("treadmill")
local tmCols = mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1},cfTM)
local tmL    = mk("Frame",{Size=UDim2.new(0.5,-1,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},tmCols)
mk("Frame",{Size=UDim2.new(0,1,1,0),Position=UDim2.new(0.5,0,0,0),BackgroundColor3=C.border,BorderSizePixel=0},tmCols)
local tmR    = mk("Frame",{Size=UDim2.new(0.5,-1,0,0),Position=UDim2.new(0.5,1,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},tmCols)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},tmL)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},tmR)
local tmLBody = makeSection(tmL,"Treadmill Settings",C.accentHi,1)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},tmLBody)
local tmDescF = mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1},tmLBody)
pad(16,16,8,4,tmDescF)
mk("TextLabel",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Text="Auto-walks the treadmill to earn eggs faster. Spams touch on all treadmill/belt/walk parts every frame.",TextColor3=C.subtext,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true},tmDescF)
divLine(tmLBody,2)
local togTreadmill = makeRowToggle(tmLBody,"Auto Treadmill",false,3,C.green)
divLine(tmLBody,4)

local treadConn  = nil
local treadParts = {}
local function cacheTreadmillParts()
    treadParts = {}
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local nm = obj.Name:lower()
            if nm:find("tread") or nm:find("walk") or nm:find("run")
            or nm:find("belt")  or nm:find("mill")  or nm:find("conveyor") then
                table.insert(treadParts, obj)
            end
        end
    end
end
togTreadmill.onChange(function(v)
    if v then
        cacheTreadmillParts()
        if #treadParts == 0 then task.delay(2, cacheTreadmillParts) end
        treadConn = RunService.Heartbeat:Connect(function()
            pcall(function()
                local root = getRoot()
                if not root then return end
                for _,obj in ipairs(treadParts) do
                    if obj and obj.Parent then
                        local tt = obj:FindFirstChildOfClass("TouchTransmitter")
                        if tt then pcall(firetouchinterest, root, obj, 0) end
                        local cl = obj:FindFirstChildOfClass("ClickDetector")
                        if cl then pcall(fireclickdetector, cl) end
                        local pr = obj:FindFirstChildOfClass("ProximityPrompt")
                        if pr then pcall(fireproximityprompt, pr) end
                    end
                end
                for _,v2 in ipairs(workspace:GetDescendants()) do
                    if v2:IsA("RemoteEvent") then
                        local nm = v2.Name:lower()
                        if nm:find("tread") or nm:find("walk") or nm:find("run") or nm:find("belt") then
                            pcall(function() v2:FireServer() end)
                        end
                    end
                end
            end)
        end)
    else
        if treadConn then treadConn:Disconnect() treadConn=nil end
    end
end)
local tmRBody = makeSection(tmR,"Treadmill Status",C.accentHi,1)
pad(16,16,8,8,tmRBody)
local tmStatus = mk("TextLabel",{
    Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
    BackgroundTransparency=1, Text="Status: Idle",
    TextColor3=C.dim, TextSize=11,
    Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=1,
},tmRBody)
local tmPartCount = mk("TextLabel",{
    Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
    BackgroundTransparency=1, Text="Treadmill parts found: 0",
    TextColor3=C.dim, TextSize=10,
    Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=2,
},tmRBody)
togTreadmill.onChange(function(v)
    tmStatus.Text       = v and "Status: Running" or "Status: Idle"
    tmStatus.TextColor3 = v and C.green or C.dim
    tmPartCount.Text    = "Treadmill parts found: "..#treadParts
    tmPartCount.TextColor3 = #treadParts>0 and C.green or C.red
end)

-- ─────────────────────────────────────────────────────────────
-- TAB: THE RIFT
-- ─────────────────────────────────────────────────────────────
local cfRF   = makeContent("rift")
local rfCols = mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1},cfRF)
local rfL    = mk("Frame",{Size=UDim2.new(0.5,-1,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},rfCols)
mk("Frame",{Size=UDim2.new(0,1,1,0),Position=UDim2.new(0.5,0,0,0),BackgroundColor3=C.border,BorderSizePixel=0},rfCols)
local rfR    = mk("Frame",{Size=UDim2.new(0.5,-1,0,0),Position=UDim2.new(0.5,1,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},rfCols)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},rfL)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},rfR)
local rfLBody = makeSection(rfL,"Rift Farm Settings",C.accentHi,1)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},rfLBody)
local rfDescF = mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1},rfLBody)
pad(16,16,8,4,rfDescF)
mk("TextLabel",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Text="Three pets become one Rift egg.\nSubmitting permanently consumes the three offered pets.",TextColor3=C.subtext,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true},rfDescF)
divLine(rfLBody,2)
makeRowToggle(rfLBody,"Farm Missing Rift Pets",false,3,C.cyan)
divLine(rfLBody,4)
makeRowToggle(rfLBody,"Auto Submit & Claim",false,5,C.purple)
divLine(rfLBody,6)
local rfRBody = makeSection(rfR,"Recipe & Progress",C.accentHi,1)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},rfRBody)
local rfRecipeTxt=mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1},rfRBody)
pad(16,16,8,4,rfRecipeTxt)
mk("TextLabel",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Text="Banner: Shattered Rift\nProgress: 0/50\nTrades: 0",TextColor3=C.dim,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true},rfRecipeTxt)
makeRowButton(rfRBody,"Refresh Requirements",2)
makeRowButton(rfRBody,"Submit / Claim Reward",3)

-- ─────────────────────────────────────────────────────────────
-- TAB: ADMIN ABUSE
-- ─────────────────────────────────────────────────────────────
local cfAA   = makeContent("adminAbuse")
local aaCols = mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1},cfAA)
local aaL    = mk("Frame",{Size=UDim2.new(0.5,-1,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},aaCols)
mk("Frame",{Size=UDim2.new(0,1,1,0),Position=UDim2.new(0.5,0,0,0),BackgroundColor3=C.border,BorderSizePixel=0},aaCols)
local aaR    = mk("Frame",{Size=UDim2.new(0.5,-1,0,0),Position=UDim2.new(0.5,1,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},aaCols)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},aaL)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},aaR)

local aaLBody = makeSection(aaL,"Dragon Event Auto Farm",C.accentHi,1)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},aaLBody)
local aaDescF = mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1},aaLBody)
pad(16,16,8,4,aaDescF)
mk("TextLabel",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Text="Dragon event only. Targets dragon-tier eggs specifically.",TextColor3=C.subtext,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true},aaDescF)
divLine(aaLBody,2)
local togDragon = makeRowToggle(aaLBody,"Auto Farm Dragon Event",false,3,C.gold)
divLine(aaLBody,4)

local hlBody = makeSection(aaL,"Hold Longest Admin Abuse",C.accentHi,2)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},hlBody)
local hlDescF=mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1},hlBody)
pad(16,16,8,4,hlDescF)
mk("TextLabel",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Text="Flies 300 studs into sky. Locks with BodyPosition (no drift). God mode on. Spams all hold zone interactions every frame.",TextColor3=C.subtext,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true},hlDescF)
local hlBtnF=mk("Frame",{Size=UDim2.new(1,0,0,54),BackgroundTransparency=1,LayoutOrder=2},hlBody)
pad(16,16,6,8,hlBtnF)
local hlBtn=mk("TextButton",{
    Size=UDim2.new(1,0,0,40), BackgroundColor3=C.accentDim,
    Text="HOLD LONGEST - START",
    TextColor3=Color3.new(1,1,1), TextSize=13,
    Font=Enum.Font.GothamBold, BorderSizePixel=0,
},hlBtnF)
corner(10,hlBtn)
uistroke(C.gold,1.2,hlBtn)
hlBtn.MouseEnter:Connect(function() TweenService:Create(hlBtn,TweenInfo.new(0.1),{BackgroundColor3=C.purple}):Play() end)
hlBtn.MouseLeave:Connect(function()
    TweenService:Create(hlBtn,TweenInfo.new(0.1),{BackgroundColor3=holdActive and C.red or C.accentDim}):Play()
end)
hlBtn.MouseButton1Click:Connect(function()
    holdActive = not holdActive
    if holdActive then
        hlBtn.Text             = "HOLD LONGEST - STOP"
        hlBtn.BackgroundColor3 = C.red
        startHoldLongest()
    else
        hlBtn.Text             = "HOLD LONGEST - START"
        hlBtn.BackgroundColor3 = C.accentDim
        stopHoldLongest()
    end
end)

local aaRBody  = makeSection(aaR,"Dragon Egg Detection",C.accentHi,1)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},aaRBody)
local dlTitleF = mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1},aaRBody)
pad(16,16,8,4,dlTitleF)
mk("TextLabel",{Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,Text="Available Dragon Eggs",TextColor3=C.accentHi,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},dlTitleF)
local dragonListF=mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=2},aaRBody)
pad(16,16,0,8,dragonListF)
local dragonList=mk("TextLabel",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Text="Scanning...",TextColor3=C.dim,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true},dragonListF)

-- ─────────────────────────────────────────────────────────────
-- SCAN LOOP
-- ─────────────────────────────────────────────────────────────
task.spawn(function()
    while true do
        task.wait(1.0)
        local ok,eggs = pcall(scanAllEggs)
        if ok and eggs then
            State.eggList = eggs

            local root = getRoot()
            if root then
                for _,data in ipairs(eggs) do
                    pcall(function()
                        data.dist = math.floor((root.Position - data.pos).Magnitude)
                    end)
                end
            end

            if State.currentTab == "autoSteal" then
                for _,ch in ipairs(asRBody:GetChildren()) do
                    if ch:IsA("Frame") and ch ~= statusRow then ch:Destroy() end
                end
                local shown = 0
                for i,data in ipairs(eggs) do
                    if State.selectedRar[data.rarity] then
                        buildEggRow(data,i,asRBody)
                        shown = shown + 1
                        if shown >= 18 then break end
                    end
                end
                if shown == 0 then
                    mk("TextLabel",{
                        Size=UDim2.new(1,0,0,40), BackgroundTransparency=1,
                        Text="No matching eggs found on map",
                        TextColor3=C.subtext, TextSize=11,
                        Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Center, LayoutOrder=1,
                    },asRBody)
                end
            end

            if State.currentTab == "eggPredict" then
                for _,ch in ipairs(epRBody:GetChildren()) do
                    if ch:IsA("Frame") then ch:Destroy() end
                end
                for i,data in ipairs(eggs) do
                    buildPredictRow(data,i,epRBody)
                    if i >= 15 then break end
                end
            end

            if State.espEnabled then
                local currentParts = {}
                for _,data in ipairs(eggs) do
                    if data.part and data.part.Parent then currentParts[data.part]=data end
                end
                for part,bd in pairs(espBoards) do
                    if not currentParts[part] or not part.Parent then
                        pcall(function() bd.bill:Destroy() end)
                        espBoards[part] = nil
                    end
                end
                for part,data in pairs(currentParts) do
                    if not espBoards[part] then buildESPBill(data)
                    else refreshESPText(data) end
                end
            end

            if #eggs > 0 then
                local e=eggs[1]; local rd=getRD(e.rarity)
                lrStatus.Text="Egg: "..e.name.."\nPet: "..e.pet.."\n"..rd.name.."  "..e.dist.."m"..(e.money~="" and "\nMoney: "..e.money or "")
                lrStatus.TextColor3=rd.color
            else
                lrStatus.Text="No eggs detected"; lrStatus.TextColor3=C.subtext
            end

            local dEggs = {}
            for _,data in ipairs(eggs) do
                local r=data.rarity
                if r=="Secret" or r=="Eternal" or r=="Mythic" or r=="Cosmic" or r=="Divine" then
                    table.insert(dEggs, data.pet.." ["..r.."]")
                end
            end
            dragonList.Text = #dEggs>0 and table.concat(dEggs,"\n") or "No dragon-tier eggs detected"
        end
    end
end)

-- ─────────────────────────────────────────────────────────────
-- AUTO STEAL LOOP — smooth, no double fire, no backing
-- ─────────────────────────────────────────────────────────────
local stealOnceFlag = false
task.spawn(function()
    while true do
        task.wait(0.15)
        if not togAutoSteal.getOn() then
            stealOnceFlag = false
        elseif not State.stealing and not stealBusy then
            if togStealOnce.getOn() and stealOnceFlag then
                togAutoSteal.setOn(false)
                setStatus("Steal Once complete", C.green)
                stealOnceFlag = false
            else
                if togStealOnce.getOn() and not stealOnceFlag then stealOnceFlag = true end
                local eggs   = State.eggList
                if eggs and #eggs > 0 then
                    local target = nil
                    for _,data in ipairs(eggs) do
                        if State.selectedRar[data.rarity] then
                            if data.obj and data.obj.Parent then
                                target = data; break
                            end
                        end
                    end
                    if target then
                        State.stealing = true
                        State.lastSteal = target
                        setStatus("Auto: "..target.pet.." ["..target.rarity.."]", C.accentHi)
                        stealEgg(target, function(ok)
                            State.stealing = false
                            setStatus(ok and "Got: "..target.pet or "Missed", ok and C.green or C.red)
                        end)
                    end
                end
            end
        end
    end
end)

-- ─────────────────────────────────────────────────────────────
-- EGG-DROP WATCHER — re-steal when tracked egg disappears
-- ─────────────────────────────────────────────────────────────
RunService.Heartbeat:Connect(function()
    if not togAutoSteal.getOn() then return end
    if not State.lastSteal then return end
    if State.stealing or stealBusy then return end
    if not State.lastSteal.obj or not State.lastSteal.obj.Parent then
        State.lastSteal = nil
        State.stealQueued = true
    end
end)

-- ─────────────────────────────────────────────────────────────
-- WINDOW TOGGLE
-- ─────────────────────────────────────────────────────────────
IconBtn.MouseButton1Click:Connect(function()
    if iconWasDragged() then return end
    Window.Visible = not Window.Visible
    if Window.Visible then
        Window.Size = UDim2.new(0,880,0,0)
        TweenService:Create(Window,TweenInfo.new(0.22,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
            {Size=UDim2.new(0,880,0,590)}):Play()
        for _,nb in ipairs(navBtns) do nb.setActive(false) end
        navAutoSteal.setActive(true)
        for id,cf in pairs(ContentFrames) do cf.Visible=(id=="autoSteal") end
        TabTitle.Text    = "Auto Steal"
        State.currentTab = "autoSteal"
    else
        TweenService:Create(Window,TweenInfo.new(0.15),{Size=UDim2.new(0,880,0,0)}):Play()
        task.delay(0.16,function()
            Window.Visible=false
            Window.Size=UDim2.new(0,880,0,590)
        end)
    end
end)

for _,nb in ipairs(navBtns) do nb.setActive(false) end
navAutoSteal.setActive(true)
for id,cf in pairs(ContentFrames) do cf.Visible=(id=="autoSteal") end

-- ─────────────────────────────────────────────────────────────
-- RESPAWN
-- ─────────────────────────────────────────────────────────────
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    State.stealing = false
    homePos        = nil
    lineCenterCache= nil
    stealBusy      = false
    stopFly()
    pcall(function() if rideWeld then rideWeld:Destroy() rideWeld=nil end end)
    if holdActive then
        stopHoldLongest()
        holdActive             = false
        hlBtn.Text             = "HOLD LONGEST - START"
        hlBtn.BackgroundColor3 = C.accentDim
    end
    setStatus("Respawned - ready", C.subtext)
end)

print("GNS HUB v4.1 LOADED - Click the GNS circle to open!")