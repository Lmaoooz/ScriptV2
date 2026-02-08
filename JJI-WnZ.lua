repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players.LocalPlayer
repeat task.wait() until game.Players.LocalPlayer.Character

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Auto Investigation",
    SubTitle = "by WnZ",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "users" }),
    AutoJoin = Window:AddTab({ Title = "Auto Join", Icon = "layers" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local CHECK_INTERVAL = 0
local EMPTY_CHECK_TIME = 3
local LOBBY_PLACE_ID = 10450270085

local mobsFolder = workspace:WaitForChild("Objects"):WaitForChild("Mobs")
local missionItemsFolder = workspace.Objects:WaitForChild("MissionItems")
local dropsFolder = workspace.Objects:WaitForChild("Drops")
local spawnLocation = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Parts") and workspace.Map.Parts:FindFirstChild("SpawnLocation")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local autoFarmEnabled = false
local autoJoinLobbyEnabled = false
local autoJoinEnabled = false
local rejoinOnKickEnabled = false
local selectedStage = "Cursed School"
local selectedLevel = 1
local selectedDifficulty = "Easy"
local currentTarget = nil

player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoidRootPart = character:WaitForChild("HumanoidRootPart")
end)

local function checkAndKillNearbyMobs()
	if not humanoidRootPart or not humanoidRootPart.Parent then return end
	
	for _, mob in pairs(mobsFolder:GetChildren()) do
		if mob:IsA("Model") then
			local humanoid = mob:FindFirstChildOfClass("Humanoid")
			if humanoid then
				pcall(function()
					if humanoid.Health > 0 then
						humanoid.Health = 0
					end
				end)
			end
		end
	end
end

local function teleportAndFirePrompts()
	if not humanoidRootPart or not humanoidRootPart.Parent then return end
	
	for _, item in pairs(missionItemsFolder:GetChildren()) do
		if item:IsA("MeshPart") then
			humanoidRootPart.CFrame = item.CFrame
			task.wait(0.1)
			
			local proximityPrompt = item:FindFirstChildOfClass("ProximityPrompt", true)
			if proximityPrompt then
				fireproximityprompt(proximityPrompt)
			end
			
			task.wait(0.1)
		elseif item:IsA("Model") then
			local modelRoot = item:FindFirstChild("HumanoidRootPart") or item:FindFirstChild("Torso") or item:FindFirstChildWhichIsA("BasePart")
			
			if modelRoot then
				humanoidRootPart.CFrame = modelRoot.CFrame
				task.wait(0.03)
				
				local proximityPrompt = item:FindFirstChildOfClass("ProximityPrompt", true)
				if proximityPrompt then
					for i = 1, 15 do
						fireproximityprompt(proximityPrompt)
						task.wait(0.02)
					end
				end
				
				if spawnLocation then
					humanoidRootPart.CFrame = spawnLocation.CFrame
					task.wait(0.03)
					
					if proximityPrompt then
						for i = 1, 10 do
							fireproximityprompt(proximityPrompt)
							task.wait(0.02)
						end
					end
				end
			end
		end
	end
end

local lastEPress = 0
local function pressEIfDropsExist()
	if #dropsFolder:GetChildren() > 0 then
		if tick() - lastEPress >= 0.5 then
			VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
			task.wait(0.05)
			VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
			lastEPress = tick()
		end
	end
end

local function isFullyVisible(guiObject)
	if not guiObject then return false end
	
	local current = guiObject
	while current and current ~= game do
		if current:IsA("GuiObject") then
			if not current.Visible then
				return false
			end
		end
		current = current.Parent
	end
	
	return true
end

local function clickUIButtons()
	local buttons = {
		player.PlayerGui:FindFirstChild("StorylineDialogue") and player.PlayerGui.StorylineDialogue:FindFirstChild("Frame") and player.PlayerGui.StorylineDialogue.Frame:FindFirstChild("Dialogue") and player.PlayerGui.StorylineDialogue.Frame.Dialogue:FindFirstChild("Skip"),
		player.PlayerGui:FindFirstChild("InvestigationResults") and player.PlayerGui.InvestigationResults:FindFirstChild("Frame") and player.PlayerGui.InvestigationResults.Frame:FindFirstChild("Continue"),
		player.PlayerGui:FindFirstChild("Loot") and player.PlayerGui.Loot:FindFirstChild("Results") and player.PlayerGui.Loot.Results:FindFirstChild("Main") and player.PlayerGui.Loot.Results.Main:FindFirstChild("Continue"),
		player.PlayerGui:FindFirstChild("ReadyScreen") and player.PlayerGui.ReadyScreen:FindFirstChild("Frame") and player.PlayerGui.ReadyScreen.Frame:FindFirstChild("Replay")
	}
	
	for _, button in pairs(buttons) do
		if button and isFullyVisible(button) then
			GuiService.SelectedObject = button
			task.wait(0.05)
			VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
			task.wait(0.05)
			VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
			task.wait(0.1)
		end
	end
end

local function isTargetAlive()
	if not currentTarget or not currentTarget.Parent then
		return false
	end
	
	local humanoid = currentTarget:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		return true
	end
	
	return false
end

local function teleportToAliveMob()
	if not humanoidRootPart or not humanoidRootPart.Parent then return nil end
	
	for _, mob in pairs(mobsFolder:GetChildren()) do
		if mob:IsA("Model") and mob ~= currentTarget then
			local mobRoot = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso")
			local humanoid = mob:FindFirstChildOfClass("Humanoid")
			
			if mobRoot and humanoid and humanoid.Health > 0 then
				humanoidRootPart.CFrame = mobRoot.CFrame
				return mob
			end
		end
	end
	
	return nil
end

local function isMobsFolderEmpty()
	for _, mob in pairs(mobsFolder:GetChildren()) do
		if mob:IsA("Model") then
			return false
		end
	end
	return true
end

local function hasModelInMobs()
	for _, mob in pairs(mobsFolder:GetChildren()) do
		if mob:IsA("Model") then
			return true
		end
	end
	return false
end

local function autoFarmLoop()
	if game.PlaceId == LOBBY_PLACE_ID then
		return
	end
	
	currentTarget = teleportToAliveMob()
	
	local lastTeleportTime = 0
	local wasEmpty = false
	
	while autoFarmEnabled do
		if game.PlaceId == LOBBY_PLACE_ID then
			task.wait(1)
			continue
		end
		
		if not isTargetAlive() then
			currentTarget = teleportToAliveMob()
		end
		
		checkAndKillNearbyMobs()
		
		if not isTargetAlive() then
			currentTarget = teleportToAliveMob()
		end
		
		teleportAndFirePrompts()
		pressEIfDropsExist()
		clickUIButtons()
		
		local isEmpty = isMobsFolderEmpty()
		
		if isEmpty and not wasEmpty then
			lastTeleportTime = tick()
			wasEmpty = true
			currentTarget = nil
		elseif not isEmpty then
			if wasEmpty and tick() - lastTeleportTime >= EMPTY_CHECK_TIME then
				if hasModelInMobs() then
					currentTarget = teleportToAliveMob()
				end
				lastTeleportTime = tick()
			end
			wasEmpty = false
		end
		
		task.wait(CHECK_INTERVAL)
	end
end

local function autoJoinLobbyLoop()
	while autoJoinLobbyEnabled do
		if game.PlaceId ~= LOBBY_PLACE_ID then
			task.wait(1)
			continue
		end
		
		character:PivotTo(CFrame.new(Vector3.new(-309.895752, 4470.329102, -15742.235352)))
		task.wait(0.2)
		
		local acceptButton = player.PlayerGui:FindFirstChild("JoinQueue") and player.PlayerGui.JoinQueue:FindFirstChild("Frame") and player.PlayerGui.JoinQueue.Frame:FindFirstChild("Accept")
		
		if acceptButton and acceptButton.Visible then
			GuiService.SelectedObject = acceptButton
			task.wait(0.05)
			VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
			task.wait(0.05)
			VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
		end
		
		task.wait(0.5)
	end
end

local function autoJoinLoop()
	while autoJoinEnabled do
		if game.PlaceId == LOBBY_PLACE_ID then
			task.wait(1)
			continue
		end
		
		local args = {
			[1] = "Investigation",
			[2] = selectedStage,
			[3] = selectedLevel,
			[4] = selectedDifficulty
		}
		
		pcall(function()
			ReplicatedStorage.Remotes.Server.Raids.QuickStart:InvokeServer(unpack(args))
		end)
		
		task.wait(5)
	end
end

local function monitorKickMessages()
	while rejoinOnKickEnabled do
		task.wait(0.5)
		
		local coreGui = game:GetService("CoreGui")
		local kickPrompt = coreGui:FindFirstChild("RobloxPromptGui") and coreGui.RobloxPromptGui:FindFirstChild("promptOverlay")
		
		if kickPrompt and kickPrompt.Visible then
			if game.PlaceId ~= LOBBY_PLACE_ID then
				TeleportService:Teleport(LOBBY_PLACE_ID, player)
				break
			end
		end
		
		for _, gui in pairs(player.PlayerGui:GetChildren()) do
			if gui:IsA("ScreenGui") then
				for _, obj in pairs(gui:GetDescendants()) do
					if obj:IsA("TextLabel") or obj:IsA("TextButton") then
						local text = obj.Text:lower()
						if text:find("kick") or text:find("disconnect") or text:find("banned") or text:find("removed") then
							if game.PlaceId ~= LOBBY_PLACE_ID then
								TeleportService:Teleport(LOBBY_PLACE_ID, player)
								break
							end
						end
					end
				end
			end
		end
	end
end

do
	Fluent:Notify({
		Title = "Investigation Farm Hub",
		Content = "Script loaded successfully!",
		Duration = 5
	})
	
	local AutoFarmToggle = Tabs.Main:AddToggle("AutoFarmToggle", {
		Title = "Auto Farm Investigation",
		Description = "Auto Kill Aura/Replay/Rescue/Collect/Etc.",
		Default = false
	})
	
	AutoFarmToggle:OnChanged(function()
		autoFarmEnabled = Options.AutoFarmToggle.Value
		if autoFarmEnabled then
			if game.PlaceId == LOBBY_PLACE_ID then
				Fluent:Notify({
					Title = "Warning",
					Content = "Auto Farm only works outside lobby!",
					Duration = 3
				})
			else
				task.spawn(autoFarmLoop)
			end
		end
	end)
	
	local AutoJoinLobbyToggle = Tabs.Main:AddToggle("AutoJoinLobbyToggle", {
		Title = "Auto Join Investigation (Lobby)",
		Description = "Auto teleport into investigation area.",
		Default = false
	})
	
	AutoJoinLobbyToggle:OnChanged(function()
		autoJoinLobbyEnabled = Options.AutoJoinLobbyToggle.Value
		if autoJoinLobbyEnabled then
			if game.PlaceId ~= LOBBY_PLACE_ID then
				Fluent:Notify({
					Title = "Warning",
					Content = "This only works in lobby!",
					Duration = 3
				})
			else
				task.spawn(autoJoinLobbyLoop)
			end
		end
	end)
	
	local RejoinOnKickToggle = Tabs.Main:AddToggle("RejoinOnKickToggle", {
		Title = "Rejoin to lobby if kicked",
		Description = "Automatically Rejoins You When Got Any Kick Message.",
		Default = false
	})
	
	RejoinOnKickToggle:OnChanged(function()
		rejoinOnKickEnabled = Options.RejoinOnKickToggle.Value
		if rejoinOnKickEnabled then
			task.spawn(monitorKickMessages)
		end
	end)
	
	Tabs.AutoJoin:AddParagraph({
		Title = "Auto Join Settings",
		Content = "Select Stage/Level/Difficulty."
	})
	
	local StageDropdown = Tabs.AutoJoin:AddDropdown("StageDropdown", {
		Title = "Select Stage",
		Values = {"Cursed School", "Yasohachi Bridge", "Tokyo Subway", "Eerie Farm", "Detention Center"},
		Multi = false,
		Default = nil,
	})
	
	StageDropdown:OnChanged(function(Value)
		selectedStage = Value
	end)
	
	local LevelDropdown = Tabs.AutoJoin:AddDropdown("LevelDropdown", {
		Title = "Select Level",
		Values = {"1", "2", "3", "4"},
		Multi = false,
		Default = nil,
	})
	
	LevelDropdown:OnChanged(function(Value)
		selectedLevel = tonumber(Value)
	end)
	
	local DifficultyDropdown = Tabs.AutoJoin:AddDropdown("DifficultyDropdown", {
		Title = "Select Difficulty",
		Values = {"Easy", "Medium", "Hard", "Nightmare"},
		Multi = false,
		Default = nil,
	})
	
	DifficultyDropdown:OnChanged(function(Value)
		selectedDifficulty = Value
	end)
	
	local AutoJoinToggle = Tabs.AutoJoin:AddToggle("AutoJoinToggle", {
		Title = "Enable Auto Join",
		Description = "Auto Join Your Selected Stage",
		Default = false
	})
	
	AutoJoinToggle:OnChanged(function()
		autoJoinEnabled = Options.AutoJoinToggle.Value
		if autoJoinEnabled then
			if game.PlaceId == LOBBY_PLACE_ID then
				Fluent:Notify({
					Title = "Warning",
					Content = "Auto Join only works outside lobby!",
					Duration = 3
				})
			else
				task.spawn(autoJoinLoop)
			end
		end
	end)
end

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("InvestigationFarmHub")
SaveManager:SetFolder("InvestigationFarmHub/config")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

SaveManager:LoadAutoloadConfig()
