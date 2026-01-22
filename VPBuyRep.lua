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
    Buy = tabGroups.TabGroup1:Tab({ Name = "Purchase Menu", Image = "rbxassetid://10734950309" }),
    Settings = tabGroups.TabGroup1:Tab({ Name = "Settings", Image = "rbxassetid://10734950309" })
}

local sections = {
    BuySection = tabs.Buy:Section({ Side = "Left" }),
    InfoSection = tabs.Buy:Section({ Side = "Right" }),
}

-- Function to get all available items
local function getAvailableItems()
    local items = {}
    local success, err = pcall(function()
        local slotUI = game:GetService("ReplicatedStorage").Assets.UIs["Reputation Store"].BG.Iinv.Material.Template.Slot.UI
        for _, child in pairs(slotUI:GetChildren()) do
            table.insert(items, child.Name)
        end
    end)
    
    if not success then
        Window:Notify({
            Title = "Error",
            Description = "Failed to get items: " .. tostring(err),
            Lifetime = 5
        })
        return {"No items found"}
    end
    
    return #items > 0 and items or {"No items found"}
end

-- Get items for dropdown
local availableItems = getAvailableItems()
local firstTimeBuying = true

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

sections.BuySection:Button({
    Name = "Buy Items (Dropdown)",
    Callback = function()
        local selectedItem = ItemDropdown.Value
        
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
                
                -- Buy the item
                local args = {
                    [1] = "Buy",
                    [2] = selectedItem
                }
                
                local buySuccess, buyErr = pcall(function()
                    repStoreGui.BG.Iinv.Function:InvokeServer(unpack(args))
                end)
                
                if buySuccess then
                    Window:Notify({
                        Title = "Success",
                        Description = "Purchased: " .. selectedItem,
                        Lifetime = 5
                    })
                else
                    Window:Notify({
                        Title = "Purchase Failed",
                        Description = "Error: " .. tostring(buyErr),
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
                Title = "Auto Buy Script",
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

sections.BuySection:Divider()

-- Refresh items button
sections.BuySection:Button({
    Name = "Refresh Items List",
    Callback = function()
        local newItems = getAvailableItems()
        ItemDropdown:UpdateSelection(newItems[1])
        Window:Notify({
            Title = "Success",
            Description = "Items list refreshed!",
            Lifetime = 3
        })
    end,
})

sections.BuySection:Divider()

-- Manual input section
sections.BuySection:Header({
    Name = "Buy with Manual method"
})

local manualItemValue = ""

local manualItemInput = sections.BuySection:Input({
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

sections.BuySection:Button({
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
                    -- Wait and check for new frames in Material (up to 4 seconds)
                    local boughtItemName = nil
                    local checkDuration = 4
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
                        Window:Notify({
                            Title = "Success",
                            Description = "Purchased: " .. boughtItemName,
                            Lifetime = 5
                        })
                    else
                        Window:Notify({
                            Title = "Failed",
                            Description = "Purchased: Nothing. You write it wrong or items you entered wasn't purchaseable.",
                            Lifetime = 5
                        })
                    end
                else
                    Window:Notify({
                        Title = "Purchase Failed",
                        Description = "Error: " .. tostring(buyErr),
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

MacLib:SetFolder("VersePieceRepShop")
tabs.Settings:InsertConfigSection("Left")

Window.onUnloaded(function()
    print("Script Unloaded!")
end)

tabs.Buy:Select()
MacLib:LoadAutoLoadConfig()
