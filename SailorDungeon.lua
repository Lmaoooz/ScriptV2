-- Wait for game to fully load
if not game:IsLoaded() then
    game.Loaded:Wait()
end

task.wait(2) -- Additional wait to ensure everything is loaded

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "[Sailor Piece] - Auto Dungeon script |",
    SubTitle = "By WnZ",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Auto Farm", Icon = "sword" }),
    Dungeon = Window:AddTab({ Title = "Dungeon", Icon = "layers" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Get current place ID
local currentPlaceId = game.PlaceId

-- Remotes
local AttackRemote = ReplicatedStorage.CombatSystem.Remotes.RequestHit
local HakiRemote = ReplicatedStorage.RemoteEvents.HakiRemote
local DungeonRemote = ReplicatedStorage.Remotes.RequestDungeonPortal
local DungeonDifficultyRemote = ReplicatedStorage.Remotes.DungeonWaveVote
local DungeonReplayRemote = ReplicatedStorage.Remotes.DungeonWaveReplayVote

-- Auto Farm Variables
local AutoFarmEnabled = false
local AutoAbilityEnabled = false
local AutoHakiEnabled = false
local AutoEquipWeaponEnabled = false
local AutoJoinDungeonEnabled = false
local AutoDifficultyEnabled = false
local AutoReplayDungeonEnabled = false
local currentTarget = nil
local lastAttackTime = 0
local lastTargetSearchTime = 0
local lastDifficultyVoteTime = 0
local lastReplayVoteTime = 0
local selectedAbilities = {}
local selectedWeapon = nil
local selectedDungeon = nil
local selectedDifficulty = "Easy"

-- Ability Key Mapping
local abilityKeys = {
    ["Z"] = Enum.KeyCode.Z,
    ["X"] = Enum.KeyCode.X,
    ["C"] = Enum.KeyCode.C,
    ["V"] = Enum.KeyCode.V
}

-- Config
local CONFIG = {
    AttackDelay = 0,
    TargetRefreshRate = 0.5,
    AttackDistance = 3,
}

-- Functions
local function isValidEnemy(entity)
    if not entity then return false end
    if not entity.Parent then return false end
    
    local humanoid = entity:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    if humanoid.Health <= 0 then return false end
    if entity == Character then return false end
    if Players:GetPlayerFromCharacter(entity) then return false end
    if not entity:FindFirstChild("HumanoidRootPart") then return false end
    
    return true
end

local function findNearestEnemy()
    local nearestEnemy = nil
    local shortestDistance = math.huge
    
    -- Get enemies from workspace.NPCs folder
    local NPCsFolder = workspace:FindFirstChild("NPCs")
    if not NPCsFolder then return nil end
    
    for _, entity in pairs(NPCsFolder:GetChildren()) do
        if entity:IsA("Model") and isValidEnemy(entity) then
            local enemyRoot = entity:FindFirstChild("HumanoidRootPart")
            if enemyRoot then
                local distance = (HumanoidRootPart.Position - enemyRoot.Position).Magnitude
                
                if distance < shortestDistance then
                    nearestEnemy = entity
                    shortestDistance = distance
                end
            end
        end
    end
    
    return nearestEnemy
end

local function attackTarget()
    if not currentTarget or not isValidEnemy(currentTarget) then
        currentTarget = nil
        return false
    end
    
    local enemyRoot = currentTarget:FindFirstChild("HumanoidRootPart")
    if not enemyRoot then 
        currentTarget = nil
        return false 
    end
    
    -- Safety check: make sure enemy still exists and is valid
    if not enemyRoot.Parent then
        currentTarget = nil
        return false
    end
    
    local targetPosition = enemyRoot.Position
    
    -- Position behind enemy
    local enemyLookVector = enemyRoot.CFrame.LookVector
    local behindPosition = targetPosition - (enemyLookVector * CONFIG.AttackDistance)
    
    -- Create CFrame facing the enemy
    local lookAtCFrame = CFrame.new(behindPosition, targetPosition)
    
    -- Smoothly set position
    pcall(function()
        HumanoidRootPart.CFrame = lookAtCFrame
    end)
    
    task.wait(0.05)
    
    -- Double check enemy is still valid before attacking
    if not isValidEnemy(currentTarget) then
        currentTarget = nil
        return false
    end
    
    -- Attack
    pcall(function()
        AttackRemote:FireServer()
    end)
    
    return true
end

local function pressKey(key)
    VirtualInputManager:SendKeyEvent(true, key, false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, key, false, game)
end

local function fireHakiRemote()
    local args = {[1] = "Toggle"}
    pcall(function()
        HakiRemote:FireServer(unpack(args))
    end)
end

local function voteDifficulty()
    if not selectedDifficulty then return end
    
    local args = {
        [1] = selectedDifficulty
    }
    pcall(function()
        DungeonDifficultyRemote:FireServer(unpack(args))
    end)
end

local function voteReplay()
    local args = {
        [1] = "sponsor"
    }
    pcall(function()
        DungeonReplayRemote:FireServer(unpack(args))
    end)
end

local function getAvailableWeapons()
    local weapons = {}
    
    -- Check backpack
    for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            table.insert(weapons, tool.Name)
        end
    end
    
    -- Check equipped tools
    if Character then
        for _, tool in pairs(Character:GetChildren()) do
            if tool:IsA("Tool") then
                local alreadyListed = false
                for _, weaponName in pairs(weapons) do
                    if weaponName == tool.Name then
                        alreadyListed = true
                        break
                    end
                end
                if not alreadyListed then
                    table.insert(weapons, tool.Name)
                end
            end
        end
    end
    
    return weapons
end

local function equipWeapon(weaponName)
    if not weaponName then return end
    
    -- Check if already equipped
    local equippedTool = Character:FindFirstChild(weaponName)
    if equippedTool and equippedTool:IsA("Tool") then
        return
    end
    
    -- Find tool in backpack and equip
    local tool = LocalPlayer.Backpack:FindFirstChild(weaponName)
    if tool and tool:IsA("Tool") then
        local humanoid = Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:EquipTool(tool)
        end
    end
end

local function joinDungeon(dungeonName)
    if not dungeonName then return end
    
    local args = {
        [1] = dungeonName
    }
    pcall(function()
        DungeonRemote:FireServer(unpack(args))
    end)
end

-- UI Setup
local WeaponDropdown -- Declare here so we can reference it in refresh button

do
    Fluent:Notify({
        Title = "Auto Farm",
        Content = "Script loaded successfully!",
        Duration = 5
    })

    Tabs.Main:AddParagraph({
        Title = "Auto Farm",
        Content = "Automatically targets, teleports to, and kills enemies with Humanoid health.\nToggle below to start farming!"
    })

    -- Main Auto Farm Toggle
    local MainToggle = Tabs.Main:AddToggle("AutoFarmToggle", {
        Title = "Enable Auto Farm",
        Default = false
    })

    MainToggle:OnChanged(function()
        AutoFarmEnabled = Options.AutoFarmToggle.Value

        if AutoFarmEnabled then
            Fluent:Notify({
                Title = "Auto Farm",
                Content = "Auto Farm & Teleport Enabled!",
                Duration = 3
            })
        else
            Fluent:Notify({
                Title = "Auto Farm",
                Content = "Auto Farm & Teleport Disabled!",
                Duration = 3
            })
            currentTarget = nil
        end
    end)

    -- Attack Distance Input
    local AttackDistanceInput = Tabs.Main:AddInput("AttackDistanceInput", {
        Title = "Farm Distance",
        Description = "Distance attacking enemies. 10 Is Recommended."
        Default = "10",
        Placeholder = "Enter distance",
        Numeric = true,
        Finished = false,
        Callback = function(Value)
            local distance = tonumber(Value)
            if distance and distance > 0 then
                CONFIG.AttackDistance = distance
                Fluent:Notify({
                    Title = "Attack Distance",
                    Content = "Distance set to: " .. distance,
                    Duration = 2
                })
            end
        end
    })

    Tabs.Main:AddParagraph({
        Title = "Weapon Settings",
        Content = "Auto equip your selected weapon."
    })

    -- Get available weapons
    local availableWeapons = getAvailableWeapons()
    
    -- Choose Weapon Dropdown
    WeaponDropdown = Tabs.Main:AddDropdown("WeaponDropdown", {
        Title = "Choose Weapon",
        Description = "Select weapon to auto equip.",
        Values = availableWeapons,
        Multi = false,
        Default = 1,
    })

    WeaponDropdown:OnChanged(function(Value)
        selectedWeapon = Value
    end)

    -- Auto Equip Weapon Toggle
    local AutoEquipToggle = Tabs.Main:AddToggle("AutoEquipWeapon", {
        Title = "Auto Equip Weapon",
        Default = false
    })

    AutoEquipToggle:OnChanged(function()
        AutoEquipWeaponEnabled = Options.AutoEquipWeapon.Value
        if AutoEquipWeaponEnabled then
            equipWeapon(selectedWeapon)
            Fluent:Notify({
                Title = "Auto Equip",
                Content = "Auto Equip Weapon Enabled!",
                Duration = 3
            })
        else
            Fluent:Notify({
                Title = "Auto Equip",
                Content = "Auto Equip Weapon Disabled!",
                Duration = 3
            })
        end
    end)

    -- Refresh Weapon Button
    Tabs.Main:AddButton({
        Title = "Refresh Weapon List",
        Description = "Refresh available weapons from backpack",
        Callback = function()
            local newWeapons = getAvailableWeapons()
            WeaponDropdown:SetValues(newWeapons)
            Fluent:Notify({
                Title = "Weapon List",
                Content = "Weapon list refreshed!",
                Duration = 2
            })
        end
    })

    Tabs.Main:AddParagraph({
        Title = "Ability Settings",
        Content = "Select abilities and enable auto ability to use them repeatedly."
    })

    -- Select Ability Multi Dropdown
    local AbilityDropdown = Tabs.Main:AddDropdown("AbilityDropdown", {
        Title = "Select Ability Keys",
        Description = "Choose which ability keys to press automatically.",
        Values = {"Z", "X", "C", "V"},
        Multi = true,
        Default = {},
    })

    AbilityDropdown:OnChanged(function(Value)
        selectedAbilities = {}
        for ability, enabled in pairs(Value) do
            selectedAbilities[ability] = enabled
        end
    end)

    -- Auto Ability Toggle
    local AutoAbilityToggle = Tabs.Main:AddToggle("AutoAbilityToggle", {
        Title = "Auto Ability",
        Description = "Continuously press selected ability keys",
        Default = false
    })

    AutoAbilityToggle:OnChanged(function()
        AutoAbilityEnabled = Options.AutoAbilityToggle.Value
        if AutoAbilityEnabled then
            Fluent:Notify({
                Title = "Auto Ability",
                Content = "Auto Ability Enabled! Pressing selected keys...",
                Duration = 3
            })
        else
            Fluent:Notify({
                Title = "Auto Ability",
                Content = "Auto Ability Disabled!",
                Duration = 3
            })
        end
    end)

    Tabs.Main:AddParagraph({
        Title = "Haki Settings",
        Content = "Auto enable Haki on spawn."
    })

    -- Auto Haki Toggle
    local AutoHakiToggle = Tabs.Main:AddToggle("AutoHakiToggle", {
        Title = "Auto Haki [Buso]",
        Default = false
    })

    AutoHakiToggle:OnChanged(function()
        AutoHakiEnabled = Options.AutoHakiToggle.Value
        if AutoHakiEnabled then
            fireHakiRemote()
            Fluent:Notify({
                Title = "Auto Haki [Buso]",
                Content = "Auto Haki Enabled!",
                Duration = 3
            })
        else
            Fluent:Notify({
                Title = "Auto Haki [Buso]",
                Content = "Auto Haki Disabled!",
                Duration = 3
            })
        end
    end)

    -- Dungeon Tab
    Tabs.Dungeon:AddParagraph({
        Title = "Dungeon Auto Join",
        Content = "Automatically join selected dungeon."
    })

    -- Select Dungeon Dropdown
    local DungeonDropdown = Tabs.Dungeon:AddDropdown("DungeonDropdown", {
        Title = "Select Dungeon",
        Description = "Choose which dungeon to auto join.",
        Values = {"CidDungeon", "RuneDungeon"},
        Multi = false,
        Default = 1,
    })

    DungeonDropdown:OnChanged(function(Value)
        selectedDungeon = Value
    end)

    -- Auto Join Dungeon Toggle
    local AutoJoinDungeonToggle = Tabs.Dungeon:AddToggle("AutoJoinDungeon", {
        Title = "Auto Join Dungeon",
        Default = false
    })

    AutoJoinDungeonToggle:OnChanged(function()
        AutoJoinDungeonEnabled = Options.AutoJoinDungeon.Value
        if AutoJoinDungeonEnabled then
            joinDungeon(selectedDungeon)
            Fluent:Notify({
                Title = "Auto Join Dungeon",
                Content = "Joining " .. tostring(selectedDungeon) .. "!",
                Duration = 3
            })
        else
            Fluent:Notify({
                Title = "Auto Join Dungeon",
                Content = "Auto Join Dungeon Disabled!",
                Duration = 3
            })
        end
    end)

    Tabs.Dungeon:AddParagraph({
        Title = "Dungeon Difficulty",
        Content = "Automatically vote for dungeon difficulty."
    })

    -- Select Dungeon Difficulty Dropdown
    local DifficultyDropdown = Tabs.Dungeon:AddDropdown("DifficultyDropdown", {
        Title = "Select Dungeon Difficulty",
        Description = "Choose dungeon difficulty to vote for.",
        Values = {"Easy", "Medium", "Hard", "Extreme"},
        Multi = false,
        Default = 1,
    })

    DifficultyDropdown:OnChanged(function(Value)
        selectedDifficulty = Value
    end)

    -- Auto Difficulty Toggle
    local AutoDifficultyToggle = Tabs.Dungeon:AddToggle("AutoDifficulty", {
        Title = "Auto Difficulty Vote",
        Description = "Continuously vote for selected difficulty",
        Default = false
    })

    AutoDifficultyToggle:OnChanged(function()
        AutoDifficultyEnabled = Options.AutoDifficulty.Value
        if AutoDifficultyEnabled then
            Fluent:Notify({
                Title = "Auto Difficulty",
                Content = "Auto voting for " .. selectedDifficulty .. "!",
                Duration = 3
            })
        else
            Fluent:Notify({
                Title = "Auto Difficulty",
                Content = "Auto Difficulty Disabled!",
                Duration = 3
            })
        end
    end)

    Tabs.Dungeon:AddParagraph({
        Title = "Dungeon Replay",
        Content = "Automatically vote to replay dungeon."
    })

    -- Auto Replay Dungeon Toggle
    local AutoReplayToggle = Tabs.Dungeon:AddToggle("AutoReplayDungeon", {
        Title = "Auto Replay Dungeon",
        Description = "Continuously vote to replay dungeon",
        Default = false
    })

    AutoReplayToggle:OnChanged(function()
        AutoReplayDungeonEnabled = Options.AutoReplayDungeon.Value
        if AutoReplayDungeonEnabled then
            Fluent:Notify({
                Title = "Auto Replay",
                Content = "Auto Replay Dungeon Enabled!",
                Duration = 3
            })
        else
            Fluent:Notify({
                Title = "Auto Replay",
                Content = "Auto Replay Dungeon Disabled!",
                Duration = 3
            })
        end
    end)
end

-- Main Auto Farm Loop
RunService.Heartbeat:Connect(function()
    if not AutoFarmEnabled then return end
    
    -- Check if place ID is restricted
    if currentPlaceId == 77747658251236 then return end
    
    if not Character or not Character.Parent then
        Character = LocalPlayer.Character
        if Character then
            HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
        else
            return
        end
    end
    
    local currentTime = tick()
    
    -- Search for new target
    if currentTime - lastTargetSearchTime >= CONFIG.TargetRefreshRate then
        if not currentTarget or not isValidEnemy(currentTarget) then
            currentTarget = findNearestEnemy()
        end
        lastTargetSearchTime = currentTime
    end
    
    -- Attack current target
    if currentTarget and currentTime - lastAttackTime >= CONFIG.AttackDelay then
        if attackTarget() then
            lastAttackTime = currentTime
        else
            currentTarget = nil
        end
    end
end)

-- Auto Ability Loop
task.spawn(function()
    while true do
        task.wait(0.1)
        
        if AutoAbilityEnabled then
            for abilityKey, enabled in pairs(selectedAbilities) do
                if enabled and abilityKeys[abilityKey] then
                    pressKey(abilityKeys[abilityKey])
                end
            end
        end
    end
end)

-- Auto Difficulty Vote Loop
task.spawn(function()
    while true do
        task.wait(0.5)
        
        if AutoDifficultyEnabled then
            local currentTime = tick()
            if currentTime - lastDifficultyVoteTime >= 0.5 then
                voteDifficulty()
                lastDifficultyVoteTime = currentTime
            end
        end
    end
end)

-- Auto Replay Vote Loop
task.spawn(function()
    while true do
        task.wait(0.5)
        
        if AutoReplayDungeonEnabled then
            local currentTime = tick()
            if currentTime - lastReplayVoteTime >= 0.5 then
                voteReplay()
                lastReplayVoteTime = currentTime
            end
        end
    end
end)

-- Auto Equip Weapon Loop
RunService.Heartbeat:Connect(function()
    if not AutoEquipWeaponEnabled or not selectedWeapon then return end
    
    if Character then
        equipWeapon(selectedWeapon)
    end
end)

-- Handle character respawn
LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    currentTarget = nil
    
    -- Auto Haki on respawn
    if AutoHakiEnabled then
        task.wait(0.5)
        fireHakiRemote()
    end
    
    -- Auto equip weapon on respawn
    if AutoEquipWeaponEnabled and selectedWeapon then
        task.wait(0.5)
        equipWeapon(selectedWeapon)
    end
end)

-- Addons Setup
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("SailorDungeon")
SaveManager:SetFolder("SailorDungeon/configuration")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

SaveManager:LoadAutoloadConfig()
