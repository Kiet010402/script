local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Webhook của bạn (thay URL ở đây)
local WEBHOOK_URL = "https://discord.com/api/webhooks/1421839599407333438/GNFpTJi0tFwx-76k6o6gYDVZZEd4ojtEDehQfBLc62F8HPSIGR2ShqXE_nJnnzBTSSl8"

-- Folder chứa seeds
local seedsFolder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Seeds")

-- Hàm lấy dữ liệu seeds
local function collectSeedsData()
	local data = {}
	
	for _, seed in ipairs(seedsFolder:GetChildren()) do
		if seed:IsA("Model") or seed:IsA("Folder") or seed:IsA("Part") then
			local seedInfo = {}
			for _, attrName in ipairs(seed:GetAttributes()) do
				seedInfo[attrName] = seed:GetAttribute(attrName)
			end
			data[seed.Name] = seedInfo
		end
	end
	
	return data
end

-- Hàm gửi webhook
local function sendWebhook()
	local seedsData = collectSeedsData()
	
	local payload = {
		content = "**Seeds Data Update**",
		embeds = {{
			title = "Seeds Info",
			description = "Tổng hợp toàn bộ Seeds trong game",
			color = 3447003,
			fields = {}
		}}
	}
	
	-- Thêm từng seed vào embed
	for seedName, info in pairs(seedsData) do
		table.insert(payload.embeds[1].fields, {
			name = seedName,
			value = string.format("Price: %s\nStock: %s", tostring(info.Price), tostring(info.Stock)),
			inline = false
		})
	end
	
	-- Gửi request
	local jsonData = HttpService:JSONEncode(payload)
	HttpService:PostAsync(WEBHOOK_URL, jsonData, Enum.HttpContentType.ApplicationJson)
end

-- Lặp lại mỗi 10 giây
while true do
	sendWebhook()
	wait(10)
end
