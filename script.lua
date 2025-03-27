local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("DuongTuan - Anime Last Stand", "DarkTheme")

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
    }
}

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
    Config.AutoJoin.JoinMode = value
    print("Join Mode set to: "..value)
end)

AutoJoinSection:NewDropdown("Map", "Select map", {"Central City"}, function(value)
    Config.AutoJoin.Map = value
    print("Map set to: "..value)
end)

AutoJoinSection:NewDropdown("Act", "Select act", {"6"}, function(value)
    Config.AutoJoin.Act = value
    print("Act set to: "..value)
end)

AutoJoinSection:NewDropdown("Difficulty", "Select difficulty", {"Normal"}, function(value)
    Config.AutoJoin.Difficulty = value
    print("Difficulty set to: "..value)
end)

AutoJoinSection:NewToggle("Friends Only", "Toggle friends only", function(state)
    Config.AutoJoin.FriendsOnly = state
    print("Friends Only set to: "..tostring(state))
end)

AutoJoinSection:NewToggle("Auto Join Map", "Toggle auto join map", function(state)
    Config.AutoJoin.AutoJoinMap = state
    print("Auto Join Map set to: "..tostring(state))
end)

AutoJoinSection:NewSlider("Auto Start Delay", "Set auto start delay", 60, 0, function(value)
    Config.AutoJoin.AutoStartDelay = value
    print("Auto Start Delay set to: "..value)
end)

AutoJoinSection:NewToggle("Auto Start", "Toggle auto start", function(state)
    Config.AutoJoin.AutoStart = state
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
    Config.AutoChallenge.IgnoreMap = value
    print("Ignore Challenge Map set to: "..value)
end)

AutoChallengeSection:NewDropdown("Ignore Challenge", "Select ignore challenge", {"None"}, function(value)
    Config.AutoChallenge.IgnoreChallenge = value
    print("Ignore Challenge set to: "..value)
end)

-- Main Section
MainSection:NewToggle("Auto Leave", "Toggle auto leave", function(state)
    Config.Main.AutoLeave = state
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
    Config.Main.AutoReplay = state
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
    Config.Main.AutoNext = state
    print("Auto Next set to: "..tostring(state))
end)

MainSection:NewSlider("TP Delay", "Set teleport delay", 60, 0, function(value)
    Config.Main.TPDelay = value
    print("TP Delay set to: "..value.." seconds")
end)

MainSection:NewToggle("Delete Map", "Toggle delete map", function(state)
    Config.Main.DeleteMap = state
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
    -- Thử phương pháp 1: Tìm LobbySpawn trong workspace
    local success = false
    
    -- In ra thông báo
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "DuongTuan Hub",
        Text = "Đang dịch chuyển về lobby...",
        Duration = 2
    })
    
    -- Phương pháp 1: Tìm teleport position trong workspace
    local possibleLobbyNames = {"LobbySpawn", "Lobby", "lobbyspawn", "lobbyPosition", "SpawnLocation", "LobbyLocation"}
    for _, name in pairs(possibleLobbyNames) do
        local lobbyPart = game:GetService("Workspace"):FindFirstChild(name)
        if lobbyPart then
            game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(lobbyPart.CFrame)
            print("Teleported to lobby using method 1 with: " .. name)
            success = true
            break
        end
    end
    
    -- Phương pháp 2: Tìm điểm spawn mặc định
    if not success then
        for _, spawn in pairs(game:GetService("Workspace"):GetDescendants()) do
            if spawn:IsA("SpawnLocation") then
                game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(spawn.CFrame)
                print("Teleported to lobby using method 2")
                success = true
                break
            end
        end
    end
    
    -- Phương pháp 3: Sử dụng remote event (nếu có)
    if not success then
        local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
        if remotes then
            local teleportRemote = remotes:FindFirstChild("TeleportToLobby") or remotes:FindFirstChild("Teleport")
            if teleportRemote then
                teleportRemote:FireServer("Lobby")
                print("Teleported to lobby using method 3")
                success = true
            end
        end
    end
    
    -- Phương pháp 4: Tìm nút teleport lobby trong UI và click
    if not success then
        for _, button in pairs(game:GetService("Players").LocalPlayer.PlayerGui:GetDescendants()) do
            if button:IsA("TextButton") and 
               (button.Text:lower():find("lobby") or button.Text:lower():find("home") or button.Text:lower():find("thoát")) and 
               button.Visible then
                firesignal(button.MouseButton1Click)
                print("Teleported to lobby using method 4")
                success = true
                break
            end
        end
    end
    
    -- Phương pháp 5: Cố gắng teleport đến vị trí 0,0,0 (thường là lobby)
    if not success then
        local rootPart = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = CFrame.new(0, 100, 0) -- Teleport to origin with some height
            print("Teleported to lobby using method 5")
            success = true
        end
    end
    
    if success then
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "DuongTuan Hub",
            Text = "Đã dịch chuyển về lobby thành công!",
            Duration = 3
        })
    else
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "DuongTuan Hub",
            Text = "Không thể dịch chuyển về lobby!",
            Duration = 3
        })
        print("Failed to teleport to lobby")
    end
end)

MainSection:NewToggle("Auto Lobby TP on Time", "Toggle auto lobby TP on time", function(state)
    Config.Main.AutoLobbyTP = state
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
        Config.Main.LobbyTime = time
        print("Auto Lobby Time set to: "..time.." minutes")
    else
        print("Invalid time value")
    end
end)

MainSection:NewToggle("Auto 2x/1.5x Game Speed", "Toggle auto game speed", function(state)
    Config.Main.AutoGameSpeed = state
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
        Config.Main.FOV = newFOV
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
    Config.Main.FOV = 70
    
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
    Config.AutoInfCastle.Type = value
    print("Infinite Castle Type set to: "..value)
end)

AutoInfCastleSection:NewTextBox("Infinite Castle Room", "Set infinite castle room", function(value)
    local room = tonumber(value)
    if room then
        Config.AutoInfCastle.Room = room
        print("Infinite Castle Room set to: "..room)
    else
        print("Invalid room value")
    end
end)

AutoInfCastleSection:NewToggle("Hard Mode Castle", "Toggle hard mode castle", function(state)
    Config.AutoInfCastle.HardMode = state
    print("Hard Mode Castle set to: "..tostring(state))
end)

AutoInfCastleSection:NewToggle("Auto Castle", "Toggle auto castle", function(state)
    Config.AutoInfCastle.AutoCastle = state
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

-- SHOP Tab Content (có thể thêm sau)

-- MISC Tab Content (có thể thêm sau)

-- Thông báo khi script được tải
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "DuongTuan Hub - Anime Last Stand",
    Text = "Script đã được tải thành công!",
    Duration = 5
})

print("Script loaded successfully!")
