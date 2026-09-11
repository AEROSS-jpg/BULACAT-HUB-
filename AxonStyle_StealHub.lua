--[[
    Axon-Style Steal Hub
    Game: Steal An Egg
    
    Features:
    - Center → Fast natural run → Steal → Ride Monster back (no hit)
    - High WalkSpeed running (not pure teleport)
    - God Mode
    - Egg Predictor
    - Solo Server Joiner
    - Clean dark UI inspired by Axon Hub
    - Pet image placeholders
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
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHuman()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

-- Colors (dark Axon style)
local C = {
    bg       = Color3.fromRGB(12, 10, 18),
    sidebar  = Color3.fromRGB(16, 13, 24),
    panel    = Color3.fromRGB(22, 18, 32),
    card     = Color3.fromRGB(28, 24, 40),
    accent   = Color3.fromRGB(180, 70, 255),
    accent2  = Color3.fromRGB(120, 80, 255),
    text     = Color3.fromRGB(235, 230, 255),
    subtext  = Color3.fromRGB(140, 130, 170),
    dim      = Color3.fromRGB(80, 70, 110),
    green    = Color3.fromRGB(70, 230, 140),
    red      = Color3.fromRGB(255, 70, 90),
    gold     = Color3.fromRGB(255, 200, 60),
    cyan     = Color3.fromRGB(80, 200, 255),
}

-- Rarity
local RARITY_DATA = {
    {name="Cosmic",    color=Color3.fromRGB(160,80,255), rank=1},
    {name="Divine",    color=Color3.fromRGB(255,215,0),  rank=2},
    {name="Eternal",   color=Color3.fromRGB(200,50,255), rank=3},
    {name="Secret",    color=Color3.fromRGB(255,55,55),  rank=4},
    {name="Mythic",    color=Color3.fromRGB(255,135,0),  rank=5},
    {name="Legendary", color=Color3.fromRGB(255,200,0),  rank=6},
    {name="Epic",      color=Color3.fromRGB(130,0,255),  rank=7},
    {name="Rare",      color=Color3.fromRGB(0,120,255),  rank=8},
    {name="Uncommon",  color=Color3.fromRGB(0,200,80),   rank=9},
    {name="Common",    color=Color3.fromRGB(155,155,155),rank=10},
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
    end
    for _,v in ipairs(obj:GetDescendants()) do
        if v:IsA("StringValue") then
            hit = matchRarity(v.Name) or matchRarity(v.Value)
            if hit then return hit end
        elseif v:IsA("TextLabel") or v:IsA("TextButton") then
            hit = matchRarity(v.Text)
            if hit then return hit end
        end
    end
    return "Common"
end

local PET_KEYS = {"pet","reward","hatch","item","name","prize","animal","give","drop","contain","unlock","creature"}
local function looksLikePetName(s)
    if not s or #s < 2 or #s > 50 then return false end
    local low = s:lower()
    if low:find("click") or low:find("press") or low:find("open") or low:find("buy")
    or low:find("steal") or low:find("collect") or low:find("touch") or low:find("hold")
    or low:find("cost") or low:find("timer") or low:find("price") then return false end
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
        if (v:IsA("TextLabel") or v:IsA("TextButton")) and looksLikePetName(v.Text) then
            return v.Text
        end
    end
    local stripped = obj.Name:gsub("[Ee][Gg][Gg]",""):gsub("_"," "):match("^%s*(.-)%s*$")
    if stripped and #stripped > 1 then return stripped end
    return "Mystery Pet"
end

local function getEggName(obj)
    local n = obj.Name
    if obj.Parent and obj.Parent:IsA("Model") then n = obj.Parent.Name end
    return n:gsub("_"," ")
end

-- Pet images (replace with real asset IDs)
local PET_IMAGES = {
    ["Cerberus"] = "rbxassetid://0",
    ["Kraken"] = "rbxassetid://0",
    ["Stag"] = "rbxassetid://0",
    ["TRex"] = "rbxassetid://0",
    ["Axolotl"] = "rbxassetid://0",
    ["Swan"] = "rbxassetid://0",
    ["Oni Tiger"] = "rbxassetid://0",
    ["Kitsune"] = "rbxassetid://0",
    ["Unicorn"] = "rbxassetid://0",
    ["Gorilla King"] = "rbxassetid://0",
    ["Dreadscale"] = "rbxassetid://0",
    ["Nightflame"] = "rbxassetid://0",
    ["Phoenix"] = "rbxassetid://0",
    ["Chicken"] = "rbxassetid://0",
    ["Dog"] = "rbxassetid://0",
}
local function getPetImage(name)
    return PET_IMAGES[name] or "rbxassetid://0"
end

-- State
local State = {
    autoSteal = false,
    stealing  = false,
    selectedRar = {},
    eggList   = {},
    homePos   = nil,
    stolen    = 0,
    currentTab = "autoSteal",
}
for _,r in ipairs(RARITY_DATA) do State.selectedRar[r.name] = true end

-- God Mode
local godActive = false
local godConn = nil
local function enableGodMode()
    if godActive then return end
    godActive = true
    local hum = getHuman()
    if hum then
        hum.MaxHealth = math.huge
        hum.Health = math.huge
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false) end)
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false) end)
    end
    godConn = RunService.Heartbeat:Connect(function()
        if not godActive then return end
        local h = getHuman()
        if h and h.Health < math.huge then h.Health = math.huge end
    end)
end

-- Line Center + Monster
local function findLineCenter()
    if State.homePos then return State.homePos end
    local root = getRoot()
    if not root then return nil end
    local keywords = {"line","start","spawn","center","queue","waiting","base","home","safe"}
    local best, bd = nil, math.huge
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local nm = obj.Name:lower()
            for _,kw in ipairs(keywords) do
                if nm:find(kw,1,true) then
                    local d = (root.Position - obj.Position).Magnitude
                    if d < bd then bd = d; best = obj end
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
    local best, bd = nil, 100
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local nm = obj.Name:lower()
            if nm:find("guardian") or nm:find("monster") or nm:find("boss")
            or nm:find("chicken") or nm:find("swan") or nm:find("tiger")
            or nm:find("gorilla") or nm:find("dragon") or nm:find("parent")
            or nm:find("kitsune") or nm:find("oni") or nm:find("cerberus") then
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

-- Fast natural run
local function fastRunTo(targetPos, mult)
    mult = mult or 5.5
    local root = getRoot()
    local hum = getHuman()
    if not root or not hum then return false end
    local old = hum.WalkSpeed
    hum.WalkSpeed = math.clamp(old * mult, 60, 220)
    local t0 = tick()
    while (root.Position - targetPos).Magnitude > 8 and tick() - t0 < 7 do
        if not root.Parent then break end
        local dir = (targetPos - root.Position)
        if dir.Magnitude > 0.1 then hum:Move(dir.Unit) end
        if math.abs(root.Position.Y - targetPos.Y) > 5 then
            root.CFrame = CFrame.new(root.Position.X, targetPos.Y + 2.5, root.Position.Z)
        end
        task.wait()
    end
    hum.WalkSpeed = old
    hum:Move(Vector3.zero)
    return (root.Position - targetPos).Magnitude <= 14
end

local function snapTo(pos)
    local root = getRoot()
    if root then root.CFrame = CFrame.new(pos) end
end

-- Ride monster back
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
        task.wait(0.35)
    end
    local t0 = tick()
    while (root.Position - home).Magnitude > 15 and tick() - t0 < 9 do
        root.CFrame = root.CFrame:Lerp(CFrame.new(home), 0.15)
        task.wait()
    end
    if rideWeld then pcall(function() rideWeld:Destroy() end) rideWeld = nil end
    snapTo(home)
end

-- Steal sequence
local function stealEgg(data, cb)
    if State.stealing then return end
    State.stealing = true
    enableGodMode()
    local root = getRoot()
    if not root or not data or not data.part then
        State.stealing = false
        if cb then cb(false) end
        return
    end
    local center = findLineCenter()
    local eggPos = data.pos + Vector3.new(0, 3.5, 0)

    fastRunTo(center, 5.2)
    local ok = fastRunTo(eggPos, 6)
    if not ok then snapTo(eggPos) task.wait(0.08) end

    local egg, part = data.obj, data.part
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
    rideMonsterBack(center)
    State.stealing = false
    State.stolen = State.stolen + 1
    if cb then cb(true) end
end

-- Scanner
local function getEggPart(obj)
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then return obj.PrimaryPart or obj:FindFirstChildOfClass("BasePart") end
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
            obj = obj, part = part,
            rarity = predictRarity(obj),
            pet = petName,
            dist = math.floor((root.Position - part.Position).Magnitude),
            pos = part.Position,
            name = getEggName(obj),
            image = getPetImage(petName),
        })
    end
    local function recurse(parent)
        local ok, children = pcall(function() return parent:GetChildren() end)
        if not ok then return end
        for _,obj in ipairs(children) do
            if not seen[obj] then
                if obj.Name:lower():find("egg") then tryAdd(obj) end
                if obj:IsA("Model") or obj:IsA("Folder") then recurse(obj) end
            end
        end
    end
    recurse(workspace)
    table.sort(found, function(a,b)
        local ra, rb = getRD(a.rarity).rank, getRD(b.rarity).rank
        if ra ~= rb then return ra < rb end
        return a.dist < b.dist
    end)
    return found
end

-- Solo Joiner
local function startSoloJoiner()
    task.spawn(function()
        while true do
            task.wait(12)
            if #Players:GetPlayers() > 1 then
                pcall(function()
                    TeleportService:Teleport(game.PlaceId, LocalPlayer)
                end)
            end
        end
    end)
end

-- ===================== UI =====================
local function createUI()
    pcall(function()
        local old = CoreGui:FindFirstChild("AxonStyleHub")
        if old then old:Destroy() end
    end)

    local sg = Instance.new("ScreenGui")
    sg.Name = "AxonStyleHub"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = CoreGui

    -- Main window
    local win = Instance.new("Frame")
    win.Size = UDim2.new(0, 780, 0, 480)
    win.Position = UDim2.new(0.5, -390, 0.5, -240)
    win.BackgroundColor3 = C.bg
    win.BorderSizePixel = 0
    win.Parent = sg
    Instance.new("UICorner", win).CornerRadius = UDim.new(0, 14)

    local stroke = Instance.new("UIStroke", win)
    stroke.Color = Color3.fromRGB(60, 40, 100)
    stroke.Thickness = 1.2

    -- Sidebar
    local side = Instance.new("Frame")
    side.Size = UDim2.new(0, 180, 1, 0)
    side.BackgroundColor3 = C.sidebar
    side.BorderSizePixel = 0
    side.Parent = win
    Instance.new("UICorner", side).CornerRadius = UDim.new(0, 14)

    local logo = Instance.new("TextLabel")
    logo.Size = UDim2.new(1, -20, 0, 40)
    logo.Position = UDim2.new(0, 12, 0, 14)
    logo.BackgroundTransparency = 1
    logo.Text = "Axon Hub"
    logo.TextColor3 = C.accent
    logo.Font = Enum.Font.GothamBold
    logo.TextSize = 20
    logo.TextXAlignment = Enum.TextXAlignment.Left
    logo.Parent = side

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, -20, 0, 18)
    sub.Position = UDim2.new(0, 12, 0, 48)
    sub.BackgroundTransparency = 1
    sub.Text = "Steal an Egg"
    sub.TextColor3 = C.subtext
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 12
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.Parent = side

    local function navBtn(text, y, tabId)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, -24, 0, 36)
        b.Position = UDim2.new(0, 12, 0, y)
        b.BackgroundColor3 = C.panel
        b.Text = "  " .. text
        b.TextColor3 = C.text
        b.Font = Enum.Font.GothamMedium
        b.TextSize = 14
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.BorderSizePixel = 0
        b.Parent = side
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
        b.MouseButton1Click:Connect(function()
            State.currentTab = tabId
            for _,c in ipairs(win:GetChildren()) do
                if c:IsA("Frame") and c.Name:find("Content") then
                    c.Visible = (c.Name == "Content_" .. tabId)
                end
            end
        end)
        return b
    end

    navBtn("Auto Steal", 90, "autoSteal")
    navBtn("Egg Predictor", 132, "predictor")
    navBtn("Solo Servers", 174, "servers")

    -- Content: Auto Steal
    local contentSteal = Instance.new("Frame")
    contentSteal.Name = "Content_autoSteal"
    contentSteal.Size = UDim2.new(1, -200, 1, -20)
    contentSteal.Position = UDim2.new(0, 190, 0, 10)
    contentSteal.BackgroundTransparency = 1
    contentSteal.Parent = win

    local title1 = Instance.new("TextLabel")
    title1.Size = UDim2.new(1, 0, 0, 30)
    title1.BackgroundTransparency = 1
    title1.Text = "Auto Steal"
    title1.TextColor3 = C.text
    title1.Font = Enum.Font.GothamBold
    title1.TextSize = 18
    title1.TextXAlignment = Enum.TextXAlignment.Left
    title1.Parent = contentSteal

    local statusLbl = Instance.new("TextLabel")
    statusLbl.Name = "Status"
    statusLbl.Size = UDim2.new(1, 0, 0, 22)
    statusLbl.Position = UDim2.new(0, 0, 0, 40)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Text = "Status: Ready"
    statusLbl.TextColor3 = C.subtext
    statusLbl.Font = Enum.Font.Gotham
    statusLbl.TextSize = 14
    statusLbl.TextXAlignment = Enum.TextXAlignment.Left
    statusLbl.Parent = contentSteal

    local countLbl = Instance.new("TextLabel")
    countLbl.Name = "Count"
    countLbl.Size = UDim2.new(1, 0, 0, 20)
    countLbl.Position = UDim2.new(0, 0, 0, 65)
    countLbl.BackgroundTransparency = 1
    countLbl.Text = "Stolen: 0"
    countLbl.TextColor3 = C.green
    countLbl.Font = Enum.Font.Gotham
    countLbl.TextSize = 13
    countLbl.TextXAlignment = Enum.TextXAlignment.Left
    countLbl.Parent = contentSteal

    local function makeBtn(parent, text, y, col, fn)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 220, 0, 38)
        b.Position = UDim2.new(0, 0, 0, y)
        b.BackgroundColor3 = col
        b.Text = text
        b.TextColor3 = Color3.new(1,1,1)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 14
        b.BorderSizePixel = 0
        b.Parent = parent
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 9)
        b.MouseButton1Click:Connect(fn)
        return b
    end

    makeBtn(contentSteal, "TOGGLE AUTO STEAL", 100, C.accent, function()
        State.autoSteal = not State.autoSteal
        statusLbl.Text = State.autoSteal and "Status: Auto Steal RUNNING" or "Status: Paused"
        statusLbl.TextColor3 = State.autoSteal and C.green or C.subtext
    end)

    makeBtn(contentSteal, "FORCE GOD MODE", 150, Color3.fromRGB(100, 50, 180), function()
        enableGodMode()
        statusLbl.Text = "Status: God Mode ON"
        statusLbl.TextColor3 = C.accent
    end)

    -- Content: Predictor
    local contentPred = Instance.new("Frame")
    contentPred.Name = "Content_predictor"
    contentPred.Size = UDim2.new(1, -200, 1, -20)
    contentPred.Position = UDim2.new(0, 190, 0, 10)
    contentPred.BackgroundTransparency = 1
    contentPred.Visible = false
    contentPred.Parent = win

    local title2 = Instance.new("TextLabel")
    title2.Size = UDim2.new(1, 0, 0, 30)
    title2.BackgroundTransparency = 1
    title2.Text = "Egg Predictor"
    title2.TextColor3 = C.text
    title2.Font = Enum.Font.GothamBold
    title2.TextSize = 18
    title2.TextXAlignment = Enum.TextXAlignment.Left
    title2.Parent = contentPred

    local predList = Instance.new("ScrollingFrame")
    predList.Name = "PredList"
    predList.Size = UDim2.new(1, -10, 1, -50)
    predList.Position = UDim2.new(0, 0, 0, 45)
    predList.BackgroundColor3 = C.panel
    predList.BorderSizePixel = 0
    predList.ScrollBarThickness = 4
    predList.Parent = contentPred
    Instance.new("UICorner", predList).CornerRadius = UDim.new(0, 10)
    local listLayout = Instance.new("UIListLayout", predList)
    listLayout.Padding = UDim.new(0, 6)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- Content: Servers
    local contentSrv = Instance.new("Frame")
    contentSrv.Name = "Content_servers"
    contentSrv.Size = UDim2.new(1, -200, 1, -20)
    contentSrv.Position = UDim2.new(0, 190, 0, 10)
    contentSrv.BackgroundTransparency = 1
    contentSrv.Visible = false
    contentSrv.Parent = win

    local title3 = Instance.new("TextLabel")
    title3.Size = UDim2.new(1, 0, 0, 30)
    title3.BackgroundTransparency = 1
    title3.Text = "Solo Servers"
    title3.TextColor3 = C.text
    title3.Font = Enum.Font.GothamBold
    title3.TextSize = 18
    title3.TextXAlignment = Enum.TextXAlignment.Left
    title3.Parent = contentSrv

    makeBtn(contentSrv, "START SOLO AUTO JOINER", 50, C.cyan, function()
        startSoloJoiner()
        statusLbl.Text = "Status: Solo Joiner active"
        statusLbl.TextColor3 = C.cyan
    end)

    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, 0, 0, 60)
    info.Position = UDim2.new(0, 0, 0, 100)
    info.BackgroundTransparency = 1
    info.Text = "Joiner will hop until the server has 1 player.\nUse with Auto Steal for best results."
    info.TextColor3 = C.subtext
    info.Font = Enum.Font.Gotham
    info.TextSize = 13
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.TextWrapped = true
    info.Parent = contentSrv

    return statusLbl, countLbl, predList
end

local statusLabel, countLabel, predList = createUI()

local function setStatus(t, col)
    if statusLabel then
        statusLabel.Text = "Status: " .. t
        if col then statusLabel.TextColor3 = col end
    end
end

local function refreshPredictor(eggs)
    if not predList then return end
    for _,c in ipairs(predList:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    for i, data in ipairs(eggs) do
        if i > 12 then break end
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -12, 0, 52)
        row.BackgroundColor3 = C.card
        row.BorderSizePixel = 0
        row.LayoutOrder = i
        row.Parent = predList
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

        local img = Instance.new("ImageLabel")
        img.Size = UDim2.new(0, 40, 0, 40)
        img.Position = UDim2.new(0, 8, 0.5, -20)
        img.BackgroundTransparency = 1
        img.Image = data.image
        img.Parent = row

        local name = Instance.new("TextLabel")
        name.Size = UDim2.new(0.5, 0, 0, 20)
        name.Position = UDim2.new(0, 56, 0, 6)
        name.BackgroundTransparency = 1
        name.Text = data.pet
        name.TextColor3 = C.text
        name.Font = Enum.Font.GothamBold
        name.TextSize = 14
        name.TextXAlignment = Enum.TextXAlignment.Left
        name.Parent = row

        local rar = Instance.new("TextLabel")
        rar.Size = UDim2.new(0.5, 0, 0, 18)
        rar.Position = UDim2.new(0, 56, 0, 28)
        rar.BackgroundTransparency = 1
        rar.Text = data.rarity .. "  •  " .. data.dist .. "m"
        rar.TextColor3 = getRD(data.rarity).color
        rar.Font = Enum.Font.Gotham
        rar.TextSize = 12
        rar.TextXAlignment = Enum.TextXAlignment.Left
        rar.Parent = row
    end
    predList.CanvasSize = UDim2.new(0, 0, 0, #eggs * 58)
end

-- Loops
task.spawn(function()
    while true do
        task.wait(1.2)
        local ok, list = pcall(scanAllEggs)
        if ok and list then
            State.eggList = list
            refreshPredictor(list)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.4)
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
        setStatus("→ " .. target.pet .. " [" .. target.rarity .. "]", C.accent)
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
    task.wait(1.2)
    State.stealing = false
    State.homePos = nil
    if rideWeld then pcall(function() rideWeld:Destroy() end) rideWeld = nil end
    setStatus("Respawned — ready", C.subtext)
end)

print("Axon-Style Steal Hub loaded")
print("Center → Fast Run → Steal → Ride Monster back")
setStatus("Ready", C.subtext)
