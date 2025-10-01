-- Shop Stock Webhook Tracker
local WEBHOOK_URL = "https://discord.com/api/webhooks/1353364994905079828/dUnPYd2A2GzaagDKIXiZLPd5LZMi9HCHTrtNMAkIKbyHdGnwn26leSxfjlVJkvQNWEkp"

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- Hàm format số tiền
local function formatPrice(price)
    if price >= 1000000 then
        local millions = math.floor(price / 1000000)
        local remainder = price % 1000000
        local thousands = math.floor(remainder / 100000)
        
        if thousands > 0 then
            return string.format("%dM%d", millions, thousands)
        else
            return string.format("%dM", millions)
        end
    elseif price >= 1000 then
        local thousands = math.floor(price / 100)
        return string.format("%dK", thousands)
    else
        return tostring(price)
    end
end

-- Hàm tạo embed đẹp cho webhook
local function createStockEmbed(stockData)
    local fields = {}
    local totalSeeds = 0
    local totalStock = 0
    
    -- Sắp xếp theo tên
    local sortedSeeds = {}
    for seedName, data in pairs(stockData) do
        table.insert(sortedSeeds, {name = seedName, data = data})
    end
    table.sort(sortedSeeds, function(a, b) return a.name < b.name end)
    
    -- Tạo fields cho embed
    for _, seed in ipairs(sortedSeeds) do
        local stockStatus = seed.data.Stock > 0 and "✅" or "❌"
        
        table.insert(fields, {
            name = seed.name,
            value = string.format("```\n💰 Price: %s\n📦 Stock: %d %s\n```", 
                formatPrice(seed.data.Price),
                seed.data.Stock,
                stockStatus
            ),
            inline = true
        })
        
        totalSeeds = totalSeeds + 1
        totalStock = totalStock + seed.data.Stock
    end
    
    local embed = {
        title = "🏪 SHOP STOCK UPDATE",
        description = "**George's Seed Shop has restocked!**\n━━━━━━━━━━━━━━━━━━━━",
        color = 3066993, -- Màu xanh lá
        fields = fields,
        footer = {
            text = string.format("📊 Total: %d Seeds | 📦 Total Stock: %d items", totalSeeds, totalStock),
            icon_url = "https://cdn.discordapp.com/emojis/1234567890.png"
        },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        thumbnail = {
            url = "https://cdn-icons-png.flaticon.com/512/1652/1652967.png"
        }
    }
    
    return {
        username = "Shop Stock Bot",
        avatar_url = "https://cdn-icons-png.flaticon.com/512/2331/2331966.png",
        embeds = {embed}
    }
end

-- Hàm gửi webhook
local function sendWebhook(stockData)
    local success, result = pcall(function()
        local payload = createStockEmbed(stockData)
        local jsonPayload = HttpService:JSONEncode(payload)
        
        return request({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = jsonPayload
        })
    end)
    
    if success then
        print("✅ Webhook sent successfully!")
    else
        warn("❌ Failed to send webhook:", result)
    end
end

-- Hàm thu thập dữ liệu stock
local function collectStockData()
    local stockData = {}
    local seedsFolder = ReplicatedStorage.Assets.Seeds
    
    for _, seed in pairs(seedsFolder:GetChildren()) do
        if seed:IsA("Folder") or seed:IsA("Model") then
            local price = seed:FindFirstChild("Price")
            local stock = seed:FindFirstChild("Stock")
            
            if price and stock then
                stockData[seed.Name] = {
                    Price = price.Value,
                    Stock = stock.Value
                }
            end
        end
    end
    
    return stockData
end

-- Hàm chính để theo dõi timer
local function monitorShopTimer()
    local timerPath = workspace.Plots["3"].NPCs.George.Timer.Timer
    local lastTimeValue = timerPath.Text
    local hasSentWebhook = false
    
    print("🔍 Monitoring George's shop timer...")
    
    RunService.Heartbeat:Connect(function()
        local currentTime = timerPath.Text
        
        -- Kiểm tra nếu timer về 00:00
        if currentTime == "00:00" and lastTimeValue ~= "00:00" then
            print("⏰ Timer reached 00:00! Waiting 1 second...")
            hasSentWebhook = false
            
            task.wait(1)
            
            if not hasSentWebhook then
                print("📦 Collecting stock data...")
                local stockData = collectStockData()
                
                if next(stockData) then
                    print("📤 Sending webhook...")
                    sendWebhook(stockData)
                    hasSentWebhook = true
                else
                    warn("⚠️ No stock data found!")
                end
            end
        end
        
        lastTimeValue = currentTime
    end)
end

-- Khởi chạy script
print("=" .. string.rep("=", 50))
print(" Shop Stock Webhook Tracker Started!")
print("=" .. string.rep("=", 50))

local success, err = pcall(monitorShopTimer)

if not success then
    warn("❌ Error starting monitor:", err)
end
