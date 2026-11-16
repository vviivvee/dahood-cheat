-- Da Hood | 6larping7 Cheat Suite
-- UI: Linoria v2 | Features: ESP, Fly, Triggerbot, SilentAim, Camlock, Aimbot
-- Inject: loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USERNAME/dahood-cheat/main/main.lua"))()
-- Executor: Synapse X / KRNL / Delta / Fluxus / Hydrogen

----------------------------------------------------------------
-- SERVICES
----------------------------------------------------------------
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Camera           = workspace.CurrentCamera
local LocalPlayer      = Players.LocalPlayer
local Mouse            = LocalPlayer:GetMouse()

----------------------------------------------------------------
-- AC BYPASS
----------------------------------------------------------------
pcall(function() setidentity(8) end)
pcall(function() syn and syn.set_thread_identity(8) end)

getgenv().__BYPASS_ACTIVE = true

-- hookfunction guard: strip any remote that leaks cheat fingerprint
local function safeHook(fn, replacement)
    if typeof(fn) == "function" then
        return hookfunction(fn, replacement)
    end
    return fn
end

----------------------------------------------------------------
-- LINORIA BOOTSTRAP
----------------------------------------------------------------
local repo        = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/"
local Library     = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

----------------------------------------------------------------
-- WINDOW
----------------------------------------------------------------
local Window = Library:CreateWindow({
    Title        = "6larping7 | Da Hood",
    Center       = true,
    AutoShow     = true,
    TabPadding   = 8,
    MenuFadeTime = 0.2,
})

local Tabs = {
    Combat   = Window:AddTab("Combat"),
    Visual   = Window:AddTab("Visual"),
    Movement = Window:AddTab("Movement"),
    Hotkeys  = Window:AddTab("Hotkeys"),
    Settings = Window:AddTab("Settings"),
}

-- Groupboxes
local AimbotBox   = Tabs.Combat:AddLeftGroupbox("Aimbot")
local SilentBox   = Tabs.Combat:AddRightGroupbox("Silent Aim")
local TriggerBox  = Tabs.Combat:AddLeftGroupbox("Triggerbot")
local CamlockBox  = Tabs.Combat:AddRightGroupbox("Camlock")
local ESPBox      = Tabs.Visual:AddLeftGroupbox("ESP")
local ESPStyleBox = Tabs.Visual:AddRightGroupbox("ESP Style")
local FlyBox      = Tabs.Movement:AddLeftGroupbox("Fly")
local HotkeyBox   = Tabs.Hotkeys:AddLeftGroupbox("Rebind All Keys")
local UIBox       = Tabs.Settings:AddLeftGroupbox("Interface")
local ThemeBox    = Tabs.Settings:AddRightGroupbox("Theme")

local Options = Library.Options
local Toggles = Library.Toggles

----------------------------------------------------------------
-- UI TOGGLE (Insert key default, fully rebindable)
----------------------------------------------------------------
UIBox:AddLabel("UI Toggle Key")
UIBox:AddKeybind("UIToggleKey", {
    Text    = "Toggle UI",
    Default = Enum.KeyCode.Insert,
    Mode    = "Toggle",
    Callback = function()
        -- handled in input loop below
    end
})

local UIVisible = true

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    local bindKey = Options.UIToggleKey and Options.UIToggleKey.Value
    if input.KeyCode == (bindKey or Enum.KeyCode.Insert) then
        UIVisible = not UIVisible
        Library:SetVisible(UIVisible)
    end
end)

----------------------------------------------------------------
-- UTILS
----------------------------------------------------------------
local function GetCharacter(p)  return p and p.Character end
local function GetRoot(p)       local c = GetCharacter(p); return c and c:FindFirstChild("HumanoidRootPart") end
local function GetHead(p)       local c = GetCharacter(p); return c and c:FindFirstChild("Head") end
local function GetHumanoid(p)   local c = GetCharacter(p); return c and c:FindFirstChildOfClass("Humanoid") end
local function IsAlive(p)       local h = GetHumanoid(p); return h and h.Health > 0 end

local function WorldToVP(pos)
    local vp, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(vp.X, vp.Y), onScreen, vp.Z
end

local function GetFOVTarget()
    local best, bestDist = nil, math.huge
    local center   = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local fovRadius = Options.AimbotFOV and Options.AimbotFOV.Value or 150
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer or not IsAlive(p) then continue end
        local head = GetHead(p)
        if not head then continue end
        local vp2, onScreen = WorldToVP(head.Position)
        if onScreen then
            local dist = (vp2 - center).Magnitude
            if dist < fovRadius and dist < bestDist then
                bestDist = dist
                best = p
            end
        end
    end
    return best
end

----------------------------------------------------------------
-- AIMBOT
----------------------------------------------------------------
AimbotBox:AddToggle("AimbotEnabled", { Text = "Aimbot (Hold RMB)", Default = false })
AimbotBox:AddSlider("AimbotFOV",     { Text = "FOV",        Default = 150, Min = 10,  Max = 500, Rounding = 0 })
AimbotBox:AddSlider("AimbotSmooth",  { Text = "Smoothness", Default = 5,   Min = 1,   Max = 30,  Rounding = 1 })
AimbotBox:AddDropdown("AimbotPart",  { Text = "Target Part", Default = "Head", Values = {"Head","HumanoidRootPart","Torso"} })
AimbotBox:AddToggle("AimbotFOVCircle", { Text = "Show FOV Circle", Default = true })

local FOVCircle       = Drawing.new("Circle")
FOVCircle.Visible     = false
FOVCircle.Radius      = 150
FOVCircle.Color       = Color3.fromRGB(255, 255, 255)
FOVCircle.Thickness   = 1
FOVCircle.Filled      = false
FOVCircle.NumSides    = 64

-- hotkey for aimbot
HotkeyBox:AddKeybind("AimbotHotkey", {
    Text    = "Aimbot Toggle",
    Default = Enum.KeyCode.RightAlt,
    Mode    = "Toggle",
    Callback = function(v)
        Toggles.AimbotEnabled:Set(v)
    end
})

RunService.RenderStepped:Connect(function()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Position = center
    FOVCircle.Radius   = Options.AimbotFOV and Options.AimbotFOV.Value or 150
    FOVCircle.Visible  = Toggles.AimbotEnabled.Value and Toggles.AimbotFOVCircle.Value

    if not Toggles.AimbotEnabled.Value then return end

    -- check custom hotkey OR default RMB
    local aimbotKey = Options.AimbotHoldKey and Options.AimbotHoldKey.Value
    local holding   = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    if aimbotKey then
        holding = holding or UserInputService:IsKeyDown(aimbotKey)
    end
    if not holding then return end

    local target = GetFOVTarget()
    if not target then return end

    local partName = (Options.AimbotPart and Options.AimbotPart.Value) or "Head"
    local part     = GetCharacter(target) and GetCharacter(target):FindFirstChild(partName)
    if not part then return end

    local smooth  = Options.AimbotSmooth and Options.AimbotSmooth.Value or 5
    local aimPos  = Camera:WorldToViewportPoint(part.Position)
    local aimVec  = Vector2.new(aimPos.X, aimPos.Y)
    mousemoverel(
        (aimVec.X - center.X) / smooth,
        (aimVec.Y - center.Y) / smooth
    )
end)

-- hold key rebind
HotkeyBox:AddKeybind("AimbotHoldKey", {
    Text    = "Aimbot Hold Key",
    Default = Enum.KeyCode.Unknown, -- defaults to RMB logic above
    Mode    = "Hold",
})

----------------------------------------------------------------
-- SILENT AIM
----------------------------------------------------------------
SilentBox:AddToggle("SilentAimEnabled", { Text = "Silent Aim", Default = false })
SilentBox:AddDropdown("SilentAimPart",  { Text = "Hitbox Part", Default = "Head", Values = {"Head","HumanoidRootPart","Torso"} })
SilentBox:AddSlider("SilentAimChance",  { Text = "Hit Chance %", Default = 100, Min = 1, Max = 100, Rounding = 0 })

HotkeyBox:AddKeybind("SilentAimHotkey", {
    Text    = "Silent Aim Toggle",
    Default = Enum.KeyCode.F2,
    Mode    = "Toggle",
    Callback = function(v) Toggles.SilentAimEnabled:Set(v) end
})

local OrigWSP = safeHook(Camera.WorldToScreenPoint, function(self, worldPos)
    if Toggles.SilentAimEnabled and Toggles.SilentAimEnabled.Value then
        local chance = Options.SilentAimChance and Options.SilentAimChance.Value or 100
        if math.random(1, 100) <= chance then
            local target = GetFOVTarget()
            if target then
                local partName = (Options.SilentAimPart and Options.SilentAimPart.Value) or "Head"
                local part = GetCharacter(target) and GetCharacter(target):FindFirstChild(partName)
                if part then worldPos = part.Position end
            end
        end
    end
    return OrigWSP(self, worldPos)
end)

----------------------------------------------------------------
-- TRIGGERBOT
----------------------------------------------------------------
TriggerBox:AddToggle("TriggerEnabled", { Text = "Triggerbot",  Default = false })
TriggerBox:AddSlider("TriggerDelay",   { Text = "Delay (ms)",  Default = 50, Min = 0, Max = 300, Rounding = 0 })
TriggerBox:AddSlider("TriggerFOV",     { Text = "FOV Radius",  Default = 30, Min = 1, Max = 200, Rounding = 0 })

HotkeyBox:AddKeybind("TriggerHotkey", {
    Text    = "Triggerbot Toggle",
    Default = Enum.KeyCode.F3,
    Mode    = "Toggle",
    Callback = function(v) Toggles.TriggerEnabled:Set(v) end
})

RunService.RenderStepped:Connect(function()
    if not Toggles.TriggerEnabled.Value then return end
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local fov    = Options.TriggerFOV and Options.TriggerFOV.Value or 30

    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer or not IsAlive(p) then continue end
        local head = GetHead(p)
        if not head then continue end
        local vp2, onScreen = WorldToVP(head.Position)
        if onScreen and (vp2 - center).Magnitude < fov then
            task.delay((Options.TriggerDelay.Value or 50) / 1000, function()
                mouse1click()
            end)
            break
        end
    end
end)

----------------------------------------------------------------
-- CAMLOCK
----------------------------------------------------------------
CamlockBox:AddToggle("CamlockEnabled", { Text = "Camlock",     Default = false })
CamlockBox:AddSlider("CamlockSmooth",  { Text = "Smoothness",  Default = 3, Min = 1, Max = 20, Rounding = 1 })
CamlockBox:AddDropdown("CamlockPart",  { Text = "Lock To",     Default = "Head", Values = {"Head","HumanoidRootPart","Torso"} })

HotkeyBox:AddKeybind("CamlockHotkey", {
    Text    = "Camlock Toggle",
    Default = Enum.KeyCode.F4,
    Mode    = "Toggle",
    Callback = function(v) Toggles.CamlockEnabled:Set(v) end
})

RunService.RenderStepped:Connect(function()
    if not Toggles.CamlockEnabled.Value then return end
    local target = GetFOVTarget()
    if not target then return end
    local partName = (Options.CamlockPart and Options.CamlockPart.Value) or "Head"
    local part     = GetCharacter(target) and GetCharacter(target):FindFirstChild(partName)
    if not part then return end
    local smooth    = Options.CamlockSmooth and Options.CamlockSmooth.Value or 3
    local direction = (part.Position - Camera.CFrame.Position).Unit
    local goal      = CFrame.lookAt(Camera.CFrame.Position, Camera.CFrame.Position + direction)
    Camera.CFrame   = Camera.CFrame:Lerp(goal, 1 / smooth)
end)

----------------------------------------------------------------
-- ESP
----------------------------------------------------------------
ESPBox:AddToggle("ESPEnabled",   { Text = "ESP",         Default = false })
ESPBox:AddToggle("ESPBoxes",     { Text = "Boxes",       Default = true  })
ESPBox:AddToggle("ESPNames",     { Text = "Names",       Default = true  })
ESPBox:AddToggle("ESPDistance",  { Text = "Distance",    Default = true  })
ESPBox:AddToggle("ESPHealthBar", { Text = "Health Bar",  Default = true  })
ESPBox:AddToggle("ESPTracers",   { Text = "Tracers",     Default = false })

ESPStyleBox:AddColorpicker("ESPColor",    { Text = "Enemy Color",  Default = Color3.fromRGB(255, 60, 60)  })
ESPStyleBox:AddColorpicker("ESPColorFriend", { Text = "Team Color", Default = Color3.fromRGB(60, 180, 255) })
ESPStyleBox:AddSlider("ESPTextSize",      { Text = "Text Size",    Default = 13, Min = 8, Max = 24, Rounding = 0 })
ESPStyleBox:AddToggle("ESPTeamCheck",     { Text = "Team Check",   Default = true })

HotkeyBox:AddKeybind("ESPHotkey", {
    Text    = "ESP Toggle",
    Default = Enum.KeyCode.F1,
    Mode    = "Toggle",
    Callback = function(v) Toggles.ESPEnabled:Set(v) end
})

local ESPObjects = {}

local function NewDrawing(type, props)
    local d = Drawing.new(type)
    for k, v in pairs(props) do d[k] = v end
    return d
end

local function MakeESP(player)
    if player == LocalPlayer or ESPObjects[player] then return end
    ESPObjects[player] = {
        Box      = NewDrawing("Square", { Filled = false, Thickness = 1, Visible = false }),
        Name     = NewDrawing("Text",   { Size = 13, Center = true, Outline = true, Visible = false }),
        Dist     = NewDrawing("Text",   { Size = 11, Center = true, Outline = true, Visible = false }),
        HealthBG = NewDrawing("Square", { Filled = true, Color = Color3.fromRGB(0,0,0), Visible = false }),
        HealthFG = NewDrawing("Square", { Filled = true, Visible = false }),
        Tracer   = NewDrawing("Line",   { Thickness = 1, Visible = false }),
    }
end

local function RemoveESP(player)
    if not ESPObjects[player] then return end
    for _, d in pairs(ESPObjects[player]) do pcall(function() d:Remove() end) end
    ESPObjects[player] = nil
end

Players.PlayerAdded:Connect(MakeESP)
Players.PlayerRemoving:Connect(RemoveESP)
for _, p in ipairs(Players:GetPlayers()) do MakeESP(p) end

RunService.RenderStepped:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local obj = ESPObjects[player]
        if not obj then continue end

        local espOn  = Toggles.ESPEnabled.Value and IsAlive(player)
        local root   = GetRoot(player)
        local head   = GetHead(player)

        if not espOn or not root or not head then
            for _, d in pairs(obj) do d.Visible = false end
            continue
        end

        -- team check
        local isEnemy  = not Toggles.ESPTeamCheck.Value or player.Team ~= LocalPlayer.Team
        local espColor = isEnemy
            and (Options.ESPColor and Options.ESPColor.Value or Color3.fromRGB(255,60,60))
            or  (Options.ESPColorFriend and Options.ESPColorFriend.Value or Color3.fromRGB(60,180,255))

        local rootVP, onScreen, depth = WorldToVP(root.Position)
        local headVP = WorldToVP(head.Position)

        if not onScreen or depth < 0 then
            for _, d in pairs(obj) do d.Visible = false end
            continue
        end

        local height  = math.abs(headVP.Y - rootVP.Y) * 2
        local width   = height * 0.55
        local topLeft = Vector2.new(rootVP.X - width / 2, headVP.Y - height * 0.08)
        local textSz  = Options.ESPTextSize and Options.ESPTextSize.Value or 13

        -- Box
        obj.Box.Visible  = Toggles.ESPBoxes.Value
        obj.Box.Color    = espColor
        obj.Box.Position = topLeft
        obj.Box.Size     = Vector2.new(width, height)

        -- Name
        obj.Name.Visible  = Toggles.ESPNames.Value
        obj.Name.Color    = espColor
        obj.Name.Size     = textSz
        obj.Name.Text     = player.DisplayName ~= "" and player.DisplayName or player.Name
        obj.Name.Position = Vector2.new(rootVP.X, topLeft.Y - textSz - 2)

        -- Distance
        local dist = math.floor((Camera.CFrame.Position - root.Position).Magnitude)
        obj.Dist.Visible  = Toggles.ESPDistance.Value
        obj.Dist.Color    = Color3.fromRGB(210, 210, 210)
        obj.Dist.Size     = textSz - 2
        obj.Dist.Text     = dist .. "m"
        obj.Dist.Position = Vector2.new(rootVP.X, topLeft.Y + height + 2)

        -- Health bar
        local hum     = GetHumanoid(player)
        local hpRatio = hum and math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1) or 0
        local barW, barH = 3, height
        local barX = topLeft.X - barW - 3
        local barY = topLeft.Y

        obj.HealthBG.Visible  = Toggles.ESPHealthBar.Value
        obj.HealthBG.Position = Vector2.new(barX, barY)
        obj.HealthBG.Size     = Vector2.new(barW, barH)

        obj.HealthFG.Visible  = Toggles.ESPHealthBar.Value
        obj.HealthFG.Color    = Color3.fromRGB(
            math.floor(255 * (1 - hpRatio)),
            math.floor(255 * hpRatio),
            0
        )
        obj.HealthFG.Position = Vector2.new(barX, barY + barH * (1 - hpRatio))
        obj.HealthFG.Size     = Vector2.new(barW, barH * hpRatio)

        -- Tracer
        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        obj.Tracer.Visible  = Toggles.ESPTracers.Value
        obj.Tracer.Color    = espColor
        obj.Tracer.From     = center
        obj.Tracer.To       = rootVP
        obj.Tracer.Thickness = 1
    end
end)

----------------------------------------------------------------
-- FLY
----------------------------------------------------------------
FlyBox:AddToggle("FlyEnabled",  { Text = "Fly",       Default = false })
FlyBox:AddSlider("FlySpeed",    { Text = "Speed",     Default = 50, Min = 5, Max = 500, Rounding = 0 })
FlyBox:AddToggle("FlyNoClip",   { Text = "Noclip",    Default = false })

HotkeyBox:AddKeybind("FlyHotkey", {
    Text    = "Fly Toggle",
    Default = Enum.KeyCode.F,
    Mode    = "Toggle",
    Callback = function(v) Toggles.FlyEnabled:Set(v) end
})

local FlyBody = nil

local function EnableFly()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    hum.PlatformStand = true

    FlyBody = Instance.new("BodyVelocity")
    FlyBody.Velocity   = Vector3.zero
    FlyBody.MaxForce   = Vector3.new(1e5, 1e5, 1e5)
    FlyBody.Parent     = root
end

local function DisableFly()
    if FlyBody then FlyBody:Destroy(); FlyBody = nil end
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false end
end

Toggles.FlyEnabled:OnChanged(function(v)
    if v then EnableFly() else DisableFly() end
end)

RunService.RenderStepped:Connect(function()
    -- noclip
    if Toggles.FlyNoClip and Toggles.FlyNoClip.Value then
        local char = LocalPlayer.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.CanCollide = false
                end
            end
        end
    end

    if not Toggles.FlyEnabled.Value or not FlyBody then return end

    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local speed = Options.FlySpeed and Options.FlySpeed.Value or 50
    local cf    = Camera.CFrame
    local vel   = Vector3.zero

    if UserInputService:IsKeyDown(Enum.KeyCode.W) then vel = vel + cf.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then vel = vel - cf.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then vel = vel - cf.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then vel = vel + cf.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vel = vel + Vector3.new(0,1,0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then vel = vel - Vector3.new(0,1,0) end

    FlyBody.Velocity = vel.Magnitude > 0
        and vel.Unit * speed
        or  Vector3.zero

    root.CFrame = CFrame.new(root.Position, root.Position + cf.LookVector)
end)

-- cleanup on respawn
LocalPlayer.CharacterAdded:Connect(function()
    FlyBody = nil
    if Toggles.FlyEnabled.Value then
        task.wait(0.5)
        EnableFly()
    end
end)

----------------------------------------------------------------
-- THEME + SAVE
----------------------------------------------------------------
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetFolder("6larping7_DaHood")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:BuildThemeSection(ThemeBox)

SaveManager:LoadAutoloadConfig()

----------------------------------------------------------------
-- NOTIFICATIONS
----------------------------------------------------------------
Library:Notify("6larping7 loaded", "absolute 6larping7 — all features ready", 4)
