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
local selectedWeaponName = ""
local selectedSkills = {}
local bossKillThreshold = 80
local currentTargetRoot = nil
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

-- [TARGET FINDING LOGIC]
local function findAliveMob()
	-- Priority: Boss (any boss in folder, even if HP is unknown)
	for _, boss in pairs(bossFolder:GetChildren()) do
		if boss:IsA("Model") then
			local root = boss:FindFirstChild("HumanoidRootPart") or boss:FindFirstChild("Torso")
			if root then
				return boss, root, true
			end
		end
	end
	
	-- Secondary: Mob (any existing child)
	for _, mob in pairs(mobsFolder:GetChildren()) do
		if mob:IsA("Model") then
			local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso")
			if root then
				return mob, root, false
			end
		end
	end
	
	return nil, nil, false
end

-- [KILL LOGIC]
local function killRegularMobs()
	for _, mob in pairs(mobsFolder:GetChildren()) do
		if mob:IsA("Model") then
			local hum = mob:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				pcall(function()
					hum.Health = 0
				end)
			end
		end
	end
end

local function checkAndKillBosses()
	for _, boss in pairs(bossFolder:GetChildren()) do
		if boss:IsA("Model") then
			local hum = boss:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 and hum.MaxHealth > 0 then
				local current = hum.Health
				local max = hum.MaxHealth
				local percentRemaining = (current / max) * 100
				
				if percentRemaining <= bossKillThreshold then
					pcall(function()
						hum.Health = 0
					end)
				end
			end
		end
	end
end

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

-- [HEARTBEAT TELEPORT LOOP] - Fixed to always update when target exists
RunService.Heartbeat:Connect(function()
	if autoFarmEnabled and currentTargetRoot and currentTargetRoot.Parent and humanoidRootPart and humanoidRootPart.Parent then
		local behindCFrame = currentTargetRoot.CFrame * CFrame.new(0, 0, 4)
		humanoidRootPart.CFrame = behindCFrame
		
		if humanoidRootPart.AssemblyLinearVelocity.Magnitude > 0 then
			humanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		end
	end
end)

-- [MAIN AUTO FARM LOOP] - Fixed to continuously find targets
local function autoFarmLoop()
	equipWeapon()
	task.wait(0.5)
	
	while autoFarmEnabled do
		if not isWeaponEquipped() then
			equipWeapon()
		end
		
		-- Always try to find a target
		local target, root, isBoss = findAliveMob()
		
		if target and root then
			currentTargetRoot = root
			
			-- Always attack
			pressMouseButton()
			
			-- Always use skills
			for skillKey, enabled in pairs(selectedSkills) do
				if enabled then
					useKeySkill(skillKey)
				end
			end
		else
			currentTargetRoot = nil
		end
		
		-- Kill logic
		killRegularMobs()
		checkAndKillBosses()
		
		task.wait(0)
	end
	
	currentTargetRoot = nil
end

-- [CHECK IF PLAYER IS IN DUNGEON]
local function isPlayerInDungeon()
	pcall(function()
		local dungeonPortals = workspace.Main.Characters:FindFirstChild("Rogue Town")
		if dungeonPortals then
			local portalsFolder = dungeonPortals:FindFirstChild("Dungeons")
			if portalsFolder then
				local portalPart = portalsFolder:FindFirstChild(selectedDungeon)
				if portalPart and portalPart:IsA("Part") then
					local playersFolder = portalPart:FindFirstChild("Players")
					if playersFolder then
						for _, stringValue in pairs(playersFolder:GetChildren()) do
							if stringValue:IsA("StringValue") and stringValue.Value == player.Name then
								return true
							end
						end
					end
				end
			end
		end
	end)
	return false
end

-- [AUTO JOIN LOBBY LOGIC - ONLY IN LOBBY]
local function autoJoinDungeon()
	if game.PlaceId ~= LOBBY_ID then return end
	if not Options.AutoJoinToggle or not Options.AutoJoinToggle.Value then return end
	
	pcall(function()
		-- Check if already in dungeon
		if isPlayerInDungeon() then
			return
		end
		
		-- Portal doesn't exist or player not in it, proceed with joining
		local dungeonSpawn = player.PlayerGui.Button:FindFirstChild("Dungeon Spawn")
		if not dungeonSpawn then return end
		
		-- Make GUI visible
		dungeonSpawn.Visible = true
		task.wait(0.5)
		
		-- Select dungeon by clicking its frame
		local dungeonFrame = dungeonSpawn.Dungeon.Frame:FindFirstChild(selectedDungeon)
		if dungeonFrame then
			GuiService.SelectedObject = dungeonFrame
			task.wait(0.1)
			pressKey(Enum.KeyCode.Return)
			task.wait(0.5)
		end
		
		-- Click Spawn button
		local spawnButton = dungeonSpawn.Dungeon:FindFirstChild("Spawn")
		if spawnButton then
			GuiService.SelectedObject = spawnButton
			task.wait(0.1)
			pressKey(Enum.KeyCode.Return)
			task.wait(1)
		end
		
		-- Find portal and keep pressing E until player is in dungeon
		local dungeonPortals = workspace.Main.Characters:FindFirstChild("Rogue Town")
		if dungeonPortals then
			local portalsFolder = dungeonPortals:FindFirstChild("Dungeons")
			if portalsFolder then
				local portalPart = portalsFolder:FindFirstChild(selectedDungeon)
				if portalPart and portalPart:IsA("Part") then
					-- Set ProximityPrompt duration to 0
					local prompt = portalPart:FindFirstChildOfClass("ProximityPrompt")
					if prompt then
						prompt.HoldDuration = 0
					end
					
					-- Keep pressing E until player is in dungeon
					while not isPlayerInDungeon() and Options.AutoJoinToggle and Options.AutoJoinToggle.Value do
						-- Teleport to portal
						humanoidRootPart.CFrame = portalPart.CFrame
						task.wait(0.1)
						
						-- Press E
						pressKey(Enum.KeyCode.E)
						task.wait(0.2)
					end
				end
			end
		end
	end)
end

-- Auto Join Trigger - Only runs when toggle is enabled
task.spawn(function()
	while task.wait(3) do
		if game.PlaceId == LOBBY_ID and Options.AutoJoinToggle and Options.AutoJoinToggle.Value then
			autoJoinDungeon()
		end
	end
end)

-- [IN-DUNGEON AUTO DIFFICULTY/START/RESTART - NOT IN LOBBY]
task.spawn(function()
	while task.wait(1) do
		if game.PlaceId ~= LOBBY_ID then
			local dungeonGui = player.PlayerGui:FindFirstChild("Dungeon")
			if not dungeonGui then continue end
			
			-- Auto Difficulty Selection
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
			
			-- Auto Start
			if Options.AutoStartToggle and Options.AutoStartToggle.Value then
				local startFrame = dungeonGui:FindFirstChild("Start")
				if startFrame and startFrame.Visible then
					GuiService.SelectedObject = startFrame
					task.wait(0.1)
					pressKey(Enum.KeyCode.Return)
					task.wait(0.5)
				end
			end
			
			-- Auto Restart
			if Options.AutoRestartToggle and Options.AutoRestartToggle.Value then
				local restartFrame = dungeonGui:FindFirstChild("Restart")
				if restartFrame and restartFrame.Visible then
					GuiService.SelectedObject = restartFrame
					task.wait(0.1)
					pressKey(Enum.KeyCode.Return)
					task.wait(0.5)
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
			currentTargetRoot = nil
		end
	end)
	
	Tabs.Main:AddParagraph({
		Title = "Boss Settings",
		Content = "Configure Boss Insta-Kill behavior."
	})
	
	local BossSlider = Tabs.Main:AddSlider("BossKillSlider", {
		Title = "Insta-Kill Boss at % Health",
		Description = "Sets Boss HP to 0 when it drops below this %",
		Default = 50,
		Min = 0,
		Max = 100,
		Rounding = 1,
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

-- Delayed Haki activation after load
task.spawn(function()
	task.wait(1.2)
	if Options.HakiToggle and Options.HakiToggle.Value then
		hakiEnabled = true
		ensureHaki()
	end
end)
