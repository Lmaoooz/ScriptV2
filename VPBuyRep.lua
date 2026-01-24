-- Code Made By Claude AI
-- Prompt Made By Me
local targetPlaceId = 86639052909924
if game.PlaceId ~= targetPlaceId then
    warn("Wrong game buddy, It's for: Verse Piece > " .. targetPlaceId)
    return
end

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local placeName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name

local MacLib = loadstring(game:HttpGet("https://github.com/biggaboy212/Maclib/releases/latest/download/maclib.txt"))()

local Window = MacLib:Window({
    Title = "Reputation Shop Purchaser",
    Subtitle = placeName,
    Size = UDim2.fromOffset(868, 650),
    DragStyle = 2,
    DisabledWindowControls = {},
    ShowUserInfo = false,
    Keybind = Enum.KeyCode.RightControl,
    AcrylicBlur = true,
})

task.spawn(function()
    for _, obj in pairs(game:GetService("CoreGui"):GetChildren()) do
        local screenGui = obj:FindFirstChild("ScreenGui")
        if screenGui then
            local base = screenGui:FindFirstChild("Base")
            if base and base:IsA("Frame") then
                base.Size = UDim2.fromOffset(868, 400)
                break
            end
        end
    end
end)

local globalSettings = {
    UIBlurToggle = Window:GlobalSetting({
        Name = "UI Blur (Optional)",
        Default = Window:GetAcrylicBlurState(),
        Callback = function(bool)
            Window:SetAcrylicBlurState(bool)
            Window:Notify({
                Title = Window.Settings.Title,
                Description = (bool and "Enabled" or "Disabled") .. " UI Blur",
                Lifetime = 5
            })
        end,
    }),
    NotificationToggler = Window:GlobalSetting({
        Name = "Notifications",
        Default = Window:GetNotificationsState(),
        Callback = function(bool)
            Window:SetNotificationsState(bool)
            Window:Notify({
                Title = Window.Settings.Title,
                Description = (bool and "Enabled" or "Disabled") .. " Notifications",
                Lifetime = 5
            })
        end,
    }),
    ShowUserInfo = Window:GlobalSetting({
        Name = "User Info Visibility (Optional)",
        Default = Window:GetUserInfoState(),
        Callback = function(bool)
            Window:SetUserInfoState(bool)
            Window:Notify({
                Title = Window.Settings.Title,
                Description = (bool and "Showing" or "Redacted") .. " User Info",
                Lifetime = 5
            })
        end,
    })
}

local tabGroups = {
    TabGroup1 = Window:TabGroup()
}

local tabs = {
    Buy = tabGroups.TabGroup1:Tab({ Name = "Purchase Menu", Image = "rbxassetid://114505581952233" }),
    Settings = tabGroups.TabGroup1:Tab({ Name = "Settings", Image = "rbxassetid://18801194936" })
}

local sections = {
    BuySection = tabs.Buy:Section({ Side = "Left" }),
    BuyManualSection = tabs.Buy:Section({ Side = "Left" }),
    InfoSection = tabs.Buy:Section({ Side = "Right" }),
    MiscSection = tabs.Buy:Section({ Side = "Right" }),
}

-- Hardcoded list of all buyable items with prices
local availableItems = {
    "Ability Reroll - 100",
    "Ability Storage - 350",
    "Aizen Eyepatch - 7,500",
    "American Flag - 100,000",
    "Anibus Sword - 75,000",
    "Angel Wing - 750",
    "Ant King Head - 65,000",
    "Ashen Ring - 1,500,000",
    "Babylon's Fragment - 3,000",
    "Babylon's Key - 7,000",
    "Basaka Dagger - 2,200",
    "Behelit - 100,000",
    "Boss Ticket - 200",
    "Brand of Sacrifice - 500,000",
    "Casull - 15,000",
    "Capsule - 5,000",
    "Champion Necklace - 50,000",
    "Chaos Ingot - 25,000",
    "Cid's Sword - 3,500",
    "Clover Leaf - 333",
    "Curse King Fingers - 20,000",
    "Curse Worm - 2,000",
    "Dragon Ball - 500",
    "Demon Core - 5,000",
    "Demon Ring - 1,500,000",
    "Dragonslayer - 75,000",
    "Drilling Artifact - 1,000",
    "Dungeon Medal - 1,000",
    "Dungeon Ticket - 750",
    "Elder Blood - 25,000",
    "Enchant Limitbreak Stone - 10,000",
    "Enhance Stone - 250",
    "Eternal Wisp - 2,500",
    "Explosive Artifact - 1,000",
    "Falcon Feather - 100,000",
    "Fire Essence - 25,000",
    "Forbidden Magic - 50,000",
    "Gae Bolg - 15,000",
    "Gacha Coins - 500",
    "Game Ball - 30,000",
    "Germa Blood - 1,200,000",
    "Golden Ball - 30,000",
    "Golden Earrings - 50,000",
    "Green Rage - 90,000",
    "Haki Mastery Book - 200",
    "Hogyoku Fragment - 5,000",
    "Ice Artifact - 1,000",
    "Infernal Core - 2,500",
    "Intelligent Artifact - 1,000",
    "Jackal - 15,000",
    "John-Smith Mask - 5,000,000",
    "Joker Card - 777",
    "Kamish Necklace - 50,000",
    "Kanshou - 25,000",
    "Killua Soul - 2,500",
    "King Card - 777",
    "Knight Dagger - 1,500",
    "Kokushibo's Sword - 7,500",
    "Legendary Saiyan Rage Serum - 85,000",
    "Legendary Shard - 25,000",
    "Light Ore - 500",
    "Light Shard - 200",
    "Limitbreak Stone - 5,000",
    "Los Lobos Core - 15,000",
    "Lucky Wisp - 5,000",
    "Mage Scarf - 1,000",
    "Mage Wisp - 3,500",
    "Magic Eye - 80,000",
    "Magic Treasure Vault - 75,000",
    "Matoi Staff - 120,000",
    "Memory Shards - 75,000",
    "Mimicry - 5,000",
    "Motivated Chair - 35,000",
    "Mysterious Arrow - 2,500",
    "Okarun Glasses - 20,000",
    "Phoenix Mantle - 75,000",
    "President Gun - 20,000",
    "Prestige Key - 75,000",
    "Previous Boss Ticket - 350",
    "Queen Card - 777",
    "Race Reroll - 100",
    "Race Storage - 350",
    "Raid Boss Ticket - 500",
    "Reason Eliminating Matter - 25,000",
    "Recovery Artifact - 1,000",
    "Remove Relic Potion - 350",
    "Remove Wisp Potion - 350",
    "Reroll Shard - 500",
    "Resurreccion Energy - 500",
    "Rinnegan Eyes - 7,000",
    "Rowan Fragment - 1,000",
    "Saiya Artifact - 1,000",
    "Saiyan Blood - 50,000",
    "Shadow Fragment - 700",
    "Shadow Shard - 500",
    "Sharingan Eyes - 7,000",
    "Six Eyes - 3,000",
    "Slime - 1,000",
    "Slime Core - 5,000",
    "Spell Scroll: Black Flame - 45,000",
    "Spell Scroll: Black Hole - 30,000",
    "Spell Scroll: Lightning - 15,000",
    "Spell Scroll: Lightning Storm - 15,000",
    "Spirit Hogyoku - 15,000",
    "Split Soul Katana - 250",
    "Sukuna Fingers - 350",
    "Sword of Light Recipe - 5,000",
    "Sword of Rupture - 75,000",
    "Tempest Ore - 7,500",
    "The True Sukuna Finger - 1,750",
    "Third Eyes - 250,000",
    "Trait Storage - 350",
    "True Hogyoku - 3,500",
    "True Six Eyes - 6,000",
    "Truth Essence - 50,000",
    "Turbo Artifact - 1,000",
    "Turbo Granny Soul - 1,500",
    "Ultimate Rune - 10,000",
    "Undead Artifact - 1,000",
    "Unusual Arrowhead - 35,000",
    "Unusual Arrowstick - 35,000",
    "Uryu Reiatsu - 10,000",
    "Void Eyes - 17,500",
    "Wado - 12,500",
    "Warrior Wisp - 7,500",
    "Wisp - 1,000",
    "Yamato's Sword - 35,000",
    "Zangetsu Soul - 500",
    "Zenitsu's Sword - 5,000",
    "Zeff Book - 1,200,000"
}

local firstTimeBuying = true

-- Helper function to extract item name from dropdown selection
local function extractItemName(fullText)
    local dashPos = fullText:find(" %- ")
    if dashPos then
        return fullText:sub(1, dashPos - 1)
    end
    return fullText
end

sections.BuySection:Header({
    Name = "Buy with Dropdown method"
})

-- Dropdown for selecting items
local ItemDropdown = sections.BuySection:Dropdown({
    Name = "Select Items",
    Search = true,
    Multi = false,
    Required = true,
    Options = availableItems,
    Default = 1,
    Callback = function(Value)
        print("Selected item: " .. Value)
    end,
}, "ItemDropdown")

local dropdownAmountValue = "1"

local dropdownAmountInput = sections.BuySection:Input({
    Name = "Amount of items to buy",
    Placeholder = "Enter amount (e.g., 5)",
    AcceptedCharacters = "Numbers",
    Callback = function(input)
        dropdownAmountValue = input
    end,
    onChanged = function(input)
        dropdownAmountValue = input
    end,
}, "DropdownAmountInput")

sections.BuySection:Divider()

sections.BuySection:Button({
    Name = "Buy Items (Dropdown)",
    Callback = function()
        local selectedItem = extractItemName(ItemDropdown.Value)
        
        if not selectedItem or selectedItem == "No items found" then
            Window:Notify({
                Title = "Error",
                Description = "Please select a valid item first!",
                Lifetime = 5
            })
            return
        end
        
        -- Function to execute buy logic
local function executeBuy()
    local amount = tonumber(dropdownAmountValue)
    
    if not amount or amount <= 0 then
        Window:Notify({
            Title = "Error",
            Description = "Please enter a valid amount (number greater than 0)!",
            Lifetime = 5
        })
        return
    end
    
    local success, err = pcall(function()
        local player = game:GetService("Players").LocalPlayer
        local repStoreGui = player.PlayerGui:FindFirstChild("Reputation Store")
        
        -- Set proximity prompt hold duration to 0
        local proximityPrompt = workspace.Npc.Misc["Reputation Store"].ProximityPrompt
        local originalHoldDuration = proximityPrompt.HoldDuration
        proximityPrompt.HoldDuration = 0
        
        -- Check if Reputation Store GUI already exists
        if not repStoreGui then
            -- Teleport to the position
            player.Character:PivotTo(CFrame.new(Vector3.new(-913.936157, 135.355194, 317.129181)))
            task.wait(0.3)
            
            -- Keep pressing E until GUI appears
            local VIM = game:GetService("VirtualInputManager")
            local maxAttempts = 20
            local attempts = 0
            
            while attempts < maxAttempts do
                repStoreGui = player.PlayerGui:FindFirstChild("Reputation Store")
                if repStoreGui then
                    break
                end
                
                -- Press E key
                VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                task.wait(0.05)
                VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                task.wait(0.2)
                
                attempts = attempts + 1
            end
            
            if not repStoreGui then
                proximityPrompt.HoldDuration = originalHoldDuration
                Window:Notify({
                    Title = "Error",
                    Description = "Failed to open Reputation Store!",
                    Lifetime = 5
                })
                return
            end
        end
        
        -- Show the GUI
        repStoreGui.Enabled = true
        task.wait(0.3)
        
        -- Buy the item multiple times based on amount
        for i = 1, amount do
            local args = {
                [1] = "Buy",
                [2] = selectedItem
            }
            
            local buySuccess, buyErr = pcall(function()
                repStoreGui.BG.Iinv.Function:InvokeServer(unpack(args))
            end)
            
            if not buySuccess then
                Window:Notify({
                    Title = "Purchase Failed",
                    Description = "Error on item " .. i .. ": " .. tostring(buyErr),
                    Lifetime = 5
                })
            end
            
            task.wait(0.1) -- Small delay between purchases
        end
        
        Window:Notify({
            Title = "Success",
            Description = "Purchased " .. amount .. "x " .. selectedItem,
            Lifetime = 5
        })
        
        -- Close the GUI and restore proximity prompt
        task.wait(0.2)
        repStoreGui.Enabled = false
        proximityPrompt.HoldDuration = originalHoldDuration
    end)
    
    if not success then
        Window:Notify({
            Title = "Error",
            Description = "Failed to buy: " .. tostring(err),
            Lifetime = 5
        })
    end
            end
        
        -- Show dialog on first time
        if firstTimeBuying then
            Window:Dialog({
                Title = "Stop right there.",
                Description = "First time pressing the button, would you like to teleport and open the shop first?",
                Buttons = {
                    {
                        Name = "Yes",
                        Callback = function()
                            firstTimeBuying = false
                            task.spawn(function()
                                task.wait(0.3)
                                executeBuy()
                            end)
                        end,
                    },
                    {
                        Name = "No",
                        Callback = function()
                            -- Do nothing, just close dialog
                        end
                    }
                }
            })
        else
            executeBuy()
        end
    end,
})

-- Manual input section
sections.BuyManualSection:Header({
    Name = "Buy with Manual method"
})

local manualItemValue = ""

local manualItemInput = sections.BuyManualSection:Input({
    Name = "Enter an item name you want to buy",
    Placeholder = "Enter item name",
    AcceptedCharacters = "All",
    Callback = function(input)
        manualItemValue = input
        print("Manual item input: " .. input)
    end,
    onChanged = function(input)
        manualItemValue = input
    end,
}, "ManualItemInput")

local manualAmountValue = "1"

local manualAmountInput = sections.BuyManualSection:Input({
    Name = "Amount of items to buy",
    Placeholder = "Enter amount (e.g., 5)",
    AcceptedCharacters = "Numbers",
    Callback = function(input)
        manualAmountValue = input
    end,
    onChanged = function(input)
        manualAmountValue = input
    end,
}, "ManualAmountInput")

sections.BuyManualSection:Divider()

sections.BuyManualSection:Button({
    Name = "Buy Item (Manual)",
    Callback = function()
        local manualItem = manualItemValue
        
        -- Trim whitespace
        manualItem = manualItem:match("^%s*(.-)%s*$")
        
        if manualItem == "" then
            Window:Notify({
                Title = "Error",
                Description = "Please enter an item name first!",
                Lifetime = 5
            })
            return
        end
        
        -- Function to execute buy logic for manual input
local function executeManualBuy()
    local amount = tonumber(manualAmountValue)
    
    if not amount or amount <= 0 then
        Window:Notify({
            Title = "Error",
            Description = "Please enter a valid amount (number greater than 0)!",
            Lifetime = 5
        })
        return
    end
    
    local success, err = pcall(function()
        local player = game:GetService("Players").LocalPlayer
        local repStoreGui = player.PlayerGui:FindFirstChild("Reputation Store")
        
        -- Set proximity prompt hold duration to 0
        local proximityPrompt = workspace.Npc.Misc["Reputation Store"].ProximityPrompt
        local originalHoldDuration = proximityPrompt.HoldDuration
        proximityPrompt.HoldDuration = 0
        
        -- Check if Reputation Store GUI already exists
        if not repStoreGui then
            -- Teleport to the position
            player.Character:PivotTo(CFrame.new(Vector3.new(-913.936157, 135.355194, 317.129181)))
            task.wait(0.3)
            
            -- Keep pressing E until GUI appears
            local VIM = game:GetService("VirtualInputManager")
            local maxAttempts = 20
            local attempts = 0
            
            while attempts < maxAttempts do
                repStoreGui = player.PlayerGui:FindFirstChild("Reputation Store")
                if repStoreGui then
                    break
                end
                
                -- Press E key
                VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                task.wait(0.05)
                VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                task.wait(0.2)
                
                attempts = attempts + 1
            end
            
            if not repStoreGui then
                proximityPrompt.HoldDuration = originalHoldDuration
                Window:Notify({
                    Title = "Error",
                    Description = "Failed to open Reputation Store!",
                    Lifetime = 5
                })
                return
            end
        end
        
        -- Show the GUI
        repStoreGui.Enabled = true
        task.wait(0.3)
        
        -- Buy the item multiple times based on amount
        local successfulPurchases = 0
        
        for i = 1, amount do
            -- Get current frames in Material before buying
            local announceGui = player.PlayerGui:FindFirstChild("Annouce")
            local materialFolder = announceGui and announceGui:FindFirstChild("Material")
            local beforeFrames = {}
            
            if materialFolder then
                for _, child in pairs(materialFolder:GetChildren()) do
                    if child:IsA("Frame") then
                        beforeFrames[child.Name] = true
                    end
                end
            end
            
            -- Buy the item using manual input
            local args = {
                [1] = "Buy",
                [2] = manualItem
            }
            
            local buySuccess, buyErr = pcall(function()
                repStoreGui.BG.Iinv.Function:InvokeServer(unpack(args))
            end)
            
            if buySuccess then
                -- Wait and check for new frames in Material
                local boughtItemName = nil
                local checkDuration = 2
                local checkInterval = 0.1
                local totalWaited = 0
                
                while totalWaited < checkDuration and not boughtItemName do
                    task.wait(checkInterval)
                    totalWaited = totalWaited + checkInterval
                    
                    if materialFolder then
                        for _, child in pairs(materialFolder:GetChildren()) do
                            if child:IsA("Frame") and not beforeFrames[child.Name] then
                                boughtItemName = child.Name
                                break
                            end
                        end
                    end
                end
                
                if boughtItemName then
                    successfulPurchases = successfulPurchases + 1
                end
            end
            
            task.wait(0.1) -- Small delay between purchases
        end
        
        if successfulPurchases > 0 then
            Window:Notify({
                Title = "Success",
                Description = "Purchased: " .. successfulPurchases .. "x items",
                Lifetime = 5
            })
        else
            Window:Notify({
                Title = "Failed",
                Description = "No items purchased. Check item name or availability.",
                Lifetime = 5
            })
        end
        
        -- Close the GUI and restore proximity prompt
        task.wait(0.2)
        repStoreGui.Enabled = false
        proximityPrompt.HoldDuration = originalHoldDuration
    end)
    
    if not success then
        Window:Notify({
            Title = "Error",
            Description = "Failed to buy: " .. tostring(err),
            Lifetime = 5
        })
    end
            end
        
        -- Show dialog on first time
        if firstTimeBuying then
            Window:Dialog({
                Title = "Stop right there.",
                Description = "Seemed like it's your first time pressing the button, would you like to teleport and open the shop first?",
                Buttons = {
                    {
                        Name = "Yes",
                        Callback = function()
                            firstTimeBuying = false
                            task.spawn(function()
                                task.wait(0.3)
                                executeManualBuy()
                            end)
                        end,
                    },
                    {
                        Name = "No",
                        Callback = function()
                            -- Do nothing, just close dialog
                        end
                    }
                }
            })
        else
            executeManualBuy()
        end
    end,
})

-- Right section paragraph
sections.InfoSection:Paragraph({
    Header = "Information",
    Body = "- Some items may cannot be purchased, it's not script's fault.\n- You can purchase any items even if they're not in stocks.\n- You can try to use Manual method if the item you want is not available in dropdown."
})

-- Misc Section
sections.MiscSection:Paragraph({
    Header = "How to fix",
    Body = "Can't interact with NPC'S?\n- Press this button below and\n- Problem Fixed. Now you can interact with NPC'S."
})

sections.MiscSection:Button({
    Name = "Close Reputation GUI",
    Callback = function()
        task.spawn(function()
            local player = game:GetService("Players").LocalPlayer
            local repStoreGui = player.PlayerGui:FindFirstChild("Reputation Store")

            if repStoreGui then
                -- Make GUI visible
                repStoreGui.Enabled = true
                task.wait(0.2)

                -- Set SelectedObject to Cancel button
                local cancelButton = repStoreGui.BG.Iinv.Cancel
                game:GetService("GuiService").SelectedObject = cancelButton
                task.wait(0.1)

                -- Simulate Enter key
                local VIM = game:GetService("VirtualInputManager")
                VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                task.wait(0.05)
                VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)

                task.wait(0.2)

                Window:Notify({
                    Title = "Success",
                    Description = "Reputation Shop GUI closed!",
                    Lifetime = 3
                })
            else
                Window:Notify({
                    Title = "Error",
                    Description = "Reputation Shop GUI not found!",
                    Lifetime = 3
                })
            end
        end)
    end,
})

MacLib:SetFolder("VersePieceRepShop")
tabs.Settings:InsertConfigSection("Left")

Window.onUnloaded(function()
    print("Script Unloaded!")
end)

tabs.Buy:Select()
MacLib:LoadAutoLoadConfig()

-- Create open/close button
local OpenCloseGui = Instance.new("ScreenGui")
OpenCloseGui.Name = "RepShopToggleButton"
OpenCloseGui.ResetOnSpawn = false
OpenCloseGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
OpenCloseGui.Parent = game:GetService("CoreGui")

local ButtonFrame = Instance.new("Frame")
ButtonFrame.Name = "ButtonFrame"
ButtonFrame.Size = UDim2.fromOffset(60, 60)
ButtonFrame.Position = UDim2.new(0, 10, 0, 370)
ButtonFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ButtonFrame.BorderSizePixel = 0
ButtonFrame.Active = true
ButtonFrame.Draggable = true
ButtonFrame.Parent = OpenCloseGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = ButtonFrame

local IconButton = Instance.new("ImageButton")
IconButton.Name = "IconButton"
IconButton.Size = UDim2.fromScale(1, 1)
IconButton.Position = UDim2.fromScale(0, 0)
IconButton.BackgroundTransparency = 1
IconButton.Image = "rbxassetid://118786472658875"
IconButton.ScaleType = Enum.ScaleType.Fit
IconButton.Parent = ButtonFrame

-- Function to find and toggle MacLib UI
local function toggleMacLibUI()
    for _, obj in pairs(game:GetService("CoreGui"):GetChildren()) do
        local screenGui = obj:FindFirstChild("ScreenGui")
        if screenGui then
            local base = screenGui:FindFirstChild("Base")
            if base and base:IsA("Frame") then
                screenGui.Enabled = not screenGui.Enabled
                return
            end
        end
    end
end

IconButton.MouseButton1Click:Connect(function()
    toggleMacLibUI()
end)
