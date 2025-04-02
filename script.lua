-- Arise Crossover - Discord Webhook cho AFKRewards
local allowedPlaceId = 87039211657390 -- PlaceId mà script được phép chạy
local afkPlaceId = 116614712661486 -- PlaceId của khu vực AFK

-- Kiểm tra PlaceID ngay từ đầu để chỉ chạy trên đúng game
if game.PlaceId ~= allowedPlaceId and game.PlaceId ~= afkPlaceId then
    local placeName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name or "Không xác định"
    print("❌ Script Arise Webhook chỉ hoạt động trên game với PlaceID: " .. allowedPlaceId .. " hoặc khu vực AFK: " .. afkPlaceId)
    print("❌ Game hiện tại: " .. placeName .. " (PlaceID: " .. game.PlaceId .. ")")
    return -- Dừng script ngay lập tức
end

-- Thông báo khu vực hiện tại
if game.PlaceId == allowedPlaceId then
    print("✅ Đang chạy script trong game chính")
elseif game.PlaceId == afkPlaceId then
    print("✅ Đang chạy script trong khu vực AFK")
end

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

-- Khởi tạo Rayfield UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Sử dụng tên người chơi để tạo file cấu hình riêng cho từng tài khoản
local playerName = Player.Name:gsub("[^%w_]", "_") -- Loại bỏ ký tự đặc biệt
local CONFIG_FILE = "AriseWebhook_" .. playerName .. ".json"

-- Biến kiểm soát trạng thái script
local scriptRunning = true

-- Biến đánh dấu đã ping ZIRU G
local hasAlreadyPingedZiruG = false

-- Đọc cấu hình từ file (nếu có)
local function loadConfig()
    local success, result = pcall(function()
        if readfile and isfile and isfile(CONFIG_FILE) then
            return HttpService:JSONDecode(readfile(CONFIG_FILE))
        end
        return nil
    end)
    
    if success and result then
        print("Đã tải cấu hình từ file cho tài khoản " .. playerName)
        print("Auto TP từ config: " .. tostring(result.AUTO_TP_TO_AFK))
        return result
    else
        print("Không tìm thấy file cấu hình cho tài khoản " .. playerName)
        return nil
    end
end

-- Lưu cấu hình xuống file
local function saveConfig(config)
    local success, err = pcall(function()
        if writefile then
            writefile(CONFIG_FILE, HttpService:JSONEncode(config))
            return true
        end
        return false
    end)
    
    if success then
        print("Đã lưu cấu hình vào file " .. CONFIG_FILE)
        return true
    else
        warn("Lỗi khi lưu cấu hình: " .. tostring(err))
        return false
    end
end

-- Tắt hoàn toàn script (định nghĩa hàm này trước khi được gọi)
local function shutdownScript()
    print("Đang tắt script Arise Webhook...")
    scriptRunning = false
    
    -- Lưu cấu hình trước khi tắt
    saveConfig(CONFIG)
    
    -- Hủy bỏ tất cả các kết nối sự kiện (nếu có)
    for _, connection in pairs(connections or {}) do
        if typeof(connection) == "RBXScriptConnection" and connection.Connected then
            connection:Disconnect()
        end
    end
    
    -- Đóng cửa sổ Rayfield
    Rayfield:Destroy()
    
    print("Script Arise Webhook đã tắt hoàn toàn")
end

-- Cấu hình Webhook Discord của bạn
local WEBHOOK_URL = "YOUR_URL" -- Giá trị mặc định

-- Tải cấu hình từ file (nếu có)
local savedConfig = loadConfig()
if savedConfig then
    if savedConfig.WEBHOOK_URL then
        WEBHOOK_URL = savedConfig.WEBHOOK_URL
        print("Đã tải URL webhook từ cấu hình: " .. WEBHOOK_URL:sub(1, 30) .. "...")
    end
    
    -- Chỉ cập nhật các giá trị khác từ savedConfig nếu chúng tồn tại
    local CONFIG_DEFAULTS = {
        WEBHOOK_URL = WEBHOOK_URL,
        WEBHOOK_COOLDOWN = 3,
        SHOW_UI = true,
        UI_POSITION = UDim2.new(0.7, 0, 0.05, 0),
        ACCOUNT_NAME = playerName,
        AUTO_TP_TO_AFK = false,
        TELEPORT_COOLDOWN = 30
    }
    
    -- Tạo đối tượng CONFIG bằng cách gộp từ mặc định và giá trị đã lưu
    CONFIG = {}
    for key, value in pairs(CONFIG_DEFAULTS) do
        CONFIG[key] = (savedConfig[key] ~= nil) and savedConfig[key] or value
    end
    
    print("Trạng thái Auto TP từ file config: " .. tostring(CONFIG.AUTO_TP_TO_AFK))
else
    -- Tùy chọn định cấu hình mặc định nếu không có file
    CONFIG = {
        WEBHOOK_URL = WEBHOOK_URL,
        WEBHOOK_COOLDOWN = 3,
        SHOW_UI = true,
        UI_POSITION = UDim2.new(0.7, 0, 0.05, 0),
        ACCOUNT_NAME = playerName,
        AUTO_TP_TO_AFK = false,
        TELEPORT_COOLDOWN = 30
    }
end

-- Lưu cấu hình hiện tại
saveConfig(CONFIG)

-- Lưu trữ phần thưởng đã nhận để tránh gửi trùng lặp
local receivedRewards = {}

-- Theo dõi tổng phần thưởng
local totalRewards = {}

-- Lưu trữ số lượng item đã kiểm tra từ RECEIVED
local playerItems = {}

-- Cooldown giữa các lần gửi webhook (giây)
local WEBHOOK_COOLDOWN = CONFIG.WEBHOOK_COOLDOWN
local lastWebhookTime = 0

-- Đang xử lý một phần thưởng (tránh xử lý đồng thời)
local isProcessingReward = false

-- Lưu danh sách các kết nối sự kiện để có thể ngắt kết nối khi tắt script
local connections = {}

-- Tạo khai báo trước các hàm để tránh lỗi gọi nil
local findRewardsUI
local findReceivedFrame
local findNewRewardNotification
local checkNewRewards
local checkReceivedRewards
local readActualItemQuantities
local sendTestWebhook

-- Khởi tạo Window Rayfield
local Window = Rayfield:CreateWindow({
    Name = "Arise Webhook - " .. playerName,
    LoadingTitle = "Arise Crossover",
    LoadingSubtitle = "by DuongTuan",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "AriseWebhook",
        FileName = "AriseWebhook_" .. playerName
    },
    KeySystem = false
})

-- Tạo Tab chính
local MainTab = Window:CreateTab("Webhook", 4483362458) -- Sử dụng icon mặc định

-- Tạo Input cho URL Webhook
local WebhookInput = MainTab:CreateInput({
    Name = "Discord Webhook URL",
    PlaceholderText = "Nhập URL webhook Discord...",
    RemoveTextAfterFocusLost = false,
    CurrentValue = CONFIG.WEBHOOK_URL ~= "YOUR_URL" and CONFIG.WEBHOOK_URL or "",
    Flag = "WebhookURL",
    Callback = function(Text)
        if Text ~= "" and Text ~= CONFIG.WEBHOOK_URL then
            CONFIG.WEBHOOK_URL = Text
            WEBHOOK_URL = Text -- Cập nhật biến toàn cục
            
            -- Lưu vào file cấu hình
            if saveConfig(CONFIG) then
                Rayfield:Notify({
                    Title = "Thành công",
                    Content = "Đã lưu URL mới cho " .. playerName,
                    Duration = 3,
                    Image = "check", -- Lucide icon
                })
            else
                Rayfield:Notify({
                    Title = "Lưu ý",
                    Content = "Đã lưu URL mới (không lưu được file)",
                    Duration = 3,
                    Image = "alert-triangle", -- Lucide icon
                })
            end
        end
    end,
})

-- Tạo Slider cho Cooldown
local CooldownSlider = MainTab:CreateSlider({
    Name = "Thời gian cooldown giữa các webhook",
    Range = {1, 10},
    Increment = 1,
    Suffix = "giây",
    CurrentValue = CONFIG.WEBHOOK_COOLDOWN,
    Flag = "WebhookCooldown",
    Callback = function(Value)
        CONFIG.WEBHOOK_COOLDOWN = Value
        WEBHOOK_COOLDOWN = Value
        saveConfig(CONFIG)
    end,
})

-- Tạo nút Test Webhook
local TestButton = MainTab:CreateButton({
    Name = "Kiểm tra kết nối Webhook",
    Callback = function()
        -- Hiển thị thông báo đang kiểm tra
        Rayfield:Notify({
            Title = "Đang kiểm tra",
            Content = "Đang gửi webhook thử nghiệm...",
            Duration = 2,
            Image = "loader", -- Lucide icon
        })
        
        -- Thử gửi webhook kiểm tra
        local success = sendTestWebhook("Kiểm tra kết nối từ Arise Crossover Rewards Tracker")
        
        if success then
            Rayfield:Notify({
                Title = "Thành công",
                Content = "Kiểm tra webhook thành công!",
                Duration = 3,
                Image = "check", -- Lucide icon
            })
        else
            Rayfield:Notify({
                Title = "Lỗi",
                Content = "Kiểm tra webhook thất bại, vui lòng kiểm tra URL!",
                Duration = 5,
                Image = "x", -- Lucide icon
            })
        end
    end,
})

-- Tạo Toggle hiển thị/ẩn UI
local UIToggle = MainTab:CreateToggle({
    Name = "Hiển thị UI",
    CurrentValue = CONFIG.SHOW_UI,
    Flag = "ShowUI",
    Callback = function(Value)
        CONFIG.SHOW_UI = Value
        saveConfig(CONFIG)
    end,
})

-- Tạo Tab thông tin phần thưởng
local RewardsTab = Window:CreateTab("Phần thưởng", "gift") -- Sử dụng icon Lucide

-- Hiển thị thông tin tổng phần thưởng
local RewardsInfo = RewardsTab:CreateSection("Thông tin phần thưởng")

-- Text hiển thị tổng phần thưởng (sẽ được cập nhật)
local TotalRewardsText = ""

-- Tạo một paragraph để hiển thị tổng phần thưởng
local TotalRewardsLabel = RewardsTab:CreateParagraph({
    Title = "Tổng phần thưởng hiện có",
    Content = "Đang tải thông tin phần thưởng..."
})

-- Tạo button để làm mới thông tin phần thưởng với xử lý lỗi
local RefreshButton = RewardsTab:CreateButton({
    Name = "Làm mới thông tin phần thưởng",
    Callback = function()
        -- Đọc số lượng item hiện tại với xử lý lỗi
        pcall(function()
            readActualItemQuantities()
        end)
        
        -- Cập nhật thông tin hiển thị với xử lý lỗi
        pcall(function()
            local rewardsText = getTotalRewardsText()
            TotalRewardsText = rewardsText
            
            if TotalRewardsLabel then
                TotalRewardsLabel:Set({
                    Title = "Tổng phần thưởng hiện có", 
                    Content = rewardsText
                })
            end
            
            Rayfield:Notify({
                Title = "Đã làm mới",
                Content = "Đã cập nhật thông tin phần thưởng",
                Duration = 2,
                Image = "refresh-cw", -- Lucide icon
            })
        end)
    end,
})

-- Tạo button để xóa hết phần thưởng đã lưu
local ClearButton = RewardsTab:CreateButton({
    Name = "Xóa thông tin phần thưởng đã lưu",
    Callback = function()
        -- Xóa hết thông tin phần thưởng đã lưu
        receivedRewards = {}
        totalRewards = {}
        playerItems = {}
        
        -- Cập nhật lại thông tin hiển thị
        TotalRewardsLabel:Set({
            Title = "Tổng phần thưởng hiện có",
            Content = "Đã xóa thông tin phần thưởng"
        })
        
        Rayfield:Notify({
            Title = "Đã xóa",
            Content = "Đã xóa toàn bộ thông tin phần thưởng đã lưu",
            Duration = 3,
            Image = "trash-2", -- Lucide icon
        })
    end,
})

-- Tab Teleport
local TeleportTab = Window:CreateTab("Teleport", "navigation") -- Sử dụng icon Lucide cho teleport

-- Lấy lại cài đặt từ Global sau khi teleport
local function loadGlobalSettings()
    if _G and _G.AriseWebhookSettings then
        local settings = _G.AriseWebhookSettings
        CONFIG.AUTO_TP_TO_AFK = settings.AUTO_TP_TO_AFK
        
        -- Cập nhật các cài đặt khác nếu có
        if settings.WEBHOOK_URL then CONFIG.WEBHOOK_URL = settings.WEBHOOK_URL end
        if settings.WEBHOOK_COOLDOWN then CONFIG.WEBHOOK_COOLDOWN = settings.WEBHOOK_COOLDOWN end
        if settings.TELEPORT_COOLDOWN then CONFIG.TELEPORT_COOLDOWN = settings.TELEPORT_COOLDOWN end
        
        -- Cập nhật UI
        if AutoTPToggle then
            -- Sử dụng pcall để tránh lỗi khi gọi
            pcall(function()
                AutoTPToggle:Set(CONFIG.AUTO_TP_TO_AFK)
            end)
        end
        
        -- Lưu cấu hình
        saveConfig(CONFIG)
        
        -- Xóa cài đặt toàn cục sau khi đã sử dụng
        _G.AriseWebhookSettings = nil
    end
end

-- Tạo section thông tin
local TeleportInfo = TeleportTab:CreateSection("Teleport to AFK Area")

-- Tạo toggle cho Auto TP to AFK
local AutoTPToggle = TeleportTab:CreateToggle({
    Name = "Auto TP to AFK",
    CurrentValue = CONFIG.AUTO_TP_TO_AFK,
    Flag = "AutoTPToAFK",
    Callback = function(Value)
        print("Toggle Auto TP được thay đổi: " .. tostring(Value))
        CONFIG.AUTO_TP_TO_AFK = Value
        saveConfig(CONFIG)
        
        if Value then
            Rayfield:Notify({
                Title = "Auto TP đã bật",
                Content = "Sẽ tự động teleport sau " .. CONFIG.TELEPORT_COOLDOWN .. " giây",
                Duration = 5,
                Image = "navigation", -- Lucide icon
            })
            
            -- Bắt đầu quá trình teleport
            startAutoTeleport()
        else
            Rayfield:Notify({
                Title = "Auto TP đã tắt",
                Content = "Đã hủy tự động teleport",
                Duration = 3,
                Image = "navigation-off", -- Lucide icon
            })
        end
    end,
})

-- Tạo slider để điều chỉnh thời gian chờ trước khi teleport
local TeleportCooldownSlider = TeleportTab:CreateSlider({
    Name = "Thời gian chờ trước khi teleport",
    Range = {5, 60},
    Increment = 5,
    Suffix = "giây",
    CurrentValue = CONFIG.TELEPORT_COOLDOWN or 30,
    Flag = "TeleportCooldown",
    Callback = function(Value)
        CONFIG.TELEPORT_COOLDOWN = Value
        saveConfig(CONFIG)
    end,
})

-- Tạo button để teleport ngay lập tức
local TeleportNowButton = TeleportTab:CreateButton({
    Name = "Teleport Ngay",
    Callback = function()
        Rayfield:Notify({
            Title = "Đang teleport",
            Content = "Đang chuyển đến khu vực AFK...",
            Duration = 3,
            Image = "loader", -- Lucide icon
        })
        
        -- Thực hiện teleport ngay lập tức
        performTeleport()
    end,
})

-- Tab cài đặt
local SettingsTab = Window:CreateTab("Cài đặt", "settings") -- Sử dụng icon Lucide

-- Tạo button để tắt script
local ShutdownButton = SettingsTab:CreateButton({
    Name = "Tắt script",
    Callback = function()
        Rayfield:Notify({
            Title = "Xác nhận",
            Content = "Bạn có chắc chắn muốn tắt script?",
            Duration = 5,
            Image = "alert-triangle", -- Lucide icon
            Actions = {
                Ignore = {
                    Name = "Hủy",
                    Callback = function()
                        -- Không làm gì
                    end
                },
                Confirm = {
                    Name = "Tắt",
                    Callback = function()
                        shutdownScript() -- Tắt hoàn toàn script
                    end
                }
            }
        })
    end,
})

-- Biến kiểm soát auto teleport
local autoTeleportRunning = false
local teleportConnection = nil

-- Hàm thực hiện teleport
function performTeleport()
    local TeleportService = game:GetService("TeleportService")
    local Players = game:GetService("Players")
    local placeId = 116614712661486
    local player = Players.LocalPlayer
    
    -- Lưu trạng thái Auto TP trước khi teleport
    local autoTPEnabled = CONFIG.AUTO_TP_TO_AFK
    
    -- Lưu cấu hình trước khi teleport
    saveConfig(CONFIG)
    
    -- Kiểm tra nếu người chơi đã ở nơi cần đến
    if game.PlaceId == placeId then
        Rayfield:Notify({
            Title = "Thông báo",
            Content = "Bạn đã ở trong khu vực AFK",
            Duration = 3,
            Image = "check", -- Lucide icon
        })
        return -- Dừng ngay lập tức nếu đã ở đúng nơi
    end
    
    -- Lưu cài đặt vào GlobalSettings trước khi teleport
    if _G then
        _G.AriseWebhookSettings = {
            AUTO_TP_TO_AFK = autoTPEnabled,
            WEBHOOK_URL = CONFIG.WEBHOOK_URL,
            WEBHOOK_COOLDOWN = CONFIG.WEBHOOK_COOLDOWN,
            TELEPORT_COOLDOWN = CONFIG.TELEPORT_COOLDOWN
        }
        print("Đã lưu cài đặt Auto TP: " .. tostring(autoTPEnabled))
    end
    
    -- Thực hiện teleport với pcall để bắt lỗi
    local success, errorMessage = pcall(function()
        TeleportService:Teleport(placeId, player)
    end)
    
    if not success then
        warn("Teleport failed: " .. tostring(errorMessage))
        Rayfield:Notify({
            Title = "Lỗi teleport",
            Content = "Không thể teleport: " .. tostring(errorMessage),
            Duration = 5,
            Image = "alert-triangle", -- Lucide icon
        })
    end
end

-- Hàm bắt đầu quá trình auto teleport
function startAutoTeleport()
    if autoTeleportRunning then return end
    
    autoTeleportRunning = true
    
    -- Tạo một task mới để thực hiện teleport
    spawn(function()
        while scriptRunning and CONFIG.AUTO_TP_TO_AFK and autoTeleportRunning do
            -- Kiểm tra nếu không đúng PlaceId thì dừng script
            if game.PlaceId ~= allowedPlaceId and game.PlaceId ~= 116614712661486 then
                autoTeleportRunning = false
                break
            end
            
            -- Kiểm tra nếu đã ở khu vực AFK thì đợi và kiểm tra lại
            if game.PlaceId == 116614712661486 then
                -- Đã ở khu vực AFK, đợi một thời gian rồi kiểm tra lại
                Rayfield:Notify({
                    Title = "Auto TP",
                    Content = "Bạn đã ở trong khu vực AFK, sẽ kiểm tra lại sau " .. CONFIG.TELEPORT_COOLDOWN .. " giây",
                    Duration = 3,
                    Image = "check", -- Lucide icon
                })
                task.wait(CONFIG.TELEPORT_COOLDOWN)
                continue
            end
            
            -- Đếm ngược thời gian
            local countdown = CONFIG.TELEPORT_COOLDOWN
            while countdown > 0 and CONFIG.AUTO_TP_TO_AFK and autoTeleportRunning do
                if countdown == CONFIG.TELEPORT_COOLDOWN or countdown == 10 or countdown <= 5 then
                    Rayfield:Notify({
                        Title = "Auto TP",
                        Content = "Sẽ teleport sau " .. countdown .. " giây",
                        Duration = 1.5,
                        Image = "clock", -- Lucide icon
                    })
                end
                task.wait(1)
                countdown = countdown - 1
            end
            
            -- Nếu đã tắt auto TP hoặc script đã dừng
            if not CONFIG.AUTO_TP_TO_AFK or not autoTeleportRunning or not scriptRunning then
                autoTeleportRunning = false
                break
            end
            
            -- Thực hiện teleport
            performTeleport()
            
            -- Đợi một khoảng thời gian rồi bắt đầu lại vòng lặp
            task.wait(5)
        end
        
        autoTeleportRunning = false
    end)
    
    -- Xử lý trường hợp script bị tắt
    if teleportConnection then
        teleportConnection:Disconnect()
    end
    
    -- Thêm connection vào danh sách để có thể hủy khi tắt script
    teleportConnection = Players.PlayerRemoving:Connect(function(plr)
        if plr == Player then
            autoTeleportRunning = false
            if teleportConnection then
                teleportConnection:Disconnect()
            end
        end
    end)
    
    table.insert(connections, teleportConnection)
end

-- Tìm UI phần thưởng
findRewardsUI = function()
    if not Player or not Player:FindFirstChild("PlayerGui") then
        warn("Không tìm thấy PlayerGui")
        return nil
    end
    
    -- Tìm trong PlayerGui
    for _, gui in pairs(Player.PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
            -- Tìm frame chứa các phần thưởng
            local rewardsFrame = gui:FindFirstChild("REWARDS", true) 
            if rewardsFrame then
                return rewardsFrame.Parent
            end
            
            -- Tìm theo tên khác nếu không tìm thấy
            for _, obj in pairs(gui:GetDescendants()) do
                if obj:IsA("TextLabel") and (obj.Text == "REWARDS" or obj.Text:find("REWARD")) then
                    return obj.Parent
                end
            end
        end
    end
    return nil
end

-- Theo dõi phần thưởng "RECEIVED"
findReceivedFrame = function()
    -- Thêm thông báo debug
    print("Đang tìm kiếm UI RECEIVED...")
    
    if not Player or not Player:FindFirstChild("PlayerGui") then
        warn("Không tìm thấy PlayerGui")
        return nil
    end
    
    -- Sử dụng pcall để bắt lỗi
    local success, result = pcall(function()
        for _, gui in pairs(Player.PlayerGui:GetChildren()) do
            if gui:IsA("ScreenGui") then
                -- Phương pháp 1: Tìm trực tiếp label RECEIVED
                for _, obj in pairs(gui:GetDescendants()) do
                    if obj:IsA("TextLabel") and obj.Text == "RECEIVED" then
                        print("Đã tìm thấy label RECEIVED qua TextLabel")
                        return obj.Parent
                    end
                end
                
                -- Phương pháp 2: Tìm ImageLabel hoặc Frame có tên là RECEIVED
                local receivedFrame = gui:FindFirstChild("RECEIVED", true)
                if receivedFrame then
                    print("Đã tìm thấy RECEIVED qua FindFirstChild")
                    return receivedFrame.Parent
                end
                
                -- Phương pháp 3: Tìm các Frame chứa phần thưởng 
                for _, frame in pairs(gui:GetDescendants()) do
                    if (frame:IsA("Frame") or frame:IsA("ScrollingFrame")) and
                       (frame.Name:upper():find("RECEIVED") or 
                        (frame.Name:upper():find("REWARD") and not frame.Name:upper():find("REWARDS"))) then
                        print("Đã tìm thấy RECEIVED qua tên Frame: " .. frame.Name)
                        return frame
                    end
                end
                
                -- Phương pháp 4: Tìm các phần thưởng đặc trưng trong RECEIVED
                for _, frame in pairs(gui:GetDescendants()) do
                    if frame:IsA("Frame") or frame:IsA("ImageLabel") then
                        -- Đếm số lượng item trong frame
                        local itemCount = 0
                        local hasPercentage = false
                        
                        for _, child in pairs(frame:GetDescendants()) do
                            if child:IsA("TextLabel") then
                                -- Kiểm tra phần trăm (dấu hiệu của item)
                                if child.Text:match("^%d+%.?%d*%%$") then
                                    hasPercentage = true
                                end
                                
                                -- Kiểm tra "POWDER", "GEMS", "TICKETS" (dấu hiệu của item)
                                if child.Text:find("POWDER") or child.Text:find("GEMS") or child.Text:find("TICKETS") then
                                    itemCount = itemCount + 1
                                end
                            end
                        end
                        
                        -- Nếu frame chứa nhiều loại item và có phần trăm, có thể là RECEIVED
                        if itemCount >= 2 and hasPercentage and not frame.Name:upper():find("REWARDS") then
                            print("Đã tìm thấy RECEIVED qua việc phân tích nội dung: " .. frame.Name)
                            return frame
                        end
                    end
                end
            end
        end
        
        print("KHÔNG thể tìm thấy UI RECEIVED, tiếp tục tìm với cách khác...")
        
        -- Phương pháp cuối: Tìm một frame bất kỳ chứa TextLabel "POWDER", không thuộc REWARDS
        for _, gui in pairs(Player.PlayerGui:GetChildren()) do
            if gui:IsA("ScreenGui") then
                for _, frame in pairs(gui:GetDescendants()) do
                    if (frame:IsA("Frame") or frame:IsA("ImageLabel")) and not frame.Name:upper():find("REWARDS") then
                        for _, child in pairs(frame:GetDescendants()) do
                            if child:IsA("TextLabel") and 
                               (child.Text:find("POWDER") or child.Text:find("GEMS")) and
                               not frame:FindFirstChild("REWARDS", true) then
                                local parentName = frame.Parent and frame.Parent.Name or "unknown"
                                print("Tìm thấy frame có thể là RECEIVED: " .. frame.Name .. " (Parent: " .. parentName .. ")")
                                return frame
                            end
                        end
                    end
                end
            end
        end
        
        return nil
    end)
    
    if not success then
        warn("Lỗi khi tìm kiếm RECEIVED Frame: " .. tostring(result))
        return nil
    end
    
    return result
end

-- Tìm frame thông báo phần thưởng mới "YOU GOT A NEW REWARD!"
findNewRewardNotification = function()
    if not Player or not Player:FindFirstChild("PlayerGui") then
        warn("Không tìm thấy PlayerGui")
        return nil
    end
    
    local success, result = pcall(function()
        for _, gui in pairs(Player.PlayerGui:GetChildren()) do
            if gui:IsA("ScreenGui") then
                for _, obj in pairs(gui:GetDescendants()) do
                    if obj:IsA("TextLabel") and obj.Text:find("YOU GOT A NEW REWARD") then
                        return obj.Parent
                    end
                end
            end
        end
        return nil
    end)
    
    if not success then
        warn("Lỗi khi tìm kiếm New Reward Notification: " .. tostring(result))
        return nil
    end
    
    return result
end

-- Cập nhật hàm readActualItemQuantities để sử dụng hàm extractQuantity đúng cách
readActualItemQuantities = function()
    local receivedUI = findReceivedFrame()
    if not receivedUI then 
        print("Không tìm thấy UI RECEIVED để đọc số lượng")
        return 
    end
    
    print("Đang đọc phần thưởng từ RECEIVED UI: " .. receivedUI:GetFullName())
    
    -- Bảo vệ lỗi với pcall
    local success, result = pcall(function()
        -- Reset playerItems để cập nhật lại
        playerItems = {}
        local foundAnyItem = false
        
        -- Debug: In ra tất cả con của receivedUI
        print("Các phần tử con của RECEIVED UI:")
        for i, child in pairs(receivedUI:GetChildren()) do
            print("  " .. i .. ": " .. child.Name .. " [" .. child.ClassName .. "]")
        end
        
        for _, itemFrame in pairs(receivedUI:GetChildren()) do
            if itemFrame:IsA("Frame") or itemFrame:IsA("ImageLabel") then
                local itemType = ""
                local baseQuantity = 0
                local multiplier = 1
                
                -- Debug: In thông tin từng frame
                print("Đang phân tích frame: " .. itemFrame.Name)
                
                -- Tìm tên item và số lượng
                for _, child in pairs(itemFrame:GetDescendants()) do
                    if child:IsA("TextLabel") then
                        local text = child.Text
                        print("  TextLabel: '" .. text .. "'")
                        
                        -- Cải thiện: Kiểm tra văn bản chứa TIGER
                        if text:find("TIGER") then
                            itemType = "TIGER"
                            print("    Phát hiện TIGER item")
                            
                            -- Tìm số lượng trong ngoặc - ví dụ: TIGER(1)
                            local foundQuantity = nil
                            pcall(function() 
                                foundQuantity = extractQuantity(text)
                            end)
                            
                            if foundQuantity then
                                multiplier = foundQuantity
                                print("    Số lượng TIGER: " .. multiplier)
                            end
                            
                            -- Nếu không tìm được số lượng, giả định là 1
                            if multiplier <= 0 then
                                multiplier = 1
                            end
                            
                            -- Nếu không có baseQuantity, giả định là 1
                            if baseQuantity <= 0 then
                                baseQuantity = 1
                            end
                        -- Thêm xử lý cho TWIN PRISM BLADES
                        elseif text:find("TWIN PRISM BLADES") then
                            itemType = "TWIN PRISM BLADES"
                            print("    Phát hiện TWIN PRISM BLADES item")
                            
                            -- Tìm số lượng trong ngoặc - ví dụ: TWIN PRISM BLADES(1)
                            local foundQuantity = nil
                            pcall(function() 
                                foundQuantity = extractQuantity(text)
                            end)
                            
                            if foundQuantity then
                                multiplier = foundQuantity
                                print("    Số lượng TWIN PRISM BLADES: " .. multiplier)
                            end
                            
                            -- Nếu không tìm được số lượng, giả định là 1
                            if multiplier <= 0 then
                                multiplier = 1
                            end
                            
                            -- Nếu không có baseQuantity, giả định là 1
                            if baseQuantity <= 0 then
                                baseQuantity = 1
                            end
                        -- Thêm xử lý cho ZIRU G
                        elseif text:find("ZIRU G") then
                            itemType = "ZIRU G"
                            print("    Phát hiện ZIRU G item")
                            
                            -- Tìm số lượng trong ngoặc - ví dụ: ZIRU G(1)
                            local foundQuantity = nil
                            pcall(function() 
                                foundQuantity = extractQuantity(text)
                            end)
                            
                            if foundQuantity then
                                multiplier = foundQuantity
                                print("    Số lượng ZIRU G: " .. multiplier)
                            end
                            
                            -- Nếu không tìm được số lượng, giả định là 1
                            if multiplier <= 0 then
                                multiplier = 1
                            end
                            
                            -- Nếu không có baseQuantity, giả định là 1
                            if baseQuantity <= 0 then
                                baseQuantity = 1
                            end
                        end
                        
                        -- Tìm loại item (GEMS, POWDER, TICKETS, v.v.)
                        local foundItemType = text:match("(%w+)%s*%(%d+%)") or text:match("(%w+)%s*$")
                        if foundItemType then
                            itemType = foundItemType
                            print("    Phát hiện loại item: " .. itemType)
                        end
                        
                        -- Tìm số lượng trong ngoặc - ví dụ: GEMS(1)
                        local foundQuantity = nil
                        pcall(function() 
                            foundQuantity = extractQuantity(text)
                        end)
                        
                        if foundQuantity then
                            multiplier = foundQuantity
                            print("    Phát hiện số lượng từ ngoặc (multiplier): " .. multiplier)
                        end
                        
                        -- Tìm số lượng đứng trước tên item - ví dụ: 500 GEMS
                        local amountPrefix = text:match("^(%d+)%s+%w+")
                        if amountPrefix then
                            baseQuantity = tonumber(amountPrefix)
                            print("    Phát hiện số lượng cơ bản: " .. baseQuantity)
                        end
                    end
                end
                
                -- Tính toán số lượng thực tế bằng cách nhân số lượng cơ bản với hệ số từ ngoặc
                local finalQuantity = baseQuantity * multiplier
                print("    Số lượng cuối cùng: " .. baseQuantity .. " x " .. multiplier .. " = " .. finalQuantity)
                
                -- Chỉ lưu các phần thưởng không phải CASH
                local isCash = false
                pcall(function()
                    isCash = isCashReward(itemType)
                end)
                
                if itemType ~= "" and finalQuantity > 0 and not isCash then
                    playerItems[itemType] = (playerItems[itemType] or 0) + finalQuantity
                    print("Đã đọc item: " .. finalQuantity .. " " .. itemType .. " (từ " .. baseQuantity .. " x " .. multiplier .. ")")
                    foundAnyItem = true
                elseif itemType ~= "" and finalQuantity > 0 then
                    print("Bỏ qua item CASH: " .. finalQuantity .. " " .. itemType)
                end
            end
        end
        
        -- Cố gắng đọc theo cách khác nếu không tìm thấy item nào
        if not foundAnyItem then
            print("Không tìm thấy item nào bằng phương pháp thông thường, thử phương pháp thay thế...")
            
            -- Tìm tất cả TextLabel trong receivedUI có chứa GEMS, POWDER, TICKETS, TIGER
            for _, child in pairs(receivedUI:GetDescendants()) do
                if child:IsA("TextLabel") then
                    local text = child.Text
                    
                    -- Tìm item có pattern X ITEM_TYPE(Y) hoặc ITEM_TYPE(Y)
                    local baseAmount, itemType, multiplier = text:match("(%d+)%s+([%w%s]+)%((%d+)%)")
                    if baseAmount and itemType and multiplier then
                        baseAmount = tonumber(baseAmount)
                        multiplier = tonumber(multiplier)
                        local finalAmount = baseAmount * multiplier
                        
                        local isCash = false
                        pcall(function()
                            isCash = isCashReward(itemType)
                        end)
                        
                        if not isCash then
                            playerItems[itemType] = (playerItems[itemType] or 0) + finalAmount
                            print("Phương pháp thay thế - Đã đọc item: " .. finalAmount .. " " .. itemType .. " (từ " .. baseAmount .. " x " .. multiplier .. ")")
                            foundAnyItem = true
                        end
                    else
                        -- Kiểm tra văn bản có chứa TIGER(X), TWIN PRISM BLADES(X) hoặc ZIRU G(X)
                        local itemType, multiplier = text:match("([%w%s]+)%((%d+)%)")
                        if itemType and multiplier then
                            if itemType == "TIGER" or text:find("TIGER") or
                               itemType == "TWIN PRISM BLADES" or text:find("TWIN PRISM BLADES") or
                               itemType == "ZIRU G" or text:find("ZIRU G") then
                                
                                multiplier = tonumber(multiplier)
                                local isCash = false
                                pcall(function()
                                    isCash = isCashReward(itemType)
                                end)
                                
                                if multiplier and multiplier > 0 and not isCash then
                                    playerItems[itemType] = (playerItems[itemType] or 0) + multiplier
                                    print("Phương pháp thay thế - Đã đọc item đặc biệt: " .. multiplier .. " " .. itemType)
                                    foundAnyItem = true
                                end
                            end
                        end
                        
                        -- Phương pháp đơn giản hơn: tìm tên item đặc biệt mà không có định dạng
                        if text:find("TWIN PRISM BLADES") and not playerItems["TWIN PRISM BLADES"] then
                            playerItems["TWIN PRISM BLADES"] = (playerItems["TWIN PRISM BLADES"] or 0) + 1
                            print("Phương pháp thay thế - Đã đọc TWIN PRISM BLADES")
                            foundAnyItem = true
                        elseif text:find("ZIRU G") and not playerItems["ZIRU G"] then
                            playerItems["ZIRU G"] = (playerItems["ZIRU G"] or 0) + 1
                            print("Phương pháp thay thế - Đã đọc ZIRU G")
                            foundAnyItem = true
                        end
                    end
                end
            end
        end
        
        -- Thêm: Kiểm tra đặc biệt cho TIGER nếu vẫn chưa thấy
        if not playerItems["TIGER"] then
            for _, child in pairs(receivedUI:GetDescendants()) do
                if child:IsA("TextLabel") and child.Text:find("TIGER") then
                    print("Phát hiện TIGER thông qua kiểm tra đặc biệt: " .. child.Text)
                    -- Tìm số lượng trong ngoặc nếu có
                    local quantity = 1
                    pcall(function()
                        quantity = extractQuantity(child.Text) or 1
                    end)
                    playerItems["TIGER"] = (playerItems["TIGER"] or 0) + quantity
                    foundAnyItem = true
                end
            end
        end
        
        -- Thêm: Kiểm tra đặc biệt cho TWIN PRISM BLADES nếu vẫn chưa thấy
        if not playerItems["TWIN PRISM BLADES"] then
            for _, child in pairs(receivedUI:GetDescendants()) do
                if child:IsA("TextLabel") and child.Text:find("TWIN PRISM BLADES") then
                    print("Phát hiện TWIN PRISM BLADES thông qua kiểm tra đặc biệt: " .. child.Text)
                    -- Tìm số lượng trong ngoặc nếu có
                    local quantity = 1
                    pcall(function()
                        quantity = extractQuantity(child.Text) or 1
                    end)
                    playerItems["TWIN PRISM BLADES"] = (playerItems["TWIN PRISM BLADES"] or 0) + quantity
                    foundAnyItem = true
                end
            end
        end
        
        -- Thêm: Kiểm tra đặc biệt cho ZIRU G nếu vẫn chưa thấy
        if not playerItems["ZIRU G"] then
            for _, child in pairs(receivedUI:GetDescendants()) do
                if child:IsA("TextLabel") and child.Text:find("ZIRU G") then
                    print("Phát hiện ZIRU G thông qua kiểm tra đặc biệt: " .. child.Text)
                    -- Tìm số lượng trong ngoặc nếu có
                    local quantity = 1
                    pcall(function()
                        quantity = extractQuantity(child.Text) or 1
                    end)
                    playerItems["ZIRU G"] = (playerItems["ZIRU G"] or 0) + quantity
                    foundAnyItem = true
                end
            end
        end
        
        -- Hiển thị tất cả các item đã đọc được
        print("----- Danh sách item hiện có (không bao gồm CASH) -----")
        if next(playerItems) ~= nil then
            for itemType, amount in pairs(playerItems) do
                print(itemType .. ": " .. amount)
            end
        else
            print("Không đọc được bất kỳ item nào từ UI RECEIVED!")
        end
        print("------------------------------------------------------")
        
        return playerItems
    end)
    
    if not success then
        warn("Lỗi khi đọc số lượng item: " .. tostring(result))
        -- Trả về playerItems hiện tại nếu có lỗi
        return playerItems
    end
    
    return result or playerItems
end

-- Cập nhật tổng phần thưởng
local function updateTotalRewards(rewardText)
    if not rewardText or type(rewardText) ~= "string" then
        warn("Không thể cập nhật tổng phần thưởng: rewardText không hợp lệ")
        return
    end

    -- Sử dụng pcall để bắt lỗi
    local success, result = pcall(function()
        local amount, itemType = nil, nil
        pcall(function()
            amount, itemType = parseReward(rewardText)
        end)
        
        if amount and itemType then
            -- Bỏ qua CASH
            local isCash = false
            pcall(function()
                isCash = isCashReward(itemType)
            end)
            
            if isCash then
                print("Bỏ qua cập nhật CASH: " .. amount .. " " .. itemType)
                return
            end
            
            if not totalRewards[itemType] then
                totalRewards[itemType] = amount
            else
                totalRewards[itemType] = totalRewards[itemType] + amount
            end
            print("Đã cập nhật tổng phần thưởng: " .. amount .. " " .. itemType)
        end
    end)
    
    if not success then
        warn("Lỗi khi cập nhật tổng phần thưởng: " .. tostring(result))
    end
end

-- Tạo chuỗi tổng hợp tất cả phần thưởng
local function getTotalRewardsText()
    -- Sử dụng pcall để bắt lỗi
    local success, rewardText = pcall(function()
        local result = "Tổng phần thưởng:\n"
        
        -- Đọc số lượng item thực tế từ UI (sử dụng pcall để tránh lỗi)
        pcall(function()
            readActualItemQuantities()
        end)
        
        -- Ưu tiên hiển thị số liệu từ playerItems nếu có
        if playerItems and next(playerItems) ~= nil then
            for itemType, amount in pairs(playerItems) do
                -- Bảo vệ lỗi với pcall
                local isCash = false
                pcall(function()
                    isCash = isCashReward(itemType)
                end)
                
                -- Loại bỏ CASH (thêm biện pháp bảo vệ)
                if not isCash then
                    result = result .. "- " .. amount .. " " .. itemType .. "\n"
                end
            end
        else
            -- Sử dụng totalRewards nếu không đọc được từ UI
            if totalRewards and next(totalRewards) ~= nil then
                for itemType, amount in pairs(totalRewards) do
                    -- Bảo vệ lỗi với pcall
                    local isCash = false
                    pcall(function()
                        isCash = isCashReward(itemType)
                    end)
                    
                    -- Loại bỏ CASH (thêm biện pháp bảo vệ)
                    if not isCash then
                        result = result .. "- " .. amount .. " " .. itemType .. "\n"
                    end
                end
            else
                -- Không có dữ liệu
                result = result .. "- Chưa có dữ liệu phần thưởng\n"
            end
        end
        
        return result
    end)
    
    if not success then
        warn("Lỗi khi tạo chuỗi phần thưởng: " .. tostring(rewardText))
        return "Tổng phần thưởng:\n- Đã xảy ra lỗi khi đọc dữ liệu\n"
    end
    
    return rewardText
end

-- Tạo chuỗi hiển thị các phần thưởng vừa nhận
local function getLatestRewardsText(newRewardInfo)
    if not newRewardInfo or type(newRewardInfo) ~= "string" then
        return "Không có thông tin phần thưởng"
    end
    
    -- Sử dụng pcall để bắt lỗi
    local success, rewardText = pcall(function()
        -- Loại bỏ các tiền tố không cần thiết
        local cleanRewardInfo = newRewardInfo:gsub("RECEIVED:%s*", "")
        cleanRewardInfo = cleanRewardInfo:gsub("YOU GOT A NEW REWARD!%s*", "")
        
        local amount, itemType = nil, nil
        pcall(function()
            amount, itemType = parseReward(cleanRewardInfo)
        end)
        
        local result = "Phần thưởng mới:\n- " .. cleanRewardInfo .. "\n\n"
        
        -- Chỉ hiển thị tổng nếu không phải CASH
        if amount and itemType and playerItems and playerItems[itemType] then
            local isCash = false
            pcall(function()
                isCash = isCashReward(itemType)
            end)
            
            if not isCash then
                result = result .. "Tổng " .. itemType .. ": " .. playerItems[itemType] .. " (+" .. amount .. ")\n"
            end
        end
        
        return result
    end)
    
    if not success then
        warn("Lỗi khi tạo chuỗi phần thưởng mới: " .. tostring(rewardText))
        return "Phần thưởng mới:\n- " .. newRewardInfo .. "\n\nKhông thể hiển thị chi tiết do lỗi\n"
    end
    
    return rewardText
end

-- Kiểm tra xem có thể gửi webhook không (cooldown)
local function canSendWebhook()
    local success, result = pcall(function()
        local currentTime = tick()
        if not lastWebhookTime then
            lastWebhookTime = 0
        end
        
        if not WEBHOOK_COOLDOWN then
            WEBHOOK_COOLDOWN = 3
        end
        
        if currentTime - lastWebhookTime < WEBHOOK_COOLDOWN then
            return false
        end
        return true
    end)
    
    if not success then
        warn("Lỗi khi kiểm tra cooldown webhook: " .. tostring(result))
        return false
    end
    
    return result
end

-- Gửi webhook thử nghiệm để kiểm tra kết nối
sendTestWebhook = function(customMessage)
    -- Nếu đang xử lý phần thưởng khác, không gửi webhook thử nghiệm
    if isProcessingReward then
        print("Đang xử lý phần thưởng khác, không thể gửi webhook thử nghiệm")
        return false
    end
    
    -- Đánh dấu đang xử lý
    isProcessingReward = true
    
    local message = customMessage or "Đây là webhook thử nghiệm từ Arise Crossover Rewards Tracker"
    
    local data = {
        content = nil,
        embeds = {
            {
                title = "🔍 Arise Crossover - Webhook Thử Nghiệm",
                description = message,
                color = 5814783, -- Màu tím
                fields = {
                    {
                        name = "Thời gian",
                        value = os.date("%d/%m/%Y %H:%M:%S"),
                        inline = true
                    },
                    {
                        name = "Người chơi",
                        value = Player.Name,
                        inline = true
                    }
                },
                footer = {
                    text = "Arise Crossover Rewards Tracker - Webhook độc quyền của DuongTuan"
                }
            }
        }
    }
    
    -- Chuyển đổi dữ liệu thành chuỗi JSON
    local jsonData = HttpService:JSONEncode(data)
    
    print("Đang gửi webhook thử nghiệm...")
    
    -- Sử dụng HTTP request từ executor
    local success, err = pcall(function()
        -- Synapse X
        if syn and syn.request then
            syn.request({
                Url = CONFIG.WEBHOOK_URL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = jsonData
            })
            print("Đã gửi webhook thử nghiệm qua syn.request")
        -- KRNL, Script-Ware và nhiều executor khác
        elseif request then
            request({
                Url = CONFIG.WEBHOOK_URL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = jsonData
            })
            print("Đã gửi webhook thử nghiệm qua request")
        -- Các Executor khác
        elseif http and http.request then
            http.request({
                Url = CONFIG.WEBHOOK_URL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = jsonData
            })
            print("Đã gửi webhook thử nghiệm qua http.request")
        -- JJSploit và một số executor khác
        elseif httppost then
            httppost(CONFIG.WEBHOOK_URL, jsonData)
            print("Đã gửi webhook thử nghiệm qua httppost")
        else
            error("Không tìm thấy HTTP API nào được hỗ trợ bởi executor hiện tại")
        end
    end)
    
    -- Kết thúc xử lý
    wait(0.5)
    isProcessingReward = false
    
    if success then
        -- Hiển thị thông báo Rayfield khi gửi thành công
        Rayfield:Notify({
            Title = "Thử nghiệm thành công",
            Content = "Đã gửi webhook thử nghiệm thành công",
            Duration = 3,
            Image = "check", -- Lucide icon
        })
        print("Đã gửi webhook thử nghiệm thành công")
        return true
    else
        -- Hiển thị thông báo Rayfield khi gửi thất bại
        Rayfield:Notify({
            Title = "Thử nghiệm thất bại",
            Content = "Lỗi: " .. tostring(err),
            Duration = 5,
            Image = "x", -- Lucide icon
        })
        warn("Lỗi gửi webhook thử nghiệm: " .. tostring(err))
        return false
    end
end

-- Tìm kiếm các phần tử UI ban đầu
local function findAllUIElements()
    print("Đang tìm kiếm các phần tử UI...")
    
    -- Sử dụng pcall để bắt lỗi
    local success, result = pcall(function()
        local rewardsUI = findRewardsUI()
        local receivedUI = findReceivedFrame()
        local newRewardUI = findNewRewardNotification()
        
        -- Đọc số lượng item hiện tại
        pcall(function()
            readActualItemQuantities()
        end)
        
        -- Kiểm tra thông báo phần thưởng mới trước tiên
        if newRewardUI then
            print("Đã tìm thấy thông báo YOU GOT A NEW REWARD!")
            pcall(function()
                checkNewRewardNotification(newRewardUI)
            end)
        else
            print("Chưa tìm thấy thông báo phần thưởng mới")
            
            -- Nếu không có thông báo NEW REWARD, kiểm tra REWARDS
            if rewardsUI then
                print("Đã tìm thấy UI phần thưởng")
                pcall(function()
                    checkNewRewards(rewardsUI)
                end)
            else
                warn("Không tìm thấy UI phần thưởng")
            end
        end
        
        -- Luôn đọc RECEIVED để cập nhật số lượng item hiện tại
        if receivedUI then
            print("Đã tìm thấy UI RECEIVED")
            pcall(function()
                checkReceivedRewards(receivedUI)
            end)
        end
        
        return rewardsUI, receivedUI, newRewardUI
    end)
    
    if not success then
        warn("Lỗi khi tìm kiếm UI phần thưởng: " .. tostring(result))
        return nil, nil, nil
    end
    
    return result
end

-- Theo dõi thay đổi trong PlayerGui
local playerGuiConnection
playerGuiConnection = Player.PlayerGui.ChildAdded:Connect(function(child)
    if not scriptRunning then
        playerGuiConnection:Disconnect()
        return
    end
    
    if child:IsA("ScreenGui") then
        delay(2, function()
            if scriptRunning then
                findAllUIElements()
            end
        end)
    end
end)

-- Theo dõi sự xuất hiện của thông báo phần thưởng mới
spawn(function()
    while scriptRunning and wait(2) do
        if not scriptRunning then break end
        
        local newRewardUI = findNewRewardNotification()
        if newRewardUI then
            checkNewRewardNotification(newRewardUI)
        end
    end
end)

-- Theo dõi phần thưởng mới liên tục (với tần suất thấp hơn)
spawn(function()
    while scriptRunning and wait(5) do
        if not scriptRunning then break end
        
        -- Đọc số lượng item định kỳ
        readActualItemQuantities()
        
        -- Chỉ kiểm tra REWARDS nếu không có NEW REWARD
        local newRewardUI = findNewRewardNotification()
        if not newRewardUI then
            local rewardsUI = findRewardsUI()
            if rewardsUI then
                checkNewRewards(rewardsUI)
            end
        end
        
        -- Luôn kiểm tra RECEIVED để cập nhật số lượng
        local receivedUI = findReceivedFrame()
        if receivedUI then
            checkReceivedRewards(receivedUI)
        end
    end
end)

-- Gửi một webhook về tất cả phần thưởng hiện có trong UI RECEIVED khi khởi động script
local function sendInitialReceivedWebhook()
    print("Đang gửi webhook ban đầu về các phần thưởng hiện có...")
    
    -- Hiển thị thông báo đang gửi webhook ban đầu
    Rayfield:Notify({
        Title = "Khởi tạo",
        Content = "Đang kiểm tra và gửi thông tin phần thưởng hiện có...",
        Duration = 3,
        Image = "loader", -- Lucide icon
    })
    
    -- Tìm UI RECEIVED và đọc dữ liệu
    local receivedUI = findReceivedFrame()
    if not receivedUI then 
        print("Không tìm thấy UI RECEIVED - thử phương án dự phòng...")
        
        -- Hiển thị thông báo không tìm thấy UI
        Rayfield:Notify({
            Title = "Lưu ý",
            Content = "Không tìm thấy UI hiển thị phần thưởng, vui lòng mở UI phần thưởng trong game",
            Duration = 5,
            Image = "alert-triangle", -- Lucide icon
        })
        
        -- Phương án dự phòng sẽ được giữ nguyên
        -- ...
    else
        -- Nếu tìm thấy RECEIVED UI, tiếp tục xử lý
        print("Đã tìm thấy UI RECEIVED, đang đọc dữ liệu...")
        
        -- Tạo danh sách phần thưởng thủ công bằng cách duyệt toàn bộ UI
        local receivedItems = {}
        local foundAny = false
        
        -- Tìm tất cả TextLabel trong RECEIVED UI
        for _, textLabel in pairs(receivedUI:GetDescendants()) do
            if textLabel:IsA("TextLabel") then
                local text = textLabel.Text
                
                -- Nếu chứa GEMS, POWDER hoặc TICKETS
                if (text:find("GEMS") or text:find("POWDER") or text:find("TICKETS")) and not isCashReward(text) then
                    print("Tìm thấy item text: " .. text)
                    table.insert(receivedItems, text)
                    foundAny = true
                end
            end
        end
        
        -- Không gửi webhook nếu không tìm thấy item nào
        if not foundAny then
            print("Không tìm thấy phần thưởng nào trong UI RECEIVED")
            
            -- Hiển thị thông báo không tìm thấy phần thưởng
            Rayfield:Notify({
                Title = "Thông báo",
                Content = "Không tìm thấy phần thưởng nào hiện có",
                Duration = 3,
                Image = "info", -- Lucide icon
            })
            
            -- Vẫn cập nhật lại playerItems để dùng cho lần sau
            readActualItemQuantities()
            return
        end
        
        -- Đánh dấu đang xử lý
        isProcessingReward = true
        
        local allItemsText = ""
        for _, itemText in ipairs(receivedItems) do
            allItemsText = allItemsText .. "- " .. itemText .. "\n"
        end
        
        -- Đọc số lượng item chính xác
        readActualItemQuantities()
        
        -- Hiển thị thông tin từ playerItems thay vì receivedItems
        local itemListText = ""
        if next(playerItems) ~= nil then
            for itemType, amount in pairs(playerItems) do
                itemListText = itemListText .. "- " .. amount .. " " .. itemType .. "\n"
            end
        else
            -- Sử dụng receivedItems nếu không đọc được từ playerItems
            itemListText = allItemsText
        end
        
        local data = {
            content = nil,
            embeds = {
                {
                    title = "🎮 Arise Crossover - Phần thưởng hiện có",
                    description = "Danh sách phần thưởng đã nhận",
                    color = 7419530, -- Màu xanh biển
                    fields = {
                        {
                            name = "Phần thưởng đã nhận",
                            value = itemListText ~= "" and itemListText or "Không có phần thưởng nào",
                            inline = false
                        },
                        {
                            name = "Thời gian",
                            value = os.date("%d/%m/%Y %H:%M:%S"),
                            inline = true
                        },
                        {
                            name = "Người chơi",
                            value = Player.Name,
                            inline = true
                        }
                    },
                    footer = {
                        text = "Arise Crossover Rewards Tracker - Webhook độc quyền của DuongTuan"
                    }
                }
            }
        }
        
        -- Chuyển đổi dữ liệu thành chuỗi JSON
        local jsonData = HttpService:JSONEncode(data)
        
        print("Chuẩn bị gửi webhook với dữ liệu: " .. jsonData:sub(1, 100) .. "...")
        
        -- Sử dụng HTTP request từ executor thay vì HttpService
        local success, err = pcall(function()
            -- Synapse X
            if syn and syn.request then
                syn.request({
                    Url = CONFIG.WEBHOOK_URL,
                    Method = "POST",
                    Headers = {
                        ["Content-Type"] = "application/json"
                    },
                    Body = jsonData
                })
                print("Đã gửi webhook qua syn.request")
            -- KRNL, Script-Ware và nhiều executor khác
            elseif request then
                request({
                    Url = CONFIG.WEBHOOK_URL,
                    Method = "POST",
                    Headers = {
                        ["Content-Type"] = "application/json"
                    },
                    Body = jsonData
                })
                print("Đã gửi webhook qua request")
            -- Các Executor khác
            elseif http and http.request then
                http.request({
                    Url = CONFIG.WEBHOOK_URL,
                    Method = "POST",
                    Headers = {
                        ["Content-Type"] = "application/json"
                    },
                    Body = jsonData
                })
                print("Đã gửi webhook qua http.request")
            -- JJSploit và một số executor khác
            elseif httppost then
                httppost(CONFIG.WEBHOOK_URL, jsonData)
                print("Đã gửi webhook qua httppost")
            else
                error("Không tìm thấy HTTP API nào được hỗ trợ bởi executor hiện tại")
            end
        end)
        
        if success then
            print("Đã gửi webhook ban đầu thành công với " .. #receivedItems .. " phần thưởng")
            
            -- Hiển thị thông báo gửi webhook thành công
            Rayfield:Notify({
                Title = "Thành công",
                Content = "Đã gửi thông tin " .. #receivedItems .. " phần thưởng hiện có",
                Duration = 3,
                Image = "check", -- Lucide icon
            })
        else
            warn("Lỗi gửi webhook ban đầu: " .. tostring(err))
            
            -- Hiển thị thông báo lỗi
            Rayfield:Notify({
                Title = "Lỗi",
                Content = "Không thể gửi webhook ban đầu: " .. tostring(err),
                Duration = 5,
                Image = "x", -- Lucide icon
            })
        end
        
        -- Kết thúc xử lý
        wait(0.5) -- Chờ một chút để tránh xử lý quá nhanh
        isProcessingReward = false
        lastWebhookTime = tick() -- Cập nhật thời gian gửi webhook cuối cùng
    end
end

-- Khởi tạo tìm kiếm ban đầu và tạo UI
delay(3, function()
    print("Bắt đầu tìm kiếm UI và chuẩn bị gửi webhook khởi động...")
    
    -- Tìm các UI
    findAllUIElements()
    
    -- Gửi webhook ban đầu chỉ một lần
    sendInitialReceivedWebhook()
    
    -- Cập nhật thông tin hiển thị phần thưởng trong Rayfield
    if TotalRewardsLabel then
        local rewardsText = getTotalRewardsText()
        TotalRewardsText = rewardsText
        TotalRewardsLabel:Set({
            Title = "Tổng phần thưởng hiện có", 
            Content = rewardsText
        })
    end
    
    -- Thông báo Rayfield đã khởi động xong
    Rayfield:Notify({
        Title = "Arise Webhook đã sẵn sàng",
        Content = "Đang theo dõi phần thưởng của " .. playerName,
        Duration = 5,
        Image = "check-circle", -- Lucide icon
    })
end)

print("Script theo dõi phần thưởng AFKRewards đã được nâng cấp:")
print("- Giao diện mới sử dụng Rayfield")
print("- Gửi webhook khi khởi động để thông báo các phần thưởng hiện có")
print("- Chỉ gửi MỘT webhook cho mỗi phần thưởng mới")
print("- Không hiển thị và không gửi webhook cho CASH")
print("- Kiểm tra số lượng item thực tế từ RECEIVED")
print("- Hiển thị tổng phần thưởng chính xác trong webhook")
print("- Ping @everyone khi phát hiện ZIRU G lần đầu tiên")
print("- Chức năng tự động teleport đến khu vực AFK")
print("- Cấu hình riêng biệt cho từng tài khoản: " .. CONFIG_FILE)
print("- Giám sát phần thưởng mới với cooldown " .. WEBHOOK_COOLDOWN .. " giây")
print("- Hỗ trợ phát hiện đặc biệt cho TIGER, TWIN PRISM BLADES và ZIRU G")

-- Gửi thông tin đến Discord webhook (sử dụng HTTP request từ executor)
local function sendWebhook(rewardInfo, rewardObject, isNewReward)
    print("DEBUG: Đang chuẩn bị gửi webhook cho phần thưởng: " .. rewardInfo)
    
    -- Loại bỏ các tiền tố không cần thiết
    local cleanRewardInfo = rewardInfo:gsub("RECEIVED:%s*", "")
    cleanRewardInfo = cleanRewardInfo:gsub("YOU GOT A NEW REWARD!%s*", "")
    
    -- Bỏ qua nếu phần thưởng là CASH
    if isCashReward(cleanRewardInfo) then
        print("Bỏ qua gửi webhook cho CASH: " .. cleanRewardInfo)
        return
    end
    
    -- Kiểm tra xem có đang xử lý phần thưởng khác không
    if isProcessingReward then
        print("Đang xử lý phần thưởng khác, bỏ qua...")
        return
    end
    
    -- Kiểm tra cooldown
    if not canSendWebhook() then
        print("Cooldown webhook còn " .. math.floor(WEBHOOK_COOLDOWN - (tick() - lastWebhookTime)) .. " giây, bỏ qua...")
        return
    end
    
    -- Tạo ID duy nhất và kiểm tra trùng lặp
    local rewardId = createUniqueRewardId(cleanRewardInfo)
    print("DEBUG: ID phần thưởng: " .. rewardId)
    if receivedRewards[rewardId] then
        print("Phần thưởng này đã được gửi trước đó: " .. cleanRewardInfo)
        return
    end
    
    -- Đánh dấu đang xử lý
    isProcessingReward = true
    lastWebhookTime = tick()
    
    -- Đánh dấu đã nhận
    receivedRewards[rewardId] = true
    
    -- Đọc số lượng item thực tế trước khi gửi webhook
    readActualItemQuantities()
    
    local title = "🎁 Arise Crossover - AFKRewards"
    local description = "Phần thưởng mới đã nhận được!"
    
    -- Cập nhật tổng phần thưởng
    updateTotalRewards(cleanRewardInfo)

    -- Kiểm tra xem phần thưởng có chứa ZIRU G không để ping @everyone (chỉ lần đầu tiên)
    local hasZiruG = cleanRewardInfo:find("ZIRU G") ~= nil or (playerItems["ZIRU G"] ~= nil and playerItems["ZIRU G"] > 0)
    local shouldPingEveryone = hasZiruG and not hasAlreadyPingedZiruG
    
    -- Nếu phát hiện ZIRU G, đánh dấu đã ping để không ping lần sau
    if hasZiruG and not hasAlreadyPingedZiruG then
        hasAlreadyPingedZiruG = true
        print("Đánh dấu đã ping ZIRU G lần đầu tiên, sẽ không ping lần sau")
    end
    
    local data = {
        content = shouldPingEveryone and "@everyone Phát hiện ZIRU G lần đầu tiên!" or nil,
        embeds = {
            {
                title = title,
                description = description,
                color = 7419530, -- Màu xanh biển
                fields = {
                    {
                        name = "Thông tin phần thưởng",
                        value = getLatestRewardsText(cleanRewardInfo),
                        inline = false
                    },
                    {
                        name = "Thời gian",
                        value = os.date("%d/%m/%Y %H:%M:%S"),
                        inline = true
                    },
                    {
                        name = "Người chơi",
                        value = Player.Name,
                        inline = true
                    },
                    {
                        name = "Tổng hợp phần thưởng",
                        value = getTotalRewardsText(),
                        inline = false
                    }
                },
                footer = {
                    text = "Arise Crossover Rewards Tracker"
                }
            }
        }
    }
    
    print("DEBUG: Đang tạo dữ liệu JSON và gửi webhook...")
    
    -- Chuyển đổi dữ liệu thành chuỗi JSON
    local jsonData = HttpService:JSONEncode(data)
    
    -- Cập nhật URL từ cấu hình
    local currentWebhookUrl = CONFIG.WEBHOOK_URL
    
    print("DEBUG: URL webhook: " .. (currentWebhookUrl:sub(1, 30) .. "..."))
    
    -- Sử dụng HTTP request từ executor thay vì HttpService
    local success, err = pcall(function()
        -- Synapse X
        if syn and syn.request then
            print("DEBUG: Sử dụng syn.request")
            syn.request({
                Url = currentWebhookUrl,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = jsonData
            })
        -- KRNL, Script-Ware và nhiều executor khác
        elseif request then
            print("DEBUG: Sử dụng request")
            request({
                Url = currentWebhookUrl,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = jsonData
            })
        -- Các Executor khác
        elseif http and http.request then
            print("DEBUG: Sử dụng http.request")
            http.request({
                Url = currentWebhookUrl,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = jsonData
            })
        -- JJSploit và một số executor khác
        elseif httppost then
            print("DEBUG: Sử dụng httppost")
            httppost(currentWebhookUrl, jsonData)
        else
            error("Không tìm thấy HTTP API nào được hỗ trợ bởi executor hiện tại")
        end
    end)
    
    if success then
        print("Đã gửi phần thưởng thành công: " .. cleanRewardInfo)
        if shouldPingEveryone then
            print("Đã ping @everyone vì phát hiện ZIRU G lần đầu tiên!")
        end
        
        -- Hiển thị thông báo Rayfield khi nhận phần thưởng
        Rayfield:Notify({
            Title = "Phần thưởng mới!",
            Content = cleanRewardInfo,
            Duration = 5,
            Image = "gift", -- Lucide icon
        })
        
        -- Cập nhật thông tin hiển thị trong UI
        if TotalRewardsLabel then
            local rewardsText = getTotalRewardsText()
            TotalRewardsText = rewardsText
            TotalRewardsLabel:Set({
                Title = "Tổng phần thưởng hiện có", 
                Content = rewardsText
            })
        end
    else
        warn("Lỗi gửi webhook: " .. tostring(err))
        
        -- Hiển thị thông báo lỗi trong Rayfield
        Rayfield:Notify({
            Title = "Lỗi gửi webhook",
            Content = "Không thể gửi thông tin phần thưởng: " .. tostring(err),
            Duration = 5,
            Image = "alert-triangle", -- Lucide icon
        })
    end
    
    -- Kết thúc xử lý
    wait(0.5) -- Chờ một chút để tránh xử lý quá nhanh
    isProcessingReward = false
end

-- Tạo nút để gửi webhook thủ công với phần thưởng hiện tại - phiên bản đơn giản hơn
local SendCurrentButton = RewardsTab:CreateButton({
    Name = "Gửi webhook phần thưởng hiện tại",
    Callback = function()
        -- Hiển thị thông báo đang gửi
        Rayfield:Notify({
            Title = "Đang gửi",
            Content = "Đang gửi thông tin phần thưởng hiện tại...",
            Duration = 2,
            Image = "loader", -- Lucide icon
        })
        
        -- Đọc lại dữ liệu phần thưởng hiện tại
        readActualItemQuantities()
        
        -- Kiểm tra URL webhook
        if not CONFIG.WEBHOOK_URL or CONFIG.WEBHOOK_URL == "YOUR_URL" or CONFIG.WEBHOOK_URL == "" then
            Rayfield:Notify({
                Title = "Lỗi URL",
                Content = "URL webhook chưa được cấu hình. Vui lòng nhập URL trong tab Webhook.",
                Duration = 5,
                Image = "alert-triangle", -- Lucide icon
            })
            return
        end
        
        -- Tạo phần thưởng giả
        local fakeReward = "2000 GEMS"
        if playerItems and playerItems["GEMS"] then
            fakeReward = playerItems["GEMS"] .. " GEMS"
        end
        
        print("Đang gửi webhook thủ công với phần thưởng: " .. fakeReward)
        
        -- Gọi hàm gửi webhook với phần thưởng hiện có
        local success = pcall(function()
            sendWebhook(fakeReward, nil, true)
        end)
        
        if success then
            Rayfield:Notify({
                Title = "Thành công",
                Content = "Đã gửi thông tin phần thưởng hiện tại qua webhook",
                Duration = 3,
                Image = "check", -- Lucide icon
            })
        else
            Rayfield:Notify({
                Title = "Lỗi",
                Content = "Không thể gửi webhook, vui lòng kiểm tra console",
                Duration = 5,
                Image = "x", -- Lucide icon
            })
        end
    end,
})

-- Set này dùng để theo dõi đã gửi webhook của phần thưởng
local sentRewards = {}

-- Kiểm tra phần thưởng mới từ thông báo "YOU GOT A NEW REWARD!"
checkNewRewardNotification = function(notificationContainer)
    if not notificationContainer then return end
    
    -- Tìm các thông tin phần thưởng trong thông báo
    local rewardText = ""
    
    for _, child in pairs(notificationContainer:GetDescendants()) do
        if child:IsA("TextLabel") and not child.Text:find("YOU GOT") then
            rewardText = rewardText .. child.Text .. " "
        end
    end
    
    -- Nếu tìm thấy thông tin phần thưởng
    if rewardText ~= "" then
        -- Tạo ID để kiểm tra
        local rewardId = createUniqueRewardId(rewardText)
        
        -- Nếu chưa gửi phần thưởng này
        if not sentRewards[rewardId] then
            sentRewards[rewardId] = true
            
            -- Đọc số lượng item hiện tại trước
            readActualItemQuantities()
            -- Gửi webhook với thông tin phần thưởng mới
            sendWebhook(rewardText, notificationContainer, true)
            return true
        end
    end
    
    return false
end

-- Kiểm tra phần thưởng mới
checkNewRewards = function(rewardsContainer)
    if not rewardsContainer then return end
    
    for _, rewardObject in pairs(rewardsContainer:GetChildren()) do
        if rewardObject:IsA("Frame") or rewardObject:IsA("ImageLabel") then
            -- Tìm các text label trong phần thưởng
            local rewardText = ""
            
            for _, child in pairs(rewardObject:GetDescendants()) do
                if child:IsA("TextLabel") then
                    rewardText = rewardText .. child.Text .. " "
                end
            end
            
            -- Nếu là phần thưởng có dữ liệu
            if rewardText ~= "" then
                -- Tạo ID để kiểm tra
                local rewardId = createUniqueRewardId(rewardText)
                
                -- Nếu chưa gửi phần thưởng này
                if not sentRewards[rewardId] then
                    sentRewards[rewardId] = true
                    sendWebhook(rewardText, rewardObject, false)
                end
            end
        end
    end
end

-- Kiểm tra khi nhận được phần thưởng mới
checkReceivedRewards = function(receivedContainer)
    if not receivedContainer then return end
    
    -- Đọc số lượng item hiện tại
    readActualItemQuantities()
    
    -- Ghi nhận đã kiểm tra RECEIVED
    local receivedMarked = false
    
    for _, rewardObject in pairs(receivedContainer:GetChildren()) do
        if rewardObject:IsA("Frame") or rewardObject:IsA("ImageLabel") then
            local rewardText = ""
            
            for _, child in pairs(rewardObject:GetDescendants()) do
                if child:IsA("TextLabel") then
                    rewardText = rewardText .. child.Text .. " "
                end
            end
            
            -- Nếu là phần thưởng có dữ liệu và chưa ghi nhận RECEIVED
            if rewardText ~= "" and not receivedMarked then
                receivedMarked = true
                
                -- Không gửi webhook từ phần RECEIVED nữa, chỉ ghi nhận đã đọc
                -- Webhook sẽ được gửi từ NEW REWARD hoặc REWARDS
                
                -- Đánh dấu tất cả phần thưởng từ RECEIVED đã được xử lý
                local rewardId = createUniqueRewardId("RECEIVED:" .. rewardText)
                sentRewards[rewardId] = true
            end
        end
    end
    
    -- Cập nhật thông tin hiển thị trong UI nếu có thay đổi
    if TotalRewardsLabel then
        local rewardsText = getTotalRewardsText()
        if rewardsText ~= TotalRewardsText then
            TotalRewardsText = rewardsText
            TotalRewardsLabel:Set({
                Title = "Tổng phần thưởng hiện có", 
                Content = rewardsText
            })
        end
    end
end

-- Tạo UI cấu hình Webhook (thay thế hàm cũ bằng các phần tử Rayfield)
local function createWebhookUI()
    -- Không cần tạo UI tùy chỉnh nữa vì đã dùng Rayfield
    print("Đã chuyển sang sử dụng Rayfield UI")
    
    -- Đọc số lượng item hiện tại và cập nhật hiển thị
    spawn(function()
        wait(1) -- Chờ UI khởi tạo xong
        readActualItemQuantities()
        local rewardsText = getTotalRewardsText()
        TotalRewardsText = rewardsText
        TotalRewardsLabel:Set({
            Title = "Tổng phần thưởng hiện có", 
            Content = rewardsText
        })
    end)
    
    return nil -- Không cần trả về UI nữa
end

-- Cập nhật hàm shutdownScript để hủy auto teleport
local originalShutdownScript = shutdownScript
shutdownScript = function()
    -- Dừng auto teleport
    autoTeleportRunning = false
    
    -- Gọi hàm tắt script gốc bằng pcall để tránh lỗi
    pcall(function()
        originalShutdownScript()
    end)
end

-- Khởi động auto teleport nếu đã được bật trước đó
spawn(function()
    wait(5) -- Đợi script khởi động hoàn tất
    
    -- Tải cài đặt từ Global nếu có
    loadGlobalSettings()
    
    -- Khởi động auto teleport nếu được bật
    if CONFIG.AUTO_TP_TO_AFK then
        startAutoTeleport()
    end
end)

-- Trích xuất số lượng từ chuỗi văn bản (ví dụ: từ "GEMS(10)" -> 10)
local function extractQuantity(text)
    if not text or type(text) ~= "string" then
        return nil
    end
    
    -- Tìm số lượng trong ngoặc đơn - ví dụ: GEMS(10)
    local quantity = text:match("%((%d+)%)")
    if quantity then
        return tonumber(quantity)
    end
    
    -- Tìm số lượng ở đầu chuỗi - ví dụ: 500 GEMS
    local prefixQuantity = text:match("^(%d+)%s+")
    if prefixQuantity then
        return tonumber(prefixQuantity)
    end
    
    return nil
end

-- Kiểm tra xem phần thưởng có phải là tiền (CASH) hay không
local function isCashReward(rewardText)
    if not rewardText or type(rewardText) ~= "string" then
        return false
    end
    
    return rewardText:find("CASH") ~= nil or 
           rewardText:find("MONEY") ~= nil or 
           rewardText:find("CURRENCY") ~= nil or
           rewardText:find("DOLLAR") ~= nil
end

-- Tạo ID duy nhất cho phần thưởng để tránh trùng lặp
local function createUniqueRewardId(rewardText)
    if type(rewardText) ~= "string" then
        return tostring(tick()) -- Sử dụng thời gian hiện tại nếu không có văn bản
    end
    
    -- Loại bỏ khoảng trắng và chuyển thành chữ thường
    local cleanText = rewardText:gsub("%s+", ""):lower()
    
    -- Kết hợp văn bản đã làm sạch với thời gian hiện tại (làm tròn đến giây)
    local currentTime = math.floor(tick() / 10) * 10
    return cleanText .. "_" .. tostring(currentTime)
end

-- Phân tích phần thưởng từ văn bản
local function parseReward(rewardText)
    if not rewardText or type(rewardText) ~= "string" then
        return nil, nil
    end
    
    -- Loại bỏ tiền tố không cần thiết
    local cleanText = rewardText:gsub("RECEIVED:%s*", "")
    cleanText = cleanText:gsub("YOU GOT A NEW REWARD!%s*", "")
    
    -- Pattern 1: Số lượng + Loại (ví dụ: "500 GEMS")
    local amount, itemType = cleanText:match("(%d+)%s+([%w%s]+)")
    
    -- Pattern 2: Loại(Số lượng) (ví dụ: "GEMS(10)")
    if not amount or not itemType then
        itemType, amount = cleanText:match("([%w%s]+)%((%d+)%)")
    end
    
    -- Pattern 3: Chỉ là tên vật phẩm đặc biệt (ví dụ: "TIGER")
    if not amount and not itemType then
        if cleanText:find("TIGER") then
            itemType = "TIGER"
            amount = 1
        elseif cleanText:find("TWIN PRISM BLADES") then
            itemType = "TWIN PRISM BLADES"
            amount = 1
        elseif cleanText:find("ZIRU G") then
            itemType = "ZIRU G"
            amount = 1
        end
    end
    
    -- Chuyển đổi số lượng thành số
    if amount then
        amount = tonumber(amount)
    end
    
    -- Làm sạch tên vật phẩm nếu có
    if itemType then
        itemType = itemType:gsub("^%s+", ""):gsub("%s+$", "")
    end
    
    return amount, itemType
end

-- Đặt các hàm này vào môi trường toàn cục để các hàm khác có thể sử dụng
_G.extractQuantity = extractQuantity
_G.isCashReward = isCashReward
_G.createUniqueRewardId = createUniqueRewardId
_G.parseReward = parseReward

-- Tạo nút để gửi webhook thủ công với phần thưởng hiện tại
local SendCurrentButton = RewardsTab:CreateButton({
    Name = "Gửi webhook phần thưởng hiện tại",
    Callback = function()
        -- Hiển thị thông báo đang gửi
        Rayfield:Notify({
            Title = "Đang gửi",
            Content = "Đang gửi thông tin phần thưởng hiện tại...",
            Duration = 2,
            Image = "loader", -- Lucide icon
        })
        
        -- Tạo nội dung phần thưởng hiện tại để gửi
        local currentRewardsText = ""
        if playerItems and next(playerItems) ~= nil then
            for itemType, amount in pairs(playerItems) do
                currentRewardsText = currentRewardsText .. amount .. " " .. itemType .. "\n"
            end
        else
            -- Đọc lại số lượng item
            pcall(function()
                readActualItemQuantities()
            end)
            
            -- Thử lại lấy dữ liệu sau khi đọc lại
            if playerItems and next(playerItems) ~= nil then
                for itemType, amount in pairs(playerItems) do
                    currentRewardsText = currentRewardsText .. amount .. " " .. itemType .. "\n"
                end
            else
                currentRewardsText = "2000 GEMS" -- Mặc định nếu không đọc được
            end
        end
        
        print("DEBUG: Nội dung phần thưởng sẽ gửi: " .. currentRewardsText)
        
        -- Kiểm tra URL webhook
        if not CONFIG.WEBHOOK_URL or CONFIG.WEBHOOK_URL == "YOUR_URL" or CONFIG.WEBHOOK_URL == "" then
            Rayfield:Notify({
                Title = "Lỗi URL",
                Content = "URL webhook chưa được cấu hình. Vui lòng nhập URL trong tab Webhook.",
                Duration = 5,
                Image = "alert-triangle", -- Lucide icon
            })
            return
        end
        
        print("DEBUG: URL Webhook: " .. CONFIG.WEBHOOK_URL:sub(1, 30) .. "...")
        
        -- Gửi webhook thủ công
        local data = {
            content = nil,
            embeds = {
                {
                    title = "🎮 Arise Crossover - Phần thưởng hiện tại",
                    description = "Phần thưởng hiện có trong game",
                    color = 7419530, -- Màu xanh biển
                    fields = {
                        {
                            name = "Danh sách phần thưởng",
                            value = currentRewardsText ~= "" and currentRewardsText or "Không có phần thưởng",
                            inline = false
                        },
                        {
                            name = "Thời gian",
                            value = os.date("%d/%m/%Y %H:%M:%S"),
                            inline = true
                        },
                        {
                            name = "Người chơi",
                            value = Player.Name,
                            inline = true
                        }
                    },
                    footer = {
                        text = "Arise Crossover Rewards Tracker - Webhook độc quyền của DuongTuan"
                    }
                }
            }
        }
        
        -- Chuyển đổi dữ liệu thành chuỗi JSON
        local jsonData = ""
        local jsonSuccess = pcall(function()
            jsonData = HttpService:JSONEncode(data)
        end)
        
        if not jsonSuccess or jsonData == "" then
            Rayfield:Notify({
                Title = "Lỗi JSON",
                Content = "Không thể tạo dữ liệu JSON",
                Duration = 5,
                Image = "x", -- Lucide icon
            })
            return
        end
        
        print("DEBUG: Chuỗi JSON đã tạo thành công, độ dài: " .. #jsonData)
        
        -- Gửi HTTP request
        local success, result = false, "Không tìm thấy phương thức HTTP nào"
        
        -- Thử từng phương thức HTTP
        if syn and syn.request then
            print("DEBUG: Đang gửi qua syn.request")
            success, result = pcall(function()
                return syn.request({
                    Url = CONFIG.WEBHOOK_URL,
                    Method = "POST",
                    Headers = {
                        ["Content-Type"] = "application/json"
                    },
                    Body = jsonData
                })
            end)
            print("DEBUG: Kết quả syn.request - Success: " .. tostring(success) .. ", Status: " .. (success and (result.StatusCode or "N/A") or "Lỗi"))
        elseif request then
            print("DEBUG: Đang gửi qua request")
            success, result = pcall(function()
                return request({
                    Url = CONFIG.WEBHOOK_URL,
                    Method = "POST",
                    Headers = {
                        ["Content-Type"] = "application/json"
                    },
                    Body = jsonData
                })
            end)
            print("DEBUG: Kết quả request - Success: " .. tostring(success) .. ", Status: " .. (success and (result.StatusCode or "N/A") or "Lỗi"))
        elseif http and http.request then
            print("DEBUG: Đang gửi qua http.request")
            success, result = pcall(function()
                return http.request({
                    Url = CONFIG.WEBHOOK_URL,
                    Method = "POST",
                    Headers = {
                        ["Content-Type"] = "application/json"
                    },
                    Body = jsonData
                })
            end)
            print("DEBUG: Kết quả http.request - Success: " .. tostring(success) .. ", Status: " .. (success and "OK" or "Lỗi"))
        elseif httppost then
            print("DEBUG: Đang gửi qua httppost")
            success, result = pcall(function()
                return httppost(CONFIG.WEBHOOK_URL, jsonData)
            end)
            print("DEBUG: Kết quả httppost - Success: " .. tostring(success))
        else
            print("DEBUG: Không tìm thấy phương thức HTTP nào được hỗ trợ")
        end
        
        if success then
            Rayfield:Notify({
                Title = "Thành công",
                Content = "Đã gửi thông tin phần thưởng hiện tại qua webhook",
                Duration = 3,
                Image = "check", -- Lucide icon
            })
        else
            Rayfield:Notify({
                Title = "Lỗi gửi webhook",
                Content = "Không thể gửi webhook: " .. tostring(result),
                Duration = 5,
                Image = "x", -- Lucide icon
            })
        end
    end,
})

-- Cập nhật nút Test Webhook để hiển thị thêm thông tin debug
local TestButton = MainTab:CreateButton({
    Name = "Kiểm tra kết nối Webhook",
    Callback = function()
        -- Hiển thị thông báo đang kiểm tra
        Rayfield:Notify({
            Title = "Đang kiểm tra",
            Content = "Đang gửi webhook thử nghiệm...",
            Duration = 2,
            Image = "loader", -- Lucide icon
        })
        
        -- Debug thông tin
        print("DEBUG: URL Webhook: " .. (CONFIG.WEBHOOK_URL or "nil"))
        print("DEBUG: Executor hiện tại:")
        print("  - syn.request: " .. tostring(syn and syn.request ~= nil))
        print("  - request: " .. tostring(request ~= nil))
        print("  - http.request: " .. tostring(http and http.request ~= nil))
        print("  - httppost: " .. tostring(httppost ~= nil))
        
        -- Thử gửi webhook kiểm tra
        local success = sendTestWebhook("Kiểm tra kết nối từ Arise Crossover Rewards Tracker")
        
        if success then
            Rayfield:Notify({
                Title = "Thành công",
                Content = "Kiểm tra webhook thành công!",
                Duration = 3,
                Image = "check", -- Lucide icon
            })
        else
            Rayfield:Notify({
                Title = "Lỗi",
                Content = "Kiểm tra webhook thất bại, vui lòng kiểm tra URL!",
                Duration = 5,
                Image = "x", -- Lucide icon
            })
        end
    end,
})
