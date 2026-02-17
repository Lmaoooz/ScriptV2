repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players.LocalPlayer
repeat task.wait() until game.Players.LocalPlayer.Character

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

WindUI:SetTheme("Dark")

local Window = WindUI:CreateWindow({
    Title = "Auto Farm Dungeon",
    Icon = "swords",
    Author = "by WnZ",
    Folder = "WnZHub",
    Size = UDim2.fromOffset(580, 490),
    Theme = "Dark",
    Acrylic = false,
    HideSearchBar = false,
    OpenButton = {
        Title = "WnZ Hub",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 2,
        Enabled = true,
        OnlyMobile = false,
        Color = ColorSequence.new(Color3.fromHex("#30FF6A"), Color3.fromHex("#e7ff2f")),
    },
})

local SideMain    = Window:Section({ Title = "Auto Farm",  Opened = true })
local SideJoin    = Window:Section({ Title = "Auto Join",  Opened = true })

local Tabs = {
    Main     = SideMain:Tab({ Title = "Farm Settings", Icon = "swords" }),
    AutoJoin = SideJoin:Tab({ Title = "Join Settings", Icon = "door-open" }),
}

local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService         = game:GetService("RunService")
local GuiService         = game:GetService("GuiService")
local TeleportService    = game:GetService("TeleportService")

local player  = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local LOBBY_ID = 84988808589910

local mobsFolder       = workspace:WaitForChild("Main"):WaitForChild("Characters"):WaitForChild("Dungeon"):WaitForChild("Mob")
local bossFolder       = workspace.Main.Characters.Dungeon:WaitForChild("Boss")
local charactersFolder = workspace:WaitForChild("Main"):WaitForChild("Characters")

local autoFarmEnabled   = false
local hakiEnabled       = false
local rejoinOnKickEnabled = false
local autoDodgeUltimate = false
local autoLeaveWithPlayer = false
local isDodgingUltimate = false

local selectedWeaponName = ""
local selectedSkills     = { Z = false, X = false, C = false, V = false, F = false }
local bossKillThreshold  = 50
local mobsDistance       = 8
local currentTarget      = nil
local currentTargetType  = nil

local selectedDungeon    = "Anti-Magic"
local selectedDifficulty = "Normal"

local Toggles = {
    AutoJoinToggle    = false,
    AutoStartToggle   = false,
    AutoRestartToggle = false,
}

player.CharacterAdded:Connect(function(newChar)
    character          = newChar
    humanoidRootPart   = character:WaitForChild("HumanoidRootPart")
    task.wait(1.5)
    if autoFarmEnabled and selectedWeaponName ~= "" then equipWeapon() end
    if hakiEnabled then ensureHaki() end
end)

local function pressKey(keyCode)
    VirtualInputManager:SendKeyEvent(true,  keyCode, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
end

local function pressMouseButton()
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true,  game, 0)
    task.wait(0.01)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end

local function useKeySkill(key)
    VirtualInputManager:SendKeyEvent(true,  Enum.KeyCode[key], false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
end

local function getWeaponsFromBackpack()
    local weapons = {}
    local bp = player:FindFirstChild("Backpack")
    if bp then
        for _, t in pairs(bp:GetChildren()) do
            if t:IsA("Tool") then table.insert(weapons, t.Name) end
        end
    end
    for _, t in pairs(character:GetChildren()) do
        if t:IsA("Tool") then table.insert(weapons, t.Name) end
    end
    return weapons
end

function equipWeapon()
    if selectedWeaponName == "" then return end
    local bp  = player:FindFirstChild("Backpack")
    local hum = character:FindFirstChild("Humanoid")
    if not hum or hum.Health <= 0 then return end
    if character:FindFirstChild(selectedWeaponName) then return end
    if bp then
        local tool = bp:FindFirstChild(selectedWeaponName)
        if tool then hum:EquipTool(tool) end
    end
end

local function isWeaponEquipped()
    if selectedWeaponName == "" then return false end
    local eq = character:FindFirstChildOfClass("Tool")
    return eq and eq.Name == selectedWeaponName
end

function ensureHaki()
    task.spawn(function()
        while hakiEnabled do
            local pf = charactersFolder:FindFirstChild(player.Name)
            if pf and pf:FindFirstChild("Haki") then break end
            pcall(function()
                ReplicatedStorage.Remotes.Serverside:FireServer("Server", "Misc", "Haki", 1)
            end)
            task.wait(0.2)
        end
    end)
end

local function getDungeonList()
    local list = {}
    pcall(function()
        local ds = player.PlayerGui.Button:FindFirstChild("Dungeon Spawn")
        if ds then
            for _, c in pairs(ds.Dungeon.Frame:GetChildren()) do
                if c:IsA("Frame") then table.insert(list, c.Name) end
            end
        end
    end)
    if #list == 0 then return { "Anti-Magic" } end
    return list
end

local function findTarget()
    local Dungeon = workspace.Main.Characters:FindFirstChild("Dungeon")
    if not Dungeon then return nil, nil end

    local BossFolder = Dungeon:FindFirstChild("Boss")
    if BossFolder then
        for _, v in ipairs(BossFolder:GetChildren()) do
            if v:IsA("Model") then
                local root = v:FindFirstChild("HumanoidRootPart")
                    or v:FindFirstChild("Torso")
                    or v.PrimaryPart
                if root then return v, "Boss" end
            end
        end
    end

    local MobFolder = Dungeon:FindFirstChild("Mob")
    if MobFolder and humanoidRootPart and humanoidRootPart.Parent then
        local closest, shortestDist = nil, math.huge
        local lpPos = humanoidRootPart.Position
        for _, v in ipairs(MobFolder:GetChildren()) do
            if v:IsA("Model") then
                local root = v:FindFirstChild("HumanoidRootPart")
                    or v:FindFirstChild("Torso")
                    or v.PrimaryPart
                if root then
                    local dist = (lpPos - root.Position).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        closest = v
                    end
                end
            end
        end
        if closest then return closest, "Mob" end
    end

    return nil, nil
end

local function checkAndKillBosses()
    for _, boss in pairs(bossFolder:GetChildren()) do
        if boss:IsA("Model") then
            local hum = boss:FindFirstChildOfClass("Humanoid")
            if hum then
                local cur = tonumber(hum.Health)
                local max = tonumber(hum.MaxHealth)
                local thr = tonumber(bossKillThreshold) or 50
                if cur and max and cur > 0 and max > 0 then
                    if (cur / max) * 100 <= thr then
                        pcall(function() hum.Health = 0 end)
                    end
                end
            end
        end
    end
end

local function isBossUsingUltimate()
    if not autoDodgeUltimate then return false end
    for _, boss in pairs(bossFolder:GetChildren()) do
        if boss:IsA("Model") then
            local hl = boss:FindFirstChild("HL")
            if hl and hl:IsA("Highlight") then return true end
        end
    end
    return false
end

local function monitorKickMessages()
    while rejoinOnKickEnabled do
        task.wait(1)
        local coreGui     = game:GetService("CoreGui")
        local rpg         = coreGui:FindFirstChild("RobloxPromptGui")
        local overlay     = rpg and rpg:FindFirstChild("promptOverlay")
        local errorPrompt = overlay and overlay:FindFirstChild("ErrorPrompt")
        if errorPrompt and errorPrompt.Visible then
            if game.PlaceId ~= LOBBY_ID then
                TeleportService:Teleport(LOBBY_ID, player)
            end
        end
    end
end

task.spawn(function()
    while task.wait(2) do
        if not autoLeaveWithPlayer then continue end
        if game.PlaceId == LOBBY_ID then continue end
        local others = 0
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player then others += 1 end
        end
        if others > 0 then
            WindUI:Notify({ Title = "Auto Leave", Content = "Player detected! Leaving...", Icon = "log-out", Duration = 3 })
            task.wait(1)
            pcall(function() TeleportService:Teleport(LOBBY_ID, player) end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.05) do
        if autoFarmEnabled and autoDodgeUltimate then
            local usingUlt = isBossUsingUltimate()
            if usingUlt and not isDodgingUltimate then
                isDodgingUltimate = true
                pcall(function()
                    if humanoidRootPart and humanoidRootPart.Parent and currentTarget then
                        local br = currentTarget:FindFirstChild("HumanoidRootPart")
                            or currentTarget:FindFirstChild("Torso")
                            or currentTarget.PrimaryPart
                        if br then
                            humanoidRootPart.CFrame = br.CFrame * CFrame.new(0, 50, 300)
                        end
                    end
                end)
            elseif not usingUlt and isDodgingUltimate then
                isDodgingUltimate = false
            end
        else
            isDodgingUltimate = false
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if not autoFarmEnabled or isDodgingUltimate then return end
    pcall(function()
        local char = player.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = char and char:FindFirstChild("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then return end

        local target, targetType = findTarget()
        if target and target.Parent then
            currentTarget     = target
            currentTargetType = targetType
            local root = target:FindFirstChild("HumanoidRootPart")
                or target:FindFirstChild("Torso")
                or target.PrimaryPart
            if root and root.Parent then
                if targetType == "Boss" then
                    hrp.CFrame = root.CFrame * CFrame.new(0, 0, mobsDistance)
                    hrp.CFrame = CFrame.lookAt(hrp.Position, root.Position)
                else
                    hrp.CFrame = root.CFrame * CFrame.new(0, 0, mobsDistance)
                end
                if hrp.AssemblyLinearVelocity.Magnitude > 0 then
                    hrp.AssemblyLinearVelocity = Vector3.zero
                end
            end
        else
            currentTarget     = nil
            currentTargetType = nil
        end
    end)
end)

local function autoFarmLoop()
    equipWeapon()
    task.wait(0.5)

    while autoFarmEnabled do
        pcall(function()
            if not isWeaponEquipped() then equipWeapon() end

            if not isDodgingUltimate then
                local target, targetType = findTarget()
                if target and target.Parent then
                    currentTarget     = target
                    currentTargetType = targetType

                    pressMouseButton()

                    for key, enabled in pairs(selectedSkills) do
                        if enabled then useKeySkill(key) end
                    end
                else
                    currentTarget     = nil
                    currentTargetType = nil
                end

                checkAndKillBosses()
            end
        end)

        task.wait(0)
    end

    currentTarget     = nil
    currentTargetType = nil
end

local function isPlayerInDungeon()
    local ok, res = pcall(function()
        local rt = workspace.Main.Characters:FindFirstChild("Rogue Town")
        if not rt then return false end
        local pf = rt:FindFirstChild("Dungeons")
        if not pf then return false end
        local dp = pf:FindFirstChild(selectedDungeon)
        if not dp then return false end
        local mf = dp:FindFirstChild("Match")
        if not mf then return false end
        local fr = mf:FindFirstChild("Frame")
        if not fr then return false end
        local lbl = fr:FindFirstChild(player.Name)
        return lbl and lbl:IsA("TextLabel")
    end)
    return ok and res
end

local function autoJoinDungeon()
    if game.PlaceId ~= LOBBY_ID then return end
    if not Toggles.AutoJoinToggle then return end
    pcall(function()
        if isPlayerInDungeon() then return end
        local ds = player.PlayerGui.Button:FindFirstChild("Dungeon Spawn")
        if not ds then return end
        ds.Visible = true
        task.wait(0.5)
        local df = ds.Dungeon.Frame:FindFirstChild(selectedDungeon)
        if df then
            GuiService.SelectedObject = df
            task.wait(0.1)
            pressKey(Enum.KeyCode.Return)
            task.wait(0.5)
        end
        local sb = ds.Dungeon:FindFirstChild("Spawn")
        if sb then
            GuiService.SelectedObject = sb
            task.wait(0.1)
            pressKey(Enum.KeyCode.Return)
            task.wait(1)
        end
        local rt = workspace.Main.Characters:FindFirstChild("Rogue Town")
        if rt then
            local pf = rt:FindFirstChild("Dungeons")
            if pf then
                local portal = pf:FindFirstChild(selectedDungeon)
                if portal and portal:IsA("Part") then
                    local prox = portal:FindFirstChildOfClass("ProximityPrompt")
                    if prox then prox.HoldDuration = 0 end
                    while not isPlayerInDungeon() and Toggles.AutoJoinToggle do
                        humanoidRootPart.CFrame = portal.CFrame
                        task.wait(0.1)
                        pressKey(Enum.KeyCode.E)
                        task.wait(0.2)
                    end
                end
            end
        end
    end)
end

task.spawn(function()
    while task.wait(3) do
        if game.PlaceId == LOBBY_ID and Toggles.AutoJoinToggle then
            autoJoinDungeon()
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if game.PlaceId == LOBBY_ID then continue end
        local dg = player.PlayerGui:FindFirstChild("Dungeon")
        if not dg then continue end

        if Toggles.AutoJoinToggle then
            local df = dg:FindFirstChild("Difficulty")
            if df and df.Visible then
                local opt = df:FindFirstChild(selectedDifficulty)
                if opt and opt.Visible then
                    GuiService.SelectedObject = opt
                    task.wait(0.1)
                    pressKey(Enum.KeyCode.Return)
                    task.wait(0.5)
                end
            end
        end

        if Toggles.AutoStartToggle then
            local sf = dg:FindFirstChild("Start")
            if sf and sf.Visible then
                GuiService.SelectedObject = sf
                task.wait(0.1)
                pressKey(Enum.KeyCode.Return)
                task.wait(0.5)
            end
        end

        if Toggles.AutoRestartToggle then
            local rf = dg:FindFirstChild("Restart")
            if rf and rf.Visible then
                GuiService.SelectedObject = rf
                task.wait(0.1)
                pressKey(Enum.KeyCode.Return)
                task.wait(0.5)
            end
        end
    end
end)

WindUI:Notify({ Title = "WnZ Hub", Content = "Loaded successfully!", Icon = "check", Duration = 4 })

local WeaponSection = Tabs.Main:Section({ Title = "Weapon & Skills", Icon = "sword", Opened = true, Box = true })

local weaponsList = getWeaponsFromBackpack()
if #weaponsList > 0 then selectedWeaponName = weaponsList[1] end

local WeaponDropdown = WeaponSection:Dropdown({
    Title   = "Select Weapon",
    Values  = (#weaponsList > 0) and weaponsList or { "None" },
    Flag    = "WeaponDropdown",
    Value   = weaponsList[1] or "None",
    Callback = function(val)
        selectedWeaponName = val
    end
})

WeaponSection:Button({
    Title    = "Refresh Weapons",
    Icon     = "refresh-cw",
    Callback = function()
        local newList = getWeaponsFromBackpack()
        WeaponDropdown:Refresh(newList)
        if #newList > 0 then selectedWeaponName = newList[1] end
        WindUI:Notify({ Title = "Weapons", Content = "Found " .. #newList .. " weapons", Icon = "check", Duration = 2 })
    end
})

local SkillSection = Tabs.Main:Section({ Title = "Skills (toggle to use)", Icon = "zap", Opened = true, Box = true })

for _, key in ipairs({ "Z", "X", "C", "V", "F" }) do
    SkillSection:Toggle({
        Title    = "Use Skill " .. key,
        Flag     = "Skill_" .. key,
        Value    = false,
        Callback = function(state)
            selectedSkills[key] = state
        end
    })
end

local FarmSection = Tabs.Main:Section({ Title = "Farm Controls", Icon = "target", Opened = true, Box = true })

local AutoFarmToggle
AutoFarmToggle = FarmSection:Toggle({
    Title    = "Enable Auto Farm",
    Desc     = "Auto attack mobs/boss — attacks while model exists",
    Flag     = "AutoFarmToggle",
    Value    = false,
    Callback = function(state)
        autoFarmEnabled = state
        if state then
            if selectedWeaponName == "" or selectedWeaponName == "None" then
                autoFarmEnabled = false
                AutoFarmToggle:Set(false)
                WindUI:Notify({ Title = "Warning", Content = "Select a weapon first!", Icon = "alert-triangle", Duration = 3 })
                return
            end
            task.spawn(autoFarmLoop)
        else
            currentTarget     = nil
            currentTargetType = nil
            isDodgingUltimate = false
        end
    end
})

FarmSection:Toggle({
    Title    = "Auto Dodge Boss Ultimate",
    Desc     = "Teleport away when boss HL Highlight appears",
    Flag     = "AutoDodgeToggle",
    Value    = false,
    Callback = function(state)
        autoDodgeUltimate = state
        if not state then isDodgingUltimate = false end
    end
})

FarmSection:Toggle({
    Title    = "Auto Leave When Player Detected",
    Desc     = "Leave dungeon if another player joins",
    Flag     = "AutoLeaveToggle",
    Value    = false,
    Callback = function(state)
        autoLeaveWithPlayer = state
        if state then
            WindUI:Notify({ Title = "Auto Leave", Content = "Will leave if a player joins!", Icon = "log-out", Duration = 3 })
        end
    end
})

local SettingsSection = Tabs.Main:Section({ Title = "Farm Settings", Icon = "settings", Opened = true, Box = true })

SettingsSection:Slider({
    Title    = "Mobs Distance",
    Desc     = "Teleport distance to mobs & boss (Default: 8)",
    Flag     = "MobsDistSlider",
    Value    = { Min = 1, Max = 30, Default = 8 },
    Callback = function(val)
        mobsDistance = val
    end
})

SettingsSection:Slider({
    Title    = "Insta-Kill Boss at % HP",
    Desc     = "Set boss HP to 0 when below this percentage",
    Flag     = "BossKillSlider",
    Value    = { Min = 0, Max = 100, Default = 50 },
    Callback = function(val)
        bossKillThreshold = val
    end
})

SettingsSection:Toggle({
    Title    = "Enable Haki",
    Desc     = "Automatically activate Haki",
    Flag     = "HakiToggle",
    Value    = true,
    Callback = function(state)
        hakiEnabled = state
        if state then ensureHaki() end
    end
})

SettingsSection:Toggle({
    Title    = "Auto Rejoin on Kick",
    Desc     = "Return to lobby when kicked",
    Flag     = "RejoinToggle",
    Value    = true,
    Callback = function(state)
        rejoinOnKickEnabled = state
        if state then task.spawn(monitorKickMessages) end
    end
})

local DungeonSection = Tabs.AutoJoin:Section({ Title = "Dungeon Selection", Icon = "map-pin", Opened = true, Box = true })

local dungeons = getDungeonList()
if #dungeons > 0 then selectedDungeon = dungeons[1] end

DungeonSection:Dropdown({
    Title    = "Select Dungeon",
    Values   = dungeons,
    Flag     = "DungeonDropdown",
    Value    = dungeons[1] or "Anti-Magic",
    Callback = function(val)
        selectedDungeon = val
    end
})

DungeonSection:Dropdown({
    Title    = "Select Difficulty",
    Values   = { "Normal", "Hard" },
    Flag     = "DifficultyDropdown",
    Value    = "Normal",
    Callback = function(val)
        selectedDifficulty = val
    end
})

local ActionsSection = Tabs.AutoJoin:Section({ Title = "Auto Actions", Icon = "play", Opened = true, Box = true })

ActionsSection:Toggle({
    Title    = "Auto Join Dungeon",
    Desc     = "Automatically join selected dungeon from lobby",
    Flag     = "AutoJoinToggle",
    Value    = false,
    Callback = function(state)
        Toggles.AutoJoinToggle = state
    end
})

ActionsSection:Toggle({
    Title    = "Auto Start",
    Desc     = "Automatically press the Start button",
    Flag     = "AutoStartToggle",
    Value    = false,
    Callback = function(state)
        Toggles.AutoStartToggle = state
    end
})

ActionsSection:Toggle({
    Title    = "Auto Restart",
    Desc     = "Automatically press the Restart button",
    Flag     = "AutoRestartToggle",
    Value    = false,
    Callback = function(state)
        Toggles.AutoRestartToggle = state
    end
})

task.spawn(function()
    task.wait(1.2)
    if hakiEnabled then ensureHaki() end
end)
