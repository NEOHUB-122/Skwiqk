--=============================================================
-- NEOHUB | FISCH SCRIPT (NO DESTROY GUI VERSION)
--====================================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--====================================================================
-- ⚡ PLACE ID LOCK ⚡
--====================================================================
local PlaceIdLock = 16732694052 -- ID game Fisch di Roblox

if PlaceIdLock and game.PlaceId ~= PlaceIdLock then
    Player:Kick("[ NEOHUB ]\n\nSorry, this script is specifically designed for Place ID: " .. tostring(PlaceIdLock) .. ".")
    task.wait(0.5)
    return
end


--====================================================================
-- CONFIG
--====================================================================
local Config = {
    Version = "V2.0",
    Logo = "rbxassetid://80870779095600",
    SlashSFX = "rbxassetid://137628815514180",
    DiscordIcon = "rbxassetid://122715425359428",
    YouTubeIcon = "rbxassetid://100722440559649",
    DiscordLink = "https://discord.gg/neohub",

    TeamNeoFlex = "rbxassetid://130928776041330",
    TeamNeoLow = "rbxassetid://126079599694770",
    TeamNeoParty = "rbxassetid://96723739082694",
    TeamNeoShy = "rbxassetid://93439870067142",

    Background = Color3.fromRGB(8, 10, 16),
    Panel = Color3.fromRGB(13, 17, 27),
    Section = Color3.fromRGB(17, 23, 36),
    Blue = Color3.fromRGB(0, 145, 255),
    BlueDark = Color3.fromRGB(0, 65, 125),
    White = Color3.fromRGB(235, 242, 255),
    Gray = Color3.fromRGB(135, 148, 170),
    Green = Color3.fromRGB(70, 220, 130),
    Yellow = Color3.fromRGB(255, 205, 65),
    Red = Color3.fromRGB(255, 75, 85),

    DefaultUIScale = 100,
}

local State = { ShowNotifications = true, UIScale = Config.DefaultUIScale }

local Existing = PlayerGui:FindFirstChild("NEOHUB_GUI")
if Existing then Existing:Destroy() end

--====================================================================
-- FISCH AUTOMATION & LOGIC SETUP
--====================================================================
pcall(setthreadidentity, 8)
local FischConfig = {
    Enabled = false,
    Instant = false,
    Power = 100,
    PerfectCast = true,
    Delay = 1,
}
local LoopThread = nil

local ResetRemote = ReplicatedStorage:FindFirstChild("events") and ReplicatedStorage.events:FindFirstChild("FishingRod/Reset") or nil

local function isRod(tool)
    return tool and tool:IsA("Tool") and tool:FindFirstChild("events") ~= nil
end

local function getEquippedRod()
    local char = Player.Character
    if not char then return nil end
    local tool = char:FindFirstChildOfClass("Tool")
    return isRod(tool) and tool or nil
end

local function getAnyRod()
    local rod = getEquippedRod()
    if rod then return rod end
    local bp = Player:FindFirstChildOfClass("Backpack")
    if not bp then return nil end
    for _, t in ipairs(bp:GetChildren()) do
        if isRod(t) then
            local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:EquipTool(t)
                local t0 = os.clock()
                while os.clock() - t0 < 2 do
                    rod = getEquippedRod()
                    if rod then return rod end
                    task.wait(0.05)
                end
            end
        end
    end
    return nil
end

RunService.RenderStepped:Connect(function()
    local okRC, RC = pcall(function() return require(ReplicatedStorage.client.legacyControllers.ReelController) end)
    if okRC and RC and RC.ActiveReel and FischConfig.Enabled then
        local reel = RC.ActiveReel
        reel.frozenUntil = math.max(reel.frozenUntil, tick() + 0.25)
        reel.barPosition = reel.fishPosition
        reel.onbar = true
    end
end)

local function solveReel(reel)
    if not reel then return end
    local okRC, RC = pcall(function() return require(ReplicatedStorage.client.legacyControllers.ReelController) end)
    if FischConfig.Instant then
        local t0 = os.clock()
        while not reel.ready and os.clock() - t0 < 15 do task.wait(0.05) end
        if okRC and RC and RC.ActiveReel == reel then
            pcall(function() reel:EndMinigame(true) end)
        end
    else
        local t0 = os.clock()
        while okRC and RC and RC.ActiveReel == reel and os.clock() - t0 < 180 do
            task.wait(0.1)
        end
    end
end

local function autofishLoop()
    while FischConfig.Enabled do
        local rod = getAnyRod()
        if not rod then task.wait(2); continue end
        if ResetRemote and (rod:FindFirstChild("bobber") or (rod.values and rod.values.casted.Value)) then
            pcall(function() ResetRemote:FireServer() end)
            task.wait(0.3)
        end
        
        local CastRF = ReplicatedStorage:FindFirstChild("packages") and require(ReplicatedStorage.packages.Net):RemoteFunction("FishingRod/Cast")
        local ok, res = pcall(function()
            return CastRF:InvokeServer(math.clamp(FischConfig.Power, 0, 100), FischConfig.PerfectCast)
        end)
        
        if ok and res == true then
            local t0 = os.clock()
            local okRC, RC = pcall(function() return require(ReplicatedStorage.client.legacyControllers.ReelController) end)
            while FischConfig.Enabled do
                if okRC and RC and RC.ActiveReel then break end
                if os.clock() - t0 > 150 then break end
                if not getEquippedRod() then break end
                local shakeui = Player.PlayerGui:FindFirstChild("shakeui")
                if shakeui then
                    local ShakeEv = ReplicatedStorage:FindFirstChild("packages") and require(ReplicatedStorage.packages.Net):RemoteEvent("LureShake/Shake")
                    pcall(function() ShakeEv:FireServer() end)
                    task.wait(0.3)
                else
                    task.wait(0.1)
                end
            end
            if okRC and RC then solveReel(RC.ActiveReel) end
            task.wait(FischConfig.Delay + math.random() * 0.5)
        else
            task.wait(2)
        end
    end
end

--====================================================================
-- MAIN UI (ORIGINAL STRUCTURE)
--====================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NEOHUB_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.Parent = PlayerGui

local function Create(className, properties, parent)
    local object = Instance.new(className)
    for property, value in pairs(properties or {}) do object[property] = value end
    object.Parent = parent
    return object
end

local function Corner(parent, radius) return Create("UICorner", { CornerRadius = UDim.new(0, radius or 8) }, parent) end
local function Stroke(parent, color, thickness, transparency) return Create("UIStroke", { Color = color or Config.Blue, Thickness = thickness or 1, Transparency = transparency or 0 }, parent) end
local function Label(parent, text, size, position, fontSize, color, font)
    return Create("TextLabel", { BackgroundTransparency = 1, Position = position or UDim2.new(), Size = size or UDim2.new(1, 0, 0, 25), Font = font or Enum.Font.Gotham, Text = text or "", TextColor3 = color or Config.White, TextSize = fontSize or 12, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center }, parent)
end
local function Button(parent, text, size, position)
    local button = Create("TextButton", { Size = size, Position = position, BackgroundColor3 = Config.Section, BorderSizePixel = 0, AutoButtonColor = false, Font = Enum.Font.GothamSemibold, Text = text, TextColor3 = Config.White, TextSize = 11 }, parent)
    Corner(button, 7)
    local outline = Stroke(button, Config.Blue, 1, 0.65); outline.Name = "UIStroke"
    button.MouseEnter:Connect(function() TweenService:Create(button, TweenInfo.new(0.12), { BackgroundColor3 = Config.BlueDark }):Play() end)
    button.MouseLeave:Connect(function() TweenService:Create(button, TweenInfo.new(0.12), { BackgroundColor3 = Config.Section }):Play() end)
    return button
end

local function Notify(title, message)
    if not State.ShowNotifications then return end
    pcall(function() StarterGui:SetCore("SendNotification", { Title = title, Text = message, Duration = 3 }) end)
end

local function MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPosition = false, nil, nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPosition = frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
end

local Main = Create("Frame", { Size = UDim2.new(0, 570, 0, 375), Position = UDim2.new(0.5, -285, 0.5, -187), BackgroundColor3 = Config.Background, BorderSizePixel = 0, Visible = false, ZIndex = 1 }, ScreenGui)
Corner(Main, 10); Stroke(Main, Config.Blue, 1.5)
local MainScale = Create("UIScale", { Scale = State.UIScale / 100 }, Main)

local Header = Create("Frame", { Size = UDim2.new(1, 0, 0, 48), BackgroundColor3 = Config.Panel, BorderSizePixel = 0, ZIndex = 2 }, Main)
Corner(Header, 10)
Create("Frame", { Size = UDim2.new(1, 0, 0, 10), Position = UDim2.new(0, 0, 1, -10), BackgroundColor3 = Config.Panel, BorderSizePixel = 0, ZIndex = 2 }, Header)
Create("ImageLabel", { Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(0, 12, 0, 9), BackgroundTransparency = 1, Image = Config.Logo, ScaleType = Enum.ScaleType.Fit, ZIndex = 3 }, Header)
Label(Header, "NEOHUB FISCH", UDim2.new(0, 145, 0, 23), UDim2.new(0, 49, 0, 5), 16, Config.Blue).ZIndex = 3
Label(Header, Config.Version, UDim2.new(0, 180, 0, 17), UDim2.new(0, 50, 0, 26), 9, Config.Gray).ZIndex = 3

local MinimizeButton = Button(Header, "−", UDim2.new(0, 31, 0, 28), UDim2.new(1, -43, 0, 10))
MinimizeButton.TextSize = 20; MinimizeButton.ZIndex = 3
MakeDraggable(Main, Header)

local Sidebar = Create("Frame", { Size = UDim2.new(0, 135, 1, -58), Position = UDim2.new(0, 8, 0, 54), BackgroundColor3 = Config.Panel, BorderSizePixel = 0, ZIndex = 2 }, Main)
Corner(Sidebar, 8)
Label(Sidebar, "TABS", UDim2.new(1, -18, 0, 22), UDim2.new(0, 10, 0, 7), 9, Config.Gray).ZIndex = 3

local TabButtons = Create("Frame", { Size = UDim2.new(1, -12, 1, -39), Position = UDim2.new(0, 6, 0, 32), BackgroundTransparency = 1, ZIndex = 3 }, Sidebar)
Create("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, TabButtons)

local Content = Create("ScrollingFrame", { Size = UDim2.new(1, -157, 1, -66), Position = UDim2.new(0, 149, 0, 56), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = Config.Blue, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 2 }, Main)
Create("UIPadding", { PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 6), PaddingBottom = UDim.new(0, 10) }, Content)
Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, Content)

local MiniButton = Create("ImageButton", { Size = UDim2.new(0, 52, 0, 52), Position = UDim2.new(0, 18, 0.45, 0), BackgroundColor3 = Config.Panel, Image = Config.Logo, ScaleType = Enum.ScaleType.Fit, Visible = false, AutoButtonColor = false, ZIndex = 3 }, ScreenGui)
Corner(MiniButton, 13); Stroke(MiniButton, Config.Blue, 2)
MakeDraggable(MiniButton)
MinimizeButton.MouseButton1Click:Connect(function() Main.Visible = false; MiniButton.Visible = true end)
MiniButton.MouseButton1Click:Connect(function() Main.Visible = true; MiniButton.Visible = false end)

--====================================================================
-- COMPONENTS & UI HELPERS
--====================================================================
local function ClearContent()
    for _, child in ipairs(Content:GetChildren()) do
        if child:IsA("GuiObject") and not child:IsA("UIListLayout") and not child:IsA("UIPadding") then child:Destroy() end
    end
end
local function Section(title) local frame = Create("Frame", { Size = UDim2.new(1, -2, 0, 31), BackgroundColor3 = Config.BlueDark, BorderSizePixel = 0, ZIndex = 3 }, Content); Corner(frame, 6); Label(frame, title:upper(), UDim2.new(1, -16, 1, 0), UDim2.new(0, 10, 0, 0), 11, Config.White).ZIndex = 4; return frame end
local function Description(text) local label = Label(Content, text, UDim2.new(1, -2, 0, 35), UDim2.new(), 10, Config.Gray); label.TextYAlignment = Enum.TextYAlignment.Top; label.ZIndex = 3; return label end

local function ActionRow(title, desc, btnText, callback)
    local row = Create("Frame", { Size = UDim2.new(1, -2, 0, desc and 55 or 42), BackgroundColor3 = Config.Panel, BorderSizePixel = 0, ZIndex = 3 }, Content)
    Corner(row, 7); Stroke(row, Config.Section, 1)
    Label(row, title, UDim2.new(1, -110, 0, 22), UDim2.new(0, 10, 0, desc and 4 or 10), 11, Config.White).ZIndex = 4
    if desc then Label(row, desc, UDim2.new(1, -110, 0, 22), UDim2.new(0, 10, 0, 26), 9, Config.Gray).ZIndex = 4 end
    local act = Button(row, btnText or "EXECUTE", UDim2.new(0, 88, 0, 27), UDim2.new(1, -96, 0.5, -13.5))
    act.ZIndex = 4; act.MouseButton1Click:Connect(function() if callback then callback() end end)
    return row
end

local function ToggleRow(title, default, callback)
    local toggled = default
    local row = Create("Frame", { Size = UDim2.new(1, -2, 0, 42), BackgroundColor3 = Config.Panel, BorderSizePixel = 0, ZIndex = 3 }, Content)
    Corner(row, 7); Stroke(row, Config.Section, 1)
    Label(row, title, UDim2.new(1, -60, 1, 0), UDim2.new(0, 10, 0, 0), 11, Config.White).ZIndex = 4
    local box = Create("Frame", { Size = UDim2.new(0, 38, 0, 20), Position = UDim2.new(1, -48, 0.5, -10), BackgroundColor3 = toggled and Config.Blue or Config.Section, BorderSizePixel = 0, ZIndex = 4 }, row)
    Corner(box, 10)
    local circle = Create("Frame", { Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(0, toggled and 19 or 3, 0.5, -8), BackgroundColor3 = Config.White, BorderSizePixel = 0, ZIndex = 5 }, box)
    Corner(circle, 8)
    local btn = Create("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", ZIndex = 6 }, row)
    btn.MouseButton1Click:Connect(function()
        toggled = not toggled
        TweenService:Create(box, TweenInfo.new(0.15), { BackgroundColor3 = toggled and Config.Blue or Config.Section }):Play()
        TweenService:Create(circle, TweenInfo.new(0.15), { Position = UDim2.new(0, toggled and 19 or 3, 0.5, -8) }):Play()
        if callback then callback(toggled) end
    end)
    return row
end

local function SliderRow(title, min, max, default, callback)
    local val = default
    local row = Create("Frame", { Size = UDim2.new(1, -2, 0, 55), BackgroundColor3 = Config.Panel, BorderSizePixel = 0, ZIndex = 3 }, Content)
    Corner(row, 7); Stroke(row, Config.Section, 1)
    Label(row, title, UDim2.new(1, -70, 0, 22), UDim2.new(0, 10, 0, 5), 11, Config.White).ZIndex = 4

    local valBox = Create("TextBox", { Size = UDim2.new(0, 50, 0, 22), Position = UDim2.new(1, -60, 0, 5), BackgroundColor3 = Config.Section, BorderSizePixel = 0, Font = Enum.Font.GothamBold, Text = tostring(default), TextColor3 = Config.White, TextSize = 11, ZIndex = 4 }, row)
    Corner(valBox, 5)

    local track = Create("Frame", { Size = UDim2.new(1, -20, 0, 6), Position = UDim2.new(0, 10, 0, 37), BackgroundColor3 = Config.Section, BorderSizePixel = 0, ZIndex = 4 }, row)
    Corner(track, 3)
    local fill = Create("Frame", { Size = UDim2.new((default - min)/(max - min), 0, 1, 0), BackgroundColor3 = Config.Blue, BorderSizePixel = 0, ZIndex = 5 }, track)
    Corner(fill, 3)

    local function update(v)
        v = math.clamp(math.round(v), min, max)
        val = v
        valBox.Text = tostring(v)
        fill.Size = UDim2.new((v - min)/(max - min), 0, 1, 0)
        if callback then callback(v) end
    end

    valBox.FocusLost:Connect(function()
        local num = tonumber(valBox.Text)
        if num then update(num) else valBox.Text = tostring(val) end
    end)

    local dragging = false
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local pos = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            update(min + (max - min) * pos)
        end
    end)
    return row
end

local function TeamRow(parent, name, imageId)
    local row = Create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Config.Panel, BorderSizePixel = 0, ZIndex = 3 }, parent)
    Corner(row, 7); Stroke(row, Config.Section, 1)
    Create("ImageLabel", { Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(0, 8, 0.5, -15), BackgroundTransparency = 1, Image = imageId, ScaleType = Enum.ScaleType.Fit, ZIndex = 4 }, row)
    Label(row, name, UDim2.new(1, -45, 1, 0), UDim2.new(0, 45, 0, 0), 12, Config.White, Enum.Font.GothamBold).ZIndex = 4
    return row
end

--====================================================================
-- PAGES (TABS & FEATURES)
--====================================================================
local function BuildHome()
    Section("Welcome to NEOHUB")
    Description("Hi, I'm from Indonesia 🇮🇩 Welcome to NEOHUB Fisch Edition!")
    Section("My Links")
    ActionRow("Discord Community", "Join our Discord server", "COPY", function()
        if setclipboard then setclipboard(Config.DiscordLink); Notify("Copied!", "Discord link copied.") end
    end)
    ActionRow("YouTube Channel", "NEOHUB YouTube Channel", "COPY", function()
        if setclipboard then setclipboard("https://youtube.com/@NEOHUB"); Notify("Copied!", "YouTube link copied.") end
    end)
    Section("Our Team")
    local teamGrid = Create("Frame", { Size = UDim2.new(1, -2, 0, 0), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 3 }, Content)
    Create("UIGridLayout", { CellSize = UDim2.new(0.5, -4, 0, 50), CellPadding = UDim2.new(0, 8, 0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, teamGrid)
    TeamRow(teamGrid, "NEOPARTY", Config.TeamNeoParty)
    TeamRow(teamGrid, "NEOLOW", Config.TeamNeoLow)
    TeamRow(teamGrid, "NEOFLEX", Config.TeamNeoFlex)
    TeamRow(teamGrid, "NEOSHY", Config.TeamNeoShy)
end

local function BuildMain()
    Section("Auto Fishing System")
    ToggleRow("Auto Fishing", FischConfig.Enabled, function(state)
        FischConfig.Enabled = state
        if state then
            Notify("Auto Fishing", "Activated!")
            if not LoopThread or coroutine.status(LoopThread) == "dead" then
                LoopThread = task.spawn(autofishLoop)
            end
        else
            Notify("Auto Fishing", "Deactivated!")
        end
    end)
    ToggleRow("Instant Mode", FischConfig.Instant, function(v) FischConfig.Instant = v end)
    ToggleRow("Perfect Cast", FischConfig.PerfectCast, function(v) FischConfig.PerfectCast = v end)
    SliderRow("Cast Power", 10, 100, FischConfig.Power, function(v) FischConfig.Power = v end)
    SliderRow("Recast Delay", 0, 10, FischConfig.Delay, function(v) FischConfig.Delay = v end)
    ActionRow("Reset Bobber", "Manual reset rod state", "RESET", function()
        if ResetRemote then pcall(function() ResetRemote:FireServer() end); Notify("Reset", "Bobber reset sent.") end
    end)
    Section("Shop & Sell")
    ActionRow("Sell All Fish", "Sell all items in inventory", "SELL", function()
        local ev = ReplicatedStorage:FindFirstChild("events") and ReplicatedStorage.events:FindFirstChild("selleverything")
        if ev then ev:InvokeServer(); Notify("Success", "All fish sold!") end
    end)
    ActionRow("Sell Fish (In Hand)", "Sell fish held by merchant", "SELL", function()
        pcall(function() workspace.world.npcs.Merchant.merchant.sell:InvokeServer() end)
        Notify("Success", "Fish in hand sold!")
    end)
end

local function BuildPlayer()
    Section("Character Settings")
    SliderRow("WalkSpeed", 16, 100, 16, function(v) pcall(function() Player.Character.Humanoid.WalkSpeed = v end) end)
    SliderRow("Super Jump", 50, 100, 50, function(v) pcall(function() Player.Character.Humanoid.JumpPower = v end) end)
    ToggleRow("Infinite Jump", false, function(state)
        getgenv().InfJumpEnabled = state
        if state then
            UserInputService.JumpRequest:Connect(function()
                if getgenv().InfJumpEnabled and Player.Character then
                    Player.Character:FindFirstChildOfClass('Humanoid'):ChangeState("Jumping")
                end
            end)
        end
    end)
    ToggleRow("Anti Void", false, function(state)
        getgenv().AntiVoidEnabled = state
        task.spawn(function()
            local lastPos = Vector3.new(0, 150, 0)
            while getgenv().AntiVoidEnabled do
                task.wait(0.5)
                local char = Player.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    local hrp = char.HumanoidRootPart
                    if hrp.Position.Y > -50 then lastPos = hrp.Position
                    else hrp.CFrame = CFrame.new(lastPos + Vector3.new(0, 10, 0)); Notify("Anti Void", "Saved from void!") end
                end
            end
        end)
    end)
    ToggleRow("Toggle Water Walking", false, function(state) pcall(function() Player.Character.Humanoid.PlatformStand = state end) end)
    ToggleRow("No Clip", false, function(state)
        getgenv().NoClip = state
        RunService.Stepped:Connect(function()
            if getgenv().NoClip and Player.Character then
                for _, v in pairs(Player.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
            end
        end)
    end)
    ToggleRow("Infinite Oxygen", false, function(state) pcall(function() Player.Character.client.oxygen.Disabled = state end) end)
end

local function BuildBoat()
    Section("Boat Control")
    ActionRow("Show UI Buy Boat", "Toggle Shipwright Shop UI", "TOGGLE", function()
        pcall(function() local ui = Player.PlayerGui.hud.safezone.shipwright; ui.Visible = not ui.Visible end)
    end)
    ActionRow("Speed Hack for Boat", "Boost active boat speed", "BOOST", function()
        pcall(function()
            local boat = workspace:FindFirstChild("Boat")
            if boat and boat.PrimaryPart then
                local bv = Instance.new("BodyVelocity", boat.PrimaryPart)
                bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
                bv.Velocity = boat.PrimaryPart.CFrame.LookVector * 260
                game.Debris:AddItem(bv, 5)
                Notify("Speed Hack", "Boat speed boosted!")
            end
        end)
    end)
end

local function BuildWorld()
    Section("Environment & Lighting")
    ToggleRow("Weather Clear", false, function(state) pcall(function() ReplicatedStorage.world.weather.Value = state and 'Clear' or 'Normal' end) end)
    ToggleRow("Day Only", false, function(state)
        getgenv().DayOnly = state
        RunService.Heartbeat:Connect(function() if getgenv().DayOnly then Lighting.TimeOfDay = "12:00:00" end end)
    end)
    ToggleRow("Fullbright", false, function(state)
        Lighting.Brightness = state and 2 or 1
        Lighting.ClockTime = state and 14 or 12
        Lighting.GlobalShadows = not state
    end)
    ActionRow("Remove Fog", "Clear atmosphere fog", "REMOVE", function() pcall(function() Lighting.Sky.Parent = Lighting.bloom or Lighting end) end)
    Section("Server & Performance")
    ToggleRow("Anti AFK", true, function(state) getgenv().AntiAFK = state end)
    task.spawn(function()
        while task.wait(1) do
            if getgenv().AntiAFK then
                pcall(function()
                    local vu = game:GetService("VirtualUser")
                    Player.Idled:Connect(function() vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame); task.wait(1); vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame) end)
                end)
            end
        end
    end)
    ActionRow("FPS Boost", "Optimize rendering", "BOOST", function()
        pcall(function()
            Lighting.GlobalShadows = false
            settings().Rendering.QualityLevel = "Level01"
            for _, v in pairs(workspace:GetDescendants()) do if v:IsA("BasePart") then v.Material = "Plastic"; v.Reflectance = 0 end end
        end)
    end)
    ActionRow("Rejoin Server", "Reconnect", "REJOIN", function() game:GetService("TeleportService"):Teleport(game.PlaceId, Player) end)
    ActionRow("Server Hop", "Jump to another public server", "HOP", function()
        local servers = game.HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/'..game.PlaceId..'/servers/Public?sortOrder=Asc&limit=100'))
        for _, s in ipairs(servers.data) do
            if s.playing < s.maxPlayers and s.id ~= game.JobId then
                game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, s.id, Player)
                break
            end
        end
    end)
end

local function BuildTeleport()
    Section("Fisch Island Teleports")
    local locations = {
        {"Sunstone Island", Vector3.new(-913.63, 137.29, -1129.90)},
        {"Roslit Bay", Vector3.new(-1501.68, 133, 416.21)},
        {"Moosewood", Vector3.new(433.80, 147.07, 261.80)},
        {"Enchant Room", Vector3.new(1310.05, -805.29, -162.35)},
        {"Mushgrove Swamp", Vector3.new(2442.81, 130.90, -686.16)},
        {"Snowcap Island", Vector3.new(2589.53, 134.92, 2333.10)},
        {"Terrapin Island", Vector3.new(152.37, 154.91, 2000.92)},
        {"Best Spot (Secret)", Vector3.new(1447.85, 133.50, -7649.65)},
    }
    for _, loc in ipairs(locations) do
        ActionRow(loc[1], "Teleport instantly", "GO", function()
            pcall(function() Player.Character.HumanoidRootPart.CFrame = CFrame.new(loc[2]) end)
            Notify("Teleport", "Moved to " .. loc[1])
        end)
    end
end

local function BuildMisc()
    Section("Utilities & Bypass")
    ActionRow("Bypass Radar", "Toggle radar tags", "TOGGLE", function()
        for _, v in pairs(game:GetService("CollectionService"):GetTagged("radarTag")) do if v:IsA("BillboardGui") then v.Enabled = not v.Enabled end end
    end)
    ActionRow("Bypass Sell All", "Unlock sell all gamepass", "UNLOCK", function()
        pcall(function() Player.PlayerGui.hud.safezone.backpack.inventory.Sell.sellall.Disabled = true end)
        Notify("Bypass", "Sell All unlocked!")
    end)
end

local function BuildCredits()
    Section("Join Our Community 💙")
    Description("Hello NEOHUB users 😁! Don't forget to join our Discord.")
    Section("Developed By")
    Description("NEOPARTY | NEOLOW | NEOFLEX | NEOSHY", Config.White)
    Section("⚠️ DISCLAIMER ⚠️")
    local disclaimer = Label(Content, "This script is made by NEOPARTY. If anyone steals the UI or Features, they will be prosecuted.", UDim2.new(1, -2, 0, 60), UDim2.new(), 10, Config.Red)
    disclaimer.TextYAlignment = Enum.TextYAlignment.Top; disclaimer.Font = Enum.Font.GothamBold; disclaimer.TextWrapped = true; disclaimer.ZIndex = 3
end

local PageBuilders = {
    Home = BuildHome,
    Main = BuildMain,
    Player = BuildPlayer,
    Boat = BuildBoat,
    World = BuildWorld,
    Teleport = BuildTeleport,
    Misc = BuildMisc,
    Credits = BuildCredits,
}
local TabNames = { "Home", "Main", "Player", "Boat", "World", "Teleport", "Misc", "Credits" }

local function SelectTab(tabName)
    ClearContent()
    for _, button in ipairs(TabButtons:GetChildren()) do
        if button:IsA("TextButton") then
            local active = button.Name == tabName
            button.BackgroundColor3 = active and Config.BlueDark or Config.Section
            button.TextColor3 = active and Config.White or Config.Gray
        end
    end
    if PageBuilders[tabName] then PageBuilders[tabName]() end
    Content.CanvasPosition = Vector2.new(0, 0)
end

for index, tabName in ipairs(TabNames) do
    local tabButton = Create("TextButton", { Name = tabName, Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = Config.Section, BorderSizePixel = 0, AutoButtonColor = false, Font = Enum.Font.GothamSemibold, Text = "   " .. tabName, TextColor3 = Config.Gray, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = index, ZIndex = 3 }, TabButtons)
    Corner(tabButton, 5)
    tabButton.MouseButton1Click:Connect(function() SelectTab(tabName) end)
end

--====================================================================
-- CINEMATIC INTRO
--====================================================================
local IntroGui = Create("ScreenGui", { Name = "NEOHUB_Intro", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 999 }, PlayerGui)
local Loading = Create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Config.Background, BorderSizePixel = 0, ZIndex = 1 }, IntroGui)

local LoadingLogo = Create("ImageLabel", { Size = UDim2.new(0, 88, 0, 88), Position = UDim2.new(0.5, -44, 0.5, -105), BackgroundTransparency = 1, Image = Config.Logo, ScaleType = Enum.ScaleType.Fit, ZIndex = 2 }, Loading)
Label(Loading, "NEOHUB", UDim2.new(0, 280, 0, 40), UDim2.new(0.5, -140, 0.5, -8), 27, Config.Blue).ZIndex = 2
Label(Loading, "INITIALIZING FISCH...", UDim2.new(0, 280, 0, 25), UDim2.new(0.5, -140, 0.5, 32), 11, Config.Gray).ZIndex = 2

local LoadingTrack = Create("Frame", { Size = UDim2.new(0, 250, 0, 5), Position = UDim2.new(0.5, -125, 0.5, 65), BackgroundColor3 = Config.Section, BorderSizePixel = 0, ZIndex = 3 }, Loading)
Corner(LoadingTrack, 5)
local LoadingBar = Create("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Config.Blue, BorderSizePixel = 0, ZIndex = 4 }, LoadingTrack)
Corner(LoadingBar, 5)
local LoadingPercent = Label(Loading, "0%", UDim2.new(0, 100, 0, 22), UDim2.new(0.5, -50, 0.5, 78), 10, Config.Gray)
LoadingPercent.TextXAlignment = Enum.TextXAlignment.Center; LoadingPercent.ZIndex = 3

local popupFrame = Create("Frame", { Size = UDim2.fromScale(0.45, 0.4), Position = UDim2.new(0.5, 0, -1, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Config.Panel, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 10 }, IntroGui)
Corner(popupFrame, 12)
local popupStroke = Stroke(popupFrame, Config.Blue, 2); popupStroke.Transparency = 1
local welcomeText = Create("TextLabel", { Size = UDim2.new(1, -30, 0, 40), Position = UDim2.new(0, 15, 0, 18), BackgroundTransparency = 1, Text = "WELCOME TO NEOHUB", TextColor3 = Config.White, Font = Enum.Font.GothamBlack, TextSize = 24, TextTransparency = 1, ZIndex = 11 }, popupFrame)
local runButton = Create("TextButton", { Size = UDim2.new(1, -30, 0, 40), Position = UDim2.new(0, 15, 1, -55), BackgroundColor3 = Config.Blue, BorderSizePixel = 0, AutoButtonColor = false, Font = Enum.Font.Gotham, Text = "⚡ RUN SCRIPT", TextColor3 = Config.White, TextSize = 14, TextTransparency = 1, ZIndex = 11 }, popupFrame)
Corner(runButton, 8)
local slashSound = Create("Sound", { SoundId = Config.SlashSFX, Volume = 1 }, SoundService)

local function tw(obj, time, props, style, dir) 
    local t = TweenService:Create(obj, TweenInfo.new(time, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
    t:Play()
    return t 
end

task.spawn(function()
    for progress = 0, 100, 5 do
        LoadingBar:TweenSize(UDim2.new(progress / 100, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.08, true)
        LoadingPercent.Text = progress .. "%"
        task.wait(0.05)
    end
    task.wait(0.3)

    tw(LoadingLogo, 0.4, { ImageTransparency = 1 })
    tw(LoadingTrack, 0.4, { BackgroundTransparency = 1 })
    tw(LoadingBar, 0.4, { BackgroundTransparency = 1 })
    tw(LoadingPercent, 0.4, { TextTransparency = 1 })
    for _, v in ipairs(Loading:GetChildren()) do if v:IsA("TextLabel") then tw(v, 0.4, { TextTransparency = 1 }) end end
    task.wait(0.3)

    slashSound:Play()
    task.wait(0.2)

    tw(popupFrame, 0.8, { Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 0 }, Enum.EasingStyle.Back)
    tw(popupStroke, 0.8, { Transparency = 0 })
    task.wait(0.3)
    tw(welcomeText, 0.4, { TextTransparency = 0 })
    task.wait(0.15)
    tw(runButton, 0.4, { TextTransparency = 0 })

    runButton.MouseButton1Click:Wait()
    
    tw(runButton, 0.15, { BackgroundColor3 = Color3.fromRGB(0, 255, 150) })
    tw(popupFrame, 0.25, { Position = UDim2.new(0.5, 0, 1.5, 0), BackgroundTransparency = 1 })
    tw(popupStroke, 0.25, { Transparency = 1 })
    tw(welcomeText, 0.2, { TextTransparency = 1 })
    tw(runButton, 0.2, { TextTransparency = 1 })
    task.wait(0.4)

    Main.Visible = true
    SelectTab("Home")
    tw(Loading, 0.5, { BackgroundTransparency = 1 })
    task.wait(0.6)

    IntroGui:Destroy()
    Notify("NEOHUB", "Fisch Edition Loaded Successfully! 🚀")
end)
