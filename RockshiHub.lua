-- // ============================================
-- // 🥋 ROCKSHI HUB — Axon Hub Style, Blue Theme
-- // Game: Steal An Egg
-- // Executor: KRNL / Synapse X / Fluxus / Delta
-- // Unbannable: Client-only reads
-- // ============================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer      = Players.LocalPlayer

local function getChar()  return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait() end
local function getRoot()  local c=getChar() return c and c:FindFirstChild("HumanoidRootPart") end
local function getHuman() local c=getChar() return c and c:FindFirstChildOfClass("Humanoid") end

-- // COLORS — Blue Theme like Axon Hub but blue
local C = {
    bg       = Color3.fromRGB(14,16,26),
    sidebar  = Color3.fromRGB(18,20,34),
    panel    = Color3.fromRGB(22,25,42),
    card     = Color3.fromRGB(28,32,52),
    card2    = Color3.fromRGB(32,36,58),
    accent   = Color3.fromRGB(60,140,255),
    accentHi = Color3.fromRGB(100,170,255),
    accentDim= Color3.fromRGB(40,80,160),
    text     = Color3.fromRGB(220,225,240),
    subtext  = Color3.fromRGB(130,140,170),
    dim      = Color3.fromRGB(80,90,120),
    green    = Color3.fromRGB(80,220,140),
    red      = Color3.fromRGB(255,80,80),
    gold     = Color3.fromRGB(255,200,60),
    purple   = Color3.fromRGB(160,80,255),
    border   = Color3.fromRGB(38,44,72),
}

-- // RARITY
local RARITY_DATA = {
    {name="Cosmic",   color=Color3.fromRGB(160,80,255),  rank=1},
    {name="Divine",   color=Color3.fromRGB(255,215,0),   rank=2},
    {name="Eternal",  color=Color3.fromRGB(180,60,255),  rank=3},
    {name="Secret",   color=Color3.fromRGB(255,60,60),   rank=4},
    {name="Mythic",   color=Color3.fromRGB(255,140,0),   rank=5},
    {name="Legendary",color=Color3.fromRGB(255,200,0),   rank=6},
    {name="Epic",     color=Color3.fromRGB(140,0,255),   rank=7},
    {name="Rare",     color=Color3.fromRGB(0,120,255),   rank=8},
    {name="Uncommon", color=Color3.fromRGB(0,200,80),    rank=9},
    {name="Common",   color=Color3.fromRGB(160,160,160), rank=10},
}
local RARITY_MAP={}
for _,r in ipairs(RARITY_DATA) do RARITY_MAP[r.name]=r end
local function getRD(n) return RARITY_MAP[n] or RARITY_MAP["Common"] end

-- // ─────────────────────────────────────────────
-- // SCANNERS
-- // ─────────────────────────────────────────────
local function predictRarity(obj)
    local checks={"cosmic","divine","eternal","secret","mythic","legendary","epic","rare","uncommon"}
    local mapped={"Cosmic","Divine","Eternal","Secret","Mythic","Legendary","Epic","Rare","Uncommon"}
    local nm=obj.Name:lower()
    for i,kw in ipairs(checks) do if nm:find(kw) then return mapped[i] end end
    for _,v in ipairs(obj:GetDescendants()) do
        local t=""
        if v:IsA("StringValue") then t=(v.Value or ""):lower()
        elseif v:IsA("TextLabel") then t=(v.Text or ""):lower()
        elseif v:IsA("IntValue") and v.Name:lower():find("rar") then
            local m={[1]="Cosmic",[2]="Divine",[3]="Eternal",[4]="Secret",[5]="Mythic",[6]="Legendary",[7]="Epic",[8]="Rare",[9]="Uncommon"}
            if m[v.Value] then return m[v.Value] end
        end
        for i,kw in ipairs(checks) do if t:find(kw) then return mapped[i] end end
    end
    if obj.Parent then
        local pnm=obj.Parent.Name:lower()
        for i,kw in ipairs(checks) do if pnm:find(kw) then return mapped[i] end end
    end
    return "Common"
end

local function predictPet(obj)
    for _,v in ipairs(obj:GetDescendants()) do
        if v:IsA("StringValue") then
            local nm=v.Name:lower()
            if (nm:find("pet") or nm:find("reward") or nm:find("hatch") or nm:find("item") or nm:find("name") or nm:find("prize")) and v.Value~="" then
                return v.Value end
        end
    end
    for _,v in ipairs(obj:GetDescendants()) do
        if v:IsA("TextLabel") and v.Text~="" and #v.Text<50 then
            local t=v.Text:lower()
            if not t:find("click") and not t:find("press") and not t:find("open") and not t:find("buy") then return v.Text end
        end
    end
    if obj.Parent then
        for _,v in ipairs(obj.Parent:GetChildren()) do
            if v:IsA("StringValue") and v.Value~="" then
                local nm=v.Name:lower()
                if nm:find("pet") or nm:find("reward") or nm:find("name") then return v.Value end
            end
        end
    end
    local nm=obj.Name:gsub("[Ee]gg",""):gsub("^%s+",""):gsub("%s+$","")
    return nm~="" and nm.." Pet" or "Unknown Pet"
end

local function getEggValue(obj)
    for _,v in ipairs(obj:GetDescendants()) do
        if (v:IsA("NumberValue") or v:IsA("IntValue")) then
            local nm=v.Name:lower()
            if (nm:find("value") or nm:find("coin") or nm:find("price") or nm:find("worth")) and v.Value>0 then
                local val=v.Value
                if val>=1e9 then return string.format("%.2fB",val/1e9)
                elseif val>=1e6 then return string.format("%.2fM",val/1e6)
                elseif val>=1e3 then return string.format("%.1fK",val/1e3) end
                return tostring(val)
            end
        end
    end
    return ""
end

local function getPetImage(obj)
    for _,v in ipairs(obj:GetDescendants()) do
        if v:IsA("ImageLabel") and v.Image~="" then return v.Image end
    end
    for _,v in ipairs(obj:GetDescendants()) do
        if v:IsA("Decal") and v.Texture~="" then return v.Texture end
    end
    return ""
end

local function scanAllEggs()
    local root=getRoot()
    if not root then return {} end
    local found,seen={},{}
    local function recurse(folder)
        local ok,children=pcall(function() return folder:GetChildren() end)
        if not ok then return end
        for _,obj in ipairs(children) do
            if not seen[obj] then
                seen[obj]=true
                local nm=obj.Name:lower()
                if nm:find("egg") then
                    local pos=nil
                    if obj:IsA("BasePart") then pos=obj.Position
                    elseif obj:IsA("Model") then
                        local ok2,cf=pcall(function() return obj:GetModelCFrame() end)
                        if ok2 then pos=cf.Position end
                    end
                    if pos then
                        table.insert(found,{
                            obj    = obj,
                            rarity = predictRarity(obj),
                            pet    = predictPet(obj),
                            value  = getEggValue(obj),
                            dist   = math.floor((root.Position-pos).Magnitude),
                            pos    = pos,
                            image  = getPetImage(obj),
                        })
                    end
                end
                pcall(recurse,obj)
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

-- // ─────────────────────────────────────────────
-- // GOD MODE
-- // ─────────────────────────────────────────────
local godConn=nil
local function enableGodMode()
    pcall(function()
        local hum=getHuman() if not hum then return end
        hum.MaxHealth=math.huge hum.Health=math.huge
        if godConn then godConn:Disconnect() end
        godConn=hum.HealthChanged:Connect(function(hp)
            if hp<hum.MaxHealth then hum.Health=math.huge end
        end)
        hum:SetStateEnabled(Enum.HumanoidStateType.Dead,false)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown,false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,false)
        for _,p in ipairs(getChar():GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide=false end
        end
    end)
end
local function disableGodMode()
    if godConn then godConn:Disconnect() godConn=nil end
    pcall(function()
        local hum=getHuman() if not hum then return end
        hum.MaxHealth=100 hum.Health=100
        hum:SetStateEnabled(Enum.HumanoidStateType.Dead,true)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown,true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,true)
        for _,p in ipairs(getChar():GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide=true end
        end
    end)
end

-- // ─────────────────────────────────────────────
-- // FLY ENGINE
-- // ─────────────────────────────────────────────
local flyConn,bVel,bGyro,isFly=nil,nil,nil,false
local function stopFly()
    isFly=false
    if flyConn then flyConn:Disconnect() flyConn=nil end
    pcall(function() if bVel  then bVel:Destroy()  bVel=nil  end end)
    pcall(function() if bGyro then bGyro:Destroy() bGyro=nil end end)
    pcall(function() local h=getHuman() if h then h.PlatformStand=false end end)
end
local function flyTo(pos,speed,cb)
    stopFly() isFly=true
    pcall(function()
        local root=getRoot() local human=getHuman()
        if not root or not human then if cb then cb() end return end
        human.PlatformStand=true
        bVel=Instance.new("BodyVelocity",root)
        bVel.MaxForce=Vector3.new(1e6,1e6,1e6) bVel.Velocity=Vector3.new(0,0,0)
        bGyro=Instance.new("BodyGyro",root)
        bGyro.MaxTorque=Vector3.new(1e6,1e6,1e6) bGyro.P=1e4
        flyConn=RunService.Heartbeat:Connect(function()
            if not isFly then return end
            local r=getRoot() if not r then stopFly() return end
            local diff=pos-r.Position
            if diff.Magnitude<3 then stopFly() if cb then task.spawn(cb) end return end
            local dir=diff.Unit
            bVel.Velocity=dir*(speed or 180)
            bGyro.CFrame=CFrame.new(r.Position,r.Position+dir)
        end)
    end)
end

local function rideBack()
    local root=getRoot() if not root then return end
    local best,bd=nil,math.huge
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            for _,kw in ipairs({"mount","monster","creature","ride","mob","boss","npc","dinosaur"}) do
                if obj.Name:lower():find(kw) then
                    local d=(root.Position-obj.Position).Magnitude
                    if d<bd and d<100 then bd=d best=obj end
                    break
                end
            end
        end
    end
    if best then
        root.CFrame=CFrame.new(best.Position+Vector3.new(0,5,0))
        local w=Instance.new("WeldConstraint") w.Part0=root w.Part1=best w.Parent=root
        task.delay(6,function() pcall(function() w:Destroy() end) end)
    else
        pcall(function()
            local h=getHuman() if not h then return end
            local prev=h.WalkSpeed h.WalkSpeed=80
            task.delay(4,function() pcall(function() h.WalkSpeed=prev end) end)
        end)
    end
end

local function stealEgg(data,onDone)
    if not data or not data.obj or not data.obj.Parent then if onDone then onDone(false) end return end
    enableGodMode()
    local highPos=data.pos+Vector3.new(0,75,0)
    flyTo(highPos,180,function()
        local root=getRoot()
        if not root then disableGodMode() if onDone then onDone(false) end return end
        root.CFrame=CFrame.new(data.pos+Vector3.new(0,3,0))
        task.wait(0.05)
        local obj=data.obj
        local touch=obj:FindFirstChildOfClass("TouchTransmitter")
        if touch then pcall(firetouchinterest,root,obj,0) task.wait(0.05) pcall(firetouchinterest,root,obj,1) end
        local click=obj:FindFirstChildOfClass("ClickDetector")
        if click then pcall(fireclickdetector,click) end
        local prompt=obj:FindFirstChildOfClass("ProximityPrompt") or (obj.Parent and obj.Parent:FindFirstChildOfClass("ProximityPrompt"))
        if prompt then pcall(fireproximityprompt,prompt) end
        for _,v in ipairs(workspace:GetDescendants()) do
            if v:IsA("RemoteEvent") then
                local nm=v.Name:lower()
                if nm:find("hatch") or nm:find("collect") or nm:find("open") or nm:find("egg") or nm:find("claim") then
                    pcall(function() v:FireServer() end)
                end
            end
        end
        task.wait(0.2) disableGodMode() rideBack()
        if onDone then onDone(true) end
    end)
end

-- // HOLD LONGEST
local holdActive=false local holdConn,holdBV,holdBG=nil,nil,nil
local function startHoldLongest()
    if holdActive then return end
    holdActive=true enableGodMode()
    pcall(function()
        local root=getRoot() if not root then return end
        local skyY=root.Position.Y+300
        local skyPos=Vector3.new(root.Position.X,skyY,root.Position.Z)
        local human=getHuman() if human then human.PlatformStand=true end
        holdBV=Instance.new("BodyVelocity",root) holdBV.MaxForce=Vector3.new(1e6,1e6,1e6) holdBV.Velocity=Vector3.new(0,200,0)
        holdBG=Instance.new("BodyGyro",root) holdBG.MaxTorque=Vector3.new(1e6,1e6,1e6) holdBG.CFrame=root.CFrame
        local reached=false
        holdConn=RunService.Heartbeat:Connect(function()
            if not holdActive then return end
            local r=getRoot() if not r then return end
            if not reached and r.Position.Y>=skyY-10 then reached=true holdBV.Velocity=Vector3.new(0,0,0) end
            if reached then
                local diff=skyPos-r.Position
                holdBV.Velocity=diff.Magnitude>2 and diff.Unit*50 or Vector3.new(0,0,0)
                for _,obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") then
                        local nm=obj.Name:lower()
                        if nm:find("hold") or nm:find("zone") or nm:find("claim") or nm:find("admin") or nm:find("platform") then
                            local touch=obj:FindFirstChildOfClass("TouchTransmitter")
                            if touch then pcall(firetouchinterest,r,obj,0) end
                            local click=obj:FindFirstChildOfClass("ClickDetector")
                            if click then pcall(fireclickdetector,click) end
                            local prompt=obj:FindFirstChildOfClass("ProximityPrompt")
                            if prompt then pcall(fireproximityprompt,prompt) end
                        end
                    end
                end
            end
        end)
    end)
end
local function stopHoldLongest()
    holdActive=false
    if holdConn then holdConn:Disconnect() holdConn=nil end
    pcall(function() if holdBV then holdBV:Destroy() holdBV=nil end end)
    pcall(function() if holdBG then holdBG:Destroy() holdBG=nil end end)
    disableGodMode()
    pcall(function() local h=getHuman() if h then h.PlatformStand=false end end)
end

-- // STATE
local State={
    loopActive=false, stealing=false, eggList={},
    selectedRar={Cosmic=true,Divine=true,Eternal=true,Secret=true},
    currentTab="autoSteal",
}

-- // ─────────────────────────────────────────────
-- // UI BUILD
-- // ─────────────────────────────────────────────
local CoreGui=game:GetService("CoreGui")
pcall(function() local old=CoreGui:FindFirstChild("RockshiHubUI") if old then old:Destroy() end end)

local Screen=Instance.new("ScreenGui")
Screen.Name="RockshiHubUI" Screen.ResetOnSpawn=false
Screen.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
Screen.DisplayOrder=999 Screen.Parent=CoreGui

local function mk(class,props,parent)
    local i=Instance.new(class)
    for k,v in pairs(props) do i[k]=v end
    if parent then i.Parent=parent end
    return i
end
local function corner(r,p) mk("UICorner",{CornerRadius=UDim.new(0,r)},p) end
local function pad(l,r,t,b,p)
    local u=Instance.new("UIPadding")
    u.PaddingLeft=UDim.new(0,l) u.PaddingRight=UDim.new(0,r)
    u.PaddingTop=UDim.new(0,t) u.PaddingBottom=UDim.new(0,b) u.Parent=p
end
local function divider(parent,layoutOrder)
    local d=mk("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=C.border,BorderSizePixel=0,LayoutOrder=layoutOrder or 99},parent)
    return d
end
local function makeDraggable(handle,target)
    local drag,ds,sp=false,nil,nil
    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            drag=true ds=inp.Position sp=target.Position
            inp.Changed:Connect(function()
                if inp.UserInputState==Enum.UserInputState.End then drag=false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if drag and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
            local d=inp.Position-ds
            target.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
        end
    end)
end

-- toggle switch builder
local function makeToggle(parent,xOff,yOff,defaultOn)
    local track=mk("Frame",{Size=UDim2.new(0,44,0,22),Position=UDim2.new(0,xOff,0,yOff),BackgroundColor3=defaultOn and C.accentDim or Color3.fromRGB(35,40,65),BorderSizePixel=0},parent)
    corner(999,track)
    local thumb=mk("Frame",{Size=UDim2.new(0,16,0,16),Position=defaultOn and UDim2.new(0,25,0.5,-8) or UDim2.new(0,3,0.5,-8),BackgroundColor3=defaultOn and C.accent or C.dim,BorderSizePixel=0},track)
    corner(999,thumb)
    local btn=mk("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=5},track)
    local on=defaultOn or false
    local function setOn(v)
        on=v
        local goal=v and UDim2.new(0,25,0.5,-8) or UDim2.new(0,3,0.5,-8)
        TweenService:Create(thumb,TweenInfo.new(0.15),{Position=goal,BackgroundColor3=v and C.accent or C.dim}):Play()
        TweenService:Create(track,TweenInfo.new(0.15),{BackgroundColor3=v and C.accentDim or Color3.fromRGB(35,40,65)}):Play()
    end
    local callbacks={}
    btn.MouseButton1Click:Connect(function()
        setOn(not on)
        for _,cb in ipairs(callbacks) do pcall(cb,on) end
    end)
    return {setOn=setOn,getOn=function() return on end,onChanged=function(cb) table.insert(callbacks,cb) end,track=track}
end

-- // ─────────────────────────────────────────────
-- // DRAGGABLE CIRCLE ICON
-- // ─────────────────────────────────────────────
local IconWrap=mk("Frame",{Size=UDim2.new(0,76,0,76),Position=UDim2.new(0,10,0,120),BackgroundColor3=C.sidebar,BorderSizePixel=0},Screen)
corner(16,IconWrap)
mk("UIStroke",{Color=C.border,Thickness=1.5},IconWrap)

-- Particle ring
local PRing=mk("Frame",{Size=UDim2.new(1,22,1,22),Position=UDim2.new(0,-11,0,-11),BackgroundTransparency=1,BorderSizePixel=0},IconWrap)
corner(999,PRing)
local particles={}
for i=1,10 do
    local a=math.rad((i-1)*36) local r=44
    local dot=mk("Frame",{Size=UDim2.new(0,4,0,4),Position=UDim2.new(0.5,math.cos(a)*r-2,0.5,math.sin(a)*r-2),BackgroundColor3=i%3==0 and C.gold or i%2==0 and C.accentHi or C.accent,BorderSizePixel=0,ZIndex=5},PRing)
    corner(999,dot)
    table.insert(particles,{dot=dot,angle=a,r=r})
end
local rot=0
RunService.Heartbeat:Connect(function(dt)
    rot=rot+dt*1.8
    for i,p in ipairs(particles) do
        local a=p.angle+rot
        p.dot.Position=UDim2.new(0.5,math.cos(a)*p.r-2,0.5,math.sin(a)*p.r-2)
        local s=3+math.sin(rot*2+i)*1.2
        p.dot.Size=UDim2.new(0,s,0,s)
    end
end)

mk("TextLabel",{Size=UDim2.new(1,0,0,44),Position=UDim2.new(0,0,0,4),BackgroundTransparency=1,Text="🥋",TextSize=30,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center},IconWrap)
mk("TextLabel",{Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,1,-16),BackgroundTransparency=1,Text="RH",TextSize=9,Font=Enum.Font.GothamBold,TextColor3=C.accentHi,TextXAlignment=Enum.TextXAlignment.Center},IconWrap)

local IconBtn=mk("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=10},IconWrap)
makeDraggable(IconBtn,IconWrap)

-- // ─────────────────────────────────────────────
-- // MAIN WINDOW — Axon Hub layout
-- // ─────────────────────────────────────────────
local Window=mk("Frame",{
    Size=UDim2.new(0,860,0,580),
    Position=UDim2.new(0.5,-430,0.5,-290),
    BackgroundColor3=C.bg,
    BorderSizePixel=0,
    Visible=false,
    ClipsDescendants=true,
},Screen)
corner(12,Window)
mk("UIStroke",{Color=C.border,Thickness=1},Window)

-- // TITLE BAR
local TitleBar=mk("Frame",{Size=UDim2.new(1,0,0,40),BackgroundColor3=C.sidebar,BorderSizePixel=0},Window)
mk("Frame",{Size=UDim2.new(1,0,0,10),Position=UDim2.new(0,0,1,-10),BackgroundColor3=C.sidebar,BorderSizePixel=0},TitleBar)

-- Traffic lights
local function trafficLight(x,col)
    local f=mk("Frame",{Size=UDim2.new(0,13,0,13),Position=UDim2.new(0,x,0.5,-6),BackgroundColor3=col,BorderSizePixel=0},TitleBar)
    corner(999,f) return f
end
trafficLight(12,Color3.fromRGB(255,95,87))
trafficLight(30,Color3.fromRGB(255,189,46))
trafficLight(48,Color3.fromRGB(40,200,64))

-- Globe icon
mk("TextLabel",{Size=UDim2.new(0,20,0,20),Position=UDim2.new(0,68,0.5,-10),BackgroundTransparency=1,Text="🌐",TextSize=14,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center},TitleBar)

-- Search bar
local SearchBar=mk("Frame",{Size=UDim2.new(0,200,0,26),Position=UDim2.new(0,380,0.5,-13),BackgroundColor3=C.panel,BorderSizePixel=0},TitleBar)
corner(6,SearchBar)
mk("TextLabel",{Size=UDim2.new(0,20,1,0),Position=UDim2.new(0,6,0,0),BackgroundTransparency=1,Text="🔍",TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Center},SearchBar)
local SearchInput=mk("TextBox",{Size=UDim2.new(1,-28,1,0),Position=UDim2.new(0,24,0,0),BackgroundTransparency=1,Text="",PlaceholderText="Search...",TextColor3=C.text,PlaceholderColor3=C.dim,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false},SearchBar)

-- Tab title
local TabTitle=mk("TextLabel",{Size=UDim2.new(0,200,1,0),Position=UDim2.new(0.5,-100,0,0),BackgroundTransparency=1,Text="Auto Steal",TextColor3=C.text,TextSize=13,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center},TitleBar)

-- Icons right
mk("TextButton",{Size=UDim2.new(0,26,0,26),Position=UDim2.new(1,-58,0.5,-13),BackgroundTransparency=1,Text="⊞",TextColor3=C.dim,TextSize=16,Font=Enum.Font.GothamBold,BorderSizePixel=0},TitleBar)
mk("TextButton",{Size=UDim2.new(0,26,0,26),Position=UDim2.new(1,-30,0.5,-13),BackgroundTransparency=1,Text="↺",TextColor3=C.dim,TextSize=16,Font=Enum.Font.GothamBold,BorderSizePixel=0},TitleBar)

makeDraggable(TitleBar,Window)

-- // SIDEBAR — Left panel like Axon Hub
local Sidebar=mk("Frame",{Size=UDim2.new(0,220,1,-40),Position=UDim2.new(0,0,0,40),BackgroundColor3=C.sidebar,BorderSizePixel=0},Window)

-- Hub name
local HubNameFrame=mk("Frame",{Size=UDim2.new(1,0,0,70),BackgroundColor3=C.panel,BorderSizePixel=0},Sidebar)
pad(16,16,12,12,HubNameFrame)
mk("TextLabel",{Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,Text="Rockshi Hub",TextColor3=C.accentHi,TextSize=16,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},HubNameFrame)
mk("TextLabel",{Size=UDim2.new(1,0,0,16),Position=UDim2.new(0,0,0,26),BackgroundTransparency=1,Text="Steal an Egg",TextColor3=C.subtext,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},HubNameFrame)

-- Section label
local SideBody=mk("ScrollingFrame",{Size=UDim2.new(1,0,1,-140),Position=UDim2.new(0,0,0,70),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=2,ScrollBarImageColor3=C.accent,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y},Sidebar)
mk("UIListLayout",{Padding=UDim.new(0,2),SortOrder=Enum.SortOrder.LayoutOrder},SideBody)
pad(10,10,8,8,SideBody)

-- Section header
local function sectionHeader(text,parent,order)
    local f=mk("Frame",{Size=UDim2.new(1,0,0,22),BackgroundTransparency=1,LayoutOrder=order},parent)
    mk("Frame",{Size=UDim2.new(0,6,0,6),Position=UDim2.new(0,0,0.5,-3),BackgroundColor3=C.accent,BorderSizePixel=0},f)
    corner(999,f:FindFirstChildOfClass("Frame"))
    mk("TextLabel",{Size=UDim2.new(1,-14,1,0),Position=UDim2.new(0,12,0,0),BackgroundTransparency=1,Text=text,TextColor3=C.subtext,TextSize=9,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},f)
    return f
end

-- Sidebar nav button
local navBtns={}
local ContentFrames={}

local function sideNavBtn(label,icon,tabId,order)
    local active=false
    local btn=mk("TextButton",{Size=UDim2.new(1,0,0,34),BackgroundTransparency=1,Text="",BorderSizePixel=0,LayoutOrder=order},SideBody)
    local indicator=mk("Frame",{Size=UDim2.new(0,3,0,22),Position=UDim2.new(0,0,0.5,-11),BackgroundColor3=C.accent,BorderSizePixel=0,Visible=false},btn)
    corner(999,indicator)
    local iconLbl=mk("TextLabel",{Size=UDim2.new(0,22,1,0),Position=UDim2.new(0,10,0,0),BackgroundTransparency=1,Text=icon,TextSize=14,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center},btn)
    local textLbl=mk("TextLabel",{Size=UDim2.new(1,-36,1,0),Position=UDim2.new(0,36,0,0),BackgroundTransparency=1,Text=label,TextColor3=C.subtext,TextSize=12,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},btn)

    local function setActive(v)
        active=v
        indicator.Visible=v
        textLbl.TextColor3=v and C.text or C.subtext
        textLbl.Font=v and Enum.Font.GothamBold or Enum.Font.Gotham
        btn.BackgroundTransparency=v and 0 or 1
        if v then btn.BackgroundColor3=C.card end
        if v then corner(8,btn) end
    end

    btn.MouseButton1Click:Connect(function()
        for _,nb in ipairs(navBtns) do nb.setActive(false) end
        setActive(true)
        for id,cf in pairs(ContentFrames) do
            cf.Visible=(id==tabId)
        end
        TabTitle.Text=label
        State.currentTab=tabId
    end)

    table.insert(navBtns,{setActive=setActive,tabId=tabId})
    return {setActive=setActive,btn=btn}
end

sectionHeader("EGGS",SideBody,1)
local navAutoSteal   = sideNavBtn("Auto Steal",   "◎","autoSteal",  2)
local navEggPredict  = sideNavBtn("Egg Predictor","☯","eggPredict", 3)
local navEggESP      = sideNavBtn("Egg ESP",      "◈","eggESP",     4)
local navEggAuto     = sideNavBtn("Egg Automation","⬡","eggAuto",   5)
local navEggFinder   = sideNavBtn("Egg Finder",   "⊙","eggFinder",  6)
sectionHeader("EVENTS",SideBody,7)
local navBossEvent   = sideNavBtn("Boss Event",   "⬣","bossEvent",  8)
local navTheRift     = sideNavBtn("The Rift",     "↺","theRift",    9)
local navAdminAbuse  = sideNavBtn("Admin Abuse",  "♛","adminAbuse", 10)

-- User card at bottom of sidebar
local UserCard=mk("Frame",{Size=UDim2.new(1,0,0,60),Position=UDim2.new(0,0,1,-60),BackgroundColor3=C.panel,BorderSizePixel=0},Sidebar)
pad(12,12,10,10,UserCard)
local UserAvatar=mk("Frame",{Size=UDim2.new(0,36,0,36),Position=UDim2.new(0,0,0.5,-18),BackgroundColor3=C.card2,BorderSizePixel=0},UserCard)
corner(999,UserAvatar)
mk("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="🥋",TextSize=18,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center},UserAvatar)
local uname=LocalPlayer.Name
mk("TextLabel",{Size=UDim2.new(1,-50,0,18),Position=UDim2.new(0,44,0,4),BackgroundTransparency=1,Text=uname,TextColor3=C.text,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},UserCard)
mk("TextLabel",{Size=UDim2.new(1,-50,0,14),Position=UDim2.new(0,44,0,24),BackgroundTransparency=1,Text="@"..uname,TextColor3=C.subtext,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},UserCard)
mk("TextLabel",{Size=UDim2.new(0,40,0,16),Position=UDim2.new(1,-44,0.5,-8),BackgroundTransparency=1,Text="Free",TextColor3=C.subtext,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Right},UserCard)

-- // CONTENT AREA — Right side
local ContentArea=mk("Frame",{Size=UDim2.new(1,-220,1,-40),Position=UDim2.new(0,220,0,40),BackgroundColor3=C.bg,BorderSizePixel=0},Window)
mk("UIStroke",{Color=C.border,Thickness=1},ContentArea)

-- Content frame builder
local function makeContent(tabId)
    local f=mk("ScrollingFrame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=C.accent,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=false},ContentArea)
    mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},f)
    ContentFrames[tabId]=f
    return f
end

-- Section block builder (collapsible like Axon Hub)
local function makeSection(parent,title,accentColor,order)
    local wrap=mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=order},parent)
    local header=mk("Frame",{Size=UDim2.new(1,0,0,40),BackgroundTransparency=1},wrap)
    pad(20,20,0,0,header)
    local titleLbl=mk("TextLabel",{Size=UDim2.new(0,300,1,0),BackgroundTransparency=1,Text=title,TextColor3=accentColor or C.accentHi,TextSize=13,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},header)
    local chevron=mk("TextButton",{Size=UDim2.new(0,20,0,20),Position=UDim2.new(1,-0,0.5,-10),BackgroundTransparency=1,Text="∨",TextColor3=C.subtext,TextSize=14,Font=Enum.Font.GothamBold,BorderSizePixel=0},header)
    local body=mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},wrap)
    local expanded=true
    chevron.MouseButton1Click:Connect(function()
        expanded=not expanded
        body.Visible=expanded
        chevron.Text=expanded and "∨" or ">"
    end)
    return body,header
end

-- Row builder helpers
local function rowToggle(parent,label,defaultOn,order,onChange)
    local row=mk("Frame",{Size=UDim2.new(1,0,0,38),BackgroundTransparency=1,LayoutOrder=order},parent)
    pad(20,20,0,0,row)
    mk("TextLabel",{Size=UDim2.new(1,-60,1,0),BackgroundTransparency=1,Text=label,TextColor3=C.subtext,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},row)
    local tog=makeToggle(row,0,0,defaultOn)
    tog.track.Position=UDim2.new(1,-44,0.5,-11)
    if onChange then tog.onChanged(onChange) end
    return tog
end

local function rowButton(parent,label,order,onClick)
    local row=mk("Frame",{Size=UDim2.new(1,0,0,38),BackgroundTransparency=1,LayoutOrder=order},parent)
    pad(20,20,0,0,row)
    mk("TextLabel",{Size=UDim2.new(1,-30,1,0),BackgroundTransparency=1,Text=label,TextColor3=C.subtext,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},row)
    local arr=mk("TextButton",{Size=UDim2.new(0,20,0,20),Position=UDim2.new(1,-0,0.5,-10),BackgroundTransparency=1,Text=">",TextColor3=C.dim,TextSize=14,Font=Enum.Font.GothamBold,BorderSizePixel=0},row)
    local fullBtn=mk("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=5},row)
    if onClick then fullBtn.MouseButton1Click:Connect(onClick) end
    return row
end

local function dropdownRow(parent,label,value,order)
    local row=mk("Frame",{Size=UDim2.new(1,0,0,38),BackgroundTransparency=1,LayoutOrder=order},parent)
    pad(20,20,4,4,row)
    local inner=mk("Frame",{Size=UDim2.new(1,0,0,30),BackgroundColor3=C.card,BorderSizePixel=0},row)
    corner(8,inner)
    mk("TextLabel",{Size=UDim2.new(0,14,1,0),Position=UDim2.new(0,8,0,0),BackgroundTransparency=1,Text="⊞",TextColor3=C.dim,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center},inner)
    mk("TextLabel",{Size=UDim2.new(1,-40,1,0),Position=UDim2.new(0,24,0,0),BackgroundTransparency=1,Text=value,TextColor3=C.subtext,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},inner)
    mk("TextLabel",{Size=UDim2.new(0,14,1,0),Position=UDim2.new(1,-16,0,0),BackgroundTransparency=1,Text="⊞",TextColor3=C.dim,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center},inner)
    return row
end

local function infoText(parent,text,order)
    local row=mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=order},parent)
    pad(20,20,0,8,row)
    local lbl=mk("TextLabel",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,Text=text,TextColor3=C.subtext,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,AutomaticSize=Enum.AutomaticSize.Y},row)
    return row
end

-- // ─────────────────────────────────────────────
-- // TAB: AUTO STEAL
-- // ─────────────────────────────────────────────
local cfAutoSteal=makeContent("autoSteal")

-- Two-column layout like Axon Hub
local autoColumns=mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1},cfAutoSteal)
local autoLeft=mk("Frame",{Size=UDim2.new(0.5,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},autoColumns)
local autoRight=mk("Frame",{Size=UDim2.new(0.5,0,0,0),Position=UDim2.new(0.5,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},autoColumns)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},autoLeft)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},autoRight)

-- LEFT COLUMN
local ccBody,ccHeader=makeSection(autoLeft,"Collection Controls",C.accentHi,1)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},ccBody)

-- Can't collect tip
local tipWrap=mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1},ccBody)
pad(20,20,0,8,tipWrap)
local tipTitle=mk("TextLabel",{Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,Text="Can't collect an egg?",TextColor3=C.accentHi,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},tipWrap)
local tipDesc=mk("TextLabel",{Size=UDim2.new(1,0,0,0),Position=UDim2.new(0,0,0,20),BackgroundTransparency=1,Text="If the collector reaches an egg but cannot pick it up, your travel speed is too high. Press Calibrate Speed Now and the script will find the right collection speed.",TextColor3=C.subtext,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,AutomaticSize=Enum.AutomaticSize.Y},tipWrap)

local speedWrap=mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=2},ccBody)
pad(20,20,0,8,speedWrap)
mk("TextLabel",{Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,Text="Speed Calibration",TextColor3=C.accentHi,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},speedWrap)
mk("TextLabel",{Size=UDim2.new(1,0,0,16),Position=UDim2.new(0,0,0,20),BackgroundTransparency=1,Text="Not calibrated yet.",TextColor3=C.subtext,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},speedWrap)

rowButton(ccBody,"Calibrate Speed Now",3)

-- Toggles
local loopTog=rowToggle(ccBody,"Continuous Egg Collection",false,4,function(on) State.loopActive=on end)
rowToggle(ccBody,"Friend Boost Border Drop",false,5)
rowToggle(ccBody,"Block Treadmill During Collection",false,6)
rowToggle(ccBody,"Train While Waiting For Egg",false,7)

-- RIGHT COLUMN
local rcBody,rcHeader=makeSection(autoRight,"",C.accentHi,1)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},rcBody)

dropdownRow(rcBody,"Collection Areas...",  "Collection Areas...",  1)
dropdownRow(rcBody,"Allowed Egg Types...", "Allowed Egg Types...", 2)
dropdownRow(rcBody,"Allowed Egg Rarities...","Allowed Egg Rarities...",3)
dropdownRow(rcBody,"Allowed Mutations...","Allowed Mutations...",  4)

local minValRow=mk("Frame",{Size=UDim2.new(1,0,0,38),BackgroundTransparency=1,LayoutOrder=5},rcBody)
pad(20,20,4,4,minValRow)
mk("TextLabel",{Size=UDim2.new(1,-60,1,0),BackgroundTransparency=1,Text="Minimum $/s to Steal",TextColor3=C.subtext,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},minValRow)
local minValBox=mk("Frame",{Size=UDim2.new(0,40,0,24),Position=UDim2.new(1,-40,0.5,-12),BackgroundColor3=C.card,BorderSizePixel=0},minValRow)
corner(6,minValBox)
mk("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="0",TextColor3=C.text,TextSize=11,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center},minValBox)

rowToggle(rcBody,"Require Every Chosen Mutation",false,6)
rowToggle(rcBody,"Mutated Eggs Only",false,7)

-- // ─────────────────────────────────────────────
-- // TAB: EGG PREDICTOR
-- // ─────────────────────────────────────────────
local cfEggPredict=makeContent("eggPredict")
local epColumns=mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1},cfEggPredict)
local epLeft=mk("Frame",{Size=UDim2.new(0.5,-1,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},epColumns)
mk("Frame",{Size=UDim2.new(0,1,1,0),Position=UDim2.new(0.5,0,0,0),BackgroundColor3=C.border,BorderSizePixel=0},epColumns)
local epRight=mk("Frame",{Size=UDim2.new(0.5,-1,0,0),Position=UDim2.new(0.5,1,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},epColumns)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},epLeft)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},epRight)

local epLBody,_=makeSection(epLeft,"Predictor Controls",C.accentHi,1)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},epLBody)
dropdownRow(epLBody,"Area","Area • All Areas",1)
dropdownRow(epLBody,"Show","Show • Forecast, Upcoming Spawns",2)

local searchRow=mk("Frame",{Size=UDim2.new(1,0,0,38),BackgroundTransparency=1,LayoutOrder=3},epLBody)
pad(20,20,4,4,searchRow)
local searchInner=mk("Frame",{Size=UDim2.new(1,0,0,30),BackgroundColor3=C.card,BorderSizePixel=0},searchRow)
corner(8,searchInner)
mk("TextLabel",{Size=UDim2.new(0.5,-4,1,0),Position=UDim2.new(0,8,0,0),BackgroundTransparency=1,Text="Search Pet",TextColor3=C.dim,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},searchInner)
mk("TextLabel",{Size=UDim2.new(0.5,-4,1,0),Position=UDim2.new(0.5,0,0,0),BackgroundTransparency=1,Text="Pet name...",TextColor3=C.dim,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Right},searchInner)

dropdownRow(epLBody,"Rarities","Rarities...",4)
rowButton(epLBody,"Refresh Predictions",5)

local nextChangeWrap=mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=6},epLBody)
pad(20,20,8,8,nextChangeWrap)
mk("TextLabel",{Size=UDim2.new(1,0,0,16),BackgroundTransparency=1,Text="Next Egg Change",TextColor3=C.accentHi,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},nextChangeWrap)
mk("TextLabel",{Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,0,18),BackgroundTransparency=1,Text="NEXT EGG CHANGE",TextColor3=C.subtext,TextSize=10,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},nextChangeWrap)
mk("TextLabel",{Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,0,34),BackgroundTransparency=1,Text="Eggs change every 5 minutes.",TextColor3=C.dim,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},nextChangeWrap)

-- Countdown timer
local countdownLbl=mk("TextLabel",{Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,0,50),BackgroundTransparency=1,Text="--s remaining",TextColor3=C.accentHi,TextSize=10,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},nextChangeWrap)
local countdownSecs=300
task.spawn(function()
    while true do
        task.wait(1)
        countdownSecs=countdownSecs-1
        if countdownSecs<=0 then countdownSecs=300 end
        countdownLbl.Text=tostring(countdownSecs).."s remaining"
    end
end)

local statusWrap=mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=7},epLBody)
pad(20,20,8,4,statusWrap)
mk("TextLabel",{Size=UDim2.new(1,0,0,16),BackgroundTransparency=1,Text="Status",TextColor3=C.accentHi,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},statusWrap)
mk("TextLabel",{Size=UDim2.new(1,0,0,0),Position=UDim2.new(0,0,0,18),BackgroundTransparency=1,Text="Upcoming Spawns + Shared Forecast | Chances from live servers",TextColor3=C.dim,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,AutomaticSize=Enum.AutomaticSize.Y},statusWrap)

-- RIGHT: Upcoming Pets list — reads from real scanEggs data
local epRBody,_=makeSection(epRight,"Upcoming Pets",C.accentHi,1)
mk("UIListLayout",{Padding=UDim.new(0,2),SortOrder=Enum.SortOrder.LayoutOrder},epRBody)

local function buildPredictRow(data,idx,parent)
    local rd=getRD(data.rarity)
    local row=mk("Frame",{Size=UDim2.new(1,0,0,52),BackgroundColor3=idx%2==0 and C.card or C.card2,BorderSizePixel=0,LayoutOrder=idx},parent)
    pad(12,12,0,0,row)
    mk("UIStroke",{Color=rd.color,Thickness=0,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},row)
    -- rarity left border color
    mk("Frame",{Size=UDim2.new(0,3,1,-8),Position=UDim2.new(0,-12,0,4),BackgroundColor3=rd.color,BorderSizePixel=0},row)
    local img=mk("ImageLabel",{Size=UDim2.new(0,36,0,36),Position=UDim2.new(0,0,0.5,-18),BackgroundColor3=C.panel,BorderSizePixel=0,Image=data.image or ""},row)
    corner(6,img)
    if (data.image or "")=="" then mk("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="🐾",TextSize=18,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center},img) end
    mk("TextLabel",{Size=UDim2.new(1,-130,0,18),Position=UDim2.new(0,46,0,8),BackgroundTransparency=1,Text=data.pet,TextColor3=C.text,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},row)
    mk("TextLabel",{Size=UDim2.new(1,-130,0,14),Position=UDim2.new(0,46,0,26),BackgroundTransparency=1,Text=data.rarity.." / "..data.dist.."m",TextColor3=rd.color,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},row)
    local valTxt=data.value~="" and data.value or "Now"
    mk("TextLabel",{Size=UDim2.new(0,60,0,18),Position=UDim2.new(1,-60,0,8),BackgroundTransparency=1,Text=valTxt,TextColor3=C.text,TextSize=11,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Right},row)
    mk("TextLabel",{Size=UDim2.new(0,60,0,14),Position=UDim2.new(1,-60,0,26),BackgroundTransparency=1,Text="Now",TextColor3=C.green,TextSize=10,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Right},row)
end

-- // ─────────────────────────────────────────────
-- // TAB: EGG ESP
-- // ─────────────────────────────────────────────
local cfEggESP=makeContent("eggESP")
local espCols=mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1},cfEggESP)
local espLeft=mk("Frame",{Size=UDim2.new(0.5,-1,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},espCols)
mk("Frame",{Size=UDim2.new(0,1,1,0),Position=UDim2.new(0.5,0,0,0),BackgroundColor3=C.border,BorderSizePixel=0},espCols)
local espRight=mk("Frame",{Size=UDim2.new(0.5,-1,0,0),Position=UDim2.new(0.5,1,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},espCols)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},espLeft)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},espRight)

local espLBody,_=makeSection(espLeft,"Egg ESP",C.accentHi,1)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},espLBody)
rowToggle(espLBody,"Egg ESP",false,1)
dropdownRow(espLBody,"Eggs To Show","Eggs To Show • All Matching Eggs",2)
dropdownRow(espLBody,"Choose The Best By","Choose The Best By • Highest KG",3)

-- KG selector
local kgFrame=mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=4},espLBody)
pad(24,20,4,4,kgFrame)
for _,opt in ipairs({"Highest KG","Highest Rarity","Largest Size"}) do
    local r=mk("Frame",{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},kgFrame)
    local dot=mk("Frame",{Size=UDim2.new(0,14,0,14),Position=UDim2.new(0,0,0.5,-7),BackgroundColor3=opt=="Highest KG" and C.accent or C.card2,BorderSizePixel=0},r)
    corner(999,dot)
    if opt=="Highest KG" then mk("Frame",{Size=UDim2.new(0,6,0,6),Position=UDim2.new(0.5,-3,0.5,-3),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0},dot) corner(999,dot:FindFirstChild("Frame")) end
    mk("TextLabel",{Size=UDim2.new(1,-20,1,0),Position=UDim2.new(0,20,0,0),BackgroundTransparency=1,Text=opt,TextColor3=opt=="Highest KG" and C.text or C.subtext,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},r)
end

-- View distance slider
local vdRow=mk("Frame",{Size=UDim2.new(1,0,0,50),BackgroundTransparency=1,LayoutOrder=5},espLBody)
pad(20,20,4,4,vdRow)
mk("TextLabel",{Size=UDim2.new(1,-60,0,16),BackgroundTransparency=1,Text="View Distance",TextColor3=C.subtext,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},vdRow)
local sliderTrack=mk("Frame",{Size=UDim2.new(0.7,0,0,6),Position=UDim2.new(0,0,0,28),BackgroundColor3=C.card2,BorderSizePixel=0},vdRow)
corner(999,sliderTrack)
local sliderFill=mk("Frame",{Size=UDim2.new(0.5,0,1,0),BackgroundColor3=C.accent,BorderSizePixel=0},sliderTrack)
corner(999,sliderFill)
local sliderThumb=mk("Frame",{Size=UDim2.new(0,14,0,14),Position=UDim2.new(0.5,-7,0.5,-7),BackgroundColor3=C.accentHi,BorderSizePixel=0},sliderTrack)
corner(999,sliderThumb)
local vdValBox=mk("Frame",{Size=UDim2.new(0,50,0,24),Position=UDim2.new(1,-50,0,22),BackgroundColor3=C.card,BorderSizePixel=0},vdRow)
corner(6,vdValBox)
mk("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="5000",TextColor3=C.text,TextSize=11,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center},vdValBox)

rowToggle(espLBody,"Show Pet Income Before Hatch",false,6)

local espRBody,_=makeSection(espRight,"Choose Your Eggs",C.accentHi,1)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},espRBody)
dropdownRow(espRBody,"Areas","Areas...",1)
dropdownRow(espRBody,"Egg Types","Egg Types...",2)
dropdownRow(espRBody,"Rarities","Rarities...",3)
dropdownRow(espRBody,"Mutations","Mutations...",4)
rowToggle(espRBody,"Mutated Eggs Only",false,5)

-- Minimum KG row
local mkgRow=mk("Frame",{Size=UDim2.new(1,0,0,50),BackgroundTransparency=1,LayoutOrder=6},espRBody)
pad(20,20,4,4,mkgRow)
mk("TextLabel",{Size=UDim2.new(1,-60,0,16),BackgroundTransparency=1,Text="Minimum KG",TextColor3=C.subtext,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},mkgRow)
local mkgTrack=mk("Frame",{Size=UDim2.new(0.7,0,0,6),Position=UDim2.new(0,0,0,28),BackgroundColor3=C.card2,BorderSizePixel=0},mkgRow)
corner(999,mkgTrack)
local mkgFill=mk("Frame",{Size=UDim2.new(0,0,1,0),BackgroundColor3=C.accent,BorderSizePixel=0},mkgTrack)
corner(999,mkgFill)
local mkgThumb=mk("Frame",{Size=UDim2.new(0,14,0,14),Position=UDim2.new(0,-7,0.5,-7),BackgroundColor3=C.accentHi,BorderSizePixel=0},mkgTrack)
corner(999,mkgThumb)
local mkgValBox=mk("Frame",{Size=UDim2.new(0,50,0,24),Position=UDim2.new(1,-50,0,22),BackgroundColor3=C.card,BorderSizePixel=0},mkgRow)
corner(6,mkgValBox)
mk("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="0.00",TextColor3=C.text,TextSize=11,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center},mkgValBox)

-- Live Result
local lrBody,_=makeSection(espRight,"Live Result",C.accentHi,2)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},lrBody)
local lrStatus=mk("TextLabel",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,Text="No matching eggs visible.",TextColor3=C.dim,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1},lrBody)
pad(20,20,8,8,lrStatus)

-- // ─────────────────────────────────────────────
-- // TAB: EGG AUTOMATION
-- // ─────────────────────────────────────────────
local cfEggAuto=makeContent("eggAuto")
local eaCols=mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1},cfEggAuto)
local eaLeft=mk("Frame",{Size=UDim2.new(0.5,-1,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},eaCols)
mk("Frame",{Size=UDim2.new(0,1,1,0),Position=UDim2.new(0.5,0,0,0),BackgroundColor3=C.border,BorderSizePixel=0},eaCols)
local eaRight=mk("Frame",{Size=UDim2.new(0.5,-1,0,0),Position=UDim2.new(0.5,1,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},eaCols)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},eaLeft)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},eaRight)

local eaLBody,_=makeSection(eaLeft,"One-Toggle Full Cycle",C.accentHi,1)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},eaLBody)
rowToggle(eaLBody,"Steal → Place → Hatch → Decide",false,1)
dropdownRow(eaLBody,"Egg Placement Policy","Egg Placement Policy • Every Egg",2)
dropdownRow(eaLBody,"Hatched Pet Decision","Hatched Pet Decision • Keep Every Pet",3)

local pdRow=mk("Frame",{Size=UDim2.new(1,0,0,50),BackgroundTransparency=1,LayoutOrder=4},eaLBody)
pad(20,20,4,4,pdRow)
mk("TextLabel",{Size=UDim2.new(1,-60,0,16),BackgroundTransparency=1,Text="Pipeline Decision Delay",TextColor3=C.subtext,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},pdRow)
local pdTrack=mk("Frame",{Size=UDim2.new(0.7,0,0,6),Position=UDim2.new(0,0,0,28),BackgroundColor3=C.card2,BorderSizePixel=0},pdRow)
corner(999,pdTrack)
local pdFill=mk("Frame",{Size=UDim2.new(0.4,0,1,0),BackgroundColor3=C.accent,BorderSizePixel=0},pdTrack)
corner(999,pdFill)
mk("Frame",{Size=UDim2.new(0,14,0,14),Position=UDim2.new(0.4,-7,0.5,-7),BackgroundColor3=C.accentHi,BorderSizePixel=0},pdTrack)
local pdValBox=mk("Frame",{Size=UDim2.new(0,50,0,24),Position=UDim2.new(1,-50,0,22),BackgroundColor3=C.card,BorderSizePixel=0},pdRow)
corner(6,pdValBox)
mk("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="0.75",TextColor3=C.text,TextSize=11,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center},pdValBox)

local psBody,_=makeSection(eaLeft,"Priority Scheduler",C.accentHi,2)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},psBody)
local psStatus=mk("TextLabel",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1,Text="Idle\nFull cycle is off.\nTravel Speed: 600 | Pickup: up to 600\nActions: 0 | Completed: 0",TextColor3=C.dim,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true},psBody)
pad(20,20,8,8,psStatus)

local prBody,_=makeSection(eaLeft,"Placement Rules",C.accentHi,3)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},prBody)
dropdownRow(prBody,"Egg Types To Place","Egg Types To Place...",1)
dropdownRow(prBody,"Placement Rarities","Placement Rarities...",2)

local eaRBody,_=makeSection(eaRight,"Placement and Hatching",C.accentHi,1)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},eaRBody)
rowToggle(eaRBody,"Place Matching Eggs",false,1)
rowToggle(eaRBody,"Place Every Egg",false,2)
rowToggle(eaRBody,"Hatch Eggs When Ready",false,3)

local asBody,_=makeSection(eaRight,"Automation Summary",C.accentHi,2)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},asBody)
local asStat=mk("TextLabel",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1,Text="Placed: 0 | Hatched: 0\nReady",TextColor3=C.dim,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true},asBody)
pad(20,20,8,8,asStat)

-- // ─────────────────────────────────────────────
-- // TAB: EGG FINDER
-- // ─────────────────────────────────────────────
local cfEggFinder=makeContent("eggFinder")
local efCols=mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1},cfEggFinder)
local efLeft=mk("Frame",{Size=UDim2.new(0.5,-1,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},efCols)
mk("Frame",{Size=UDim2.new(0,1,1,0),Position=UDim2.new(0.5,0,0,0),BackgroundColor3=C.border,BorderSizePixel=0},efCols)
local efRight=mk("Frame",{Size=UDim2.new(0.5,-1,0,0),Position=UDim2.new(0.5,1,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},efCols)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},efLeft)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},efRight)

local efLBody,_=makeSection(efLeft,"Egg Finder",C.accentHi,1)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},efLBody)
local howText=mk("TextLabel",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1,Text="How the hunt works\nPick the egg you want and start the hunt. The finder scans every nest in the current server; if your egg isn't there it teleports straight to the egg and steals it for you — fully AFK.",TextColor3=C.accentHi,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true},efLBody)
pad(20,20,8,8,howText)
dropdownRow(efLBody,"Egg To Find","Egg To Find...",2)
local huntTog=rowToggle(efLBody,"Start The Hunt",false,3)

local huntStatusWrap=mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=4},efLBody)
pad(20,20,8,8,huntStatusWrap)
mk("TextLabel",{Size=UDim2.new(1,0,0,16),BackgroundTransparency=1,Text="Hunt Status",TextColor3=C.accentHi,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},huntStatusWrap)
local huntStatusLbl=mk("TextLabel",{Size=UDim2.new(1,0,0,0),Position=UDim2.new(0,0,0,20),BackgroundTransparency=1,Text="Choose an egg and start the hunt.",TextColor3=C.dim,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,AutomaticSize=Enum.AutomaticSize.Y},huntStatusWrap)

local efRBody,_=makeSection(efRight,"Server Hopping",C.accentHi,1)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},efRBody)
local shText=mk("TextLabel",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1,Text="No-rate-limit hopping\nHops fire the instant a scan finishes — no cooldowns, no delays. Every server id is remembered so you never land in the same server twice.",TextColor3=C.accentHi,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true},efRBody)
pad(20,20,8,8,shText)
rowButton(efRBody,"Hop Server Now",2)
rowButton(efRBody,"Forget Visited Servers",3)

-- // ─────────────────────────────────────────────
-- // TAB: BOSS EVENT
-- // ─────────────────────────────────────────────
local cfBossEvent=makeContent("bossEvent")
local beCols=mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1},cfBossEvent)
local beLeft=mk("Frame",{Size=UDim2.new(0.5,-1,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},beCols)
mk("Frame",{Size=UDim2.new(0,1,1,0),Position=UDim2.new(0.5,0,0,0),BackgroundColor3=C.border,BorderSizePixel=0},beCols)
local beRight=mk("Frame",{Size=UDim2.new(0.5,-1,0,0),Position=UDim2.new(0.5,1,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},beCols)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},beLeft)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},beRight)

local beLBody,_=makeSection(beLeft,"Boss Event Automation",C.accentHi,1)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},beLBody)
local beDesc=mk("TextLabel",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1,Text="Rifts and the Abyss Overlord\nEnter the boss arena through the game's portal, then enable the actions you want.",TextColor3=C.accentHi,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true},beLBody)
pad(20,20,8,8,beDesc)
rowToggle(beLBody,"Auto Farm Boss Event",false,2)
rowToggle(beLBody,"Glide to Rifts and Boss",false,3)
rowToggle(beLBody,"Break Rifts with Bat",false,4)
rowToggle(beLBody,"Attack Vulnerable Boss",false,5)

local beStatusWrap=mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=6},beLBody)
pad(20,20,8,8,beStatusWrap)
mk("TextLabel",{Size=UDim2.new(1,0,0,16),BackgroundTransparency=1,Text="Farm Status",TextColor3=C.accentHi,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},beStatusWrap)
mk("TextLabel",{Size=UDim2.new(1,0,0,0),Position=UDim2.new(0,0,0,20),BackgroundTransparency=1,Text="Event: Closed | Location: Main map\nMain-map priority: Wanted eggs > Boss Event > The Rift > Treadmill",TextColor3=C.dim,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,AutomaticSize=Enum.AutomaticSize.Y},beStatusWrap)

local beRBody,_=makeSection(beRight,"Boss Shop",C.accentHi,1)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},beRBody)
local bsDesc=mk("TextLabel",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1,Text="Spend Boss Tokens on selected items. Items come from the live Boss Shop. An empty selection buys nothing.",TextColor3=C.accentHi,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true},beRBody)
pad(20,20,8,8,bsDesc)
dropdownRow(beRBody,"Items to Buy","Items to Buy...",2)
rowToggle(beRBody,"Auto Buy Selected Items",false,3)
rowButton(beRBody,"Buy One Selected Item Now",4)
rowButton(beRBody,"Refresh Shop Items and Prices",5)

-- // ─────────────────────────────────────────────
-- // TAB: THE RIFT
-- // ─────────────────────────────────────────────
local cfTheRift=makeContent("theRift")
local trCols=mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1},cfTheRift)
local trLeft=mk("Frame",{Size=UDim2.new(0.5,-1,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},trCols)
mk("Frame",{Size=UDim2.new(0,1,1,0),Position=UDim2.new(0.5,0,0,0),BackgroundColor3=C.border,BorderSizePixel=0},trCols)
local trRight=mk("Frame",{Size=UDim2.new(0.5,-1,0,0),Position=UDim2.new(0.5,1,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},trCols)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},trLeft)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},trRight)

local trLBody,_=makeSection(trLeft,"Rift Pet Automation",C.accentHi,1)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},trLBody)
local trDesc=mk("TextLabel",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1,Text="Three pets become one Rift egg\nSubmitting permanently consumes the three offered pets. Equipped, favorited, locked, fused and visual-spawner pets are never used.",TextColor3=C.accentHi,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true},trLBody)
pad(20,20,8,8,trDesc)
dropdownRow(trLBody,"Rift Banner to Farm","Rift Banner to Farm • Any Banner",2)
rowToggle(trLBody,"Farm Missing Rift Pets",false,3)
rowToggle(trLBody,"Auto Submit Pets and Claim Rift Egg",false,4)
rowToggle(trLBody,"Allow Mutated Pets as Offerings",false,5)

local trRBody,_=makeSection(trRight,"Current Recipe and Progress",C.accentHi,1)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},trRBody)
local trRecipe=mk("TextLabel",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1,Text="The Rift\nBanner: Shattered Rift\nPty: 0/50\nTrades this server session: 0\n1. Salamander — own 0, eligible 0, keeping 1\n2. Snowy Owl — own 0, eligible 0, keeping 1\n3. Bladehide — own 0, eligible 0, keeping 1",TextColor3=C.dim,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true},trRBody)
pad(20,20,8,8,trRecipe)
rowButton(trRBody,"Refresh Requirements / Preview Offerings",2)
rowButton(trRBody,"Submit One Set / Finish Pending Reward",3)
rowButton(trRBody,"Reset Confirmed Trade Counter",4)

local fpBody,_=makeSection(trRight,"Farm priority",C.accentHi,2)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},fpBody)
local fpDesc=mk("TextLabel",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1,Text="Wanted eggs → The Rift → treadmill. The Rift uses normal collection routes, not the Dragon-event wall.",TextColor3=C.dim,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true},fpBody)
pad(20,20,8,8,fpDesc)

-- // ─────────────────────────────────────────────
-- // TAB: ADMIN ABUSE
-- // ─────────────────────────────────────────────
local cfAdminAbuse=makeContent("adminAbuse")
local aaCols=mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1},cfAdminAbuse)
local aaLeft=mk("Frame",{Size=UDim2.new(0.5,-1,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},aaCols)
mk("Frame",{Size=UDim2.new(0,1,1,0),Position=UDim2.new(0.5,0,0,0),BackgroundColor3=C.border,BorderSizePixel=0},aaCols)
local aaRight=mk("Frame",{Size=UDim2.new(0.5,-1,0,0),Position=UDim2.new(0.5,1,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},aaCols)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},aaLeft)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},aaRight)

local aaLBody,_=makeSection(aaLeft,"Dragon Event Auto Farm",C.accentHi,1)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},aaLBody)
local aaDesc=mk("TextLabel",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1,Text="Dragon event only\nSelect which Dragon-event eggs you want. Only DragonEggEvent categories appear here; normal area eggs and every other event are ignored.",TextColor3=C.accentHi,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true},aaLBody)
pad(20,20,8,8,aaDesc)
dropdownRow(aaLBody,"Dragon Event Eggs To Collect","Dragon Event Eggs To Collect...",2)
rowToggle(aaLBody,"Auto Farm Dragon Event Egg",false,3)

-- HOLD LONGEST — own section, big button
local hlBody,_=makeSection(aaLeft,"Hold Longest Admin Abuse",C.accentHi,2)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},hlBody)
local hlDesc=mk("TextLabel",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1,Text="Flies 300 studs into the air, enables god mode, and spams all hold/zone/admin interactions. Unkillable while active.",TextColor3=C.subtext,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true},hlBody)
pad(20,20,8,4,hlDesc)

local hlBtnWrap=mk("Frame",{Size=UDim2.new(1,0,0,48),BackgroundTransparency=1,LayoutOrder=2},hlBody)
pad(20,20,4,8,hlBtnWrap)
local hlBtn=mk("TextButton",{Size=UDim2.new(1,0,0,36),BackgroundColor3=C.accentDim,Text="👑  HOLD LONGEST — START",TextColor3=Color3.new(1,1,1),TextSize=13,Font=Enum.Font.GothamBold,BorderSizePixel=0},hlBtnWrap)
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

local aaRBody,_=makeSection(aaRight,"Dragon Event Detection",C.accentHi,1)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},aaRBody)
local availDragonTitle=mk("TextLabel",{Size=UDim2.new(1,0,0,16),BackgroundTransparency=1,Text="Available Dragon eggs",TextColor3=C.accentHi,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=1},aaRBody)
pad(20,20,8,4,availDragonTitle)
local dragonList=mk("TextLabel",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,Text="Scanning...",TextColor3=C.dim,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,LayoutOrder=2},aaRBody)
pad(20,20,0,8,dragonList)

local liveStateBody,_=makeSection(aaRight,"Live Event State",C.accentHi,2)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},liveStateBody)
local liveStateLbl=mk("TextLabel",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,Text="Dragon event: Inactive\nPhase: Inactive | Spawned eggs: 0\nZone: Waiting for zone",TextColor3=C.dim,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,LayoutOrder=1},liveStateBody)
pad(20,20,8,8,liveStateLbl)

-- // ─────────────────────────────────────────────
-- // DATA LOOPS
-- // ─────────────────────────────────────────────

-- Scan loop
task.spawn(function()
    while true do
        task.wait(0.5)
        local ok,eggs=pcall(scanAllEggs)
        if ok and eggs then
            State.eggList=eggs
            -- Update Egg Predictor list
            if State.currentTab=="eggPredict" then
                for _,c in ipairs(epRBody:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
                for i,data in ipairs(eggs) do buildPredictRow(data,i,epRBody) if i>=10 then break end end
            end
            -- Update dragon detection
            local dragonEggs={}
            for _,data in ipairs(eggs) do
                if data.rarity=="Secret" or data.rarity=="Eternal" or data.rarity=="Mythic" or data.rarity=="Legendary" then
                    table.insert(dragonEggs,data.pet.." • "..data.rarity)
                end
            end
            if #dragonEggs>0 then
                dragonList.Text=table.concat(dragonEggs,"\n")
            else
                dragonList.Text="No dragon-tier eggs detected"
            end
            -- ESP live result
            if #eggs>0 then
                local e=eggs[1]
                lrStatus.Text="Best: "..e.pet.." ["..e.rarity.."] — "..e.dist.."m away"
                lrStatus.TextColor3=getRD(e.rarity).color
            end
        end
    end
end)

-- Auto steal loop
task.spawn(function()
    while true do
        task.wait(0.15)
        if not State.loopActive or State.stealing then continue end
        local eggs=State.eggList
        if not eggs or #eggs==0 then continue end
        local target=nil
        for _,data in ipairs(eggs) do
            if State.selectedRar[data.rarity] then target=data break end
        end
        if not target then continue end
        State.stealing=true
        stealEgg(target,function(ok)
            State.stealing=false
        end)
    end
end)

-- // TOGGLE WINDOW
IconBtn.MouseButton1Click:Connect(function()
    Window.Visible=not Window.Visible
    if Window.Visible then
        -- activate default tab
        navAutoSteal.setActive(true)
        for id,cf in pairs(ContentFrames) do cf.Visible=(id=="autoSteal") end
        TabTitle.Text="Auto Steal"
        State.currentTab="autoSteal"
    end
end)

-- Default tab on first open
navAutoSteal.setActive(true)
for id,cf in pairs(ContentFrames) do cf.Visible=(id=="autoSteal") end

-- // RESPAWN
LocalPlayer.CharacterAdded:Connect(function()
    State.stealing=false stopFly()
    if holdActive then stopHoldLongest() holdOn=false hlBtn.Text="👑  HOLD LONGEST — START" hlBtn.BackgroundColor3=C.accentDim end
end)

print("🥋 ROCKSHI HUB Loaded — Tap the circle icon!")
