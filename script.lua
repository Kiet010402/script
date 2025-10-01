local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remote = Instance.new("RemoteEvent")
remote.Name = "SendStockWebhook"
remote.Parent = ReplicatedStorage

local WebhookURL = "https://discord.com/api/webhooks/1353364994905079828/dUnPYd2A2GzaagDKIXiZLPd5LZMi9HCHTrtNMAkIKbyHdGnwn26leSxfjlVJkvQNWEkp"

local function formatNumber(n)
    if n >= 1e6 then
        return string.format("%dm", n/1e6)
    elseif n >= 1e3 then
        return string.format("%dk", n/1e3)
    else
        return tostring(n)
    end
end

local function sendToWebhook()
    local Seeds = ReplicatedStorage.Assets.Seeds
    local description = ""

    for _, seed in pairs(Seeds:GetChildren()) do
        local price = seed:FindFirstChild("Price") and seed.Price.Value or 0
        local stock = seed:FindFirstChild("Stock") and seed.Stock.Value or "?"
        description ..= string.format("**%s**\nPrice: `%s`\nStock: `%s`\n\n", seed.Name, formatNumber(price), stock)
    end

    local embed = {
        title = "🌾 Shop Stock Update 🌾",
        description = description,
        color = 0x57F287,
        footer = { text = "Cập nhật tự động từ game" },
        timestamp = DateTime.now():ToIsoDate()
    }

    local data = {
        username = "🌱 Shop Stock Bot 🌱",
        embeds = {embed}
    }

    local jsonData = HttpService:JSONEncode(data)
    HttpService:PostAsync(WebhookURL, jsonData, Enum.HttpContentType.ApplicationJson)
end

remote.OnServerEvent:Connect(function()
    sendToWebhook()
end)
