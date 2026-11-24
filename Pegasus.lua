-- ═══════════════════════════════════════════════════════
--  Pegasus Hub | Dead Rails
--  Developer : rexx script
--  Library   : github.com/rexxmbutt-lang/Libraary-script-roblox
-- ═══════════════════════════════════════════════════════

-- ── Load Library (hanya untuk Notify) ────────────────
local LibOk, Lib = pcall(function()
    return loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/rexxmbutt-lang/Libraary-script-roblox/refs/heads/main/library.luau"
    ))()
end)
if not LibOk then Lib = nil end

-- ── Services ─────────────────────────────────────────
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Workspace        = game:GetService("Workspace")
local ReplicatedStorage= game:GetService("ReplicatedStorage")

local lp   = Players.LocalPlayer
local char = lp.Character or lp.CharacterAdded:Wait()
local hum  = char:WaitForChild("Humanoid")
local hrp  = char:WaitForChild("HumanoidRootPart")

lp.CharacterAdded:Connect(function(c)
    char = c
    hum  = c:WaitForChild("Humanoid")
    hrp  = c:WaitForChild("HumanoidRootPart")
end)

-- ── State flags ───────────────────────────────────────
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
local ESP_COLOR     = Color3.fromRGB(255, 0, 0)

-- ═══════════════════════════════════════════════════════
--  HELPERS
-- ═══════════════════════════════════════════════════════
local function getAll()
    local ok, r = pcall(function() return Workspace:GetDescendants() end)
    return ok and r or {}
end

-- ═══════════════════════════════════════════════════════
--  FEATURES
-- ═══════════════════════════════════════════════════════

-- Auto Bonds
local function tickBonds()
    local origin = hrp.CFrame
    for _, v in ipairs(getAll()) do
        local n = v.Name:lower()
        if n:find("bond") or n:find("gold") or n:find("coin") or n:find("cash") then
            if v:IsA("BasePart") or v:IsA("Model") then
                local part = v:IsA("Model") and v.PrimaryPart or v
                if part then
                    pcall(function() hrp.CFrame = part.CFrame + Vector3.new(0,2,0) end)
                    task.wait(0.04)
                end
            end
        end
    end
    hrp.CFrame = origin
end

-- Bring All Items
local function tickBring()
    for _, v in ipairs(getAll()) do
        if v:IsA("BasePart") and not v.Anchored and v.CanCollide == false then
            pcall(function()
                v.CFrame = hrp.CFrame + Vector3.new(math.random(-3,3),1,math.random(-3,3))
            end)
        end
    end
end

-- Auto Escape
local WIN_REMOTES = {
    "EscapeGame","WinGame","TrainEscaped","Escaped",
    "Victory","FinishGame","GameWin","CompleteGame"
}
local function doEscape()
    for _, name in ipairs(WIN_REMOTES) do
        local r = ReplicatedStorage:FindFirstChild(name,true)
                  or Workspace:FindFirstChild(name,true)
        if r then
            if r:IsA("RemoteEvent")    then pcall(function() r:FireServer()   end) end
            if r:IsA("RemoteFunction") then pcall(function() r:InvokeServer() end) end
        end
    end
    F.AutoEscape = false
end

-- Auto Drive
local driveConn = nil
local function startDrive()
    for _, v in ipairs(getAll()) do
        if v:IsA("VehicleSeat") or v:IsA("Seat") then
            local n = v.Name:lower()
            if n:find("driver") or n:find("cabin") or n:find("front") or n:find("seat") then
                pcall(function() v:Sit(hum) end)
                if v:IsA("VehicleSeat") then
                    if driveConn then driveConn:Disconnect() end
                    driveConn = RunService.Heartbeat:Connect(function()
                        if not F.AutoDrive then driveConn:Disconnect() driveConn=nil return end
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
    flyBV          = Instance.new("BodyVelocity")
    flyBV.Velocity = Vector3.zero
    flyBV.MaxForce = Vector3.new(1e5,1e5,1e5)
    flyBV.Parent   = hrp
    flyBG          = Instance.new("BodyGyro")
    flyBG.MaxTorque= Vector3.new(1e5,1e5,1e5)
    flyBG.D        = 100
    flyBG.Parent   = hrp
    flyConn = RunService.RenderStepped:Connect(function()
        if not F.Fly then
            if flyBV then flyBV:Destroy() flyBV=nil end
            if flyBG then flyBG:Destroy() flyBG=nil end
            flyConn:Disconnect() flyConn=nil
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
    if flyBV  then flyBV:Destroy()       flyBV=nil  end
    if flyBG  then flyBG:Destroy()       flyBG=nil  end
    if flyConn then flyConn:Disconnect() flyConn=nil end
    pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
end

-- ═══════════════════════════════════════════════════════
--  ESP — DrawingLib box merah
-- ═══════════════════════════════════════════════════════
local espData = {}

local function espTag(v)
    local n = v.Name:lower()
    if F.ESPBonds    and (n:find("bond") or n:find("gold") or n:find("coin")) then return "BOND"     end
    if F.ESPZombie   and  n:find("zombie")                                     then return "ZOMBIE"   end
    if F.ESPWerewolf and  n:find("werewolf")                                   then return "WEREWOLF" end
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
    for _,l in ipairs(lines) do l.Visible=true end
end
local function hideBox(lines)
    for _,l in ipairs(lines) do l.Visible=false end
end

RunService.RenderStepped:Connect(function()
    local anyESP = F.ESPBonds or F.ESPZombie or F.ESPWerewolf or F.ESPCowboy
    for mdl, e in pairs(espData) do
        if not mdl or not mdl.Parent then destroyEntry(e) espData[mdl]=nil end
    end
    if not anyESP then
        for m,e in pairs(espData) do destroyEntry(e) espData[m]=nil end
        return
    end
    local seen = {}
    for _, v in ipairs(getAll()) do
        local tag = espTag(v)
        if tag then
            local mdl = v:IsA("Model") and v or (v.Parent and v.Parent:IsA("Model") and v.Parent or nil)
            if mdl and not seen[mdl] then
                seen[mdl] = true
                if not espData[mdl] then espData[mdl]={box=newBox(),lbl=newLbl()} end
                local e   = espData[mdl]
                local ok, bbcf, bbs = pcall(function() return mdl:GetBoundingBox() end)
                if ok and bbcf and bbs then
                    local top    = bbcf.Position + Vector3.new(0, bbs.Y/2, 0)
                    local bottom = bbcf.Position - Vector3.new(0, bbs.Y/2, 0)
                    local tsp,tv = w2s(top)
                    local bsp,bv = w2s(bottom)
                    if tv or bv then
                        local h  = math.abs(tsp.Y - bsp.Y)
                        local w  = h * 0.55
                        local tl = Vector2.new(tsp.X-w/2, math.min(tsp.Y,bsp.Y))
                        drawBox(e.box, tl, tl+Vector2.new(w,h))
                        local dist = math.floor((bbcf.Position-hrp.Position).Magnitude)
                        e.lbl.Text     = string.format("[%s] %s | %dm", tag, mdl.Name, dist)
                        e.lbl.Position = Vector2.new(tl.X, tl.Y-16)
                        e.lbl.Visible  = true
                    else
                        hideBox(e.box) e.lbl.Visible=false
                    end
                else
                    hideBox(e.box) e.lbl.Visible=false
                end
            end
        end
    end
    for m,e in pairs(espData) do
        if not seen[m] then hideBox(e.box) e.lbl.Visible=false end
    end
end)

-- ── Main loop ─────────────────────────────────────────
task.spawn(function()
    while task.wait(0.5) do
        if F.AutoBonds  then pcall(tickBonds) end
        if F.BringItems then pcall(tickBring) end
        if F.AutoEscape then pcall(doEscape)  end
    end
end)

-- ═══════════════════════════════════════════════════════
--  UI — 100% Roblox Instance primitif, zero _Custom
-- ═══════════════════════════════════════════════════════
local function getGuiParent()
    if gethui then local ok,r=pcall(gethui) if ok and r then return r end end
    if cloneref then
        local ok,r=pcall(function() return cloneref(game:GetService("CoreGui")) end)
        if ok and r then return r end
    end
    return game:GetService("CoreGui")
end

-- Notify wrapper
local function notify(msg, dur)
    if Lib and type(Lib)=="table" and Lib.Notify then
        pcall(function() Lib:Notify({Title="Pegasus Hub",Content=msg,Duration=dur or 3}) end)
    end
end

-- ── Colour palette ────────────────────────────────────
local C = {
    BG       = Color3.fromRGB(10,10,13),
    Panel    = Color3.fromRGB(18,18,22),
    Field    = Color3.fromRGB(24,24,30),
    Hover    = Color3.fromRGB(30,30,38),
    Text     = Color3.fromRGB(240,240,245),
    Sub      = Color3.fromRGB(140,140,150),
    Border   = Color3.fromRGB(55,55,68),
    TglOn    = Color3.fromRGB(72,187,120),
    TglOff   = Color3.fromRGB(44,44,55),
    White    = Color3.fromRGB(255,255,255),
    Discord  = Color3.fromRGB(88,101,242),
    DiscHov  = Color3.fromRGB(108,121,255),
}

-- ── Instance helpers ─────────────────────────────────
local function N(cls, props, parent)
    local i = Instance.new(cls)
    for k,v in pairs(props) do
        pcall(function() i[k]=v end)
    end
    if parent then i.Parent=parent end
    return i
end
local function corner(inst,r)
    return N("UICorner",{CornerRadius=UDim.new(0,r or 8)},inst)
end
local function uistroke(inst,col,trans,thick)
    return N("UIStroke",{
        Color=col or C.Border,
        Transparency=trans or 0.5,
        Thickness=thick or 1,
        ApplyStrokeMode=Enum.ApplyStrokeMode.Border,
    },inst)
end
local function tw(obj,t,props)
    TweenService:Create(obj,TweenInfo.new(t,Enum.EasingStyle.Quad),props):Play()
end

-- ── Root ScreenGui ───────────────────────────────────
local SG = N("ScreenGui",{
    Name="PegasusHub",
    ResetOnSpawn=false,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
    DisplayOrder=999,
}, getGuiParent())

-- ── Window ───────────────────────────────────────────
local W,H = 390,490
local Win = N("Frame",{
    Name="Window",
    Size=UDim2.new(0,W,0,H),
    Position=UDim2.new(0.5,-W/2,0.5,-H/2),
    BackgroundColor3=C.BG,
    BorderSizePixel=0,
    ClipsDescendants=true,
},SG)
corner(Win,10)
uistroke(Win,C.Border,0.4,1)

-- ── Drag ─────────────────────────────────────────────
do
    local dragging,dmouse,dpos=false,nil,nil
    Win.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1
        or inp.UserInputType==Enum.UserInputType.Touch then
            dragging=true dmouse=inp.Position dpos=Win.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType==Enum.UserInputType.MouseMovement
        or inp.UserInputType==Enum.UserInputType.Touch then
            local d=inp.Position-dmouse
            Win.Position=UDim2.new(dpos.X.Scale,dpos.X.Offset+d.X,
                                   dpos.Y.Scale,dpos.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1
        or inp.UserInputType==Enum.UserInputType.Touch then
            dragging=false
        end
    end)
end

-- ── Titlebar ─────────────────────────────────────────
local TB = N("Frame",{
    Size=UDim2.new(1,0,0,50),
    BackgroundColor3=C.Panel,
    BorderSizePixel=0,
    ZIndex=2,
},Win)
corner(TB,10)
N("Frame",{
    Size=UDim2.new(1,0,0,12),
    Position=UDim2.new(0,0,1,-12),
    BackgroundColor3=C.Panel,
    BorderSizePixel=0,
    ZIndex=2,
},TB)

N("TextLabel",{
    Size=UDim2.new(1,-50,0,26),
    Position=UDim2.new(0,14,0,6),
    BackgroundTransparency=1,
    Text="🦅  Pegasus Hub",
    TextSize=14, Font=Enum.Font.GothamBold,
    TextColor3=C.Text,
    TextXAlignment=Enum.TextXAlignment.Left,
    ZIndex=3,
},TB)
N("TextLabel",{
    Size=UDim2.new(1,-50,0,18),
    Position=UDim2.new(0,14,0,28),
    BackgroundTransparency=1,
    Text="Dead Rails  •  rexx script",
    TextSize=10, Font=Enum.Font.Gotham,
    TextColor3=C.Sub,
    TextXAlignment=Enum.TextXAlignment.Left,
    ZIndex=3,
},TB)

-- Close
local CloseB = N("TextButton",{
    Size=UDim2.new(0,24,0,24),
    Position=UDim2.new(1,-34,0,13),
    BackgroundColor3=Color3.fromRGB(50,30,30),
    Text="✕", TextSize=11,
    TextColor3=Color3.fromRGB(220,100,100),
    Font=Enum.Font.GothamBold,
    AutoButtonColor=false, BorderSizePixel=0, ZIndex=4,
},TB)
corner(CloseB,5)
CloseB.MouseButton1Click:Connect(function()
    tw(Win,0.18,{Size=UDim2.new(0,W,0,0),BackgroundTransparency=1})
    task.wait(0.2) SG:Destroy()
end)

-- ── Tab bar ──────────────────────────────────────────
local TabBar = N("Frame",{
    Size=UDim2.new(1,0,0,34),
    Position=UDim2.new(0,0,0,50),
    BackgroundColor3=C.Panel,
    BorderSizePixel=0,
    ZIndex=2,
},Win)
-- separator line
N("Frame",{
    Size=UDim2.new(1,0,0,1),
    Position=UDim2.new(0,0,1,-1),
    BackgroundColor3=C.Border,
    BorderSizePixel=0,
    ZIndex=3,
},TabBar)

N("UIListLayout",{
    FillDirection=Enum.FillDirection.Horizontal,
    SortOrder=Enum.SortOrder.LayoutOrder,
    Padding=UDim.new(0,2),
    VerticalAlignment=Enum.VerticalAlignment.Center,
},TabBar)
N("UIPadding",{PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8)},TabBar)

-- ── Content area ─────────────────────────────────────
local ContentArea = N("Frame",{
    Size=UDim2.new(1,0,1,-84),
    Position=UDim2.new(0,0,0,84),
    BackgroundTransparency=1,
    ClipsDescendants=true,
},Win)

-- ═══════════════════════════════════════════════════════
--  TAB SYSTEM
-- ═══════════════════════════════════════════════════════
local tabList    = {}
local activeTab  = nil

local function makeTab(name, icon)
    local displayName = icon and (icon.."  "..name) or name

    local btn = N("TextButton",{
        Size=UDim2.new(0,0,1,-6),
        AutomaticSize=Enum.AutomaticSize.X,
        BackgroundColor3=C.BG,
        BackgroundTransparency=1,
        Text=displayName, TextSize=11,
        TextColor3=C.Sub,
        Font=Enum.Font.GothamBold,
        AutoButtonColor=false,
        BorderSizePixel=0,
        ZIndex=3,
        LayoutOrder=#tabList+1,
    },TabBar)
    N("UIPadding",{PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10)},btn)
    corner(btn,6)

    -- underline indicator
    local line = N("Frame",{
        Size=UDim2.new(0.7,0,0,2),
        Position=UDim2.new(0.15,0,1,-2),
        BackgroundColor3=C.TglOn,
        BorderSizePixel=0,
        Visible=false,
        ZIndex=4,
    },btn)
    corner(line,1)

    local scroll = N("ScrollingFrame",{
        Size=UDim2.new(1,0,1,0),
        BackgroundTransparency=1,
        ScrollBarThickness=3,
        ScrollBarImageColor3=C.Border,
        CanvasSize=UDim2.new(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y,
        Visible=false,
        BorderSizePixel=0,
        ZIndex=2,
    },ContentArea)
    N("UIListLayout",{
        SortOrder=Enum.SortOrder.LayoutOrder,
        Padding=UDim.new(0,5),
    },scroll)
    N("UIPadding",{
        PaddingLeft=UDim.new(0,10), PaddingRight=UDim.new(0,10),
        PaddingTop=UDim.new(0,10),  PaddingBottom=UDim.new(0,14),
    },scroll)

    local tab = {btn=btn,scroll=scroll,line=line}
    table.insert(tabList, tab)

    local function activate()
        if activeTab then
            activeTab.scroll.Visible=false
            activeTab.line.Visible=false
            tw(activeTab.btn,0.12,{TextColor3=C.Sub, BackgroundTransparency=1})
        end
        activeTab      = tab
        scroll.Visible = true
        line.Visible   = true
        tw(btn,0.12,{TextColor3=C.Text, BackgroundTransparency=0.75})
    end

    btn.MouseButton1Click:Connect(activate)
    if #tabList == 1 then activate() end

    return scroll
end

-- ═══════════════════════════════════════════════════════
--  CONTROL WIDGETS
-- ═══════════════════════════════════════════════════════
local rowOrder = 0
local function nextOrder() rowOrder+=1 return rowOrder end

local function makeRow(parent, h)
    local f = N("Frame",{
        Size=UDim2.new(1,0,0,h or 38),
        BackgroundColor3=C.Field,
        BorderSizePixel=0,
        ZIndex=3,
        LayoutOrder=nextOrder(),
    },parent)
    corner(f,7)
    uistroke(f,C.Border,0.65,1)
    return f
end

local function makeSectionLabel(parent, text)
    N("TextLabel",{
        Size=UDim2.new(1,0,0,16),
        BackgroundTransparency=1,
        Text=string.upper(text),
        TextSize=9, Font=Enum.Font.GothamBold,
        TextColor3=C.Sub,
        TextXAlignment=Enum.TextXAlignment.Left,
        ZIndex=3,
        LayoutOrder=nextOrder(),
    },parent)
end

local function makeToggle(parent, name, default, onChange)
    local row   = makeRow(parent)
    local state = default or false

    N("TextLabel",{
        Size=UDim2.new(1,-58,1,0),
        Position=UDim2.new(0,12,0,0),
        BackgroundTransparency=1,
        Text=name, TextSize=12,
        Font=Enum.Font.GothamBold,
        TextColor3=C.Text,
        TextXAlignment=Enum.TextXAlignment.Left,
        ZIndex=4,
    },row)

    -- Pill
    local pill = N("Frame",{
        Size=UDim2.new(0,38,0,20),
        Position=UDim2.new(1,-50,0.5,-10),
        BackgroundColor3=state and C.TglOn or C.TglOff,
        BorderSizePixel=0, ZIndex=4,
    },row)
    corner(pill,10)

    local dot = N("Frame",{
        Size=UDim2.new(0,14,0,14),
        Position=state and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7),
        BackgroundColor3=C.White,
        BorderSizePixel=0, ZIndex=5,
    },pill)
    corner(dot,7)

    local hitbox = N("TextButton",{
        Size=UDim2.new(1,0,1,0),
        BackgroundTransparency=1,
        Text="",AutoButtonColor=false, ZIndex=6,
    },row)

    hitbox.MouseButton1Click:Connect(function()
        state = not state
        tw(pill,0.14,{BackgroundColor3=state and C.TglOn or C.TglOff})
        tw(dot, 0.14,{Position=state and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)})
        onChange(state)
    end)
    hitbox.MouseEnter:Connect(function() tw(row,0.1,{BackgroundColor3=C.Hover}) end)
    hitbox.MouseLeave:Connect(function() tw(row,0.1,{BackgroundColor3=C.Field}) end)
end

local function makeButton(parent, name, onClick)
    local row = makeRow(parent)
    row.BackgroundColor3 = C.Panel

    N("TextLabel",{
        Size=UDim2.new(1,0,1,0),
        BackgroundTransparency=1,
        Text=name, TextSize=12,
        Font=Enum.Font.GothamBold,
        TextColor3=C.Text,
        TextXAlignment=Enum.TextXAlignment.Center,
        ZIndex=4,
    },row)

    local hitbox = N("TextButton",{
        Size=UDim2.new(1,0,1,0),
        BackgroundTransparency=1,
        Text="",AutoButtonColor=false, ZIndex=5,
    },row)
    hitbox.MouseButton1Click:Connect(onClick)
    hitbox.MouseEnter:Connect(function() tw(row,0.1,{BackgroundColor3=C.Hover}) end)
    hitbox.MouseLeave:Connect(function() tw(row,0.1,{BackgroundColor3=C.Panel}) end)
end

local function makeLabel(parent, text)
    N("TextLabel",{
        Size=UDim2.new(1,0,0,20),
        BackgroundTransparency=1,
        Text=text, TextSize=11,
        Font=Enum.Font.Gotham,
        TextColor3=C.Sub,
        TextXAlignment=Enum.TextXAlignment.Center,
        TextWrapped=true,
        ZIndex=3,
        LayoutOrder=nextOrder(),
    },parent)
end

-- ═══════════════════════════════════════════════════════
--  BUILD TABS
-- ═══════════════════════════════════════════════════════

-- ── MAIN ─────────────────────────────────────────────
local mainScroll = makeTab("MAIN","⚔")

makeSectionLabel(mainScroll, "Currency")
makeToggle(mainScroll,"Auto Bonds",false,function(s)
    F.AutoBonds=s notify("Auto Bonds: "..(s and "ON" or "OFF"))
end)

makeSectionLabel(mainScroll, "Items")
makeToggle(mainScroll,"Bring All Item",false,function(s)
    F.BringItems=s notify("Bring All Item: "..(s and "ON" or "OFF"))
end)

makeSectionLabel(mainScroll, "Game")
makeButton(mainScroll,"▶  Auto Escape (WIN)",function()
    F.AutoEscape=true notify("Auto Escape aktif!")
end)
makeButton(mainScroll,"🚂  Auto Drive (Toggle)",function()
    F.AutoDrive=not F.AutoDrive
    if F.AutoDrive then
        startDrive()
        notify("Auto Drive: ON")
    else
        if driveConn then driveConn:Disconnect() driveConn=nil end
        notify("Auto Drive: OFF")
    end
end)

makeSectionLabel(mainScroll, "Movement")
makeToggle(mainScroll,"Speed Boost  [WASD]",false,function(s)
    F.SpeedBoost=s applySpeed() notify("Speed Boost: "..(s and "ON" or "OFF"))
end)
makeToggle(mainScroll,"Fly  [WASD + Space/Ctrl]",false,function(s)
    F.Fly=s
    if s then startFly() else stopFly() end
    notify("Fly: "..(s and "ON" or "OFF"))
end)

-- ── ESP ───────────────────────────────────────────────
rowOrder = 0
local espScroll = makeTab("ESP","👁")

makeSectionLabel(espScroll, "Box ESP — Merah")
makeToggle(espScroll,"ESP Bonds",false,function(s)
    F.ESPBonds=s notify("ESP Bonds: "..(s and "ON" or "OFF"))
end)
makeToggle(espScroll,"ESP Zombie",false,function(s)
    F.ESPZombie=s notify("ESP Zombie: "..(s and "ON" or "OFF"))
end)
makeToggle(espScroll,"ESP Werewolf",false,function(s)
    F.ESPWerewolf=s notify("ESP Werewolf: "..(s and "ON" or "OFF"))
end)
makeToggle(espScroll,"ESP Cowboy",false,function(s)
    F.ESPCowboy=s notify("ESP Cowboy: "..(s and "ON" or "OFF"))
end)

-- ── DEVELOPER ────────────────────────────────────────
rowOrder = 0
local devScroll = makeTab("DEV","👤")

-- spacer atas
N("Frame",{Size=UDim2.new(1,0,0,8),BackgroundTransparency=1,LayoutOrder=nextOrder()},devScroll)

makeLabel(devScroll, "hello guys")
makeLabel(devScroll, "My name is rexx")
makeLabel(devScroll, "And me the developer this script")

N("Frame",{Size=UDim2.new(1,0,0,8),BackgroundTransparency=1,LayoutOrder=nextOrder()},devScroll)
makeLabel(devScroll, "Join my discord server to get")
makeLabel(devScroll, "new script & Information")
N("Frame",{Size=UDim2.new(1,0,0,10),BackgroundTransparency=1,LayoutOrder=nextOrder()},devScroll)

-- Discord button — oval, miring
local discHolder = N("Frame",{
    Size=UDim2.new(1,0,0,52),
    BackgroundTransparency=1,
    LayoutOrder=nextOrder(),
},devScroll)

local discBtn = N("TextButton",{
    Size=UDim2.new(0,220,0,38),
    Position=UDim2.new(0.5,-110,0.5,-19),
    BackgroundColor3=C.Discord,
    Text="⟣  Join Discord  ⟢",
    TextSize=13, Font=Enum.Font.GothamBold,
    TextColor3=C.White,
    AutoButtonColor=false,
    BorderSizePixel=0,
    Rotation=-3,
    ZIndex=4,
},discHolder)
corner(discBtn,20)
uistroke(discBtn,Color3.fromRGB(120,130,255),0.3,1)

discBtn.MouseButton1Click:Connect(function()
    local url = "https://discord.gg/kjVyy4vxR5"
    if setclipboard then
        setclipboard(url)
    elseif syn and syn.clipboard then
        syn.clipboard.set(url)
    end
    notify("Discord link disalin ke clipboard!",3)
end)
discBtn.MouseEnter:Connect(function() tw(discBtn,0.12,{BackgroundColor3=C.DiscHov}) end)
discBtn.MouseLeave:Connect(function() tw(discBtn,0.12,{BackgroundColor3=C.Discord}) end)

-- ── Hotkey INSERT = hide/show ─────────────────────────
UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.Insert then
        Win.Visible = not Win.Visible
    end
end)

-- ── Open notify ──────────────────────────────────────
notify("Pegasus Hub loaded! | Dead Rails", 5)
