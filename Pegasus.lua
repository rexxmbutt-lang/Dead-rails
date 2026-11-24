-- Pegasus Hub | Dead Rails
-- Developer: rexx script
-- Library  : https://raw.githubusercontent.com/rexxmbutt-lang/Libraary-script-roblox/refs/heads/main/library.luau

-- ── Load Library (Notify only) ───────────────────────
local Lib = nil
pcall(function()
    Lib = loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/rexxmbutt-lang/Libraary-script-roblox/refs/heads/main/library.luau"
    ))()
end)

-- ── Services ─────────────────────────────────────────
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Workspace        = game:GetService("Workspace")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local CollectionService= game:GetService("CollectionService")

local lp   = Players.LocalPlayer
local char = lp.Character or lp.CharacterAdded:Wait()
local hum  = char:WaitForChild("Humanoid")
local hrp  = char:WaitForChild("HumanoidRootPart")

lp.CharacterAdded:Connect(function(c)
    char = c
    hum  = c:WaitForChild("Humanoid")
    hrp  = c:WaitForChild("HumanoidRootPart")
end)

-- ── Notify wrapper ────────────────────────────────────
local function Notify(msg, dur)
    if Lib and type(Lib) == "table" and Lib.Notify then
        pcall(function() Lib:Notify({ Title = "Pegasus Hub", Content = msg, Duration = dur or 3 }) end)
    end
end

-- ── Flags ─────────────────────────────────────────────
local F = {
    AutoBonds   = false,
    BringItems  = false,
    AutoEscape  = false,
    AutoDrive   = false,
    SpeedBoost  = false,
    Fly         = false,
    ESPBonds    = false,
    ESPZombie   = false,
    ESPWerewolf = false,
    ESPCowboy   = false,
}

local DEFAULT_SPEED = 16
local BOOST_SPEED   = 80
local FLY_SPEED     = 60

-- ═══════════════════════════════════════════════════
--  HELPERS
-- ═══════════════════════════════════════════════════
local function allDesc()
    local ok, r = pcall(function() return Workspace:GetDescendants() end)
    return ok and r or {}
end

local function allChildren()
    local ok, r = pcall(function() return Workspace:GetChildren() end)
    return ok and r or {}
end

-- Dead Rails: bonds = collectible currency items
-- Name patterns from actual game inspection
local BOND_PATTERNS = {
    "bond", "gold", "coin", "cash", "dollar", "money",
    "currency", "treasure", "reward", "loot", "pick",
    "collect", "pickup"
}
local ZOMBIE_PATTERNS  = { "zombie", "undead", "walker", "infected", "dead" }
local WOLF_PATTERNS    = { "werewolf", "wolf", "lycan" }
local COWBOY_PATTERNS  = { "cowboy", "outlaw", "bandit", "gunslinger", "sheriff", "ranger", "desperado" }

local function matchAny(name, patterns)
    local low = name:lower()
    for _, p in ipairs(patterns) do
        if low:find(p, 1, true) then return true end
    end
    return false
end

-- ═══════════════════════════════════════════════════
--  FEATURES
-- ═══════════════════════════════════════════════════

-- AUTO BONDS
-- Dead Rails bonds are BaseParts or Models tagged/named as collectibles
-- Method: teleport to them (they auto-collect on touch), return
local bondConn = nil
local function startBonds()
    if bondConn then bondConn:Disconnect() end
    bondConn = RunService.Heartbeat:Connect(function()
        if not F.AutoBonds then bondConn:Disconnect() bondConn = nil return end
        local origin = hrp.CFrame
        for _, v in ipairs(allDesc()) do
            if matchAny(v.Name, BOND_PATTERNS) then
                local part = nil
                if v:IsA("BasePart") then
                    part = v
                elseif v:IsA("Model") and v.PrimaryPart then
                    part = v.PrimaryPart
                end
                if part and part.Parent then
                    -- Also try firing collect remotes if they exist on the part
                    for _, child in ipairs(part:GetChildren()) do
                        if child:IsA("RemoteEvent") then
                            pcall(function() child:FireServer() end)
                        end
                    end
                    pcall(function()
                        hrp.CFrame = CFrame.new(part.Position + Vector3.new(0, 2, 0))
                    end)
                    task.wait(0.05)
                end
            end
        end
        -- Also check for ClickDetectors / ProximityPrompts on collectibles
        for _, v in ipairs(allDesc()) do
            if v:IsA("ProximityPrompt") and matchAny(v.Parent.Name or "", BOND_PATTERNS) then
                pcall(function()
                    hrp.CFrame = CFrame.new(v.Parent.Position + Vector3.new(0, 2, 0))
                    task.wait(0.05)
                    -- fire the prompt trigger
                    local fe = v.Parent:FindFirstChild("Triggered")
                        or v.Parent:FindFirstChildOfClass("RemoteEvent")
                    if fe then pcall(function() fe:FireServer() end) end
                end)
            end
        end
    end)
end

-- BRING ALL ITEMS
-- Bring loose BaseParts that are unanchored/no-collide to player
local function tickBring()
    if not F.BringItems then return end
    for _, v in ipairs(allDesc()) do
        if v:IsA("BasePart") and not v.Anchored then
            pcall(function()
                v.CFrame = CFrame.new(
                    hrp.Position + Vector3.new(math.random(-2,2), 0.5, math.random(-2,2))
                )
            end)
        end
    end
end

-- AUTO ESCAPE
-- Dead Rails: win by escaping on the train. Fire every possible win remote.
local WIN_REMOTES = {
    "EscapeGame","WinGame","TrainEscaped","Escaped","Victory",
    "FinishGame","GameWin","CompleteGame","TrainLeft","TrainDepart",
    "PlayerEscaped","Survive","GameOver","EndGame","Win",
    "EscapeSuccessful","BoardTrain","TrainDeparted","Escape"
}
local function doEscape()
    -- Search all services for remotes
    for _, service in ipairs({ ReplicatedStorage, Workspace }) do
        for _, v in ipairs(service:GetDescendants()) do
            local n = v.Name
            for _, rn in ipairs(WIN_REMOTES) do
                if n == rn or n:lower() == rn:lower() then
                    if v:IsA("RemoteEvent") then
                        pcall(function() v:FireServer() end)
                    elseif v:IsA("RemoteFunction") then
                        pcall(function() v:InvokeServer() end)
                    end
                end
            end
        end
    end
    -- Also try to teleport player into the train trigger zone
    -- Dead Rails escape zone is usually at one end of the map near train
    for _, v in ipairs(allDesc()) do
        local n = v.Name:lower()
        if n:find("escape") or n:find("finish") or n:find("exit") or n:find("win") then
            if v:IsA("BasePart") then
                pcall(function() hrp.CFrame = CFrame.new(v.Position + Vector3.new(0, 3, 0)) end)
                task.wait(0.1)
            end
        end
    end
    F.AutoEscape = false
end

-- AUTO DRIVE
-- Find train VehicleSeat and sit, lock throttle
local driveConn = nil
local function startDrive()
    local seatNames = { "driver", "cabin", "front", "engineer", "control", "seat", "helm" }
    for _, v in ipairs(allDesc()) do
        if v:IsA("VehicleSeat") or v:IsA("Seat") then
            local n = v.Name:lower()
            local match = false
            for _, sn in ipairs(seatNames) do
                if n:find(sn) then match = true break end
            end
            if match then
                pcall(function() v:Sit(hum) end)
                if v:IsA("VehicleSeat") then
                    if driveConn then driveConn:Disconnect() end
                    driveConn = RunService.Heartbeat:Connect(function()
                        if not F.AutoDrive then
                            driveConn:Disconnect() driveConn = nil return
                        end
                        pcall(function()
                            v.Throttle = 1
                            v.Steer    = 0
                        end)
                    end)
                end
                return
            end
        end
    end
    -- Fallback: sit in any VehicleSeat in workspace
    for _, v in ipairs(allDesc()) do
        if v:IsA("VehicleSeat") then
            pcall(function() v:Sit(hum) end)
            if driveConn then driveConn:Disconnect() end
            driveConn = RunService.Heartbeat:Connect(function()
                if not F.AutoDrive then driveConn:Disconnect() driveConn = nil return end
                pcall(function() v.Throttle = 1 v.Steer = 0 end)
            end)
            return
        end
    end
end

-- SPEED
local function applySpeed()
    pcall(function()
        hum.WalkSpeed = F.SpeedBoost and BOOST_SPEED or DEFAULT_SPEED
    end)
end

-- FLY
local flyBV, flyBG, flyConn = nil, nil, nil
local function startFly()
    if flyBV then return end
    flyBV = Instance.new("BodyVelocity")
    flyBV.Velocity  = Vector3.zero
    flyBV.MaxForce  = Vector3.new(1e6, 1e6, 1e6)
    flyBV.Parent    = hrp
    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    flyBG.D         = 100
    flyBG.Parent    = hrp
    flyConn = RunService.RenderStepped:Connect(function()
        if not F.Fly then
            if flyBV then flyBV:Destroy() flyBV = nil end
            if flyBG then flyBG:Destroy() flyBG = nil end
            flyConn:Disconnect() flyConn = nil
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
            return
        end
        local cam = Workspace.CurrentCamera
        local mv  = Vector3.zero
        local uis = UserInputService
        if uis:IsKeyDown(Enum.KeyCode.W) then mv += cam.CFrame.LookVector  end
        if uis:IsKeyDown(Enum.KeyCode.S) then mv -= cam.CFrame.LookVector  end
        if uis:IsKeyDown(Enum.KeyCode.A) then mv -= cam.CFrame.RightVector end
        if uis:IsKeyDown(Enum.KeyCode.D) then mv += cam.CFrame.RightVector end
        if uis:IsKeyDown(Enum.KeyCode.Space)       then mv += Vector3.yAxis end
        if uis:IsKeyDown(Enum.KeyCode.LeftControl) then mv -= Vector3.yAxis end
        flyBV.Velocity = mv.Magnitude > 0 and mv.Unit * FLY_SPEED or Vector3.zero
        flyBG.CFrame   = cam.CFrame
        hum:ChangeState(Enum.HumanoidStateType.Physics)
    end)
end

-- ═══════════════════════════════════════════════════
--  ESP — DrawingLib box merah
-- ═══════════════════════════════════════════════════
local espData = {}

local function espTag(v)
    local n = v.Name:lower()
    if F.ESPBonds    and matchAny(n, BOND_PATTERNS)    then return "BOND"     end
    if F.ESPZombie   and matchAny(n, ZOMBIE_PATTERNS)  then return "ZOMBIE"   end
    if F.ESPWerewolf and matchAny(n, WOLF_PATTERNS)    then return "WEREWOLF" end
    if F.ESPCowboy   and matchAny(n, COWBOY_PATTERNS)  then return "COWBOY"   end
    return nil
end

local ESP_COLOR = Color3.fromRGB(255, 0, 0)

local function newBox()
    local t = {}
    for i = 1, 4 do
        local l = Drawing.new("Line")
        l.Color     = ESP_COLOR
        l.Thickness = 1.5
        l.Visible   = false
        t[i] = l
    end
    return t
end
local function newLbl()
    local l = Drawing.new("Text")
    l.Color   = ESP_COLOR
    l.Size    = 13
    l.Outline = true
    l.Visible = false
    return l
end
local function destroyEntry(e)
    if not e then return end
    for _, l in ipairs(e.box) do pcall(function() l:Remove() end) end
    if e.lbl then pcall(function() e.lbl:Remove() end) end
end
local function w2s(pos)
    local sp, vis = Workspace.CurrentCamera:WorldToViewportPoint(pos)
    return Vector2.new(sp.X, sp.Y), sp.Z > 0 and vis
end
local function drawBox(lines, tl, br)
    local x0,y0,x1,y1 = tl.X,tl.Y,br.X,br.Y
    lines[1].From=Vector2.new(x0,y0) lines[1].To=Vector2.new(x1,y0)
    lines[2].From=Vector2.new(x0,y1) lines[2].To=Vector2.new(x1,y1)
    lines[3].From=Vector2.new(x0,y0) lines[3].To=Vector2.new(x0,y1)
    lines[4].From=Vector2.new(x1,y0) lines[4].To=Vector2.new(x1,y1)
    for _, l in ipairs(lines) do l.Visible = true end
end
local function hideBox(lines)
    for _, l in ipairs(lines) do l.Visible = false end
end

RunService.RenderStepped:Connect(function()
    local anyESP = F.ESPBonds or F.ESPZombie or F.ESPWerewolf or F.ESPCowboy
    for mdl, e in pairs(espData) do
        if not mdl or not mdl.Parent then destroyEntry(e) espData[mdl] = nil end
    end
    if not anyESP then
        for m, e in pairs(espData) do destroyEntry(e) espData[m] = nil end
        return
    end
    local seen = {}
    for _, v in ipairs(allDesc()) do
        local tag = espTag(v)
        if tag then
            local mdl = (v:IsA("Model") and v)
                or (v.Parent and v.Parent:IsA("Model") and v.Parent)
                or (v:IsA("BasePart") and v)
            if mdl and not seen[mdl] then
                seen[mdl] = true
                if not espData[mdl] then espData[mdl] = { box = newBox(), lbl = newLbl() } end
                local e = espData[mdl]
                local ok, bbcf, bbs
                if mdl:IsA("Model") then
                    ok, bbcf, bbs = pcall(function() return mdl:GetBoundingBox() end)
                else
                    ok = true
                    bbcf = mdl.CFrame
                    bbs  = mdl.Size
                end
                if ok and bbcf and bbs then
                    local top    = bbcf.Position + Vector3.new(0, bbs.Y/2, 0)
                    local bottom = bbcf.Position - Vector3.new(0, bbs.Y/2, 0)
                    local tsp, tv = w2s(top)
                    local bsp, bv = w2s(bottom)
                    if tv or bv then
                        local h  = math.abs(tsp.Y - bsp.Y)
                        local w  = math.max(h * 0.5, 20)
                        local tl = Vector2.new(tsp.X - w/2, math.min(tsp.Y, bsp.Y))
                        drawBox(e.box, tl, tl + Vector2.new(w, h))
                        local dist = math.floor((bbcf.Position - hrp.Position).Magnitude)
                        e.lbl.Text     = string.format("[%s] %s | %dm", tag, mdl.Name, dist)
                        e.lbl.Position = Vector2.new(tl.X, tl.Y - 16)
                        e.lbl.Visible  = true
                    else
                        hideBox(e.box) e.lbl.Visible = false
                    end
                else
                    hideBox(e.box) e.lbl.Visible = false
                end
            end
        end
    end
    for m, e in pairs(espData) do
        if not seen[m] then hideBox(e.box) e.lbl.Visible = false end
    end
end)

-- Main loop
task.spawn(function()
    while task.wait(0.4) do
        if F.BringItems  then pcall(tickBring) end
        if F.AutoEscape  then pcall(doEscape)  end
    end
end)

-- Start bonds loop on toggle
-- (started/stopped via toggle callback, not loop)

-- ═══════════════════════════════════════════════════
--  UI — 100% Instance.new, library Notify only
--  Zero emoji, zero _Custom access
-- ═══════════════════════════════════════════════════
local function getGui()
    if gethui then local ok,r=pcall(gethui) if ok and r then return r end end
    if cloneref then
        local ok,r=pcall(function() return cloneref(game:GetService("CoreGui")) end)
        if ok and r then return r end
    end
    return game:GetService("CoreGui")
end

-- Palette
local C = {
    BG      = Color3.fromRGB(8, 8, 10),
    Panel   = Color3.fromRGB(14, 14, 18),
    Field   = Color3.fromRGB(20, 20, 26),
    Hover   = Color3.fromRGB(28, 28, 36),
    Text    = Color3.fromRGB(240, 240, 245),
    Sub     = Color3.fromRGB(130, 130, 145),
    Border  = Color3.fromRGB(50, 50, 65),
    TglOn   = Color3.fromRGB(68, 190, 110),
    TglOff  = Color3.fromRGB(40, 40, 52),
    White   = Color3.fromRGB(255, 255, 255),
    Discord = Color3.fromRGB(88, 101, 242),
    DiscHov = Color3.fromRGB(108, 121, 255),
    TabAct  = Color3.fromRGB(240, 240, 245),
    TabInact= Color3.fromRGB(90, 90, 110),
}

local function N(cls, props, parent)
    local i = Instance.new(cls)
    for k, v in pairs(props) do pcall(function() i[k] = v end) end
    if parent then i.Parent = parent end
    return i
end
local function corner(inst, r)
    return N("UICorner", { CornerRadius = UDim.new(0, r or 8) }, inst)
end
local function stroke(inst, col, trans, thick)
    return N("UIStroke", {
        Color = col or C.Border,
        Transparency = trans or 0.5,
        Thickness = thick or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, inst)
end
local function tw(obj, t, props)
    TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quad), props):Play()
end

-- Root
local SG = N("ScreenGui", {
    Name = "PegasusHub",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 999,
}, getGui())

-- Window
local W, H = 395, 505
local Win = N("Frame", {
    Name = "Window",
    Size = UDim2.new(0, W, 0, H),
    Position = UDim2.new(0.5, -W/2, 0.5, -H/2),
    BackgroundColor3 = C.BG,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, SG)
corner(Win, 10)
stroke(Win, C.Border, 0.35, 1)

-- Drag
do
    local drag, dm, dp = false, nil, nil
    Win.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            drag = true dm = inp.Position dp = Win.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not drag then return end
        if inp.UserInputType == Enum.UserInputType.MouseMovement
        or inp.UserInputType == Enum.UserInputType.Touch then
            local d = inp.Position - dm
            Win.Position = UDim2.new(dp.X.Scale, dp.X.Offset+d.X, dp.Y.Scale, dp.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then drag = false end
    end)
end

-- Titlebar
local TB = N("Frame", {
    Size = UDim2.new(1, 0, 0, 48),
    BackgroundColor3 = C.Panel,
    BorderSizePixel = 0, ZIndex = 2,
}, Win)
corner(TB, 10)
N("Frame", {
    Size = UDim2.new(1, 0, 0, 10), Position = UDim2.new(0, 0, 1, -10),
    BackgroundColor3 = C.Panel, BorderSizePixel = 0, ZIndex = 2,
}, TB)
N("TextLabel", {
    Size = UDim2.new(1, -50, 0, 24), Position = UDim2.new(0, 14, 0, 7),
    BackgroundTransparency = 1, Text = "Pegasus Hub",
    TextSize = 14, Font = Enum.Font.GothamBold, TextColor3 = C.Text,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3,
}, TB)
N("TextLabel", {
    Size = UDim2.new(1, -50, 0, 16), Position = UDim2.new(0, 14, 0, 29),
    BackgroundTransparency = 1, Text = "Dead Rails  |  rexx script",
    TextSize = 10, Font = Enum.Font.Gotham, TextColor3 = C.Sub,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3,
}, TB)

-- Close button
local CloseB = N("TextButton", {
    Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -34, 0.5, -12),
    BackgroundColor3 = Color3.fromRGB(55, 28, 28),
    Text = "x", TextSize = 11, TextColor3 = Color3.fromRGB(220, 90, 90),
    Font = Enum.Font.GothamBold, AutoButtonColor = false,
    BorderSizePixel = 0, ZIndex = 4,
}, TB)
corner(CloseB, 5)
CloseB.MouseButton1Click:Connect(function()
    tw(Win, 0.18, { Size = UDim2.new(0, W, 0, 0) })
    task.wait(0.2) SG:Destroy()
end)

-- Tab bar
local TabBar = N("Frame", {
    Size = UDim2.new(1, 0, 0, 34), Position = UDim2.new(0, 0, 0, 48),
    BackgroundColor3 = C.Panel, BorderSizePixel = 0, ZIndex = 2,
}, Win)
N("Frame", {
    Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1),
    BackgroundColor3 = C.Border, BorderSizePixel = 0, ZIndex = 3,
}, TabBar)
N("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 2),
    VerticalAlignment = Enum.VerticalAlignment.Center,
}, TabBar)
N("UIPadding", { PaddingLeft = UDim.new(0, 8) }, TabBar)

-- Content
local ContentArea = N("Frame", {
    Size = UDim2.new(1, 0, 1, -82), Position = UDim2.new(0, 0, 0, 82),
    BackgroundTransparency = 1, ClipsDescendants = true,
}, Win)

-- ── Tab system ───────────────────────────────────────
local tabList   = {}
local activeTab = nil

local function makeTab(name)
    local btn = N("TextButton", {
        Size = UDim2.new(0, 0, 1, -6), AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = C.Panel, BackgroundTransparency = 1,
        Text = name, TextSize = 11, TextColor3 = C.TabInact,
        Font = Enum.Font.GothamBold, AutoButtonColor = false,
        BorderSizePixel = 0, ZIndex = 3, LayoutOrder = #tabList + 1,
    }, TabBar)
    N("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, btn)
    corner(btn, 6)

    local line = N("Frame", {
        Size = UDim2.new(0.7, 0, 0, 2), Position = UDim2.new(0.15, 0, 1, -2),
        BackgroundColor3 = C.TglOn, BorderSizePixel = 0,
        Visible = false, ZIndex = 4,
    }, btn)
    corner(line, 1)

    local scroll = N("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
        ScrollBarThickness = 3, ScrollBarImageColor3 = C.Border,
        CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false, BorderSizePixel = 0, ZIndex = 2,
    }, ContentArea)
    N("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5) }, scroll)
    N("UIPadding", {
        PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
        PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 14),
    }, scroll)

    local tab = { btn = btn, scroll = scroll, line = line }
    table.insert(tabList, tab)

    local function activate()
        if activeTab then
            activeTab.scroll.Visible = false
            activeTab.line.Visible   = false
            tw(activeTab.btn, 0.12, { TextColor3 = C.TabInact, BackgroundTransparency = 1 })
        end
        activeTab      = tab
        scroll.Visible = true
        line.Visible   = true
        tw(btn, 0.12, { TextColor3 = C.TabAct, BackgroundTransparency = 0.75 })
    end

    btn.MouseButton1Click:Connect(activate)
    if #tabList == 1 then activate() end
    return scroll
end

-- ── Control widgets ──────────────────────────────────
local rowOrder = 0
local function nextOrd() rowOrder += 1 return rowOrder end

local function makeRow(parent, h)
    local f = N("Frame", {
        Size = UDim2.new(1, 0, 0, h or 38),
        BackgroundColor3 = C.Field, BorderSizePixel = 0,
        ZIndex = 3, LayoutOrder = nextOrd(),
    }, parent)
    corner(f, 7)
    stroke(f, C.Border, 0.65, 1)
    return f
end

local function makeSec(parent, text)
    N("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1,
        Text = text:upper(), TextSize = 9, Font = Enum.Font.GothamBold,
        TextColor3 = C.Sub, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 3, LayoutOrder = nextOrd(),
    }, parent)
end

local function makeSpacer(parent, h)
    N("Frame", { Size = UDim2.new(1, 0, 0, h or 6), BackgroundTransparency = 1, LayoutOrder = nextOrd() }, parent)
end

local function makeToggle(parent, name, default, onChange)
    local row   = makeRow(parent)
    local state = default or false

    N("TextLabel", {
        Size = UDim2.new(1, -58, 1, 0), Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1, Text = name, TextSize = 12,
        Font = Enum.Font.GothamBold, TextColor3 = C.Text,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4,
    }, row)

    local pill = N("Frame", {
        Size = UDim2.new(0, 38, 0, 20), Position = UDim2.new(1, -50, 0.5, -10),
        BackgroundColor3 = state and C.TglOn or C.TglOff,
        BorderSizePixel = 0, ZIndex = 4,
    }, row)
    corner(pill, 10)

    local dot = N("Frame", {
        Size = UDim2.new(0, 14, 0, 14),
        Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
        BackgroundColor3 = C.White, BorderSizePixel = 0, ZIndex = 5,
    }, pill)
    corner(dot, 7)

    local hbx = N("TextButton", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
        Text = "", AutoButtonColor = false, ZIndex = 6,
    }, row)
    hbx.MouseButton1Click:Connect(function()
        state = not state
        tw(pill, 0.14, { BackgroundColor3 = state and C.TglOn or C.TglOff })
        tw(dot,  0.14, { Position = state and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7) })
        onChange(state)
    end)
    hbx.MouseEnter:Connect(function() tw(row, 0.1, { BackgroundColor3 = C.Hover }) end)
    hbx.MouseLeave:Connect(function() tw(row, 0.1, { BackgroundColor3 = C.Field }) end)
end

local function makeButton(parent, name, onClick)
    local row = makeRow(parent)
    row.BackgroundColor3 = C.Panel
    N("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
        Text = name, TextSize = 12, Font = Enum.Font.GothamBold,
        TextColor3 = C.Text, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 4,
    }, row)
    local hbx = N("TextButton", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
        Text = "", AutoButtonColor = false, ZIndex = 5,
    }, row)
    hbx.MouseButton1Click:Connect(onClick)
    hbx.MouseEnter:Connect(function() tw(row, 0.1, { BackgroundColor3 = C.Hover }) end)
    hbx.MouseLeave:Connect(function() tw(row, 0.1, { BackgroundColor3 = C.Panel }) end)
end

local function makeLbl(parent, text)
    N("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1,
        Text = text, TextSize = 11, Font = Enum.Font.Gotham,
        TextColor3 = C.Sub, TextXAlignment = Enum.TextXAlignment.Center,
        TextWrapped = true, ZIndex = 3, LayoutOrder = nextOrd(),
    }, parent)
end

-- ═══════════════════════════════════════════════════
--  TABS
-- ═══════════════════════════════════════════════════
local mainScroll = makeTab("MAIN")

makeSec(mainScroll, "Currency")
makeToggle(mainScroll, "Auto Bonds", false, function(s)
    F.AutoBonds = s
    if s then startBonds() end
    Notify("Auto Bonds: " .. (s and "ON" or "OFF"))
end)

makeSec(mainScroll, "Items")
makeToggle(mainScroll, "Bring All Item", false, function(s)
    F.BringItems = s
    Notify("Bring All Item: " .. (s and "ON" or "OFF"))
end)

makeSec(mainScroll, "Game")
makeButton(mainScroll, "Auto Escape  (WIN)", function()
    F.AutoEscape = true
    task.spawn(doEscape)
    Notify("Auto Escape fired!")
end)

makeButton(mainScroll, "Auto Drive  (Toggle)", function()
    F.AutoDrive = not F.AutoDrive
    if F.AutoDrive then
        task.spawn(startDrive)
        Notify("Auto Drive: ON")
    else
        if driveConn then driveConn:Disconnect() driveConn = nil end
        Notify("Auto Drive: OFF")
    end
end)

makeSec(mainScroll, "Movement")
makeToggle(mainScroll, "Speed Boost  [WASD]", false, function(s)
    F.SpeedBoost = s
    applySpeed()
    Notify("Speed Boost: " .. (s and "ON" or "OFF"))
end)

makeToggle(mainScroll, "Fly  [WASD + Space/Ctrl]", false, function(s)
    F.Fly = s
    if s then startFly() end
    Notify("Fly: " .. (s and "ON" or "OFF"))
end)

-- ESP tab
rowOrder = 0
local espScroll = makeTab("ESP")

makeSec(espScroll, "Box ESP  Merah")
makeToggle(espScroll, "ESP Bonds", false, function(s)
    F.ESPBonds = s
    Notify("ESP Bonds: " .. (s and "ON" or "OFF"))
end)
makeToggle(espScroll, "ESP Zombie", false, function(s)
    F.ESPZombie = s
    Notify("ESP Zombie: " .. (s and "ON" or "OFF"))
end)
makeToggle(espScroll, "ESP Werewolf", false, function(s)
    F.ESPWerewolf = s
    Notify("ESP Werewolf: " .. (s and "ON" or "OFF"))
end)
makeToggle(espScroll, "ESP Cowboy", false, function(s)
    F.ESPCowboy = s
    Notify("ESP Cowboy: " .. (s and "ON" or "OFF"))
end)

-- Dev tab
rowOrder = 0
local devScroll = makeTab("DEV")

makeSpacer(devScroll, 10)
makeLbl(devScroll, "hello guys")
makeLbl(devScroll, "My name is rexx")
makeLbl(devScroll, "And me the developer this script")
makeSpacer(devScroll, 6)
makeLbl(devScroll, "Join my discord server to get")
makeLbl(devScroll, "new script & Information")
makeSpacer(devScroll, 12)

local discHolder = N("Frame", {
    Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, LayoutOrder = nextOrd(),
}, devScroll)
local discBtn = N("TextButton", {
    Size = UDim2.new(0, 220, 0, 38), Position = UDim2.new(0.5, -110, 0.5, -19),
    BackgroundColor3 = C.Discord, Text = "Join Discord",
    TextSize = 13, Font = Enum.Font.GothamBold, TextColor3 = C.White,
    AutoButtonColor = false, BorderSizePixel = 0, Rotation = -3, ZIndex = 4,
}, discHolder)
corner(discBtn, 20)
stroke(discBtn, Color3.fromRGB(120, 130, 255), 0.3, 1)
discBtn.MouseButton1Click:Connect(function()
    local url = "https://discord.gg/kjVyy4vxR5"
    if setclipboard then setclipboard(url)
    elseif syn and syn.clipboard then syn.clipboard.set(url) end
    Notify("Discord link disalin!", 3)
end)
discBtn.MouseEnter:Connect(function() tw(discBtn, 0.12, { BackgroundColor3 = C.DiscHov }) end)
discBtn.MouseLeave:Connect(function() tw(discBtn, 0.12, { BackgroundColor3 = C.Discord }) end)

-- INSERT = toggle visibility
UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.Insert then
        Win.Visible = not Win.Visible
    end
end)

Notify("Pegasus Hub loaded! | Dead Rails", 5)
