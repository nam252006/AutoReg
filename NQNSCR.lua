-- Load ArrayField Library
local ArrayField = loadstring(game:HttpGet("https://raw.githubusercontent.com/UI-Interface/ArrayField/main/Source.lua",true))()

-- Destroy old UI if exists
if _G.NQN_Window then
    pcall(function()
        _G.NQN_Window:Destroy()
    end)
end
if _G.NQN_Running then
    _G.NQN_Running = false
end

-- Get PlaceId
local currentPlaceId = game.PlaceId

-- PlaceIds
local MENU_PLACEID = 131079272918660
local GAME_PLACEID = 136364146980997

local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")

-- Wait for player
Players.LocalPlayer:WaitForChild("PlayerGui")
wait(2)

if currentPlaceId == MENU_PLACEID then
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
        wait(2)
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
                runAuto()
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
    
    spawn(function()
        while wait(0.5) do
            pcall(function()
                Label:Set("Slot: " .. selectedSlot)
                StatusLabel:Set("Status: " .. (autoRunning and "Running" or "Idle"))
            end)
        end
    end)
    
    ArrayField:LoadConfiguration()

elseif currentPlaceId == GAME_PLACEID then
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
    local webhookUrl = ""
    local webhookEnabled = false
    local lastFiendFound = ""
    local webhookSent = false
    local lastWebhookTest = 0
    
    -- Load saved config
    pcall(function()
        if isfile("NQNSCR_Game.txt") then
            local configData = readfile("NQNSCR_Game.txt")
            local config = HttpService:JSONDecode(configData)
            webhookUrl = config.webhookUrl or ""
            webhookEnabled = config.webhookEnabled or false
            autoRunning = config.autoRunning or false
        end
    end)
    
    -- Auto-save function
    local function saveConfig()
        pcall(function()
            local config = {
                webhookUrl = webhookUrl,
                webhookEnabled = webhookEnabled,
                autoRunning = autoRunning
            }
            writefile("NQNSCR_Game.txt", HttpService:JSONEncode(config))
        end)
    end
    
    -- Helper Functions
    local function generateRandomName()
        local chars = "abcdefghijklmnopqrstuvwxyz0123456789"
        local name = ""
        for i = 1, math.random(6, 10) do
            local rand = math.random(1, #chars)
            name = name .. chars:sub(rand, rand)
        end
        return name
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
        print("⏳ Waiting 5 seconds before leaving...")
        task.wait(5)
        
        print("🚪 Leaving Roblox...")
        print("→ Pressing ESC")
        pressKey(Enum.KeyCode.Escape)
        task.wait(0.5)
        
        print("→ Pressing L")
        pressKey(Enum.KeyCode.L)
        task.wait(0.5)
        
        print("→ Pressing Enter (1st)")
        pressKey(Enum.KeyCode.Return)
        task.wait(0.3)
        
        print("→ Pressing Enter (2nd - confirm)")
        pressKey(Enum.KeyCode.Return)
        task.wait(0.5)
        
        print("✅ Leave sequence completed!")
        ArrayField:Notify({
            Title = "Leaving Game",
            Content = "Disconnecting from Roblox...",
            Duration = 3,
            Image = 4483362458
        })
    end
    
    -- Webhook function
    local function sendWebhook(fiendType, playerName)
        if not webhookEnabled then
            print("⚠️ Webhook is disabled")
            return false
        end
        
        if webhookUrl == "" then
            print("⚠️ Webhook URL not set!")
            return false
        end
        
        local success, err = pcall(function()
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
            end
            
            local data = {
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
                        ["text"] = "Ngô Quang Nam - guns.lol/shopbss"
                    },
                    ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%S")
                }}
            }
            
            local response = request({
                Url = webhookUrl,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode(data)
            })
            
            if response.StatusCode == 204 then
                print("✅ Webhook sent successfully!")
                ArrayField:Notify({
                    Title = "Webhook Sent",
                    Content = fiendType .. " detected!",
                    Duration = 3,
                    Image = 4483362458
                })
                return true
            else
                print("⚠️ Webhook failed: " .. response.StatusCode)
                return false
            end
        end)
        
        if not success then
            warn("❌ Webhook error: " .. tostring(err))
            return false
        end
        
        return success
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
                end
            end
            
            searchDescendants(playerEntity)
            
            if hasNailFiend then
                return "Nail Fiend"
            elseif hasSharkFiend then
                return "Shark Fiend"
            elseif hasGunFiend then
                return "Gun Fiend"
            else
                return nil
            end
        end)
        
        if success and result then
            print("✅ Fiend detected: " .. result)
            lastFiendFound = result
            
            webhookSent = sendWebhook(result, playerName)
            
            if webhookSent then
                print("🎯 Webhook sent successfully, preparing to leave...")
                leaveRoblox()
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
        local randomName = generateRandomName()
        
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
        if not _G.NQN_Running or not autoRunning then return end  -- Check if still running
        
        task.wait(3)
        
        if not _G.NQN_Running or not autoRunning then return end  -- Check again after wait
        
        local success = pcall(function()
            local completed = runFullSequence()
            
            if not _G.NQN_Running or not autoRunning then return end  -- Check if stopped during sequence
            
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
            if not _G.NQN_Running or not autoRunning then return end  -- Don't restart if manually stopped
            
            retryCount = retryCount + 1
            print("❌ Error occurred! Restarting... (Retry: " .. retryCount .. ")")
            task.wait(1)
            if _G.NQN_Running and autoRunning then
                runAutoSequence()
            end
        end
    end
    
    -- ===== UI =====
    
    -- MAIN SECTION
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
    
    -- Auto-start if was enabled
    if autoRunning then
        task.spawn(function()
            task.wait(0.5)
            retryCount = 0
            webhookSent = false
            runAutoSequence()
        end)
    end
    
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
    
    -- WEBHOOK SECTION
    MainTab:CreateSection("Webhook Settings")
    
    MainTab:CreateToggle({
        Name = "Enable Webhook",
        CurrentValue = webhookEnabled,
        Flag = "WebhookEnabled",
        Callback = function(Value)
            webhookEnabled = Value
            saveConfig()
            print("Webhook " .. (Value and "enabled" or "disabled"))
            ArrayField:Notify({
                Title = webhookEnabled and "Webhook ON" or "Webhook OFF",
                Content = webhookEnabled and "Will send to Discord" or "Notifications disabled",
                Duration = 2,
                Image = 4483362458
            })
        end
    })
    
    MainTab:CreateInput({
        Name = "Webhook URL",
        PlaceholderText = "https://discord.com/api/webhooks/...",
        RemoveTextAfterFocusLost = false,
        Flag = "WebhookURL",
        CurrentValue = webhookUrl,
        Callback = function(Text)
            webhookUrl = Text
            saveConfig()
            print("Webhook URL: " .. Text)
            ArrayField:Notify({
                Title = "URL Saved",
                Content = "Webhook URL updated",
                Duration = 2,
                Image = 4483362458
            })
        end
    })
    
    MainTab:CreateButton({
        Name = "Test Webhook",
        Callback = function()
            local currentTime = tick()
            
            -- Cooldown check
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
            
            if webhookUrl == "" then
                ArrayField:Notify({
                    Title = "No URL",
                    Content = "Set webhook URL first",
                    Duration = 3,
                    Image = 4483362458
                })
                return
            end
            
            lastWebhookTest = currentTime
            
            ArrayField:Notify({
                Title = "Testing",
                Content = "Sending test webhook...",
                Duration = 2,
                Image = 4483362458
            })
            
            -- Send test webhook regardless of toggle
            local tempEnabled = webhookEnabled
            webhookEnabled = true
            sendWebhook("Nail Fiend", Players.LocalPlayer.Name)
            webhookEnabled = tempEnabled
        end
    })
    
    ArrayField:LoadConfiguration()

else
    warn("Unknown PlaceId: " .. currentPlaceId)
end
