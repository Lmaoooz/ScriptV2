repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players.LocalPlayer
repeat task.wait() until game.Players.LocalPlayer.Character

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Auto Farm Dungeon | Rogue Piece",
    SubTitle = "by WnZ",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 520),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Auto Farm Settings", Icon = "sword" }),
    AutoJoin = Window:AddTab({ Title = "Auto Join Settings", Icon = "layers" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local LOBBY_ID = 84988808589910

-- Folders
local mobsFolder = workspace:WaitForChild("Main"):WaitForChild("Characters"):WaitForChild("Dungeon"):WaitForChild("Mob")
local bossFolder = workspace.Main.Characters.Dungeon:WaitForChild("Boss")
local charactersFolder = workspace:WaitForChild("Main"):WaitForChild("Characters")

-- State Variables
local autoFarmEnabled = false
local hakiEnabled = false
local rejoinOnKickEnabled = false
local autoDodgeUltimate = false
local autoLeaveWithPlayer = false
local isDodgingUltimate = false
local bossJustKilled = false -- New state to track insta-kill
local selectedWeaponName = ""
local selectedSkills = {}
local bossKillThreshold = 50
local mobsDistance = 8
local currentTarget = nil
local currentTargetType = nil
local selectedDungeon = "Anti-Magic"
local selectedDifficulty = "Normal"

-- [CHARACTER RESPAWN HANDLER]
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	task.wait(1.5)
	
	if autoFarmEnabled and selectedWeaponName ~= "" then
		equipWeapon()
	end
	
	if hakiEnabled then
		ensureHaki()
	end
end)

-- [UTILITY FUNCTIONS]
local function pressKey(keyCode)
	VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
	task.wait(0.05)
	VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
end

local function pressMouseButton()
	VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
	task.wait(0.01)
	VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end

local function useKeySkill(key)
	VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
	task.wait(0.05)
	VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
end

-- [WEAPON LOGIC]
local function getWeaponsFromBackpack()
	local weapons = {}
	local bp = player:FindFirstChild("Backpack")
	
	if bp then
		for _, tool in pairs(bp:GetChildren()) do
			if tool:IsA("Tool") then
				table.insert(weapons, tool.Name)
			end
		end
	end
	
	for _, tool in pairs(character:GetChildren()) do
		if tool:IsA("Tool") then
			table.insert(weapons, tool.Name)
		end
	end
	
	return weapons
end

function equipWeapon()
	if selectedWeaponName == "" then return end
	
	local bp = player:FindFirstChild("Backpack")
	local hum = character:FindFirstChild("Humanoid")
	
	if not hum or hum.Health <= 0 then return end
	if character:FindFirstChild(selectedWeaponName) then return end
	
	if bp then
		local tool = bp:FindFirstChild(selectedWeaponName)
		if tool then
			hum:EquipTool(tool)
		end
	end
end

local function isWeaponEquipped()
	if selectedWeaponName == "" then return false end
	local equipped = character:FindFirstChildOfClass("Tool")
	return equipped and equipped.Name == selectedWeaponName
end

-- [HAKI LOGIC]
function ensureHaki()
	task.spawn(function()
		while hakiEnabled do
			local playerCharFolder = charactersFolder:FindFirstChild(player.Name)
			if playerCharFolder and playerCharFolder:FindFirstChild("Haki") then
				break
			end
			
			local args = {[1] = "Server", [2] = "Misc", [3] = "Haki", [4] = 1}
			pcall(function()
				ReplicatedStorage.Remotes.Serverside:FireServer(unpack(args))
			end)
			task.wait(0.2)
		end
	end)
end

-- [DUNGEON SELECTION FETCH]
local function getDungeonList()
	local list = {}
	pcall(function()
		local dungeonSpawn = player.PlayerGui.Button:FindFirstChild("Dungeon Spawn")
		if dungeonSpawn then
			local frame = dungeonSpawn.Dungeon.Frame
			for _, child in pairs(frame:GetChildren()) do
				if child:IsA("Frame") then
					table.insert(list, child.Name)
				end
			end
		end
	end)
	if #list == 0 then
		return {"Anti-Magic"}
	end
	return list
end

-- [CHECK IF BOSS HAS ULTIMATE (HL HIGHLIGHT)]
local function isBossUsingUltimate()
	if not autoDodgeUltimate then return false end
	
	for _, boss in pairs(bossFolder:GetChildren()) do
		if boss:IsA("Model") then
			local hlHighlight = boss:FindFirstChild("HL")
			if hlHighlight and hlHighlight:IsA("Highlight") then
				return true
			end
		end
	end
	return false
end

-- [UPDATED TARGET FINDING]
local function findAliveMob()
    local Dungeon = workspace.Main.Characters:FindFirstChild("Dungeon")
    if not Dungeon then return nil, nil end

    -- PRIORITY 1: Boss (Target ANY boss model, dead or alive, so we stay floating safely)
    local BossFolder = Dungeon:FindFirstChild("Boss")
    if BossFolder then
        for _, v in ipairs(BossFolder:GetChildren()) do
            if v:IsA("Model") then
                local root = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChild("Torso") or v.PrimaryPart
                if root then
                    return v, "Boss"
                end
            end
        end
    end

    -- PRIORITY 2: Mobs (Only target alive ones for fast switching)
    local MobFolder = Dungeon:FindFirstChild("Mob")
    if MobFolder then
        local closest, shortestDist = nil, math.huge
        if humanoidRootPart and humanoidRootPart.Parent then
            local lpPos = humanoidRootPart.Position
            for _, v in ipairs(MobFolder:GetChildren()) do
                if v:IsA("Model") then
                    local hum = v:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then -- Ignore dead mobs
                        local root = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChild("Torso") or v.PrimaryPart
                        if root then
                            local distance = (lpPos - root.Position).Magnitude
                            if distance < shortestDist then
                                shortestDist = distance
                                closest = v
                            end
                        end
                    end
                end
            end
        end
        return closest, "Mob"
    end
    return nil, nil
end

local function checkAndKillBosses()
    local bossFound = false -- Define this so the script knows if a boss exists
    
    for _, boss in pairs(bossFolder:GetChildren()) do
        if boss:IsA("Model") then
            bossFound = true -- Mark that a boss model was found
            local hum = boss:FindFirstChildOfClass("Humanoid")
            if hum then
                local current = tonumber(hum.Health)
                local max = tonumber(hum.MaxHealth)
                
                if current and max and max > 0 then
                    local percentRemaining = (current / max) * 100
                    
                    -- Only set HP to 0 if it's currently alive and below threshold
                    if current > 0 and percentRemaining <= bossKillThreshold then
                        pcall(function()
                            hum.Health = 0
                            bossJustKilled = true -- Set flag when insta-kill triggers
                        end)
                    end
                end
            end
        end
    end

    -- Reset the flag once there are no "Model" children left in Boss folder
    if bossJustKilled and not bossFound then
        bossJustKilled = false
    end
end -- This correctly ends the function

-- [KICK MONITOR LOGIC]
local function monitorKickMessages()
	while rejoinOnKickEnabled do
		task.wait(1)
		
		local promptOverlay = game:GetService("CoreGui"):FindFirstChild("RobloxPromptGui") and game:GetService("CoreGui").RobloxPromptGui:FindFirstChild("promptOverlay")
		local errorPrompt = promptOverlay and promptOverlay:FindFirstChild("ErrorPrompt")
		
		if errorPrompt and errorPrompt.Visible then
			if game.PlaceId ~= LOBBY_ID then
				TeleportService:Teleport(LOBBY_ID, player)
			end
		end
	end
end

-- [AUTO LEAVE WHEN PLAYER IN DUNGEON]
task.spawn(function()
	while task.wait(1) do
		if not autoLeaveWithPlayer then continue end
		if game.PlaceId == LOBBY_ID then continue end
		
		local otherPlayers = 0
		for _, p in pairs(Players:GetPlayers()) do
			if p ~= player then
				otherPlayers = otherPlayers + 1
			end
		end
		
		if otherPlayers > 0 then
			Fluent:Notify({
				Title = "Auto Leave",
				Content = "Player detected! Leaving to lobby...",
				Duration = 3
			})
			task.wait(1)
			pcall(function()
				TeleportService:Teleport(LOBBY_ID, player)
			end)
		end
	end
end)

-- [ULTIMATE DODGE MONITOR]
task.spawn(function()
	while task.wait(0.05) do
		if autoFarmEnabled and autoDodgeUltimate then
			local bossUsingUlt = isBossUsingUltimate()
			
			if bossUsingUlt and not isDodgingUltimate then
				isDodgingUltimate = true
				
				pcall(function()
					if humanoidRootPart and humanoidRootPart.Parent and currentTarget then
						local bossRoot = currentTarget:FindFirstChild("HumanoidRootPart") or currentTarget:FindFirstChild("Torso") or currentTarget.PrimaryPart
						if bossRoot then
							local awayPosition = bossRoot.CFrame * CFrame.new(0, 50, 300)
							humanoidRootPart.CFrame = awayPosition
						end
					end
				end)
			elseif not bossUsingUlt and isDodgingUltimate then
				isDodgingUltimate = false
			end
		else
			isDodgingUltimate = false
		end
	end
end)

-- [HEARTBEAT TELEPORT LOOP]
RunService.Heartbeat:Connect(function()
    if not autoFarmEnabled then return end
    if isDodgingUltimate then return end
    
    pcall(function()
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        
        if not hrp or not hum or hum.Health <= 0 then return end

        local target, targetType = findAliveMob()
        
        if target and target.Parent and targetType then
            currentTarget = target
            currentTargetType = targetType
            
            local targetRoot = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Torso") or target.PrimaryPart
            
            if targetRoot and targetRoot.Parent then
                local shouldTeleportUp = false
                
                -- Check if Boss is below threshold
                if targetType == "Boss" then
                    local bHum = target:FindFirstChildOfClass("Humanoid")
                    if bHum then
                        local bMax = bHum.MaxHealth
                        local bCur = bHum.Health
                        if bMax > 0 then
                            local pct = (bCur / bMax) * 100
                            -- If HP is 0 OR below threshold, stay up
                            if pct <= bossKillThreshold or bCur <= 0 then
                                shouldTeleportUp = true
                            end
                        end
                    end
                end

                if shouldTeleportUp then
                    -- STAY SAFE: 50 studs ABOVE the boss
                    hrp.CFrame = targetRoot.CFrame * CFrame.new(0, 50, 0)
                    hrp.CFrame = CFrame.lookAt(hrp.Position, targetRoot.Position)
                    hrp.AssemblyLinearVelocity = Vector3.zero -- Stop falling
                elseif targetType == "Boss" then
                    -- ATTACK MODE: Behind the boss
                    hrp.CFrame = targetRoot.CFrame * CFrame.new(0, 0, mobsDistance)
                    hrp.CFrame = CFrame.lookAt(hrp.Position, targetRoot.Position)
                else
                    -- NORMAL MOB: Behind the mob
                    hrp.CFrame = targetRoot.CFrame * CFrame.new(0, 0, mobsDistance)
                end
                
                -- General safety to prevent flinging
                if hrp.AssemblyLinearVelocity.Magnitude > 50 then
                    hrp.AssemblyLinearVelocity = Vector3.zero
                end
            end
        else
            currentTarget = nil
            currentTargetType = nil
        end
    end)
end)

-- [MAIN AUTO FARM LOOP]
local function autoFarmLoop()
	equipWeapon()
	task.wait(0.5)
	
	while autoFarmEnabled do
		pcall(function()
			if not isWeaponEquipped() then
				equipWeapon()
			end
			
			if not isDodgingUltimate and not bossJustKilled then
				local target, targetType = findAliveMob()
				
				if target and targetType then
					currentTarget = target
					currentTargetType = targetType
					
					pressMouseButton() -- Manual kill logic
					
					for skillKey, enabled in pairs(selectedSkills) do
						if enabled then
							useKeySkill(skillKey)
						end
					end
				else
					currentTarget = nil
					currentTargetType = nil
				end
				
				checkAndKillBosses()
			elseif bossJustKilled then
                checkAndKillBosses()
            end
		end)
		
		task.wait() -- Minimal wait for maximum targeting speed
	end
	
	currentTarget = nil
	currentTargetType = nil
end

-- [CHECK IF PLAYER IS IN DUNGEON]
local function isPlayerInDungeon()
	local success, result = pcall(function()
		local dungeonPortals = workspace.Main.Characters:FindFirstChild("Rogue Town")
		if dungeonPortals then
			local portalsFolder = dungeonPortals:FindFirstChild("Dungeons")
			if portalsFolder then
				local dungeonPart = portalsFolder:FindFirstChild(selectedDungeon)
				if dungeonPart then
					local matchFolder = dungeonPart:FindFirstChild("Match")
					if matchFolder then
						local frame = matchFolder:FindFirstChild("Frame")
						if frame then
							local playerLabel = frame:FindFirstChild(player.Name)
							if playerLabel and playerLabel:IsA("TextLabel") then
								return true
							end
						end
					end
				end
			end
		end
		return false
	end)
	
	return success and result
end

-- [AUTO JOIN LOBBY LOGIC]
local function autoJoinDungeon()
	if game.PlaceId ~= LOBBY_ID then return end
	if not Options.AutoJoinToggle or not Options.AutoJoinToggle.Value then return end
	
	pcall(function()
		if isPlayerInDungeon() then return end
		
		local dungeonSpawn = player.PlayerGui.Button:FindFirstChild("Dungeon Spawn")
		if not dungeonSpawn then return end
		
		dungeonSpawn.Visible = true
		task.wait(0.5)
		
		local dungeonFrame = dungeonSpawn.Dungeon.Frame:FindFirstChild(selectedDungeon)
		if dungeonFrame then
			GuiService.SelectedObject = dungeonFrame
			task.wait(0.1)
			pressKey(Enum.KeyCode.Return)
			task.wait(0.5)
		end
		
		local spawnButton = dungeonSpawn.Dungeon:FindFirstChild("Spawn")
		if spawnButton then
			GuiService.SelectedObject = spawnButton
			task.wait(0.1)
			pressKey(Enum.KeyCode.Return)
			task.wait(1)
		end
		
		local dungeonPortals = workspace.Main.Characters:FindFirstChild("Rogue Town")
		if dungeonPortals then
			local portalsFolder = dungeonPortals:FindFirstChild("Dungeons")
			if portalsFolder then
				local portalPart = portalsFolder:FindFirstChild(selectedDungeon)
				if portalPart and portalPart:IsA("Part") then
					local prompt = portalPart:FindFirstChildOfClass("ProximityPrompt")
					if prompt then
						prompt.HoldDuration = 0
					end
					
					while not isPlayerInDungeon() and Options.AutoJoinToggle and Options.AutoJoinToggle.Value do
						humanoidRootPart.CFrame = portalPart.CFrame
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
		if game.PlaceId == LOBBY_ID and Options.AutoJoinToggle and Options.AutoJoinToggle.Value then
			autoJoinDungeon()
		end
	end
end)

-- [IN-DUNGEON AUTO DIFFICULTY/START/RESTART]
task.spawn(function()
	while task.wait(1) do
		if game.PlaceId ~= LOBBY_ID then
			local dungeonGui = player.PlayerGui:FindFirstChild("Dungeon")
			if not dungeonGui then continue end

			if Options.AutoJoinToggle and Options.AutoJoinToggle.Value then
				local difficultyFrame = dungeonGui:FindFirstChild("Difficulty")
				if difficultyFrame and difficultyFrame.Visible then
					local difficultyOption = difficultyFrame:FindFirstChild(selectedDifficulty)
					if difficultyOption and difficultyOption.Visible then
						GuiService.SelectedObject = difficultyOption
						task.wait(0.1)
						pressKey(Enum.KeyCode.Return)
						task.wait(0.5)
					end
				end
			end

			if Options.AutoStartToggle and Options.AutoStartToggle.Value then
				local startFrame = dungeonGui:FindFirstChild("Start")
				if startFrame then
					while startFrame.Visible do
						GuiService.SelectedObject = startFrame
						task.wait(0.1)
						pressKey(Enum.KeyCode.Return)
						task.wait(0.2)
					end
					task.wait(2)
					if startFrame.Visible then
						GuiService.SelectedObject = startFrame
						task.wait(0.1)
						pressKey(Enum.KeyCode.Return)
						task.wait(0.5)
					end
				end
			end

			if Options.AutoRestartToggle and Options.AutoRestartToggle.Value then
				local restartFrame = dungeonGui:FindFirstChild("Restart")
				if restartFrame then
					while restartFrame.Visible do
						GuiService.SelectedObject = restartFrame
						task.wait(0.1)
						pressKey(Enum.KeyCode.Return)
						task.wait(0.2)
					end
					task.wait(2)
					if restartFrame.Visible then
						GuiService.SelectedObject = restartFrame
						task.wait(0.1)
						pressKey(Enum.KeyCode.Return)
						task.wait(0.5)
					end
				end
			end
		end
	end
end)

-- [UI BUILD: MAIN TAB]
do
	Fluent:Notify({
		Title = "Script",
		Content = "Script loaded successfully!",
		Duration = 5
	})
	
	local weaponsList = getWeaponsFromBackpack()
	
	local WeaponDropdown = Tabs.Main:AddDropdown("WeaponDropdown", {
		Title = "Select Weapon",
		Values = weaponsList,
		Multi = false,
		Default = 1
	})
	
	WeaponDropdown:OnChanged(function(Value)
		selectedWeaponName = Value
	end)
	
	Tabs.Main:AddButton({
		Title = "Refresh Weapon",
		Description = "Refresh weapon list",
		Callback = function()
			local newList = getWeaponsFromBackpack()
			WeaponDropdown:SetValues(newList)
			Fluent:Notify({
				Title = "Weapons Refreshed",
				Content = "Found " .. #newList .. " weapons",
				Duration = 3
			})
		end
	})
	
	if #weaponsList > 0 then
		selectedWeaponName = weaponsList[1]
	end
	
	local SkillDropdown = Tabs.Main:AddDropdown("SkillDropdown", {
		Title = "Select Skills",
		Description = "Automatically fires all selected skills",
		Values = {"Z", "X", "C", "V", "F"},
		Multi = true,
		Default = {}
	})
	
	SkillDropdown:OnChanged(function(Value)
		selectedSkills = Value
	end)
	
	local AutoFarmToggle = Tabs.Main:AddToggle("AutoFarmToggle", {
		Title = "Enable Auto Farm",
		Description = "Auto attack and kill mobs/bosses",
		Default = false
	})
	
	AutoFarmToggle:OnChanged(function()
		autoFarmEnabled = Options.AutoFarmToggle.Value
		if autoFarmEnabled then
			if selectedWeaponName == "" then
				Options.AutoFarmToggle:SetValue(false)
				Fluent:Notify({
					Title = "Warning",
					Content = "Please select a weapon first!",
					Duration = 3
				})
			else
				task.spawn(autoFarmLoop)
			end
		else
			currentTarget = nil
			currentTargetType = nil
			isDodgingUltimate = false
		end
	end)
	
	local AutoDodgeToggle = Tabs.Main:AddToggle("AutoDodgeToggle", {
		Title = "Auto Dodge Boss Ultimate",
		Description = "Dodge when boss HL Highlight appears",
		Default = false
	})
	
	AutoDodgeToggle:OnChanged(function()
		autoDodgeUltimate = Options.AutoDodgeToggle.Value
		if not autoDodgeUltimate then
			isDodgingUltimate = false
		end
	end)

	local AutoLeaveToggle = Tabs.Main:AddToggle("AutoLeaveToggle", {
		Title = "Auto Leave When Have Player",
		Description = "Leave dungeon if another player detected (solo only)",
		Default = false
	})

	AutoLeaveToggle:OnChanged(function()
		autoLeaveWithPlayer = Options.AutoLeaveToggle.Value
	end)

	Tabs.Main:AddParagraph({
		Title = "Farm Settings",
		Content = "Configure farming distance and behavior."
	})

	local DistanceSlider = Tabs.Main:AddSlider("MobsDistanceSlider", {
		Title = "Mobs Distance",
		Description = "Distance between you and mobs/boss (Default: 8)",
		Default = 8,
		Min = 1,
		Max = 30,
		Rounding = 1,
		Callback = function(Value)
			mobsDistance = Value
		end
	})

	DistanceSlider:OnChanged(function(Value)
		mobsDistance = Value
	end)
	
	Tabs.Main:AddParagraph({
		Title = "Boss Settings",
		Content = "Configure Boss Insta-Kill behavior."
	})
	
	local BossSlider = Tabs.Main:AddSlider("BossKillSlider", {
		Title = "Insta-Kill Boss at % Health",
		Description = "Sets Boss HP to 0 when it drops below this %",
		Default = 50,
		Min = 1,
		Max = 100,
		Rounding = 0,
		Callback = function(Value)
			bossKillThreshold = Value
		end
	})
	
	BossSlider:OnChanged(function(Value)
		bossKillThreshold = Value
	end)
	
	local HakiToggle = Tabs.Main:AddToggle("HakiToggle", {
		Title = "Enable Haki",
		Description = "Auto enable Haki",
		Default = true
	})
	
	HakiToggle:OnChanged(function()
		hakiEnabled = Options.HakiToggle.Value
		if hakiEnabled then
			ensureHaki()
		end
	end)
	
	local RejoinOnKickToggle = Tabs.Main:AddToggle("RejoinOnKickToggle", {
		Title = "Auto Rejoin When Kicked",
		Description = "Automatically rejoins lobby when kicked",
		Default = true
	})
	
	RejoinOnKickToggle:OnChanged(function()
		rejoinOnKickEnabled = Options.RejoinOnKickToggle.Value
		if rejoinOnKickEnabled then
			task.spawn(monitorKickMessages)
		end
	end)
end

-- [UI BUILD: AUTO JOIN TAB]
do
	local dungeons = getDungeonList()
	
	local DungeonDropdown = Tabs.AutoJoin:AddDropdown("DungeonDropdown", {
		Title = "Select Dungeon",
		Values = dungeons,
		Multi = false,
		Default = 1
	})
	
	DungeonDropdown:OnChanged(function(Value)
		selectedDungeon = Value
	end)
	
	local DifficultyDropdown = Tabs.AutoJoin:AddDropdown("DifficultyDropdown", {
		Title = "Select Difficulty",
		Values = {"Normal", "Hard"},
		Multi = false,
		Default = 1
	})
	
	DifficultyDropdown:OnChanged(function(Value)
		selectedDifficulty = Value
	end)
	
	Tabs.AutoJoin:AddToggle("AutoJoinToggle", {
		Title = "Auto Join Dungeon",
		Description = "Automatically join selected dungeon",
		Default = false
	})
	
	Tabs.AutoJoin:AddToggle("AutoStartToggle", {
		Title = "Auto Start",
		Description = "Automatically Press Start",
		Default = false
	})
	
	Tabs.AutoJoin:AddToggle("AutoRestartToggle", {
		Title = "Auto Restart",
		Description = "Automatically Press Restart",
		Default = false
	})
end

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("WnZHub")
SaveManager:SetFolder("WnZHub/configs")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
Window:SelectTab(1)
SaveManager:LoadAutoloadConfig()

task.spawn(function()
	task.wait(1.2)
	if Options.HakiToggle and Options.HakiToggle.Value then
		hakiEnabled = true
		ensureHaki()
	end
end)

-- Pat 4
