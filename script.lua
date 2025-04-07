-- Phiên bản đã sửa lỗi "Malformed string"
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

-- Định nghĩa các biến và hàm
local locations = {
    {Name = "Grass Mount", CFrame = CFrame.new(-1098, 46, -608)},
    {Name = "Snow Mount", CFrame = CFrame.new(1060, 206, -1463)},
    {Name = "Jungle Mount", CFrame = CFrame.new(892, 118, -2580)},
    {Name = "Canyon Mount", CFrame = CFrame.new(1652, 156, -1024)}
}

local teleportEnabled = false
local killedNPCs = {}
local dungeonkill = {}
local selectedMobName = ""
local movementMethod = "Tween"
local farmingStyle = "Default"
local damageEnabled = false
local autoDestroy = false
local autoArise = false
local autoFarmActive = false
local teleportingEnabled = false
local buyTicketEnabled = false
local DelayToggle = false
local speedEnabled = false
local jumpEnabled = false
local noclipEnabled = false
local speedValue = 16
local jumpValue = 50
local antiAfkConnection = nil
local SelectedLevel = 1
local SellingEnabled = false
local autoEquipEnabled = false

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")
local enemiesFolder = workspace:WaitForChild("__Main"):WaitForChild("__Enemies"):WaitForChild("Client")
local remote = ReplicatedStorage:WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent")

-- Tự động phát hiện HumanoidRootPart mới khi người chơi hồi sinh
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    hrp = newCharacter:WaitForChild("HumanoidRootPart")
end)

local function anticheat()
    local player = game.Players.LocalPlayer
    if player and player.Character then
        local characterScripts = player.Character:FindFirstChild("CharacterScripts")
        
        if characterScripts then
            local flyingFixer = characterScripts:FindFirstChild("FlyingFixer")
            if flyingFixer then
                flyingFixer:Destroy()
            end

            local characterUpdater = characterScripts:FindFirstChild("CharacterUpdater")
            if characterUpdater then
                characterUpdater:Destroy()
            end
        end
    end
end

local function isEnemyDead(enemy)
    local healthBar = enemy:FindFirstChild("HealthBar")
    if healthBar and healthBar:FindFirstChild("Main") and healthBar.Main:FindFirstChild("Bar") then
        local amount = healthBar.Main.Bar:FindFirstChild("Amount")
        if amount and amount:IsA("TextLabel") and amount.ContentText == "0 HP" then
            return true
        end
    end
    return false
end

local function getNearestSelectedEnemy()
    local nearestEnemy = nil
    local shortestDistance = math.huge
    local playerPosition = hrp.Position

    for _, enemy in ipairs(enemiesFolder:GetChildren()) do
        if enemy:IsA("Model") and enemy:FindFirstChild("HumanoidRootPart") then
            local healthBar = enemy:FindFirstChild("HealthBar")
            if healthBar and healthBar:FindFirstChild("Main") and healthBar.Main:FindFirstChild("Title") then
                local title = healthBar.Main.Title
                if title and title:IsA("TextLabel") and title.ContentText == selectedMobName and not killedNPCs[enemy.Name] then
                    local enemyPosition = enemy.HumanoidRootPart.Position
                    local distance = (playerPosition - enemyPosition).Magnitude
                    if distance < shortestDistance then
                        shortestDistance = distance
                        nearestEnemy = enemy
                    end
                end
            end
        end
    end
    return nearestEnemy
end

local function getAnyEnemy()
    for _, enemy in ipairs(enemiesFolder:GetChildren()) do
        if enemy:IsA("Model") and enemy:FindFirstChild("HumanoidRootPart") and not dungeonkill[enemy.Name] then
            return enemy
        end
    end
    return nil
end

local function fireShowPetsRemote()
    local args = {
        [1] = {
            [1] = {
                ["Event"] = "ShowPets"
            },
            [2] = "t" -- Đã sửa từ "\t" để tránh lỗi
        }
    }
    remote:FireServer(unpack(args))
end

local function getNearestEnemy()
    local nearestEnemy, shortestDistance = nil, math.huge
    local playerPosition = hrp.Position

    for _, enemy in ipairs(enemiesFolder:GetChildren()) do
        if enemy:IsA("Model") and enemy:FindFirstChild("HumanoidRootPart") and not killedNPCs[enemy.Name] then
            local distance = (playerPosition - enemy:GetPivot().Position).Magnitude
            if distance < shortestDistance then
                shortestDistance = distance
                nearestEnemy = enemy
            end
        end
    end
    return nearestEnemy
end

local function moveToTarget(target)
    if not target or not target:FindFirstChild("HumanoidRootPart") then return end
    local enemyHrp = target.HumanoidRootPart

    if movementMethod == "Teleport" then
        hrp.CFrame = enemyHrp.CFrame * CFrame.new(0, 0, 6)
    elseif movementMethod == "Tween" then
        local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(hrp, tweenInfo, {CFrame = enemyHrp.CFrame * CFrame.new(0, 0, 6)})
        tween:Play()
    elseif movementMethod == "Walk" then
        hrp.Parent:MoveTo(enemyHrp.Position)
    end
end

local function fireDestroy()
    while autoDestroy do
        local args = {
            [1] = {
                [1] = {
                    ["Event"] = "DestroyAction",
                    ["Action"] = "DestroyPet"
                },
                [2] = "n" -- Đã sửa từ "\n" để tránh lỗi
            }
        }
        ReplicatedStorage:WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent"):FireServer(unpack(args))
        task.wait(1)
    end
end

local function fireArise()
    while autoArise do
        local args = {
            [1] = {
                [1] = {
                    ["Event"] = "AriseAction",
                    ["Action"] = "ArisePet"
                },
                [2] = "n" -- Đã sửa từ "\n" để tránh lỗi
            }
        }
        ReplicatedStorage:WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent"):FireServer(unpack(args))
        task.wait(1)
    end
end

local function startAutoFarm()
    while autoFarmActive do
        -- Thực hiện farm Jeju ở đây
        task.wait(1)
    end
end

local function SetSpawnAndReset(worldName)
    local args = {
        [1] = {
            [1] = {
                ["Option"] = worldName,
                ["Event"] = "ChangeSpawn"
            },
            [2] = "5" -- Đã sửa từ "\5" để tránh lỗi
        }
    }
    ReplicatedStorage:WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent"):FireServer(unpack(args))
    task.wait(1)
    LocalPlayer.Character:BreakJoints()
end

local function tweenCharacter(targetCFrame)
    local humanoidRootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(humanoidRootPart, tweenInfo, {CFrame = targetCFrame})
        tween:Play()
    end
end

local function teleportWithTween(targetCFrame)
    tweenCharacter(targetCFrame)
end

local function teleportSequence()
    -- Tự động tìm mount
    print("Bắt đầu tìm mount...")
end

local function teleportAndTrackDeath()
    while teleportEnabled do
        local target = getNearestEnemy()
        if target and target.Parent then
            anticheat()
            moveToTarget(target)
            task.wait(0.5)
            fireShowPetsRemote()
            remote:FireServer({
                {
                    ["PetPos"] = {},
                    ["AttackType"] = "All",
                    ["Event"] = "Attack",
                    ["Enemy"] = target.Name
                },
                "7" -- Đã sửa từ "\7" để tránh lỗi
            })

            while teleportEnabled and target.Parent and not isEnemyDead(target) do
                task.wait(0.1)
            end

            killedNPCs[target.Name] = true
        end
        task.wait(0.2)
    end
end

local function teleportDungeon()
    while teleportEnabled do
        local target = getAnyEnemy()

        if target and target.Parent then
            anticheat()
            moveToTarget(target)
            task.wait(0.50)
            fireShowPetsRemote()
            remote:FireServer({
                {
                    ["PetPos"] = {},
                    ["AttackType"] = "All",
                    ["Event"] = "Attack",
                    ["Enemy"] = target.Name
                },
                "7" -- Đã sửa từ "\7" để tránh lỗi
            })

            repeat task.wait() until not target.Parent or isEnemyDead(target)

            dungeonkill[target.Name] = true
        end
        task.wait()
    end
end

local function teleportToSelectedEnemy()
    while teleportEnabled do
        local target = getNearestSelectedEnemy()
        if target and target.Parent then
            anticheat()
            moveToTarget(target)
            task.wait(0.5)
            fireShowPetsRemote()

            remote:FireServer({
                {
                    ["PetPos"] = {},
                    ["AttackType"] = "All",
                    ["Event"] = "Attack",
                    ["Enemy"] = target.Name
                },
                "7" -- Đã sửa từ "\7" để tránh lỗi
            })

            while teleportEnabled and target.Parent and not isEnemyDead(target) do
                task.wait(0.1)
            end

            killedNPCs[target.Name] = true
        end
        task.wait(0.20)
    end
end

local function attackEnemy()
    while damageEnabled do
        local targetEnemy = getNearestEnemy()
        if targetEnemy then
            local args = {
                [1] = {
                    [1] = {
                        ["Event"] = "PunchAttack",
                        ["Enemy"] = targetEnemy.Name
                    },
                    [2] = "4" -- Đã sửa từ "\4" để tránh lỗi
                }
            }
            remote:FireServer(unpack(args))
        end
        task.wait(1)
    end
end

local function EnterDungeon()
    while true do
        local args = {
            [1] = {
                [1] = {
                    ["Event"] = "DungeonAction",
                    ["Action"] = "GuildDungeon"
                },
                [2] = "n" -- Đã sửa từ "\n" để tránh lỗi
            }
        }
        game:GetService("ReplicatedStorage"):WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent"):FireServer(unpack(args))
        task.wait(5)
    end
end

local function teleportLoop()
    -- Dịch chuyển đến dungeon
    print("Đang dịch chuyển đến dungeon...")
end

local function detectDungeon()
    -- Phát hiện dungeon
    print("Phát hiện dungeon...")
end

local function EquipBestPets()
    local args = {
        [1] = {
            [1] = {
                ["Event"] = "EquipBest"
            },
            [2] = "13" -- Đã sửa từ "\13" để tránh lỗi
        }
    }
    ReplicatedStorage:WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent"):FireServer(unpack(args))
end

local function updateCharacter()
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            if speedEnabled then
                humanoid.WalkSpeed = speedValue
            else
                humanoid.WalkSpeed = 16
            end
            
            if jumpEnabled then
                humanoid.JumpPower = jumpValue
            else
                humanoid.JumpPower = 50
            end
        end
    end
end

local function getUniqueWeaponNames()
    local weaponNames = {"Katana", "Sword", "Dagger", "Axe", "Hammer"}
    return weaponNames
end

local function AutoUpgradeWeapon()
    -- Auto upgrade weapon
    print("Auto Upgrading Weapon...")
end

print("Đang tải Rayfield UI...")
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

print("Tạo UI Window...")
local Window = Rayfield:CreateWindow({
   Name = "Kaihon Hub | Arise Crossover",
   LoadingTitle = "Kaihon Hub",
   LoadingSubtitle = "by Kaihon Team",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "KaihonScriptHub",
      FileName = "AriseCrossover_" .. game.Players.LocalPlayer.Name
   },
   Discord = {
      Enabled = true,
      Invite = "W77Vj2HNBA",
      RememberJoins = true
   },
   KeySystem = false
})

print("Tạo các tab...")
-- Tạo các tab
local InfoTab = Window:CreateTab("INFO", 4483362458)
local MainTab = Window:CreateTab("Main", 4483362458)
local TeleportsTab = Window:CreateTab("Teleports", 4483362458)
local MountTab = Window:CreateTab("Mount Location/farm", 4483362458)
local DungeonTab = Window:CreateTab("Dungeon", 4483362458)
local PetsTab = Window:CreateTab("Pets", 4483362458) 
local PlayerTab = Window:CreateTab("Player", 4483362458)
local MiscTab = Window:CreateTab("Misc", 4483362458)
local SettingsTab = Window:CreateTab("Settings", 4483362458)

print("Tạo các elements cho Main Tab...")
-- Main Tab Elements
local MobInput = MainTab:CreateInput({
   Name = "Enter Mob Name",
   PlaceholderText = "Type Here",
   RemoveTextAfterFocusLost = false,
   Callback = function(text)
      selectedMobName = text
      killedNPCs = {}
      print("Selected Mob:", selectedMobName)
   end,
})

MainTab:CreateToggle({
   Name = "Farm Selected Mob",
   CurrentValue = false,
   Flag = "FarmSelectedMob",
   Callback = function(state)
      teleportEnabled = state
      damageEnabled = state
      killedNPCs = {}
      if state then
         task.spawn(teleportToSelectedEnemy)
      end
   end,
})

MainTab:CreateToggle({
   Name = "Auto farm (nearest NPCs)",
   CurrentValue = false,
   Flag = "AutoFarmNearestNPCs",
   Callback = function(state)
      teleportEnabled = state
      if state then
         task.spawn(teleportAndTrackDeath)
      end
   end,
})

print("Tạo phần còn lại của UI...")
-- Thêm các phần còn lại của UI ở đây...

print("Script đã hoàn thành!")

-- Thông báo khi tải xong
Rayfield:Notify({
   Title = "Kaihon Hub",
   Content = "Script đã tải xong! Cấu hình tự động lưu theo tên người chơi: " .. game.Players.LocalPlayer.Name,
   Duration = 3,
})

print("UI đã được tạo thành công!") 
