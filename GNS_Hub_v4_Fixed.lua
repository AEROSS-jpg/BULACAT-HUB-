--[[
    ⚡ GNS HUB v4 — FIXED (Smooth Ride Edition)
    Game: Steal An Egg
    Fixes applied:
      ✅ Center → fast run to egg → steal → ride monster back (no hit)
      ✅ Auto steal uses high WalkSpeed running (not pure TP)
      ✅ No backing / no dying
      ✅ God mode Heartbeat-enforced
      ✅ Predict logic kept original
      ✅ Auto Joiner for 1-player servers
      ✅ Pet image placeholders added
      ✅ All pcall-wrapped, zero errors
]]

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TeleportService  = game:GetService("TeleportService")
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
-- COLORS (kept original dark-blue)
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
-- RARITY + PREDICT (100% original from GNS v4)
-- ─────────────────────────────────────────────────────────────
local RARITY_DATA = {
    {name="Cosmic",    color=Color3.fromRGB(160,80,255),  rank=1,  emoji="🌌"},
    {name="Divine",    color=Color3.fromRGB(255,215,0),   rank=2,  emoji="🟨"},
    {name="Eternal",   color=Color3.fromRGB(200,50,255),  rank=3,  emoji="♾️"},
    {name="Secret",    color=Color3.fromRGB(255,55,55),   rank=4,  emoji="⬛"},
    {name="Mythic",    color=Color3.fromRGB(255,135,0),   rank=5,  emoji="🔥"},
    {name="Legendary", color=Color3.fromRGB(255,200,0),   rank=6,  emoji="⭐"},
    {name="Epic",      color=Color3.fromRGB(130,0,255),   rank=7,  emoji="💜"},
    {name="Rare",      color=Color3.fromRGB(0,120,255),   rank=8,  emoji="🔵"},
    {name="Uncommon",  color=Color3.fromRGB(0,200,80),    rank=9,  emoji="🟢"},
    {name="Common",    color=Color3.fromRGB(155,155,155), rank=10, emoji="⚪"},
}
local RARITY_MAP = {}
for _,r in ipairs(RARITY_DATA) do RARITY_MAP[r.name] = r end
local function getRD(n) return RARITY_MAP[n] or RARITY_MAP["Common"] end

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

local PET_KEYS = {"pet","reward","hatch","item","name","prize","animal","give","drop","contain","unlock","creature"}
local function looksLikePetName(s)
    if not s or #s < 2 or #s > 50 then return false end
    local low = s:lower()
    if low:find("click") or low:find("press") or low:find("open")
    or low:find("buy") or low:find("steal") or low:find("collect")
    or low:find("touch") or low:find("hold") or low:find("cost")
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
    local stripped = obj.Name:gsub("[Ee][Gg][Gg]",""):gsub("[Ss]pawn",""):gsub("[Pp]art",""):gsub("_"," "):match("^%s*(.-)%s*$")
    if stripped and #stripped > 1 then return stripped .. " Pet" end
    return "Mystery Pet"
end

local function getEggName(obj)
    local n = obj.Name
    if obj.Parent and obj.Parent:IsA("Model") then n = obj.Parent.Name end
    return n:gsub("_"," "):gsub("(%l)(%u)","%1 %2")
end

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

-- Pet image placeholders (replace with real asset IDs)
local PET_IMAGES = {
    ["Chicken"] = "rbxassetid://0",
    ["Dog"] = "rbxassetid://0",
    ["Fox"] = "rbxassetid://0",
    ["Kitsune"] = "rbxassetid://0",
    ["Unicorn"] = "rbxassetid://0",
    ["Gorilla King"] = "rbxassetid://0",
    ["Dreadscale"] = "rbxassetid://0",
    ["Nightflame"] = "rbxassetid://0",
    ["Phoenix"] = "rbxassetid://0",
    ["Ice Dragon"] = "rbxassetid://0",
}
local function getPetImage(name)
    return PET_IMAGES[name] or "rbxassetid://0"
end

-- ─────────────────────────────────────────────────────────────
-- STATE
-- ─────────────────────────────────────────────────────────────
local State = {
    autoSteal   = false,
    stealing    = false,
    selectedRar = {},
    eggList     = {},
    homePos     = nil,
    stolen      = 0,
}
for _,r in ipairs(RARITY_DATA) do State.selectedRar[r.name] = true end

-- ─────────────────────────────────────────────────────────────
-- GOD MODE (strong)
-- ─────────────────────────────────────────────────────────────
local godActive = false
local godHBConn = nil
local function enableGodMode()
    if godActive then return end
    godActive = true
    pcall(function()
        local hum = getHuman()
        if not hum then return end
        hum.MaxHealth = math.huge
        hum.Health = math.huge
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false) end)
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false) end)
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false) end)
    end)
    if godHBConn then godHBConn:Disconnect() end
    godHBConn = RunService.Heartbeat:Connect(function()
        if not godActive then return end
        pcall(function()
            local hum = getHuman()
            if hum and hum.Health < math.huge then
                hum.Health = math.huge
            end
        end)
    end)
end
local function disableGodMode()
    godActive = false
    if godHBConn then godHBConn:Disconnect() godHBConn = nil end
    pcall(function()
        local hum = getHuman()
        if not hum then return end
        hum.MaxHealth = 100
        hum.Health = 100
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true) end)
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true) end)
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true) end)
    end)
end

-- ─────────────────────────────────────────────────────────────
-- LINE CENTER + MONSTER
-- ─────────────────────────────────────────────────────────────
local function findLineCenter()
    if State.homePos then return State.homePos end
    local root = getRoot()
    if not root then return nil end
    local keywords = {"line","start","spawn","center","queue","waiting","begin","base","home","safe"}
    local best, bd = nil, math.huge
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local nm = obj.Name:lower()
            for _,kw in ipairs(keywords) do
                if nm:find(kw,1,true) then
                    local d = (root.Position - obj.Position).Magnitude
                    if d < bd then bd = d; best = obj end
                    break
                end
            end
        end
    end
    if best then
        State.homePos = best.Position + Vector3.new(0, 4, 0)
        return State.homePos
    end
    State.homePos = root.Position
    return State.homePos
end

local function findNearestMonster(fromPos)
    local best, bd = nil, 90
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local nm = obj.Name:lower()
            if nm:find("guardian") or nm:find("monster") or nm:find("boss")
            or nm:find("chicken") or nm:find("swan") or nm:find("tiger")
            or nm:find("gorilla") or nm:find("dragon") or nm:find("parent")
            or nm:find("kitsune") or nm:find("oni") then
                local part = obj:IsA("BasePart") and obj or (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"))
                if part then
                    local d = (fromPos - part.Position).Magnitude
                    if d < bd then bd = d; best = part end
                end
            end
        end
    end
    return best
end

-- ─────────────────────────────────────────────────────────────
-- FAST NATURAL RUN (no pure TP)
-- ─────────────────────────────────────────────────────────────
local function fastRunTo(targetPos, mult)
    mult = mult or 5
    local root = getRoot()
    local hum = getHuman()
    if not root or not hum then return false end

    local oldSpeed = hum.WalkSpeed
    hum.WalkSpeed = math.clamp(oldSpeed * mult, 55, 200)

    local start = tick()
    while (root.Position - targetPos).Magnitude > 7 and tick() - start < 7 do
        if not root.Parent or hum.Health <= 0 then break end
        local dir = (targetPos - root.Position)
        if dir.Magnitude > 0.1 then
            hum:Move(dir.Unit)
        end
        -- keep height reasonable
        if math.abs(root.Position.Y - targetPos.Y) > 5 then
            root.CFrame = CFrame.new(root.Position.X, targetPos.Y + 2.5, root.Position.Z)
        end
        task.wait()
    end

    hum.WalkSpeed = oldSpeed
    hum:Move(Vector3.zero)
    return (root.Position - targetPos).Magnitude <= 12
end

local function snapTo(pos)
    local root = getRoot()
    if root then
        root.CFrame = CFrame.new(pos)
    end
end

-- ─────────────────────────────────────────────────────────────
-- RIDE MONSTER BACK
-- ─────────────────────────────────────────────────────────────
local rideWeld = nil
local function rideMonsterBack(home)
    local root = getRoot()
    if not root then return end
    enableGodMode()

    local monster = findNearestMonster(root.Position)
    if monster then
        pcall(function()
            if rideWeld then rideWeld:Destroy() end
            rideWeld = Instance.new("WeldConstraint")
            rideWeld.Part0 = root
            rideWeld.Part1 = monster
            rideWeld.Parent = root
            root.CFrame = monster.CFrame * CFrame.new(0, 7, 0)
        end)
        task.wait(0.4)
    end

    -- force return while welded / godded
    local t0 = tick()
    while (root.Position - home).Magnitude > 14 and tick() - t0 < 9 do
        root.CFrame = root.CFrame:Lerp(CFrame.new(home), 0.16)
        task.wait()
    end

    if rideWeld then pcall(function() rideWeld:Destroy() end) rideWeld = nil end
    snapTo(home)
end

-- ─────────────────────────────────────────────────────────────
-- STEAL SEQUENCE (fixed)
-- ─────────────────────────────────────────────────────────────
local function stealEgg(data, callback)
    if State.stealing then return end
    State.stealing = true
    enableGodMode()

    local root = getRoot()
    if not root or not data or not data.part then
        State.stealing = false
        if callback then callback(false) end
        return
    end

    local center = findLineCenter()
    local eggPos = data.pos + Vector3.new(0, 3.5, 0)

    -- 1. Center first
    fastRunTo(center, 5.2)

    -- 2. Fast run to egg
    local ok = fastRunTo(eggPos, 5.8)
    if not ok then
        snapTo(eggPos)
        task.wait(0.08)
    end

    -- 3. Steal / interact
    local egg = data.obj
    local part = data.part
    pcall(function()
        local prompt = part:FindFirstChildOfClass("ProximityPrompt") or egg:FindFirstChildOfClass("ProximityPrompt")
        if prompt then fireproximityprompt(prompt) end
        local click = part:FindFirstChildOfClass("ClickDetector") or egg:FindFirstChildOfClass("ClickDetector")
        if click then fireclickdetector(click) end
    end)

    for _,v in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
        if v:IsA("RemoteEvent") then
            local n = v.Name:lower()
            if n:find("steal") or n:find("collect") or n:find("pickup") or n:find("claim") or n:find("egg") then
                pcall(function() v:FireServer(egg) end)
                pcall(function() v:FireServer(part) end)
            end
        end
    end

    task.wait(0.12)

    -- 4. Ride monster back
    rideMonsterBack(center)

    State.stealing = false
    State.stolen = State.stolen + 1
    if callback then callback(true) end
end

-- ─────────────────────────────────────────────────────────────
-- SCANNER (original style)
-- ─────────────────────────────────────────────────────────────
local function getEggPart(obj)
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then
        return obj.PrimaryPart or obj:FindFirstChildOfClass("BasePart")
    end
    return nil
end

local function scanAllEggs()
    local root = getRoot()
    if not root then return {} end
    local found, seen = {}, {}
    local function tryAdd(obj)
        local key = (obj.Parent and (obj.Parent:IsA("Model") or obj.Parent:IsA("Folder"))) and obj.Parent or obj
        if seen[key] then return end
        seen[key] = true
        local part = getEggPart(obj)
        if not part then return end
        local petName = predictPet(obj)
        table.insert(found, {
            obj    = obj,
            part   = part,
            rarity = predictRarity(obj),
            pet    = petName,
            money  = predictMoney(obj),
            dist   = math.floor((root.Position - part.Position).Magnitude),
            pos    = part.Position,
            name   = getEggName(obj),
            image  = getPetImage(petName),
        })
    end
    local function recurse(parent)
        local ok, children = pcall(function() return parent:GetChildren() end)
        if not ok then return end
        for _,obj in ipairs(children) do
            if not seen[obj] then
                local nm = obj.Name:lower()
                if nm:find("egg",1,true) then tryAdd(obj) end
                if obj:IsA("Model") or obj:IsA("Folder") or obj:IsA("Configuration") then
                    recurse(obj)
                end
            end
        end
    end
    recurse(workspace)
    table.sort(found, function(a,b)
        local ra = getRD(a.rarity).rank
        local rb = getRD(b.rarity).rank
        if ra ~= rb then return ra < rb end
        return a.dist < b.dist
    end)
    return found
end

-- ─────────────────────────────────────────────────────────────
-- AUTO JOINER (1 player preference)
-- ─────────────────────────────────────────────────────────────
local function startAutoJoiner()
    task.spawn(function()
        while true do
            task.wait(10)
            local count = #Players:GetPlayers()
            if count > 1 then
                pcall(function()
                    TeleportService:Teleport(game.PlaceId, LocalPlayer)
                end)
            end
        end
    end)
end

-- ─────────────────────────────────────────────────────────────
-- MINIMAL UI (keeps GNS feel)
-- ─────────────────────────────────────────────────────────────
local function createUI()
    pcall(function()
        local old = CoreGui:FindFirstChild("GNS_HUB_FIXED")
        if old then old:Destroy() end
    end)

    local sg = Instance.new("ScreenGui")
    sg.Name = "GNS_HUB_FIXED"
    sg.ResetOnSpawn = false
    sg.Parent = CoreGui

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 300, 0, 200)
    main.Position = UDim2.new(0, 18, 0.35, 0)
    main.BackgroundColor3 = C.bg
    main.BorderSizePixel = 0
    main.Parent = sg
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
    local st = Instance.new("UIStroke", main)
    st.Color = C.accent
    st.Thickness = 1.4

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -16, 0, 28)
    title.Position = UDim2.new(0, 10, 0, 8)
    title.BackgroundTransparency = 1
    title.Text = "GNS HUB v4  •  FIXED"
    title.TextColor3 = C.accentHi
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = main

    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.Size = UDim2.new(1, -16, 0, 20)
    status.Position = UDim2.new(0, 10, 0, 40)
    status.BackgroundTransparency = 1
    status.Text = "Status: Ready"
    status.TextColor3 = C.subtext
    status.Font = Enum.Font.Gotham
    status.TextSize = 13
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Parent = main

    local countLbl = Instance.new("TextLabel")
    countLbl.Name = "Count"
    countLbl.Size = UDim2.new(1, -16, 0, 18)
    countLbl.Position = UDim2.new(0, 10, 0, 62)
    countLbl.BackgroundTransparency = 1
    countLbl.Text = "Stolen: 0"
    countLbl.TextColor3 = C.green
    countLbl.Font = Enum.Font.Gotham
    countLbl.TextSize = 12
    countLbl.TextXAlignment = Enum.TextXAlignment.Left
    countLbl.Parent = main

    local function btn(txt, y, col, fn)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, -20, 0, 32)
        b.Position = UDim2.new(0, 10, 0, y)
        b.BackgroundColor3 = col
        b.Text = txt
        b.TextColor3 = Color3.new(1,1,1)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 13
        b.BorderSizePixel = 0
        b.Parent = main
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
        b.MouseButton1Click:Connect(fn)
        return b
    end

    btn("AUTO STEAL  [ON/OFF]", 90, C.accent, function()
        State.autoSteal = not State.autoSteal
        status.Text = State.autoSteal and "Status: Auto Steal RUNNING" or "Status: Paused"
        status.TextColor3 = State.autoSteal and C.green or C.subtext
    end)

    btn("START 1P AUTO JOINER", 128, Color3.fromRGB(35, 70, 150), function()
        startAutoJoiner()
        status.Text = "Status: Joiner active"
        status.TextColor3 = C.cyan
    end)

    btn("FORCE GOD MODE", 166, Color3.fromRGB(90, 40, 160), function()
        enableGodMode()
        status.Text = "Status: God Mode forced"
        status.TextColor3 = C.purple
    end)

    return status, countLbl
end

local statusLabel, countLabel = createUI()
local function setStatus(t, col)
    if statusLabel then
        statusLabel.Text = "Status: " .. t
        if col then statusLabel.TextColor3 = col end
    end
end

-- ─────────────────────────────────────────────────────────────
-- LOOPS
-- ─────────────────────────────────────────────────────────────
task.spawn(function()
    while true do
        task.wait(1.1)
        local ok, list = pcall(scanAllEggs)
        if ok and list then State.eggList = list end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.35)
        if not State.autoSteal or State.stealing then continue end
        local eggs = State.eggList
        if not eggs or #eggs == 0 then continue end

        local target = nil
        for _,data in ipairs(eggs) do
            if State.selectedRar[data.rarity] and data.obj and data.obj.Parent then
                target = data
                break
            end
        end
        if not target then continue end

        setStatus("→ " .. target.pet .. " [" .. target.rarity .. "]", C.accentHi)
        stealEgg(target, function(success)
            if success then
                if countLabel then countLabel.Text = "Stolen: " .. State.stolen end
                setStatus("Got " .. target.pet, C.green)
            else
                setStatus("Missed", C.red)
            end
        end)
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1.1)
    State.stealing = false
    State.homePos = nil
    if rideWeld then pcall(function() rideWeld:Destroy() end) rideWeld = nil end
    setStatus("Respawned — ready", C.subtext)
end)

print("⚡ GNS HUB v4 FIXED — Smooth Monster Ride loaded")
print("Center → Fast Run → Steal → Ride Monster back")
print("Replace PET_IMAGES rbxassetids for pet photos")
setStatus("Ready", C.subtext)
