-- Anime Last Stand Auto Farm Script
-- Dựa theo BUANG HUB

local Players = game:GetService("Players") 
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

-- Tải thư viện Rayfield UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Kiểm tra xem đã có UI nào đang chạy không
if getgenv().RayfieldLoaded then
    Rayfield:Destroy()
end
-- Thêm một biến để kiểm soát số lượng thông báo
getgenv().NotifyOnJoin = true
getgenv().RayfieldLoaded = true
-- Đảm bảo rằng biến môi trường có giá trị mặc định
getgenv().SelectedMap = "Desert Village"
-- Tạo cửa sổ Rayfield
local Window = Rayfield:CreateWindow({
    Name = "DUONGTUAN - Anime Last Stand",
    LoadingTitle = "DUONGTUAN",
    LoadingSubtitle = "by DuongTuan",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "DUONGTUANConfig",
        FileName = "DUONGTUAN_Config"
    },
    Discord = {
        Enabled = false,
        Invite = "",
        RememberJoins = true
    },
    KeySystem = false
})

-- Tạo các tab
local MainTab = Window:CreateTab("MAIN", 4483362458)
local FarmTab = Window:CreateTab("FARM", 4483345998)
local AutoPlayTab = Window:CreateTab("AUTOPLAY+", 4483345737)
local MacroTab = Window:CreateTab("MACRO M.MAPS", 4483345737)
local ShopTab = Window:CreateTab("SHOP", 4483345737)
local MiscTab = Window:CreateTab("MISC", 4483345737)

local function activateTeleporter(silent)
    if not getgenv().AutoJoinMap then return end
    
    -- Lấy join mode từ biến global
    local joinModeString = tostring(getgenv().JoinMode)
    
    local success, errorMsg = pcall(function()
        local teleporterFolder = workspace:FindFirstChild("TeleporterFolder")
        if not teleporterFolder then
            if getgenv().CallbackError then
                Rayfield:Notify({
                    Title = "Lỗi",
                    Content = "Không tìm thấy TeleporterFolder!",
                    Duration = 3,
                    Image = "x",
                })
            end
            return
        end
        
        -- Dùng trực tiếp tên folder
        local folderName = nil
        local doorIndex = nil
        
        -- Lấy thông tin folder và index dựa trên join mode
        if joinModeString == "Story" then
            folderName = "Story"
            doorIndex = 3
        elseif joinModeString == "Challenge" then
            folderName = "Challenge"
            doorIndex = 4
        elseif joinModeString == "Raids" then
            folderName = "Raids"
            doorIndex = 8
        else
            if getgenv().CallbackError then
                Rayfield:Notify({
                    Title = "Lỗi",
                    Content = "Join Mode không hợp lệ: " .. joinModeString,
                    Duration = 3,
                    Image = "x",
                })
            end
            return
        end
        
        -- Tìm folder
        local folderPath = teleporterFolder:FindFirstChild(folderName)
        if not folderPath then
            if getgenv().CallbackError then
                Rayfield:Notify({
                    Title = "Lỗi",
                    Content = "Không tìm thấy folder: " .. folderName,
                    Duration = 3,
                    Image = "x",
                })
            end
            return
        end
        
        -- Lấy đối tượng door
        local children = folderPath:GetChildren()
        if #children < doorIndex then
            if getgenv().CallbackError then
                Rayfield:Notify({
                    Title = "Lỗi",
                    Content = "Không đủ children trong folder",
                    Duration = 3,
                    Image = "x",
                })
            end
            return
        end
        
        local teleportObject = children[doorIndex]
        if not teleportObject then
            if getgenv().CallbackError then
                Rayfield:Notify({
                    Title = "Lỗi",
                    Content = "Không tìm thấy object tại index " .. doorIndex,
                    Duration = 3,
                    Image = "x",
                })
            end
            return
        end
        
        local doorPath = teleportObject:FindFirstChild("Door")
        if not doorPath then
            if getgenv().CallbackError then
                Rayfield:Notify({
                    Title = "Lỗi",
                    Content = "Không tìm thấy Door trong object",
                    Duration = 3,
                    Image = "x",
                })
            end
            return
        end
        
        -- Teleport nhân vật
        local character = player.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then
            if getgenv().CallbackError then
                Rayfield:Notify({
                    Title = "Lỗi",
                    Content = "Không tìm thấy nhân vật hoặc HumanoidRootPart",
                    Duration = 3,
                    Image = "x",
                })
            end
            return
        end
        
        character.HumanoidRootPart.CFrame = doorPath.CFrame + Vector3.new(0, 5, 0)
        
        -- Chỉ hiển thị thông báo khi không ở chế độ im lặng và NotifyOnJoin = true
        if not silent and getgenv().NotifyOnJoin then
            Rayfield:Notify({
                Title = "Auto Join",
                Content = "Đã teleport đến " .. folderName,
                Duration = 3,
                Image = "check",
            })
        end
        -- Delay để đảm bảo teleport hoàn tất
        wait(1)
        
        -- Kích hoạt Door nếu có RemoteEvent
        local remoteEvent = doorPath:FindFirstChild("RemoteEvent")
        if remoteEvent then
            remoteEvent:FireServer()
        end
    end)
    
    if not success and getgenv().CallbackError then
        Rayfield:Notify({
            Title = "Lỗi",
            Content = "Lỗi khi teleport: " .. tostring(errorMsg),
            Duration = 5,
            Image = "x",
        })
    end
end

-- Tab MAIN
-- Section Auto Join
local AutoJoinSection = MainTab:CreateSection("Auto Join")

local JoinModeDropdown = MainTab:CreateDropdown({
    Name = "Join Mode",
    Options = {"Raids", "Story", "Challenge"},
    CurrentOption = "Raids", 
    MultipleOptions = false,
    Flag = "JoinMode",
    Callback = function(Option)
        -- Đảm bảo Option là string
        if type(Option) == "table" then
            Option = Option[1] or "Raids"
        end
        
        -- Lưu lại giá trị mới
        getgenv().JoinMode = Option
        
        -- Nếu Auto Join đang bật, kích hoạt lại teleporter với mode mới
        if getgenv().AutoJoinMap then
            -- Thêm delay để đảm bảo update đã hoàn tất
            wait(0.5)
            activateTeleporter()
        end
    end,
})
-- Sửa lại nút Select Map để xử lý lỗi
local SelectMapButton = MainTab:CreateButton({
    Name = "Select Map",
    Callback = function()
       -- Lấy thông tin map, act và difficulty
       local selectedMap = getgenv().SelectedMap
       local actValue = tonumber(getgenv().Act)
       local difficultyValue = getgenv().Difficulty
       local friendsOnly = getgenv().FriendsOnly
       
       -- Đảm bảo act là số nguyên hợp lệ
       if not actValue or actValue < 1 or actValue > 6 then
          Rayfield:Notify({
             Title = "Lỗi",
             Content = "Act phải là số từ 1-6",
             Duration = 3,
             Image = "x",
          })
          return
       end
       
       -- Kiểm tra xem có phải chế độ Story không
       if getgenv().JoinMode == "Story" then
          -- Hiển thị thông tin sẽ chọn
          Rayfield:Notify({
             Title = "Map Selection",
             Content = "Đang chọn: " .. selectedMap .. ", Act " .. actValue .. ", " .. difficultyValue,
             Duration = 3,
             Image = "check",
          })
          
          -- Gọi remote để chọn map với pcall để bắt lỗi
          local success, result = pcall(function()
             return game:GetService("ReplicatedStorage").Remotes.Story.Select:InvokeServer(selectedMap, actValue, difficultyValue, friendsOnly)
          end)
          
          if success then
             Rayfield:Notify({
                Title = "Thành công",
                Content = "Đã chọn map thành công!",
                Duration = 3,
                Image = "check",
             })
          else
             Rayfield:Notify({
                Title = "Lỗi",
                Content = "Không thể chọn map: " .. tostring(result),
                Duration = 3,
                Image = "x",
             })
             
             -- In thông tin debug để khắc phục lỗi
             print("Debug - Map:", selectedMap)
             print("Debug - Act:", actValue, type(actValue))
             print("Debug - Difficulty:", difficultyValue)
             print("Debug - FriendsOnly:", friendsOnly)
          end
       else
          Rayfield:Notify({
             Title = "Lưu ý",
             Content = "Chức năng này chỉ hoạt động ở chế độ Story. Vui lòng chuyển Join Mode sang Story.",
             Duration = 3,
             Image = "warning",
          })
       end
    end,
})

local MapDropdown = MainTab:CreateDropdown({
    Name = "Map",
    Options = {"Desert Village", "Central City", "Titan Valley", "Shinobi Village", "Ghoul City", "Marine's Ford", "Clover Kingdom", "Hero Academy"},
    CurrentOption = "Desert Village",
    MultipleOptions = false,
    Flag = "SelectedMap",
    Callback = function(Option)
        getgenv().SelectedMap = Option
    end,
})

local ActInput = MainTab:CreateInput({
   Name = "Act",
   PlaceholderText = "6",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      getgenv().Act = Text
   end,
})

local DifficultyDropdown = MainTab:CreateDropdown({
    Name = "Difficulty",
    Options = {"Easy", "Normal", "Hard", "Nightmare", "Infinite"},
    CurrentOption = "Normal",
    MultipleOptions = false,
    Flag = "Difficulty",
    Callback = function(Option)
        getgenv().Difficulty = Option
    end,
})
-- Thêm toggle Callback Error sau Friends Only
local CallbackErrorToggle = MainTab:CreateToggle({
    Name = "Callback Error",
    CurrentValue = false,
    Flag = "CallbackError",
    Callback = function(Value)
        getgenv().CallbackError = Value
    end,
})

local FriendsOnlyToggle = MainTab:CreateToggle({
    Name = "Friends Only",
    CurrentValue = false,
    Flag = "FriendsOnly",
    Callback = function(Value)
        getgenv().FriendsOnly = Value
    end,
})
-- Thêm nút Debug trước Auto Join Map
local DebugPathButton = MainTab:CreateButton({
    Name = "Debug Door Path",
    Callback = function()
       -- Kiểm tra và hiển thị đường dẫn của Door cho từng mode
       local teleporterFolder = workspace:FindFirstChild("TeleporterFolder")
       if not teleporterFolder then
          Rayfield:Notify({
             Title = "Debug",
             Content = "Không tìm thấy TeleporterFolder!",
             Duration = 3,
             Image = "x",
          })
          return
       end
       
       -- Kiểm tra Story
       local storyFolder = teleporterFolder:FindFirstChild("Story")
       if storyFolder and #storyFolder:GetChildren() >= 3 then
          local doorPath = storyFolder:GetChildren()[3]:FindFirstChild("Door")
          Rayfield:Notify({
             Title = "Debug Story",
             Content = doorPath and "Tìm thấy Door" or "Không tìm thấy Door",
             Duration = 3,
             Image = doorPath and "check" or "x",
          })
       else
          Rayfield:Notify({
             Title = "Debug Story",
             Content = "Không đủ children hoặc không tìm thấy folder",
             Duration = 3,
             Image = "x",
          })
       end
       
       -- Kiểm tra Challenge
       local challengeFolder = teleporterFolder:FindFirstChild("Challenge")
       if challengeFolder and #challengeFolder:GetChildren() >= 4 then
          local doorPath = challengeFolder:GetChildren()[4]:FindFirstChild("Door")
          Rayfield:Notify({
             Title = "Debug Challenge",
             Content = doorPath and "Tìm thấy Door" or "Không tìm thấy Door",
             Duration = 3,
             Image = doorPath and "check" or "x",
          })
       else
          Rayfield:Notify({
             Title = "Debug Challenge",
             Content = "Không đủ children hoặc không tìm thấy folder",
             Duration = 3,
             Image = "x",
          })
       end
       
       -- Kiểm tra Raids
       local raidsFolder = teleporterFolder:FindFirstChild("Raids")
       if raidsFolder and #raidsFolder:GetChildren() >= 8 then
          local doorPath = raidsFolder:GetChildren()[8]:FindFirstChild("Door")
          Rayfield:Notify({
             Title = "Debug Raids",
             Content = doorPath and "Tìm thấy Door" or "Không tìm thấy Door",
             Duration = 3,
             Image = doorPath and "check" or "x",
          })
       else
          Rayfield:Notify({
             Title = "Debug Raids",
             Content = "Không đủ children hoặc không tìm thấy folder",
             Duration = 3,
             Image = "x",
          })
       end
    end,
 })
local AutoJoinMapToggle = MainTab:CreateToggle({
    Name = "Auto Join Map",
    CurrentValue = false,
    Flag = "AutoJoinMap",
    Callback = function(Value)
        getgenv().AutoJoinMap = Value
        
        -- Khi bật Auto Join, chỉ kích hoạt teleporter một lần duy nhất
        if Value then
            activateTeleporter(false) -- Không im lặng, hiển thị thông báo
            
            -- Tắt loop nếu đang chạy
            if getgenv().JoinMapLoop then
                getgenv().JoinMapLoop:Disconnect()
                getgenv().JoinMapLoop = nil
            end
        end
    end,
})
-- Thêm toggle để bật/tắt thông báo
local NotifyToggle = MainTab:CreateToggle({
    Name = "Show Join Notifications",
    CurrentValue = true,
    Flag = "NotifyOnJoin",
    Callback = function(Value)
        getgenv().NotifyOnJoin = Value
    end,
})

local AutoStartDelayInput = MainTab:CreateInput({
   Name = "Auto Start Delay",
   PlaceholderText = "0 seconds",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      getgenv().AutoStartDelay = Text
   end,
})

local AutoStartToggle = MainTab:CreateToggle({
    Name = "Auto Start",
    CurrentValue = false,
    Flag = "AutoStart",
    Callback = function(Value)
        getgenv().AutoStart = Value
    end,
})

-- Section Main Features
local MainFeaturesSection = MainTab:CreateSection("Main")

local AutoLeaveToggle = MainTab:CreateToggle({
    Name = "Auto Leave",
    CurrentValue = false,
    Flag = "AutoLeave",
    Callback = function(Value)
        getgenv().AutoLeave = Value
    end,
})

local AutoReplayToggle = MainTab:CreateToggle({
    Name = "Auto Replay",
    CurrentValue = false,
    Flag = "AutoReplay",
    Callback = function(Value)
        getgenv().AutoReplay = Value
    end,
})

local AutoNextToggle = MainTab:CreateToggle({
    Name = "Auto Next",
    CurrentValue = false,
    Flag = "AutoNext",
    Callback = function(Value)
        getgenv().AutoNext = Value
    end,
})

local TPDelayInput = MainTab:CreateInput({
   Name = "TP Delay",
   PlaceholderText = "0 seconds",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      getgenv().TPDelay = Text
   end,
})

local DeleteMapToggle = MainTab:CreateToggle({
    Name = "Delete Map",
    CurrentValue = false,
    Flag = "DeleteMap",
    Callback = function(Value)
        getgenv().DeleteMap = Value
    end,
})

local TeleportToLobbyButton = MainTab:CreateButton({
   Name = "Teleport To Lobby",
   Callback = function()
      -- Code để teleport về lobby sẽ được thêm vào đây
      Rayfield:Notify({
         Title = "Teleport",
         Content = "Đang teleport về lobby...",
         Duration = 3,
         Image = "rbxassetid://4483345737",
      })
      
      -- Thực hiện teleport
      -- Đây là nơi sẽ thêm code teleport thực tế
   end,
})

local AutoLobbyTPToggle = MainTab:CreateToggle({
    Name = "Auto Lobby TP on Time",
    CurrentValue = false,
    Flag = "AutoLobbyTP",
    Callback = function(Value)
        getgenv().AutoLobbyTP = Value
    end,
})

local AutoLobbyTimeInput = MainTab:CreateInput({
   Name = "Auto Lobby Time",
   PlaceholderText = "40 minutes",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      getgenv().AutoLobbyTime = Text
   end,
})

local AutoGameSpeedToggle = MainTab:CreateToggle({
    Name = "Auto 2x/1.5x Game Speed",
    CurrentValue = false,
    Flag = "AutoGameSpeed",
    Callback = function(Value)
        getgenv().AutoGameSpeed = Value
    end,
})

-- Phần FARM Tab (bạn có thể phát triển sau)
FarmTab:CreateLabel("Chức năng farm sẽ được thêm sau")

-- Phần AUTOPLAY+ Tab (bạn có thể phát triển sau)
AutoPlayTab:CreateLabel("Chức năng auto play sẽ được thêm sau")

-- Phần MACRO M.MAPS Tab (bạn có thể phát triển sau)
MacroTab:CreateLabel("Chức năng macro maps sẽ được thêm sau")

-- Phần SHOP Tab (bạn có thể phát triển sau)
ShopTab:CreateLabel("Chức năng shop sẽ được thêm sau")

-- Phần MISC Tab (bạn có thể phát triển sau)
MiscTab:CreateLabel("Các chức năng khác sẽ được thêm sau")

-- Biến global để lưu trạng thái
getgenv().JoinMode = "Raids"
getgenv().SelectedMap = "Central City"
getgenv().Act = "6"
getgenv().Difficulty = "Normal"
getgenv().FriendsOnly = false
getgenv().AutoJoinMap = false
getgenv().AutoStartDelay = "0 seconds"
getgenv().AutoStart = false
getgenv().AutoLeave = false
getgenv().AutoReplay = false
getgenv().AutoNext = false
getgenv().TPDelay = "0 seconds"
getgenv().DeleteMap = false
getgenv().AutoLobbyTP = false
getgenv().AutoLobbyTime = "40 minutes"
getgenv().AutoGameSpeed = false

-- Thông báo khi script đã tải xong
Rayfield:Notify({
    Title = "Script Đã Tải Xong",
    Content = "DUONGTUAN - Anime Last Stand",
    Duration = 5,
    Image = "check",
})
