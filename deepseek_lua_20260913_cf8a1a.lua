--[[
  BULACAT Script Loader (no key system)
  Served by: GET /api/script
]]

local rawServerUrl = getgenv and getgenv().ServerURL or _G.ServerURL or "https://zeroinhub.com"
local serverUrl = (rawServerUrl and rawServerUrl ~= "" and not string.find(rawServerUrl, "{{")) and rawServerUrl or "https://zeroinhub.com"

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")


-- executor HWID
local function getHwid()
  local ok, id = pcall(function() return game:GetService("RbxAnalyticsService"):GetClientId() end)
  if ok and id and id ~= "" then return tostring(id) end
  return tostring(Players.LocalPlayer.UserId)
end


-- POST-capable HTTP (kept for other uses; auth no longer needs it)
local function httpPost(url, json)
  local opts = { Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = json }
  if syn and syn.request then return syn.request(opts) end
  if request then return request(opts) end
  if http_request then return http_request(opts) end
  if http and http.request then return http.request(opts) end
  return nil
end


local targetParent = (gethui and pcall(function() return gethui() end) and gethui()) or CoreGui or Players.LocalPlayer:WaitForChild("PlayerGui")


-- ══════════════════════════════════════════════════════════════
--  UI  — loader panel
-- ══════════════════════════════════════════════════════════════
local Gui = Instance.new("ScreenGui")
Gui.Name = "BULACATLoader"
Gui.Parent = targetParent
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 360, 0, 190)
Frame.Position = UDim2.new(0.5, -180, 0.5, -95)
Frame.BackgroundColor3 = Color3.fromRGB(4, 10, 7)
Frame.BorderSizePixel = 0
Frame.ClipsDescendants = true
Frame.Parent = Gui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 12)
Corner.Parent = Frame

local Stroke = Instance.new("UIStroke")
Stroke.Thickness = 1.2
Stroke.Color = Color3.fromRGB(34, 197, 94)
Stroke.Transparency = 0.65
Stroke.Parent = Frame

local TopLine = Instance.new("Frame")
TopLine.Size = UDim2.new(1, 0, 0, 2)
TopLine.Position = UDim2.new(0, 0, 0, 0)
TopLine.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
TopLine.BorderSizePixel = 0
TopLine.Parent = Frame

local TopLineGrad = Instance.new("UIGradient")
TopLineGrad.Transparency = NumberSequence.new({
  NumberSequenceKeypoint.new(0, 0.9),
  NumberSequenceKeypoint.new(0.5, 0),
  NumberSequenceKeypoint.new(1, 0.9)
})
TopLineGrad.Parent = TopLine

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 46)
Header.Position = UDim2.new(0, 0, 0, 0)
Header.BackgroundTransparency = 1
Header.Parent = Frame

local BrandDot = Instance.new("Frame")
BrandDot.Size = UDim2.new(0, 8, 0, 8)
BrandDot.Position = UDim2.new(0, 20, 0, 19)
BrandDot.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
BrandDot.BorderSizePixel = 0
BrandDot.Parent = Header
Instance.new("UICorner", BrandDot).CornerRadius = UDim.new(1, 0)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0, 200, 0, 46)
Title.Position = UDim2.new(0, 36, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "BULACAT"
Title.TextColor3 = Color3.fromRGB(236, 253, 245)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Badge = Instance.new("Frame")
Badge.Size = UDim2.new(0, 52, 0, 20)
Badge.Position = UDim2.new(0, 116, 0, 13)
Badge.BackgroundColor3 = Color3.fromRGB(11, 32, 20)
Badge.BorderSizePixel = 0
Badge.Parent = Header
Instance.new("UICorner", Badge).CornerRadius = UDim.new(0, 6)

local BadgeStroke = Instance.new("UIStroke")
BadgeStroke.Thickness = 1
BadgeStroke.Color = Color3.fromRGB(34, 197, 94)
BadgeStroke.Transparency = 0.5
BadgeStroke.Parent = Badge

local BadgeText = Instance.new("TextLabel")
BadgeText.Size = UDim2.new(1, 0, 1, 0)
BadgeText.BackgroundTransparency = 1
BadgeText.Text = "LOAD"
BadgeText.TextColor3 = Color3.fromRGB(74, 222, 128)
BadgeText.Font = Enum.Font.GothamBold
BadgeText.TextSize = 10
BadgeText.Parent = Badge

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -38, 0, 10)
CloseBtn.BackgroundColor3 = Color3.fromRGB(11, 23, 17)
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(125, 161, 140)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 13
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = Header
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

local CloseStroke = Instance.new("UIStroke")
CloseStroke.Thickness = 1
CloseStroke.Color = Color3.fromRGB(34, 197, 94)
CloseStroke.Transparency = 0.8
CloseStroke.Parent = CloseBtn

CloseBtn.MouseEnter:Connect(function()
  CloseBtn.TextColor3 = Color3.fromRGB(239, 68, 68)
  CloseBtn.BackgroundColor3 = Color3.fromRGB(28, 12, 12)
  CloseStroke.Color = Color3.fromRGB(239, 68, 68)
  CloseStroke.Transparency = 0.4
end)
CloseBtn.MouseLeave:Connect(function()
  CloseBtn.TextColor3 = Color3.fromRGB(125, 161, 140)
  CloseBtn.BackgroundColor3 = Color3.fromRGB(11, 23, 17)
  CloseStroke.Color = Color3.fromRGB(34, 197, 94)
  CloseStroke.Transparency = 0.8
end)
CloseBtn.MouseButton1Click:Connect(function()
  Gui:Destroy()
end)

-- Info text
local Info = Instance.new("TextLabel")
Info.Size = UDim2.new(1, -40, 0, 16)
Info.Position = UDim2.new(0, 20, 0, 48)
Info.BackgroundTransparency = 1
Info.Text = "Loading is automatic. Click Load to retry if needed."
Info.TextColor3 = Color3.fromRGB(125, 161, 140)
Info.TextSize = 11
Info.Font = Enum.Font.Gotham
Info.TextXAlignment = Enum.TextXAlignment.Left
Info.Parent = Frame

-- Status text
local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(0, 320, 0, 40)
Status.Position = UDim2.new(0.5, -160, 0, 72)
Status.BackgroundTransparency = 1
Status.Text = "Initializing..."
Status.TextColor3 = Color3.fromRGB(125, 161, 140)
Status.TextSize = 12
Status.Font = Enum.Font.GothamMedium
Status.TextWrapped = true
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Frame

-- Load button
local Continue = Instance.new("TextButton")
Continue.Size = UDim2.new(0, 320, 0, 40)
Continue.Position = UDim2.new(0.5, -160, 0, 120)
Continue.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
Continue.BorderSizePixel = 0
Continue.Text = "Load Script"
Continue.TextColor3 = Color3.fromRGB(3, 16, 8)
Continue.Font = Enum.Font.GothamBold
Continue.TextSize = 14
Continue.AutoButtonColor = true
Continue.Parent = Frame
Instance.new("UICorner", Continue).CornerRadius = UDim.new(0, 8)

local ContinueGrad = Instance.new("UIGradient")
ContinueGrad.Color = ColorSequence.new({
  ColorSequenceKeypoint.new(0, Color3.fromRGB(52, 211, 153)),
  ColorSequenceKeypoint.new(1, Color3.fromRGB(34, 197, 94))
})
ContinueGrad.Parent = Continue

-- Discord button
local DiscordBtn = Instance.new("TextButton")
DiscordBtn.Size = UDim2.new(0, 320, 0, 30)
DiscordBtn.Position = UDim2.new(0.5, -160, 0, 166)
DiscordBtn.BackgroundColor3 = Color3.fromRGB(11, 23, 17)
DiscordBtn.BorderSizePixel = 0
DiscordBtn.Text = "💬  Discord"
DiscordBtn.TextColor3 = Color3.fromRGB(129, 140, 248)
DiscordBtn.Font = Enum.Font.GothamBold
DiscordBtn.TextSize = 12
DiscordBtn.Parent = Frame
Instance.new("UICorner", DiscordBtn).CornerRadius = UDim.new(0, 8)

local DiscordStroke = Instance.new("UIStroke")
DiscordStroke.Thickness = 1
DiscordStroke.Color = Color3.fromRGB(88, 101, 242)
DiscordStroke.Transparency = 0.5
DiscordStroke.Parent = DiscordBtn


-- Window drag
local dragging, dragInput, dragStart, startPos
local function updateDrag(input)
  local delta = input.Position - dragStart
  Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

Header.InputBegan:Connect(function(input)
  if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
    dragging = true
    dragStart = input.Position
    startPos = Frame.Position
    input.Changed:Connect(function()
      if input.UserInputState == Enum.UserInputState.End then
        dragging = false
      end
    end)
  end
end)

Header.InputChanged:Connect(function(input)
  if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
    dragInput = input
  end
end)

UserInputService.InputChanged:Connect(function(input)
  if input == dragInput and dragging then
    updateDrag(input)
  end
end)


-- ══════════════════════════════════════════════════════════════
--  LOADER
-- ══════════════════════════════════════════════════════════════
local function setStatus(text, color)
  if not Status or not Status.Parent then return end
  Status.Text = text
  Status.TextColor3 = color or Color3.fromRGB(125, 161, 140)
end

local function copyToClipboard(text)
  local fn = setclipboard or toclipboard or (Clipboard and Clipboard.set)
  if fn then pcall(fn, text) return true end
  return false
end

local isLoading = false

local function loadMainScript()
  if isLoading then return end
  isLoading = true

  Continue.Text = "Loading..."
  Continue.AutoButtonColor = false
  Continue.BackgroundColor3 = Color3.fromRGB(20, 80, 45)
  Continue.TextColor3 = Color3.fromRGB(167, 199, 181)

  setStatus("Fetching script from server...", Color3.fromRGB(245, 158, 11))

  task.spawn(function()
    local hwid = getHwid()
    local placeId = tostring(game.PlaceId)
    local univId = tostring(game.GameId)
    local playerId = tostring(Players.LocalPlayer.UserId)

    local scriptUrl = serverUrl .. "/api/script"
      .. "?hwid=" .. hwid
      .. "&place_id=" .. placeId
      .. "&univ_id=" .. univId
      .. "&player_id=" .. playerId

    local ok, src = pcall(function() return game:HttpGet(scriptUrl) end)
    if not ok or not src or #src == 0 then
      setStatus("Failed to fetch script from server.", Color3.fromRGB(239, 68, 68))
      Continue.Text = "Retry"
      Continue.AutoButtonColor = true
      Continue.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
      Continue.TextColor3 = Color3.fromRGB(3, 16, 8)
      isLoading = false
      return
    end

    setStatus("Executing script...", Color3.fromRGB(74, 222, 128))

    local fn, err = loadstring(src)
    if not fn then
      -- fallback: maybe the response is a plain URL to another script
      if string.find(src, "^https?://") then
        local ok2, src2 = pcall(function() return game:HttpGet(src) end)
        if ok2 and src2 then
          fn, err = loadstring(src2)
        end
      end
    end

    if not fn then
      setStatus("Invalid script received: " .. tostring(err), Color3.fromRGB(239, 68, 68))
      Continue.Text = "Retry"
      Continue.AutoButtonColor = true
      Continue.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
      Continue.TextColor3 = Color3.fromRGB(3, 16, 8)
      isLoading = false
      return
    end

    local ok3, runErr = pcall(fn)
    if not ok3 then
      setStatus("Script error: " .. tostring(runErr), Color3.fromRGB(239, 68, 68))
      Continue.Text = "Retry"
      Continue.AutoButtonColor = true
      Continue.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
      Continue.TextColor3 = Color3.fromRGB(3, 16, 8)
      isLoading = false
      return
    end

    setStatus("Loaded. Closing panel...", Color3.fromRGB(74, 222, 128))
    task.wait(0.4)
    Gui:Destroy()
  end)
end

Continue.MouseButton1Click:Connect(loadMainScript)

DiscordBtn.MouseButton1Click:Connect(function()
  copyToClipboard("https://discord.gg/HjbXC5gbsN")
  setStatus("Discord invite copied to clipboard.", Color3.fromRGB(129, 140, 248))
end)


-- ══════════════════════════════════════════════════════════════
--  AUTO-LOAD on start
-- ══════════════════════════════════════════════════════════════
task.spawn(function()
  task.wait(0.3)
  loadMainScript()
end)