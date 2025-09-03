-- DogHub_MM2.lua
-- Dog Hub | MM2 - Rayfield UI version
-- Converted from WindUI-based KRT Hub MM2 script provided by user.
-- Keeps (nearly) all functionalities: Character, ESP, Teleport, Aimbot, AutoFarm, Innocent/Murder/Sheriff tools,
-- Gun system, Settings (Hitbox/Noclip/Anti-AFK/AutoInject), Server tools, Config save/load, Themes (basic), Socials, Changelogs.
-- Note: Rayfield doesn't expose per-color theming like WindUI; we provide basic theme & UI toggles instead.

-- Boot Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- ========== WINDOW ==========
local Window = Rayfield:CreateWindow({
    Name = "Dog Hub | MM2",
    LoadingTitle = "Dog Hub",
    LoadingSubtitle = "Rayfield • MM2 Utilities",
    Theme = "Default",
    DisableRayfieldPrompts = false,
    ToggleUIKeybind = Enum.KeyCode.K,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "DogHub",
        FileName = "DogHub_MM2_Config"
    }
})

-- Quick notify helper
local function notify(t,c,d) Rayfield:Notify({Title=t or "Dog Hub", Content=c or "", Duration=d or 3}) end

-- Tabs
local TabMain       = Window:CreateTab("Main", "terminal")
local TabCharacter  = Window:CreateTab("Character", "file-cog")
local TabTeleport   = Window:CreateTab("Teleport", "user")
local TabESP        = Window:CreateTab("ESP", "eye")
local TabAimbot     = Window:CreateTab("Aimbot", "target")
local TabAutoFarm   = Window:CreateTab("AutoFarm", "zap")
local TabInnocent   = Window:CreateTab("Innocent", "circle")
local TabMurder     = Window:CreateTab("Murder", "sword")
local TabSheriff    = Window:CreateTab("Sheriff", "shield")
local TabServer     = Window:CreateTab("Server", "atom")
local TabSettings   = Window:CreateTab("Settings", "settings")
local TabConfig     = Window:CreateTab("Configuration", "sliders")
local TabThemes     = Window:CreateTab("Themes", "palette")
local TabChangelogs = Window:CreateTab("Changelogs", "info")
local TabSocials    = Window:CreateTab("Socials", "star")

-- Services
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local Workspace          = game:GetService("Workspace")
local CurrentCamera      = Workspace.CurrentCamera
local HttpService        = game:GetService("HttpService")
local TeleportService    = game:GetService("TeleportService")
local LocalPlayer        = Players.LocalPlayer

-- Constants
local MAPS = {
    "ResearchFacility","Hospital3","MilBase","House2","Workplace","Mansion2",
    "BioLab","Hotel","Factory","Bank2","PoliceStation","Research Facility","Lobby"
}

-- MAIN (simple tips)
TabMain:CreateParagraph({Title="Dog Hub | MM2", Content="Nhấn K để ẩn/hiện UI. Cấu hình được lưu tự động vào /workspace/DogHub."})
TabMain:CreateButton({Name="Reload Dog Hub", Callback=function()
    notify("Dog Hub","Reloading...",2)
    task.spawn(function() loadstring(game:HttpGet("https://pastefy.app/le3JMGVe/raw", true))() end)
end})

-- ========== CHARACTER ==========
local CharacterSettings = {
    WalkSpeed = {Value = 16, Default = 16, Locked = false},
    JumpPower = {Value = 50, Default = 50, Locked = false}
}
local function updateCharacter()
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    if not CharacterSettings.WalkSpeed.Locked then
        humanoid.WalkSpeed = CharacterSettings.WalkSpeed.Value
    end
    if not CharacterSettings.JumpPower.Locked then
        humanoid.JumpPower = CharacterSettings.JumpPower.Value
    end
end
TabCharacter:CreateSection("Walkspeed")
TabCharacter:CreateSlider({
    Name="Walkspeed", Range={0,200}, Increment=1, CurrentValue=16,
    Callback=function(v) CharacterSettings.WalkSpeed.Value=v; updateCharacter() end
})
TabCharacter:CreateButton({Name="Reset Walkspeed", Callback=function()
    CharacterSettings.WalkSpeed.Value = CharacterSettings.WalkSpeed.Default; updateCharacter()
end})
TabCharacter:CreateToggle({
    Name="Block Walkspeed", CurrentValue=false,
    Callback=function(state) CharacterSettings.WalkSpeed.Locked=state; updateCharacter() end
})
TabCharacter:CreateSection("JumpPower")
TabCharacter:CreateSlider({
    Name="JumpPower", Range={0,200}, Increment=1, CurrentValue=50,
    Callback=function(v) CharacterSettings.JumpPower.Value=v; updateCharacter() end
})
TabCharacter:CreateButton({Name="Reset JumpPower", Callback=function()
    CharacterSettings.JumpPower.Value = CharacterSettings.JumpPower.Default; updateCharacter()
end})
TabCharacter:CreateToggle({
    Name="Block JumpPower", CurrentValue=false,
    Callback=function(state) CharacterSettings.JumpPower.Locked=state; updateCharacter() end
})

-- ========== ROLES & UTILS ==========
local roles, Murder, Sheriff, Hero = {}, nil, nil, nil
local function IsAlive(plr)
    if not plr then return false end
    for name, data in pairs(roles) do
        if name == plr.Name then
            return not data.Killed and not data.Dead
        end
    end
    return false
end
local function UpdateRoles()
    local ok, data = pcall(function()
        return ReplicatedStorage:FindFirstChild("GetPlayerData", true):InvokeServer()
    end)
    if ok and typeof(data)=="table" then
        roles, Murder, Sheriff, Hero = data, nil, nil, nil
        for name, info in pairs(roles) do
            if info.Role == "Murderer" then Murder = name end
            if info.Role == "Sheriff"  then Sheriff = name end
            if info.Role == "Hero"     then Hero = name end
        end
    end
end

-- ========== ESP ==========
local ESPCfg = {
    Murderer=false, Sheriff=false, Innocent=false, GunDrop=false
}
local function ensureHighlight(character)
    if not character then return nil end
    local h = character:FindFirstChildOfClass("Highlight")
    if not h then
        h = Instance.new("Highlight")
        h.Adornee = character
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = character
    end
    return h
end
local function updatePlayerESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local h = plr.Character:FindFirstChildOfClass("Highlight")
            local on, color = false, Color3.fromRGB(0,255,0)
            if ESPCfg.Murderer and (plr.Name == Murder) and IsAlive(plr) then
                color, on = Color3.fromRGB(255,0,0), true
            elseif ESPCfg.Sheriff and (plr.Name == Sheriff) and IsAlive(plr) then
                color, on = Color3.fromRGB(0,0,255), true
            elseif ESPCfg.Innocent and IsAlive(plr) and (plr.Name ~= Murder) and (plr.Name ~= Sheriff) and (plr.Name ~= Hero) then
                color, on = Color3.fromRGB(0,255,0), true
            elseif ESPCfg.Sheriff and (plr.Name == Hero) and IsAlive(plr) and (not IsAlive(Players[Sheriff] or nil)) then
                color, on = Color3.fromRGB(255,250,0), true
            end
            if on then
                h = h or ensureHighlight(plr.Character)
                if h then
                    h.FillColor = color
                    h.OutlineColor = color
                    h.Enabled = true
                end
            elseif h then
                h.Enabled = false
            end
        end
    end
end

local function markGunDrop(g)
    if not g then return end
    local hl = g:FindFirstChild("DogHub_GunDropHL")
    if not hl then
        hl = Instance.new("Highlight")
        hl.Name = "DogHub_GunDropHL"
        hl.Adornee = g
        hl.FillColor = Color3.fromRGB(255,215,0)
        hl.OutlineColor = Color3.fromRGB(255,165,0)
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = g
    end
end
local function refreshGunDrops()
    for _, mapName in ipairs(MAPS) do
        local map = Workspace:FindFirstChild(mapName)
        if map then
            local gunDrop = map:FindFirstChild("GunDrop")
            if gunDrop then
                if ESPCfg.GunDrop then
                    markGunDrop(gunDrop)
                else
                    local old = gunDrop:FindFirstChild("DogHub_GunDropHL")
                    if old then old:Destroy() end
                end
            end
        end
    end
end
for _, mapName in ipairs(MAPS) do
    local map = Workspace:FindFirstChild(mapName)
    if map then
        map.ChildAdded:Connect(function(child)
            if child.Name=="GunDrop" and ESPCfg.GunDrop then task.wait(0.2); markGunDrop(child) end
        end)
        map.ChildRemoved:Connect(function(child)
            if child.Name=="GunDrop" then local h=child:FindFirstChild("DogHub_GunDropHL"); if h then h:Destroy() end end
        end)
    end
end

TabESP:CreateSection("Special ESP")
TabESP:CreateToggle({Name="Highlight Murderer", CurrentValue=false, Callback=function(v) ESPCfg.Murderer=v end})
TabESP:CreateToggle({Name="Highlight Sheriff",  CurrentValue=false, Callback=function(v) ESPCfg.Sheriff=v end})
TabESP:CreateToggle({Name="Highlight Innocent", CurrentValue=false, Callback=function(v) ESPCfg.Innocent=v end})
TabESP:CreateToggle({
    Name="GunDrop Highlight", CurrentValue=false, Callback=function(v) ESPCfg.GunDrop=v; refreshGunDrops() end
})

RunService.RenderStepped:Connect(function()
    pcall(UpdateRoles)
    if ESPCfg.Murderer or ESPCfg.Sheriff or ESPCfg.Innocent then pcall(updatePlayerESP) end
    if ESPCfg.GunDrop then pcall(refreshGunDrops) end
end)

-- ========== TELEPORT ==========
TabTeleport:CreateSection("Default TP")
local teleportTarget = nil
local tpDropdown = nil

local function buildPlayersList()
    local list = {"Select Player"}
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer then table.insert(list, pl.Name) end
    end
    return list
end

tpDropdown = TabTeleport:CreateDropdown({
    Name="Players",
    Options = buildPlayersList(),
    CurrentOption = {"Select Player"},
    MultipleOptions = false,
    Callback=function(opts)
        local selected = opts[1]
        if selected and selected ~= "Select Player" then
            teleportTarget = Players:FindFirstChild(selected)
        else teleportTarget = nil end
    end
})
TabTeleport:CreateButton({Name="Update players list", Callback=function()
    tpDropdown:Refresh(buildPlayersList(), true)
end})
TabTeleport:CreateButton({Name="Teleport to player", Callback=function()
    if teleportTarget and teleportTarget.Character then
        local targetRoot = teleportTarget.Character:FindFirstChild("HumanoidRootPart")
        local localRoot  = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if targetRoot and localRoot then
            localRoot.CFrame = targetRoot.CFrame
            notify("Teleport","Teleported to "..teleportTarget.Name,2)
        end
    else
        notify("Teleport","Target unavailable",2)
    end
end})
TabTeleport:CreateSection("Special TP")
TabTeleport:CreateButton({Name="Teleport to Lobby", Callback=function()
    local lobby = Workspace:FindFirstChild("Lobby")
    if not lobby then notify("Teleport","Lobby not found",2) return end
    local spawnPoint = lobby:FindFirstChild("SpawnPoint") or lobby:FindFirstChildOfClass("SpawnLocation") or lobby:FindFirstChildWhichIsA("BasePart") or lobby
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp and spawnPoint then
        hrp.CFrame = CFrame.new(spawnPoint.Position + Vector3.new(0,3,0))
        notify("Teleport","Teleported to Lobby",2)
    end
end})
TabTeleport:CreateButton({Name="Teleport to Sheriff", Callback=function()
    UpdateRoles()
    if not Sheriff then notify("Teleport","Sheriff not set",2) return end
    local p = Players:FindFirstChild(Sheriff)
    local tr = p and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
    local lr = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if tr and lr then lr.CFrame = tr.CFrame; notify("Teleport","To Sheriff: "..Sheriff,2) else notify("Teleport","Sheriff unavailable",2) end
end})
TabTeleport:CreateButton({Name="Teleport to Murderer", Callback=function()
    UpdateRoles()
    if not Murder then notify("Teleport","Murderer not set",2) return end
    local p = Players:FindFirstChild(Murder)
    local tr = p and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
    local lr = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if tr and lr then lr.CFrame = tr.CFrame; notify("Teleport","To Murderer: "..Murder,2) else notify("Teleport","Murderer unavailable",2) end
end})

-- Keep dropdown fresh
Players.PlayerAdded:Connect(function() task.wait(1); tpDropdown:Refresh(buildPlayersList(), true) end)
Players.PlayerRemoving:Connect(function() tpDropdown:Refresh(buildPlayersList(), true) end)

-- ========== AIMBOT (Spectate & Camera Lock) ==========
TabAimbot:CreateSection("Default Aimbot")
local lockedRole = nil
TabAimbot:CreateDropdown({
    Name="Target Role", Options={"None","Sheriff","Murderer"}, CurrentOption={"None"}, MultipleOptions=false,
    Callback=function(opts) local sel = opts[1]; lockedRole = (sel ~= "None") and sel or nil end
})

local isSpectating, isCameraLocked = false, false
local originalCameraType = CurrentCamera.CameraType
local originalCameraSubject = CurrentCamera.CameraSubject

TabAimbot:CreateToggle({
    Name="Spectate Mode", CurrentValue=false,
    Callback=function(state)
        isSpectating = state
        if state then
            originalCameraType = CurrentCamera.CameraType
            originalCameraSubject = CurrentCamera.CameraSubject
            CurrentCamera.CameraType = Enum.CameraType.Scriptable
        else
            CurrentCamera.CameraType = originalCameraType
            CurrentCamera.CameraSubject = originalCameraSubject
        end
    end
})
TabAimbot:CreateToggle({
    Name="Lock Camera", CurrentValue=false,
    Callback=function(state)
        isCameraLocked = state
        if (not state and not isSpectating) then
            CurrentCamera.CameraType = originalCameraType
            CurrentCamera.CameraSubject = originalCameraSubject
        end
    end
})

local function GetTargetPosition()
    if not lockedRole then return nil end
    local targetName = (lockedRole == "Sheriff") and Sheriff or Murder
    if not targetName then return nil end
    local player = Players:FindFirstChild(targetName)
    if not (player and IsAlive(player) and player.Character) then return nil end
    local head = player.Character:FindFirstChild("Head")
    return head and head.Position
end
local function UpdateSpectate()
    if not (isSpectating and lockedRole) then return end
    local targetName = (lockedRole == "Sheriff") and Sheriff or Murder
    if not targetName then return end
    local targetChar = Players:FindFirstChild(targetName).Character
    if not targetChar then return end
    local root = targetChar:FindFirstChild("HumanoidRootPart")
    if root then
        CurrentCamera.CFrame = root.CFrame * CFrame.new(0,2,8)
    end
end
local function UpdateLockCamera()
    if not (isCameraLocked and lockedRole) then return end
    local targetPos = GetTargetPosition()
    if not targetPos then return end
    local currentPos = CurrentCamera.CFrame.Position
    CurrentCamera.CFrame = CFrame.new(currentPos, targetPos)
end
RunService.RenderStepped:Connect(function()
    UpdateRoles()
end)
RunService.RenderStepped:Connect(function()
    if isSpectating then UpdateSpectate() elseif isCameraLocked then UpdateLockCamera() end
end)

TabAimbot:CreateParagraph({Title="Silent Aimbot", Content="(Đang rework theo bản gốc)"})

-- ========== AUTOFARM COIN ==========
TabAutoFarm:CreateSection("Coin Farming")
local AF = {
    Enabled=false, Mode="Teleport", TeleportDelay=0, MoveSpeed=50, WalkSpeed=32, Interval=0.5,
    CoinContainers = {"Factory","Hospital3","MilBase","House2","Workplace","Mansion2","BioLab","Hotel","Bank2","PoliceStation","ResearchFacility","Lobby"}
}
local function findNearestCoin()
    local chr = LocalPlayer.Character
    local hrp = chr and chr:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local best, bestD = nil, math.huge
    for _, name in ipairs(AF.CoinContainers) do
        local container = Workspace:FindFirstChild(name)
        if container then
            local coins = (name=="Lobby") and container or container:FindFirstChild("CoinContainer")
            if coins then
                for _, coin in ipairs(coins:GetChildren()) do
                    if coin:IsA("BasePart") then
                        local d = (hrp.Position - coin.Position).Magnitude
                        if d < bestD then bestD, best = d, coin end
                    end
                end
            end
        end
    end
    return best
end
local function tpTo(pos)
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.CFrame = CFrame.new(pos) end
end
local function smoothTo(pos, speed)
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local s, t = hrp.Position, pos
    local dist = (s - t).Magnitude
    local dur = math.max(0.05, dist / math.max(20, speed))
    local t0 = tick()
    while AF.Enabled and tick()-t0 < dur do
        hrp.CFrame = CFrame.new(s:Lerp(t, (tick()-t0)/dur))
        task.wait()
    end
end
local function walkTo(pos, ws)
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    hum.WalkSpeed = ws
    hum:MoveTo(pos + Vector3.new(0,0,3))
    local t0 = tick()
    while AF.Enabled and hum.MoveDirection.Magnitude > 0 and tick()-t0 < 10 do task.wait(0.25) end
end
local function collect(coin)
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not (hrp and coin) then return end
    pcall(function() firetouchinterest(hrp, coin, 0); firetouchinterest(hrp, coin, 1) end)
end

local function farmLoop()
    while AF.Enabled do
        local coin = findNearestCoin()
        if coin then
            local target = coin.Position + Vector3.new(0,3,0)
            if AF.Mode=="Teleport" then tpTo(target); if AF.TeleportDelay>0 then task.wait(AF.TeleportDelay) end
            elseif AF.Mode=="Smooth" then smoothTo(target, AF.MoveSpeed)
            else walkTo(target, AF.WalkSpeed) end
            collect(coin)
        else
            notify("AutoFarm","No coins found nearby!",2)
            task.wait(1)
        end
        task.wait(AF.Interval)
    end
end

TabAutoFarm:CreateDropdown({
    Name="Movement Mode", Options={"Teleport","Smooth","Walk"}, CurrentOption={"Teleport"}, MultipleOptions=false,
    Callback=function(opts) AF.Mode = opts[1] or "Teleport"; notify("AutoFarm","Mode: "..AF.Mode,2) end
})
TabAutoFarm:CreateSlider({Name="Teleport Delay (s)", Range={0,1}, Increment=0.1, CurrentValue=0, Callback=function(v) AF.TeleportDelay=v end})
TabAutoFarm:CreateSlider({Name="Smooth Move Speed", Range={20,200}, Increment=1, CurrentValue=50, Callback=function(v) AF.MoveSpeed=v end})
TabAutoFarm:CreateSlider({Name="Walk Speed",        Range={16,100}, Increment=1, CurrentValue=32, Callback=function(v) AF.WalkSpeed=v end})
TabAutoFarm:CreateSlider({Name="Check Interval (s)",Range={0.1,2},  Increment=0.1, CurrentValue=0.5, Callback=function(v) AF.Interval=v end})
TabAutoFarm:CreateToggle({
    Name="Enable AutoFarm", CurrentValue=false,
    Callback=function(on) AF.Enabled=on; if on then task.spawn(farmLoop) notify("AutoFarm","Started!",2) else notify("AutoFarm","Stopped",2) end end
})

-- ========== GUN SYSTEM & INNOCENT TOOLS ==========
TabInnocent:CreateSection("GunDrop & Gun")
local gunNotify = true
TabInnocent:CreateToggle({Name="Notify GunDrop", CurrentValue=true, Callback=function(s) gunNotify=s end})

local function ScanGunDrops()
    local found = {}
    for _, name in ipairs(MAPS) do
        local map = Workspace:FindFirstChild(name)
        if map then
            local gunDrop = map:FindFirstChild("GunDrop")
            if gunDrop then table.insert(found, gunDrop) end
        end
    end
    local rootGun = Workspace:FindFirstChild("GunDrop")
    if rootGun then table.insert(found, rootGun) end
    return found
end

local function EquipGun()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Gun") then return true end
    local gun = LocalPlayer.Backpack:FindFirstChild("Gun")
    if gun then gun.Parent = LocalPlayer.Character; task.wait(0.1); return LocalPlayer.Character:FindFirstChild("Gun") ~= nil end
    return false
end

local function GrabGun(gunDrop)
    if not gunDrop then
        local list = ScanGunDrops()
        if #list == 0 then notify("Gun System","No gun on the map",3); return false end
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return false end
        local best, dmin = nil, math.huge
        for _, g in ipairs(list) do
            local d = (hrp.Position - g.Position).Magnitude
            if d < dmin then dmin = d; best = g end
        end
        gunDrop = best
    end
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp and gunDrop then
        hrp.CFrame = gunDrop.CFrame
        task.wait(0.3)
        local prompt = gunDrop:FindFirstChildOfClass("ProximityPrompt")
        if prompt then
            pcall(fireproximityprompt, prompt)
            notify("Gun System","Grabbed the gun!",3)
            return true
        end
    end
    return false
end

TabInnocent:CreateButton({Name="Grab Gun", Callback=function() GrabGun() end})

local AutoGrab = {Enabled=false, Interval=1}
TabInnocent:CreateToggle({Name="Auto Grab Gun", CurrentValue=false, Callback=function(state)
    AutoGrab.Enabled = state
    if state then
        task.spawn(function()
            while AutoGrab.Enabled do
                local list = ScanGunDrops()
                if (#list > 0) then
                    GrabGun(list[1])
                    task.wait(1)
                end
                task.wait(AutoGrab.Interval)
            end
        end)
        notify("Gun System","Auto Grab Gun enabled!",2)
    else
        notify("Gun System","Auto Grab Gun disabled",2)
    end
end})

local function GrabAndShootMurderer()
    if not (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Gun")) then
        if not GrabGun() then notify("Gun System","Failed to get gun!",3); return end
        task.wait(0.1)
    end
    if not EquipGun() then notify("Gun System","Failed to equip gun!",3); return end
    UpdateRoles()
    local murderer = Murder and Players:FindFirstChild(Murder) or nil
    if not (murderer and murderer.Character) then notify("Gun System","Murderer not found!",3); return end
    local tr = murderer.Character:FindFirstChild("HumanoidRootPart")
    local lr = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if tr and lr then lr.CFrame = tr.CFrame * CFrame.new(0,0,-4) task.wait(0.1) end
    local gun = LocalPlayer.Character:FindFirstChild("Gun")
    if not gun then notify("Gun System","Gun not equipped!",3); return end
    local targetPart = murderer.Character:FindFirstChild("HumanoidRootPart")
    if not targetPart then return end
    if gun:FindFirstChild("KnifeLocal") and gun.KnifeLocal:FindFirstChild("CreateBeam") then
        local args = {[1]=1, [2]=targetPart.Position, [3]="AH2"}
        gun.KnifeLocal.CreateBeam.RemoteFunction:InvokeServer(unpack(args))
        notify("Gun System","Shot the murderer!",3)
    end
end
TabInnocent:CreateButton({Name="Grab Gun & Shoot Murderer", Callback=GrabAndShootMurderer})

-- GunDrop notifications
local notifiedDrops = {}
local function checkGunDropSpawn()
    if not gunNotify then return end
    for _, name in ipairs(MAPS) do
        local map = Workspace:FindFirstChild(name)
        if map then
            local drop = map:FindFirstChild("GunDrop")
            if drop and not notifiedDrops[drop] then
                notifiedDrops[drop]=true
                notify("Gun Drop","A gun has appeared on the map: "..name,5)
            end
        end
    end
end
for _, name in ipairs(MAPS) do
    local map = Workspace:FindFirstChild(name)
    if map then
        if map:FindFirstChild("GunDrop") then checkGunDropSpawn() end
        map.ChildAdded:Connect(function(child) if child.Name=="GunDrop" then task.wait(0.5); checkGunDropSpawn() end end)
        map.ChildRemoved:Connect(function(child) if child.Name=="GunDrop" and notifiedDrops[child] then notifiedDrops[child]=nil end end)
    end
end
Workspace.ChildAdded:Connect(function(child) for _,n in ipairs(MAPS) do if child.Name==n then task.wait(1); checkGunDropSpawn() end end end)

-- ========== MURDER TOOLS ==========
TabMurder:CreateSection("Kill Functions")
local killActive = false
local attackDelay = 0.5
local targetRoles = {"Sheriff","Hero","Innocent"}

local function getPlayerRole(player)
    local data = ReplicatedStorage:FindFirstChild("GetPlayerData", true):InvokeServer()
    if data and data[player.Name] then return data[player.Name].Role end
    return nil
end
local function equipKnife()
    local character = LocalPlayer.Character; if not character then return false end
    if character:FindFirstChild("Knife") then return true end
    local knife = LocalPlayer.Backpack:FindFirstChild("Knife")
    if knife then knife.Parent = character return true end
    return false
end
local function getNearestTarget()
    local best, bestD = nil, math.huge
    local rolesData = ReplicatedStorage:FindFirstChild("GetPlayerData", true):InvokeServer()
    local lr = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not lr then return nil end
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer and pl.Character then
            local role = getPlayerRole(pl)
            local hum = pl.Character:FindFirstChild("Humanoid")
            local tr = pl.Character:FindFirstChild("HumanoidRootPart")
            if role and hum and hum.Health > 0 and tr and table.find(targetRoles, role) then
                local d = (lr.Position - tr.Position).Magnitude
                if d < bestD then bestD, best = d, pl end
            end
        end
    end
    return best
end
local function attackTarget(target)
    if not (target and target.Character) then return false end
    local hum = target.Character:FindFirstChild("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if not equipKnife() then notify("Kill Targets","No knife found!",2) return false end
    local tr = target.Character:FindFirstChild("HumanoidRootPart")
    local lr = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if tr and lr then
        lr.CFrame = CFrame.new(tr.Position + ((lr.Position - tr.Position).Unit * 2), tr.Position)
    end
    local knife = LocalPlayer.Character:FindFirstChild("Knife")
    if knife and knife:FindFirstChild("Stab") then
        for i=1,3 do knife.Stab:FireServer("Down") end
        return true
    end
    return false
end
local function killLoop()
    if killActive then return end
    killActive = true
    notify("Kill Targets","Starting attack on nearest targets...",2)
    while killActive do
        local target = getNearestTarget()
        if not target then
            notify("Kill Targets","No valid targets found!",3)
            killActive = false
            break
        end
        if attackTarget(target) then
            notify("Kill Targets","Attacked "..target.Name,1)
        end
        task.wait(attackDelay)
    end
end
local function stopKilling() killActive=false; notify("Kill Targets","Stopped",2) end

TabMurder:CreateToggle({Name="Kill All", CurrentValue=false, Callback=function(state) if state then killLoop() else stopKilling() end end})
TabMurder:CreateSlider({Name="Attack Delay", Range={0.1,2}, Increment=0.1, CurrentValue=0.5, Callback=function(v) attackDelay=v end})
TabMurder:CreateButton({Name="Equip Knife", Callback=function() if equipKnife() then notify("Knife","Knife equipped!",2) else notify("Knife","No knife found!",2) end end})

-- ========== SHERIFF TOOLS ==========
TabSheriff:CreateSection("Shot Functions")
local shotType = "Default"

TabSheriff:CreateDropdown({
    Name="Shot Type", Options={"Default","Teleport"}, CurrentOption={"Default"}, MultipleOptions=false,
    Callback=function(opts) shotType=opts[1] or "Default"; notify("Sheriff System","Shot Type: "..shotType,2) end
})

local function ShootMurderer()
    if not (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health>0) then return end
    local success, data = pcall(function() return ReplicatedStorage:FindFirstChild("GetPlayerData", true):InvokeServer() end)
    if not (success and data) then return end
    local murdererName = nil
    for name,info in pairs(data) do if info.Role=="Murderer" then murdererName=name break end end
    if not murdererName then return end
    local murderer = Players:FindFirstChild(murdererName)
    if not (murderer and murderer.Character and murderer.Character:FindFirstChild("Humanoid") and murderer.Character.Humanoid.Health>0) then return end
    local gun = LocalPlayer.Character:FindFirstChild("Gun") or LocalPlayer.Backpack:FindFirstChild("Gun")
    if (shotType=="Default") and not gun then return end
    if gun and not LocalPlayer.Character:FindFirstChild("Gun") then gun.Parent = LocalPlayer.Character end
    if shotType=="Teleport" then
        local tr = murderer.Character:FindFirstChild("HumanoidRootPart")
        local lr = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if tr and lr then lr.CFrame = tr.CFrame * CFrame.new(0,0,-4) end
    end
    gun = LocalPlayer.Character:FindFirstChild("Gun")
    if gun and gun:FindFirstChild("KnifeLocal") then
        local targetPart = murderer.Character:FindFirstChild("HumanoidRootPart")
        if targetPart then
            local args = {[1]=10, [2]=targetPart.Position, [3]="AH2"}
            gun.KnifeLocal.CreateBeam.RemoteFunction:InvokeServer(unpack(args))
        end
    end
end

TabSheriff:CreateButton({Name="Shoot murderer", Callback=ShootMurderer})

-- Draggable SHOT button
local shotButtonActive = false
local shotButton, shotButtonFrame
local buttonSize = 50

local function removeShotButton()
    if shotButton then shotButton:Destroy(); shotButton=nil end
    if shotButtonFrame then shotButtonFrame:Destroy(); shotButtonFrame=nil end
    shotButtonActive=false
    notify("Shot Button","Deactivated",2)
end

local function createShotButton()
    if shotButtonActive then return end
    local screenGui = game:GetService("CoreGui"):FindFirstChild("DogHub_SheriffGui") or Instance.new("ScreenGui")
    screenGui.Name = "DogHub_SheriffGui"; screenGui.Parent = game:GetService("CoreGui"); screenGui.ResetOnSpawn=false; screenGui.DisplayOrder=999
    shotButtonFrame = Instance.new("Frame")
    shotButtonFrame.Size = UDim2.new(0, buttonSize, 0, buttonSize)
    shotButtonFrame.Position = UDim2.new(1, -buttonSize-20, 0.5, -buttonSize/2)
    shotButtonFrame.AnchorPoint = Vector2.new(1,0.5); shotButtonFrame.BackgroundTransparency = 1; shotButtonFrame.ZIndex=100
    shotButton = Instance.new("TextButton")
    shotButton.Name="SheriffShotButton"; shotButton.Size=UDim2.new(1,0,1,0); shotButton.BackgroundColor3=Color3.fromRGB(120,120,120)
    shotButton.BackgroundTransparency=0.5; shotButton.TextColor3=Color3.fromRGB(255,255,255); shotButton.Text="SHOT"; shotButton.TextScaled=true
    shotButton.Font = Enum.Font.GothamBold; shotButton.BorderSizePixel=0; shotButton.ZIndex=101

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0,40,150); stroke.Thickness=2; stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; stroke.Transparency=0.3
    stroke.Parent = shotButton
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0.3,0); corner.Parent = shotButton

    local TweenService = game:GetService("TweenService")
    local function animatePress()
        local down = TweenService:Create(shotButton, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size=UDim2.new(0.9,0,0.9,0)})
        local up   = TweenService:Create(shotButton, TweenInfo.new(0.2, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Size=UDim2.new(1,0,1,0)})
        down:Play(); down.Completed:Wait(); up:Play()
    end

    shotButton.MouseButton1Click:Connect(function()
        animatePress()
        ShootMurderer()
    end)

    -- Dragging
    local UserInputService = game:GetService("UserInputService")
    local dragging = false
    local dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        local guiSize = game:GetService("CoreGui").AbsoluteSize
        newPos = UDim2.new(math.clamp(newPos.X.Scale,0,1), math.clamp(newPos.X.Offset,0, guiSize.X - buttonSize), math.clamp(newPos.Y.Scale,0,1), math.clamp(newPos.Y.Offset,0, guiSize.Y - buttonSize))
        shotButtonFrame.Position = newPos
    end
    shotButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = input.Position; startPos = shotButtonFrame.Position
        end
    end)
    shotButton.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then update(input) end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging=false end
    end)

    shotButton.Parent = shotButtonFrame
    shotButtonFrame.Parent = screenGui
    shotButtonActive = true
    notify("Sheriff System","Shot button activated",2)
end

TabSheriff:CreateSection("Shot Button")
TabSheriff:CreateButton({Name="Toggle Shot Button", Callback=function()
    if shotButtonActive then removeShotButton() else createShotButton() end
end})
TabSheriff:CreateSlider({Name="Button Size", Range={10,100}, Increment=1, CurrentValue=50, Callback=function(size)
    buttonSize = size
    local pos = shotButtonFrame and shotButtonFrame.Position or UDim2.new(1, -buttonSize-20, 0.5, -buttonSize/2)
    if shotButtonActive then removeShotButton(); createShotButton(); if shotButtonFrame then shotButtonFrame.Position = pos end end
    notify("Sheriff System","Size: "..tostring(size),2)
end})

-- ========== SETTINGS (Hitbox / Noclip / Anti-AFK / AutoInject) ==========
TabSettings:CreateSection("Hitboxes")
local Settings = {
    Hitbox = {Enabled=false, Size=5, Color=Color3.new(1,0,0), HBConn=nil, Adornments={}},
    Noclip = {Enabled=false, Conn=nil},
    AntiAFK = {Enabled=false, Conn=nil},
    AutoInject = {Enabled=false, ScriptURL="https://raw.githubusercontent.com/Snowt-Team/KRT-HUB/refs/heads/main/MM2.txt"}
}

local function UpdateHitboxes()
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer then
            local chr = pl.Character
            local box = Settings.Hitbox.Adornments[pl]
            if chr and Settings.Hitbox.Enabled then
                local root = chr:FindFirstChild("HumanoidRootPart")
                if root then
                    if not box then
                        box = Instance.new("BoxHandleAdornment")
                        box.Adornee = root
                        box.Size = Vector3.new(Settings.Hitbox.Size, Settings.Hitbox.Size, Settings.Hitbox.Size)
                        box.Color3 = Settings.Hitbox.Color
                        box.Transparency = 0.4
                        box.ZIndex = 10
                        box.AlwaysOnTop = true
                        box.Parent = root
                        Settings.Hitbox.Adornments[pl] = box
                    else
                        box.Size = Vector3.new(Settings.Hitbox.Size, Settings.Hitbox.Size, Settings.Hitbox.Size)
                        box.Color3 = Settings.Hitbox.Color
                    end
                end
            elseif box then
                box:Destroy()
                Settings.Hitbox.Adornments[pl] = nil
            end
        end
    end
end

TabSettings:CreateToggle({Name="Hitboxes", CurrentValue=false, Callback=function(state)
    Settings.Hitbox.Enabled=state
    if state then
        if not Settings.Hitbox.HBConn then Settings.Hitbox.HBConn = RunService.Heartbeat:Connect(UpdateHitboxes) end
    else
        if Settings.Hitbox.HBConn then Settings.Hitbox.HBConn:Disconnect(); Settings.Hitbox.HBConn=nil end
        for _, box in pairs(Settings.Hitbox.Adornments) do if box then box:Destroy() end end
        Settings.Hitbox.Adornments = {}
    end
end})
TabSettings:CreateSlider({Name="Hitbox size", Range={1,10}, Increment=1, CurrentValue=5, Callback=function(v) Settings.Hitbox.Size=v; UpdateHitboxes() end})
TabSettings:CreateColorPicker({Name="Hitbox color", Color=Color3.new(1,0,0), Callback=function(col) Settings.Hitbox.Color=col; UpdateHitboxes() end})

TabSettings:CreateSection("Character Functions")
TabSettings:CreateToggle({Name="Anti-AFK", CurrentValue=false, Callback=function(state)
    Settings.AntiAFK.Enabled = state
    if state then
        if not Settings.AntiAFK.Conn then
            Settings.AntiAFK.Conn = RunService.Heartbeat:Connect(function()
                pcall(function() local vu=game:GetService("VirtualUser"); vu:CaptureController(); vu:ClickButton2(Vector2.new()) end)
            end)
        end
    else
        if Settings.AntiAFK.Conn then Settings.AntiAFK.Conn:Disconnect(); Settings.AntiAFK.Conn=nil end
    end
end})
TabSettings:CreateToggle({Name="NoClip", CurrentValue=false, Callback=function(state)
    Settings.Noclip.Enabled = state
    if state then
        if not Settings.Noclip.Conn then
            Settings.Noclip.Conn = RunService.Stepped:Connect(function()
                local chr = LocalPlayer.Character
                if chr then
                    for _, part in ipairs(chr:GetDescendants()) do
                        if part:IsA("BasePart") then part.CanCollide = false end
                    end
                end
            end)
        end
    else
        if Settings.Noclip.Conn then Settings.Noclip.Conn:Disconnect(); Settings.Noclip.Conn=nil end
    end
end})

TabSettings:CreateSection("Auto Inject")
TabSettings:CreateToggle({Name="Auto Inject on Rejoin/Hop", CurrentValue=false, Callback=function(state)
    Settings.AutoInject.Enabled = state
    if state then
        notify("Auto Inject","Enabled. Script will reinject automatically.",3)
    else
        notify("Auto Inject","Disabled.",2)
    end
end})
local function SetupAutoInject()
    if not Settings.AutoInject.Enabled then return end
    task.spawn(function()
        task.wait(2)
        if Settings.AutoInject.Enabled then pcall(function() loadstring(game:HttpGet(Settings.AutoInject.ScriptURL))() end) end
    end)
    LocalPlayer.OnTeleport:Connect(function(s)
        if s == Enum.TeleportState.Started and Settings.AutoInject.Enabled then
            queue_on_teleport([[wait(2) loadstring(game:HttpGet("]]..Settings.AutoInject.ScriptURL..[[",true))()]])
        end
    end)
end
SetupAutoInject()
TabSettings:CreateButton({Name="Manual Re-Inject", Callback=function()
    pcall(function() loadstring(game:HttpGet(Settings.AutoInject.ScriptURL))() end)
    notify("Manual Inject","Reinjected!",2)
end})

-- ========== SERVER TOOLS ==========
TabServer:CreateButton({Name="Rejoin", Callback=function()
    local ok,err = pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
    if not ok then warn("Rejoin error:", err) end
end})
TabServer:CreateButton({Name="Server Hop", Callback=function()
    local placeId = game.PlaceId
    local currentJobId = game.JobId
    local function hop()
        local servers = {}
        local ok, result = pcall(function()
            return HttpService:JSONDecode(HttpService:GetAsync("https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Asc&limit=100"))
        end)
        if ok and result and result.data then
            for _, server in ipairs(result.data) do if server.id ~= currentJobId then table.insert(servers, server) end end
            if #servers > 0 then TeleportService:TeleportToPlaceInstance(placeId, servers[math.random(#servers)].id) else TeleportService:Teleport(placeId) end
        else TeleportService:Teleport(placeId) end
    end
    pcall(hop)
end})
TabServer:CreateButton({Name="Join to Lower Server", Callback=function()
    local placeId = game.PlaceId
    local currentJobId = game.JobId
    local function joinLow()
        local servers = {}
        local ok, result = pcall(function()
            return HttpService:JSONDecode(HttpService:GetAsync("https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Asc&limit=100"))
        end)
        if ok and result and result.data then
            for _, server in ipairs(result.data) do
                if (server.id ~= currentJobId) and (server.playing < (server.maxPlayers or 30)) then table.insert(servers, server) end
            end
            table.sort(servers, function(a,b) return a.playing < b.playing end)
            if #servers > 0 then TeleportService:TeleportToPlaceInstance(placeId, servers[1].id) else TeleportService:Teleport(placeId) end
        else TeleportService:Teleport(placeId) end
    end
    pcall(joinLow)
end})

-- ========== CONFIG SAVE/LOAD (BASIC) ==========
local folderPath = "DogHub"
pcall(makefolder, folderPath)

local function SaveFile(fileName, data)
    local path = folderPath.."/"..fileName..".json"
    local json = HttpService:JSONEncode(data)
    writefile(path, json)
end
local function LoadFile(fileName)
    local path = folderPath.."/"..fileName..".json"
    if isfile(path) then
        local json = readfile(path)
        return HttpService:JSONDecode(json)
    end
end
local function ListFiles()
    local files = {}
    for _, file in ipairs(listfiles(folderPath)) do
        local name = file:match("([^/]+)%.json$")
        if name then table.insert(files, name) end
    end
    return files
end

TabConfig:CreateSection("Save")
local fileNameInput = "DogHub_MM2"
TabConfig:CreateInput({Name="Write File Name", PlaceholderText="Enter file name", OnEnter=true, RemoveTextAfterFocusLost=false, Callback=function(text) fileNameInput = text end})
TabConfig:CreateButton({Name="Save File", Callback=function()
    if fileNameInput ~= "" then SaveFile(fileNameInput, {Theme="Default"}) notify("Save","Saved "..fileNameInput,2) end
end})

TabConfig:CreateSection("Load")
local filesDropdown = TabConfig:CreateDropdown({
    Name="Select File", Options=ListFiles(), CurrentOption={}, MultipleOptions=false,
    Callback=function(selected) fileNameInput = selected[1] or fileNameInput end
})
TabConfig:CreateButton({Name="Refresh List", Callback=function() filesDropdown:Refresh(ListFiles(), true) end})
TabConfig:CreateButton({Name="Load File", Callback=function()
    if fileNameInput ~= "" then
        local data = LoadFile(fileNameInput)
        if data then notify("File Loaded","Loaded data: "..HttpService:JSONEncode(data),5) end
    end
end})
TabConfig:CreateButton({Name="Overwrite File", Callback=function()
    if fileNameInput ~= "" then SaveFile(fileNameInput, {Theme="Default"}) notify("Save","Overwritten "..fileNameInput,2) end
end})

-- ========== THEMES (BASIC) ==========
TabThemes:CreateParagraph({Title="Themes", Content="Rayfield không hỗ trợ tuỳ biến màu sâu như WindUI. Bạn có thể dùng Theme mặc định và đổi ToggleUIKeybind (K)."})
TabThemes:CreateButton({Name="Toggle UI (K)", Callback=function() game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.K, false, game) end})

-- ========== SOCIALS & CHANGELOGS ==========
TabSocials:CreateParagraph({Title="SnowT", Content="My socials"})
TabSocials:CreateButton({Name="Copy KRT Hub TG", Callback=function()
    local ok = pcall(setclipboard, "https://t.me/KRT_client")
    if ok then notify("Copied","Link copied to clipboard",3) else notify("Clipboard","setclipboard not available",4) end
end})
TabSocials:CreateParagraph({Title="Kawasaki", Content="Socials My Friend"})
TabSocials:CreateButton({Name="Copy TG Channel", Callback=function()
    local ok = pcall(setclipboard, "https://t.me/+XFKScmKEPS41OWQ1")
    if ok then notify("Copied","Link copied to clipboard",3) else notify("Clipboard","setclipboard not available",4) end
end})

TabChangelogs:CreateParagraph({Title="Changelogs", Content=[[
• Silent Aimbot
• All Sheriff Functions & Shot variants (default/teleport), shot button
• All Murder Functions (Kill all)
• Innocent Functions (Grab GunDrop, Auto Grab, Grab & Shoot Murderer)
• AutoFarm Money (TP/Smooth/Walk) + interval/speeds
• ESP (Murderer/Sheriff/Innocent/Hero, GunDrop)
• Teleport (Player/Lobby/Murderer/Sheriff)
• Settings (Hitbox, Noclip, Anti-AFK, Auto Inject)
• Server Tools (Rejoin, Hop, Join low)
• Config Save/Load (basic), Themes (basic)
]]})

-- Load saved Rayfield config (keep as last)
Rayfield:LoadConfiguration()

-- Gentle reminder
notify("Dog Hub | MM2","Loaded Rayfield UI. Enjoy!",3)
