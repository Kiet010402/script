--// CONFIG
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WebhookURL = "https://discord.com/api/webhooks/1421839599407333438/GNFpTJi0tFwx-76k6o6gYDVZZEd4ojtEDehQfBLc62F8HPSIGR2ShqXE_nJnnzBTSSl8" -- thay webhook vào đây

--// Hàm format số (1000 -> 1k, 1000000 -> 1m)
local function formatNumber(n)
    if n >= 1e6 then
        return string.format("%dm", n/1e6)
    elseif n >= 1e3 then
        return string.format("%dk", n/1e3)
    else
        return tostring(n)
    end
end

--// Gửi Embed cho đẹp
local function sendToWebhook(embed)
    local data = {
        username = "Shop Stock Bot",
        avatar_url = "", -- icon cây cho đẹp
        embeds = {embed}
    }

    local jsonData = HttpService:JSONEncode(data)

    HttpService:PostAsync(WebhookURL, jsonData, Enum.HttpContentType.ApplicationJson)
end

--// Lắng nghe Timer về 00:00
local Timer = workspace.Plots["3"].NPCs.George.Timer.Timer

Timer:GetPropertyChangedSignal("Text"):Connect(function()
    if Timer.Text == "00:00" then
        task.wait(1) -- đợi 1s cho chắc chắn
        local Seeds = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Seeds")

        local description = ""

        for _, seed in pairs(Seeds:GetChildren()) do
            local price = seed:FindFirstChild("Price") and seed.Price.Value or 0
            local stock = seed:FindFirstChild("Stock") and seed.Stock.Value or "?"
            description ..= string.format("**%s**\nPrice: `%s`\nStock: `%s`\n\n", seed.Name, formatNumber(price), stock)
        end

        local embed = {
            title = "🌾 Shop Stock Update 🌾",
            description = description,
            color = 0x57F287, -- màu xanh lá
            footer = { text = "Cập nhật tự động từ game" },
            timestamp = DateTime.now():ToIsoDate()
        }

        sendToWebhook(embed)
    end
end)

