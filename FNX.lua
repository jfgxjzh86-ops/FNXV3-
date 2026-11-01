--==================================================
-- FNX HUD | Premium - OPTIMIZED & ENHANCED VERSION
--==================================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")
local Camera = workspace.CurrentCamera
local CoreGui = game:GetService("CoreGui")

-- TABLES
local connections = {}
local drawings = {}

-- NOTIFY
local function showNotify(title, text, icon)
    pcall(function()
        if WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = title,
                Content = text,
                Duration = 3,
                Icon = icon or "bell"
            })
        else
            print("[" .. tostring(title) .. "] " .. tostring(text))
        end
    end)
end

-- WINDUI
local WindUISuccess, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)

if not WindUISuccess or not WindUI then
    warn("[FNX Hud] Failed to load UI Library!")
    return
end

WindUI:AddTheme({
    Name = "PureBlack",
    Accent = Color3.fromRGB(0, 0, 0),
    Outline = Color3.fromRGB(30, 30, 30),
    Text = Color3.fromRGB(255, 255, 255),
    PlaceholderText = Color3.fromRGB(150, 150, 150),
    Background = Color3.fromRGB(15, 15, 15),
    Item = Color3.fromRGB(25, 25, 25)
})

local Window = WindUI:CreateWindow({
    Title = "FNX Hud | Open menu",
    Icon = "rbxassetid://81008815000806",
    Author = "by Start",
    Folder = "XCHudConfig",
    Size = UDim2.fromOffset(620, 480),
    MinSize = Vector2.new(560, 350),
    MaxSize = Vector2.new(850, 600),
    ToggleKey = Enum.KeyCode.LeftShift,
    Transparent = true,
    Theme = "PureBlack",
    Resizable = true,
    SideBarWidth = 200,
    HideSearchBar = true,
    ScrollBarEnabled = false,
    User = { Enabled = true, Anonymous = false }
})

Window:EditOpenButton({
    Title = "FNX Hud | Open menu",
    Icon = "rbxassetid://81008815000806",
    CornerRadius = UDim.new(0, 16),
    StrokeThickness = 2,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 150, 150)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
    }),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true,
})
Window:Tag({
    Title = "PVP | Paid",
    Icon = "github",
    Color = Color3.fromHex("#FF0000"),
    Radius = 13,
})


-- GLOBAL CONFIG & STATES
_G.SilentAimEnabled = false
_G.WalkSpeed = 16
_G.JumpPower = 50
_G.AimPart = "Head"
_G.FOV_Radius = 150
_G.FOV_Visible = false
_G.TracerEnabled = false
_G.EspEnabled = false
_G.TeamCheck = false
_G.WallCheck = true
_G.MaxDistance = 300
_G.HitboxEnabled = false
_G.HitboxSize = 3
_G.FullbrightEnabled = false
_G.InfJump = false
_G.Noclip = false
_G.AntiAFK = true
_G.BigBodyEnabled = false
_G.BigBodySize = 5
_G.CameraFOV = 70
_G.MaxZoomDistance = 128

local currentTarget = nil
local wallCheckParams = RaycastParams.new()
wallCheckParams.FilterType = Enum.RaycastFilterType.Exclude
wallCheckParams.IgnoreWater = true

local hasDrawing = typeof(Drawing) == "table" and typeof(Drawing.new) == "function"

-- DRAWING OVERLAYS SETUP
local Sides = 16
local fovLines = {}
local HeadSides = 16
local headRingLines = {}
local TracerLine

if hasDrawing then
    pcall(function()
        for i = 1, Sides do
            local line = Drawing.new("Line")
            line.Visible = false
            line.Thickness = 2
            line.Transparency = 1
            table.insert(fovLines, line)
            table.insert(drawings, line)
        end

        for i = 1, HeadSides do
            local line = Drawing.new("Line")
            line.Visible = false
            line.Thickness = 2
            line.Transparency = 1
            table.insert(headRingLines, line)
            table.insert(drawings, line)
        end

        TracerLine = Drawing.new("Line")
        TracerLine.Visible = false
        TracerLine.Thickness = 1.5
        TracerLine.Transparency = 1
        table.insert(drawings, TracerLine)
    end)
end

-- HELPER FUNCTIONS
local function isTargetValid(part)
    if not part or not part.Parent then return false end
    local humanoid = part.Parent:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function isTeammate(player)
    if not _G.TeamCheck or not player then return false end
    return player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team
end

local function isVisible(targetPart)
    if not _G.WallCheck then return true end
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Head") then return true end
    
    local origin = LocalPlayer.Character.Head.Position
    local direction = targetPart.Position - origin
    
    local ignoreList = {LocalPlayer.Character}
    if targetPart.Parent then table.insert(ignoreList, targetPart.Parent) end
    wallCheckParams.FilterDescendantsInstances = ignoreList
    
    local result = Workspace:Raycast(origin, direction, wallCheckParams)
    return result == nil
end


local function getSilentTarget()
    if not _G.SilentAimEnabled then return nil end
    local dist = math.huge
    local closest = nil
    local center = Camera.ViewportSize / 2
    local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if not localRoot then return nil end

    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and not isTeammate(v) then
            local humanoid = v.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local part = v.Character:FindFirstChild(_G.AimPart) or v.Character:FindFirstChild("Head")
                if part then
                    local distToPlayer = (part.Position - localRoot.Position).Magnitude
                    if distToPlayer <= _G.MaxDistance then
                        local pos, vis = Camera:WorldToViewportPoint(part.Position)
                        if vis and isVisible(part) then
                            local screenPos = Vector2.new(pos.X, pos.Y)
                            local mag = (screenPos - center).Magnitude
                            if mag <= _G.FOV_Radius and mag < dist then
                                dist = mag
                                closest = part
                            end
                        end
                    end
                end
            end
        end
    end
    return closest
end

-- EFFICIENT BODY RESIZING (SAFE ATTRIBUTE STORAGE)
local function updatePlayerBody(player)
    if player == LocalPlayer or not player.Character then return end
    local root = player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if not root:GetAttribute("OriginalSize") then
        root:SetAttribute("OriginalSize", root.Size)
    end

    if (_G.BigBodyEnabled or _G.HitboxEnabled) and not isTeammate(player) then
        local sz = _G.BigBodyEnabled and (_G.BigBodySize or 5) or (_G.HitboxSize or 3)
        root.Size = Vector3.new(sz, sz, sz)
        root.Transparency = 0.6
        root.Material = Enum.Material.ForceField
        root.CanCollide = false
    else
        local origSize = root:GetAttribute("OriginalSize")
        if origSize then root.Size = origSize end
        root.Transparency = 1
        root.Material = Enum.Material.Plastic
    end
end

local function applyAllPlayerBodies()
    for _, p in pairs(Players:GetPlayers()) do
        updatePlayerBody(p)
    end
end

-- HOOKS & SYSTEM EVENTS
if hookmetamethod and getnamecallmethod and checkcaller then
    pcall(function()
        local oldnc
        oldnc = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            
            if not checkcaller() and _G.SilentAimEnabled and currentTarget and self == Workspace then
                if method == "Raycast" and args[1] and args[2] then
                    local dir = currentTarget.Position - args[1]
                    if dir.Magnitude > 0 then
                        args[2] = dir.Unit * args[2].Magnitude
                        return oldnc(self, unpack(args))
                    end
                elseif (method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhiteList") and args[1] then
                    local dir = currentTarget.Position - args[1].Origin
                    if dir.Magnitude > 0 then
                        args[1] = Ray.new(args[1].Origin, dir.Unit * args[1].Direction.Magnitude)
                        return oldnc(self, unpack(args))
                    end
                end
            end
            return oldnc(self, ...)
        end))
    end)
end

-- Anti AFK
table.insert(connections, LocalPlayer.Idled:Connect(function()
    if _G.AntiAFK then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end))

-- ESP Setup & Character Spawn Hooks
local function applyESP(player)
    if player == LocalPlayer then return end
    local function setupChar(char)
        if not char then return end
        local hl = char:FindFirstChild("ProHighlight") or Instance.new("Highlight")
        hl.Name = "ProHighlight"
        hl.Adornee = char
        hl.FillTransparency = 0.5
        hl.FillColor = Color3.fromRGB(255, 0, 0)
        hl.OutlineColor = Color3.fromRGB(0, 0, 0)
        hl.Enabled = false
        hl.Parent = char

        task.delay(0.2, function() updatePlayerBody(player) end)
    end
    if player.Character then setupChar(player.Character) end
    table.insert(connections, player.CharacterAdded:Connect(setupChar))
end

for _, p in pairs(Players:GetPlayers()) do applyESP(p) end
table.insert(connections, Players.PlayerAdded:Connect(applyESP))

-- RENDER LOOP (OPTIMIZED)
local hue = 0
local targetCheckTimer = 0
local slowUpdateTimer = 0

local renderConn = RunService.RenderStepped:Connect(function(deltaTime)
    pcall(function()
        hue = (hue + (deltaTime * 0.4)) % 1

        if _G.SilentAimEnabled then
            targetCheckTimer = targetCheckTimer + deltaTime
            if targetCheckTimer >= 0.05 then
                targetCheckTimer = 0
                currentTarget = getSilentTarget()
            end
        else
            currentTarget = nil
        end
        
        if not isTargetValid(currentTarget) then
            currentTarget = nil
        end

        slowUpdateTimer = slowUpdateTimer + deltaTime
        if slowUpdateTimer >= 0.2 then
            slowUpdateTimer = 0

            if _G.FullbrightEnabled then
                Lighting.Ambient = Color3.new(1, 1, 1)
                Lighting.Brightness = 2
                Lighting.GlobalShadows = false
            end

            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local highlight = p.Character:FindFirstChild("ProHighlight")
                    if highlight then
                        highlight.Enabled = _G.EspEnabled and not isTeammate(p)
                    end
                end
            end
        end

        if LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                if hum.WalkSpeed ~= _G.WalkSpeed then hum.WalkSpeed = _G.WalkSpeed end
                if hum.UseJumpPower and hum.JumpPower ~= _G.JumpPower then hum.JumpPower = _G.JumpPower end
            end
        end

        if hasDrawing then
            local center = Camera.ViewportSize / 2
            
            if _G.FOV_Visible then
                for i = 1, Sides do
                    local a1 = ((i - 1) / Sides) * math.pi * 2
                    local a2 = (i / Sides) * math.pi * 2
                    local p1 = center + Vector2.new(math.cos(a1) * _G.FOV_Radius, math.sin(a1) * _G.FOV_Radius)
                    local p2 = center + Vector2.new(math.cos(a2) * _G.FOV_Radius, math.sin(a2) * _G.FOV_Radius)
                    local line = fovLines[i]
                    if line then
                        line.Visible = true
                        line.From = p1
                        line.To = p2
                        line.Color = Color3.fromHSV((hue + i / Sides) % 1, 1, 1)
                    end
                end
            else
                for _, line in pairs(fovLines) do line.Visible = false end
            end

            if currentTarget and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") then
                local headPart = currentTarget.Parent:FindFirstChild("Head") or currentTarget
                local headPos = headPart.Position
                local camRotation = Camera.CFrame.Rotation
                local billboardCF = CFrame.new(headPos) * camRotation
                local radius = 1.8

                for i = 1, HeadSides do
                    local a1 = ((i - 1) / HeadSides) * math.pi * 2
                    local a2 = (i / HeadSides) * math.pi * 2
                    
                    local p3D1 = billboardCF * Vector3.new(math.cos(a1) * radius, math.sin(a1) * radius, 0)
                    local p3D2 = billboardCF * Vector3.new(math.cos(a2) * radius, math.sin(a2) * radius, 0)
                    
                    local screen1, vis1 = Camera:WorldToViewportPoint(p3D1)
                    local screen2, vis2 = Camera:WorldToViewportPoint(p3D2)
                    
                    local rLine = headRingLines[i]
                    if rLine then
                        if vis1 and vis2 then
                            rLine.Visible = true
                            rLine.From = Vector2.new(screen1.X, screen1.Y)
                            rLine.To = Vector2.new(screen2.X, screen2.Y)
                            rLine.Color = Color3.fromHSV(hue, 1, 1)
                        else
                            rLine.Visible = false
                        end
                    end
                end

                if _G.TracerEnabled and TracerLine then
                    local targetPos, vis = Camera:WorldToViewportPoint(headPos)
                    if vis then
                        TracerLine.Visible = true
                        TracerLine.From = center
                        TracerLine.To = Vector2.new(targetPos.X, targetPos.Y)
                        TracerLine.Color = Color3.fromHSV(hue, 1, 1)
                    else
                        TracerLine.Visible = false
                    end
                elseif TracerLine then
                    TracerLine.Visible = false
                end
            else
                for _, rLine in pairs(headRingLines) do rLine.Visible = false end
                if TracerLine then TracerLine.Visible = false end
            end
        end
    end)
end)
table.insert(connections, renderConn)

-- Jump & Noclip Connections
table.insert(connections, UserInputService.JumpRequest:Connect(function()
    if _G.InfJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
    end
end))

table.insert(connections, RunService.Stepped:Connect(function()
    if _G.Noclip and LocalPlayer.Character then
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
            end
        end
    end
end))

-- UI TABS SETUP
local MainTab = Window:Tab({ Title = "Main", Icon = "settings" })
MainTab:Section({ Title = "Targeting Rules" })
MainTab:Toggle({
    Title = "Team Check",
    Default = false,
    Callback = function(Value) _G.TeamCheck = Value end,
})
MainTab:Toggle({
    Title = "Wall Check",
    Default = true,
    Callback = function(Value) _G.WallCheck = Value end,
})
MainTab:Slider({
    Title = "Max Distance",
    Step = 10,
    Value = { Min = 50, Max = 50000, Default = 300 },
    Callback = function(Value) _G.MaxDistance = Value end,
})

local CombatTab = Window:Tab({ Title = "Combat", Icon = "swords" })
CombatTab:Section({ Title = "Body Expansion System" })
CombatTab:Toggle({
    Title = "Enable Big Body ",
    Default = false,
    Callback = function(Value) 
        _G.BigBodyEnabled = Value 
        applyAllPlayerBodies()
        showNotify("Combat", "Big Body: " .. (Value and "Enabled" or "Disabled"))
    end,
})
CombatTab:Slider({
    Title = "Body Size",
    Step = 1,
    Value = { Min = 1, Max = 1000, Default = 5 },
    Callback = function(Value) 
        _G.BigBodySize = Value 
        if _G.BigBodyEnabled then applyAllPlayerBodies() end
    end,
})

local SilentAimTab = Window:Tab({ Title = "SilentAim", Icon = "sword" })
SilentAimTab:Section({ Title = "Silent Aim Control" })
SilentAimTab:Toggle({
    Title = "Enable SilentAim",
    Default = false,
    Callback = function(Value) 
        _G.SilentAimEnabled = Value 
        showNotify("SilentAim", "Status: " .. (Value and "Enabled" or "Disabled"))
    end,
})
SilentAimTab:Dropdown({
    Title = "Aim Part",
    Values = {"Head", "HumanoidRootPart", "UpperTorso"},
    Default = "Head",
    Callback = function(Value) _G.AimPart = Value end,
})

local FOVTab = Window:Tab({ Title = "FOV", Icon = "circle" })
FOVTab:Section({ Title = "FOV Settings" })
FOVTab:Toggle({
    Title = "Show FOV Circle",
    Default = false,
    Callback = function(Value) _G.FOV_Visible = Value end,
})
FOVTab:Slider({
    Title = "FOV Radius",
    Step = 1,
    Value = { Min = 50, Max = 500, Default = 150 },
    Callback = function(Value) _G.FOV_Radius = Value end,
})

local VisualsTab = Window:Tab({ Title = "Visuals", Icon = "eye" })
VisualsTab:Section({ Title = "ESP & Tracers" })
VisualsTab:Toggle({
    Title = "Enable ESP Highlight",
    Default = false,
    Callback = function(Value) 
        _G.EspEnabled = Value 
        showNotify("Visuals", "ESP Highlight: " .. (Value and "ON" or "OFF"))
    end,
})
VisualsTab:Toggle({
    Title = "Enable Target Tracer",
    Default = false,
    Callback = function(Value) _G.TracerEnabled = Value end,
})

local MoveTab = Window:Tab({ Title = "Movement", Icon = "zap" })
MoveTab:Section({ Title = "Movement Modifications" })
MoveTab:Slider({
    Title = "WalkSpeed",
    Step = 1,
    Value = { Min = 16, Max = 300, Default = 16 },
    Callback = function(Value) _G.WalkSpeed = Value end,
})
MoveTab:Slider({
    Title = "JumpPower",
    Step = 5,
    Value = { Min = 50, Max = 300, Default = 50 },
    Callback = function(Value) _G.JumpPower = Value end,
})
MoveTab:Toggle({
    Title = "Infinite Jump",
    Default = false,
    Callback = function(Value) _G.InfJump = Value end,
})
MoveTab:Toggle({
    Title = "Noclip",
    Default = false,
    Callback = function(Value) _G.Noclip = Value end,
})

local CameraTab = Window:Tab({ Title = "Camera", Icon = "compass" })
CameraTab:Section({ Title = "Camera & Environment" })
CameraTab:Slider({
    Title = "Camera FOV",
    Step = 1,
    Value = { Min = 70, Max = 120, Default = 70 },
    Callback = function(Value) 
        _G.CameraFOV = Value
        workspace.CurrentCamera.FieldOfView = Value 
    end,
})
CameraTab:Slider({
    Title = "Max Zoom Distance",
    Step = 100,
    Value = { Min = 128, Max = 5000, Default = 128 },
    Callback = function(Value) 
        _G.MaxZoomDistance = Value
        LocalPlayer.MaxZoomDistance = Value 
    end,
})

local FPSTab = Window:Tab({ Title = "FPS Boost", Icon = "activity" })
FPSTab:Section({ Title = "Performance Boost" })
FPSTab:Button({
    Title = "Full FPS Boost",
    Callback = function()
        pcall(function()
            local terrain = workspace:FindFirstChildOfClass("Terrain")
            if terrain then
                terrain.WaterWaveSize = 0
                terrain.WaterWaveSpeed = 0
                terrain.WaterReflectance = 0
                terrain.WaterTransparency = 0
            end
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            for _, v in pairs(game:GetDescendants()) do
                if v:IsA("BasePart") or v:IsA("UnionOperation") or v:IsA("MeshPart") then
                    v.Material = Enum.Material.SmoothPlastic
                    v.Reflectance = 0
                elseif v:IsA("Decal") or v:IsA("Texture") then
                    v:Destroy()
                elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
                    v.Enabled = false
                end
            end
            showNotify("FPS Boost", "Performance Mode Activated!")
        end)
    end,
})
FPSTab:Slider({
    Title = "Max FPS Cap",
    Step = 10,
    Value = { Min = 30, Max = 360, Default = 60 },
    Callback = function(Value)
        if setfpscap then pcall(setfpscap, Value) end
    end,
})

local ServerTab = Window:Tab({ Title = "Server & Config", Icon = "layers" })
ServerTab:Section({ Title = "Server Management" })
ServerTab:Button({
    Title = "Rejoin Server",
    Callback = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end,
})
ServerTab:Button({
    Title = "Server Hop",
    Callback = function()
        pcall(function()
            local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")).data
            for _, s in pairs(servers) do
                if s.playing < s.maxPlayers and s.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
                    break
                end
            end
        end)
    end,
})
ServerTab:Toggle({
    Title = "Anti-AFK",
    Default = true,
    Callback = function(Value) _G.AntiAFK = Value end,
})

showNotify("FNX Hud", "Optimized Script Loaded Successfully!", "rbxassetid://81008815000806")

--==================================================
-- OPTIMIZED BORDER OVERRIDE (EVENT-BASED)
--==================================================
task.spawn(function()
    local WHITE = Color3.fromRGB(255, 255, 255)
    local WHITE_SEQUENCE = ColorSequence.new(WHITE, WHITE)

    local function applyWhiteBorder(obj)
        local isWindUI = false
        local parent = obj.Parent
        while parent do
            if parent.Name == "WindUI" or parent.Name:find("WindUI") or parent.Name:find("XC_Notification") then
                isWindUI = true
                break
            end
            parent = parent.Parent
        end

        if isWindUI then
            if obj:IsA("UIGradient") then
                obj.Color = WHITE_SEQUENCE
            elseif obj:IsA("UIStroke") then
                obj.Color = WHITE
                obj.Transparency = 0
            end
        end
    end

    local guiTargets = { game:GetService("CoreGui"), LocalPlayer:FindFirstChild("PlayerGui") }
    for _, guiParent in ipairs(guiTargets) do
        if guiParent then
            for _, obj in ipairs(guiParent:GetDescendants()) do
                applyWhiteBorder(obj)
            end
            local objAddedConn = guiParent.DescendantAdded:Connect(applyWhiteBorder)
            table.insert(connections, objAddedConn)
        end
    end
end)

--==================================================
-- Tab: Visuals (แยก 5 สวิตช์อิสระ)
--==================================================
local VisualsTab = Window:Tab({ 
    Title = "ESP", 
    Icon = "eye" 
})

VisualsTab:Section({ Title = "ESP Controls" })

-- 1. สวิตช์ Box ESP (กล่องสี่เหลี่ยมขาว)
VisualsTab:Toggle({
    Title = "1. Box ESP (White Box)",
    Default = false,
    Callback = function(Value)
        _G.ESP_Box = Value
    end
})

-- 2. สวิตช์ Tracers (เส้นเชื่อมจากด้านบนกลางจอ)
VisualsTab:Toggle({
    Title = "2. Tracers ESP (Top-Center Line)",
    Default = false,
    Callback = function(Value)
        _G.ESP_Tracer = Value
    end
})

-- 3. สวิตช์ Name ESP (ชื่อผู้เล่น)
VisualsTab:Toggle({
    Title = "3. Name ESP",
    Default = false,
    Callback = function(Value)
        _G.ESP_Name = Value
    end
})

-- 4. สวิตช์ Health ESP (หลอดเลือด/เลือด)
VisualsTab:Toggle({
    Title = "4. Health ESP (Bar & Text)",
    Default = false,
    Callback = function(Value)
        _G.ESP_Health = Value
    end
})

-- 5. สวิตช์ Distance ESP (ระยะทาง)
VisualsTab:Toggle({
    Title = "5. Distance ESP",
    Default = false,
    Callback = function(Value)
        _G.ESP_Distance = Value
    end
})


--==================================================
-- ESP Backend Logic (Box + Top-Center Tracers + Info)
--==================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

_G.ESP_Box = false
_G.ESP_Tracer = false
_G.ESP_Name = false
_G.ESP_Health = false
_G.ESP_Distance = false

local espCache = {}

local function createESP(player)
    if player == LocalPlayer then return end
    
    local data = {
        Box = Drawing.new("Square"),
        Tracer = Drawing.new("Line"),
        Name = Drawing.new("Text"),
        HealthBarOutline = Drawing.new("Square"),
        HealthBar = Drawing.new("Square"),
        HealthText = Drawing.new("Text"),
        DistanceText = Drawing.new("Text")
    }
    
    -- 1. Box ESP (กล่องสีขาว)
    data.Box.Visible = false
    data.Box.Color = Color3.fromRGB(255, 255, 255)
    data.Box.Thickness = 1.5
    data.Box.Filled = false
    
    -- 2. Tracer Line (เส้นเชื่อมโยง)
    data.Tracer.Visible = false
    data.Tracer.Color = Color3.fromRGB(255, 255, 255)
    data.Tracer.Thickness = 1.5
    
    -- 3. Name
    data.Name.Visible = false
    data.Name.Color = Color3.fromRGB(255, 255, 255)
    data.Name.Size = 14
    data.Name.Center = true
    data.Name.Outline = true
    
    -- 4. Health
    data.HealthBarOutline.Thickness = 1
    data.HealthBarOutline.Filled = true
    data.HealthBarOutline.Color = Color3.fromRGB(0, 0, 0)
    data.HealthBarOutline.Visible = false
    
    data.HealthBar.Thickness = 1
    data.HealthBar.Filled = true
    data.HealthBar.Color = Color3.fromRGB(0, 255, 0)
    data.HealthBar.Visible = false
    
    data.HealthText.Size = 12
    data.HealthText.Center = true
    data.HealthText.Outline = true
    data.HealthText.Color = Color3.fromRGB(255, 255, 255)
    data.HealthText.Visible = false
    
    -- 5. Distance
    data.DistanceText.Size = 12
    data.DistanceText.Center = true
    data.DistanceText.Outline = true
    data.DistanceText.Color = Color3.fromRGB(255, 220, 0)
    data.DistanceText.Visible = false
    
    espCache[player] = data
end

local function removeESP(player)
    if espCache[player] then
        for _, obj in pairs(espCache[player]) do
            pcall(function() obj:Remove() end)
        end
        espCache[player] = nil
    end
end

for _, p in pairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(removeESP)

RunService.RenderStepped:Connect(function()
    for player, data in pairs(espCache) do
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        
        if char and root and hum and hum.Health > 0 then
            local vector, onScreen = Camera:WorldToViewportPoint(root.Position)
            
            if onScreen then
                local head = char:FindFirstChild("Head")
                local top = head and Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0)) or vector
                local bottom = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                
                local h = math.abs(top.Y - bottom.Y)
                local w = h / 2
                local leftX = vector.X - w / 2
                
                -- 1. Box ESP (กล่องสี่เหลี่ยมสีขาว)
                if _G.ESP_Box then
                    data.Box.Size = Vector2.new(w, h)
                    data.Box.Position = Vector2.new(leftX, top.Y)
                    data.Box.Visible = true
                else
                    data.Box.Visible = false
                end
                
                -- 2. Tracers ESP (เส้นเชื่อมจากจุดกลางบนสุดของหน้าจอ)
                if _G.ESP_Tracer then
                    local topCenterScreen = Vector2.new(Camera.ViewportSize.X / 2, 0) -- พิกัดตรงกลางด้านบนหน้าจอ
                    data.Tracer.From = topCenterScreen
                    data.Tracer.To = Vector2.new(vector.X, top.Y)
                    data.Tracer.Visible = true
                else
                    data.Tracer.Visible = false
                end
                
                -- 3. Name ESP
                if _G.ESP_Name then
                    data.Name.Text = player.Name
                    data.Name.Position = Vector2.new(vector.X, top.Y - 18)
                    data.Name.Visible = true
                else
                    data.Name.Visible = false
                end
                
                -- 4. Health ESP
                if _G.ESP_Health then
                    local healthPercent = hum.Health / hum.MaxHealth
                    local barHeight = h * healthPercent
                    
                    data.HealthBarOutline.Size = Vector2.new(4, h + 2)
                    data.HealthBarOutline.Position = Vector2.new(leftX - 7, top.Y - 1)
                    data.HealthBarOutline.Visible = true
                    
                    data.HealthBar.Size = Vector2.new(2, barHeight)
                    data.HealthBar.Position = Vector2.new(leftX - 6, top.Y + (h - barHeight))
                    data.HealthBar.Color = Color3.fromRGB(255 - (healthPercent * 255), healthPercent * 255, 0)
                    data.HealthBar.Visible = true
                    
                    data.HealthText.Text = "HP: " .. math.floor(hum.Health)
                    data.HealthText.Position = Vector2.new(vector.X, bottom.Y + 2)
                    data.HealthText.Visible = true
                else
                    data.HealthBarOutline.Visible = false
                    data.HealthBar.Visible = false
                    data.HealthText.Visible = false
                end
                
                -- 5. Distance ESP
                if _G.ESP_Distance then
                    local dist = math.floor((Camera.CFrame.Position - root.Position).Magnitude)
                    local yOffset = _G.ESP_Health and 16 or 2
                    data.DistanceText.Text = "[" .. dist .. "m]"
                    data.DistanceText.Position = Vector2.new(vector.X, bottom.Y + yOffset)
                    data.DistanceText.Visible = true
                else
                    data.DistanceText.Visible = false
                end
            else
                data.Box.Visible = false
                data.Tracer.Visible = false
                data.Name.Visible = false
                data.HealthBarOutline.Visible = false
                data.HealthBar.Visible = false
                data.HealthText.Visible = false
                data.DistanceText.Visible = false
            end
        else
            data.Box.Visible = false
            data.Tracer.Visible = false
            data.Name.Visible = false
            data.HealthBarOutline.Visible = false
            data.HealthBar.Visible = false
            data.HealthText.Visible = false
            data.DistanceText.Visible = false
        end
    end
end)



-- ==========================================================
-- ระบบรถบินได้สำหรับมือถือ (Car Fly Mobile with UI Buttons)
-- ==========================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

_G.CarFlyEnabled = false
_G.CarFlySpeed = 250
-- สร้างปุ่มควบคุมจำลองบนหน้าจอมือถือ
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CarFlyMobileUI"
ScreenGui.Parent = CoreGui
ScreenGui.Enabled = false

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 160, 0, 160)
MainFrame.Position = UDim2.new(0.03, 0, 0.45, -80)
MainFrame.BackgroundTransparency = 0.4
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = MainFrame

-- ฟังก์ชันสร้างปุ่มบนจอ
local function createButton(name, text, pos, size)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = size
    btn.Position = pos
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 14
    btn.Font = Enum.Font.SourceSansBold
    btn.Text = text
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn
    
    btn.Parent = MainFrame
    return btn
end

local btnForward = createButton("Forward", "เดินหน้า", UDim2.new(0.1, 0, 0.1, 0), UDim2.new(0.8, 0, 0.22, 0))
local btnBackward = createButton("Backward", "ถอยหลัง", UDim2.new(0.1, 0, 0.68, 0), UDim2.new(0.8, 0, 0.22, 0))
local btnUp = createButton("Up", "ขึ้น", UDim2.new(0.1, 0, 0.36, 0), UDim2.new(0.38, 0, 0.25, 0))
local btnDown = createButton("Down", "ลง", UDim2.new(0.52, 0, 0.36, 0), UDim2.new(0.38, 0, 0.25, 0))

local movingState = { Forward = false, Backward = false, Up = false, Down = false }

-- ดักจับการกดปุ่มบนหน้าจอ
btnForward.MouseButton1Down:Connect(function() movingState.Forward = true end)
btnForward.MouseButton1Up:Connect(function() movingState.Forward = false end)
btnForward.MouseLeave:Connect(function() movingState.Forward = false end)

btnBackward.MouseButton1Down:Connect(function() movingState.Backward = true end)
btnBackward.MouseButton1Up:Connect(function() movingState.Backward = false end)
btnBackward.MouseLeave:Connect(function() movingState.Backward = false end)

btnUp.MouseButton1Down:Connect(function() movingState.Up = true end)
btnUp.MouseButton1Up:Connect(function() movingState.Up = false end)
btnUp.MouseLeave:Connect(function() movingState.Up = false end)

btnDown.MouseButton1Down:Connect(function() movingState.Down = true end)
btnDown.MouseButton1Up:Connect(function() movingState.Down = false end)
btnDown.MouseLeave:Connect(function() movingState.Down = false end)

-- สร้าง Tab ใน WindUI
task.spawn(function()
    local timeout = 10
    local elapsed = 0
    local targetWindow = nil
    
    while not targetWindow and elapsed < timeout do
        targetWindow = Window or getgenv().Window or _G.WindUI
        if not targetWindow then
            task.wait(0.5)
            elapsed = elapsed + 0.5
        end
    end

    if targetWindow then
        local success, CarTab = pcall(function()
            return targetWindow:Tab({ 
                Title = "รถบินได้", 
                Icon = "plane" 
            })
        end)

        if success and CarTab then
            CarTab:Section({ Title = "ตั้งค่ารถบิน (มือถือ)" })
            
            CarTab:Toggle({
                Title = "เปิด/ปิด รถบินได้",
                Default = false,
                Callback = function(Value)
                    _G.CarFlyEnabled = Value
                    ScreenGui.Enabled = Value
                end
            })
            print("[Car Fly Mobile] โหลดสำเร็จ!")
        end
    end
end)

-- ระบบฟิสิกส์การบิน
RunService.RenderStepped:Connect(function()
    if not _G.CarFlyEnabled then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or not humanoid.SeatPart then return end

    local seat = humanoid.SeatPart
    local vehicle = seat.Parent
    if not vehicle:IsA("Model") then 
        vehicle = vehicle.Parent 
    end
    
    local primaryPart = vehicle.PrimaryPart or vehicle:FindFirstChild("HumanoidRootPart") or vehicle:FindFirstChildWhichIsA("BasePart")

    if primaryPart then
        primaryPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        primaryPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

        local moveDirection = Vector3.new()
        
        if movingState.Forward then moveDirection = moveDirection + Camera.CFrame.LookVector end
        if movingState.Backward then moveDirection = moveDirection - Camera.CFrame.LookVector end
        if movingState.Up then moveDirection = moveDirection + Vector3.new(0, 1, 0) end
        if movingState.Down then moveDirection = moveDirection - Vector3.new(0, 1, 0) end

        if moveDirection.Magnitude > 0 then
            primaryPart.AssemblyLinearVelocity = moveDirection.Unit * _G.CarFlySpeed
        else
            primaryPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end

        primaryPart.CFrame = CFrame.new(primaryPart.Position, primaryPart.Position + Camera.CFrame.LookVector)
    end
end)


