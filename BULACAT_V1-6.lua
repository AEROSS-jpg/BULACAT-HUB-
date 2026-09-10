-- BULACAT HUB v2.0 — Lennon-Style UI
-- Loadstring: loadstring(game:HttpGet("https://raw.githubusercontent.com/AEROSS-jpg/BULACAT-HUB-/main/main.lua"))()

--============================================================
-- SERVICES
--============================================================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--============================================================
-- CONFIG
--============================================================
local CONFIG = {
    TITLE = "BULACAT HUB",
    VERSION = "v2.0",
    DISCORD = "discord.gg/nullstate",
    ACCENT = Color3.fromRGB(255, 60, 60),
    BG_DARK = Color3.fromRGB(18, 18, 22),
    BG_MED = Color3.fromRGB(28, 28, 34),
    BG_LIGHT = Color3.fromRGB(38, 38, 44),
    TEXT = Color3.fromRGB(240, 240, 245),
    TEXT_DIM = Color3.fromRGB(140, 140, 150),
    KEYBIND = Enum.KeyCode.RightShift,
    KEY_SYSTEM = true,
    VALID_KEYS = {"BULACAT-FREE-2026", "BULACAT-PREMIUM-001"},
}

--============================================================
-- STATE
--============================================================
local State = {
    Toggles = {},
    Sliders = {},
    Options = {},
    Connections = {},
    Tab = "Main",
    KeyAuth = not CONFIG.KEY_SYSTEM,
}

--============================================================
-- KEY SYSTEM
--============================================================
local function showKeyScreen()
    local gui = Instance.new("ScreenGui")
    gui.Name = "BULACAT_KEY"
    gui.ResetOnSpawn = false
    gui.Parent = CoreGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 400, 0, 220)
    frame.Position = UDim2.new(0.5, -200, 0.5, -110)
    frame.BackgroundColor3 = CONFIG.BG_DARK
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = CONFIG.ACCENT
    stroke.Thickness = 1.5
    stroke.Transparency = 0.3
    stroke.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 45)
    title.BackgroundTransparency = 1
    title.Text = CONFIG.TITLE .. " — KEY REQUIRED"
    title.TextColor3 = CONFIG.TEXT
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.Parent = frame

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, -40, 0, 25)
    sub.Position = UDim2.new(0, 20, 0, 50)
    sub.BackgroundTransparency = 1
    sub.Text = "Enter your key below to unlock the hub"
    sub.TextColor3 = CONFIG.TEXT_DIM
    sub.TextSize = 13
    sub.Font = Enum.Font.Gotham
    sub.Parent = frame

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -40, 0, 40)
    box.Position = UDim2.new(0, 20, 0, 85)
    box.BackgroundColor3 = CONFIG.BG_MED
    box.BorderSizePixel = 0
    box.Text = ""
    box.PlaceholderText = "BULACAT-XXXXX-XXXX"
    box.TextColor3 = CONFIG.TEXT
    box.TextSize = 14
    box.Font = Enum.Font.Gotham
    box.Parent = frame

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 6)
    boxCorner.Parent = box

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -40, 0, 40)
    btn.Position = UDim2.new(0, 20, 0, 140)
    btn.BackgroundColor3 = CONFIG.ACCENT
    btn.BorderSizePixel = 0
    btn.Text = "UNLOCK"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 15
    btn.Font = Enum.Font.GothamBold
    btn.Parent = frame

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -40, 0, 20)
    status.Position = UDim2.new(0, 20, 0, 185)
    status.BackgroundTransparency = 1
    status.Text = ""
    status.TextColor3 = Color3.fromRGB(255, 80, 80)
    status.TextSize = 12
    status.Font = Enum.Font.Gotham
    status.Parent = frame

    btn.MouseButton1Click:Connect(function()
        local key = box.Text:gsub("%s", "")
        local valid = false
        for _, k in ipairs(CONFIG.VALID_KEYS) do
            if key == k then valid = true; break end
        end
        if valid then
            State.KeyAuth = true
            status.Text = "✅ Key accepted!"
            status.TextColor3 = Color3.fromRGB(80, 255, 120)
            task.wait(0.5)
            gui:Destroy()
            loadHub()
        else
            status.Text = "❌ Invalid key. Try again."
            status.TextColor3 = Color3.fromRGB(255, 80, 80)
        end
    end)

    box.FocusLost:Connect(function(enter)
        if enter then btn:Fire() end
    end)
end

--============================================================
-- UI FRAMEWORK (Lennon Style)
--============================================================
local UI = {}
UI.__index = UI

function UI.new()
    local self = setmetatable({}, UI)
    self.Tabs = {}
    self.ActiveTab = "Main"
    self.Elements = {}

    -- Main GUI
    self.Gui = Instance.new("ScreenGui")
    self.Gui.Name = "BULACAT_HUB"
    self.Gui.ResetOnSpawn = false
    self.Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.Gui.Parent = CoreGui

    -- Main Window
    self.Window = Instance.new("Frame")
    self.Window.Size = UDim2.new(0, 620, 0, 420)
    self.Window.Position = UDim2.new(0.5, -310, 0.5, -210)
    self.Window.BackgroundColor3 = CONFIG.BG_DARK
    self.Window.BorderSizePixel = 0
    self.Window.Active = true
    self.Window.Draggable = true
    self.Window.Parent = self.Gui

    local winCorner = Instance.new("UICorner")
    winCorner.CornerRadius = UDim.new(0, 10)
    winCorner.Parent = self.Window

    local winStroke = Instance.new("UIStroke")
    winStroke.Color = CONFIG.ACCENT
    winStroke.Thickness = 1
    winStroke.Transparency = 0.6
    winStroke.Parent = self.Window

    -- Sidebar
    self.Sidebar = Instance.new("Frame")
    self.Sidebar.Size = UDim2.new(0, 140, 1, 0)
    self.Sidebar.BackgroundColor3 = CONFIG.BG_MED
    self.Sidebar.BorderSizePixel = 0
    self.Sidebar.Parent = self.Window

    local sideCorner = Instance.new("UICorner")
    sideCorner.CornerRadius = UDim.new(0, 10)
    sideCorner.Parent = self.Sidebar

    -- Sidebar Header
    self.SideHeader = Instance.new("Frame")
    self.SideHeader.Size = UDim2.new(1, 0, 0, 50)
    self.SideHeader.BackgroundColor3 = CONFIG.BG_LIGHT
    self.SideHeader.BorderSizePixel = 0
    self.SideHeader.Parent = self.Sidebar

    local shCorner = Instance.new("UICorner")
    shCorner.CornerRadius = UDim.new(0, 10)
    shCorner.Parent = self.SideHeader

    self.SideTitle = Instance.new("TextLabel")
    self.SideTitle.Size = UDim2.new(1, 0, 1, 0)
    self.SideTitle.BackgroundTransparency = 1
    self.SideTitle.Text = CONFIG.TITLE
    self.SideTitle.TextColor3 = CONFIG.ACCENT
    self.SideTitle.TextSize = 14
    self.SideTitle.Font = Enum.Font.GothamBold
    self.SideTitle.Parent = self.SideHeader

    -- Sidebar Buttons Container
    self.SideList = Instance.new("Frame")
    self.SideList.Size = UDim2.new(1, 0, 1, -50)
    self.SideList.Position = UDim2.new(0, 0, 0, 50)
    self.SideList.BackgroundTransparency = 1
    self.SideList.Parent = self.Sidebar

    self.SideLayout = Instance.new("UIListLayout")
    self.SideLayout.Padding = UDim.new(0, 4)
    self.SideLayout.SortOrder = Enum.SortOrder.LayoutOrder
    self.SideLayout.Parent = self.SideList

    -- Content Area
    self.Content = Instance.new("Frame")
    self.Content.Size = UDim2.new(1, -150, 1, -20)
    self.Content.Position = UDim2.new(0, 145, 0, 10)
    self.Content.BackgroundTransparency = 1
    self.Content.Parent = self.Window

    self.ContentScroll = Instance.new("ScrollingFrame")
    self.ContentScroll.Size = UDim2.new(1, 0, 1, 0)
    self.ContentScroll.BackgroundTransparency = 1
    self.ContentScroll.BorderSizePixel = 0
    self.ContentScroll.ScrollBarThickness = 4
    self.ContentScroll.ScrollBarImageColor3 = CONFIG.ACCENT
    self.ContentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.ContentScroll.Parent = self.Content

    self.ContentLayout = Instance.new("UIListLayout")
    self.ContentLayout.Padding = UDim.new(0, 6)
    self.ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    self.ContentLayout.Parent = self.ContentScroll

    self.ContentScroll.ChildAdded:Connect(function()
        self.ContentScroll.CanvasSize = UDim2.new(0, 0, 0, self.ContentLayout.AbsoluteContentSize.Y + 20)
    end)

    -- Close Button
    self.CloseBtn = Instance.new("TextButton")
    self.CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    self.CloseBtn.Position = UDim2.new(1, -35, 0, 8)
    self.CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    self.CloseBtn.BorderSizePixel = 0
    self.CloseBtn.Text = "X"
    self.CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    self.CloseBtn.TextSize = 14
    self.CloseBtn.Font = Enum.Font.GothamBold
    self.CloseBtn.Parent = self.Window

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = self.CloseBtn

    self.CloseBtn.MouseButton1Click:Connect(function()
        self.Gui.Enabled = false
    end)

    -- Keybind hint
    self.KeyHint = Instance.new("TextLabel")
    self.KeyHint.Size = UDim2.new(1, 0, 0, 20)
    self.KeyHint.Position = UDim2.new(0, 0, 1, -22)
    self.KeyHint.BackgroundTransparency = 1
    self.KeyHint.Text = "Press " .. CONFIG.KEYBIND.Name .. " to toggle"
    self.KeyHint.TextColor3 = CONFIG.TEXT_DIM
    self.KeyHint.TextSize = 11
    self.KeyHint.Font = Enum.Font.Gotham
    self.KeyHint.Parent = self.Window

    return self
end

function UI:AddTab(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 35)
    btn.Position = UDim2.new(0, 5, 0, 5)
    btn.BackgroundColor3 = CONFIG.BG_LIGHT
    btn.BorderSizePixel = 0
    btn.Text = "  " .. name
    btn.TextColor3 = CONFIG.TEXT_DIM
    btn.TextSize = 13
    btn.Font = Enum.Font.Gotham
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = self.SideList

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    self.Tabs[name] = { Button = btn, Frame = nil }

    btn.MouseButton1Click:Connect(function()
        self:SwitchTab(name)
    end)
end

function UI:SwitchTab(name)
    for tabName, tabData in pairs(self.Tabs) do
        if tabName == name then
            tabData.Button.BackgroundColor3 = CONFIG.ACCENT
            tabData.Button.TextColor3 = CONFIG.TEXT
        else
            tabData.Button.BackgroundColor3 = CONFIG.BG_LIGHT
            tabData.Button.TextColor3 = CONFIG.TEXT_DIM
        end
    end
    self.ActiveTab = name
    self:RenderTab(name)
end

function UI:RenderTab(name)
    for _, child in ipairs(self.ContentScroll:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end
    if self.Tabs[name] and self.Tabs[name].Render then
        self.Tabs[name].Render()
    end
end

function UI:SetRender(name, fn)
    if self.Tabs[name] then
        self.Tabs[name].Render = fn
    end
end

--============================================================
-- UI ELEMENTS
--============================================================
local Elements = {}

function Elements.Section(parent, text)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 28)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = CONFIG.ACCENT
    label.TextSize = 13
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    return frame
end

function Elements.Toggle(parent, text, default, callback)
    local state = default or false
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.BackgroundColor3 = CONFIG.BG_MED
    frame.BorderSizePixel = 0
    frame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = CONFIG.TEXT
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 38, 0, 18)
    toggle.Position = UDim2.new(1, -50, 0, 7)
    toggle.BackgroundColor3 = state and CONFIG.ACCENT or CONFIG.BG_LIGHT
    toggle.BorderSizePixel = 0
    toggle.Text = ""
    toggle.Parent = frame

    local tcorner = Instance.new("UICorner")
    tcorner.CornerRadius = UDim.new(1, 0)
    tcorner.Parent = toggle

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 14, 0, 14)
    indicator.Position = state and UDim2.new(1, -16, 0, 2) or UDim2.new(0, 2, 0, 2)
    indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    indicator.BorderSizePixel = 0
    indicator.Parent = toggle

    local icorner = Instance.new("UICorner")
    icorner.CornerRadius = UDim.new(1, 0)
    icorner.Parent = indicator

    toggle.MouseButton1Click:Connect(function()
        state = not state
        toggle.BackgroundColor3 = state and CONFIG.ACCENT or CONFIG.BG_LIGHT
        indicator.Position = state and UDim2.new(1, -16, 0, 2) or UDim2.new(0, 2, 0, 2)
        if callback then pcall(callback, state) end
    end)

    State.Toggles[text] = {
        Get = function() return state end,
        Set = function(v)
            state = v
            toggle.BackgroundColor3 = state and CONFIG.ACCENT or CONFIG.BG_LIGHT
            indicator.Position = state and UDim2.new(1, -16, 0, 2) or UDim2.new(0, 2, 0, 2)
            if callback then pcall(callback, state) end
        end
    }
    return frame
end

function Elements.Button(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = CONFIG.BG_MED
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = CONFIG.TEXT
    btn.TextSize = 13
    btn.Font = Enum.Font.Gotham
    btn.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        if callback then pcall(callback) end
    end)
    return btn
end

function Elements.Slider(parent, text, min, max, default, callback)
    local value = default or min
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 50)
    frame.BackgroundColor3 = CONFIG.BG_MED
    frame.BorderSizePixel = 0
    frame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 0, 20)
    label.Position = UDim2.new(0, 12, 0, 4)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = CONFIG.TEXT
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local valLabel = Instance.new("TextLabel")
    valLabel.Size = UDim2.new(0, 50, 0, 20)
    valLabel.Position = UDim2.new(1, -60, 0, 4)
    valLabel.BackgroundTransparency = 1
    valLabel.Text = tostring(value)
    valLabel.TextColor3 = CONFIG.ACCENT
    valLabel.TextSize = 12
    valLabel.Font = Enum.Font.GothamBold
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    valLabel.Parent = frame

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -24, 0, 6)
    bar.Position = UDim2.new(0, 12, 0, 30)
    bar.BackgroundColor3 = CONFIG.BG_LIGHT
    bar.BorderSizePixel = 0
    bar.Parent = frame

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(1, 0)
    barCorner.Parent = bar

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = CONFIG.ACCENT
    fill.BorderSizePixel = 0
    fill.Parent = bar

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    local dragging = false

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mouseX = UserInputService:GetMouseLocation().X
            local barPos = bar.AbsolutePosition.X
            local barSize = bar.AbsoluteSize.X
            local alpha = math.clamp((mouseX - barPos) / barSize, 0, 1)
            value = math.floor(min + (max - min) * alpha)
            fill.Size = UDim2.new(alpha, 0, 1, 0)
            valLabel.Text = tostring(value)
            if callback then pcall(callback, value) end
        end
    end)

    State.Sliders[text] = {
        Get = function() return value end,
        Set = function(v)
            value = math.clamp(v, min, max)
            local alpha = (value - min) / (max - min)
            fill.Size = UDim2.new(alpha, 0, 1, 0)
            valLabel.Text = tostring(value)
            if callback then pcall(callback, value) end
        end
    }
    return frame
end

function Elements.Input(parent, text, placeholder, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.BackgroundColor3 = CONFIG.BG_MED
    frame.BorderSizePixel = 0
    frame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 80, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = CONFIG.TEXT
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -110, 0, 22)
    box.Position = UDim2.new(0, 95, 0, 5)
    box.BackgroundColor3 = CONFIG.BG_LIGHT
    box.BorderSizePixel = 0
    box.Text = ""
    box.PlaceholderText = placeholder or ""
    box.TextColor3 = CONFIG.TEXT
    box.TextSize = 12
    box.Font = Enum.Font.Gotham
    box.Parent = frame

    local bcorner = Instance.new("UICorner")
    bcorner.CornerRadius = UDim.new(0, 4)
    bcorner.Parent = box

    box.FocusLost:Connect(function(enter)
        if enter and callback then
            pcall(callback, box.Text)
        end
    end)
    return frame
end

--============================================================
-- FEATURES
--============================================================
local Features = {}

function Features.SetupAimbot(ui)
    ui:AddTab("Aimbot")
    ui:SetRender("Aimbot", function()
        Elements.Section(ui.ContentScroll, "AIMBOT SETTINGS")
        Elements.Toggle(ui.ContentScroll, "Enable Aimbot", false, function(on)
            State.Toggles["AimbotEnabled"] = on
        end)
        Elements.Slider(ui.ContentScroll, "FOV Radius", 10, 500, 120, function(val)
            State.Options["FOV"] = val
        end)
        Elements.Slider(ui.ContentScroll, "Smoothness", 0, 100, 20, function(val)
            State.Options["Smooth"] = val / 100
        end)
        Elements.Toggle(ui.ContentScroll, "Show FOV Circle", true, function(on)
            State.Toggles["ShowFOV"] = on
        end)
    end)
end

function Features.SetupESP(ui)
    ui:AddTab("ESP")
    ui:SetRender("ESP", function()
        Elements.Section(ui.ContentScroll, "PLAYER ESP")
        Elements.Toggle(ui.ContentScroll, "Enable ESP", false, function(on)
            State.Toggles["ESPEnabled"] = on
        end)
        Elements.Toggle(ui.ContentScroll, "Show Names", true, function(on)
            State.Toggles["ESPNames"] = on
        end)
        Elements.Toggle(ui.ContentScroll, "Show Health", true, function(on)
            State.Toggles["ESPHealth"] = on
        end)
        Elements.Toggle(ui.ContentScroll, "Show Distance", true, function(on)
            State.Toggles["ESPDistance"] = on
        end)
        Elements.Toggle(ui.ContentScroll, "Box ESP", false, function(on)
            State.Toggles["ESPBox"] = on
        end)
        Elements.Toggle(ui.ContentScroll, "Tracer Lines", false, function(on)            State.Toggles["ESPTracer"] = on
        end)
        Elements.Section(ui.ContentScroll, "TEAM CHECK")
        Elements.Toggle(ui.ContentScroll, "Ignore Teammates", true, function(on)
            State.Toggles["IgnoreTeam"] = on
        end)
    end)
end

function Features.SetupMovement(ui)
    ui:AddTab("Movement")
    ui:SetRender("Movement", function()
        Elements.Section(ui.ContentScroll, "SPEED")
        Elements.Toggle(ui.ContentScroll, "Speed Hack", false, function(on)
            local char = LocalPlayer.Character
            if char and char:FindFirstChildOfClass("Humanoid") then
                char.Humanoid.WalkSpeed = on and (State.Options["SpeedValue"] or 50) or 16
            end
        end)
        Elements.Slider(ui.ContentScroll, "Speed Value", 16, 500, 50, function(val)
            State.Options["SpeedValue"] = val
            if State.Toggles["Speed Hack"] and State.Toggles["Speed Hack"].Get() then
                local char = LocalPlayer.Character
                if char and char:FindFirstChildOfClass("Humanoid") then
                    char.Humanoid.WalkSpeed = val
                end
            end
        end)

        Elements.Section(ui.ContentScroll, "JUMP")
        Elements.Toggle(ui.ContentScroll, "Infinite Jump", false, function(on)
            State.Toggles["InfJump"] = on
        end)
        Elements.Slider(ui.ContentScroll, "Jump Power", 50, 500, 50, function(val)
            State.Options["JumpPower"] = val
        end)

        Elements.Section(ui.ContentScroll, "FLY")
        Elements.Toggle(ui.ContentScroll, "Fly", false, function(on)
            State.Toggles["FlyEnabled"] = on
            if not on then
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    char.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
                end
            end
        end)
        Elements.Slider(ui.ContentScroll, "Fly Speed", 10, 200, 50, function(val)
            State.Options["FlySpeed"] = val
        end)

        Elements.Section(ui.ContentScroll, "NOCLIP")
        Elements.Toggle(ui.ContentScroll, "Noclip", false, function(on)
            State.Toggles["Noclip"] = on
            if on then
                local conn
                conn = RunService.Stepped:Connect(function()
                    if not State.Toggles["Noclip"].Get() then conn:Disconnect() return end
                    local char = LocalPlayer.Character
                    if char then
                        for _, part in ipairs(char:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                            end
                        end
                    end
                end)
                table.insert(State.Connections, conn)
            end
        end)
    end)
end

function Features.SetupTeleport(ui)
    ui:AddTab("Teleport")
    ui:SetRender("Teleport", function()
        Elements.Section(ui.ContentScroll, "PLAYER TELEPORT")
        Elements.Input(ui.ContentScroll, "Player Name", "Enter name...", function(name)
            State.Options["TPTarget"] = name
        end)
        Elements.Button(ui.ContentScroll, "Teleport to Player", function()
            local target = State.Options["TPTarget"]
            if target then
                local plr = Players:FindFirstChild(target)
                if plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame
                end
            end
        end)
        Elements.Button(ui.ContentScroll, "Teleport to Mouse", function()
            local mouse = UserInputService:GetMouseLocation()
            local ray = Camera:ViewportPointToRay(mouse.X, mouse.Y)
            local hit = workspace:Raycast(ray.Origin, ray.Direction * 1000)
            if hit and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(hit.Position + Vector3.new(0, 3, 0))
            end
        end)

        Elements.Section(ui.ContentScroll, "COORDINATES")
        Elements.Input(ui.ContentScroll, "X", "0", function(v) State.Options["TPX"] = tonumber(v) or 0 end)
        Elements.Input(ui.ContentScroll, "Y", "0", function(v) State.Options["TPY"] = tonumber(v) or 0 end)
        Elements.Input(ui.ContentScroll, "Z", "0", function(v) State.Options["TPZ"] = tonumber(v) or 0 end)
        Elements.Button(ui.ContentScroll, "Teleport to Coords", function()
            local x = State.Options["TPX"] or 0
            local y = State.Options["TPY"] or 0
            local z = State.Options["TPZ"] or 0
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(x, y, z)
            end
        end)
    end)
end

function Features.SetupMisc(ui)
    ui:AddTab("Misc")
    ui:SetRender("Misc", function()
        Elements.Section(ui.ContentScroll, "VISUAL")
        Elements.Toggle(ui.ContentScroll, "Fullbright", false, function(on)
            if on then
                local lighting = game:GetService("Lighting")
                State.Options["OldAmbient"] = lighting.Ambient
                State.Options["OldBrightness"] = lighting.Brightness
                lighting.Ambient = Color3.fromRGB(255, 255, 255)
                lighting.Brightness = 2
            else
                local lighting = game:GetService("Lighting")
                if State.Options["OldAmbient"] then lighting.Ambient = State.Options["OldAmbient"] end
                if State.Options["OldBrightness"] then lighting.Brightness = State.Options["OldBrightness"] end
            end
        end)
        Elements.Toggle(ui.ContentScroll, "No Fog", false, function(on)
            local lighting = game:GetService("Lighting")
            if on then
                State.Options["OldFogEnd"] = lighting.FogEnd
                State.Options["OldFogStart"] = lighting.FogStart
                lighting.FogEnd = 100000
                lighting.FogStart = 100000
            else
                if State.Options["OldFogEnd"] then lighting.FogEnd = State.Options["OldFogEnd"] end
                if State.Options["OldFogStart"] then lighting.FogStart = State.Options["OldFogStart"] end
            end
        end)

        Elements.Section(ui.ContentScroll, "SAFETY")
        Elements.Toggle(ui.ContentScroll, "Anti AFK", true, function(on)
            State.Toggles["AntiAFK"] = on
        end)
        Elements.Toggle(ui.ContentScroll, "Disable Reset", false, function(on)
            State.Toggles["NoReset"] = on
        end)

        Elements.Section(ui.ContentScroll, "SERVER")
        Elements.Button(ui.ContentScroll, "Rejoin Server", function()
            game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
        end)
        Elements.Button(ui.ContentScroll, "Server Hop", function()
            local req = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
            local data = game:GetService("HttpService"):JSONDecode(req)
            if data and data.data and #data.data > 0 then
                local server = data.data[math.random(1, #data.data)]
                game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
            end
        end)
    end)
end

--============================================================
-- FEATURE LOOPS
--============================================================
local function setupFeatureLoops()
    -- Aimbot loop
    RunService.RenderStepped:Connect(function()
        if not State.Toggles["AimbotEnabled"] or not State.Toggles["AimbotEnabled"].Get() then return end
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        if not LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then return end

        local closest, closestDist = nil, State.Options["FOV"] or 120
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == LocalPlayer then continue end
            if State.Toggles["IgnoreTeam"] and State.Toggles["IgnoreTeam"].Get() then
                if plr.Team == LocalPlayer.Team then continue end
            end
            if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local part = State.Toggles["TargetHead"] and State.Toggles["TargetHead"].Get()
                    and plr.Character:FindFirstChild("Head") or plr.Character.HumanoidRootPart
                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                    if dist < closestDist then
                        closest, closestDist = part, dist
                    end
                end
            end
        end

        if closest then
            local targetPos = closest.Position
            local camPos = Camera.CFrame.Position
            local aimCFrame = CFrame.new(camPos, targetPos)
            if State.Toggles["SilentAim"] and State.Toggles["SilentAim"].Get() then
                -- Silent aim would require hooking metatable - simplified here
            end
            local smooth = State.Options["Smooth"] or 0.2
            Camera.CFrame = Camera.CFrame:Lerp(aimCFrame, smooth)
        end
    end)

    -- ESP loop
    RunService.RenderStepped:Connect(function()
        if not State.Toggles["ESPEnabled"] or not State.Toggles["ESPEnabled"].Get() then
            -- Cleanup existing ESP
            for _, obj in ipairs(Camera:GetChildren()) do
                if obj.Name:sub(1, 3) == "ESP" then obj:Destroy() end
            end
            return
        end

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == LocalPlayer then continue end
            if State.Toggles["IgnoreTeam"] and State.Toggles["IgnoreTeam"].Get() and plr.Team == LocalPlayer.Team then continue end
            if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChildOfClass("Humanoid") then
                local hrp = plr.Character.HumanoidRootPart
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local existing = Camera:FindFirstChild("ESP_" .. plr.Name)
                    if not existing then
                        local billboard = Instance.new("BillboardGui")
                        billboard.Name = "ESP_" .. plr.Name
                        billboard.Size = UDim2.new(0, 200, 0, 50)
                        billboard.AlwaysOnTop = true
                        billboard.Parent = Camera

                        local nameLabel = Instance.new("TextLabel")
                        nameLabel.Name = "NameLabel"
                        nameLabel.Size = UDim2.new(1, 0, 0, 15)
                        nameLabel.BackgroundTransparency = 1
                        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                        nameLabel.TextStrokeTransparency = 0
                        nameLabel.TextSize = 12
                        nameLabel.Font = Enum.Font.GothamBold
                        nameLabel.Parent = billboard

                        local healthLabel = Instance.new("TextLabel")
                        healthLabel.Name = "HealthLabel"
                        healthLabel.Size = UDim2.new(1, 0, 0, 15)
                        healthLabel.Position = UDim2.new(0, 0, 0, 15)
                        healthLabel.BackgroundTransparency = 1
                        healthLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
                        healthLabel.TextStrokeTransparency = 0
                        healthLabel.TextSize = 11
                        healthLabel.Font = Enum.Font.Gotham
                        healthLabel.Parent = billboard

                        local distLabel = Instance.new("TextLabel")
                        distLabel.Name = "DistLabel"
                        distLabel.Size = UDim2.new(1, 0, 0, 15)
                        distLabel.Position = UDim2.new(0, 0, 0, 30)
                        distLabel.BackgroundTransparency = 1
                        distLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                        distLabel.TextStrokeTransparency = 0
                        distLabel.TextSize = 10
                        distLabel.Font = Enum.Font.Gotham
                        distLabel.Parent = billboard
                    end

                    local billboard = Camera:FindFirstChild("ESP_" .. plr.Name)
                    if billboard then
                        billboard.Adornee = hrp
                        local nameLabel = billboard:FindFirstChild("NameLabel")
                        local healthLabel = billboard:FindFirstChild("HealthLabel")
                        local distLabel = billboard:FindFirstChild("DistLabel")

                        if nameLabel then
                            nameLabel.Text = State.Toggles["ESPNames"] and State.Toggles["ESPNames"].Get() and plr.Name or ""
                        end
                        if healthLabel then
                            healthLabel.Text = State.Toggles["ESPHealth"] and State.Toggles["ESPHealth"].Get() and ("HP: " .. math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)) or ""
                        end
                        if distLabel then
                            local dist = math.floor((hrp.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude)
                            distLabel.Text = State.Toggles["ESPDistance"] and State.Toggles["ESPDistance"].Get() and (dist .. " studs") or ""
                        end
                    end
                end
            end
        end
    end)

    -- Anti AFK
    LocalPlayer.Idled:Connect(function()
        if State.Toggles["AntiAFK"] and State.Toggles["AntiAFK"].Get() then
            local vu = game:GetService("VirtualUser")
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end
    end)

    -- Infinite Jump
    UserInputService.JumpRequest:Connect(function()
        if State.Toggles["InfJump"] and State.Toggles["InfJump"].Get() then
            local char = LocalPlayer.Character
            if char and char:FindFirstChildOfClass("Humanoid") then
                char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)

    -- Fly
    RunService.RenderStepped:Connect(function()
        if not State.Toggles["FlyEnabled"] or not State.Toggles["FlyEnabled"].Get() then return end
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local hrp = char.HumanoidRootPart
        local speed = State.Options["FlySpeed"] or 50
        local moveDir = Vector3.new()
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir -= Vector3.new(0, 1, 0) end
        if moveDir.Magnitude > 0 then
            hrp.Velocity = moveDir.Unit * speed
        else
            hrp.Velocity = Vector3.new(0, 0, 0)
        end
    end)
end

--============================================================
-- LOAD HUB
--============================================================
function loadHub()
    local ui = UI.new()

    -- Register tabs
    ui:AddTab("Main")
    ui:AddTab("Aimbot")
    ui:AddTab("ESP")
    ui:AddTab("Movement")
    ui:AddTab("Teleport")
    ui:AddTab("Misc")

    -- Main tab render
    ui:SetRender("Main", function()
        Elements.Section(ui.ContentScroll, "BULACAT HUB " .. CONFIG.VERSION)
        Elements.Button(ui.ContentScroll, "Discord: " .. CONFIG.DISCORD, function()
            setclipboard(CONFIG.DISCORD)
        end)
        Elements.Section(ui.ContentScroll, "QUICK TOGGLES")
        Elements.Toggle(ui.ContentScroll, "Speed Hack", false, function(on)
            local char = LocalPlayer.Character
            if char and char:FindFirstChildOfClass("Humanoid") then
                char.Humanoid.WalkSpeed = on and (State.Options["SpeedValue"] or 50) or 16
            end
        end)
        Elements.Toggle(ui.ContentScroll, "Infinite Jump", false, function(on)
            State.Toggles["InfJump"] = on
        end)
        Elements.Toggle(ui.ContentScroll, "Fullbright", false, function(on)
            local lighting = game:GetService("Lighting")
            if on then
                State.Options["OldAmbient"] = lighting.Ambient
                State.Options["OldBrightness"] = lighting.Brightness
                lighting.Ambient = Color3.fromRGB(255, 255, 255)
                lighting.Brightness = 2
            else
                if State.Options["OldAmbient"] then lighting.Ambient = State.Options["OldAmbient"] end
                if State.Options["OldBrightness"] then lighting.Brightness = State.Options["OldBrightness"] end
            end
        end)
        Elements.Section(ui.ContentScroll, "INFO")
        Elements.Button(ui.ContentScroll, "Copy Loadstring", function()
            setclipboard('loadstring(game:HttpGet("https://raw.githubusercontent.com/AEROSS-jpg/BULACAT-HUB-/main/main.lua"))()')
        end)
    end)

    -- Setup feature tabs
    Features.SetupAimbot(ui)
    Features.SetupESP(ui)
    Features.SetupMovement(ui)
    Features.SetupTeleport(ui)
    Features.SetupMisc(ui)

    -- Switch to main tab
    ui:SwitchTab("Main")

    -- Keybind toggle
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == CONFIG.KEYBIND then
            ui.Gui.Enabled = not ui.Gui.Enabled
        end
    end)

    -- Start feature loops
    setupFeatureLoops()

    print("[BULACAT] Hub loaded — Lennon style. Press " .. CONFIG.KEYBIND.Name .. " to toggle.")
end

--============================================================
-- INIT
--============================================================
if CONFIG.KEY_SYSTEM and not State.KeyAuth then
    showKeyScreen()
else
    loadHub()
end
```