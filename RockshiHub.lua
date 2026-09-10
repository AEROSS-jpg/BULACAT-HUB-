-- // ============================================
-- // 🥋 ROCKSHI HUB v3 — Blue Theme
-- // Executor: KRNL / Synapse X / Fluxus
-- // ============================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer      = Players.LocalPlayer

local function getChar()  return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait() end
local function getRoot()  return getChar():WaitForChild("HumanoidRootPart") end
local function getHuman() return getChar():WaitForChild("Humanoid") end

local CFG = {
    EGG_KEYWORDS  = {"Egg","egg"},
    STEAL_DELAY   = 0.2,
    SCAN_INTERVAL = 0.6,
    FLY_HEIGHT    = 80,
    FLY_SPEED     = 200,
    WALK_SPEED    = 80,
    HOLD_HEIGHT   = 300,
}

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

-- // RARITY PREDICT — scans name, tags, BillboardGuis, StringValues, all descendants
local function predictRarity(egg)
    local checks = {"divine","eternal","secret","cosmic","rare","uncommon"}
    local mapped  = {"Divine","Eternal","Secret","Cosmic","Rare","Uncommon"}
    local nm = egg.Name:lower()
    for i,kw in ipairs(checks) do if nm:find(kw) then return mapped[i] end end
    -- scan all descendants deeply
    for _,v in ipairs(egg:GetDescendants()) do
        local t=""
        if v:IsA("StringValue")    then t=(v.Value or ""):lower()
        elseif v:IsA("TextLabel")  then t=(v.Text  or ""):lower()
        elseif v:IsA("IntValue")   then
            -- some games store rarity as int 1-7
            local val=v.Value
            if v.Name:lower():find("rar") then
                if val==1 then return "Divine"
                elseif val==2 then return "Eternal"
                elseif val==3 then return "Secret"
                elseif val==4 then return "Cosmic"
                elseif val==5 then return "Rare"
                elseif val==6 then return "Uncommon"
                end
            end
        end
        for i,kw in ipairs(checks) do if t:find(kw) then return mapped[i] end end
    end
    -- check parent model too
    if egg.Parent then
        local pnm=egg.Parent.Name:lower()
        for i,kw in ipairs(checks) do if pnm:find(kw) then return mapped[i] end end
    end
    return "Common"
end

-- // PET PREDICT — scans all string/text values for pet names
local function predictPet(egg)
    local petKeys={"pet","reward","hatch","item","name","give","prize"}
    -- check StringValues
    for _,v in ipairs(egg:GetDescendants()) do
        if v:IsA("StringValue") then
            for _,k in ipairs(petKeys) do
                if v.Name:lower():find(k) and v.Value~="" then
                    return v.Value
                end
            end
        end
    end
    -- check TextLabels (BillboardGui, SurfaceGui)
    for _,v in ipairs(egg:GetDescendants()) do
        if v:IsA("TextLabel") and v.Text~="" and #v.Text<50 then
            local t=v.Text:lower()
            -- skip generic labels
            if not t:find("click") and not t:find("press") and not t:find("open") then
                return v.Text
            end
        end
    end
    -- check parent model StringValues
    if egg.Parent then
        for _,v in ipairs(egg.Parent:GetChildren()) do
            if v:IsA("StringValue") then
                for _,k in ipairs(petKeys) do
                    if v.Name:lower():find(k) and v.Value~="" then
                        return v.Value
                    end
                end
            end
        end
    end
    -- fallback: use egg name minus "Egg"
    local nm=egg.Name:gsub("[Ee]gg",""):gsub("^%s+",""):gsub("%s+$","")
    if nm~="" then return nm.." Pet" end
    return "Unknown Pet 🐾"
end

-- // MAP-WIDE EGG SCAN
local function scanEggs()
    local Root=getRoot()
    local found,seen={},{}
    -- scan entire workspace recursively
    local function scanFolder(folder)
        for _,obj in ipairs(folder:GetChildren()) do
            if obj:IsA("BasePart") and not seen[obj] then
                for _,kw in ipairs(CFG.EGG_KEYWORDS) do
                    if obj.Name:lower():find(kw:lower()) then
                        seen[obj]=true
                        local rar  = predictRarity(obj)
                        local pet  = predictPet(obj)
                        local dist = math.floor((Root.Position-obj.Position).Magnitude)
                        table.insert(found,{egg=obj,rarity=rar,pet=pet,dist=dist})
                        break
                    end
                end
            end
            -- recurse into models/folders
            if obj:IsA("Model") or obj:IsA("Folder") then
                scanFolder(obj)
            end
        end
    end
    scanFolder(workspace)
    -- sort rarest first, then nearest
    table.sort(found,function(a,b)
        local ra=getRD(a.rarity).rank
        local rb=getRD(b.rarity).rank
        if ra~=rb then return ra<rb end
        return a.dist<b.dist
    end)
    return found
end

-- // GOD MODE
local godConn=nil
local function enableGodMode()
    local hum=getHuman()
    hum.MaxHealth=math.huge
    hum.Health=math.huge
    if godConn then godConn:Disconnect() end
    godConn=hum.HealthChanged:Connect(function(hp)
        if hp<hum.MaxHealth then hum.Health=math.huge end
    end)
    hum:SetStateEnabled(Enum.HumanoidStateType.Dead,false)
    hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown,false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,false)
    local char=getChar()
    for _,p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide=false end
    end
end

local function disableGodMode()
    if godConn then godConn:Disconnect() godConn=nil end
    pcall(function()
        local hum=getHuman()
        hum.MaxHealth=100
        hum.Health=100
        hum:SetStateEnabled(Enum.HumanoidStateType.Dead,true)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown,true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,true)
        local char=getChar()
        for _,p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide=true end
        end
    end)
end

-- // FLY ENGINE
local flying=false
local flyConn=nil
local bodyVel=nil
local bodyGyro=nil

local function stopFly()
    flying=false
    if flyConn then flyConn:Disconnect() flyConn=nil end
    pcall(function() if bodyVel  then bodyVel:Destroy()  bodyVel=nil  end end)
    pcall(function() if bodyGyro then bodyGyro:Destroy() bodyGyro=nil end end)
    pcall(function() getHuman().PlatformStand=false end)
end

local function flyTo(targetPos,speed,onArrived)
    stopFly()
    flying=true
    local Root=getRoot()
    local Human=getHuman()
    Human.PlatformStand=true

    bodyVel=Instance.new("BodyVelocity",Root)
    bodyVel.MaxForce=Vector3.new(1e6,1e6,1e6)
    bodyVel.Velocity=Vector3.new(0,0,0)

    bodyGyro=Instance.new("BodyGyro",Root)
    bodyGyro.MaxTorque=Vector3.new(1e6,1e6,1e6)
    bodyGyro.P=1e4

    flyConn=RunService.Heartbeat:Connect(function()
        if not flying then return end
        local root=getRoot()
        local diff=targetPos-root.Position
        local dist=diff.Magnitude
        if dist<2.5 then
            stopFly()
            if onArrived then onArrived() end
            return
        end
        local dir=diff.Unit
        bodyVel.Velocity=dir*(speed or CFG.FLY_SPEED)
        bodyGyro.CFrame=CFrame.new(root.Position,root.Position+dir)
    end)
end

-- // RIDE MONSTER (like Miranda game)
local function rideNearestMount()
    local Root=getRoot()
    local best,bd=nil,math.huge
    local mountKeys={"mount","pet","monster","creature","ride","animal","mob","boss","npc"}
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            for _,kw in ipairs(mountKeys) do
                if obj.Name:lower():find(kw) then
                    local d=(Root.Position-obj.Position).Magnitude
                    if d<bd and d<80 then bd=d best=obj end
                    break
                end
            end
        end
    end
    if best then
        Root.CFrame=CFrame.new(best.Position+Vector3.new(0,5,0))
        local w=Instance.new("WeldConstraint")
        w.Part0=Root w.Part1=best w.Parent=Root
        task.delay(6,function() pcall(function() w:Destroy() end) end)
        return true
    end
    return false
end

-- // STEAL EGG — fly high, godmode, interact, ride back
local function stealEgg(egg,onDone)
    if not egg or not egg.Parent then
        if onDone then onDone(false) end return
    end
    enableGodMode()
    local highPos=egg.Position+Vector3.new(0,CFG.FLY_HEIGHT,0)
    flyTo(highPos,CFG.FLY_SPEED,function()
        local root=getRoot()
        -- fire all interaction methods
        local touch=egg:FindFirstChildOfClass("TouchTransmitter")
        if touch then
            pcall(firetouchinterest,root,egg,0)
            task.wait(0.06)
            pcall(firetouchinterest,root,egg,1)
        end
        local click=egg:FindFirstChildOfClass("ClickDetector")
        if click then pcall(fireclickdetector,click) end
        local prompt=egg:FindFirstChildOfClass("ProximityPrompt")
            or (egg.Parent and egg.Parent:FindFirstChildOfClass("ProximityPrompt"))
        if prompt then pcall(fireproximityprompt,prompt) end
        -- also try remote events named hatch/collect/open
        for _,v in ipairs(egg.Parent:GetDescendants()) do
            if v:IsA("RemoteEvent") then
                local nm=v.Name:lower()
                if nm:find("hatch") or nm:find("collect") or nm:find("open") or nm:find("egg") then
                    pcall(function() v:FireServer() end)
                end
            end
        end
        task.wait(0.3)
        disableGodMode()
        -- try ride mount, else speed boost
        local rode=rideNearestMount()
        if not rode then
            pcall(function()
                local h=getHuman()
                local prev=h.WalkSpeed
                h.WalkSpeed=CFG.WALK_SPEED
                task.delay(3,function() pcall(function() h.WalkSpeed=prev end) end)
            end)
        end
        if onDone then onDone(true) end
    end)
end

-- // HOLD LONGEST ADMIN ABUSE
local holdActive=false
local holdConn=nil
local holdBV=nil
local holdBG=nil

local function startHoldLongest(statusFn)
    if holdActive then return end
    holdActive=true
    enableGodMode()
    local Root=getRoot()
    local skyY=Root.Position.Y+CFG.HOLD_HEIGHT
    local skyPos=Vector3.new(Root.Position.X,skyY,Root.Position.Z)
    getHuman().PlatformStand=true

    holdBV=Instance.new("BodyVelocity",Root)
    holdBV.MaxForce=Vector3.new(1e6,1e6,1e6)
    holdBV.Velocity=Vector3.new(0,CFG.FLY_SPEED,0)

    holdBG=Instance.new("BodyGyro",Root)
    holdBG.MaxTorque=Vector3.new(1e6,1e6,1e6)
    holdBG.CFrame=Root.CFrame

    local reached=false
    holdConn=RunService.Heartbeat:Connect(function()
        if not holdActive then return end
        local root=getRoot()
        if not reached and root.Position.Y>=(skyY-10) then
            reached=true
            holdBV.Velocity=Vector3.new(0,0,0)
        end
        if reached then
            local diff=skyPos-root.Position
            holdBV.Velocity=diff.Magnitude>2 and diff.Unit*50 or Vector3.new(0,0,0)
            -- spam hold zone interactions
            for _,obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    local nm=obj.Name:lower()
                    if nm:find("hold") or nm:find("zone") or nm:find("claim") or nm:find("admin") or nm:find("platform") then
                        local touch=obj:FindFirstChildOfClass("TouchTransmitter")
                        if touch then pcall(firetouchinterest,root,obj,0) end
                        local click=obj:FindFirstChildOfClass("ClickDetector")
                        if click then pcall(fireclickdetector,click) end
                        local prompt=obj:FindFirstChildOfClass("ProximityPrompt")
                        if prompt then pcall(fireproximityprompt,prompt) end
                    end
                end
            end
        end
    end)
    if statusFn then statusFn("🌌 HOLD LONGEST — Active! Flying up!") end
end

local function stopHoldLongest(statusFn)
    holdActive=false
    if holdConn then holdConn:Disconnect() holdConn=nil end
    pcall(function() if holdBV  then holdBV:Destroy()  holdBV=nil  end end)
    pcall(function() if holdBG  then holdBG:Destroy()  holdBG=nil  end end)
    disableGodMode()
    pcall(function() getHuman().PlatformStand=false end)
    if statusFn then statusFn("⬛ Hold Longest — Stopped") end
end

-- // STATE
local State={
    autoSteal=false,stealOnce=false,doneOnce=false,stealing=false,
    selectedRar={Divine=true,Eternal=true,Secret=true,Cosmic=true},
}

-- // ─────────────────────────────────────────────
-- // UI
-- // ─────────────────────────────────────────────
local CoreGui=game:GetService("CoreGui")
pcall(function()
    local old=CoreGui:FindFirstChild("RockshiHub")
    if old then old:Destroy() end
end)

local ScreenGui=Instance.new("ScreenGui")
ScreenGui.Name="RockshiHub"
ScreenGui.ResetOnSpawn=false
ScreenGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder=999
ScreenGui.Parent=CoreGui

local C={
    bg      =Color3.fromRGB(8,10,20),
    panel   =Color3.fromRGB(13,17,35),
    card    =Color3.fromRGB(18,23,48),
    accent  =Color3.fromRGB(30,120,255),
    accentHi=Color3.fromRGB(80,170,255),
    text    =Color3.fromRGB(220,230,255),
    subtext =Color3.fromRGB(120,140,190),
    green   =Color3.fromRGB(50,220,120),
    red     =Color3.fromRGB(255,70,70),
    gold    =Color3.fromRGB(255,200,50),
    purple  =Color3.fromRGB(160,80,255),
}

local function mk(class,props,parent)
    local i=Instance.new(class)
    for k,v in pairs(props) do i[k]=v end
    if parent then i.Parent=parent end
    return i
end
local function corner(r,p) return mk("UICorner",{CornerRadius=UDim.new(0,r)},p) end
local function stroke(c,t,p) return mk("UIStroke",{Color=c,Thickness=t},p) end
local function pad(l,r,t,b,p)
    local u=Instance.new("UIPadding")
    u.PaddingLeft=UDim.new(0,l) u.PaddingRight=UDim.new(0,r)
    u.PaddingTop=UDim.new(0,t) u.PaddingBottom=UDim.new(0,b)
    u.Parent=p
end

-- // DRAGGABLE HELPER
local function makeDraggable(handle,target)
    local dragging,dragStart,startPos=false,nil,nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or
           input.UserInputType==Enum.UserInputType.Touch then
            dragging=true
            dragStart=input.Position
            startPos=target.Position
            input.Changed:Connect(function()
                if input.UserInputState==Enum.UserInputState.End then
                    dragging=false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or
            input.UserInputType==Enum.UserInputType.Touch) then
            local delta=input.Position-dragStart
            target.Position=UDim2.new(
                startPos.X.Scale,startPos.X.Offset+delta.X,
                startPos.Y.Scale,startPos.Y.Offset+delta.Y
            )
        end
    end)
end

-- // ── CIRCLE LOGO (draggable, particles) ────────
local CircleOuter=mk("Frame",{
    Size=UDim2.new(0,76,0,76),
    Position=UDim2.new(0,14,0.5,-38),
    BackgroundColor3=Color3.fromRGB(10,12,28),
    BorderSizePixel=0,
},ScreenGui)
corner(999,CircleOuter)
local outerStroke=stroke(C.accentHi,2.5,CircleOuter)

-- Animated glow ring
local GlowRing=mk("Frame",{
    Size=UDim2.new(1,16,1,16),
    Position=UDim2.new(0,-8,0,-8),
    BackgroundTransparency=1,BorderSizePixel=0,
},CircleOuter)
corner(999,GlowRing)
local glowS=stroke(C.accent,8,GlowRing)
glowS.Transparency=0.65
TweenService:Create(glowS,TweenInfo.new(1.4,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),
    {Transparency=0.9}):Play()

-- Rotating particle ring
local ParticleRing=mk("Frame",{
    Size=UDim2.new(1,26,1,26),
    Position=UDim2.new(0,-13,0,-13),
    BackgroundTransparency=1,BorderSizePixel=0,
},CircleOuter)
corner(999,ParticleRing)

-- Spawn 8 particle dots around ring
local particles={}
for i=1,8 do
    local angle=math.rad((i-1)*45)
    local radius=44
    local px=math.cos(angle)*radius
    local py=math.sin(angle)*radius
    local dot=mk("Frame",{
        Size=UDim2.new(0,5,0,5),
        Position=UDim2.new(0.5,px-2,0.5,py-2),
        BackgroundColor3=i%2==0 and C.accentHi or C.gold,
        BorderSizePixel=0,ZIndex=5,
    },ParticleRing)
    corner(999,dot)
    table.insert(particles,{dot=dot,angle=angle,radius=radius})
end

-- Rotate particles
local rotAngle=0
RunService.Heartbeat:Connect(function(dt)
    rotAngle=rotAngle+dt*1.8
    for i,p in ipairs(particles) do
        local a=p.angle+rotAngle
        local px=math.cos(a)*p.radius
        local py=math.sin(a)*p.radius
        p.dot.Position=UDim2.new(0.5,px-2,0.5,py-2)
        -- pulse size
        local s=4+math.sin(rotAngle*2+i)*1.5
        p.dot.Size=UDim2.new(0,s,0,s)
    end
end)

-- Logo text (Kakashi + Rock Lee vibe)
mk("TextLabel",{
    Size=UDim2.new(1,0,0,40),
    Position=UDim2.new(0,0,0,6),
    BackgroundTransparency=1,
    Text="🥋",
    TextSize=30,Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Center,
},CircleOuter)

mk("TextLabel",{
    Size=UDim2.new(1,0,0,14),
    Position=UDim2.new(0,0,1,-16),
    BackgroundTransparency=1,
    Text="RH",
    TextSize=10,Font=Enum.Font.GothamBold,
    TextColor3=C.gold,
    TextXAlignment=Enum.TextXAlignment.Center,
},CircleOuter)

local CircleBtn=mk("TextButton",{
    Size=UDim2.new(1,0,1,0),
    BackgroundTransparency=1,Text="",ZIndex=10,
},CircleOuter)

-- Make circle draggable
makeDraggable(CircleBtn,CircleOuter)

-- // ── MAIN FRAME ────────────────────────────────
local Main=mk("Frame",{
    Size=UDim2.new(0,440,0,620),
    Position=UDim2.new(0,104,0.5,-310),
    BackgroundColor3=C.bg,
    BorderSizePixel=0,Visible=false,
    ClipsDescendants=true,
},ScreenGui)
corner(16,Main)
stroke(C.accent,1.5,Main)

-- Animated top accent line
local TopLine=mk("Frame",{
    Size=UDim2.new(0,80,0,2),
    Position=UDim2.new(0.5,-40,0,0),
    BackgroundColor3=C.accentHi,BorderSizePixel=0,
},Main)
corner(2,TopLine)
TweenService:Create(TopLine,TweenInfo.new(1.5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),
    {Size=UDim2.new(0,200,0,2),Position=UDim2.new(0.5,-100,0,0),BackgroundColor3=C.gold}):Play()

-- // ── HEADER ────────────────────────────────────
local Header=mk("Frame",{
    Size=UDim2.new(1,0,0,56),
    BackgroundColor3=C.panel,BorderSizePixel=0,
},Main)
corner(16,Header)
mk("Frame",{Size=UDim2.new(1,0,0,16),Position=UDim2.new(0,0,1,-16),BackgroundColor3=C.panel,BorderSizePixel=0},Header)

mk("TextLabel",{Size=UDim2.new(0,36,0,36),Position=UDim2.new(0,12,0.5,-18),
    BackgroundTransparency=1,Text="🥋",TextSize=26,Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Center},Header)

mk("TextLabel",{Size=UDim2.new(0,220,0,26),Position=UDim2.new(0,52,0,8),
    BackgroundTransparency=1,Text="ROCKSHI HUB",TextColor3=C.accentHi,
    TextSize=17,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},Header)

mk("TextLabel",{Size=UDim2.new(0,220,0,16),Position=UDim2.new(0,52,0,32),
    BackgroundTransparency=1,Text="Egg Stealer — by nullstate",TextColor3=C.subtext,
    TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},Header)

local VB=mk("Frame",{Size=UDim2.new(0,42,0,20),Position=UDim2.new(1,-90,0.5,-10),
    BackgroundColor3=C.accent,BorderSizePixel=0},Header)
corner(6,VB)
mk("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="v3.0",
    TextColor3=Color3.new(1,1,1),TextSize=10,Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Center},VB)

local CloseBtn=mk("TextButton",{Size=UDim2.new(0,26,0,26),Position=UDim2.new(1,-36,0.5,-13),
    BackgroundColor3=C.red,Text="✕",TextColor3=Color3.new(1,1,1),TextSize=13,
    Font=Enum.Font.GothamBold,BorderSizePixel=0},Header)
corner(999,CloseBtn)

-- Make header+main draggable
makeDraggable(Header,Main)

-- // ── BODY ──────────────────────────────────────
local Body=mk("Frame",{Size=UDim2.new(1,-16,1,-64),Position=UDim2.new(0,8,0,62),
    BackgroundTransparency=1},Main)
mk("UIListLayout",{Padding=UDim.new(0,7),SortOrder=Enum.SortOrder.LayoutOrder},Body)

-- // STATUS
local StatusCard=mk("Frame",{Size=UDim2.new(1,0,0,34),BackgroundColor3=C.card,
    BorderSizePixel=0,LayoutOrder=1},Body)
corner(10,StatusCard)
local StatusDot=mk("Frame",{Size=UDim2.new(0,10,0,10),Position=UDim2.new(0,12,0.5,-5),
    BackgroundColor3=C.subtext,BorderSizePixel=0},StatusCard)
corner(999,StatusDot)
local StatusTxt=mk("TextLabel",{Size=UDim2.new(1,-30,1,0),Position=UDim2.new(0,28,0,0),
    BackgroundTransparency=1,Text="Idle — ROCKSHI HUB ready",TextColor3=C.text,
    TextSize=12,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},StatusCard)

local function setStatus(txt,dotColor)
    StatusTxt.Text=txt
    StatusDot.BackgroundColor3=dotColor or C.subtext
end

-- // HOLD LONGEST BUTTON (own section)
local HoldCard=mk("Frame",{Size=UDim2.new(1,0,0,68),BackgroundColor3=C.card,
    BorderSizePixel=0,LayoutOrder=2},Body)
corner(10,HoldCard)
pad(10,10,8,8,HoldCard)

mk("TextLabel",{Size=UDim2.new(1,0,0,14),BackgroundTransparency=1,
    Text="⚡ ADMIN ABUSE",TextColor3=C.subtext,TextSize=10,Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left},HoldCard)

local HoldBtn=mk("TextButton",{
    Size=UDim2.new(1,0,0,38),Position=UDim2.new(0,0,0,18),
    BackgroundColor3=C.purple,
    Text="👑   HOLD LONGEST   —   START",
    TextColor3=Color3.new(1,1,1),TextSize=13,Font=Enum.Font.GothamBold,
    BorderSizePixel=0,
},HoldCard)
corner(10,HoldBtn)
stroke(Color3.fromRGB(200,120,255),1.2,HoldBtn)

local holdOn=false
HoldBtn.MouseButton1Click:Connect(function()
    holdOn=not holdOn
    if holdOn then
        HoldBtn.Text="👑   HOLD LONGEST   —   STOP"
        HoldBtn.BackgroundColor3=C.red
        startHoldLongest(function(t) setStatus(t,C.gold) end)
    else
        HoldBtn.Text="👑   HOLD LONGEST   —   START"
        HoldBtn.BackgroundColor3=C.purple
        stopHoldLongest(function(t) setStatus(t,C.subtext) end)
    end
end)

-- // FILTER
local FilterCard=mk("Frame",{Size=UDim2.new(1,0,0,72),BackgroundColor3=C.card,
    BorderSizePixel=0,LayoutOrder=3},Body)
corner(10,FilterCard)
pad(10,10,6,6,FilterCard)
mk("TextLabel",{Size=UDim2.new(1,0,0,16),BackgroundTransparency=1,
    Text="FILTER BY RARITY",TextColor3=C.subtext,TextSize=10,Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left},FilterCard)

local FilterRow=mk("Frame",{Size=UDim2.new(1,0,0,32),Position=UDim2.new(0,0,0,22),
    BackgroundTransparency=1},FilterCard)
mk("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,
    Padding=UDim.new(0,6),VerticalAlignment=Enum.VerticalAlignment.Center},FilterRow)

local FILTER_DATA={{name="Divine",emoji="🟨"},{name="Eternal",emoji="🌌"},
    {name="Secret",emoji="⬛"},{name="Cosmic",emoji="🟪"}}

for _,fd in ipairs(FILTER_DATA) do
    local rd=getRD(fd.name)
    local fb=mk("TextButton",{Size=UDim2.new(0,88,0,28),BackgroundColor3=rd.color,
        Text=fd.emoji.." "..fd.name,TextColor3=Color3.new(1,1,1),TextSize=11,
        Font=Enum.Font.GothamBold,BorderSizePixel=0},FilterRow)
    corner(8,fb)
    fb.MouseButton1Click:Connect(function()
        State.selectedRar[fd.name]=not State.selectedRar[fd.name]
        fb.BackgroundTransparency=State.selectedRar[fd.name] and 0 or 0.65
        fb.TextTransparency=State.selectedRar[fd.name] and 0 or 0.4
    end)
end

-- // TOGGLE HELPER
local function makeToggle(parent,xOff,label,accentColor)
    local frame=mk("Frame",{Size=UDim2.new(0,195,0,50),
        Position=UDim2.new(0,xOff,0,0),BackgroundTransparency=1},parent)
    local track=mk("Frame",{Size=UDim2.new(0,46,0,24),Position=UDim2.new(0,10,0.5,-12),
        BackgroundColor3=Color3.fromRGB(30,35,60),BorderSizePixel=0},frame)
    corner(999,track) stroke(accentColor,1,track)
    local thumb=mk("Frame",{Size=UDim2.new(0,18,0,18),Position=UDim2.new(0,3,0.5,-9),
        BackgroundColor3=C.subtext,BorderSizePixel=0},track)
    corner(999,thumb)
    mk("TextLabel",{Size=UDim2.new(0,130,0,20),Position=UDim2.new(0,58,0.5,-10),
        BackgroundTransparency=1,Text=label,TextColor3=C.text,TextSize=12,
        Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},frame)
    local togBtn=mk("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
        Text="",ZIndex=5},frame)
    local on=false
    local function setOn(v)
        on=v
        local goal=v and UDim2.new(0,25,0.5,-9) or UDim2.new(0,3,0.5,-9)
        TweenService:Create(thumb,TweenInfo.new(0.15),
            {Position=goal,BackgroundColor3=v and accentColor or C.subtext}):Play()
        TweenService:Create(track,TweenInfo.new(0.15),
            {BackgroundColor3=v and Color3.fromRGB(20,40,80) or Color3.fromRGB(30,35,60)}):Play()
    end
    togBtn.MouseButton1Click:Connect(function() setOn(not on) end)
    return togBtn,function() return on end,setOn
end

-- // CONTROLS
local CtrlCard=mk("Frame",{Size=UDim2.new(1,0,0,50),BackgroundColor3=C.card,
    BorderSizePixel=0,LayoutOrder=4},Body)
corner(10,CtrlCard)
local _,getAutoOn,setAutoOn=makeToggle(CtrlCard,0,"Auto Steal",C.accentHi)
local _,getOnceOn,setOnceOn=makeToggle(CtrlCard,205,"Steal Once",C.gold)

-- // EGG LIST
local ListCard=mk("Frame",{Size=UDim2.new(1,0,0,290),BackgroundColor3=C.card,
    BorderSizePixel=0,LayoutOrder=5},Body)
corner(10,ListCard)
mk("TextLabel",{Size=UDim2.new(1,-16,0,20),Position=UDim2.new(0,8,0,6),
    BackgroundTransparency=1,Text="🗺  EGGS — ENTIRE MAP",TextColor3=C.subtext,
    TextSize=10,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},ListCard)

local Scroll=mk("ScrollingFrame",{Size=UDim2.new(1,-8,1,-30),Position=UDim2.new(0,4,0,26),
    BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,
    ScrollBarImageColor3=C.accent,CanvasSize=UDim2.new(0,0,0,0),
    AutomaticCanvasSize=Enum.AutomaticSize.Y},ListCard)
mk("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder},Scroll)
pad(2,2,2,4,Scroll)

-- // EGG ROW
local function buildRow(data,idx)
    local rd=getRD(data.rarity)
    local row=mk("TextButton",{Size=UDim2.new(1,-4,0,54),
        BackgroundColor3=Color3.fromRGB(14,18,38),BorderSizePixel=0,Text="",
        LayoutOrder=idx},Scroll)
    corner(8,row)

    -- hover effect
    row.MouseEnter:Connect(function()
        TweenService:Create(row,TweenInfo.new(0.12),
            {BackgroundColor3=Color3.fromRGB(22,28,55)}):Play()
    end)
    row.MouseLeave:Connect(function()
        TweenService:Create(row,TweenInfo.new(0.12),
            {BackgroundColor3=Color3.fromRGB(14,18,38)}):Play()
    end)

    local stripe=mk("Frame",{Size=UDim2.new(0,4,1,-8),Position=UDim2.new(0,4,0,4),
        BackgroundColor3=rd.color,BorderSizePixel=0},row)
    corner(4,stripe)
    mk("TextLabel",{Size=UDim2.new(0,28,0,28),Position=UDim2.new(0,12,0.5,-14),
        BackgroundTransparency=1,Text=rd.emoji,TextSize=18,Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Center},row)
    mk("TextLabel",{Size=UDim2.new(1,-135,0,20),Position=UDim2.new(0,44,0,8),
        BackgroundTransparency=1,Text=data.pet,TextColor3=C.text,TextSize=13,
        Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd},row)
    mk("TextLabel",{Size=UDim2.new(1,-135,0,16),Position=UDim2.new(0,44,0,29),
        BackgroundTransparency=1,
        Text=data.rarity.."  ·  "..data.dist.." studs away",
        TextColor3=rd.color,TextSize=10,Font=Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Left},row)

    local stBtn=mk("TextButton",{Size=UDim2.new(0,60,0,32),
        Position=UDim2.new(1,-68,0.5,-16),BackgroundColor3=C.accent,
        Text="STEAL",TextColor3=Color3.new(1,1,1),TextSize=11,
        Font=Enum.Font.GothamBold,BorderSizePixel=0},row)
    corner(8,stBtn)
    stroke(C.accentHi,1,stBtn)

    stBtn.MouseButton1Click:Connect(function()
        if State.stealing then return end
        State.stealing=true
        setStatus("🚀 Flying to: "..data.pet,C.accentHi)
        StatusDot.BackgroundColor3=C.accentHi
        stealEgg(data.egg,function(ok)
            State.stealing=false
            setStatus(ok and "✅ Stolen: "..data.pet or "❌ Failed",
                ok and C.green or C.red)
        end)
    end)
end

-- // REFRESH
local function refreshList()
    for _,c in ipairs(Scroll:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    local eggs=scanEggs()
    local added=0
    for i,data in ipairs(eggs) do
        if State.selectedRar[data.rarity] then
            buildRow(data,i) added=added+1
        end
    end
    if added==0 then
        mk("TextLabel",{Size=UDim2.new(1,0,0,40),BackgroundTransparency=1,
            Text="No matching eggs on the map",TextColor3=C.subtext,TextSize=12,
            Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Center},Scroll)
    end
end

-- // AUTO STEAL LOOP — smooth, no fake, real rarest target
local stealOnceDidIt=false
task.spawn(function()
    while task.wait(CFG.STEAL_DELAY) do
        if not getAutoOn() then
            stealOnceDidIt=false
            continue
        end
        if State.stealing then continue end
        if getOnceOn() and stealOnceDidIt then
            setAutoOn(false)
            setStatus("✅ Steal Once done!",C.green)
            stealOnceDidIt=false
            continue
        end
        -- find rarest egg on entire map
        local eggs=scanEggs()
        local target=nil
        for _,data in ipairs(eggs) do
            if State.selectedRar[data.rarity] then
                target=data break
            end
        end
        if not target then
            setStatus("🔍 Scanning map for eggs...",C.subtext)
            continue
        end
        State.stealing=true
        setStatus("🚀 Auto → "..target.pet.." ["..target.rarity.."]",C.accentHi)
        StatusDot.BackgroundColor3=C.accentHi
        stealEgg(target.egg,function(ok)
            State.stealing=false
            if getOnceOn() then stealOnceDidIt=true end
            setStatus(ok and "✅ Got: "..target.pet or "❌ Missed — retrying",
                ok and C.green or C.red)
        end)
    end
end)

-- // SCAN LOOP
task.spawn(function()
    while task.wait(CFG.SCAN_INTERVAL) do
        if Main.Visible then refreshList() end
    end
end)

-- // TOGGLES
CircleBtn.MouseButton1Click:Connect(function()
    Main.Visible=not Main.Visible
    if Main.Visible then refreshList() end
end)
CloseBtn.MouseButton1Click:Connect(function() Main.Visible=false end)

-- // RESPAWN HANDLE
LocalPlayer.CharacterAdded:Connect(function()
    State.stealing=false
    stopFly()
    if holdActive then stopHoldLongest() holdOn=false
        HoldBtn.Text="👑   HOLD LONGEST   —   START"
        HoldBtn.BackgroundColor3=C.purple
    end
    setStatus("🔄 Respawned — ROCKSHI HUB ready",C.subtext)
end)

print("🥋 ROCKSHI HUB v3 Loaded — Click the circle!")
