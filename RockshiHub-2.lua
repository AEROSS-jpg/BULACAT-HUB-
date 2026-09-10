-- // ============================================
-- // 🥋 ROCKSHI HUB — Lennon Hub Style Clone
-- // Unbannable: Client-only, no server flags
-- // Executor: KRNL / Synapse X / Fluxus / Delta
-- // ============================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer      = Players.LocalPlayer

local function getChar()  return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait() end
local function getRoot()  local c=getChar() return c and c:FindFirstChild("HumanoidRootPart") end
local function getHuman() local c=getChar() return c and c:FindFirstChildOfClass("Humanoid") end

local CFG = {
    TELEPORT_OFFSET = Vector3.new(0,3,0),
    LOOP_DELAY      = 0.15,
    SCAN_INTERVAL   = 0.5,
    FLY_HEIGHT      = 75,
    FLY_SPEED       = 180,
}

local RARITY_LIST = {
    {name="Cosmic",   color=Color3.fromRGB(160,80,255),  rank=1},
    {name="Divine",   color=Color3.fromRGB(255,215,0),   rank=2},
    {name="Eternal",  color=Color3.fromRGB(180,0,255),   rank=3},
    {name="Secret",   color=Color3.fromRGB(255,60,60),   rank=4},
    {name="Mythic",   color=Color3.fromRGB(255,120,0),   rank=5},
    {name="Legendary",color=Color3.fromRGB(255,200,0),   rank=6},
    {name="Epic",     color=Color3.fromRGB(160,0,255),   rank=7},
    {name="Rare",     color=Color3.fromRGB(0,120,255),   rank=8},
    {name="Uncommon", color=Color3.fromRGB(0,200,80),    rank=9},
    {name="Common",   color=Color3.fromRGB(160,160,160), rank=10},
}
local RARITY_MAP={}
for _,r in ipairs(RARITY_LIST) do RARITY_MAP[r.name]=r end
local function getRD(n) return RARITY_MAP[n] or RARITY_MAP["Common"] end

local function getPetImage(obj)
    for _,v in ipairs(obj:GetDescendants()) do
        if v:IsA("ImageLabel") and v.Image~="" then return v.Image end
    end
    for _,v in ipairs(obj:GetDescendants()) do
        if v:IsA("Decal") and v.Texture~="" then return v.Texture end
    end
    return ""
end

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
                return v.Value
            end
        end
    end
    for _,v in ipairs(obj:GetDescendants()) do
        if v:IsA("TextLabel") and v.Text~="" and #v.Text<50 then
            local t=v.Text:lower()
            if not t:find("click") and not t:find("press") and not t:find("open") and not t:find("buy") then
                return v.Text
            end
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
    if nm~="" then return nm.." Pet" end
    return "Unknown Pet"
end

local function getEggValue(obj)
    for _,v in ipairs(obj:GetDescendants()) do
        if (v:IsA("NumberValue") or v:IsA("IntValue")) then
            local nm=v.Name:lower()
            if (nm:find("value") or nm:find("coin") or nm:find("price") or nm:find("worth")) and v.Value>0 then
                local val=v.Value
                if val>=1e9 then return string.format("%.2fB",val/1e9)
                elseif val>=1e6 then return string.format("%.2fM",val/1e6)
                elseif val>=1e3 then return string.format("%.1fK",val/1e3)
                end
                return tostring(val)
            end
        end
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
                        local rar=predictRarity(obj)
                        local pet=predictPet(obj)
                        local val=getEggValue(obj)
                        local dist=math.floor((root.Position-pos).Magnitude)
                        local img=getPetImage(obj)
                        table.insert(found,{obj=obj,rarity=rar,pet=pet,value=val,dist=dist,pos=pos,image=img})
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

-- // GOD MODE
local godConn=nil
local function enableGodMode()
    pcall(function()
        local hum=getHuman()
        if not hum then return end
        hum.MaxHealth=math.huge hum.Health=math.huge
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
    end)
end
local function disableGodMode()
    if godConn then godConn:Disconnect() godConn=nil end
    pcall(function()
        local hum=getHuman()
        if not hum then return end
        hum.MaxHealth=100 hum.Health=100
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
local flyConn,bVel,bGyro,isFly=nil,nil,nil,false
local function stopFly()
    isFly=false
    if flyConn then flyConn:Disconnect() flyConn=nil end
    pcall(function() if bVel  then bVel:Destroy()  bVel=nil  end end)
    pcall(function() if bGyro then bGyro:Destroy() bGyro=nil end end)
    pcall(function() local h=getHuman() if h then h.PlatformStand=false end end)
end
local function flyTo(targetPos,speed,onArrived)
    stopFly() isFly=true
    pcall(function()
        local root=getRoot() local human=getHuman()
        if not root or not human then if onArrived then onArrived() end return end
        human.PlatformStand=true
        bVel=Instance.new("BodyVelocity",root)
        bVel.MaxForce=Vector3.new(1e6,1e6,1e6) bVel.Velocity=Vector3.new(0,0,0)
        bGyro=Instance.new("BodyGyro",root)
        bGyro.MaxTorque=Vector3.new(1e6,1e6,1e6) bGyro.P=1e4
        flyConn=RunService.Heartbeat:Connect(function()
            if not isFly then return end
            local r=getRoot()
            if not r then stopFly() return end
            local diff=targetPos-r.Position
            if diff.Magnitude<3 then
                stopFly()
                if onArrived then task.spawn(onArrived) end
                return
            end
            local dir=diff.Unit
            bVel.Velocity=dir*(speed or CFG.FLY_SPEED)
            bGyro.CFrame=CFrame.new(r.Position,r.Position+dir)
        end)
    end)
end

local function rideBack()
    local root=getRoot() if not root then return end
    local best,bd=nil,math.huge
    local keys={"mount","pet","monster","creature","ride","animal","mob","boss","npc","dinosaur"}
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            for _,kw in ipairs(keys) do
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
        local w=Instance.new("WeldConstraint")
        w.Part0=root w.Part1=best w.Parent=root
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
    if not data or not data.obj or not data.obj.Parent then
        if onDone then onDone(false) end return
    end
    enableGodMode()
    local highPos=data.pos+Vector3.new(0,CFG.FLY_HEIGHT,0)
    flyTo(highPos,CFG.FLY_SPEED,function()
        local root=getRoot()
        if not root then disableGodMode() if onDone then onDone(false) end return end
        root.CFrame=CFrame.new(data.pos+CFG.TELEPORT_OFFSET)
        task.wait(0.05)
        local obj=data.obj
        local touch=obj:FindFirstChildOfClass("TouchTransmitter")
        if touch then
            pcall(firetouchinterest,root,obj,0) task.wait(0.05)
            pcall(firetouchinterest,root,obj,1)
        end
        local click=obj:FindFirstChildOfClass("ClickDetector")
        if click then pcall(fireclickdetector,click) end
        local prompt=obj:FindFirstChildOfClass("ProximityPrompt")
            or (obj.Parent and obj.Parent:FindFirstChildOfClass("ProximityPrompt"))
        if prompt then pcall(fireproximityprompt,prompt) end
        for _,v in ipairs(workspace:GetDescendants()) do
            if v:IsA("RemoteEvent") then
                local nm=v.Name:lower()
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

-- // HOLD LONGEST
local holdActive=false
local holdConn,holdBV,holdBG=nil,nil,nil
local function startHoldLongest()
    if holdActive then return end
    holdActive=true enableGodMode()
    pcall(function()
        local root=getRoot() if not root then return end
        local skyY=root.Position.Y+300
        local skyPos=Vector3.new(root.Position.X,skyY,root.Position.Z)
        local human=getHuman() if human then human.PlatformStand=true end
        holdBV=Instance.new("BodyVelocity",root)
        holdBV.MaxForce=Vector3.new(1e6,1e6,1e6) holdBV.Velocity=Vector3.new(0,200,0)
        holdBG=Instance.new("BodyGyro",root)
        holdBG.MaxTorque=Vector3.new(1e6,1e6,1e6) holdBG.CFrame=root.CFrame
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
local State={loopActive=false,stealing=false,eggList={},selectedRar={Cosmic=true,Divine=true,Eternal=true,Secret=true}}

-- // UI
local CoreGui=game:GetService("CoreGui")
pcall(function() local old=CoreGui:FindFirstChild("RockshiHubUI") if old then old:Destroy() end end)

local ScreenGui=Instance.new("ScreenGui")
ScreenGui.Name="RockshiHubUI" ScreenGui.ResetOnSpawn=false
ScreenGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder=999 ScreenGui.Parent=CoreGui

local BG=Color3.fromRGB(18,18,22)
local CARD=Color3.fromRGB(26,26,32)
local BLUE=Color3.fromRGB(80,170,255)
local GREEN=Color3.fromRGB(80,220,120)
local TEXT=Color3.fromRGB(230,230,240)
local SUB=Color3.fromRGB(140,140,160)
local RED=Color3.fromRGB(255,80,80)
local GOLD=Color3.fromRGB(255,200,50)
local PURP=Color3.fromRGB(160,80,255)

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

-- // CIRCLE ICON
local IconFrame=mk("Frame",{Size=UDim2.new(0,70,0,70),Position=UDim2.new(0,10,0,100),BackgroundColor3=Color3.fromRGB(20,20,28),BorderSizePixel=0},ScreenGui)
corner(14,IconFrame)
mk("UIStroke",{Color=Color3.fromRGB(50,50,70),Thickness=1.5},IconFrame)

local PRing=mk("Frame",{Size=UDim2.new(1,20,1,20),Position=UDim2.new(0,-10,0,-10),BackgroundTransparency=1,BorderSizePixel=0},IconFrame)
corner(999,PRing)
local particles={}
for i=1,8 do
    local a=math.rad((i-1)*45) local r=42
    local dot=mk("Frame",{Size=UDim2.new(0,5,0,5),Position=UDim2.new(0.5,math.cos(a)*r-2,0.5,math.sin(a)*r-2),BackgroundColor3=i%2==0 and BLUE or GOLD,BorderSizePixel=0,ZIndex=5},PRing)
    corner(999,dot)
    table.insert(particles,{dot=dot,angle=a,r=r})
end
local rot=0
RunService.Heartbeat:Connect(function(dt)
    rot=rot+dt*2
    for i,p in ipairs(particles) do
        local a=p.angle+rot
        p.dot.Position=UDim2.new(0.5,math.cos(a)*p.r-2,0.5,math.sin(a)*p.r-2)
        local s=4+math.sin(rot*2+i)*1.5
        p.dot.Size=UDim2.new(0,s,0,s)
    end
end)
mk("TextLabel",{Size=UDim2.new(1,0,0,42),Position=UDim2.new(0,0,0,4),BackgroundTransparency=1,Text="🥋",TextSize=32,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center},IconFrame)
mk("TextLabel",{Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,1,-16),BackgroundTransparency=1,Text="RH",TextSize=9,Font=Enum.Font.GothamBold,TextColor3=GOLD,TextXAlignment=Enum.TextXAlignment.Center},IconFrame)
local IconBtn=mk("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=10},IconFrame)
makeDraggable(IconBtn,IconFrame)

-- // MAIN PANEL
local Panel=mk("Frame",{Size=UDim2.new(0,320,0,0),Position=UDim2.new(1,-332,0,60),BackgroundColor3=BG,BorderSizePixel=0,Visible=false,AutomaticSize=Enum.AutomaticSize.Y,ClipsDescendants=false},ScreenGui)
corner(14,Panel)
mk("UIStroke",{Color=Color3.fromRGB(45,45,60),Thickness=1},Panel)

-- HEADER
local PHeader=mk("Frame",{Size=UDim2.new(1,0,0,52),BackgroundColor3=CARD,BorderSizePixel=0},Panel)
corner(14,PHeader)
mk("Frame",{Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,1,-14),BackgroundColor3=CARD,BorderSizePixel=0},PHeader)

local HIcon=mk("Frame",{Size=UDim2.new(0,34,0,34),Position=UDim2.new(0,12,0.5,-17),BackgroundColor3=Color3.fromRGB(30,30,40),BorderSizePixel=0},PHeader)
corner(8,HIcon)
mk("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="🥋",TextSize=20,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center},HIcon)
mk("TextLabel",{Size=UDim2.new(0,160,0,20),Position=UDim2.new(0,52,0,10),BackgroundTransparency=1,Text="ROCKSHI HUB",TextColor3=TEXT,TextSize=14,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},PHeader)
mk("TextLabel",{Size=UDim2.new(0,160,0,14),Position=UDim2.new(0,52,0,28),BackgroundTransparency=1,Text="BEST EGG SYSTEM",TextColor3=SUB,TextSize=9,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},PHeader)

local DiscBtn=mk("TextButton",{Size=UDim2.new(0,26,0,26),Position=UDim2.new(1,-64,0.5,-13),BackgroundColor3=Color3.fromRGB(88,101,242),Text="DC",TextColor3=Color3.new(1,1,1),TextSize=8,Font=Enum.Font.GothamBold,BorderSizePixel=0},PHeader)
corner(6,DiscBtn)
local CloseBtn=mk("TextButton",{Size=UDim2.new(0,22,0,22),Position=UDim2.new(1,-34,0.5,-11),BackgroundTransparency=1,Text="✕",TextColor3=SUB,TextSize=13,Font=Enum.Font.GothamBold,BorderSizePixel=0},PHeader)
makeDraggable(PHeader,Panel)

-- BODY
local Body=mk("Frame",{Size=UDim2.new(1,0,0,0),Position=UDim2.new(0,0,0,52),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},Panel)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},Body)

-- BEST EGG SECTION
local BestCard=mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundColor3=CARD,BorderSizePixel=0,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1},Body)

local BestHeader=mk("Frame",{Size=UDim2.new(1,0,0,32),BackgroundTransparency=1},BestCard)
pad(14,14,0,0,BestHeader)
mk("TextLabel",{Size=UDim2.new(0,80,1,0),BackgroundTransparency=1,Text="BEST EGG",TextColor3=SUB,TextSize=9,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},BestHeader)
local BestExpand=mk("TextButton",{Size=UDim2.new(0,20,0,20),Position=UDim2.new(1,0,0.5,-10),BackgroundTransparency=1,Text="∨",TextColor3=SUB,TextSize=14,Font=Enum.Font.GothamBold,BorderSizePixel=0},BestHeader)

local BestRow=mk("Frame",{Size=UDim2.new(1,0,0,58),BackgroundColor3=Color3.fromRGB(30,30,38),BorderSizePixel=0},BestCard)
pad(14,14,0,0,BestRow)
local BestImg=mk("ImageLabel",{Size=UDim2.new(0,44,0,44),Position=UDim2.new(0,0,0.5,-22),BackgroundColor3=Color3.fromRGB(40,40,52),BorderSizePixel=0,Image=""},BestRow)
corner(8,BestImg)
mk("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="🐾",TextSize=22,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center},BestImg)
local BestName=mk("TextLabel",{Size=UDim2.new(1,-150,0,20),Position=UDim2.new(0,54,0,10),BackgroundTransparency=1,Text="Scanning map...",TextColor3=TEXT,TextSize=13,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},BestRow)
local BestVal=mk("TextLabel",{Size=UDim2.new(0,80,0,20),Position=UDim2.new(1,-80,0,10),BackgroundTransparency=1,Text="",TextColor3=TEXT,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Right},BestRow)
local BestRar=mk("TextLabel",{Size=UDim2.new(1,-150,0,16),Position=UDim2.new(0,54,0,30),BackgroundTransparency=1,Text="",TextColor3=PURP,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},BestRow)

local EggListFrame=mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,Visible=false},BestCard)
mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},EggListFrame)

local isExpanded=false
local function toggleExpand()
    isExpanded=not isExpanded
    EggListFrame.Visible=isExpanded
    BestExpand.Text=isExpanded and "∧" or "∨"
end
BestExpand.MouseButton1Click:Connect(toggleExpand)
BestRow.MouseButton1Click:Connect(toggleExpand)

local function buildEggRow(data,idx)
    local rd=getRD(data.rarity)
    local row=mk("Frame",{Size=UDim2.new(1,0,0,50),BackgroundColor3=idx%2==0 and Color3.fromRGB(26,26,34) or Color3.fromRGB(30,30,38),BorderSizePixel=0,LayoutOrder=idx},EggListFrame)
    pad(14,14,0,0,row)
    mk("TextLabel",{Size=UDim2.new(0,20,1,0),BackgroundTransparency=1,Text="#"..idx,TextColor3=SUB,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},row)
    local img=mk("ImageLabel",{Size=UDim2.new(0,34,0,34),Position=UDim2.new(0,22,0.5,-17),BackgroundColor3=Color3.fromRGB(38,38,50),BorderSizePixel=0,Image=data.image or ""},row)
    corner(6,img)
    if (data.image or "")=="" then
        mk("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="🐾",TextSize=16,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center},img)
    end
    mk("TextLabel",{Size=UDim2.new(1,-150,0,18),Position=UDim2.new(0,62,0,8),BackgroundTransparency=1,Text=data.pet,TextColor3=TEXT,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},row)
    mk("TextLabel",{Size=UDim2.new(1,-150,0,14),Position=UDim2.new(0,62,0,26),BackgroundTransparency=1,Text=data.rarity,TextColor3=rd.color,TextSize=9,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},row)
    local valTxt=data.value~="" and data.value or data.dist.."m"
    mk("TextLabel",{Size=UDim2.new(0,70,0,18),Position=UDim2.new(1,-70,0.5,-9),BackgroundTransparency=1,Text=valTxt,TextColor3=TEXT,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Right},row)
    local sb=mk("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=""},row)
    sb.MouseButton1Click:Connect(function()
        if State.stealing then return end
        State.stealing=true
        stealEgg(data,function(ok) State.stealing=false end)
    end)
end

-- DIVIDER
mk("Frame",{Size=UDim2.new(1,-24,0,1),Position=UDim2.new(0,12,0,0),BackgroundColor3=Color3.fromRGB(38,38,52),BorderSizePixel=0,LayoutOrder=2},Body)

-- LOOP SECTION
local LoopCard=mk("Frame",{Size=UDim2.new(1,0,0,58),BackgroundColor3=CARD,BorderSizePixel=0,LayoutOrder=3},Body)
pad(14,14,8,8,LoopCard)
mk("TextLabel",{Size=UDim2.new(0,140,0,16),BackgroundTransparency=1,Text="TELEGUIADO",TextColor3=SUB,TextSize=10,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},LoopCard)
mk("TextLabel",{Size=UDim2.new(0,140,0,14),Position=UDim2.new(0,0,0,18),BackgroundTransparency=1,Text="LOOP ACTIVE",TextColor3=Color3.fromRGB(90,90,110),TextSize=9,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},LoopCard)

local LoopLabel=mk("TextLabel",{Size=UDim2.new(0,55,0,20),Position=UDim2.new(1,-110,0,8),BackgroundTransparency=1,Text="✓ LOOP",TextColor3=GREEN,TextSize=11,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Right},LoopCard)

local TTrack=mk("Frame",{Size=UDim2.new(0,40,0,22),Position=UDim2.new(1,-44,0.5,-11),BackgroundColor3=Color3.fromRGB(38,38,50),BorderSizePixel=0},LoopCard)
corner(999,TTrack)
local TThumb=mk("Frame",{Size=UDim2.new(0,16,0,16),Position=UDim2.new(0,3,0.5,-8),BackgroundColor3=SUB,BorderSizePixel=0},TTrack)
corner(999,TThumb)
local TBtn=mk("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=5},TTrack)

local loopOn=false
local function setLoop(v)
    loopOn=v State.loopActive=v
    local goal=v and UDim2.new(0,21,0.5,-8) or UDim2.new(0,3,0.5,-8)
    TweenService:Create(TThumb,TweenInfo.new(0.15),{Position=goal,BackgroundColor3=v and GREEN or SUB}):Play()
    TweenService:Create(TTrack,TweenInfo.new(0.15),{BackgroundColor3=v and Color3.fromRGB(25,65,40) or Color3.fromRGB(38,38,50)}):Play()
    LoopLabel.Text=v and "✓ LOOP" or "LOOP"
    LoopLabel.TextColor3=v and GREEN or SUB
end
TBtn.MouseButton1Click:Connect(function() setLoop(not loopOn) end)

-- DIVIDER
mk("Frame",{Size=UDim2.new(1,-24,0,1),Position=UDim2.new(0,12,0,0),BackgroundColor3=Color3.fromRGB(38,38,52),BorderSizePixel=0,LayoutOrder=4},Body)

-- RARITY FILTER
local RarCard=mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundColor3=CARD,BorderSizePixel=0,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=5},Body)
pad(14,14,8,10,RarCard)
mk("TextLabel",{Size=UDim2.new(1,0,0,14),BackgroundTransparency=1,Text="RARITY FILTER • TP + TELEGUIADO",TextColor3=GOLD,TextSize=9,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},RarCard)

local RarGrid=mk("Frame",{Size=UDim2.new(1,0,0,0),Position=UDim2.new(0,0,0,18),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},RarCard)
local RGL=mk("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,8),Wraps=true},RarGrid)

local rarFilterData={
    {name="Cosmic",color=PURP},{name="Secret",color=RED},
    {name="Eternal",color=Color3.fromRGB(150,60,255)},{name="Divine",color=GOLD},
}
for _,fd in ipairs(rarFilterData) do
    local isOn=State.selectedRar[fd.name] or false
    local btn=mk("Frame",{Size=UDim2.new(0,126,0,28),BackgroundColor3=Color3.fromRGB(26,26,34),BorderSizePixel=0},RarGrid)
    corner(6,btn)
    local btnStroke=mk("UIStroke",{Color=isOn and fd.color or Color3.fromRGB(45,45,60),Thickness=1},btn)
    local chk=mk("Frame",{Size=UDim2.new(0,16,0,16),Position=UDim2.new(0,8,0.5,-8),BackgroundColor3=isOn and fd.color or Color3.fromRGB(38,38,50),BorderSizePixel=0},btn)
    corner(4,chk)
    local chkMark=mk("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=isOn and "✓" or "",TextColor3=Color3.new(1,1,1),TextSize=10,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center},chk)
    local lbl=mk("TextLabel",{Size=UDim2.new(1,-32,0,16),Position=UDim2.new(0,28,0.5,-8),BackgroundTransparency=1,Text=fd.name,TextColor3=isOn and fd.color or SUB,TextSize=11,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},btn)
    local clickBtn=mk("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=""},btn)
    clickBtn.MouseButton1Click:Connect(function()
        State.selectedRar[fd.name]=not State.selectedRar[fd.name]
        local on=State.selectedRar[fd.name]
        chk.BackgroundColor3=on and fd.color or Color3.fromRGB(38,38,50)
        chkMark.Text=on and "✓" or ""
        lbl.TextColor3=on and fd.color or SUB
        btnStroke.Color=on and fd.color or Color3.fromRGB(45,45,60)
    end)
end

-- DIVIDER
mk("Frame",{Size=UDim2.new(1,-24,0,1),Position=UDim2.new(0,12,0,0),BackgroundColor3=Color3.fromRGB(38,38,52),BorderSizePixel=0,LayoutOrder=6},Body)

-- HOLD LONGEST BUTTON
local HoldCard=mk("Frame",{Size=UDim2.new(1,0,0,54),BackgroundColor3=CARD,BorderSizePixel=0,LayoutOrder=7},Body)
pad(14,14,8,8,HoldCard)
mk("TextLabel",{Size=UDim2.new(1,0,0,14),BackgroundTransparency=1,Text="⚡ ADMIN ABUSE",TextColor3=SUB,TextSize=9,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},HoldCard)
local HoldBtn=mk("TextButton",{Size=UDim2.new(1,0,0,28),Position=UDim2.new(0,0,0,18),BackgroundColor3=PURP,Text="👑  HOLD LONGEST — START",TextColor3=Color3.new(1,1,1),TextSize=11,Font=Enum.Font.GothamBold,BorderSizePixel=0},HoldCard)
corner(8,HoldBtn)
local holdOn2=false
HoldBtn.MouseButton1Click:Connect(function()
    holdOn2=not holdOn2
    if holdOn2 then
        HoldBtn.Text="👑  HOLD LONGEST — STOP"
        HoldBtn.BackgroundColor3=RED
        startHoldLongest()
    else
        HoldBtn.Text="👑  HOLD LONGEST — START"
        HoldBtn.BackgroundColor3=PURP
        stopHoldLongest()
    end
end)

-- // REFRESH UI
local function refreshUI(eggs)
    if #eggs>0 then
        local best=eggs[1]
        local rd=getRD(best.rarity)
        BestName.Text=best.pet
        BestRar.Text=best.rarity BestRar.TextColor3=rd.color
        BestVal.Text=best.value~="" and best.value or best.dist.."m away"
        if (best.image or "")~="" then BestImg.Image=best.image end
    else
        BestName.Text="No eggs found" BestRar.Text="" BestVal.Text=""
    end
    for _,c in ipairs(EggListFrame:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    for i,data in ipairs(eggs) do
        buildEggRow(data,i)
        if i>=8 then break end
    end
end

-- // SCAN LOOP
task.spawn(function()
    while true do
        task.wait(CFG.SCAN_INTERVAL)
        local ok,eggs=pcall(scanAllEggs)
        if ok and eggs then
            State.eggList=eggs
            if Panel.Visible then pcall(refreshUI,eggs) end
        end
    end
end)

-- // AUTO STEAL LOOP
task.spawn(function()
    while true do
        task.wait(CFG.LOOP_DELAY)
        if not State.loopActive or State.stealing then continue end
        local eggs=State.eggList
        if not eggs or #eggs==0 then continue end
        local target=nil
        for _,data in ipairs(eggs) do
            if State.selectedRar[data.rarity] then target=data break end
        end
        if not target then continue end
        State.stealing=true
        stealEgg(target,function(ok) State.stealing=false end)
    end
end)

-- // TOGGLE
IconBtn.MouseButton1Click:Connect(function()
    Panel.Visible=not Panel.Visible
    if Panel.Visible then
        local ok,eggs=pcall(scanAllEggs)
        if ok and eggs then State.eggList=eggs pcall(refreshUI,eggs) end
    end
end)
CloseBtn.MouseButton1Click:Connect(function() Panel.Visible=false end)

LocalPlayer.CharacterAdded:Connect(function()
    State.stealing=false stopFly()
    if holdActive then stopHoldLongest() holdOn2=false HoldBtn.Text="👑  HOLD LONGEST — START" HoldBtn.BackgroundColor3=PURP end
end)

print("🥋 ROCKSHI HUB Loaded!")
