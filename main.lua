local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera           = workspace.CurrentCamera
local LocalPlayer      = Players.LocalPlayer

pcall(function() setidentity(8) end)
pcall(function() syn and syn.set_thread_identity(8) end)
getgenv().__BYPASS_ACTIVE = true
getgenv().__cheatloaded   = nil

RunService.Heartbeat:Connect(function()
    pcall(function() setidentity(8) end)
end)

local function safeHook(fn,cb)
    if type(fn)=="function" then return hookfunction(fn,cb) end
    return fn
end

----------------------------------------------------------------
-- STATE
----------------------------------------------------------------
local S = {
    UIVisible=true, SilentMode=false, TeamCheck=true,
    ESPEnabled=false, ESPBoxes=true, ESPCorner=true,
    ESPNames=true, ESPDistance=true, ESPHealthBar=true,
    ESPTracers=false, ESPSkeleton=false, ESPMaxDist=500,
    AimbotEnabled=false, AimbotFOV=150, AimbotSmooth=8,
    AimbotPredict=true, AimbotPredF=4, AimbotFOVCirc=true,
    SilentAim=false, SilentChance=90, SilentPredict=true, SilentPredF=3,
    TriggerEnabled=false, TriggerDelMin=60, TriggerDelMax=130,
    TriggerFOV=25, TriggerMaxCPS=8, TriggerBurst=220,
    TriggerPredict=true, TriggerHuman=true, TriggerHold=false,
    CamlockEnabled=false, CamlockSmooth=4, CamlockPredF=3,
    FlyEnabled=false, FlyNoClip=true, FlySpeed=60,
    FlyBoost=180, FlyAccel=8,
}

----------------------------------------------------------------
-- NOTIFY
----------------------------------------------------------------
local function Notify(msg)
    if S.SilentMode then return end
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification",{
            Title="Kori", Text=msg, Duration=3
        })
    end)
end

----------------------------------------------------------------
-- UTILS
----------------------------------------------------------------
local function GetCharacter(p) return p and p.Character end
local function GetPart(p,n) local c=GetCharacter(p); return c and c:FindFirstChild(n) end
local function GetRoot(p) return GetPart(p,"HumanoidRootPart") end
local function GetHead(p) return GetPart(p,"Head") end
local function GetHum(p) local c=GetCharacter(p); return c and c:FindFirstChildOfClass("Humanoid") end
local function IsAlive(p) local h=GetHum(p); return h and h.Health>0 end
local function GetCenter() return Vector2.new(Camera.ViewportSize.X*.5,Camera.ViewportSize.Y*.5) end
local function W2S(pos) local v,vis=Camera:WorldToViewportPoint(pos); return Vector2.new(v.X,v.Y),vis,v.Z end
local function Predict(root,f) if not root then return nil end; return root.Position+root.AssemblyLinearVelocity*(f/60) end

local function GetFOVTarget(fov)
    fov=fov or S.AimbotFOV
    local best,bestD=nil,math.huge
    local center=GetCenter()
    for _,p in ipairs(Players:GetPlayers()) do
        if p==LocalPlayer or not IsAlive(p) then continue end
        if S.TeamCheck and p.Team==LocalPlayer.Team then continue end
        local head=GetHead(p); if not head then continue end
        local vp,os=W2S(head.Position)
        if os then local d=(vp-center).Magnitude; if d<fov and d<bestD then bestD,best=d,p end end
    end
    return best
end

----------------------------------------------------------------
-- GUI BUILDER
----------------------------------------------------------------
local CoreGui = game:GetService("CoreGui")
local existing = CoreGui:FindFirstChild("KoriUI")
if existing then existing:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name="KoriUI"
ScreenGui.ResetOnSpawn=false
ScreenGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
ScreenGui.Parent=CoreGui

-- colours
local C = {
    bg      = Color3.fromRGB(15,15,20),
    panel   = Color3.fromRGB(22,22,30),
    accent  = Color3.fromRGB(100,60,220),
    accent2 = Color3.fromRGB(130,80,255),
    text    = Color3.fromRGB(220,220,230),
    muted   = Color3.fromRGB(120,120,140),
    toggle_on  = Color3.fromRGB(100,60,220),
    toggle_off = Color3.fromRGB(50,50,65),
    slider_bg  = Color3.fromRGB(40,40,55),
    white   = Color3.fromRGB(255,255,255),
    tab_sel = Color3.fromRGB(100,60,220),
    tab_unsel = Color3.fromRGB(30,30,40),
}

-- main window
local Main = Instance.new("Frame")
Main.Name="Main"
Main.Size=UDim2.new(0,540,0,400)
Main.Position=UDim2.new(0.5,-270,0.5,-200)
Main.BackgroundColor3=C.bg
Main.BorderSizePixel=0
Main.Active=true
Main.Draggable=true
Main.Parent=ScreenGui

Instance.new("UICorner",Main).CornerRadius=UDim.new(0,8)

-- title bar
local TitleBar=Instance.new("Frame")
TitleBar.Size=UDim2.new(1,0,0,36)
TitleBar.BackgroundColor3=C.panel
TitleBar.BorderSizePixel=0
TitleBar.Parent=Main
Instance.new("UICorner",TitleBar).CornerRadius=UDim.new(0,8)

local TitleFix=Instance.new("Frame")
TitleFix.Size=UDim2.new(1,0,0.5,0)
TitleFix.Position=UDim2.new(0,0,0.5,0)
TitleFix.BackgroundColor3=C.panel
TitleFix.BorderSizePixel=0
TitleFix.Parent=TitleBar

local TitleLabel=Instance.new("TextLabel")
TitleLabel.Size=UDim2.new(1,-40,1,0)
TitleLabel.Position=UDim2.new(0,12,0,0)
TitleLabel.BackgroundTransparency=1
TitleLabel.Text="Kori  |  Da Hood"
TitleLabel.TextColor3=C.text
TitleLabel.Font=Enum.Font.GothamBold
TitleLabel.TextSize=14
TitleLabel.TextXAlignment=Enum.TextXAlignment.Left
TitleLabel.Parent=TitleBar

-- close button
local CloseBtn=Instance.new("TextButton")
CloseBtn.Size=UDim2.new(0,24,0,24)
CloseBtn.Position=UDim2.new(1,-30,0.5,-12)
CloseBtn.BackgroundColor3=Color3.fromRGB(180,50,50)
CloseBtn.Text="×"
CloseBtn.TextColor3=C.white
CloseBtn.Font=Enum.Font.GothamBold
CloseBtn.TextSize=16
CloseBtn.BorderSizePixel=0
CloseBtn.Parent=TitleBar
Instance.new("UICorner",CloseBtn).CornerRadius=UDim.new(0,4)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui.Enabled=false end)

-- tab bar
local TabBar=Instance.new("Frame")
TabBar.Size=UDim2.new(1,0,0,30)
TabBar.Position=UDim2.new(0,0,0,36)
TabBar.BackgroundColor3=C.panel
TabBar.BorderSizePixel=0
TabBar.Parent=Main

local TabBarLayout=Instance.new("UIListLayout")
TabBarLayout.FillDirection=Enum.FillDirection.Horizontal
TabBarLayout.SortOrder=Enum.SortOrder.LayoutOrder
TabBarLayout.Parent=TabBar

-- content area
local Content=Instance.new("Frame")
Content.Size=UDim2.new(1,0,1,-66)
Content.Position=UDim2.new(0,0,0,66)
Content.BackgroundTransparency=1
Content.Parent=Main

-- tab system
local TabPages={}
local TabButtons={}
local ActiveTab=nil

local function MakeTab(name,order)
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(0,72,1,0)
    btn.BackgroundColor3=C.tab_unsel
    btn.BorderSizePixel=0
    btn.Text=name
    btn.TextColor3=C.muted
    btn.Font=Enum.Font.Gotham
    btn.TextSize=11
    btn.LayoutOrder=order
    btn.Parent=TabBar

    local page=Instance.new("ScrollingFrame")
    page.Size=UDim2.new(1,0,1,0)
    page.BackgroundTransparency=1
    page.BorderSizePixel=0
    page.ScrollBarThickness=3
    page.ScrollBarImageColor3=C.accent
    page.CanvasSize=UDim2.new(0,0,0,0)
    page.AutomaticCanvasSize=Enum.AutomaticSize.Y
    page.Visible=false
    page.Parent=Content

    local layout=Instance.new("UIListLayout")
    layout.SortOrder=Enum.SortOrder.LayoutOrder
    layout.Padding=UDim.new(0,4)
    layout.Parent=page

    local pad=Instance.new("UIPadding")
    pad.PaddingLeft=UDim.new(0,8)
    pad.PaddingRight=UDim.new(0,8)
    pad.PaddingTop=UDim.new(0,8)
    pad.Parent=page

    TabPages[name]=page
    TabButtons[name]=btn

    btn.MouseButton1Click:Connect(function()
        if ActiveTab then
            TabPages[ActiveTab].Visible=false
            TabButtons[ActiveTab].BackgroundColor3=C.tab_unsel
            TabButtons[ActiveTab].TextColor3=C.muted
        end
        ActiveTab=name
        page.Visible=true
        btn.BackgroundColor3=C.tab_sel
        btn.TextColor3=C.white
    end)
    return page
end

local PgCombat  = MakeTab("Combat",1)
local PgVisual  = MakeTab("Visual",2)
local PgMove    = MakeTab("Move",3)
local PgConfig  = MakeTab("Config",4)
local PgSettings= MakeTab("Settings",5)

-- activate first tab
ActiveTab="Combat"
TabPages["Combat"].Visible=true
TabButtons["Combat"].BackgroundColor3=C.tab_sel
TabButtons["Combat"].TextColor3=C.white

----------------------------------------------------------------
-- WIDGET HELPERS
----------------------------------------------------------------
local function Section(parent,title)
    local f=Instance.new("Frame")
    f.Size=UDim2.new(1,-0,0,24)
    f.BackgroundTransparency=1
    f.Parent=parent
    local l=Instance.new("TextLabel")
    l.Size=UDim2.new(1,0,1,0)
    l.BackgroundTransparency=1
    l.Text=string.upper(title)
    l.TextColor3=C.accent2
    l.Font=Enum.Font.GothamBold
    l.TextSize=10
    l.TextXAlignment=Enum.TextXAlignment.Left
    l.Parent=f
    return f
end

local function Toggle(parent,text,key,order)
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,28)
    row.BackgroundColor3=C.panel
    row.BorderSizePixel=0
    row.LayoutOrder=order or 0
    row.Parent=parent
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,5)

    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(1,-50,1,0)
    lbl.Position=UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency=1
    lbl.Text=text
    lbl.TextColor3=C.text
    lbl.Font=Enum.Font.Gotham
    lbl.TextSize=12
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.Parent=row

    local pill=Instance.new("Frame")
    pill.Size=UDim2.new(0,36,0,18)
    pill.Position=UDim2.new(1,-44,0.5,-9)
    pill.BackgroundColor3=S[key] and C.toggle_on or C.toggle_off
    pill.BorderSizePixel=0
    pill.Parent=row
    Instance.new("UICorner",pill).CornerRadius=UDim.new(1,0)

    local dot=Instance.new("Frame")
    dot.Size=UDim2.new(0,14,0,14)
    dot.Position=S[key] and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)
    dot.BackgroundColor3=C.white
    dot.BorderSizePixel=0
    dot.Parent=pill
    Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)

    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(1,0,1,0)
    btn.BackgroundTransparency=1
    btn.Text=""
    btn.Parent=row

    btn.MouseButton1Click:Connect(function()
        S[key]=not S[key]
        pill.BackgroundColor3=S[key] and C.toggle_on or C.toggle_off
        dot.Position=S[key] and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)
    end)
    return row
end

local function Slider(parent,text,key,min,max,order)
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,42)
    row.BackgroundColor3=C.panel
    row.BorderSizePixel=0
    row.LayoutOrder=order or 0
    row.Parent=parent
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,5)

    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(1,-50,0,18)
    lbl.Position=UDim2.new(0,10,0,4)
    lbl.BackgroundTransparency=1
    lbl.Text=text
    lbl.TextColor3=C.text
    lbl.Font=Enum.Font.Gotham
    lbl.TextSize=11
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.Parent=row

    local valLbl=Instance.new("TextLabel")
    valLbl.Size=UDim2.new(0,40,0,18)
    valLbl.Position=UDim2.new(1,-48,0,4)
    valLbl.BackgroundTransparency=1
    valLbl.Text=tostring(S[key])
    valLbl.TextColor3=C.accent2
    valLbl.Font=Enum.Font.GothamBold
    valLbl.TextSize=11
    valLbl.TextXAlignment=Enum.TextXAlignment.Right
    valLbl.Parent=row

    local track=Instance.new("Frame")
    track.Size=UDim2.new(1,-20,0,6)
    track.Position=UDim2.new(0,10,0,26)
    track.BackgroundColor3=C.slider_bg
    track.BorderSizePixel=0
    track.Parent=row
    Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)

    local fill=Instance.new("Frame")
    fill.Size=UDim2.new(math.clamp((S[key]-min)/(max-min),0,1),0,1,0)
    fill.BackgroundColor3=C.accent
    fill.BorderSizePixel=0
    fill.Parent=track
    Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)

    local dragging=false
    local function update(x)
        local rel=math.clamp((x-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
        local val=math.floor(min+rel*(max-min))
        S[key]=val
        fill.Size=UDim2.new(rel,0,1,0)
        valLbl.Text=tostring(val)
    end
    track.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; update(i.Position.X) end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then update(i.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)
    return row
end

local function Button(parent,text,cb,order)
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(1,0,0,28)
    btn.BackgroundColor3=C.accent
    btn.BorderSizePixel=0
    btn.Text=text
    btn.TextColor3=C.white
    btn.Font=Enum.Font.GothamBold
    btn.TextSize=12
    btn.LayoutOrder=order or 0
    btn.Parent=parent
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,5)
    btn.MouseButton1Click:Connect(cb)
    return btn
end

local function Label(parent,text,order)
    local l=Instance.new("TextLabel")
    l.Size=UDim2.new(1,0,0,20)
    l.BackgroundTransparency=1
    l.Text=text
    l.TextColor3=C.muted
    l.Font=Enum.Font.Gotham
    l.TextSize=11
    l.TextXAlignment=Enum.TextXAlignment.Left
    l.LayoutOrder=order or 0
    l.Parent=parent
    return l
end

local function TextInput(parent,placeholder,order)
    local box=Instance.new("TextBox")
    box.Size=UDim2.new(1,0,0,28)
    box.BackgroundColor3=C.panel
    box.BorderSizePixel=0
    box.Text=""
    box.PlaceholderText=placeholder
    box.PlaceholderColor3=C.muted
    box.TextColor3=C.text
    box.Font=Enum.Font.Gotham
    box.TextSize=12
    box.ClearTextOnFocus=false
    box.LayoutOrder=order or 0
    box.Parent=parent
    Instance.new("UICorner",box).CornerRadius=UDim.new(0,5)
    local pad=Instance.new("UIPadding")
    pad.PaddingLeft=UDim.new(0,8)
    pad.Parent=box
    return box
end

----------------------------------------------------------------
-- COMBAT TAB
----------------------------------------------------------------
Section(PgCombat,"Aimbot")
Toggle(PgCombat,"Aimbot (Hold RMB)","AimbotEnabled",1)
Toggle(PgCombat,"Prediction","AimbotPredict",2)
Toggle(PgCombat,"FOV Circle","AimbotFOVCirc",3)
Slider(PgCombat,"FOV Radius","AimbotFOV",10,500,4)
Slider(PgCombat,"Smoothness","AimbotSmooth",1,50,5)
Slider(PgCombat,"Pred Frames","AimbotPredF",0,15,6)

Section(PgCombat,"Silent Aim")
Toggle(PgCombat,"Silent Aim","SilentAim",7)
Toggle(PgCombat,"SA Prediction","SilentPredict",8)
Slider(PgCombat,"Hit Chance %","SilentChance",1,100,9)
Slider(PgCombat,"SA Pred Frames","SilentPredF",0,15,10)

Section(PgCombat,"Triggerbot")
Toggle(PgCombat,"Triggerbot","TriggerEnabled",11)
Toggle(PgCombat,"TB Prediction","TriggerPredict",12)
Toggle(PgCombat,"Humanise","TriggerHuman",13)
Toggle(PgCombat,"Hold Key Mode","TriggerHold",14)
Slider(PgCombat,"Delay Min ms","TriggerDelMin",0,300,15)
Slider(PgCombat,"Delay Max ms","TriggerDelMax",0,600,16)
Slider(PgCombat,"TB FOV px","TriggerFOV",1,150,17)
Slider(PgCombat,"Max CPS","TriggerMaxCPS",1,20,18)
Slider(PgCombat,"Burst Gap ms","TriggerBurst",50,1000,19)

Section(PgCombat,"Camlock")
Toggle(PgCombat,"Camlock","CamlockEnabled",20)
Slider(PgCombat,"Camlock Smooth","CamlockSmooth",1,30,21)
Slider(PgCombat,"Camlock Pred F","CamlockPredF",0,15,22)

----------------------------------------------------------------
-- VISUAL TAB
----------------------------------------------------------------
Section(PgVisual,"ESP")
Toggle(PgVisual,"ESP","ESPEnabled",1)
Toggle(PgVisual,"Boxes","ESPBoxes",2)
Toggle(PgVisual,"Corner Style","ESPCorner",3)
Toggle(PgVisual,"Names","ESPNames",4)
Toggle(PgVisual,"Distance","ESPDistance",5)
Toggle(PgVisual,"Health Bar","ESPHealthBar",6)
Toggle(PgVisual,"Tracers","ESPTracers",7)
Toggle(PgVisual,"Skeleton","ESPSkeleton",8)
Slider(PgVisual,"Max Distance","ESPMaxDist",50,2000,9)

----------------------------------------------------------------
-- MOVEMENT TAB
----------------------------------------------------------------
Section(PgMove,"Fly")
Toggle(PgMove,"Fly","FlyEnabled",1)
Toggle(PgMove,"Noclip","FlyNoClip",2)
Slider(PgMove,"Speed","FlySpeed",5,500,3)
Slider(PgMove,"Boost Speed","FlyBoost",10,1000,4)
Slider(PgMove,"Acceleration","FlyAccel",1,30,5)

----------------------------------------------------------------
-- SETTINGS TAB
----------------------------------------------------------------
Section(PgSettings,"Interface")
Toggle(PgSettings,"Silent Mode","SilentMode",1)
Toggle(PgSettings,"Team Check","TeamCheck",2)
Label(PgSettings,"UI Toggle: Left Alt",3)

----------------------------------------------------------------
-- CONFIG TAB
----------------------------------------------------------------
Section(PgConfig,"Config Manager")
local CONFIG_FOLDER    = "Kori_DaHood"
local CONFIG_SUBFOLDER = CONFIG_FOLDER.."/configs"
local AUTOLOAD_PATH    = CONFIG_FOLDER.."/autoload.txt"

pcall(function()
    if not isfolder(CONFIG_FOLDER)    then makefolder(CONFIG_FOLDER)    end
    if not isfolder(CONFIG_SUBFOLDER) then makefolder(CONFIG_SUBFOLDER) end
end)

local function SerializeConfig()
    local t={}
    for k,v in pairs(S) do t[k]=v end
    local str="return {"
    for k,v in pairs(t) do
        if type(v)=="boolean" then str=str..k.."="..tostring(v)..","
        elseif type(v)=="number" then str=str..k.."="..tostring(v).."," end
    end
    return str.."}"
end

local function DeserializeConfig(str)
    local ok,res=pcall(loadstring(str))
    if ok and type(res)=="table" then
        for k,v in pairs(res) do
            if S[k]~=nil then S[k]=v end
        end
    end
end

local function GetConfigList()
    local ok,files=pcall(listfiles,CONFIG_SUBFOLDER)
    if not ok then return {} end
    local names={}
    for _,f in ipairs(files) do
        local name=f:match("([^/\\]+)%.kori$")
        if name then table.insert(names,name) end
    end
    return names
end

local configInputBox=TextInput(PgConfig,"config name...",1)

Button(PgConfig,"Save Config",function()
    local name=configInputBox.Text~="" and configInputBox.Text or "default"
    pcall(function()
        writefile(CONFIG_SUBFOLDER.."/"..name..".kori", SerializeConfig())
    end)
    Notify("saved: "..name)
end,2)

Button(PgConfig,"Load Selected",function()
    local name=configInputBox.Text~="" and configInputBox.Text or "default"
    pcall(function()
        local path=CONFIG_SUBFOLDER.."/"..name..".kori"
        if isfile(path) then DeserializeConfig(readfile(path)); Notify("loaded: "..name) end
    end)
end,3)

Button(PgConfig,"Delete Selected",function()
    local name=configInputBox.Text~="" and configInputBox.Text or "default"
    pcall(function()
        local path=CONFIG_SUBFOLDER.."/"..name..".kori"
        if isfile(path) then delfile(path); Notify("deleted: "..name) end
    end)
end,4)

Button(PgConfig,"Set Autoload",function()
    local name=configInputBox.Text~="" and configInputBox.Text or "default"
    pcall(function() writefile(AUTOLOAD_PATH,name) end)
    Notify("autoload: "..name)
end,5)

local autoLabel=Label(PgConfig,"Autoload: none",6)
pcall(function()
    if isfile(AUTOLOAD_PATH) then
        local name=readfile(AUTOLOAD_PATH)
        autoLabel.Text="Autoload: "..name
        local path=CONFIG_SUBFOLDER.."/"..name..".kori"
        if isfile(path) then DeserializeConfig(readfile(path)) end
    end
end)

----------------------------------------------------------------
-- UI TOGGLE — LEFT ALT
----------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input,gpe)
    if gpe then return end
    if input.KeyCode==Enum.KeyCode.LeftAlt then
        S.UIVisible=not S.UIVisible
        ScreenGui.Enabled=S.UIVisible
    end
end)

----------------------------------------------------------------
-- AIMBOT
----------------------------------------------------------------
local FOVCircle     = Drawing.new("Circle")
FOVCircle.Visible   = false
FOVCircle.Radius    = 150
FOVCircle.Color     = Color3.fromRGB(255,255,255)
FOVCircle.Thickness = 1
FOVCircle.Filled    = false
FOVCircle.NumSides  = 64

RunService.RenderStepped:Connect(function()
    FOVCircle.Position=GetCenter()
    FOVCircle.Radius=S.AimbotFOV
    FOVCircle.Visible=S.AimbotEnabled and S.AimbotFOVCirc
    if not S.AimbotEnabled then return end
    if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end
    local target=GetFOVTarget(); if not target then return end
    local part=GetPart(target,"Head"); if not part then return end
    local aimWorld=S.AimbotPredict and (Predict(GetRoot(target),S.AimbotPredF) or part.Position) or part.Position
    local aimVP=Camera:WorldToViewportPoint(aimWorld)
    local aimVec=Vector2.new(aimVP.X,aimVP.Y)
    local delta=aimVec-GetCenter()
    if delta.Magnitude>1 then mousemoverel(delta.X/S.AimbotSmooth,delta.Y/S.AimbotSmooth) end
end)

----------------------------------------------------------------
-- SILENT AIM
----------------------------------------------------------------
local OrigWSP=safeHook(Camera.WorldToScreenPoint,function(self,worldPos)
    if S.SilentAim then
        if math.random(1,100)<=S.SilentChance then
            local target=GetFOVTarget()
            if target then
                local part=GetPart(target,"Head")
                if part then
                    worldPos=S.SilentPredict and (Predict(GetRoot(target),S.SilentPredF) or part.Position) or part.Position
                end
            end
        end
    end
    return OrigWSP(self,worldPos)
end)

----------------------------------------------------------------
-- TRIGGERBOT
----------------------------------------------------------------
local tLast=0; local tCount=0; local tBurst=0
local tCool=false; local tPrev=nil

local OP=OverlapParams.new()
OP.FilterType=Enum.RaycastFilterType.Exclude

RunService.Heartbeat:Connect(function()
    if not S.TriggerEnabled then tCount=0; tPrev=nil; return end
    if S.TriggerHold then
        if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then tCount=0; return end
    end
    local now=tick()
    local gap=S.TriggerBurst/1000
    if tCool then
        if now-tBurst>=gap then tCool=false; tCount=0 else return end
    end
    if tCount>=S.TriggerMaxCPS then tCool=true; tBurst=now; return end
    local lc=LocalPlayer.Character
    OP.FilterDescendantsInstances=lc and {lc} or {}
    local center=GetCenter(); local found=false; local fp=nil
    for _,p in ipairs(Players:GetPlayers()) do
        if p==LocalPlayer or not IsAlive(p) then continue end
        if S.TeamCheck and p.Team==LocalPlayer.Team then continue end
        local part=GetPart(p,"HumanoidRootPart"); if not part then continue end
        local cp=S.TriggerPredict and (Predict(GetRoot(p),2) or part.Position) or part.Position
        local vp,os=W2S(cp)
        if os and (vp-center).Magnitude<S.TriggerFOV then
            local hp=Instance.new("Part")
            hp.Size=Vector3.new(0.1,0.1,0.1); hp.CFrame=CFrame.new(cp)
            hp.Anchored=true; hp.CanCollide=false; hp.Parent=workspace
            local hits=workspace:GetPartsInPart(hp,OP); hp:Destroy()
            for _,h in ipairs(hits) do
                local m=h:FindFirstAncestorOfClass("Model")
                if m then local pl=Players:GetPlayerFromCharacter(m)
                    if pl and pl~=LocalPlayer and IsAlive(pl) then found=true; fp=pl; break end
                end
            end
            if not found then found=true; fp=p end
            if found then break end
        end
    end
    if fp~=tPrev then tCount=0; tPrev=fp end
    if not found then tCount=0; return end
    local dMin=S.TriggerDelMin/1000; local dMax=S.TriggerDelMax/1000
    local delay=S.TriggerHuman and (dMin+math.random()*(dMax-dMin)) or dMin
    if now-tLast<delay then return end
    tLast=now; tCount=tCount+1
    task.spawn(function()
        local j=math.clamp(dMax*10,0.5,2.5)
        if S.TriggerHuman then mousemoverel((math.random()-.5)*j,(math.random()-.5)*j) end
        mouse1click()
        if S.TriggerHuman then task.wait(0.014+math.random()*0.018)
            mousemoverel((math.random()-.5)*j,(math.random()-.5)*j) end
    end)
end)

----------------------------------------------------------------
-- CAMLOCK
----------------------------------------------------------------
RunService.RenderStepped:Connect(function()
    if not S.CamlockEnabled then return end
    local target=GetFOVTarget(); if not target then return end
    local part=GetPart(target,"Head"); if not part then return end
    local aimPos=Predict(GetRoot(target),S.CamlockPredF) or part.Position
    local dir=(aimPos-Camera.CFrame.Position).Unit
    Camera.CFrame=Camera.CFrame:Lerp(
        CFrame.lookAt(Camera.CFrame.Position,Camera.CFrame.Position+dir),1/S.CamlockSmooth
    )
end)

----------------------------------------------------------------
-- ESP
----------------------------------------------------------------
local BONES={
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}
local CR=0.25
local function ND(t,p) local d=Drawing.new(t); for k,v in pairs(p) do d[k]=v end; return d end
local function HA(o)
    o.Box.Visible=false;o.Name.Visible=false;o.Dist.Visible=false
    o.HBG.Visible=false;o.HFG.Visible=false;o.Tr.Visible=false
    for _,l in ipairs(o.Co) do l.Visible=false end
    for _,l in ipairs(o.Bo) do l.Visible=false end
end
local function MC() local t={}; for i=1,8 do t[i]=ND("Line",{Thickness=1.5,Visible=false}) end; return t end
local function MB() local t={}; for i=1,#BONES do t[i]=ND("Line",{Thickness=1,Visible=false}) end; return t end

local EO={}
local function MkE(p)
    if p==LocalPlayer or EO[p] then return end
    EO[p]={
        Box=ND("Square",{Filled=false,Thickness=1,Visible=false}),
        Name=ND("Text",{Size=13,Center=true,Outline=true,Visible=false}),
        Dist=ND("Text",{Size=11,Center=true,Outline=true,Visible=false}),
        HBG=ND("Square",{Filled=true,Color=Color3.fromRGB(0,0,0),Visible=false}),
        HFG=ND("Square",{Filled=true,Visible=false}),
        Tr=ND("Line",{Thickness=1,Visible=false}),
        Co=MC(),Bo=MB(),FC=0,
    }
end
local function RmE(p)
    if not EO[p] then return end
    for k,v in pairs(EO[p]) do
        if type(v)=="table" then for _,d in ipairs(v) do pcall(function()d:Remove()end) end
        elseif type(v)~="number" then pcall(function()v:Remove()end) end
    end
    EO[p]=nil
end

Players.PlayerAdded:Connect(MkE)
Players.PlayerRemoving:Connect(RmE)
for _,p in ipairs(Players:GetPlayers()) do MkE(p) end

local function HPC(r)
    if r>.5 then return Color3.fromRGB(math.floor(255*(1-r)*2),255,0)
    else return Color3.fromRGB(255,math.floor(255*r*2),0) end
end

local function DC(c,tl,sz,col)
    local tr=Vector2.new(tl.X+sz.X,tl.Y);local bl=Vector2.new(tl.X,tl.Y+sz.Y)
    local br=tl+sz;local cx=sz.X*CR;local cy=sz.Y*CR
    local function s(i,f,t) c[i].From=f;c[i].To=t;c[i].Color=col;c[i].Visible=true end
    s(1,tl,tl+Vector2.new(cx,0));s(2,tl,tl+Vector2.new(0,cy))
    s(3,tr,tr-Vector2.new(cx,0));s(4,tr,tr+Vector2.new(0,cy))
    s(5,bl,bl+Vector2.new(cx,0));s(6,bl,bl-Vector2.new(0,cy))
    s(7,br,br-Vector2.new(cx,0));s(8,br,br-Vector2.new(0,cy))
end

RunService.RenderStepped:Connect(function()
    local center=GetCenter()
    local bc=Vector2.new(center.X,Camera.ViewportSize.Y)
    local ec=Color3.fromRGB(255,60,60)
    local fc=Color3.fromRGB(60,180,255)
    for _,player in ipairs(Players:GetPlayers()) do
        if player==LocalPlayer then continue end
        local o=EO[player]; if not o then continue end
        if not S.ESPEnabled or not IsAlive(player) then HA(o);continue end
        local root=GetRoot(player);local head=GetHead(player)
        if not root or not head then HA(o);continue end
        local wd=(Camera.CFrame.Position-root.Position).Magnitude
        if wd>S.ESPMaxDist then HA(o);continue end
        o.FC=(o.FC or 0)+1
        if wd>200 and o.FC%3~=0 then continue end
        local rvp,os,dep=W2S(root.Position);local hvp,hos=W2S(head.Position)
        if not os or not hos or dep<0 then HA(o);continue end
        local bH=math.abs(rvp.Y-hvp.Y)*2.15;local bW=bH*0.58
        local tl=Vector2.new(rvp.X-bW*.5,hvp.Y-bH*.07);local bS=Vector2.new(bW,bH)
        local ie=not(S.TeamCheck and player.Team==LocalPlayer.Team)
        local col=ie and ec or fc
        o.Box.Visible=S.ESPBoxes and not S.ESPCorner
        if o.Box.Visible then o.Box.Color=col;o.Box.Position=tl;o.Box.Size=bS end
        if S.ESPBoxes and S.ESPCorner then DC(o.Co,tl,bS,col)
        else for _,l in ipairs(o.Co) do l.Visible=false end end
        local hum=GetHum(player)
        local hp=hum and hum.Health or 0;local mhp=hum and hum.MaxHealth or 100
        local hpr=math.clamp(hp/math.max(mhp,1),0,1)
        o.Name.Visible=S.ESPNames;o.Name.Color=col;o.Name.Size=13
        o.Name.Text=player.DisplayName~="" and player.DisplayName or player.Name
        o.Name.Position=Vector2.new(rvp.X,tl.Y-15)
        o.Dist.Visible=S.ESPDistance;o.Dist.Color=Color3.fromRGB(200,200,200)
        o.Dist.Size=11;o.Dist.Text=math.floor(wd).."m"
        o.Dist.Position=Vector2.new(rvp.X,tl.Y+bH+2)
        local bw,bh,bx=3,bH,tl.X-6
        o.HBG.Visible=S.ESPHealthBar;o.HBG.Position=Vector2.new(bx,tl.Y);o.HBG.Size=Vector2.new(bw,bh)
        o.HFG.Visible=S.ESPHealthBar;o.HFG.Color=HPC(hpr)
        o.HFG.Position=Vector2.new(bx,tl.Y+bh*(1-hpr));o.HFG.Size=Vector2.new(bw,bh*hpr)
        o.Tr.Visible=S.ESPTracers;o.Tr.Color=Color3.fromRGB(255,255,255)
        o.Tr.From=bc;o.Tr.To=rvp;o.Tr.Thickness=1
        if S.ESPSkeleton then
            local char=GetCharacter(player)
            for i,pair in ipairs(BONES) do
                local b=o.Bo[i]
                local p1=char and char:FindFirstChild(pair[1])
                local p2=char and char:FindFirstChild(pair[2])
                if p1 and p2 then
                    local v1,o1=W2S(p1.Position);local v2,o2=W2S(p2.Position)
                    b.Visible=o1 and o2;b.From=v1;b.To=v2;b.Color=col
                else b.Visible=false end
            end
        else for _,b in ipairs(o.Bo) do b.Visible=false end end
    end
end)

----------------------------------------------------------------
-- FLY V3
----------------------------------------------------------------
local FA=nil;local FL=nil;local FB=nil
local FLV=true;local FCV=Vector3.zero

local function EnableFly()
    local char=LocalPlayer.Character; if not char then return end
    local root=char:FindFirstChild("HumanoidRootPart")
    local hum=char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    hum.PlatformStand=true
    local ok=pcall(function()
        FA=Instance.new("Attachment");FA.Parent=root
        FL=Instance.new("LinearVelocity")
        FL.Attachment0=FA;FL.VectorVelocity=Vector3.zero
        FL.MaxForce=1e6;FL.RelativeTo=Enum.ActuatorRelativeTo.World
        FL.Parent=root;FLV=true
    end)
    if not ok then
        if FA then FA:Destroy();FA=nil end
        if FL then FL:Destroy();FL=nil end
        FB=Instance.new("BodyVelocity")
        FB.Velocity=Vector3.zero;FB.MaxForce=Vector3.new(1e6,1e6,1e6)
        FB.Parent=root;FLV=false
    end
end

local function DisableFly()
    if FL then FL:Destroy();FL=nil end
    if FA then FA:Destroy();FA=nil end
    if FB then FB:Destroy();FB=nil end
    FCV=Vector3.zero
    local char=LocalPlayer.Character
    local hum=char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand=false;hum.WalkSpeed=16;hum.JumpPower=50 end
end

UserInputService.InputBegan:Connect(function(input,gpe)
    if gpe then return end
    if input.KeyCode==Enum.KeyCode.F then
        S.FlyEnabled=not S.FlyEnabled
        if S.FlyEnabled then EnableFly() else DisableFly() end
        Notify("Fly: "..(S.FlyEnabled and "ON" or "OFF"))
    end
end)

RunService.RenderStepped:Connect(function(dt)
    if S.FlyNoClip then
        local char=LocalPlayer.Character
        if char then for _,p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide=false end
        end end
    end
    if not S.FlyEnabled then return end
    if not FL and not FB then return end
    local char=LocalPlayer.Character; if not char then return end
    local root=char:FindFirstChild("HumanoidRootPart")
    local hum=char:FindFirstChildOfClass("Humanoid")
    if not root then return end
    if hum then hum.WalkSpeed=16;hum.JumpPower=50 end
    local boost=UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
    local spd=boost and S.FlyBoost or S.FlySpeed
    local cf=Camera.CFrame;local tv=Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then tv+=cf.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then tv-=cf.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then tv-=cf.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then tv+=cf.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then tv+=Vector3.new(0,1,0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then tv-=Vector3.new(0,1,0) end
    local tgv=tv.Magnitude>0 and tv.Unit*spd or Vector3.zero
    FCV=FCV:Lerp(tgv,math.clamp(S.FlyAccel*dt,0,1))
    if FLV and FL then FL.VectorVelocity=FCV elseif FB then FB.Velocity=FCV end
    root.CFrame=CFrame.new(root.Position,root.Position+cf.LookVector)
end)

LocalPlayer.CharacterAdded:Connect(function()
    FL=nil;FA=nil;FB=nil;FCV=Vector3.zero
    if S.FlyEnabled then task.wait(0.5);EnableFly() end
end)

Notify("Kori loaded — Left Alt toggles UI")
