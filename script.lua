-- Hunter.lua
-- Simple UI using Rayfield Library for Hunters Game

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Load Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Player reference
local player = Players.LocalPlayer
local playerName = player.Name
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Create Window
local Window = Rayfield:CreateWindow({
    Name = "KaihonHub",
    LoadingTitle = "KaihonHub",
    LoadingSubtitle = "by DuongTuan",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "KaihonConfig",
        FileName = playerName .. "_Config"
    },
    KeySystem = false
})

-- Create Main Tab
local MainTab = Window:CreateTab("Main", 4483362458) -- Home icon

-- Create Map Tab
local MapTab = Window:CreateTab("Map", 9288394834) -- Map icon

-- Create Play Tab
local PlayTab = Window:CreateTab("Play", 4483362927) -- Play icon

-- Main Section
local MainSection = MainTab:CreateSection("Roll Settings")

-- Auto Roll Toggle
local rollConnection = nil
local AutoRollToggle = MainTab:CreateToggle({
    Name = "Auto Roll",
    CurrentValue = false,
    Flag = "AutoRoll",
    Callback = function(Value)
        if Value then
            -- Start auto roll
            if rollConnection then rollConnection:Disconnect() end
            
            rollConnection = game:GetService("RunService").Heartbeat:Connect(function()
                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Roll"):InvokeServer()
                wait(1) -- đợi 1 giây để tránh spam quá nhanh, có thể điều chỉnh
            end)
            
            Rayfield:Notify({
                Title = "Auto Roll Enabled",
                Content = "Now automatically rolling...",
                Duration = 3,
                Image = "dice", -- Lucide icon
            })
        else
            -- Stop auto roll
            if rollConnection then 
                rollConnection:Disconnect()
                rollConnection = nil
                
                Rayfield:Notify({
                    Title = "Auto Roll Disabled",
                    Content = "Auto roll has been stopped",
                    Duration = 3,
                    Image = "square", -- Lucide icon
                })
            end
        end
    end,
})

-- Roll Delay Slider
local RollDelaySlider = MainTab:CreateSlider({
    Name = "Roll Delay (seconds)",
    Range = {0.1, 5},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = 1,
    Flag = "RollDelay",
    Callback = function(Value)
        -- The delay will be applied on the next toggle enable
        Rayfield:Notify({
            Title = "Roll Delay Updated",
            Content = "New delay: " .. Value .. " seconds",
            Duration = 2,
            Image = "timer", -- Lucide icon
        })
    end,
})

-- Manual Roll Button
local RollButton = MainTab:CreateButton({
    Name = "Manual Roll",
    Callback = function()
        game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Roll"):InvokeServer()
        
        Rayfield:Notify({
            Title = "Manual Roll",
            Content = "Roll executed!",
            Duration = 2,
            Image = "dice", -- Lucide icon
        })
    end,
})

-- Attack Section
local AttackSection = MainTab:CreateSection("Attack Settings")

-- Auto Attack Toggle
local attackConnection = nil
local AutoAttackToggle = MainTab:CreateToggle({
    Name = "Auto Attack",
    CurrentValue = false,
    Flag = "AutoAttack",
    Callback = function(Value)
        if Value then
            -- Start auto attack
            if attackConnection then attackConnection:Disconnect() end
            
            attackConnection = game:GetService("RunService").Heartbeat:Connect(function()
                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Combat"):FireServer()
                wait(1) -- đợi 1 giây để tránh spam quá nhanh, có thể điều chỉnh
            end)
            
            Rayfield:Notify({
                Title = "Auto Attack Enabled",
                Content = "Now automatically attacking...",
                Duration = 3,
                Image = "swords", -- Lucide icon
            })
        else
            -- Stop auto attack
            if attackConnection then 
                attackConnection:Disconnect()
                attackConnection = nil
                
                Rayfield:Notify({
                    Title = "Auto Attack Disabled",
                    Content = "Auto attack has been stopped",
                    Duration = 3,
                    Image = "square", -- Lucide icon
                })
            end
        end
    end,
})

-- Attack Delay Slider
local AttackDelaySlider = MainTab:CreateSlider({
    Name = "Attack Delay (seconds)",
    Range = {0.1, 5},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = 1,
    Flag = "AttackDelay",
    Callback = function(Value)
        -- The delay will be applied on the next toggle enable
        Rayfield:Notify({
            Title = "Attack Delay Updated",
            Content = "New delay: " .. Value .. " seconds",
            Duration = 2,
            Image = "timer", -- Lucide icon
        })
    end,
})

-- Manual Attack Button
local AttackButton = MainTab:CreateButton({
    Name = "Manual Attack",
    Callback = function()
        game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Combat"):FireServer()
        
        Rayfield:Notify({
            Title = "Manual Attack",
            Content = "Attack executed!",
            Duration = 2,
            Image = "swords", -- Lucide icon
        })
    end,
})

-- Status Section
local StatusSection = MainTab:CreateSection("Status")

-- Create Stats Label
local statusLabel = MainTab:CreateLabel("Player: " .. playerName)
local rollsLabel = MainTab:CreateLabel("Rolls: 0")
local attacksLabel = MainTab:CreateLabel("Attacks: 0")

-- Roll counter
local rollCount = 0

-- Function to update roll count
local function updateRollCount()
    rollCount = rollCount + 1
    rollsLabel:Set("Rolls: " .. rollCount)
end

-- Attack counter
local attackCount = 0

-- Function to update attack count
local function updateAttackCount()
    attackCount = attackCount + 1
    attacksLabel:Set("Attacks: " .. attackCount)
end

-- Hook the update roll count to both manual and auto roll
local oldRollCallback = RollButton.Callback
RollButton.Callback = function()
    oldRollCallback()
    updateRollCount()
end

-- Hook the update attack count to manual attack
local oldAttackCallback = AttackButton.Callback
AttackButton.Callback = function()
    oldAttackCallback()
    updateAttackCount()
end

-- Map Tab Content
local MapSelectionSection = MapTab:CreateSection("Map Selection")

-- Map selection variable
local selectedMap = nil
local mapCodes = {
    ["SINGULARITY"] = "DoubleDungeonD",
    ["GOBLIN CAVES"] = "GoblinCave",
    ["SPIDER CAVERN"] = "SpiderCavern"
}

-- Map Dropdown
local MapDropdown = MapTab:CreateDropdown({
    Name = "Chọn Map",
    Options = {"SINGULARITY", "GOBLIN CAVES", "SPIDER CAVERN"},
    CurrentOption = {}, -- No default selection
    MultipleOptions = false,
    Flag = "SelectedMap",
    Callback = function(Option)
        selectedMap = Option[1]
        Rayfield:Notify({
            Title = "Map Selected",
            Content = "You selected: " .. selectedMap,
            Duration = 2,
            Image = "map", -- Lucide icon
        })
    end,
})

-- Current Map Label
local CurrentMapLabel = MapTab:CreateLabel("Selected Map: None")

-- Update map label when selection changes
local oldMapCallback = MapDropdown.Callback
MapDropdown.Callback = function(Option)
    oldMapCallback(Option)
    CurrentMapLabel:Set("Selected Map: " .. Option[1])
end

-- Map Control Section
local MapControlSection = MapTab:CreateSection("Map Controls")

-- Start button (toggle)
local startConnection = nil
local StartToggle = MapTab:CreateToggle({
    Name = "Start Map",
    CurrentValue = false,
    Flag = "StartMap",
    Callback = function(Value)
        if Value then
            if selectedMap == nil then
                Rayfield:Notify({
                    Title = "Error",
                    Content = "Please select a map first!",
                    Duration = 3,
                    Image = "alert-triangle", -- Lucide icon
                })
                StartToggle:Set(false)
                return
            end
            
            -- Create the lobby with selected map
            local mapCode = mapCodes[selectedMap]
            local args = {
                [1] = mapCode
            }
            
            -- Create lobby
            game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("createLobby"):InvokeServer(unpack(args))
            
            -- Start the lobby
            game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("LobbyStart"):FireServer()
            
            Rayfield:Notify({
                Title = "Map Started",
                Content = "Starting " .. selectedMap .. "...",
                Duration = 3,
                Image = "play", -- Lucide icon
            })
            
            -- Auto reset the toggle after starting
            wait(1)
            StartToggle:Set(false)
        end
    end,
})

-- Manual Create Lobby Button
local CreateLobbyButton = MapTab:CreateButton({
    Name = "Create Lobby Only",
    Callback = function()
        if selectedMap == nil then
            Rayfield:Notify({
                Title = "Error",
                Content = "Please select a map first!",
                Duration = 3,
                Image = "alert-triangle", -- Lucide icon
            })
            return
        end
        
        -- Create the lobby with selected map
        local mapCode = mapCodes[selectedMap]
        local args = {
            [1] = mapCode
        }
        
        -- Create lobby
        game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("createLobby"):InvokeServer(unpack(args))
        
        Rayfield:Notify({
            Title = "Lobby Created",
            Content = "Created lobby for " .. selectedMap,
            Duration = 3,
            Image = "users", -- Lucide icon
        })
    end,
})

-- Manual Start Button
local StartLobbyButton = MapTab:CreateButton({
    Name = "Start Lobby Only",
    Callback = function()
        -- Start the lobby
        game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("LobbyStart"):FireServer()
        
        Rayfield:Notify({
            Title = "Lobby Started",
            Content = "Starting lobby...",
            Duration = 3,
            Image = "play", -- Lucide icon
        })
    end,
})

-- Play Tab Content
local FarmSection = PlayTab:CreateSection("Auto Farm")

-- Available mobs
local mobList = {"All Mobs", "Golem Mage"}
local selectedMob = "All Mobs"

-- Mob selection dropdown
local MobDropdown = PlayTab:CreateDropdown({
    Name = "Select Target",
    Options = mobList,
    CurrentOption = {"All Mobs"},
    MultipleOptions = false,
    Flag = "SelectedMob",
    Callback = function(Option)
        selectedMob = Option[1]
        Rayfield:Notify({
            Title = "Target Selected",
            Content = "Now targeting: " .. selectedMob,
            Duration = 2,
            Image = "target", -- Lucide icon
        })
    end,
})

-- Teleport distance slider
local TeleportDistanceSlider = PlayTab:CreateSlider({
    Name = "Teleport Distance",
    Range = {0, 10},
    Increment = 0.5,
    Suffix = "studs",
    CurrentValue = 5,
    Flag = "TeleportDistance",
    Callback = function(Value)
        Rayfield:Notify({
            Title = "Distance Updated",
            Content = "New teleport distance: " .. Value .. " studs",
            Duration = 2,
            Image = "ruler", -- Lucide icon
        })
    end,
})

-- Farm toggle
local farmConnection = nil
local AutoFarmToggle = PlayTab:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = false,
    Flag = "AutoFarm",
    Callback = function(Value)
        -- Get the character and humanoid root part
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        
        if Value then
            -- Start auto farm
            if farmConnection then farmConnection:Disconnect() end
            
            farmConnection = game:GetService("RunService").Heartbeat:Connect(function()
                -- Find mobs
                local mobsFolder = workspace:FindFirstChild("Mobs")
                if not mobsFolder then
                    Rayfield:Notify({
                        Title = "Error",
                        Content = "Mobs folder not found!",
                        Duration = 3,
                        Image = "alert-triangle", -- Lucide icon
                    })
                    AutoFarmToggle:Set(false)
                    return
                end
                
                local targetMob = nil
                
                -- Choose target based on selection
                if selectedMob == "All Mobs" then
                    -- Find the closest mob
                    local closestDistance = math.huge
                    for _, mob in pairs(mobsFolder:GetChildren()) do
                        if mob:FindFirstChild("HumanoidRootPart") then
                            local distance = (mob.HumanoidRootPart.Position - humanoidRootPart.Position).Magnitude
                            if distance < closestDistance then
                                closestDistance = distance
                                targetMob = mob
                            end
                        end
                    end
                else
                    -- Find the selected mob type
                    if mobsFolder:FindFirstChild(selectedMob) and mobsFolder[selectedMob]:FindFirstChild("HumanoidRootPart") then
                        targetMob = mobsFolder[selectedMob]
                    end
                end
                
                -- Teleport to mob if found
                if targetMob and targetMob:FindFirstChild("HumanoidRootPart") then
                    local teleportDistance = TeleportDistanceSlider.CurrentValue
                    local mobPosition = targetMob.HumanoidRootPart.Position
                    local direction = (humanoidRootPart.Position - mobPosition).Unit
                    local targetPosition = mobPosition + (direction * teleportDistance)
                    
                    -- Teleport to the mob with offset
                    humanoidRootPart.CFrame = CFrame.new(targetPosition, mobPosition)
                    
                    -- Auto attack if enabled
                    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Combat"):FireServer()
                    wait(0.5) -- Small delay to prevent overwhelming the server
                end
            end)
            
            Rayfield:Notify({
                Title = "Auto Farm Enabled",
                Content = "Now farming: " .. selectedMob,
                Duration = 3,
                Image = "target", -- Lucide icon
            })
        else
            -- Stop auto farm
            if farmConnection then 
                farmConnection:Disconnect()
                farmConnection = nil
                
                Rayfield:Notify({
                    Title = "Auto Farm Disabled",
                    Content = "Auto farming has been stopped",
                    Duration = 3,
                    Image = "square", -- Lucide icon
                })
            end
        end
    end,
})

-- Stats section for farming
local FarmStatsSection = PlayTab:CreateSection("Farm Stats")
local mobsKilledLabel = PlayTab:CreateLabel("Mobs Killed: 0")
local farmTimeLabel = PlayTab:CreateLabel("Farm Time: 0m 0s")

-- Farm stats counters
local mobsKilled = 0
local farmStartTime = 0
local farmTimeUpdateConnection = nil

-- Update farm time
local function updateFarmTime()
    if farmStartTime > 0 then
        local elapsedTime = os.time() - farmStartTime
        local minutes = math.floor(elapsedTime / 60)
        local seconds = elapsedTime % 60
        farmTimeLabel:Set("Farm Time: " .. minutes .. "m " .. seconds .. "s")
    end
end

-- Update farm stats when toggling
local oldFarmCallback = AutoFarmToggle.Callback
AutoFarmToggle.Callback = function(Value)
    oldFarmCallback(Value)
    
    if Value then
        -- Reset and start farm timer
        farmStartTime = os.time()
        
        if farmTimeUpdateConnection then
            farmTimeUpdateConnection:Disconnect()
        end
        
        farmTimeUpdateConnection = game:GetService("RunService").Heartbeat:Connect(function()
            updateFarmTime()
            wait(1) -- Update every second
        end)
    else
        -- Stop farm timer
        if farmTimeUpdateConnection then
            farmTimeUpdateConnection:Disconnect()
            farmTimeUpdateConnection = nil
        end
    end
end

-- Function to update mob kill count
local function updateMobKillCount()
    mobsKilled = mobsKilled + 1
    mobsKilledLabel:Set("Mobs Killed: " .. mobsKilled)
end

-- Reset Stats Button
local ResetStatsButton = PlayTab:CreateButton({
    Name = "Reset Farm Stats",
    Callback = function()
        mobsKilled = 0
        farmStartTime = AutoFarmToggle.CurrentValue and os.time() or 0
        mobsKilledLabel:Set("Mobs Killed: 0")
        updateFarmTime()
        
        Rayfield:Notify({
            Title = "Stats Reset",
            Content = "Farm statistics have been reset",
            Duration = 2,
            Image = "refresh-cw", -- Lucide icon
        })
    end,
})

-- Add auto farm mob kill counter
local function hookMobDeath()
    local mobsFolder = workspace:FindFirstChild("Mobs")
    if mobsFolder then
        mobsFolder.ChildRemoved:Connect(function(child)
            if AutoFarmToggle.CurrentValue then
                updateMobKillCount()
            end
        end)
    end
end

-- Try to hook mob deaths when the script loads
hookMobDeath()

-- Try again when the workspace children change
workspace.ChildAdded:Connect(function(child)
    if child.Name == "Mobs" then
        wait(1) -- Small delay to ensure the folder is properly set up
        hookMobDeath()
    end
end)

-- Module return
return {
    UI = Window,
    StopRolling = function()
        if rollConnection then
            rollConnection:Disconnect()
            rollConnection = nil
            AutoRollToggle:Set(false)
        end
    end,
    StopAttacking = function()
        if attackConnection then
            attackConnection:Disconnect()
            attackConnection = nil
            AutoAttackToggle:Set(false)
        end
    end,
    StopFarming = function()
        if farmConnection then
            farmConnection:Disconnect()
            farmConnection = nil
            AutoFarmToggle:Set(false)
        end
        
        if farmTimeUpdateConnection then
            farmTimeUpdateConnection:Disconnect()
            farmTimeUpdateConnection = nil
        end
    end
}
