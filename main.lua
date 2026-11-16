local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera           = workspace.CurrentCamera
local LocalPlayer      = Players.LocalPlayer

pcall(function() setidentity(8) end)
pcall(function() syn and syn.set_thread_identity(8) end)
getgenv().__BYPASS_ACTIVE = true
getgenv().__cheatloaded   = nil
getgenv().__scriptname    = nil

RunService.Heartbeat:Connect(function()
    pcall(function() setidentity(8) end)
end)

local function safeHook(fn, cb)
    if type(fn) == "function" then return hookfunction(fn, cb) end
    return fn
end

local repo         = "https://cdn.jsdelivr.net/gh/violin-suzutsuki/LinoriaLib@main/"
local Library      = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title        = "Kori | Da Hood",
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
    Config   = Window:AddTab("Config"),
    Settings = Window:AddTab("Settings"),
}

local AimbotBox   = Tabs.Combat:AddLeftGroupbox("Aimbot")
local SilentBox   = Tabs.Combat:AddRightGroupbox("Silent Aim")
local TriggerBox  = Tabs.Combat:AddLeftGroupbox("Triggerbot")
local CamlockBox  = Tabs.Combat:AddRightGroupbox("Camlock")
local ESPBox      = Tabs.Visual:AddLeftGroupbox("ESP")
local ESPStyleBox = Tabs.Visual:AddRightGroupbox("ESP Style")
local FlyBox      = Tabs.Movement:AddLeftGroupbox("Fly")
local HotkeyBox   = Tabs.Hotkeys:AddLeftGroupbox("Rebind Keys")
local ConfigBox   = Tabs.Config:AddLeftGroupbox("Config Manager")
local UIBox       = Tabs.Settings:AddLeftGroupbox("Interface")
local ThemeBox    = Tabs.Settings:AddRightGroupbox("Theme")

local Options = Library.Options
local Toggles = Library.Toggles

local function Notify(title, body, duration)
    if Toggles.SilentMode and Toggles.SilentMode.Value then return end
    Library:Notify(title, body, duration or 3)
end

local UIVisible = true
UIBox:AddLabel("UI Toggle Key (default: Left Alt)")
UIBox:AddKeybind("UIToggleKey", {
    Text    = "Toggle UI",
    Default = Enum.KeyCode.LeftAlt,
    Mode    = "Toggle",
})
UIBox:AddToggle("SilentMode", {
    Text    = "Silent Mode (no notifications)",
    Default = false,
})
UIBox:AddToggle("GlobalTeamCheck", { Text = "Global Team Check", Default = true })

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    local key = (Options.UIToggleKey and Options.UIToggleKey.Value) or Enum.KeyCode.LeftAlt
    if input.KeyCode == key then
        UIVisible = not UIVisible
        Library:SetVisible(UIVisible)
    end
end)

local function GetCharacter(p) return p and p.Character end
local function GetPart(p, name) local c = GetCharacter(p); return c and c:FindFirstChild(name) end
local function GetRoot(p) return GetPart(p, "HumanoidRootPart") end
local function GetHead(p) return GetPart(p, "Head") end
local function GetHumanoid(p) local c = GetCharacter(p); return c and c:FindFirstChildOfClass("Humanoid") end
local function IsAlive(p) local h = GetHumanoid(p); return h and h.Health > 0 end
local function GetCenter() return Vector2.new(Camera.ViewportSize.X * .5, Camera.ViewportSize.Y * .5) end
local function W2S(pos) local vp, vis = Camera:WorldToViewportPoint(pos); return Vector2.new(vp.X, vp.Y), vis, vp.Z end
local function Predict(root, frames)
    if not root then return nil end
    return root.Position + root.AssemblyLinearVelocity * (frames / 60)
end

local function GetFOVTarget(fovRadius)
    fovRadius = fovRadius or (Options.AimbotFOV and Options.AimbotFOV.Value) or 150
    local best, bestDist = nil, math.huge
    local center = GetCenter()
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer or not IsAlive(p) then continue end
        if Toggles.GlobalTeamCheck and Toggles.GlobalTeamCheck.Value then
            if p.Team == LocalPlayer.Team then continue end
        end
        local head = GetHead(p); if not head then continue end
        local vp, onScreen = W2S(head.Position)
        if onScreen then
            local d = (vp - center).Magnitude
            if d < fovRadius and d < bestDist then bestDist, best = d, p end
        end
    end
    return best, bestDist
end

AimbotBox:AddToggle("AimbotEnabled",    { Text = "Aimbot",        Default = false })
AimbotBox:AddToggle("AimbotPredict",    { Text = "Prediction",    Default = true  })
AimbotBox:AddToggle("AimbotFOVCircle",  { Text = "FOV Circle",    Default = true  })
AimbotBox:AddSlider("AimbotFOV",        { Text = "FOV Radius",    Default = 150, Min = 10, Max = 500, Rounding = 0 })
AimbotBox:AddSlider("AimbotSmooth",     { Text = "Smoothness",    Default = 8,   Min = 1,  Max = 50,  Rounding = 1 })
AimbotBox:AddSlider("AimbotPredFrames", { Text = "Pred Frames",   Default = 4,   Min = 0,  Max = 15,  Rounding = 0 })
AimbotBox:AddDropdown("AimbotPart",     { Text = "Target Part",   Default = "Head", Values = {"Head","HumanoidRootPart","Torso"} })

HotkeyBox:AddKeybind("AimbotHoldKey", {
    Text    = "Aimbot Hold",
    Default = Enum.KeyCode.Unknown,
    Mode    = "Hold",
})
HotkeyBox:AddKeybind("AimbotToggleKey", {
    Text     = "Aimbot Toggle",
    Default  = Enum.KeyCode.RightAlt,
    Mode     = "Toggle",
    Callback = function(v) Toggles.AimbotEnabled:Set(v) end,
})

local FOVCircle     = Drawing.new("Circle")
FOVCircle.Visible   = false
FOVCircle.Radius    = 150
FOVCircle.Color     = Color3.fromRGB(255,255,255)
FOVCircle.Thickness = 1
FOVCircle.Filled    = false
FOVCircle.NumSides  = 64

RunService.RenderStepped:Connect(function()
    FOVCircle.Position = GetCenter()
    FOVCircle.Radius   = Options.AimbotFOV and Options.AimbotFOV.Value or 150
    FOVCircle.Visible  = Toggles.AimbotEnabled.Value and Toggles.AimbotFOVCircle.Value
    if not Toggles.AimbotEnabled.Value then return end
    local holdKey = Options.AimbotHoldKey and Options.AimbotHoldKey.Value
    local holding = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    if holdKey and holdKey ~= Enum.KeyCode.Unknown then
        holding = holding or UserInputService:IsKeyDown(holdKey)
    end
    if not holding then return end
    local target = GetFOVTarget(); if not target then return end
    local part = GetPart(target, (Options.AimbotPart and Options.AimbotPart.Value) or "Head")
    if not part then return end
    local aimWorld = Toggles.AimbotPredict.Value
        and (Predict(GetRoot(target), Options.AimbotPredFrames and Options.AimbotPredFrames.Value or 4) or part.Position)
        or part.Position
    local aimVP  = Camera:WorldToViewportPoint(aimWorld)
    local aimVec = Vector2.new(aimVP.X, aimVP.Y)
    local center = GetCenter()
    local smooth = Options.AimbotSmooth and Options.AimbotSmooth.Value or 8
    local delta  = aimVec - center
    if delta.Magnitude > 1 then
        mousemoverel(delta.X / smooth, delta.Y / smooth)
    end
end)

SilentBox:AddToggle("SilentAimEnabled", { Text = "Silent Aim",   Default = false })
SilentBox:AddToggle("SilentAimPredict", { Text = "Prediction",   Default = true  })
SilentBox:AddSlider("SilentAimChance",  { Text = "Hit Chance %", Default = 90, Min = 1, Max = 100, Rounding = 0 })
SilentBox:AddSlider("SilentAimFrames",  { Text = "Pred Frames",  Default = 3,  Min = 0, Max = 15,  Rounding = 0 })
SilentBox:AddDropdown("SilentAimPart",  { Text = "Hitbox",       Default = "Head", Values = {"Head","HumanoidRootPart","Torso"} })

HotkeyBox:AddKeybind("SilentAimHotkey", {
    Text     = "Silent Aim Toggle",
    Default  = Enum.KeyCode.F2,
    Mode     = "Toggle",
    Callback = function(v) Toggles.SilentAimEnabled:Set(v) end,
})

local OrigWSP = safeHook(Camera.WorldToScreenPoint, function(self, worldPos)
    if Toggles.SilentAimEnabled and Toggles.SilentAimEnabled.Value then
        local chance = Options.SilentAimChance and Options.SilentAimChance.Value or 90
        if math.random(1,100) <= chance then
            local target = GetFOVTarget()
            if target then
                local part = GetPart(target, (Options.SilentAimPart and Options.SilentAimPart.Value) or "Head")
                if part then
                    worldPos = Toggles.SilentAimPredict.Value
                        and (Predict(GetRoot(target), Options.SilentAimFrames and Options.SilentAimFrames.Value or 3) or part.Position)
                        or part.Position
                end
            end
        end
    end
    return OrigWSP(self, worldPos)
end)

TriggerBox:AddToggle("TriggerEnabled",  { Text = "Triggerbot",        Default = false })
TriggerBox:AddToggle("TriggerPredict",  { Text = "Prediction",        Default = true  })
TriggerBox:AddToggle("TriggerHeadOnly", { Text = "Head Only",         Default = false })
TriggerBox:AddToggle("TriggerHumanise", { Text = "Humanise",          Default = true  })
TriggerBox:AddToggle("TriggerHoldMode", { Text = "Hold Key Mode",     Default = false })
TriggerBox:AddSlider("TriggerDelayMin", { Text = "Delay Min (ms)",    Default = 60,  Min = 0,  Max = 300,  Rounding = 0 })
TriggerBox:AddSlider("TriggerDelayMax", { Text = "Delay Max (ms)",    Default = 130, Min = 0,  Max = 600,  Rounding = 0 })
TriggerBox:AddSlider("TriggerFOV",      { Text = "FOV (px)",          Default = 25,  Min = 1,  Max = 150,  Rounding = 0 })
TriggerBox:AddSlider("TriggerMaxCPS",   { Text = "Max CPS",           Default = 8,   Min = 1,  Max = 20,   Rounding = 0 })
TriggerBox:AddSlider("TriggerBurstGap", { Text = "Burst Gap (ms)",    Default = 220, Min = 50, Max = 1000, Rounding = 0 })

HotkeyBox:AddKeybind("TriggerHotkey", {
    Text     = "Triggerbot Toggle",
    Default  = Enum.KeyCode.F3,
    Mode     = "Toggle",
    Callback = function(v) Toggles.TriggerEnabled:Set(v) end,
})
HotkeyBox:AddKeybind("TriggerHoldKey", {
    Text    = "Triggerbot Hold Key",
    Default = Enum.KeyCode.Unknown,
    Mode    = "Hold",
})

local tLastShot=0; local tShotCount=0; local tLastBurst=0
local tCooldown=false; local tLastTarget=nil

local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Exclude

RunService.Heartbeat:Connect(function()
    if not Toggles.TriggerEnabled.Value then tShotCount=0; tLastTarget=nil; return end
    if Toggles.TriggerHoldMode and Toggles.TriggerHoldMode.Value then
        local hk = Options.TriggerHoldKey and Options.TriggerHoldKey.Value
        local held = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        if hk and hk ~= Enum.KeyCode.Unknown then held = held or UserInputService:IsKeyDown(hk) end
        if not held then tShotCount=0; return end
    end
    local now      = tick()
    local maxCPS   = Options.TriggerMaxCPS   and Options.TriggerMaxCPS.Value   or 8
    local burstGap = (Options.TriggerBurstGap and Options.TriggerBurstGap.Value or 220) / 1000
    if tCooldown then
        if now - tLastBurst >= burstGap then tCooldown=false; tShotCount=0
        else return end
    end
    if tShotCount >= maxCPS then tCooldown=true; tLastBurst=now; return end
    local localChar = LocalPlayer.Character
    overlapParams.FilterDescendantsInstances = localChar and {localChar} or {}
    local center = GetCenter()
    local fov    = Options.TriggerFOV and Options.TriggerFOV.Value or 25
    local found  = false; local foundPlayer = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer or not IsAlive(p) then continue end
        if Toggles.GlobalTeamCheck and Toggles.GlobalTeamCheck.Value then
            if p.Team == LocalPlayer.Team then continue end
        end
        local partName = Toggles.TriggerHeadOnly.Value and "Head" or "HumanoidRootPart"
        local part = GetPart(p, partName); if not part then continue end
        local checkPos = Toggles.TriggerPredict.Value
            and (Predict(GetRoot(p), 2) or part.Position) or part.Position
        local vp, onScreen = W2S(checkPos)
        if onScreen and (vp - center).Magnitude < fov then
            local hitPart = Instance.new("Part")
            hitPart.Size=Vector3.new(0.1,0.1,0.1); hitPart.CFrame=CFrame.new(checkPos)
            hitPart.Anchored=true; hitPart.CanCollide=false; hitPart.Parent=workspace
            local hits = workspace:GetPartsInPart(hitPart, overlapParams)
            hitPart:Destroy()
            for _, hit in ipairs(hits) do
                local model = hit:FindFirstAncestorOfClass("Model")
                if model then
                    local hp = Players:GetPlayerFromCharacter(model)
                    if hp and hp ~= LocalPlayer and IsAlive(hp) then
                        found=true; foundPlayer=hp; break
                    end
                end
            end
            if not found then found=true; foundPlayer=p end
            if found then break end
        end
    end
    if foundPlayer ~= tLastTarget then tShotCount=0; tLastTarget=foundPlayer end
    if not found then tShotCount=0; return end
    local dMin  = (Options.TriggerDelayMin and Options.TriggerDelayMin.Value or 60)  / 1000
    local dMax  = (Options.TriggerDelayMax and Options.TriggerDelayMax.Value or 130) / 1000
    local delay = Toggles.TriggerHumanise.Value
        and (dMin + math.random() * (dMax - dMin)) or dMin
    if now - tLastShot < delay then return end
    tLastShot=now; tShotCount=tShotCount+1
    task.spawn(function()
        local jScale = math.clamp(dMax*10, 0.5, 2.5)
        if Toggles.TriggerHumanise.Value then mousemoverel((math.random()-.5)*jScale,(math.random()-.5)*jScale) end
        mouse1click()
        if Toggles.TriggerHumanise.Value then
            task.wait(0.014+math.random()*0.018)
            mousemoverel((math.random()-.5)*jScale,(math.random()-.5)*jScale)
        end
    end)
end)

CamlockBox:AddToggle("CamlockEnabled", { Text = "Camlock",     Default = false })
CamlockBox:AddToggle("CamlockPredict", { Text = "Prediction",  Default = true  })
CamlockBox:AddSlider("CamlockSmooth",  { Text = "Smoothness",  Default = 4, Min = 1, Max = 30, Rounding = 1 })
CamlockBox:AddSlider("CamlockFrames",  { Text = "Pred Frames", Default = 3, Min = 0, Max = 15, Rounding = 0 })
CamlockBox:AddDropdown("CamlockPart",  { Text = "Lock To",     Default = "Head", Values = {"Head","HumanoidRootPart","Torso"} })

HotkeyBox:AddKeybind("CamlockHotkey", {
    Text     = "Camlock Toggle",
    Default  = Enum.KeyCode.F4,
    Mode     = "Toggle",
    Callback = function(v) Toggles.CamlockEnabled:Set(v) end,
})

RunService.RenderStepped:Connect(function()
    if not Toggles.CamlockEnabled.Value then return end
    local target = GetFOVTarget(); if not target then return end
    local part = GetPart(target, (Options.CamlockPart and Options.CamlockPart.Value) or "Head")
    if not part then return end
    local aimPos = Toggles.CamlockPredict.Value
        and (Predict(GetRoot(target), Options.CamlockFrames and Options.CamlockFrames.Value or 3) or part.Position)
        or part.Position
    local smooth = Options.CamlockSmooth and Options.CamlockSmooth.Value or 4
    local dir    = (aimPos - Camera.CFrame.Position).Unit
    Camera.CFrame = Camera.CFrame:Lerp(
        CFrame.lookAt(Camera.CFrame.Position, Camera.CFrame.Position + dir), 1 / smooth
    )
end)

ESPBox:AddToggle("ESPEnabled",    { Text = "ESP",          Default = false })
ESPBox:AddToggle("ESPBoxes",      { Text = "Boxes",        Default = true  })
ESPBox:AddToggle("ESPCornerBox",  { Text = "Corner Style", Default = true  })
ESPBox:AddToggle("ESPNames",      { Text = "Names",        Default = true  })
ESPBox:AddToggle("ESPDistance",   { Text = "Distance",     Default = true  })
ESPBox:AddToggle("ESPHealthBar",  { Text = "Health Bar",   Default = true  })
ESPBox:AddToggle("ESPTracers",    { Text = "Tracers",      Default = false })
ESPBox:AddToggle("ESPSkeleton",   { Text = "Skeleton",     Default = false })
ESPBox:AddToggle("ESPHealthText", { Text = "HP Number",    Default = true  })
ESPStyleBox:AddColorpicker("ESPColorEnemy",  { Text = "Enemy",     Default = Color3.fromRGB(255,60,60)   })
ESPStyleBox:AddColorpicker("ESPColorFriend", { Text = "Team",      Default = Color3.fromRGB(60,180,255)  })
ESPStyleBox:AddColorpicker("ESPColorTracer", { Text = "Tracer",    Default = Color3.fromRGB(255,255,255) })
ESPStyleBox:AddSlider("ESPTextSize",         { Text = "Text Size", Default = 13,  Min = 8,  Max = 24,   Rounding = 0 })
ESPStyleBox:AddSlider("ESPMaxDist",          { Text = "Max Dist",  Default = 500, Min = 50, Max = 2000, Rounding = 0 })

HotkeyBox:AddKeybind("ESPHotkey", {
    Text     = "ESP Toggle",
    Default  = Enum.KeyCode.F1,
    Mode     = "Toggle",
    Callback = function(v) Toggles.ESPEnabled:Set(v) end,
})

local BONES = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}
local CORNER_RATIO = 0.25

local function NewD(t,props) local d=Drawing.new(t); for k,v in pairs(props) do d[k]=v end; return d end
local function HideAll(obj)
    obj.Box.Visible=false; obj.Name.Visible=false; obj.Dist.Visible=false
    obj.HPText.Visible=false; obj.HealthBG.Visible=false; obj.HealthFG.Visible=false
    obj.Tracer.Visible=false
    for _,l in ipairs(obj.Corners) do l.Visible=false end
    for _,l in ipairs(obj.Bones)   do l.Visible=false end
end
local function MakeCorners() local t={}; for i=1,8 do t[i]=NewD("Line",{Thickness=1.5,Visible=false}) end; return t end
local function MakeBones()   local t={}; for i=1,#BONES do t[i]=NewD("Line",{Thickness=1,Visible=false}) end; return t end

local ESPObjects = {}
local function MakeESP(player)
    if player==LocalPlayer or ESPObjects[player] then return end
    ESPObjects[player]={
        Box=NewD("Square",{Filled=false,Thickness=1,Visible=false}),
        Name=NewD("Text",{Size=13,Center=true,Outline=true,Visible=false}),
        Dist=NewD("Text",{Size=11,Center=true,Outline=true,Visible=false}),
        HPText=NewD("Text",{Size=11,Center=true,Outline=true,Visible=false}),
        HealthBG=NewD("Square",{Filled=true,Color=Color3.fromRGB(0,0,0),Visible=false}),
        HealthFG=NewD("Square",{Filled=true,Visible=false}),
        Tracer=NewD("Line",{Thickness=1,Visible=false}),
        Corners=MakeCorners(), Bones=MakeBones(), FrameCount=0,
    }
end
local function RemoveESP(player)
    if not ESPObjects[player] then return end
    for k,v in pairs(ESPObjects[player]) do
        if type(v)=="table" then for _,d in ipairs(v) do pcall(function()d:Remove()end) end
        elseif type(v)~="number" then pcall(function()v:Remove()end) end
    end
    ESPObjects[player]=nil
end

Players.PlayerAdded:Connect(MakeESP)
Players.PlayerRemoving:Connect(RemoveESP)
for _,p in ipairs(Players:GetPlayers()) do MakeESP(p) end

local function HPColor(r)
    if r>.5 then return Color3.fromRGB(math.floor(255*(1-r)*2),255,0)
    else return Color3.fromRGB(255,math.floor(255*r*2),0) end
end

local function DrawCorners(c,tl,sz,col)
    local tr=Vector2.new(tl.X+sz.X,tl.Y); local bl=Vector2.new(tl.X,tl.Y+sz.Y)
    local br=tl+sz; local cx=sz.X*CORNER_RATIO; local cy=sz.Y*CORNER_RATIO
    local function s(i,f,t) c[i].From=f;c[i].To=t;c[i].Color=col;c[i].Visible=true end
    s(1,tl,tl+Vector2.new(cx,0)); s(2,tl,tl+Vector2.new(0,cy))
    s(3,tr,tr-Vector2.new(cx,0)); s(4,tr,tr+Vector2.new(0,cy))
    s(5,bl,bl+Vector2.new(cx,0)); s(6,bl,bl-Vector2.new(0,cy))
    s(7,br,br-Vector2.new(cx,0)); s(8,br,br-Vector2.new(0,cy))
end

RunService.RenderStepped:Connect(function()
    local maxDist=Options.ESPMaxDist and Options.ESPMaxDist.Value or 500
    local textSz=Options.ESPTextSize and Options.ESPTextSize.Value or 13
    local center=GetCenter()
    local bottomCenter=Vector2.new(center.X,Camera.ViewportSize.Y)
    for _,player in ipairs(Players:GetPlayers()) do
        if player==LocalPlayer then continue end
        local obj=ESPObjects[player]; if not obj then continue end
        if not Toggles.ESPEnabled.Value or not IsAlive(player) then HideAll(obj);continue end
        local root=GetRoot(player); local head=GetHead(player)
        if not root or not head then HideAll(obj);continue end
        local worldDist=(Camera.CFrame.Position-root.Position).Magnitude
        if worldDist>maxDist then HideAll(obj);continue end
        obj.FrameCount=(obj.FrameCount or 0)+1
        if worldDist>200 and obj.FrameCount%3~=0 then continue end
        local rootVP,onScreen,depth=W2S(root.Position)
        local headVP,headOS=W2S(head.Position)
        if not onScreen or not headOS or depth<0 then HideAll(obj);continue end
        local boxH=math.abs(rootVP.Y-headVP.Y)*2.15
        local boxW=boxH*0.58
        local topLeft=Vector2.new(rootVP.X-boxW*.5,headVP.Y-boxH*.07)
        local boxSize=Vector2.new(boxW,boxH)
        local isEnemy=not(Toggles.GlobalTeamCheck and Toggles.GlobalTeamCheck.Value and player.Team==LocalPlayer.Team)
        local col=isEnemy
            and (Options.ESPColorEnemy and Options.ESPColorEnemy.Value or Color3.fromRGB(255,60,60))
            or  (Options.ESPColorFriend and Options.ESPColorFriend.Value or Color3.fromRGB(60,180,255))
        local useCorner=Toggles.ESPCornerBox and Toggles.ESPCornerBox.Value
        obj.Box.Visible=Toggles.ESPBoxes.Value and not useCorner
        if obj.Box.Visible then obj.Box.Color=col;obj.Box.Position=topLeft;obj.Box.Size=boxSize end
        if Toggles.ESPBoxes.Value and useCorner then DrawCorners(obj.Corners,topLeft,boxSize,col)
        else for _,l in ipairs(obj.Corners) do l.Visible=false end end
        local hum=GetHumanoid(player)
        local hp=hum and hum.Health or 0
        local maxHp=hum and hum.MaxHealth or 100
        local hpRatio=math.clamp(hp/math.max(maxHp,1),0,1)
        obj.Name.Visible=Toggles.ESPNames.Value;obj.Name.Color=col;obj.Name.Size=textSz
        obj.Name.Text=player.DisplayName~="" and player.DisplayName or player.Name
        obj.Name.Position=Vector2.new(rootVP.X,topLeft.Y-textSz-2)
        obj.Dist.Visible=Toggles.ESPDistance.Value;obj.Dist.Color=Color3.fromRGB(200,200,200)
        obj.Dist.Size=textSz-2;obj.Dist.Text=math.floor(worldDist).."m"
        obj.Dist.Position=Vector2.new(rootVP.X,topLeft.Y+boxH+2)
        obj.HPText.Visible=Toggles.ESPHealthText.Value;obj.HPText.Color=HPColor(hpRatio)
        obj.HPText.Size=textSz-2;obj.HPText.Text=math.floor(hp).." HP"
        obj.HPText.Position=Vector2.new(rootVP.X,topLeft.Y+boxH+(textSz-2)+4)
        local barW,barH,barX=3,boxH,topLeft.X-6
        obj.HealthBG.Visible=Toggles.ESPHealthBar.Value
        obj.HealthBG.Position=Vector2.new(barX,topLeft.Y);obj.HealthBG.Size=Vector2.new(barW,barH)
        obj.HealthFG.Visible=Toggles.ESPHealthBar.Value;obj.HealthFG.Color=HPColor(hpRatio)
        obj.HealthFG.Position=Vector2.new(barX,topLeft.Y+barH*(1-hpRatio))
        obj.HealthFG.Size=Vector2.new(barW,barH*hpRatio)
        local tracerCol=Options.ESPColorTracer and Options.ESPColorTracer.Value or Color3.fromRGB(255,255,255)
        obj.Tracer.Visible=Toggles.ESPTracers.Value;obj.Tracer.Color=tracerCol
        obj.Tracer.From=bottomCenter;obj.Tracer.To=rootVP;obj.Tracer.Thickness=1
        if Toggles.ESPSkeleton.Value then
            local char=GetCharacter(player)
            for i,pair in ipairs(BONES) do
                local b=obj.Bones[i]
                local p1=char and char:FindFirstChild(pair[1])
                local p2=char and char:FindFirstChild(pair[2])
                if p1 and p2 then
                    local vp1,os1=W2S(p1.Position);local vp2,os2=W2S(p2.Position)
                    b.Visible=os1 and os2;b.From=vp1;b.To=vp2;b.Color=col;b.Thickness=1
                else b.Visible=false end
            end
        else for _,b in ipairs(obj.Bones) do b.Visible=false end end
    end
end)

FlyBox:AddToggle("FlyEnabled", { Text = "Fly",          Default = false })
FlyBox:AddToggle("FlyNoClip",  { Text = "Noclip",       Default = true  })
FlyBox:AddSlider("FlySpeed",   { Text = "Speed",        Default = 60,  Min = 5,  Max = 500,  Rounding = 0 })
FlyBox:AddSlider("FlyBoost",   { Text = "Boost Speed",  Default = 180, Min = 10, Max = 1000, Rounding = 0 })
FlyBox:AddSlider("FlyAccel",   { Text = "Acceleration", Default = 8,   Min = 1,  Max = 30,   Rounding = 1 })

HotkeyBox:AddKeybind("FlyHotkey", {
    Text     = "Fly Toggle",
    Default  = Enum.KeyCode.F,
    Mode     = "Toggle",
    Callback = function(v) Toggles.FlyEnabled:Set(v) end,
})

local FlyAttach=nil; local FlyLinear=nil; local FlyBody=nil
local FlyUseLV=true; local FlyCurrentV=Vector3.zero

local function EnableFly()
    local char=LocalPlayer.Character; if not char then return end
    local root=char:FindFirstChild("HumanoidRootPart")
    local hum=char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    hum.PlatformStand=true
    local ok=pcall(function()
        FlyAttach=Instance.new("Attachment"); FlyAttach.Parent=root
        FlyLinear=Instance.new("LinearVelocity")
        FlyLinear.Attachment0=FlyAttach
        FlyLinear.VectorVelocity=Vector3.zero
        FlyLinear.MaxForce=1e6
        FlyLinear.RelativeTo=Enum.ActuatorRelativeTo.World
        FlyLinear.Parent=root
        FlyUseLV=true
    end)
    if not ok then
        if FlyAttach then FlyAttach:Destroy(); FlyAttach=nil end
        if FlyLinear then FlyLinear:Destroy(); FlyLinear=nil end
        FlyBody=Instance.new("BodyVelocity")
        FlyBody.Velocity=Vector3.zero
        FlyBody.MaxForce=Vector3.new(1e6,1e6,1e6)
        FlyBody.Parent=root
        FlyUseLV=false
    end
end

local function DisableFly()
    if FlyLinear then FlyLinear:Destroy(); FlyLinear=nil end
    if FlyAttach then FlyAttach:Destroy(); FlyAttach=nil end
    if FlyBody   then FlyBody:Destroy();  FlyBody=nil   end
    FlyCurrentV=Vector3.zero
    local char=LocalPlayer.Character
    local hum=char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand=false; hum.WalkSpeed=16; hum.JumpPower=50 end
end

Toggles.FlyEnabled:OnChanged(function(v)
    if v then EnableFly() else DisableFly() end
end)

RunService.RenderStepped:Connect(function(dt)
    if Toggles.FlyNoClip and Toggles.FlyNoClip.Value then
        local char=LocalPlayer.Character
        if char then for _,p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide=false end
        end end
    end
    if not Toggles.FlyEnabled.Value then return end
    if not FlyLinear and not FlyBody then return end
    local char=LocalPlayer.Character; if not char then return end
    local root=char:FindFirstChild("HumanoidRootPart")
    local hum=char:FindFirstChildOfClass("Humanoid")
    if not root then return end
    if hum then hum.WalkSpeed=16; hum.JumpPower=50 end
    local boosting=UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
    local speed=boosting
        and (Options.FlyBoost and Options.FlyBoost.Value or 180)
        or  (Options.FlySpeed and Options.FlySpeed.Value or 60)
    local accel=Options.FlyAccel and Options.FlyAccel.Value or 8
    local cf=Camera.CFrame; local target=Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W)           then target+=cf.LookVector          end
    if UserInputService:IsKeyDown(Enum.KeyCode.S)           then target-=cf.LookVector          end
    if UserInputService:IsKeyDown(Enum.KeyCode.A)           then target-=cf.RightVector         end
    if UserInputService:IsKeyDown(Enum.KeyCode.D)           then target+=cf.RightVector         end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space)       then target+=Vector3.new(0,1,0)     end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then target-=Vector3.new(0,1,0)     end
    local targetV=target.Magnitude>0 and target.Unit*speed or Vector3.zero
    FlyCurrentV=FlyCurrentV:Lerp(targetV,math.clamp(accel*dt,0,1))
    if FlyUseLV and FlyLinear then FlyLinear.VectorVelocity=FlyCurrentV
    elseif FlyBody then FlyBody.Velocity=FlyCurrentV end
    root.CFrame=CFrame.new(root.Position,root.Position+cf.LookVector)
end)

LocalPlayer.CharacterAdded:Connect(function()
    FlyLinear=nil; FlyAttach=nil; FlyBody=nil; FlyCurrentV=Vector3.zero
    if Toggles.FlyEnabled.Value then task.wait(0.5); EnableFly() end
end)

local CONFIG_FOLDER    = "Kori_DaHood"
local CONFIG_SUBFOLDER = CONFIG_FOLDER.."/configs"
local AUTOLOAD_PATH    = CONFIG_FOLDER.."/autoload.txt"

if not isfolder(CONFIG_FOLDER)    then makefolder(CONFIG_FOLDER)    end
if not isfolder(CONFIG_SUBFOLDER) then makefolder(CONFIG_SUBFOLDER) end

local function GetConfigList()
    local files=listfiles(CONFIG_SUBFOLDER); local names={}
    for _,f in ipairs(files) do
        local name=f:match("([^/\\]+)%.json$") or f:match("([^/\\]+)%.cfg$")
        if name then table.insert(names,name) end
    end
    return names
end

local function SaveConfig(name)
    if name=="" then return end
    SaveManager:Save(CONFIG_SUBFOLDER.."/"..name)
    Notify("config saved: "..name, "", 3)
end

local function LoadConfig(name)
    if name=="" then return end
    local path=CONFIG_SUBFOLDER.."/"..name
    if isfile(path) or isfile(path..".json") then
        SaveManager:Load(path)
        Notify("config loaded: "..name, "", 3)
    end
end

local function DeleteConfig(name)
    if name=="" then return end
    local path=CONFIG_SUBFOLDER.."/"..name
    if isfile(path) then delfile(path) end
    if isfile(path..".json") then delfile(path..".json") end
    Notify("config deleted: "..name, "", 3)
end

local function SetAutoload(name) writefile(AUTOLOAD_PATH,name); Notify("autoload set: "..name,"",3) end
local function GetAutoload() if isfile(AUTOLOAD_PATH) then return readfile(AUTOLOAD_PATH) end; return "" end

local configNames=GetConfigList()
if #configNames==0 then configNames={"(none)"} end
local configInput=""

ConfigBox:AddInput("ConfigNameInput",{
    Text="Config Name",Default="",Numeric=false,Finished=false,
    Placeholder="type config name...",
    Callback=function(v) configInput=v end,
})
ConfigBox:AddButton("Save Config",function()
    local name=configInput~="" and configInput or "default"
    SaveConfig(name)
    local updated=GetConfigList()
    if Options.ConfigDropdown then Options.ConfigDropdown:SetValues(#updated>0 and updated or {"(none)"}) end
end)
ConfigBox:AddButton("Load Config",function()
    if Options.ConfigDropdown then
        local sel=Options.ConfigDropdown.Value
        if sel and sel~="(none)" then LoadConfig(sel) end
    end
end)
ConfigBox:AddButton("Delete Config",function()
    if Options.ConfigDropdown then
        local sel=Options.ConfigDropdown.Value
        if sel and sel~="(none)" then
            DeleteConfig(sel)
            local updated=GetConfigList()
            Options.ConfigDropdown:SetValues(#updated>0 and updated or {"(none)"})
        end
    end
end)
ConfigBox:AddButton("Set as Autoload",function()
    if Options.ConfigDropdown then
        local sel=Options.ConfigDropdown.Value
        if sel and sel~="(none)" then SetAutoload(sel) end
    end
end)
ConfigBox:AddDropdown("ConfigDropdown",{
    Text="Config List",Values=configNames,Default=configNames[1],
})
ConfigBox:AddButton("Refresh List",function()
    local updated=GetConfigList()
    if Options.ConfigDropdown then
        Options.ConfigDropdown:SetValues(#updated>0 and updated or {"(none)"})
    end
end)
ConfigBox:AddLabel("Autoload: "..(GetAutoload()~="" and GetAutoload() or "none"))

local autoName=GetAutoload()
if autoName~="" then task.wait(0.3); LoadConfig(autoName) end

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetFolder("Kori_DaHood")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:BuildThemeSection(ThemeBox)
SaveManager:LoadAutoloadConfig()

Notify("Kori", "loaded — left alt toggles UI", 4)
