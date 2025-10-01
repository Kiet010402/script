--// CONFIG
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Plots = workspace:WaitForChild("Plots")
local WebhookURL = "https://discord.com/api/webhooks/1358845419244879932/lLSX0FjOYnWJ-NK9HK-t96YVZMpn35NozjcHWPx_0rPVA2gbvxHbVKZ4sMZaUw683oBP" -- thay link webhook vào

--// Format số (1000 -> 1k, 1000000 -> 1m)
local function formatNumber(n)
    if n >= 1e6 then
        return string.format("%dm", n/1e6)
    elseif n >= 1e3 then
        return string.format("%dk", n/1e3)
    else
        return tostring(n)
    end
end

--// Hàm gửi webhook
local function sendToWebhook()
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

--// Hàm gắn sự kiện theo dõi Timer
local function setupTimer(plot)
    local npcFolder = plot:FindFirstChild("NPCs")
    if not npcFolder then return end

    local george = npcFolder:FindFirstChild("George")
    if not george then return end

    local timerFolder = george:FindFirstChild("Timer")
    if not timerFolder then return end

    local timer = timerFolder:FindFirstChild("Timer")
    if not timer or not timer:IsA("TextLabel") then return end

    -- Gắn sự kiện khi text đổi
    timer:GetPropertyChangedSignal("Text"):Connect(function()
        if timer.Text == "00:00" then
            task.wait(1)
            sendToWebhook()
        end
    end)
end

--// Theo dõi tất cả plots hiện có
for _, plot in pairs(Plots:GetChildren()) do
    setupTimer(plot)
end

--// Nếu sau này có plot mới sinh ra
Plots.ChildAdded:Connect(function(plot)
    setupTimer(plot)
end)
