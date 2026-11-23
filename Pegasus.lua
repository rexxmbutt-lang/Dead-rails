-- Pegasus Hub | Dead Rails Script
-- Developer: rexx script
-- Library: https://github.com/rexxmbutt-lang/Libraary-script-roblox
-- Executor: Delta / Codex / Arceus X / Vega X / Trigon (Android compatible)

local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UserInputService= game:GetService("UserInputService")
local Workspace       = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local lp  = Players.LocalPlayer
local char = lp.Character or lp.CharacterAdded:Wait()
local hum  = char:WaitForChild("Humanoid")
local hrp  = char:WaitForChild("HumanoidRootPart")

-- ══════════════════════════════════════════
--  Load Library
-- ══════════════════════════════════════════
local Library
local ok, err = pcall(function()
    Library = loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/rexxmbutt-lang/Libraary-script-roblox/main/Library.lua"
    ))()
end)

if not ok then
    -- Fallback: minimal UI via Drawing jika library gagal
    warn("[Pegasus Hub] Library gagal dimuat: " .. tostring(err))
    warn("[Pegasus Hub] Pastikan executor mendukung HttpGet dan repo library aktif.")
    return
end

-- ══════════════════════════════════════════
--  State flags
-- ══════════════════════════════════════════
local Flags = {
    AutoBonds       = false,
    BringAllItems   = false,
    AutoEscape      = false,
    AutoDrive       = false,
    SpeedBoost      = false,
    Fly             = false,
    ESPBonds        = false,
    ESPZombie       = false,
    ESPWerewolf     = false,
    ESPCowboy       = false,
}

local DEFAULT_SPEED   = 16
local BOOST_SPEED     = 80
local FLY_SPEED       = 60
local ESP_COLOR       = Color3.fromRGB(255, 0, 0)

-- ══════════════════════════════════════════
--  Utility helpers
-- ══════════════════════════════════════════
local function safeGetDescendants(parent)
    local ok2, result = pcall(function() return parent:GetDescendants() end)
    return ok2 and result or {}
end

local function getWorkspaceChildren()
    local ok2, result = pcall(function() return Workspace:GetDescendants() end)
    return ok2 and result or {}
end

local function refreshChar()
    char = lp.Character or lp.CharacterAdded:Wait()
    hum  = char:WaitForChild("Humanoid")
    hrp  = char:WaitForChild("HumanoidRootPart")
end

lp.CharacterAdded:Connect(refreshChar)

-- ══════════════════════════════════════════
--  MAIN FEATURES
-- ══════════════════════════════════════════

-- ── Auto Bonds ──────────────────────────────
-- Bonds = collectible currency di Dead Rails (Gold, Coin, Bond)
local function autoBonds()
    if not Flags.AutoBonds then return end
    for _, v in ipairs(getWorkspaceChildren()) do
        local nameLower = v.Name:lower()
        if v:IsA("BasePart") or v:IsA("Model") then
            if nameLower:find("bond") or nameLower:find("gold") or nameLower:find("coin") or nameLower:find("cash") then
                local part = v:IsA("Model") and v.PrimaryPart or v
                if part then
                    -- Teleport ke bond lalu kembali
                    local origin = hrp.CFrame
                    hrp.CFrame = part.CFrame + Vector3.new(0, 2, 0)
                    task.wait(0.05)
                    hrp.CFrame = origin
                end
            end
        end
    end
end

-- ── Bring All Items ─────────────────────────
-- Lempar semua item map ke posisi player
local function bringAllItems()
    if not Flags.BringAllItems then return end
    for _, v in ipairs(getWorkspaceChildren()) do
        if v:IsA("BasePart") and v.CanCollide == false and not v.Anchored then
            local ok3 = pcall(function()
                v.CFrame = hrp.CFrame + Vector3.new(math.random(-3,3), 1, math.random(-3,3))
            end)
        end
    end
end

-- ── Auto Escape ─────────────────────────────
-- Dead Rails: win trigger lewat remote "EscapeGame" / "WinGame" / "TrainEscaped"
local function autoEscape()
    if not Flags.AutoEscape then return end
    -- Coba semua remote event yang mungkin
    local remoteNames = {"EscapeGame","WinGame","TrainEscaped","Escaped","Victory","FinishGame"}
    for _, name in ipairs(remoteNames) do
        local remote = ReplicatedStorage:FindFirstChild(name, true)
            or Workspace:FindFirstChild(name, true)
        if remote and remote:IsA("RemoteEvent") then
            pcall(function() remote:FireServer() end)
        end
        if remote and remote:IsA("RemoteFunction") then
            pcall(function() remote:InvokeServer() end)
        end
    end
    Flags.AutoEscape = false  -- fire sekali saja
end

-- ── Auto Drive ──────────────────────────────
-- Duduk di seat kereta dan aktifkan throttle
local function autoDrive()
    if not Flags.AutoDrive then return end
    local trainSeats = {}
    for _, v in ipairs(getWorkspaceChildren()) do
        if v:IsA("Seat") or v:IsA("VehicleSeat") then
            local nameLower = v.Name:lower()
            if nameLower:find("driver") or nameLower:find("seat") or nameLower:find("cabin") or nameLower:find("front") then
                table.insert(trainSeats, v)
            end
        end
    end
    if #trainSeats > 0 then
        local seat = trainSeats[1]
        pcall(function()
            seat:Sit(hum)
        end)
        -- Throttle ke depan jika VehicleSeat
        if seat:IsA("VehicleSeat") then
            task.spawn(function()
                while Flags.AutoDrive and task.wait(0.1) do
                    seat.Throttle = 1
                    seat.Steer    = 0
                end
            end)
        end
    end
end

-- ── Speed Boost ─────────────────────────────
local function applySpeed()
    pcall(function()
        hum.WalkSpeed = Flags.SpeedBoost and BOOST_SPEED or DEFAULT_SPEED
    end)
end

-- ── Fly ─────────────────────────────────────
local flyPart   = nil
local flyConn   = nil
local flyBConn  = nil

local function startFly()
    if flyPart then return end
    flyPart = Instance.new("BodyVelocity")
    flyPart.Velocity       = Vector3.zero
    flyPart.MaxForce       = Vector3.new(1e5, 1e5, 1e5)
    flyPart.Parent         = hrp

    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    bg.D         = 100
    bg.Parent    = hrp

    -- Matikan gravity efek
    local function noFall()
        while Flags.Fly and task.wait() do
            if hrp then
                hrp.Velocity = Vector3.new(hrp.Velocity.X, 0, hrp.Velocity.Z)
            end
        end
    end

    flyConn = RunService.RenderStepped:Connect(function()
        if not Flags.Fly then
            flyPart:Destroy()
            flyPart = nil
            bg:Destroy()
            if flyConn then flyConn:Disconnect() flyConn = nil end
            return
        end
        local cam = Workspace.CurrentCamera
        local mv  = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then mv = mv + cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then mv = mv - cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then mv = mv - cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then mv = mv + cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then mv = mv + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then mv = mv - Vector3.new(0,1,0) end
        flyPart.Velocity = mv.Magnitude > 0 and mv.Unit * FLY_SPEED or Vector3.zero
        bg.CFrame = cam.CFrame
        hum:ChangeState(Enum.HumanoidStateType.Physics)
    end)
end

local function stopFly()
    Flags.Fly = false
    if flyPart then
        flyPart:Destroy()
        flyPart = nil
    end
    if flyConn then flyConn:Disconnect() flyConn = nil end
    pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
end

-- ══════════════════════════════════════════
--  ESP SYSTEM (Box, Merah, DrawingLib)
-- ══════════════════════════════════════════
local espObjects = {}  -- [model] = {box={}, label}

local ESP_TAG_MAP = {
    bond      = function(v) return Flags.ESPBonds     and (v.Name:lower():find("bond") or v.Name:lower():find("gold") or v.Name:lower():find("coin")) end,
    zombie    = function(v) return Flags.ESPZombie    and v.Name:lower():find("zombie") end,
    werewolf  = function(v) return Flags.ESPWerewolf  and v.Name:lower():find("werewolf") end,
    cowboy    = function(v) return Flags.ESPCowboy    and (v.Name:lower():find("cowboy") or v.Name:lower():find("outlaw") or v.Name:lower():find("bandit")) end,
}

local function newBox()
    local lines = {}
    for i = 1, 4 do
        local l = Drawing.new("Line")
        l.Color     = ESP_COLOR
        l.Thickness = 1.5
        l.Visible   = false
        lines[i] = l
    end
    return lines
end

local function newLabel()
    local lbl = Drawing.new("Text")
    lbl.Color    = ESP_COLOR
    lbl.Size     = 13
    lbl.Outline  = true
    lbl.Visible  = false
    return lbl
end

local function destroyESP(entry)
    if entry then
        for _, l in ipairs(entry.box) do l:Remove() end
        if entry.label then entry.label:Remove() end
    end
end

local function worldToScreen(pos)
    local cam = Workspace.CurrentCamera
    local sp, vis = cam:WorldToViewportPoint(pos)
    return Vector2.new(sp.X, sp.Y), sp.Z > 0 and vis
end

local function drawBox(lines, screenPos, size)
    -- screenPos = top-left corner 2D, size = {w, h}
    local x, y = screenPos.X, screenPos.Y
    local w, h = size.X, size.Y
    -- Top, Bottom, Left, Right
    lines[1].From = Vector2.new(x, y)         lines[1].To = Vector2.new(x+w, y)
    lines[2].From = Vector2.new(x, y+h)       lines[2].To = Vector2.new(x+w, y+h)
    lines[3].From = Vector2.new(x, y)         lines[3].To = Vector2.new(x, y+h)
    lines[4].From = Vector2.new(x+w, y)       lines[4].To = Vector2.new(x+w, y+h)
    for _, l in ipairs(lines) do l.Visible = true end
end

local function hideBox(lines)
    for _, l in ipairs(lines) do l.Visible = false end
end

RunService.RenderStepped:Connect(function()
    local cam     = Workspace.CurrentCamera
    local anyESP  = Flags.ESPBonds or Flags.ESPZombie or Flags.ESPWerewolf or Flags.ESPCowboy

    -- Bersihkan entry yang modelnya udah hilang
    for model, entry in pairs(espObjects) do
        if not model or not model.Parent then
            destroyESP(entry)
            espObjects[model] = nil
        end
    end

    if not anyESP then
        for model, entry in pairs(espObjects) do
            destroyESP(entry)
            espObjects[model] = nil
        end
        return
    end

    local seen = {}

    for _, v in ipairs(getWorkspaceChildren()) do
        local matched = false
        local tagName = ""
        for tag, checkFn in pairs(ESP_TAG_MAP) do
            if checkFn(v) then
                matched = true
                tagName = tag
                break
            end
        end

        if matched then
            local targetModel = v:IsA("Model") and v or v.Parent
            if targetModel and not seen[targetModel] then
                seen[targetModel] = true

                -- Ambil/buat ESP entry
                if not espObjects[targetModel] then
                    espObjects[targetModel] = {
                        box   = newBox(),
                        label = newLabel()
                    }
                end
                local entry = espObjects[targetModel]

                -- Hitung bounding box 3D → screen box
                local ok4, bbcf, bbsize = pcall(function()
                    return targetModel:GetBoundingBox()
                end)

                if ok4 and bbcf and bbsize then
                    local topCenter    = bbcf.Position + Vector3.new(0, bbsize.Y / 2, 0)
                    local bottomCenter = bbcf.Position - Vector3.new(0, bbsize.Y / 2, 0)

                    local topSP, topVis    = worldToScreen(topCenter)
                    local bottomSP, botVis = worldToScreen(bottomCenter)

                    if topVis or botVis then
                        local screenH  = math.abs(topSP.Y - bottomSP.Y)
                        local screenW  = screenH * 0.6
                        local topLeft  = Vector2.new(topSP.X - screenW / 2, math.min(topSP.Y, bottomSP.Y))

                        drawBox(entry.box, topLeft, Vector2.new(screenW, screenH))

                        -- Label nama
                        local distVal = math.floor((bbcf.Position - hrp.Position).Magnitude)
                        entry.label.Text     = "[" .. tagName:upper() .. "] " .. targetModel.Name .. " | " .. distVal .. "m"
                        entry.label.Position = Vector2.new(topLeft.X, topLeft.Y - 16)
                        entry.label.Visible  = true
                    else
                        hideBox(entry.box)
                        entry.label.Visible = false
                    end
                else
                    hideBox(entry.box)
                    entry.label.Visible = false
                end
            end
        end
    end

    -- Hide ESP untuk model yang tidak matched di frame ini
    for model, entry in pairs(espObjects) do
        if not seen[model] then
            hideBox(entry.box)
            entry.label.Visible = false
        end
    end
end)

-- ══════════════════════════════════════════
--  MAIN LOOP (auto-bonds, bring, escape)
-- ══════════════════════════════════════════
task.spawn(function()
    while task.wait(0.5) do
        if Flags.AutoBonds   then autoBonds()   end
        if Flags.BringAllItems then bringAllItems() end
        if Flags.AutoEscape  then autoEscape()  end
    end
end)

-- Auto drive trigger sekali saat toggle on
-- Speed diterapkan via toggle callback

-- ══════════════════════════════════════════
--  UI via Library
-- ══════════════════════════════════════════
local Window = Library:CreateWindow({
    Title   = "Pegasus Hub",
    SubTitle = "Dead Rails",
    Theme   = "Dark",
})

-- ── Tab: MAIN ───────────────────────────────
local MainTab = Window:CreateTab("MAIN")

MainTab:CreateToggle({
    Name     = "Auto Bonds",
    Default  = false,
    Callback = function(state)
        Flags.AutoBonds = state
    end,
})

MainTab:CreateToggle({
    Name     = "Bring All Item",
    Default  = false,
    Callback = function(state)
        Flags.BringAllItems = state
    end,
})

MainTab:CreateButton({
    Name     = "Auto Escape",
    Callback = function()
        Flags.AutoEscape = true
        autoEscape()
    end,
})

MainTab:CreateButton({
    Name     = "Auto Drive",
    Callback = function()
        Flags.AutoDrive = not Flags.AutoDrive
        if Flags.AutoDrive then autoDrive() end
    end,
})

MainTab:CreateToggle({
    Name     = "Speed Boost",
    Default  = false,
    Callback = function(state)
        Flags.SpeedBoost = state
        applySpeed()
    end,
})

MainTab:CreateToggle({
    Name     = "Fly",
    Default  = false,
    Callback = function(state)
        Flags.Fly = state
        if state then
            startFly()
        else
            stopFly()
        end
    end,
})

-- ── Tab: ESP ────────────────────────────────
local EspTab = Window:CreateTab("ESP")

EspTab:CreateToggle({
    Name     = "ESP Bonds",
    Default  = false,
    Callback = function(state) Flags.ESPBonds = state end,
})

EspTab:CreateToggle({
    Name     = "ESP Zombie",
    Default  = false,
    Callback = function(state) Flags.ESPZombie = state end,
})

EspTab:CreateToggle({
    Name     = "ESP Werewolf",
    Default  = false,
    Callback = function(state) Flags.ESPWerewolf = state end,
})

EspTab:CreateToggle({
    Name     = "ESP Cowboy",
    Default  = false,
    Callback = function(state) Flags.ESPCowboy = state end,
})

-- ── Tab: DEVELOPER ──────────────────────────
local DevTab = Window:CreateTab("DEVELOPER")

DevTab:CreateLabel({
    Text  = "hello guys",
    Align = "Center",
})

DevTab:CreateLabel({
    Text  = "My name is rexx",
    Align = "Center",
})

DevTab:CreateLabel({
    Text  = "And me the developer this script",
    Align = "Center",
})

DevTab:CreateLabel({
    Text  = "Join my discord server to get new script & Information",
    Align = "Center",
})

DevTab:CreateButton({
    Name     = "⬡  Join Discord  ⬡",   -- oval miring via teks dekoratif
    Callback = function()
        -- Buka URL Discord via setclipboard (executor support)
        local url = "https://discord.gg/kjVyy4vxR5"
        if setclipboard then
            setclipboard(url)
            Library:Notify("Discord link disalin ke clipboard!", 3)
        elseif syn and syn.clipboard then
            syn.clipboard.set(url)
        end
    end,
})

-- ══════════════════════════════════════════
--  Notify: Hub loaded
-- ══════════════════════════════════════════
Library:Notify("Pegasus Hub loaded! | Dead Rails", 5)
