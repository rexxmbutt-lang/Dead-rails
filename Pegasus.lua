-- ═══════════════════════════════════════════════════════
--  Pegasus Hub | Dead Rails
--  Developer : rexx script
--  Library   : github.com/rexxmbutt-lang/Libraary-script-roblox
-- ═══════════════════════════════════════════════════════

-- ── Load Library ──────────────────────────────────────
local Lib = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/rexxmbutt-lang/Libraary-script-roblox/refs/heads/main/library.luau"
))()

-- ── Services & locals ────────────────────────────────
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UserInputService= game:GetService("UserInputService")
local TweenService    = game:GetService("TweenService")
local Workspace       = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local lp   = Players.LocalPlayer
local char = lp.Character or lp.CharacterAdded:Wait()
local hum  = char:WaitForChild("Humanoid")
local hrp  = char:WaitForChild("HumanoidRootPart")

lp.CharacterAdded:Connect(function(c)
    char = c
    hum  = c:WaitForChild("Humanoid")
    hrp  = c:WaitForChild("HumanoidRootPart")
end)

-- ── State ─────────────────────────────────────────────
local F = {
    AutoBonds    = false,
    BringItems   = false,
    AutoEscape   = false,
    AutoDrive    = false,
    SpeedBoost   = false,
    Fly          = false,
    ESPBonds     = false,
    ESPZombie    = false,
    ESPWerewolf  = false,
    ESPCowboy    = false,
}

local DEFAULT_SPEED = 16
local BOOST_SPEED   = 80
local FLY_SPEED     = 60
local ESP_COLOR     = Color3.fromRGB(255, 0, 0)

-- ── Helpers ───────────────────────────────────────────
local function getAll()
    local ok, r = pcall(function() return Workspace:GetDescendants() end)
    return ok and r or {}
end

-- ═══════════════════════════════════════════════════════
--  MAIN FEATURES
-- ═══════════════════════════════════════════════════════

-- Auto Bonds: collect semua currency di map
local function tickBonds()
    local origin = hrp.CFrame
    for _, v in ipairs(getAll()) do
        local n = v.Name:lower()
        if (n:find("bond") or n:find("gold") or n:find("coin") or n:find("cash"))
            and (v:IsA("BasePart") or v:IsA("Model")) then
            local part = v:IsA("Model") and v.PrimaryPart or v
            if part then
                pcall(function()
                    hrp.CFrame = part.CFrame + Vector3.new(0, 2, 0)
                end)
                task.wait(0.04)
            end
        end
    end
    hrp.CFrame = origin
end

-- Bring All Items: lempar item ke player
local function tickBring()
    for _, v in ipairs(getAll()) do
        if v:IsA("BasePart") and not v.Anchored and v.CanCollide == false then
            pcall(function()
                v.CFrame = hrp.CFrame
                    + Vector3.new(math.random(-3,3), 1, math.random(-3,3))
            end)
        end
    end
end

-- Auto Escape: fire semua remote event win condition
local WIN_REMOTES = {
    "EscapeGame","WinGame","TrainEscaped","Escaped",
    "Victory","FinishGame","GameWin","CompleteGame"
}
local function doEscape()
    for _, name in ipairs(WIN_REMOTES) do
        local r = ReplicatedStorage:FindFirstChild(name, true)
                  or Workspace:FindFirstChild(name, true)
        if r then
            if r:IsA("RemoteEvent") then pcall(function() r:FireServer() end) end
            if r:IsA("RemoteFunction") then pcall(function() r:InvokeServer() end) end
        end
    end
    F.AutoEscape = false
end

-- Auto Drive: duduk di seat kereta, throttle max
local driveConn = nil
local function startDrive()
    for _, v in ipairs(getAll()) do
        if v:IsA("VehicleSeat") or v:IsA("Seat") then
            local n = v.Name:lower()
            if n:find("driver") or n:find("cabin") or n:find("front") or n:find("seat") then
                pcall(function() v:Sit(hum) end)
                if v:IsA("VehicleSeat") then
                    driveConn = RunService.Heartbeat:Connect(function()
                        if not F.AutoDrive then driveConn:Disconnect() return end
                        v.Throttle = 1
                        v.Steer    = 0
                    end)
                end
                return
            end
        end
    end
end

-- Speed
local function applySpeed()
    pcall(function()
        hum.WalkSpeed = F.SpeedBoost and BOOST_SPEED or DEFAULT_SPEED
    end)
end

-- Fly
local flyBV, flyBG, flyConn = nil, nil, nil
local function startFly()
    if flyBV then return end
    flyBV = Instance.new("BodyVelocity")
    flyBV.Velocity  = Vector3.zero
    flyBV.MaxForce  = Vector3.new(1e5,1e5,1e5)
    flyBV.Parent    = hrp
    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1e5,1e5,1e5)
    flyBG.D         = 100
    flyBG.Parent    = hrp
    flyConn = RunService.RenderStepped:Connect(function()
        if not F.Fly then
            if flyBV then flyBV:Destroy() flyBV = nil end
            if flyBG then flyBG:Destroy() flyBG = nil end
            flyConn:Disconnect() flyConn = nil
            return
        end
        local cam = Workspace.CurrentCamera
        local mv  = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then mv += cam.CFrame.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then mv -= cam.CFrame.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then mv -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then mv += cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)       then mv += Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then mv -= Vector3.yAxis end
        flyBV.Velocity = mv.Magnitude > 0 and mv.Unit * FLY_SPEED or Vector3.zero
        flyBG.CFrame   = cam.CFrame
        hum:ChangeState(Enum.HumanoidStateType.Physics)
    end)
end
local function stopFly()
    F.Fly = false
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
    if flyConn then flyConn:Disconnect() flyConn = nil end
    pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
end

-- ═══════════════════════════════════════════════════════
--  ESP (DrawingLib — box merah)
-- ═══════════════════════════════════════════════════════
local espData = {} -- [model] = { box={L,L,L,L}, lbl }

local function espTagMatch(v)
    local n = v.Name:lower()
    if F.ESPBonds    and (n:find("bond") or n:find("gold") or n:find("coin")) then return "BOND"     end
    if F.ESPZombie   and n:find("zombie")   then return "ZOMBIE"   end
    if F.ESPWerewolf and n:find("werewolf") then return "WEREWOLF" end
    if F.ESPCowboy   and (n:find("cowboy") or n:find("outlaw") or n:find("bandit")) then return "COWBOY" end
    return nil
end

local function newBox()
    local t = {}
    for i = 1,4 do
        local l = Drawing.new("Line")
        l.Color     = ESP_COLOR
        l.Thickness = 1.5
        l.Visible   = false
        t[i] = l
    end
    return t
end

local function newLabel()
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
    local cam = Workspace.CurrentCamera
    local sp, vis = cam:WorldToViewportPoint(pos)
    return Vector2.new(sp.X, sp.Y), sp.Z > 0 and vis
end

local function drawBox(lines, tl, br)
    local x0,y0 = tl.X, tl.Y
    local x1,y1 = br.X, br.Y
    lines[1].From=Vector2.new(x0,y0) lines[1].To=Vector2.new(x1,y0) -- top
    lines[2].From=Vector2.new(x0,y1) lines[2].To=Vector2.new(x1,y1) -- bottom
    lines[3].From=Vector2.new(x0,y0) lines[3].To=Vector2.new(x0,y1) -- left
    lines[4].From=Vector2.new(x1,y0) lines[4].To=Vector2.new(x1,y1) -- right
    for _,l in ipairs(lines) do l.Visible = true end
end

local function hideBox(lines)
    for _,l in ipairs(lines) do l.Visible = false end
end

RunService.RenderStepped:Connect(function()
    local anyESP = F.ESPBonds or F.ESPZombie or F.ESPWerewolf or F.ESPCowboy
    for model, e in pairs(espData) do
        if not model or not model.Parent then
            destroyEntry(e)
            espData[model] = nil
        end
    end
    if not anyESP then
        for m, e in pairs(espData) do destroyEntry(e) espData[m] = nil end
        return
    end

    local seen = {}
    for _, v in ipairs(getAll()) do
        local tag = espTagMatch(v)
        if tag then
            local mdl = v:IsA("Model") and v or v.Parent
            if mdl and not seen[mdl] then
                seen[mdl] = true
                if not espData[mdl] then
                    espData[mdl] = { box = newBox(), lbl = newLabel() }
                end
                local e = espData[mdl]
                local ok, bbcf, bbs = pcall(function() return mdl:GetBoundingBox() end)
                if ok and bbcf and bbs then
                    local top    = bbcf.Position + Vector3.new(0, bbs.Y/2, 0)
                    local bottom = bbcf.Position - Vector3.new(0, bbs.Y/2, 0)
                    local tsp, tv = w2s(top)
                    local bsp, bv = w2s(bottom)
                    if tv or bv then
                        local h = math.abs(tsp.Y - bsp.Y)
                        local w = h * 0.6
                        local tl = Vector2.new(tsp.X - w/2, math.min(tsp.Y, bsp.Y))
                        local br = tl + Vector2.new(w, h)
                        drawBox(e.box, tl, br)
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

-- ── Main loop (bonds, bring, escape) ─────────────────
task.spawn(function()
    while task.wait(0.5) do
        if F.AutoBonds   then pcall(tickBonds)  end
        if F.BringItems  then pcall(tickBring)  end
        if F.AutoEscape  then pcall(doEscape)   end
    end
end)

-- ═══════════════════════════════════════════════════════
--  UI  (Rexxzy_Library native — Custom primitives)
-- ═══════════════════════════════════════════════════════
local Custom = Lib._Custom or (function()
    -- Rexxzy_Library expose Custom via upvalue; fallback kalau nil
    local ok, m = pcall(loadstring, game:HttpGet(
        "https://raw.githubusercontent.com/rexxmbutt-lang/Libraary-script-roblox/refs/heads/main/library.luau"
    ))
    return ok and m and m._Custom or nil
end)()

-- GuiParent
local function getGui()
    if gethui then local ok,r = pcall(gethui) if ok and r then return r end end
    if cloneref then
        local ok,r = pcall(function() return cloneref(game:GetService("CoreGui")) end)
        if ok and r then return r end
    end
    return game:GetService("CoreGui")
end

-- ── Colour palette (matches library's Theme) ─────────
local T = {
    Dark      = Color3.fromRGB(4,4,5),
    Panel     = Color3.fromRGB(14,14,17),
    Field     = Color3.fromRGB(22,22,27),
    Text      = Color3.fromRGB(245,245,247),
    Sub       = Color3.fromRGB(155,155,162),
    Border    = Color3.fromRGB(76,76,83),
    Accent    = Color3.fromRGB(245,245,247),
    Off       = Color3.fromRGB(36,36,41),
    Hover     = Color3.fromRGB(28,28,33),
    Red       = Color3.fromRGB(220,60,60),
    White     = Color3.fromRGB(238,238,242),
    Toggle_On = Color3.fromRGB(80,200,120),
}

local function new(cls, props, parent)
    local i = Instance.new(cls)
    for k,v in pairs(props) do i[k] = v end
    if parent then i.Parent = parent end
    return i
end
local function corner(inst, r)
    return new("UICorner",{CornerRadius=UDim.new(0,r or 8)},inst)
end
local function stroke(inst, col, trans, thick)
    return new("UIStroke",{
        Color=col or T.White, Transparency=trans or 0.72,
        Thickness=thick or 1, ApplyStrokeMode=Enum.ApplyStrokeMode.Border
    },inst)
end
local function tween(obj,t,props)
    TweenService:Create(obj,TweenInfo.new(t,Enum.EasingStyle.Quad),props):Play()
end
local function label(parent, text, size, color, xa)
    return new("TextLabel",{
        Text=text, TextSize=size or 12,
        TextColor3=color or T.Text,
        Font=Enum.Font.GothamBold,
        BackgroundTransparency=1,
        BorderSizePixel=0,
        TextXAlignment=xa or Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd,
        Size=UDim2.new(1,0,1,0),
    }, parent)
end

-- ── Notify helper ─────────────────────────────────────
local function notify(msg, dur)
    if Lib and Lib.Notify then
        pcall(function() Lib:Notify({ Title="Pegasus Hub", Content=msg, Duration=dur or 3 }) end)
    end
end

-- ══════════════════════════════════════════════════════
--  ROOT GUI
-- ══════════════════════════════════════════════════════
local GuiParent = getGui()
local ScreenGui = new("ScreenGui",{
    Name="PegasusHub",
    ResetOnSpawn=false,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
}, GuiParent)

-- Main window frame
local WIN_W, WIN_H = 400, 500
local Window = new("Frame",{
    Size=UDim2.new(0,WIN_W,0,WIN_H),
    Position=UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2),
    BackgroundColor3=T.Dark,
    BorderSizePixel=0,
    ClipsDescendants=true,
    Name="Window",
},ScreenGui)
corner(Window,10)
stroke(Window,T.Border,0.3,1)

-- ── Drag ─────────────────────────────────────────────
do
    local drag,startM,startP = false,nil,nil
    Window.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then
            drag=true startM=inp.Position startP=Window.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if drag and inp.UserInputType==Enum.UserInputType.MouseMovement then
            local d=inp.Position-startM
            Window.Position=UDim2.new(
                startP.X.Scale,startP.X.Offset+d.X,
                startP.Y.Scale,startP.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
    end)
end

-- ── Titlebar ─────────────────────────────────────────
local Titlebar = new("Frame",{
    Size=UDim2.new(1,0,0,46),
    BackgroundColor3=T.Panel,
    BorderSizePixel=0,
    Name="Titlebar",
},Window)
corner(Titlebar,10)
-- bottom corners square
new("Frame",{
    Size=UDim2.new(1,0,0,10),
    Position=UDim2.new(0,0,1,-10),
    BackgroundColor3=T.Panel,
    BorderSizePixel=0,
},Titlebar)

label(Titlebar,"🦅  Pegasus Hub",14,T.Text,Enum.TextXAlignment.Left).Position=UDim2.new(0,14,0,0)
label(Titlebar,"Dead Rails",11,T.Sub,Enum.TextXAlignment.Left).Position=UDim2.new(0,14,0,22)

-- Close button
local CloseBtn = new("TextButton",{
    Size=UDim2.new(0,26,0,26),
    Position=UDim2.new(1,-36,0,10),
    BackgroundColor3=T.Off,
    Text="✕",TextSize=12,
    TextColor3=T.Sub,
    Font=Enum.Font.GothamBold,
    AutoButtonColor=false,
    BorderSizePixel=0,
},Titlebar)
corner(CloseBtn,6)
CloseBtn.MouseButton1Click:Connect(function()
    tween(Window,0.2,{Size=UDim2.new(0,WIN_W,0,0)})
    task.wait(0.22) ScreenGui:Destroy()
end)

-- ── Tab bar ──────────────────────────────────────────
local TabBar = new("Frame",{
    Size=UDim2.new(1,0,0,36),
    Position=UDim2.new(0,0,0,46),
    BackgroundColor3=T.Panel,
    BorderSizePixel=0,
},Window)
local TabLayout = new("UIListLayout",{
    FillDirection=Enum.FillDirection.Horizontal,
    SortOrder=Enum.SortOrder.LayoutOrder,
    Padding=UDim.new(0,4),
},TabBar)
new("UIPadding",{PaddingLeft=UDim.new(0,10),PaddingTop=UDim.new(0,6),PaddingBottom=UDim.new(0,6)},TabBar)

-- Content area
local ContentArea = new("Frame",{
    Size=UDim2.new(1,0,1,-82),
    Position=UDim2.new(0,0,0,82),
    BackgroundTransparency=1,
    ClipsDescendants=true,
},Window)

-- ── Tab system ───────────────────────────────────────
local tabs = {}
local activeTab = nil

local function createTab(name)
    -- Tab button
    local btn = new("TextButton",{
        Size=UDim2.new(0,0,1,0),
        AutomaticSize=Enum.AutomaticSize.X,
        BackgroundColor3=T.Off,
        BackgroundTransparency=1,
        Text=name, TextSize=12,
        TextColor3=T.Sub,
        Font=Enum.Font.GothamBold,
        AutoButtonColor=false,
        BorderSizePixel=0,
        LayoutOrder=#tabs+1,
    },TabBar)
    new("UIPadding",{PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10)},btn)
    corner(btn,6)

    -- Content frame for this tab
    local content = new("ScrollingFrame",{
        Size=UDim2.new(1,0,1,0),
        BackgroundTransparency=1,
        ScrollBarThickness=3,
        ScrollBarImageColor3=T.Border,
        CanvasSize=UDim2.new(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y,
        Visible=false,
        BorderSizePixel=0,
    },ContentArea)
    new("UIListLayout",{
        SortOrder=Enum.SortOrder.LayoutOrder,
        Padding=UDim.new(0,6),
    },content)
    new("UIPadding",{
        PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12),
        PaddingTop=UDim.new(0,10),PaddingBottom=UDim.new(0,10),
    },content)

    local tab = { btn=btn, content=content, name=name }
    table.insert(tabs, tab)

    btn.MouseButton1Click:Connect(function()
        if activeTab then
            activeTab.content.Visible = false
            tween(activeTab.btn,0.12,{TextColor3=T.Sub, BackgroundTransparency=1})
        end
        activeTab = tab
        content.Visible = true
        tween(btn,0.12,{TextColor3=T.Text, BackgroundTransparency=0.6})
    end)

    -- Activate first tab automatically
    if #tabs == 1 then
        activeTab = tab
        content.Visible = true
        btn.BackgroundTransparency = 0.6
        btn.TextColor3 = T.Text
    end

    return content
end

-- ── Control widgets ──────────────────────────────────
local function rowFrame(parent, order)
    local f = new("Frame",{
        Size=UDim2.new(1,0,0,38),
        BackgroundColor3=T.Field,
        BorderSizePixel=0,
        LayoutOrder=order or 1,
    },parent)
    corner(f,8)
    stroke(f,T.Border,0.7,1)
    return f
end

local function addToggle(parent, name, default, onChange, order)
    local row = rowFrame(parent, order)
    local lbl = new("TextLabel",{
        Size=UDim2.new(1,-52,1,0),
        Position=UDim2.new(0,12,0,0),
        BackgroundTransparency=1,
        Text=name, TextSize=12,
        TextColor3=T.Text,
        Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Left,
    },row)

    -- Toggle pill
    local pill = new("Frame",{
        Size=UDim2.new(0,38,0,20),
        Position=UDim2.new(1,-50,0.5,-10),
        BackgroundColor3=default and T.Toggle_On or T.Off,
        BorderSizePixel=0,
    },row)
    corner(pill,10)
    local dot = new("Frame",{
        Size=UDim2.new(0,14,0,14),
        Position=default and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7),
        BackgroundColor3=T.White,
        BorderSizePixel=0,
    },pill)
    corner(dot,7)

    local state = default or false
    local btn = new("TextButton",{
        Size=UDim2.new(1,0,1,0),
        BackgroundTransparency=1,
        Text="",AutoButtonColor=false,
    },row)
    btn.MouseButton1Click:Connect(function()
        state = not state
        tween(pill,0.15,{BackgroundColor3=state and T.Toggle_On or T.Off})
        tween(dot,0.15,{Position=state and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)})
        onChange(state)
    end)

    -- Hover
    btn.MouseEnter:Connect(function() tween(row,0.1,{BackgroundColor3=T.Hover}) end)
    btn.MouseLeave:Connect(function() tween(row,0.1,{BackgroundColor3=T.Field}) end)

    return state
end

local function addButton(parent, name, onClick, order)
    local row = rowFrame(parent, order)
    row.BackgroundColor3 = T.Panel
    local lbl = new("TextLabel",{
        Size=UDim2.new(1,0,1,0),
        BackgroundTransparency=1,
        Text=name, TextSize=12,
        TextColor3=T.Text,
        Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Center,
    },row)
    local btn = new("TextButton",{
        Size=UDim2.new(1,0,1,0),
        BackgroundTransparency=1,
        Text="",AutoButtonColor=false,
    },row)
    btn.MouseButton1Click:Connect(onClick)
    btn.MouseEnter:Connect(function() tween(row,0.1,{BackgroundColor3=T.Hover}) end)
    btn.MouseLeave:Connect(function() tween(row,0.1,{BackgroundColor3=T.Panel}) end)
end

local function addLabel(parent, text, order)
    new("TextLabel",{
        Size=UDim2.new(1,0,0,22),
        BackgroundTransparency=1,
        Text=text, TextSize=11,
        TextColor3=T.Sub,
        Font=Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Center,
        TextWrapped=true,
        LayoutOrder=order or 1,
    },parent)
end

local function addSection(parent, name, order)
    new("TextLabel",{
        Size=UDim2.new(1,0,0,18),
        BackgroundTransparency=1,
        Text=name, TextSize=10,
        TextColor3=T.Sub,
        Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Left,
        LayoutOrder=order or 1,
    },parent)
end

-- ══════════════════════════════════════════════════════
--  TABS & CONTROLS
-- ══════════════════════════════════════════════════════

-- ── MAIN Tab ──────────────────────────────────────────
local mainContent = createTab("MAIN")

addSection(mainContent,"CURRENCY",1)
addToggle(mainContent,"Auto Bonds",false,function(s)
    F.AutoBonds = s
    notify("Auto Bonds: "..(s and "ON" or "OFF"))
end,2)

addSection(mainContent,"ITEMS",3)
addToggle(mainContent,"Bring All Item",false,function(s)
    F.BringItems = s
    notify("Bring All Item: "..(s and "ON" or "OFF"))
end,4)

addSection(mainContent,"GAME",5)
addButton(mainContent,"Auto Escape (WIN)",function()
    F.AutoEscape = true
    notify("Auto Escape aktif!")
end,6)

addButton(mainContent,"Auto Drive (Toggle)",function()
    F.AutoDrive = not F.AutoDrive
    if F.AutoDrive then startDrive() end
    if driveConn and not F.AutoDrive then driveConn:Disconnect() driveConn=nil end
    notify("Auto Drive: "..(F.AutoDrive and "ON" or "OFF"))
end,7)

addSection(mainContent,"MOVEMENT",8)
addToggle(mainContent,"Speed Boost  [WASD]",false,function(s)
    F.SpeedBoost = s
    applySpeed()
    notify("Speed Boost: "..(s and "ON" or "OFF"))
end,9)

addToggle(mainContent,"Fly  [WASD+Space/Ctrl]",false,function(s)
    F.Fly = s
    if s then startFly() else stopFly() end
    notify("Fly: "..(s and "ON" or "OFF"))
end,10)

-- ── ESP Tab ───────────────────────────────────────────
local espContent = createTab("ESP")

addSection(espContent,"BOX ESP (MERAH)",1)
addToggle(espContent,"ESP Bonds",false,function(s)
    F.ESPBonds = s
    notify("ESP Bonds: "..(s and "ON" or "OFF"))
end,2)
addToggle(espContent,"ESP Zombie",false,function(s)
    F.ESPZombie = s
    notify("ESP Zombie: "..(s and "ON" or "OFF"))
end,3)
addToggle(espContent,"ESP Werewolf",false,function(s)
    F.ESPWerewolf = s
    notify("ESP Werewolf: "..(s and "ON" or "OFF"))
end,4)
addToggle(espContent,"ESP Cowboy",false,function(s)
    F.ESPCowboy = s
    notify("ESP Cowboy: "..(s and "ON" or "OFF"))
end,5)

-- ── DEVELOPER Tab ─────────────────────────────────────
local devContent = createTab("DEV")

addLabel(devContent,"hello guys",1)
addLabel(devContent,"My name is rexx",2)
addLabel(devContent,"And me the developer this script",3)
addLabel(devContent,"Join my discord server to get",4)
addLabel(devContent,"new script & Information",5)

-- Discord button oval miring
local discordRow = new("Frame",{
    Size=UDim2.new(1,0,0,46),
    BackgroundTransparency=1,
    LayoutOrder=6,
},devContent)
local discordBtn = new("TextButton",{
    Size=UDim2.new(0,220,0,36),
    Position=UDim2.new(0.5,-110,0.5,-18),
    BackgroundColor3=Color3.fromRGB(88,101,242),
    Text="⟣  Join Discord  ⟢",
    TextSize=13,
    TextColor3=Color3.fromRGB(255,255,255),
    Font=Enum.Font.GothamBold,
    AutoButtonColor=false,
    BorderSizePixel=0,
    Rotation=-3,  -- miring sedikit
},discordRow)
corner(discordBtn,18)  -- oval
stroke(discordBtn,Color3.fromRGB(100,115,255),0.4,1)

discordBtn.MouseButton1Click:Connect(function()
    local url = "https://discord.gg/kjVyy4vxR5"
    if setclipboard then
        setclipboard(url)
        notify("Discord link disalin!",3)
    elseif syn and syn.clipboard then
        syn.clipboard.set(url)
        notify("Discord link disalin!",3)
    end
end)
discordBtn.MouseEnter:Connect(function()
    tween(discordBtn,0.12,{BackgroundColor3=Color3.fromRGB(100,115,255)})
end)
discordBtn.MouseLeave:Connect(function()
    tween(discordBtn,0.12,{BackgroundColor3=Color3.fromRGB(88,101,242)})
end)

-- ── Hotkey: INSERT = toggle visibility ───────────────
UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.Insert then
        Window.Visible = not Window.Visible
    end
end)

-- ── Open notify ──────────────────────────────────────
notify("Pegasus Hub loaded! | Dead Rails",5)
