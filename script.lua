local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Thay URL webhook của bạn vào đây
local WEBHOOK_URL = "https://discord.com/api/webhooks/1353364994905079828/dUnPYd2A2GzaagDKIXiZLPd5LZMi9HCHTrtNMAkIKbyHdGnwn26leSxfjlVJkvQNWEkp"

-- Hàm lấy thông tin seeds
local function getSeedsData()
    local seedsFolder = ReplicatedStorage:FindFirstChild("Assets")
    if seedsFolder then
        seedsFolder = seedsFolder:FindFirstChild("Seeds")
    end
    
    if not seedsFolder then
        warn("Không tìm thấy folder Seeds")
        return nil
    end
    
    local seedsData = {}
    
    for _, seed in ipairs(seedsFolder:GetChildren()) do
        local seedInfo = {
            Name = seed.Name,
            Price = seed:GetAttribute("Price") or 0,
            Stock = seed:GetAttribute("Stock") or 0,
            Plant = seed:GetAttribute("Plant") or "Unknown"
        }
        table.insert(seedsData, seedInfo)
    end
    
    return seedsData
end

-- Hàm gửi data về webhook
local function sendToWebhook(data)
    if not data then return end
    
    local embedFields = {}
    
    for _, seed in ipairs(data) do
        table.insert(embedFields, {
            name = seed.Name,
            value = string.format("🌱 Plant: %s\n💰 Price: %d\n📦 Stock: %d", 
                seed.Plant, seed.Price, seed.Stock),
            inline = true
        })
    end
    
    local payload = {
        embeds = {{
            title = "🌾 Seeds Information",
            description = "Thông tin chi tiết về tất cả seeds",
            color = 3066993,
            fields = embedFields,
            timestamp = os.date("!%Y-%m-%dT%H:%M:%S")
        }}
    }
    
    local jsonPayload = HttpService:JSONEncode(payload)
    
    local success, response = pcall(function()
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
        print("✅ Đã gửi data về webhook thành công!")
    else
        warn("❌ Lỗi khi gửi webhook:", response)
    end
end

-- Loop gửi mỗi 10 giây
while true do
    local seedsData = getSeedsData()
    sendToWebhook(seedsData)
    wait(10)
end
