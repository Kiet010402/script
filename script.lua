--// CONFIG
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Plots = workspace:WaitForChild("Plots")
local WebhookURL = "https://discord.com/api/webhooks/1353364994905079828/dUnPYd2A2GzaagDKIXiZLPd5LZMi9HCHTrtNMAkIKbyHdGnwn26leSxfjlVJkvQNWEkp" -- thay link webhook vào

--// Format số (1000 -> 1k, 1000000 -> 1m)
local function formatNumber(n)
    if n >= 1e6 then
        return string.format("%.1fm", n/1e6)
    elseif n >= 1e3 then
        return string.format("%.1fk", n/1e3)
    else
        return tostring(n)
    end
end

--// Hàm gửi webhook
local function sendToWebhook()
    local success, err = pcall(function()
        local Seeds = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Seeds")
        local description = ""
        
        for _, seed in pairs(Seeds:GetChildren()) do
            -- FIX: Dùng GetAttribute thay vì .Value
            local price = seed:GetAttribute("Price") or 0
            local stock = seed:GetAttribute("Stock") or 0
            local plant = seed:GetAttribute("Plant") or seed.Name
            
            description = description .. string.format(
                "**%s**\n🌱 Plant: `%s`\n💰 Price: `%s`\n📦 Stock: `%s`\n\n", 
                seed.Name, 
                plant,
                formatNumber(price), 
                tostring(stock)
            )
        end
        
        local embed = {
            title = "🌾 Shop Stock Update 🌾",
            description = description,
            color = 5763719, -- 0x57F287
            footer = { text = "Cập nhật tự động từ game" },
            timestamp = DateTime.now():ToIsoDate()
        }
        
        local data = {
            username = "🌱 Shop Stock Bot 🌱",
            embeds = {embed}
        }
        
        local jsonData = HttpService:JSONEncode(data)
        
        -- FIX: Thêm xử lý lỗi chi tiết hơn
        local response = HttpService:PostAsync(
            WebhookURL, 
            jsonData, 
            Enum.HttpContentType.ApplicationJson,
            false
        )
        
        print("✅ Webhook sent successfully!")
        return response
    end)
    
    if not success then
        warn("❌ Lỗi khi gửi webhook:", err)
    end
end

--// Hàm gắn sự kiện theo dõi Timer
local function setupTimer(plot)
    local success, err = pcall(function()
        local npcFolder = plot:WaitForChild("NPCs", 5)
        if not npcFolder then return end
        
        local george = npcFolder:WaitForChild("George", 5)
        if not george then return end
        
        local timerFolder = george:WaitForChild("Timer", 5)
        if not timerFolder then return end
        
        local timer = timerFolder:WaitForChild("Timer", 5)
        if not timer or not timer:IsA("TextLabel") then return end
        
        print("✅ Đã gắn timer cho plot:", plot.Name)
        
        -- Gắn sự kiện khi text đổi
        timer:GetPropertyChangedSignal("Text"):Connect(function()
            if timer.Text == "00:00" then
                print("⏰ Timer đã về 00:00, đang gửi webhook...")
                task.wait(1)
                sendToWebhook()
            end
        end)
    end)
    
    if not success then
        warn("⚠️ Không thể setup timer cho plot:", plot.Name, "-", err)
    end
end

--// Theo dõi tất cả plots hiện có
for _, plot in pairs(Plots:GetChildren()) do
    task.spawn(function()
        setupTimer(plot)
    end)
end

--// Nếu sau này có plot mới sinh ra
Plots.ChildAdded:Connect(function(plot)
    task.spawn(function()
        setupTimer(plot)
    end)
end)

print("🚀 Script đã khởi động! Đang theo dõi timer...")

-- Test gửi webhook ngay khi khởi động (tùy chọn)
-- task.wait(2)
-- sendToWebhook()
