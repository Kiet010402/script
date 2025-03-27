local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("DuongTuan - Anime Last Stand", "DarkTheme")

-- Tạo tên file cấu hình
local configFileName = "DuongTuanALS_Config.json"

-- Biến cấu hình
local Config = {
    AutoJoin = {
        Enabled = false,
        JoinMode = "Raids",
        Map = "Central City",
        Act = "6",
        Difficulty = "Normal",
        FriendsOnly = false,
        AutoJoinMap = false,
        AutoStartDelay = 0,
        AutoStart = false
    },
    Main = {
        AutoLeave = false,
        AutoReplay = false,
        AutoNext = false,
        TPDelay = 0,
        DeleteMap = false,
        AutoLobbyTP = false,
        LobbyTime = 40,
        AutoGameSpeed = false,
        FOV = 70, -- Thêm FOV mặc định
        FOVEnabled = false -- Biến để kiểm soát FOV tự động
    },
    AutoChallenge = {
        IgnoreMap = "None",
        IgnoreChallenge = "None"
    },
    AutoInfCastle = {
        Type = "None",
        Room = 0,
        HardMode = false,
        AutoCastle = false
    },
    Shop = {
        -- Auto Summon
        SummonMode = "None",
        SummonBanner = "None",
        SummonUnit = "None",
        SummonGems = 0,
        AutoSummon = false,
        
        -- Auto Fuse
        FuseUnit = "None",
        AutoFuse = false,
        
        -- Auto Sell
        SellRarity = "None",
        AutoSell = false,
        
        -- Auto Sell Portals
        SellPortalSelect = "None",
        SellPortalDifficulty = "None",
        SellPortalMap = "None",
        SellPortalAct = "None",
        AutoSellPortal = false,
        
        -- Auto Buy
        BuyList = "None",
        AutoBuy = false,
        
        -- Auto Roll Trait
        SelectedTraits = "None",
        AutoRoll = false,
        
        -- Summer Event
        SummerUnit = "None"
    }
}

-- Hàm để lưu cấu hình vào file
local function SaveConfig()
    -- Kiểm tra xem writefile có tồn tại không
    if writefile then
        -- Chuyển đổi bảng Config thành chuỗi JSON
        local json = game:GetService("HttpService"):JSONEncode(Config)
        -- Ghi JSON vào file
        writefile(configFileName, json)
        
        print("Đã lưu cấu hình thành công!")
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "DuongTuan Hub",
            Text = "Đã lưu cấu hình thành công!",
            Duration = 2
        })
    else
        print("Không thể lưu cấu hình: writefile không được hỗ trợ")
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "DuongTuan Hub",
            Text = "Không thể lưu cấu hình! (Executor không hỗ trợ)",
            Duration = 2
        })
    end
end

-- Hàm để tải cấu hình từ file
local function LoadConfig()
    -- Kiểm tra xem readfile có tồn tại không và file có tồn tại không
    if readfile and pcall(function() readfile(configFileName) end) then
        -- Đọc file và chuyển đổi từ JSON thành bảng
        local json = readfile(configFileName)
        local success, loadedConfig = pcall(function()
            return game:GetService("HttpService"):JSONDecode(json)
        end)
        
        if success and loadedConfig then
            -- Cập nhật cấu hình từ file đã đọc
            for category, settings in pairs(loadedConfig) do
                if Config[category] then
                    for setting, value in pairs(settings) do
                        if Config[category][setting] ~= nil then
                            Config[category][setting] = value
                        end
                    end
                end
            end
            
            print("Đã tải cấu hình thành công!")
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "DuongTuan Hub",
                Text = "Đã tải cấu hình thành công!",
                Duration = 2
            })
            
            -- Áp dụng cấu hình FOV nếu được bật
            if Config.Main.FOVEnabled and Config.Main.FOV then
                local camera = game:GetService("Workspace").CurrentCamera
                if camera then
                    pcall(function()
                        camera.FieldOfView = Config.Main.FOV
                    end)
                end
            end
            
            return true
        end
    end
    
    print("Không tìm thấy cấu hình hoặc không thể tải")
    return false
end

-- Tải cấu hình khi khởi động script
LoadConfig()

-- Cập nhật cấu hình API
-- Tạo phiên bản mới của function SaveConfig để gọi mỗi khi có thay đổi cài đặt
local function UpdateConfig(category, setting, value)
    if Config[category] and Config[category][setting] ~= nil then
        Config[category][setting] = value
        SaveConfig() -- Lưu cấu hình ngay sau khi thay đổi
    end
end

-- MAIN Tab
local MainTab = Window:NewTab("MAIN")
local FarmTab = Window:NewTab("FARM")
local AutoPlayTab = Window:NewTab("AUTOPLAY+")
local MacroTab = Window:NewTab("MACRO")
local MapsTab = Window:NewTab("M.MAPS")
local ShopTab = Window:NewTab("SHOP")
local MiscTab = Window:NewTab("MISC")

-- Main Tab Sections
local MainSection = MainTab:NewSection("Main")
local AutoJoinSection = MainTab:NewSection("Auto Join")
local AutoChallengeSection = MainTab:NewSection("Auto Challenge")
local AutoInfCastleSection = MainTab:NewSection("Auto Infinite Castle")

-- Auto Join Section
AutoJoinSection:NewDropdown("Join Mode", "Select join mode", {"Raids"}, function(value)
    UpdateConfig("AutoJoin", "JoinMode", value)
    print("Join Mode set to: "..value)
end)

AutoJoinSection:NewDropdown("Map", "Select map", {"Central City"}, function(value)
    UpdateConfig("AutoJoin", "Map", value)
    print("Map set to: "..value)
end)

AutoJoinSection:NewDropdown("Act", "Select act", {"6"}, function(value)
    UpdateConfig("AutoJoin", "Act", value)
    print("Act set to: "..value)
end)

AutoJoinSection:NewDropdown("Difficulty", "Select difficulty", {"Normal"}, function(value)
    UpdateConfig("AutoJoin", "Difficulty", value)
    print("Difficulty set to: "..value)
end)

AutoJoinSection:NewToggle("Friends Only", "Toggle friends only", function(state)
    UpdateConfig("AutoJoin", "FriendsOnly", state)
    print("Friends Only set to: "..tostring(state))
end)

AutoJoinSection:NewToggle("Auto Join Map", "Toggle auto join map", function(state)
    UpdateConfig("AutoJoin", "AutoJoinMap", state)
    print("Auto Join Map set to: "..tostring(state))
end)

AutoJoinSection:NewSlider("Auto Start Delay", "Set auto start delay", 60, 0, function(value)
    UpdateConfig("AutoJoin", "AutoStartDelay", value)
    print("Auto Start Delay set to: "..value)
end)

AutoJoinSection:NewToggle("Auto Start", "Toggle auto start", function(state)
    UpdateConfig("AutoJoin", "AutoStart", state)
    print("Auto Start set to: "..tostring(state))
    
    -- Kích hoạt chức năng Auto Start
    if state then
        -- Tạo một coroutine để chạy song song với game
        spawn(function()
            while Config.AutoJoin.AutoStart do
                -- Logic để tự động khởi động game
                print("Auto Starting...")
                
                -- Kiểm tra xem người chơi có đang ở trong lobby không
                local isInLobby = (game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("LobbyGui") ~= nil)
                
                if isInLobby and Config.AutoJoin.AutoJoinMap then
                    -- Tìm menu chọn map và nhấn nút join
                    for _, button in pairs(game:GetService("Players").LocalPlayer.PlayerGui:GetDescendants()) do
                        if button:IsA("TextButton") and button.Text:lower():find("join") and button.Visible then
                            -- Nhấn nút join
                            firesignal(button.MouseButton1Click)
                            print("Join button clicked")
                            
                            -- Đợi theo thời gian delay đã cài đặt
                            wait(Config.AutoJoin.AutoStartDelay)
                            
                            -- Tìm nút Start
                            for _, startButton in pairs(game:GetService("Players").LocalPlayer.PlayerGui:GetDescendants()) do
                                if startButton:IsA("TextButton") and startButton.Text:lower():find("start") and startButton.Visible then
                                    -- Nhấn nút Start
                                    firesignal(startButton.MouseButton1Click)
                                    print("Start button clicked")
                                    break
                                end
                            end
                            break
                        end
                    end
                end
                
                wait(1) -- Đợi 1 giây trước khi kiểm tra lại
            end
        end)
    end
end)

-- Auto Challenge Section
AutoChallengeSection:NewDropdown("Ignore Challenge Map", "Select ignore challenge map", {"None"}, function(value)
    UpdateConfig("AutoChallenge", "IgnoreMap", value)
    print("Ignore Challenge Map set to: "..value)
end)

AutoChallengeSection:NewDropdown("Ignore Challenge", "Select ignore challenge", {"None"}, function(value)
    UpdateConfig("AutoChallenge", "IgnoreChallenge", value)
    print("Ignore Challenge set to: "..value)
end)

-- Main Section
MainSection:NewToggle("Auto Leave", "Toggle auto leave", function(state)
    UpdateConfig("Main", "AutoLeave", state)
    print("Auto Leave set to: "..tostring(state))
    
    if state then
        spawn(function()
            while Config.Main.AutoLeave do
                -- Kiểm tra xem game đã kết thúc chưa
                local gameOver = false
                -- Tìm màn hình kết thúc game
                for _, ui in pairs(game:GetService("Players").LocalPlayer.PlayerGui:GetDescendants()) do
                    if ui:IsA("Frame") and (ui.Name:lower():find("result") or ui.Name:lower():find("gameover")) and ui.Visible then
                        gameOver = true
                        break
                    end
                end
                
                if gameOver then
                    -- Tìm nút để rời game
                    for _, button in pairs(game:GetService("Players").LocalPlayer.PlayerGui:GetDescendants()) do
                        if button:IsA("TextButton") and (button.Text:lower():find("leave") or button.Text:lower():find("quit")) and button.Visible then
                            firesignal(button.MouseButton1Click)
                            print("Leave button clicked")
                            break
                        end
                    end
                end
                
                wait(1)
            end
        end)
    end
end)

MainSection:NewToggle("Auto Replay", "Toggle auto replay", function(state)
    UpdateConfig("Main", "AutoReplay", state)
    print("Auto Replay set to: "..tostring(state))
    
    if state then
        spawn(function()
            while Config.Main.AutoReplay do
                -- Logic cho Auto Replay
                -- Tương tự như Auto Leave nhưng tìm nút Replay
                wait(1)
            end
        end)
    end
end)

MainSection:NewToggle("Auto Next", "Toggle auto next", function(state)
    UpdateConfig("Main", "AutoNext", state)
    print("Auto Next set to: "..tostring(state))
end)

MainSection:NewSlider("TP Delay", "Set teleport delay", 60, 0, function(value)
    UpdateConfig("Main", "TPDelay", value)
    print("TP Delay set to: "..value.." seconds")
end)

MainSection:NewToggle("Delete Map", "Toggle delete map", function(state)
    UpdateConfig("Main", "DeleteMap", state)
    print("Delete Map set to: "..tostring(state))
    
    if state then
        -- Xóa các phần tử map để tăng FPS
        spawn(function()
            while Config.Main.DeleteMap do
                for _, v in pairs(game.Workspace:GetDescendants()) do
                    if v:IsA("Model") and (v.Name:lower():find("tree") or v.Name:lower():find("grass") or v.Name:lower():find("bush")) then
                        v:Destroy()
                    end
                end
                wait(5) -- Đợi 5 giây trước khi xóa lại
            end
        end)
    end
end)

MainSection:NewButton("Teleport To Lobby", "Teleport to lobby", function()
    local success = false
    
    -- In ra thông báo
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "DuongTuan Hub",
        Text = "Đang dịch chuyển về điểm ban đầu...",
        Duration = 2
    })
    
    -- Phương pháp 1: Teleport đến vị trí spawn mặc định 
    local spawnLocation = game:GetService("Workspace"):FindFirstChildOfClass("SpawnLocation")
    if spawnLocation then
        game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(spawnLocation.CFrame + Vector3.new(0, 5, 0))
        print("Đã teleport đến vị trí spawn mặc định")
        success = true
    end
    
    -- Phương pháp 2: Tìm vị trí spawn với tên cụ thể
    if not success then
        local possibleSpawnNames = {"SpawnLocation", "Spawn", "PlayerSpawn", "StartLocation", "PlayerStart"}
        for _, name in pairs(possibleSpawnNames) do
            local spawnPart = game:GetService("Workspace"):FindFirstChild(name)
            if spawnPart then
                game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(spawnPart.CFrame + Vector3.new(0, 5, 0))
                print("Đã teleport đến " .. name)
                success = true
                break
            end
        end
    end
    
    -- Phương pháp 3: Teleport đến vị trí 0,0,0 nếu không tìm thấy spawn point
    if not success then
        local rootPart = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = CFrame.new(0, 100, 0) -- Teleport to origin with some height
            print("Đã teleport đến vị trí 0,0,0")
            success = true
        end
    end
    
    if success then
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "DuongTuan Hub",
            Text = "Đã dịch chuyển về điểm ban đầu thành công!",
            Duration = 3
        })
    else
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "DuongTuan Hub",
            Text = "Không thể dịch chuyển về điểm ban đầu!",
            Duration = 3
        })
        print("Không thể teleport về điểm ban đầu")
    end
end)

MainSection:NewToggle("Auto Lobby TP on Time", "Toggle auto lobby TP on time", function(state)
    UpdateConfig("Main", "AutoLobbyTP", state)
    print("Auto Lobby TP on Time set to: "..tostring(state))
    
    if state then
        spawn(function()
            while Config.Main.AutoLobbyTP do
                -- Đếm ngược thời gian rồi teleport về lobby
                local timeToWait = Config.Main.LobbyTime * 60 -- Chuyển đổi phút sang giây
                wait(timeToWait)
                
                if Config.Main.AutoLobbyTP then
                    -- Teleport về lobby
                    local lobbyLocation = game:GetService("Workspace"):FindFirstChild("LobbySpawn")
                    if lobbyLocation then
                        game:GetService("Players").LocalPlayer.Character:SetPrimaryPartCFrame(lobbyLocation.CFrame)
                        print("Auto teleported to lobby after "..Config.Main.LobbyTime.." minutes")
                    end
                end
            end
        end)
    end
end)

MainSection:NewTextBox("Auto Lobby Time", "Set auto lobby time", function(value)
    local time = tonumber(value)
    if time then
        UpdateConfig("Main", "LobbyTime", time)
        print("Auto Lobby Time set to: "..time.." minutes")
    else
        print("Invalid time value")
    end
end)

MainSection:NewToggle("Auto 2x/1.5x Game Speed", "Toggle auto game speed", function(state)
    UpdateConfig("Main", "AutoGameSpeed", state)
    print("Auto Game Speed set to: "..tostring(state))
    
    if state then
        spawn(function()
            while Config.Main.AutoGameSpeed do
                -- Tìm nút tăng tốc độ game và nhấn
                for _, button in pairs(game:GetService("Players").LocalPlayer.PlayerGui:GetDescendants()) do
                    if button:IsA("TextButton") and (button.Text:find("2x") or button.Text:find("1.5x")) and button.Visible then
                        firesignal(button.MouseButton1Click)
                        print("Game speed button clicked")
                        break
                    end
                end
                wait(5) -- Kiểm tra mỗi 5 giây
            end
        end)
    end
end)

-- Thêm Buttons để điều chỉnh FOV thay vì slider
MainSection:NewLabel("Camera FOV")

-- Thêm TextBox để nhập giá trị FOV
MainSection:NewTextBox("Nhập FOV (1-120)", "Nhập giá trị FOV (zoom) từ 1-120", function(value)
    local newFOV = tonumber(value)
    if newFOV and newFOV >= 1 and newFOV <= 120 then
        UpdateConfig("Main", "FOV", newFOV)
        print("FOV value set to: "..newFOV)
        
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "DuongTuan Hub",
            Text = "Giá trị FOV đã đặt: " .. newFOV .. " (Nhấn Kích hoạt FOV để áp dụng)",
            Duration = 2
        })
    else
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "DuongTuan Hub",
            Text = "Giá trị FOV không hợp lệ. Hãy nhập số từ 1-120",
            Duration = 2
        })
        print("Invalid FOV value")
    end
end)

-- Thêm Button để bật/tắt FOV tự động
MainSection:NewButton("Kích hoạt FOV", "Áp dụng giá trị FOV đã cài đặt", function()
    UpdateConfig("Main", "FOVEnabled", true)
    local camera = game:GetService("Workspace").CurrentCamera
    if camera then
        -- Áp dụng FOV đã cài đặt
        pcall(function()
            local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local tween = game:GetService("TweenService"):Create(camera, tweenInfo, {FieldOfView = Config.Main.FOV})
            tween:Play()
        end)
        
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "DuongTuan Hub",
            Text = "FOV đã được đặt thành: " .. Config.Main.FOV,
            Duration = 2
        })
    end
end)

-- Thêm Button để reset FOV
MainSection:NewButton("Reset FOV", "Đặt lại FOV về giá trị mặc định (70)", function()
    UpdateConfig("Main", "FOV", 70)
    UpdateConfig("Main", "FOVEnabled", false)
    
    -- Reset camera về FOV mặc định
    local camera = game:GetService("Workspace").CurrentCamera
    if camera then
        pcall(function()
            local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local tween = game:GetService("TweenService"):Create(camera, tweenInfo, {FieldOfView = 70})
            tween:Play()
        end)
    end
    
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "DuongTuan Hub",
        Text = "FOV đã được reset về mặc định (70)",
        Duration = 2
    })
    
    print("FOV reset to default (70)")
end)

-- Auto Infinite Castle Section
AutoInfCastleSection:NewDropdown("Infinite Castle Type", "Select infinite castle type", {"None"}, function(value)
    UpdateConfig("AutoInfCastle", "Type", value)
    print("Infinite Castle Type set to: "..value)
end)

AutoInfCastleSection:NewTextBox("Infinite Castle Room", "Set infinite castle room", function(value)
    local room = tonumber(value)
    if room then
        UpdateConfig("AutoInfCastle", "Room", room)
        print("Infinite Castle Room set to: "..room)
    else
        print("Invalid room value")
    end
end)

AutoInfCastleSection:NewToggle("Hard Mode Castle", "Toggle hard mode castle", function(state)
    UpdateConfig("AutoInfCastle", "HardMode", state)
    print("Hard Mode Castle set to: "..tostring(state))
end)

AutoInfCastleSection:NewToggle("Auto Castle", "Toggle auto castle", function(state)
    UpdateConfig("AutoInfCastle", "AutoCastle", state)
    print("Auto Castle set to: "..tostring(state))
    
    if state then
        spawn(function()
            while Config.AutoInfCastle.AutoCastle do
                -- Logic cho Auto Castle
                print("Auto Castle running...")
                wait(1)
            end
        end)
    end
end)

-- FARM Tab Content (có thể thêm sau)

-- AUTOPLAY+ Tab Content (có thể thêm sau)

-- MACRO Tab Content (có thể thêm sau)

-- M.MAPS Tab Content (có thể thêm sau)

-- SHOP Tab Content
-- Shop Tab Sections
local AutoSummonSection = ShopTab:NewSection("Auto Summon")
local AutoFuseSection = ShopTab:NewSection("Auto Fuse")
local AutoSellSection = ShopTab:NewSection("Auto Sell")
local AutoSellPortalSection = ShopTab:NewSection("Auto Sell Portals")
local AutoBuySection = ShopTab:NewSection("Auto Buy")
local AutoRollTraitSection = ShopTab:NewSection("Auto Roll Trait")
local SummerEventSection = ShopTab:NewSection("Summer Event")

-- Auto Summon Section
AutoSummonSection:NewDropdown("Summon Mode", "Select summon mode", {"Normal", "Special", "Event"}, function(value)
    UpdateConfig("Shop", "SummonMode", value)
    print("Summon Mode set to: "..value)
end)

AutoSummonSection:NewDropdown("Summon Banner", "Select summon banner", {"Standard", "Premium"}, function(value)
    UpdateConfig("Shop", "SummonBanner", value)
    print("Summon Banner set to: "..value)
end)

AutoSummonSection:NewDropdown("Summon Unit", "Select unit to summon", {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical"}, function(value)
    UpdateConfig("Shop", "SummonUnit", value)
    print("Summon Unit set to: "..value)
end)

AutoSummonSection:NewTextBox("Summon Gems", "Enter number of gems to use", function(value)
    local gems = tonumber(value)
    if gems then
        UpdateConfig("Shop", "SummonGems", gems)
        print("Summon Gems set to: "..gems)
    else
        print("Invalid gems value")
    end
end)

AutoSummonSection:NewToggle("Auto Summon", "Toggle auto summon", function(state)
    UpdateConfig("Shop", "AutoSummon", state)
    print("Auto Summon set to: "..tostring(state))
    
    if state then
        spawn(function()
            while Config.Shop.AutoSummon do
                -- Logic cho Auto Summon
                print("Auto Summon running...")
                
                -- Tìm nút summon và click
                for _, button in pairs(game:GetService("Players").LocalPlayer.PlayerGui:GetDescendants()) do
                    if button:IsA("TextButton") and button.Text:lower():find("summon") and button.Visible then
                        firesignal(button.MouseButton1Click)
                        print("Summon button clicked")
                        break
                    end
                end
                
                wait(2) -- Đợi 2 giây trước khi summon tiếp
            end
        end)
    end
end)

-- Auto Fuse Section
AutoFuseSection:NewDropdown("Fuse Unit", "Select unit to fuse", {"Common", "Uncommon", "Rare", "Epic", "Legendary"}, function(value)
    UpdateConfig("Shop", "FuseUnit", value)
    print("Fuse Unit set to: "..value)
end)

AutoFuseSection:NewToggle("Auto Fuse", "Toggle auto fuse", function(state)
    UpdateConfig("Shop", "AutoFuse", state)
    print("Auto Fuse set to: "..tostring(state))
    
    if state then
        spawn(function()
            while Config.Shop.AutoFuse do
                -- Logic cho Auto Fuse
                print("Auto Fuse running...")
                
                -- Tìm nút fuse và click
                for _, button in pairs(game:GetService("Players").LocalPlayer.PlayerGui:GetDescendants()) do
                    if button:IsA("TextButton") and button.Text:lower():find("fuse") and button.Visible then
                        firesignal(button.MouseButton1Click)
                        print("Fuse button clicked")
                        break
                    end
                end
                
                wait(2) -- Đợi 2 giây trước khi fuse tiếp
            end
        end)
    end
end)

-- Auto Sell Section
AutoSellSection:NewDropdown("Sell Rarity", "Select rarity to auto sell", {"Common", "Uncommon", "Rare", "Epic", "Legendary", "All"}, function(value)
    UpdateConfig("Shop", "SellRarity", value)
    print("Sell Rarity set to: "..value)
end)

AutoSellSection:NewToggle("Auto Sell", "Toggle auto sell", function(state)
    UpdateConfig("Shop", "AutoSell", state)
    print("Auto Sell set to: "..tostring(state))
    
    if state then
        spawn(function()
            while Config.Shop.AutoSell do
                -- Logic cho Auto Sell
                print("Auto Sell running...")
                
                -- Tìm nút sell và click
                for _, button in pairs(game:GetService("Players").LocalPlayer.PlayerGui:GetDescendants()) do
                    if button:IsA("TextButton") and button.Text:lower():find("sell") and button.Visible then
                        firesignal(button.MouseButton1Click)
                        print("Sell button clicked")
                        break
                    end
                end
                
                wait(2) -- Đợi 2 giây trước khi sell tiếp
            end
        end)
    end
end)

-- Auto Sell Portal Section
AutoSellPortalSection:NewDropdown("Sell Portal Select", "Select portal to sell", {"None"}, function(value)
    UpdateConfig("Shop", "SellPortalSelect", value)
    print("Sell Portal Select set to: "..value)
end)

AutoSellPortalSection:NewDropdown("Sell Portal Difficulty", "Select portal difficulty", {"Normal", "Hard", "Nightmare"}, function(value)
    UpdateConfig("Shop", "SellPortalDifficulty", value)
    print("Sell Portal Difficulty set to: "..value)
end)

AutoSellPortalSection:NewDropdown("Sell Portal Map", "Select portal map", {"Central City"}, function(value)
    UpdateConfig("Shop", "SellPortalMap", value)
    print("Sell Portal Map set to: "..value)
end)

AutoSellPortalSection:NewDropdown("Sell Portal Act", "Select portal act", {"1", "2", "3", "4", "5", "6"}, function(value)
    UpdateConfig("Shop", "SellPortalAct", value)
    print("Sell Portal Act set to: "..value)
end)

AutoSellPortalSection:NewToggle("Auto Sell Portal", "Toggle auto sell portal", function(state)
    UpdateConfig("Shop", "AutoSellPortal", state)
    print("Auto Sell Portal set to: "..tostring(state))
    
    if state then
        spawn(function()
            while Config.Shop.AutoSellPortal do
                -- Logic cho Auto Sell Portal
                print("Auto Sell Portal running...")
                
                -- Tìm nút sell portal và click
                for _, button in pairs(game:GetService("Players").LocalPlayer.PlayerGui:GetDescendants()) do
                    if button:IsA("TextButton") and button.Text:lower():find("sell portal") and button.Visible then
                        firesignal(button.MouseButton1Click)
                        print("Sell Portal button clicked")
                        break
                    end
                end
                
                wait(2) -- Đợi 2 giây trước khi sell portal tiếp
            end
        end)
    end
end)

-- Auto Buy Section
AutoBuySection:NewDropdown("Buy List", "Select items to buy", {"Summon Ticket", "XP Potion", "Gold Potion"}, function(value)
    UpdateConfig("Shop", "BuyList", value)
    print("Buy List set to: "..value)
end)

AutoBuySection:NewToggle("Auto Buy", "Toggle auto buy", function(state)
    UpdateConfig("Shop", "AutoBuy", state)
    print("Auto Buy set to: "..tostring(state))
    
    if state then
        spawn(function()
            while Config.Shop.AutoBuy do
                -- Logic cho Auto Buy
                print("Auto Buy running...")
                
                -- Tìm nút buy và click
                for _, button in pairs(game:GetService("Players").LocalPlayer.PlayerGui:GetDescendants()) do
                    if button:IsA("TextButton") and button.Text:lower():find("buy") and button.Visible then
                        firesignal(button.MouseButton1Click)
                        print("Buy button clicked")
                        break
                    end
                end
                
                wait(2) -- Đợi 2 giây trước khi buy tiếp
            end
        end)
    end
end)

-- Auto Roll Trait Section
AutoRollTraitSection:NewDropdown("Selected Traits", "Select traits to roll for", {"Damage", "Range", "Speed", "Defense"}, function(value)
    UpdateConfig("Shop", "SelectedTraits", value)
    print("Selected Traits set to: "..value)
end)

AutoRollTraitSection:NewToggle("Auto Roll", "Toggle auto roll traits", function(state)
    UpdateConfig("Shop", "AutoRoll", state)
    print("Auto Roll set to: "..tostring(state))
    
    if state then
        spawn(function()
            while Config.Shop.AutoRoll do
                -- Logic cho Auto Roll Trait
                print("Auto Roll Trait running...")
                
                -- Tìm nút roll và click
                for _, button in pairs(game:GetService("Players").LocalPlayer.PlayerGui:GetDescendants()) do
                    if button:IsA("TextButton") and button.Text:lower():find("roll") and button.Visible then
                        firesignal(button.MouseButton1Click)
                        print("Roll button clicked")
                        break
                    end
                end
                
                wait(2) -- Đợi 2 giây trước khi roll tiếp
            end
        end)
    end
end)

-- Summer Event Section
SummerEventSection:NewDropdown("Summer Unit", "Select summer event unit", {"None"}, function(value)
    UpdateConfig("Shop", "SummerUnit", value)
    print("Summer Unit set to: "..value)
end)

-- MISC Tab Content
local MiscSection = MiscTab:NewSection("Cấu hình")

-- Thêm nút lưu cấu hình
MiscSection:NewButton("Lưu cấu hình", "Lưu tất cả cài đặt hiện tại", function()
    SaveConfig()
end)

-- Thêm nút tải cấu hình
MiscSection:NewButton("Tải cấu hình", "Tải cài đặt đã lưu", function()
    if LoadConfig() then
        -- Cập nhật lại UI hiển thị nếu cần
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "DuongTuan Hub",
            Text = "Đã tải và áp dụng cấu hình!",
            Duration = 2
        })
    else
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "DuongTuan Hub",
            Text = "Không tìm thấy cấu hình đã lưu!",
            Duration = 2
        })
    end
end)

-- Thông báo khi script được tải
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "DuongTuan Hub - Anime Last Stand",
    Text = "Script đã được tải thành công!",
    Duration = 5
})

-- Thông báo nếu tải được cấu hình
if readfile and pcall(function() readfile(configFileName) end) then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "DuongTuan Hub",
        Text = "Đã tải cấu hình đã lưu!",
        Duration = 3
    })
end

print("Script loaded successfully!")
