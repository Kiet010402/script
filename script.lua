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
getgenv().RayfieldLoaded = true

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

-- Tab MAIN
-- Section Auto Join
local AutoJoinSection = MainTab:CreateSection("Auto Join")

local JoinModeDropdown = MainTab:CreateDropdown({
    Name = "Join Mode",
    Options = {"Raids", "Story", "Challenge", "Infinite Mode"},
    CurrentOption = "Raids",
    MultipleOptions = false,
    Flag = "JoinMode",
    Callback = function(Option)
        getgenv().JoinMode = Option
    end,
})

local MapDropdown = MainTab:CreateDropdown({
    Name = "Map",
    Options = {"Central City", "Titan Valley", "Shinobi Village", "Ghoul City", "Marine's Ford", "Clover Kingdom", "Hero Academy"},
    CurrentOption = "Central City",
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

local FriendsOnlyToggle = MainTab:CreateToggle({
    Name = "Friends Only",
    CurrentValue = false,
    Flag = "FriendsOnly",
    Callback = function(Value)
        getgenv().FriendsOnly = Value
    end,
})

local AutoJoinMapToggle = MainTab:CreateToggle({
    Name = "Auto Join Map",
    CurrentValue = false,
    Flag = "AutoJoinMap",
    Callback = function(Value)
        getgenv().AutoJoinMap = Value
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
    Content = "BUANG HUB - Anime Last Stand",
    Duration = 5,
    Image = "check",
}) 
