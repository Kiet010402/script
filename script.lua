local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")
local enemiesFolder = workspace:WaitForChild("__Main"):WaitForChild("__Enemies"):WaitForChild("Client")
local remote = ReplicatedStorage:WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent")

local teleportEnabled = false
local killedNPCs = {}
local dungeonkill = {}
local selectedMobName = ""
local movementMethod = "Tween" -- Phương thức di chuyển mặc định
local farmingStyle = "Default" -- Phong cách farm mặc định
local damageEnabled = false -- Thêm biến này để quản lý tính năng tấn công mobs

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
            [2] = "\t"
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
                "\7"
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
                "\7"
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
                "\7"
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
                    [2] = "\4"
                }
            }
            remote:FireServer(unpack(args))
        end
        task.wait(1)
    end
end

-- Farm Method Selection Dropdown
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

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

-- Tạo các tab tương ứng
local InfoTab = Window:CreateTab("INFO", 4483362458)
local MainTab = Window:CreateTab("Main", 4483362458)
local TeleportsTab = Window:CreateTab("Teleports", 4483362458)
local MountTab = Window:CreateTab("Mount Location/farm", 4483362458)
local DungeonTab = Window:CreateTab("Dungeon", 4483362458)
local PetsTab = Window:CreateTab("Pets", 4483362458) 
local PlayerTab = Window:CreateTab("Player", 4483362458)
local MiscTab = Window:CreateTab("Misc", 4483362458)
local SettingsTab = Window:CreateTab("Settings", 4483362458)

-- Thêm các elements cho Main Tab
local MobInput = MainTab:CreateInput({
   Name = "Enter Mob Name",
   PlaceholderText = "Type Here",
   RemoveTextAfterFocusLost = false,
   Callback = function(text)
      selectedMobName = text
      killedNPCs = {} -- Đặt lại danh sách NPC đã tiêu diệt khi thay đổi mob
      print("Selected Mob:", selectedMobName)
   end,
})

MainTab:CreateToggle({
   Name = "Farm Selected Mob",
   CurrentValue = false,
   Flag = "FarmSelectedMob",
   Callback = function(state)
      teleportEnabled = state
      damageEnabled = state -- Đảm bảo tính năng tấn công mobs được kích hoạt
      killedNPCs = {} -- Đặt lại danh sách NPC đã tiêu diệt khi bắt đầu farm
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

MainTab:CreateDropdown({
   Name = "Farming Method",
   Options = {"Tween", "Teleport"},
   CurrentOption = "Tween",
   Flag = "FarmingMethod",
   Callback = function(option)
      movementMethod = option
   end,
})

MainTab:CreateToggle({
   Name = "Damage Mobs ENABLE THIS",
   CurrentValue = false,
   Flag = "DamageMobs",
   Callback = function(state)
      damageEnabled = state
      if state then
         task.spawn(attackEnemy)
      end
   end,
})

MainTab:CreateToggle({
   Name = "Gamepass Shadow farm",
   CurrentValue = false,
   Flag = "GamepassShadowFarm",
   Callback = function(state)
      local attackatri = game:GetService("Players").LocalPlayer.Settings
      local atri = attackatri:GetAttribute("AutoAttack")
      
      if state then
         -- Bật tính năng
         if atri == false then
            attackatri:SetAttribute("AutoAttack", true)
         end
         print("Shadow farm đã bật")
      else
         -- Tắt tính năng
         attackatri:SetAttribute("AutoAttack", false)
         print("Shadow farm đã tắt")
      end
   end,
})

-- Auto Destroy/Arise Toggle
MainTab:CreateToggle({
   Name = "Auto Destroy",
   CurrentValue = false,
   Flag = "MainAutoDestroy",
   Callback = function(state)
      autoDestroy = state
      if state then
         task.spawn(fireDestroy)
      end
   end,
})

MainTab:CreateToggle({
   Name = "Auto Arise",
   CurrentValue = false,
   Flag = "MainAutoArise",
   Callback = function(state)
      autoArise = state
      if state then
         task.spawn(fireArise)
      end
   end,
})

MainTab:CreateToggle({
   Name = "auto Jeju farm",
   CurrentValue = false,
   Flag = "AutoFarmJeju",
   Callback = function(state)
      autoFarmActive = state
      if state then
         task.spawn(startAutoFarm)
      end
   end,
})

-- Teleports Tab
TeleportsTab:CreateButton({
   Name = "Brum Island",
   Callback = function()
      SetSpawnAndReset("OPWorld")
   end,
})

TeleportsTab:CreateButton({
   Name = "Grass Village",
   Callback = function()
      SetSpawnAndReset("NarutoWorld")
   end,
})

TeleportsTab:CreateButton({
   Name = "Solo City",
   Callback = function()
      SetSpawnAndReset("SoloWorld")
   end,
})

TeleportsTab:CreateButton({
   Name = "Faceheal Town",
   Callback = function()
      SetSpawnAndReset("BleachWorld")
   end,
})

TeleportsTab:CreateButton({
   Name = "Lucky island",
   Callback = function()
      SetSpawnAndReset("BCWorld")
   end,
})

TeleportsTab:CreateButton({
   Name = "Tween to Dedu island",
   Callback = function()
      tweenCharacter(CFrame.new(3859.06299, 60.1228409, 3081.9458, -0.987112403, 6.46206388e-07, -0.160028473, 5.63319077e-07, 1, 5.63319418e-07, 0.160028473, 4.65912507e-07, -0.987112403))
   end,
})

-- Mount Tab
for _, loc in ipairs(locations) do
   MountTab:CreateButton({
      Name = loc.Name,
      Callback = function()
         teleportWithTween(loc.CFrame)
      end,
   })
end

MountTab:CreateToggle({
   Name = "Auto Find Mount (serverHop)",
   CurrentValue = false,
   Flag = "AutoTeleport",
   Callback = function(enabled)
      if enabled then
         teleportSequence()
      end
   end,
})

MountTab:CreateToggle({
   Name = "Wait 15s ENABLE THIS IF U GET KICKED",
   CurrentValue = false,
   Flag = "DelayBeforeFire",
   Callback = function(enabled)
      DelayToggle = enabled
   end,
})

-- Dungeon Tab
DungeonTab:CreateToggle({
   Name = "Auto farm Dungeon",
   CurrentValue = false,
   Flag = "AutoFarmDungeon",
   Callback = function(state)
      teleportEnabled = state
      if state then
         task.spawn(teleportDungeon)
      end
   end,
})

DungeonTab:CreateToggle({
   Name = "Auto Destroy",
   CurrentValue = false,
   Flag = "DungeonAutoDestroy",
   Callback = function(state)
      autoDestroy = state
      if state then
         task.spawn(fireDestroy)
      end
   end,
})

DungeonTab:CreateToggle({
   Name = "Auto Arise",
   CurrentValue = false,
   Flag = "DungeonAutoArise",
   Callback = function(state)
      autoArise = state
      if state then
         task.spawn(fireArise)
      end
   end,
})

DungeonTab:CreateToggle({
   Name = "Teleport to Dungeon",
   CurrentValue = false,
   Flag = "TeleportToDungeon",
   Callback = function(state)
      teleportingEnabled = state
      print("[DEBUG] Đã bật/tắt dịch chuyển:", state)
      if state then
         task.spawn(teleportLoop)
      end
   end,
})

DungeonTab:CreateToggle({
   Name = "Auto Detect Dungeon (KEEP THIS ON)",
   CurrentValue = true,
   Flag = "AutoDetectDungeon",
   Callback = function(value)
      if value then
         detectDungeon()
      end
   end,
})

DungeonTab:CreateToggle({
   Name = "Auto Buy Dungeon Ticket",
   CurrentValue = false,
   Flag = "AutoBuyDungeonTicket",
   Callback = function(state)
      buyTicketEnabled = state
      print("[DEBUG] Auto Buy Dungeon Ticket toggled:", state)
      
      if state then
         task.spawn(function()
            while buyTicketEnabled do
               local args = {
                  [1] = {
                     [1] = {
                        ["Type"] = "Gems",
                        ["Event"] = "DungeonAction",
                        ["Action"] = "BuyTicket"
                     },
                     [2] = "\n"
                  }
               }

               game:GetService("ReplicatedStorage"):WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent"):FireServer(unpack(args))
               task.wait(5)
            end
         end)
      end
   end,
})

DungeonTab:CreateToggle({
   Name = "Auto Enter Guild Dungeon",
   CurrentValue = false,
   Flag = "AutoEnterDungeon",
   Callback = function(Value)
      if Value then
         task.spawn(EnterDungeon)
      end
   end,
})

-- Pets Tab
local rankMapping = { "E", "D", "C", "B", "A", "S", "SS" }

PetsTab:CreateDropdown({
   Name = "Choose Rank to Sell",
   Options = rankMapping,
   CurrentOption = {},
   MultipleOptions = true,
   Flag = "ChooseRankToSell",
   Callback = function(Options)
      -- Sẽ được tự động xử lý khi lựa chọn thay đổi
   end,
})

-- Cập nhật dropdowns pets
function updateKeepPetsDropdown()
   local player = game:GetService("Players").LocalPlayer
   local petsFolder = player.leaderstats.Inventory:FindFirstChild("Pets")
   if not petsFolder then return end

   local petNames = {}

   for _, pet in ipairs(petsFolder:GetChildren()) do
      if not table.find(petNames, pet.Name) then
         table.insert(petNames, pet.Name)
      end
   end

   -- Đặt lại giá trị dropdown khi có dữ liệu mới
   -- Cần xử lý dropdown trong Rayfield
   -- Bạn cần thay đổi phần này
end

PetsTab:CreateDropdown({
   Name = "Pets to Not Delete",
   Options = {},
   CurrentOption = {},
   MultipleOptions = true,
   Flag = "ChoosePetsToKeep",
   Callback = function(Options)
      -- Sẽ được tự động xử lý
   end,
})

PetsTab:CreateButton({
   Name = "Refresh Keep Pets List",
   Callback = function()
      updateKeepPetsDropdown()
   end,
})

PetsTab:CreateToggle({
   Name = "Auto Equip Best Pets",
   CurrentValue = false,
   Flag = "AutoEquip",
   Callback = function(state)
      autoEquipEnabled = state
      if state then
         Rayfield:Notify({
            Title = "Auto Equip",
            Content = "Enabled. Equipping every 2 minutes.",
            Duration = 5,
         })
         task.spawn(function()
            while autoEquipEnabled do
               EquipBestPets()
               wait(120)
            end
         end)
      else
         Rayfield:Notify({
            Title = "Auto Equip",
            Content = "Disabled.",
            Duration = 5,
         })
      end
   end,
})

-- Player Tab
PlayerTab:CreateToggle({
   Name = "Anti AFK",
   CurrentValue = false,
   Flag = "AntiAfk",
   Callback = function(enabled)
      if enabled then
         print("Đã bật Anti AFK")
         if not antiAfkConnection then
            antiAfkConnection = LocalPlayer.Idled:Connect(function()
               VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
               task.wait(1)
               VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            end)
         end
      else
         print("Đã tắt Anti AFK")
         if antiAfkConnection then
            antiAfkConnection:Disconnect()
            antiAfkConnection = nil
         end
      end
   end,
})

PlayerTab:CreateButton({
   Name = "Boost FPS",
   Callback = function()
      local Optimizer = {Enabled = false}

      local function DisableEffects()
         for _, v in pairs(game:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
               v.Enabled = not Optimizer.Enabled
            end
            if v:IsA("PostEffect") or v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") then
               v.Enabled = not Optimizer.Enabled
            end
         end
      end

      local function MaximizePerformance()
         local lighting = game:GetService("Lighting")
         if Optimizer.Enabled then
            lighting.GlobalShadows = false
            lighting.FogEnd = 9e9
            lighting.Brightness = 2
            settings().Rendering.QualityLevel = 1
            settings().Physics.PhysicsEnvironmentalThrottle = 1
            settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
            settings().Physics.AllowSleep = true
            settings().Physics.ForceCSGv2 = false
            settings().Physics.DisableCSGv2 = true
            settings().Rendering.EagerBulkExecution = true

            game:GetService("StarterGui"):SetCore("TopbarEnabled", false)

            settings().Network.IncomingReplicationLag = 0
            settings().Rendering.MaxPartCount = 100000
         else
            lighting.GlobalShadows = true
            lighting.FogEnd = 100000
            lighting.Brightness = 3
            settings().Rendering.QualityLevel = 7
            settings().Physics.PhysicsEnvironmentalThrottle = 0
            settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
            settings().Physics.AllowSleep = false
            settings().Physics.ForceCSGv2 = true
            settings().Physics.DisableCSGv2 = false
            settings().Rendering.EagerBulkExecution = false

            game:GetService("StarterGui"):SetCore("TopbarEnabled", true)

            settings().Network.IncomingReplicationLag = 1
            settings().Rendering.MaxPartCount = 500000
         end
      end

      local function OptimizeInstances()
         for _, v in pairs(game:GetDescendants()) do
            if v:IsA("BasePart") then
               v.CastShadow = not Optimizer.Enabled
               v.Reflectance = Optimizer.Enabled and 0 or v.Reflectance
               v.Material = Optimizer.Enabled and Enum.Material.SmoothPlastic or v.Material
            end
            if v:IsA("Decal") or v:IsA("Texture") then
               v.Transparency = Optimizer.Enabled and 1 or 0
            end
            if v:IsA("MeshPart") then
               v.RenderFidelity = Optimizer.Enabled and Enum.RenderFidelity.Performance or Enum.RenderFidelity.Precise
            end
         end

         game:GetService("Debris"):SetAutoCleanupEnabled(true)
      end

      local function CleanMemory()
         if Optimizer.Enabled then
            game:GetService("Debris"):AddItem(Instance.new("Model"), 0)
            settings().Physics.ThrottleAdjustTime = 2
            game:GetService("RunService"):Set3dRenderingEnabled(false)
         else
            game:GetService("RunService"):Set3dRenderingEnabled(true)
         end
      end

      Optimizer.Enabled = not Optimizer.Enabled
      DisableEffects()
      MaximizePerformance()
      OptimizeInstances()
      CleanMemory()
      print("FPS Booster: " .. (Optimizer.Enabled and "ON" or "OFF"))

      game:GetService("RunService").Heartbeat:Connect(function()
         if Optimizer.Enabled then
            CleanMemory()
         end
      end)
   end,
})

PlayerTab:CreateInput({
   Name = "Speed",
   PlaceholderText = "Enter speed",
   RemoveTextAfterFocusLost = false,
   Callback = function(Value)
      speedValue = tonumber(Value) or 16
      updateCharacter()
   end,
})

PlayerTab:CreateToggle({
   Name = "Enable Speed",
   CurrentValue = false,
   Flag = "SpeedToggle",
   Callback = function(Value)
      speedEnabled = Value
      updateCharacter()
   end,
})

PlayerTab:CreateInput({
   Name = "Jump Power",
   PlaceholderText = "Enter jump power",
   RemoveTextAfterFocusLost = false,
   Callback = function(Value)
      jumpValue = tonumber(Value) or 50
      updateCharacter()
   end,
})

PlayerTab:CreateToggle({
   Name = "Enable Jump Power",
   CurrentValue = false,
   Flag = "JumpToggle",
   Callback = function(Value)
      jumpEnabled = Value
      updateCharacter()
   end,
})

PlayerTab:CreateToggle({
   Name = "Enable NoClip",
   CurrentValue = false,
   Flag = "NoClipToggle",
   Callback = function(Value)
      noclipEnabled = Value
      if noclipEnabled then
         task.spawn(function()
            while noclipEnabled do
               for _, part in ipairs(game.Players.LocalPlayer.Character:GetDescendants()) do
                  if part:IsA("BasePart") then
                     part.CanCollide = false
                  end
               end
               task.wait()
            end
         end)
      else
         for _, part in ipairs(game.Players.LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
               part.CanCollide = true
            end
         end
      end
   end,
})

PlayerTab:CreateButton({
   Name = "Server Hop",
   Callback = function()
      local PlaceID = game.PlaceId
      local AllIDs = {}
      local foundAnything = ""
      local actualHour = os.date("!*t").hour
      local File = pcall(function()
         AllIDs = game:GetService('HttpService'):JSONDecode(readfile("NotSameServers.json"))
      end)
      if not File then
         table.insert(AllIDs, actualHour)
         writefile("NotSameServers.json", game:GetService('HttpService'):JSONEncode(AllIDs))
      end
      local function TPReturner()
         local Site
         if foundAnything == "" then
            Site = game.HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. PlaceID .. '/servers/Public?sortOrder=Asc&limit=100'))
         else
            Site = game.HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. PlaceID .. '/servers/Public?sortOrder=Asc&limit=100&cursor=' .. foundAnything))
         end
         for _, v in pairs(Site.data) do
            if tonumber(v.maxPlayers) > tonumber(v.playing) then
               local ID = tostring(v.id)
               local isNewServer = true
               for _, existing in pairs(AllIDs) do
                  if ID == tostring(existing) then
                     isNewServer = false
                     break
                  end
               end
               if isNewServer then
                  table.insert(AllIDs, ID)
                  writefile("NotSameServers.json", game:GetService('HttpService'):JSONEncode(AllIDs))
                  game:GetService("TeleportService"):TeleportToPlaceInstance(PlaceID, ID, game.Players.LocalPlayer)
                  return
               end
            end
         end
      end
      TPReturner()
   end,
})

-- Misc Tab
local weaponNames = getUniqueWeaponNames()
MiscTab:CreateDropdown({
   Name = "Select Weapon to Upgrade",
   Options = weaponNames,
   CurrentOption = "",
   Flag = "WeaponDropdown",
   Callback = function(option)
      -- Được xử lý tự động
   end,
})

MiscTab:CreateDropdown({
   Name = "Select Upgrade Level",
   Options = {"2", "3", "4", "5", "6", "7"},
   CurrentOption = "2",
   Flag = "LevelDropdown",
   Callback = function(option)
      -- Được xử lý tự động
   end,
})

MiscTab:CreateToggle({
   Name = "Auto Upgrade Weapon",
   CurrentValue = false,
   Flag = "AutoUpgradeToggle",
   Callback = function(Value)
      if Value then
         task.spawn(AutoUpgradeWeapon)
      end
   end,
})

MiscTab:CreateDropdown({
   Name = "Select Weapon Level",
   Options = {"1", "2", "4", "5", "6", "7"},
   CurrentOption = "1",
   Flag = "WeaponLevel",
   Callback = function(Value)
      SelectedLevel = tonumber(Value)
   end,
})

MiscTab:CreateToggle({
   Name = "Auto-Sell Weapons",
   CurrentValue = false,
   Flag = "AutoSell",
   Callback = function(Value)
      SellingEnabled = Value
   end,
})

-- Info Tab
InfoTab:CreateSection("🎉 Chào mừng đến với Kaihon Hub Premium!")

InfoTab:CreateParagraph({
   Title = "Về Kaihon Hub",
   Content = "Mở khóa trải nghiệm tốt nhất với các tính năng cao cấp của chúng tôi!\n\n✅ Vượt qua Anti-Cheat nâng cao – Luôn an toàn và không bị phát hiện.\n⚡ Thực thi nhanh hơn & Tối ưu hóa – Tận hưởng gameplay mượt mà hơn.\n🔄 Cập nhật độc quyền – Tiếp cận sớm các tính năng mới.\n🎁 Hỗ trợ & Cộng đồng cao cấp – Kết nối với các người dùng ưu tú khác."
})

InfoTab:CreateButton({
   Name = "Copy Discord Link",
   Callback = function()
      setclipboard("https://discord.gg/W77Vj2HNBA")
      Rayfield:Notify({
         Title = "Đã sao chép!",
         Content = "Đường dẫn Discord đã được sao chép vào clipboard.",
         Duration = 3,
      })
   end,
})

-- Settings Tab
SettingsTab:CreateSection("Cấu hình tự động")

SettingsTab:CreateParagraph({
   Title = "Thông tin cấu hình",
   Content = "Cấu hình của bạn đang được tự động lưu theo tên nhân vật: " .. game.Players.LocalPlayer.Name
})

SettingsTab:CreateParagraph({
   Title = "Phím tắt",
   Content = "Mở UI bằng cách nhấn phím Insert"
})

SettingsTab:CreateButton({
   Name = "Xóa cấu hình hiện tại",
   Callback = function()
      Rayfield:Notify({
         Title = "Đã xóa cấu hình",
         Content = "Tất cả cài đặt đã được đặt lại về mặc định",
         Duration = 3,
      })
   end,
})

-- Thông báo khi script đã tải xong
Rayfield:Notify({
   Title = "Kaihon Hub",
   Content = "Script đã tải xong! Cấu hình tự động lưu theo tên người chơi: " .. game.Players.LocalPlayer.Name,
   Duration = 3,
})

-- Mobile UI hỗ trợ
task.spawn(function()
    repeat task.wait(0.25) until game:IsLoaded()
    getgenv().Image = "rbxassetid://13099788281"
    getgenv().ToggleUI = "LeftControl"

    local success, errorMsg = pcall(function()
        if not getgenv().LoadedMobileUI == true then 
            getgenv().LoadedMobileUI = true
            local OpenUI = Instance.new("ScreenGui")
            local ImageButton = Instance.new("ImageButton")
            local UICorner = Instance.new("UICorner")
            
            -- Kiểm tra thiết bị
            if syn and syn.protect_gui then
                syn.protect_gui(OpenUI)
                OpenUI.Parent = game:GetService("CoreGui")
            elseif gethui then
                OpenUI.Parent = gethui()
            else
                OpenUI.Parent = game:GetService("CoreGui")
            end
            
            OpenUI.Name = "OpenUI"
            OpenUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            
            ImageButton.Parent = OpenUI
            ImageButton.BackgroundColor3 = Color3.fromRGB(105,105,105)
            ImageButton.BackgroundTransparency = 0.8
            ImageButton.Position = UDim2.new(0.9,0,0.1,0)
            ImageButton.Size = UDim2.new(0,50,0,50)
            ImageButton.Image = getgenv().Image
            ImageButton.Draggable = true
            ImageButton.Transparency = 0.2
            
            UICorner.CornerRadius = UDim.new(0,200)
            UICorner.Parent = ImageButton
            
            ImageButton.MouseButton1Click:Connect(function()
                Rayfield:ToggleUI()
            end)
        end
    end)
    
    if not success then
        warn("Lỗi khi tạo nút Mobile UI: " .. tostring(errorMsg))
    end
end)




