-- Anti-freeze protection
local success, err = pcall(function()
    
-- Destroy old UI if exists
if _G.NQN_Window then
    pcall(function()
        _G.NQN_Window:Destroy()
    end)
end
if _G.NQN_Running then
    _G.NQN_Running = false
end

-- Wait for game to load
if not game:IsLoaded() then
    game.Loaded:Wait()
end

print("🔄 Loading ArrayField Library...")

-- Load ArrayField Library with timeout
local ArrayField
local loadSuccess = pcall(function()
    ArrayField = loadstring(game:HttpGet("https://raw.githubusercontent.com/UI-Interface/ArrayField/main/Source.lua",true))()
end)

if not loadSuccess or not ArrayField then
    warn("❌ Failed to load ArrayField library!")
    return
end

print("✅ ArrayField loaded successfully!")

-- Get PlaceId
local currentPlaceId = game.PlaceId

-- PlaceIds
local MENU_PLACEID = 131079272918660
local GAME_PLACEID = 136364146980997

local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")

-- Wait for player with timeout
local player = Players.LocalPlayer
if not player then
    warn("❌ LocalPlayer not found!")
    return
end

local timeout = 10
local waited = 0
while not player:FindFirstChild("PlayerGui") and waited < timeout do
    task.wait(0.5)
    waited = waited + 0.5
end

if not player:FindFirstChild("PlayerGui") then
    warn("❌ PlayerGui not found after timeout!")
    return
end

print("✅ Player loaded!")
task.wait(1)

if currentPlaceId == MENU_PLACEID then
    print("📍 Menu Place detected")
    
    -- ===== MENU UI =====
    local Window = ArrayField:CreateWindow({
        Name = "Ngô Quang Nam - guns.lol/shopbss",
        LoadingTitle = "Loading...",
        LoadingSubtitle = "Menu Mode",
        ConfigurationSaving = {
            Enabled = true,
            FolderName = nil,
            FileName = "NQN_MenuConfig"
        },
        Discord = {
            Enabled = false,
            Invite = "noinvite",
            RememberJoins = true
        },
        KeySystem = false,
        KeySettings = {
            Title = "Key",
            Subtitle = "Key System",
            Note = "No key",
            FileName = "Key",
            SaveKey = false,
            GrabKeyFromSite = false,
            Key = {""}
        }
    })

    local MainTab = Window:CreateTab("Main", 4483362458)
    
    -- Store window reference
    _G.NQN_Window = Window
    _G.NQN_Running = false
    
    -- Variables
    local autoRunning = false
    local selectedSlot = 1
    
    -- Load saved config
    pcall(function()
        if isfile("NQNSCR_Menu.txt") then
            local configData = readfile("NQNSCR_Menu.txt")
            local config = HttpService:JSONDecode(configData)
            selectedSlot = config.selectedSlot or 1
            autoRunning = config.autoRunning or false
        end
    end)
    
    -- Auto-save function
    local function saveConfig()
        pcall(function()
            local config = {
                selectedSlot = selectedSlot,
                autoRunning = autoRunning
            }
            writefile("NQNSCR_Menu.txt", HttpService:JSONEncode(config))
        end)
    end
    
    -- Functions
    local function clickPlay()
        pcall(function()
            local playButton = Players.LocalPlayer.PlayerGui.Main.Menu.Buttons["PLAY GAME"].Button
            firesignal(playButton.MouseButton1Click)
        end)
    end
    
    local function fireSlot(slotNum)
        pcall(function()
            local remoteLoaded = game:GetService("ReplicatedStorage").Files.Remotes.Loaded
            remoteLoaded:FireServer(slotNum)
        end)
    end
    
    local function runAuto()
        if not autoRunning then return end
        clickPlay()
        task.wait(2)
        fireSlot(selectedSlot)
    end
    
    -- UI Elements
    MainTab:CreateSection("Main")
    
    local Toggle = MainTab:CreateToggle({
        Name = "Auto Run Slot",
        CurrentValue = autoRunning,
        Flag = "AutoRunToggle",
        Callback = function(Value)
            autoRunning = Value
            saveConfig()
            if Value then
                ArrayField:Notify({
                    Title = "Started",
                    Content = "Slot " .. selectedSlot,
                    Duration = 3,
                    Image = 4483362458
                })
                task.spawn(runAuto)
            end
        end
    })
    
    -- Auto-start if was enabled
    if autoRunning then
        task.spawn(function()
            task.wait(0.5)
            runAuto()
        end)
    end
    
    local Slider = MainTab:CreateSlider({
        Name = "Select Slot",
        Range = {1, 10},
        Increment = 1,
        CurrentValue = selectedSlot,
        Flag = "SlotNumber",
        Callback = function(Value)
            selectedSlot = Value
            saveConfig()
        end
    })
    
    MainTab:CreateSection("Info")
    local Label = MainTab:CreateLabel("Slot: " .. selectedSlot)
    local StatusLabel = MainTab:CreateLabel("Status: Idle")
    
    task.spawn(function()
        while task.wait(0.5) do
            pcall(function()
                if Label and Label.Set then
                    Label:Set("Slot: " .. selectedSlot)
                end
                if StatusLabel and StatusLabel.Set then
                    StatusLabel:Set("Status: " .. (autoRunning and "Running" or "Idle"))
                end
            end)
        end
    end)
    
    ArrayField:LoadConfiguration()
    print("✅ Menu UI loaded!")

elseif currentPlaceId == GAME_PLACEID then
    print("📍 Game Place detected")
    
    -- ===== GAME UI =====
    local Window = ArrayField:CreateWindow({
        Name = "Ngô Quang Nam - guns.lol/shopbss",
        LoadingTitle = "Loading...",
        LoadingSubtitle = "Game Mode",
        ConfigurationSaving = {
            Enabled = true,
            FolderName = nil,
            FileName = "NQN_GameConfig"
        },
        Discord = {
            Enabled = false,
            Invite = "noinvite",
            RememberJoins = true
        },
        KeySystem = false,
        KeySettings = {
            Title = "Key",
            Subtitle = "Key System",
            Note = "No key",
            FileName = "Key",
            SaveKey = false,
            GrabKeyFromSite = false,
            Key = {""}
        }
    })

    local MainTab = Window:CreateTab("Main", 4483362458)
    
    -- Store window reference
    _G.NQN_Window = Window
    _G.NQN_Running = true
    
    -- Variables
    local autoRunning = false
    local currentStep = "Idle"
    local retryCount = 0
    local webhookUrl1 = ""  -- Webhook 1: All fiends with full info
    local webhookUrl2 = ""  -- Webhook 2: Only Violence/Gun/Angel/Blood, no player name
    local webhook1Enabled = false
    local webhook2Enabled = false
    local lastFiendFound = ""
    local webhookSent = false
    local lastWebhookTest = 0
    local useCustomName = false
    local customName = ""
    local discordID = ""
    
    -- Load saved config
    pcall(function()
        if isfile("NQNSCR_Game.txt") then
            local configData = readfile("NQNSCR_Game.txt")
            local config = HttpService:JSONDecode(configData)
            webhookUrl1 = config.webhookUrl1 or ""
            webhookUrl2 = config.webhookUrl2 or ""
            webhook1Enabled = config.webhook1Enabled or false
            webhook2Enabled = config.webhook2Enabled or false
            autoRunning = config.autoRunning or false
            useCustomName = config.useCustomName or false
            customName = config.customName or ""
            discordID = config.discordID or ""
        end
    end)
    
    -- Auto-save function
    local function saveConfig()
        pcall(function()
            local config = {
                webhookUrl1 = webhookUrl1,
                webhookUrl2 = webhookUrl2,
                webhook1Enabled = webhook1Enabled,
                webhook2Enabled = webhook2Enabled,
                autoRunning = autoRunning,
                useCustomName = useCustomName,
                customName = customName,
                discordID = discordID
            }
            writefile("NQNSCR_Game.txt", HttpService:JSONEncode(config))
        end)
    end
    
    -- Helper Functions - SAFE NAME GENERATOR (MAX 10 CHARS)
    local function generateRandomName()
        local prefixes = {
            "Pro", "Max", "Ace", "God", "Rex",
            "Hex", "Zen", "Kai", "Ray",
            "Leo", "Jay", "Sam", "Ben", "Ken"
        }
        
        local formatType = math.random(1, 3)
        local name = ""
        
        if formatType == 1 then
            name = prefixes[math.random(1, #prefixes)] .. math.random(1000, 9999)
        elseif formatType == 2 then
            name = prefixes[math.random(1, #prefixes)] .. math.random(10000, 99999)
        else
            local letters = "XYZABCDEFGH"
            name = prefixes[math.random(1, #prefixes)] .. math.random(100, 999) .. letters:sub(math.random(1, #letters), math.random(1, #letters))
        end
        
        if #name > 10 then
            name = prefixes[math.random(1, #prefixes)] .. math.random(1000, 9999)
        end
        
        return name
    end
    
    -- Function to get name (custom or random)
    local function getName()
        if useCustomName and customName ~= "" then
            return customName:sub(1, 10)
        else
            return generateRandomName()
        end
    end
    
    local function pressKey(key)
        VirtualInputManager:SendKeyEvent(true, key, false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, key, false, game)
    end
    
    local function typeText(text)
        for i = 1, #text do
            VirtualInputManager:SendTextInputCharacterEvent(text:sub(i, i), game)
            task.wait(0.05)
        end
    end
    
    -- Function to leave Roblox
    local function leaveRoblox()
        print("⏳ Waiting 5 seconds before closing Roblox...")
        task.wait(5)
        
        print("🚪 Closing Roblox completely...")
        ArrayField:Notify({
            Title = "Closing Roblox",
            Content = "Shutting down completely...",
            Duration = 3,
            Image = 4483362458
        })
        
        task.wait(1)
        
        pcall(function()
            game:Shutdown()
        end)
    end
    
    -- Dual Webhook function
    local function sendWebhook(fiendType, playerName)
        local webhook1Success = false
        local webhook2Success = false
        
        -- Color and emoji setup
        local color = 3066993
        local emoji = "👹"
        
        if fiendType == "Nail Fiend" then
            color = 15158332
            emoji = "🔨"
        elseif fiendType == "Shark Fiend" then
            color = 3447003
            emoji = "🦈"
        elseif fiendType == "Gun Fiend" then
            color = 10181046
            emoji = "🔫"
        elseif fiendType == "Blood Fiend" then
            color = 15548997
            emoji = "🩸"
        elseif fiendType == "Angel Fiend" then
            color = 16777215
            emoji = "👼"
        elseif fiendType == "Violence Fiend" then
            color = 16711680
            emoji = "💀"
        end
        
        local shouldPing = (fiendType == "Gun Fiend" or fiendType == "Angel Fiend") and discordID ~= ""
        local contentText = shouldPing and ("<@" .. discordID .. ">") or ""
        
        -- WEBHOOK 1: All fiends with full info
        if webhook1Enabled and webhookUrl1 ~= "" then
            local success1, err1 = pcall(function()
                local data = {
                    ["content"] = contentText,
                    ["embeds"] = {{
                        ["title"] = emoji .. " " .. fiendType .. " Found!",
                        ["description"] = "A Fiend has been detected!",
                        ["color"] = color,
                        ["fields"] = {
                            {
                                ["name"] = "👤 Player",
                                ["value"] = playerName,
                                ["inline"] = true
                            },
                            {
                                ["name"] = "👹 Fiend Type",
                                ["value"] = fiendType,
                                ["inline"] = true
                            },
                            {
                                ["name"] = "⏰ Time",
                                ["value"] = os.date("%Y-%m-%d %H:%M:%S"),
                                ["inline"] = false
                            }
                        },
                        ["footer"] = {
                            ["text"] = "Webhook 1 - Full Info | guns.lol/shopbss"
                        },
                        ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%S")
                    }}
                }
                
                local response = request({
                    Url = webhookUrl1,
                    Method = "POST",
                    Headers = {
                        ["Content-Type"] = "application/json"
                    },
                    Body = HttpService:JSONEncode(data)
                })
                
                if response.StatusCode == 204 then
                    print("✅ Webhook 1 sent successfully!")
                    webhook1Success = true
                else
                    print("⚠️ Webhook 1 failed: " .. response.StatusCode)
                end
            end)
            
            if not success1 then
                warn("❌ Webhook 1 error: " .. tostring(err1))
            end
        end
        
        -- WEBHOOK 2: Only Violence/Gun/Angel/Blood, no player name
        local webhook2Fiends = {
            ["Violence Fiend"] = true,
            ["Gun Fiend"] = true,
            ["Angel Fiend"] = true,
            ["Blood Fiend"] = true
        }
        
        if webhook2Enabled and webhookUrl2 ~= "" and webhook2Fiends[fiendType] then
            local success2, err2 = pcall(function()
                local data = {
                    ["content"] = contentText,
                    ["embeds"] = {{
                        ["title"] = emoji .. " " .. fiendType .. " Found!",
                        ["description"] = "A rare Fiend has been detected!",
                        ["color"] = color,
                        ["fields"] = {
                            {
                                ["name"] = "👹 Fiend Type",
                                ["value"] = fiendType,
                                ["inline"] = true
                            },
                            {
                                ["name"] = "⏰ Time",
                                ["value"] = os.date("%Y-%m-%d %H:%M:%S"),
                                ["inline"] = true
                            }
                        },
                        ["footer"] = {
                            ["text"] = "Webhook 2 - Rare Fiends Only | guns.lol/shopbss"
                        },
                        ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%S")
                    }}
                }
                
                local response = request({
                    Url = webhookUrl2,
                    Method = "POST",
                    Headers = {
                        ["Content-Type"] = "application/json"
                    },
                    Body = HttpService:JSONEncode(data)
                })
                
                if response.StatusCode == 204 then
                    print("✅ Webhook 2 sent successfully!")
                    webhook2Success = true
                else
                    print("⚠️ Webhook 2 failed: " .. response.StatusCode)
                end
            end)
            
            if not success2 then
                warn("❌ Webhook 2 error: " .. tostring(err2))
            end
        elseif webhook2Enabled and webhookUrl2 ~= "" then
            print("ℹ️ Webhook 2 skipped - " .. fiendType .. " is not in filter list")
        end
        
        -- Notify user
        local sentCount = 0
        if webhook1Success then sentCount = sentCount + 1 end
        if webhook2Success then sentCount = sentCount + 1 end
        
        if sentCount > 0 then
            ArrayField:Notify({
                Title = "Webhook Sent",
                Content = fiendType .. " detected! (" .. sentCount .. " webhooks)",
                Duration = 3,
                Image = 4483362458
            })
        end
        
        return webhook1Success or webhook2Success
    end
    
    -- Check for Fiend
    local function checkForFiend()
        print("⏳ Waiting 5 seconds before checking Fiend...")
        task.wait(5)
        
        local playerName = Players.LocalPlayer.Name
        local workspace = game:GetService("Workspace")
        
        print("🔍 Checking for Fiend in Workspace...")
        
        local success, result = pcall(function()
            local worldFolder = workspace:FindFirstChild("World")
            if not worldFolder then 
                print("❌ World folder not found")
                return nil 
            end
            print("✓ Found World folder")
            
            local entitiesFolder = worldFolder:FindFirstChild("Entities")
            if not entitiesFolder then 
                print("❌ Entities folder not found")
                return nil 
            end
            print("✓ Found Entities folder")
            
            local playerEntity = entitiesFolder:FindFirstChild(playerName)
            if not playerEntity then 
                print("❌ Player entity not found: " .. playerName)
                return nil 
            end
            print("✓ Found player entity: " .. playerName)
            
            local hasNailFiend = false
            local hasSharkFiend = false
            local hasGunFiend = false
            local hasBloodFiend = false
            local hasAngelFiend = false
            local hasViolenceFiend = false
            
            print("📋 Scanning for Fiend parts...")
            
            local function searchDescendants(parent)
                for _, child in pairs(parent:GetDescendants()) do
                    local childName = child.Name
                    
                    if string.find(childName, "NailFiend_Brain") then
                        print("🔨 FOUND: NailFiend_Brain")
                        hasNailFiend = true
                    end
                    
                    if string.find(childName, "LargeSharkHead") then
                        print("🦈 FOUND: LargeSharkHead")
                        hasSharkFiend = true
                    end
                    
                    if string.find(childName, "GunArm") or string.find(childName, "gun_head") or string.find(childName, "gunhead") then
                        print("🔫 FOUND: Gun part (" .. childName .. ")")
                        hasGunFiend = true
                    end
                    
                    if string.find(childName, "Stage 2 Horn") or string.find(childName, "Stage 3 Horn") or string.find(childName, "Stage2Horn") or string.find(childName, "Stage3Horn") then
                        print("🩸 FOUND: Blood Fiend horn (" .. childName .. ")")
                        hasBloodFiend = true
                    end
                    
                    if string.find(childName, "Wings") or string.find(childName, "Wing") then
                        print("👼 FOUND: Angel Fiend wings (" .. childName .. ")")
                        hasAngelFiend = true
                    end
                    
                    if string.find(childName, "ViolenceFiend") or string.find(childName, "Violence") then
                        print("💀 FOUND: Violence Fiend part (" .. childName .. ")")
                        hasViolenceFiend = true
                    end
                end
            end
            
            searchDescendants(playerEntity)
            
            if hasViolenceFiend then
                return "Violence Fiend"
            elseif hasNailFiend then
                return "Nail Fiend"
            elseif hasSharkFiend then
                return "Shark Fiend"
            elseif hasGunFiend then
                return "Gun Fiend"
            elseif hasBloodFiend then
                return "Blood Fiend"
            elseif hasAngelFiend then
                return "Angel Fiend"
            else
                return nil
            end
        end)
        
        if success and result then
            print("✅ Fiend detected: " .. result)
            lastFiendFound = result
            
            print("📤 Sending webhook notifications...")
            webhookSent = sendWebhook(result, playerName)
            
            if webhookSent then
                print("✅ Webhook(s) sent successfully!")
                print("⏳ Waiting 3 seconds to ensure webhooks are delivered...")
                task.wait(3)
                print("🎯 Now preparing to leave...")
                leaveRoblox()
            else
                print("⚠️ All webhooks failed, but Fiend was detected")
                ArrayField:Notify({
                    Title = "Webhook Failed",
                    Content = "Fiend found but webhooks failed",
                    Duration = 5,
                    Image = 4483362458
                })
            end
            
            return result
        else
            if not success then
                print("❌ Error while checking: " .. tostring(result))
            end
            print("❌ No Fiend found")
            return nil
        end
    end
    
    local function validateMove()
        return true
    end
    
    -- Main Auto Sequence
    local function runFullSequence()
        local randomName = getName()
        
        currentStep = "Step 1: BackSlash (ON)"
        print("→ " .. currentStep)
        pressKey(Enum.KeyCode.BackSlash)
        task.wait(0.5)
        if not _G.NQN_Running or not autoRunning or not validateMove() then return false end
        
        currentStep = "Step 2: Enter"
        print("→ " .. currentStep)
        pressKey(Enum.KeyCode.Return)
        task.wait(0.5)
        if not _G.NQN_Running or not autoRunning or not validateMove() then return false end
        
        currentStep = "Step 3: BackSlash (OFF)"
        print("→ " .. currentStep)
        pressKey(Enum.KeyCode.BackSlash)
        task.wait(0.5)
        if not _G.NQN_Running or not autoRunning or not validateMove() then return false end
        
        currentStep = "Step 4: BackSlash (ON again)"
        print("→ " .. currentStep)
        pressKey(Enum.KeyCode.BackSlash)
        task.wait(0.5)
        if not _G.NQN_Running or not autoRunning or not validateMove() then return false end
        
        currentStep = "Step 5: Enter"
        print("→ " .. currentStep)
        pressKey(Enum.KeyCode.Return)
        task.wait(0.5)
        if not _G.NQN_Running or not autoRunning or not validateMove() then return false end
        
        currentStep = "Step 6: Down"
        print("→ " .. currentStep)
        pressKey(Enum.KeyCode.Down)
        task.wait(0.5)
        if not _G.NQN_Running or not autoRunning or not validateMove() then return false end
        
        currentStep = "Step 7: Enter"
        print("→ " .. currentStep)
        pressKey(Enum.KeyCode.Return)
        task.wait(0.5)
        if not _G.NQN_Running or not autoRunning or not validateMove() then return false end
        
        currentStep = "Step 8: Type Name (" .. randomName .. ")"
        print("→ " .. currentStep)
        typeText(randomName)
        task.wait(0.5)
        if not _G.NQN_Running or not autoRunning or not validateMove() then return false end
        
        currentStep = "Step 9: Enter"
        print("→ " .. currentStep)
        pressKey(Enum.KeyCode.Return)
        task.wait(0.5)
        if not _G.NQN_Running or not autoRunning or not validateMove() then return false end
        
        currentStep = "Step 10: Down"
        print("→ " .. currentStep)
        pressKey(Enum.KeyCode.Down)
        task.wait(0.5)
        if not _G.NQN_Running or not autoRunning or not validateMove() then return false end
        
        currentStep = "Step 11: Left"
        print("→ " .. currentStep)
        pressKey(Enum.KeyCode.Left)
        task.wait(0.5)
        if not _G.NQN_Running or not autoRunning or not validateMove() then return false end
        
        currentStep = "Step 12: Enter"
        print("→ " .. currentStep)
        pressKey(Enum.KeyCode.Return)
        task.wait(0.5)
        if not _G.NQN_Running or not autoRunning or not validateMove() then return false end
        
        currentStep = "Step 13: Down"
        print("→ " .. currentStep)
        pressKey(Enum.KeyCode.Down)
        task.wait(0.5)
        if not _G.NQN_Running or not autoRunning or not validateMove() then return false end
        
        currentStep = "Step 14: Down"
        print("→ " .. currentStep)
        pressKey(Enum.KeyCode.Down)
        task.wait(0.5)
        if not _G.NQN_Running or not autoRunning or not validateMove() then return false end
        
        currentStep = "Step 15: Enter (Final)"
        print("→ " .. currentStep)
        pressKey(Enum.KeyCode.Return)
        task.wait(0.5)
        
        if not _G.NQN_Running or not autoRunning then return false end
        
        currentStep = "Checking for Fiend..."
        print("→ " .. currentStep)
        checkForFiend()
        
        return true
    end
    
    -- Main Auto Function
    local function runAutoSequence()
        if not _G.NQN_Running or not autoRunning then return end
        
        task.wait(3)
        
        if not _G.NQN_Running or not autoRunning then return end
        
        local success = pcall(function()
            local completed = runFullSequence()
            
            if not _G.NQN_Running or not autoRunning then return end
            
            if completed then
                print("✅ Sequence completed successfully!")
                retryCount = 0
                autoRunning = false
                ArrayField:Notify({
                    Title = "Complete!",
                    Content = "Sequence finished.",
                    Duration = 3,
                    Image = 4483362458
                })
            else
                retryCount = retryCount + 1
                print("⚠️ Invalid move detected! Restarting... (Retry: " .. retryCount .. ")")
                ArrayField:Notify({
                    Title = "Error Detected",
                    Content = "Restarting (Retry: " .. retryCount .. ")",
                    Duration = 2,
                    Image = 4483362458
                })
                task.wait(1)
                if _G.NQN_Running and autoRunning then
                    runAutoSequence()
                end
            end
        end)
        
        if not success then
            if not _G.NQN_Running or not autoRunning then return end
            
            retryCount = retryCount + 1
            print("❌ Error occurred! Restarting... (Retry: " .. retryCount .. ")")
            task.wait(1)
            if _G.NQN_Running and autoRunning then
                runAutoSequence()
            end
        end
    end
    
    -- ===== UI =====
    
    MainTab:CreateSection("Main")
    
    MainTab:CreateToggle({
        Name = "Auto Reg",
        CurrentValue = autoRunning,
        Flag = "AutoToggle",
        Callback = function(Value)
            autoRunning = Value
            saveConfig()
            if Value then
                retryCount = 0
                webhookSent = false
                ArrayField:Notify({
                    Title = "Starting",
                    Content = "Running sequence...",
                    Duration = 3,
                    Image = 4483362458
                })
                task.spawn(runAutoSequence)
            else
                currentStep = "Idle"
                ArrayField:Notify({
                    Title = "Stopped",
                    Content = "Sequence cancelled",
                    Duration = 2,
                    Image = 4483362458
                })
            end
        end
    })
    
    if autoRunning then
        task.spawn(function()
            task.wait(0.5)
            retryCount = 0
            webhookSent = false
            runAutoSequence()
        end)
    end
    
    MainTab:CreateSection("Name Settings")
    
    MainTab:CreateToggle({
        Name = "Use Custom Name",
        CurrentValue = useCustomName,
        Flag = "UseCustomName",
        Callback = function(Value)
            useCustomName = Value
            saveConfig()
            local modeText = Value and "Custom Name: " .. (customName ~= "" and customName or "Not set") or "Random Name"
            print("Name mode: " .. modeText)
            ArrayField:Notify({
                Title = Value and "Custom Name ON" or "Random Name ON",
                Content = modeText,
                Duration = 2,
                Image = 4483362458
            })
        end
    })
    
    MainTab:CreateInput({
        Name = "Custom Name (Max 10 chars)",
        PlaceholderText = "Enter name...",
        RemoveTextAfterFocusLost = false,
        Flag = "CustomName",
        CurrentValue = customName,
        Callback = function(Text)
            customName = Text:sub(1, 10)
            saveConfig()
            print("Custom name: " .. customName)
            ArrayField:Notify({
                Title = "Name Saved",
                Content = "Custom name: " .. (customName ~= "" and customName or "Empty"),
                Duration = 2,
                Image = 4483362458
            })
        end
    })
    
    MainTab:CreateSection("Actions")
    
    MainTab:CreateButton({
        Name = "Check Fiend Now",
        Callback = function()
            task.spawn(function()
                local fiend = checkForFiend()
                if fiend then
                    ArrayField:Notify({
                        Title = "Fiend Found!",
                        Content = fiend,
                        Duration = 3,
                        Image = 4483362458
                    })
                else
                    ArrayField:Notify({
                        Title = "No Fiend",
                        Content = "No Fiend detected",
                        Duration = 2,
                        Image = 4483362458
                    })
                end
            end)
        end
    })
    
    MainTab:CreateSection("Webhook Settings")
    
    -- Webhook 1
    MainTab:CreateToggle({
        Name = "Enable Webhook 1 (All Fiends)",
        CurrentValue = webhook1Enabled,
        Flag = "Webhook1Enabled",
        Callback = function(Value)
            webhook1Enabled = Value
            saveConfig()
            ArrayField:Notify({
                Title = webhook1Enabled and "Webhook 1 ON" or "Webhook 1 OFF",
                Content = "All fiends with full info",
                Duration = 2,
                Image = 4483362458
            })
        end
    })
    
    MainTab:CreateInput({
        Name = "Webhook 1 URL",
        PlaceholderText = "https://discord.com/api/webhooks/...",
        RemoveTextAfterFocusLost = false,
        Flag = "Webhook1URL",
        CurrentValue = webhookUrl1,
        Callback = function(Text)
            webhookUrl1 = Text
            saveConfig()
            ArrayField:Notify({
                Title = "Webhook 1 Saved",
                Content = "URL updated",
                Duration = 2,
                Image = 4483362458
            })
        end
    })
    
    -- Webhook 2
    MainTab:CreateToggle({
        Name = "Enable Webhook 2 (Rare Only)",
        CurrentValue = webhook2Enabled,
        Flag = "Webhook2Enabled",
        Callback = function(Value)
            webhook2Enabled = Value
            saveConfig()
            ArrayField:Notify({
                Title = webhook2Enabled and "Webhook 2 ON" or "Webhook 2 OFF",
                Content = "Violence/Gun/Angel/Blood only",
                Duration = 2,
                Image = 4483362458
            })
        end
    })
    
    MainTab:CreateInput({
        Name = "Webhook 2 URL",
        PlaceholderText = "https://discord.com/api/webhooks/...",
        RemoveTextAfterFocusLost = false,
        Flag = "Webhook2URL",
        CurrentValue = webhookUrl2,
        Callback = function(Text)
            webhookUrl2 = Text
            saveConfig()
            ArrayField:Notify({
                Title = "Webhook 2 Saved",
                Content = "URL updated",
                Duration = 2,
                Image = 4483362458
            })
        end
    })
    
    MainTab:CreateInput({
        Name = "Discord ID (Ping for Gun/Angel)",
        PlaceholderText = "Your Discord ID...",
        RemoveTextAfterFocusLost = false,
        Flag = "DiscordID",
        CurrentValue = discordID,
        Callback = function(Text)
            discordID = Text
            saveConfig()
            ArrayField:Notify({
                Title = "Discord ID Saved",
                Content = "Will ping for Gun/Angel Fiend",
                Duration = 2,
                Image = 4483362458
            })
        end
    })
    
    MainTab:CreateButton({
        Name = "Test Webhooks",
        Callback = function()
            local currentTime = tick()
            
            if currentTime - lastWebhookTest < 5 then
                local remaining = math.ceil(5 - (currentTime - lastWebhookTest))
                ArrayField:Notify({
                    Title = "Cooldown",
                    Content = "Wait " .. remaining .. "s before testing again",
                    Duration = 2,
                    Image = 4483362458
                })
                return
            end
            
            if webhookUrl1 == "" and webhookUrl2 == "" then
                ArrayField:Notify({
                    Title = "No URLs",
                    Content = "Set at least one webhook URL first",
                    Duration = 3,
                    Image = 4483362458
                })
                return
            end
            
            lastWebhookTest = currentTime
            
            ArrayField:Notify({
                Title = "Testing",
                Content = "Sending test webhooks...",
                Duration = 2,
                Image = 4483362458
            })
            
            local temp1 = webhook1Enabled
            local temp2 = webhook2Enabled
            webhook1Enabled = webhookUrl1 ~= ""
            webhook2Enabled = webhookUrl2 ~= ""
            sendWebhook("Gun Fiend", Players.LocalPlayer.Name)
            webhook1Enabled = temp1
            webhook2Enabled = temp2
        end
    })
    
    ArrayField:LoadConfiguration()
    print("✅ Game UI loaded!")

else
    warn("⚠️ Unknown PlaceId: " .. currentPlaceId)
end

end)

if not success then
    warn("❌ Script Error: " .. tostring(err))
end

print("✅ Script execution completed!")
