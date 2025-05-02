    -- FPS Boost Script for Mobile by Claude
    -- Features: Removes map elements, removes all water, disables sound, optimizes graphics, shows FPS counter

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local SoundService = game:GetService("SoundService")
    local Lighting = game:GetService("Lighting")
    local Terrain = workspace:FindFirstChildOfClass("Terrain")
    local UserInputService = game:GetService("UserInputService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local MaterialService = game:GetService("MaterialService")

    -- FPS Counter Setup (Mobile-friendly)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "FPSCounter"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- For mobile, parent to PlayerGui instead of CoreGui
    local player = Players.LocalPlayer
    if player then
        ScreenGui.Parent = player:WaitForChild("PlayerGui")
    end

    local TextLabel = Instance.new("TextLabel")
    TextLabel.Name = "FPSText"
    TextLabel.Size = UDim2.new(0, 100, 0, 30)
    TextLabel.Position = UDim2.new(0, 10, 0, 10)
    TextLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    TextLabel.BackgroundTransparency = 0.5
    TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TextLabel.Font = Enum.Font.SourceSansBold
    TextLabel.TextSize = 18
    TextLabel.Text = "FPS: --"
    TextLabel.Parent = ScreenGui

    -- Create toggle button for mobile
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Name = "ToggleFPS"
    ToggleButton.Size = UDim2.new(0, 40, 0, 40)
    ToggleButton.Position = UDim2.new(0, 120, 0, 5)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    ToggleButton.BackgroundTransparency = 0.3
    ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.Font = Enum.Font.SourceSansBold
    ToggleButton.TextSize = 12
    ToggleButton.Text = "Hide"
    ToggleButton.Parent = ScreenGui

    -- Function to completely remove water
    local function removeAllWater()
        -- Terrain water removal (completely disable water)
        if Terrain then
            -- Set water properties to invisible
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
            Terrain.WaterReflectance = 0
            Terrain.WaterTransparency = 1
            
            -- Try to remove water completely
            if Terrain:FindFirstChild("Water") then
                Terrain.Water:Destroy()
            end
            
            -- Try to disable water via material
            pcall(function()
                Terrain:SetMaterialColor(Enum.Material.Water, Color3.new(0, 0, 0))
                Terrain:SetMaterialColor(Enum.Material.Air, Color3.new(0, 0, 0))
                
                -- Clear all water cells in terrain
                local regionToReplace = Region3.new(Vector3.new(-10000, -10000, -10000), Vector3.new(10000, 10000, 10000))
                Terrain:ReplaceMaterial(regionToReplace, Enum.Material.Water, Enum.Material.Air)
            end)
        end
        
        -- Find all water parts by name or appearance
        local waterKeywords = {"water", "ocean", "lake", "pond", "puddle", "liquid", "fluid", "sea"}
        
        -- Remove all meshes or parts that might be water
        for _, part in pairs(workspace:GetDescendants()) do
            -- Check for water in name
            local name = part.Name:lower()
            local isWaterByName = false
            
            for _, keyword in ipairs(waterKeywords) do
                if name:match(keyword) then
                    isWaterByName = true
                    break
                end
            end
            
            -- Handle Parts
            if part:IsA("BasePart") then
                -- Remove water by name
                if isWaterByName then
                    part.Transparency = 1
                    part.CanCollide = false
                end
                
                -- Remove water by color (blue-ish)
                local color = part.Color
                if color.b > 0.7 and color.g > 0.4 and color.r < 0.6 then
                    part.Transparency = 1
                end
                
                -- Remove water by material
                if part.Material == Enum.Material.Water or part.Material == Enum.Material.Glass then
                    part.Transparency = 1
                    part.CanCollide = false
                end
            end
            
            -- Handle MeshParts specifically
            if part:IsA("MeshPart") and (isWaterByName or part.TextureID:match("water")) then
                part.Transparency = 1
                part.CanCollide = false
            end
            
            -- Disable water animations or scripts
            if part:IsA("Script") or part:IsA("LocalScript") then
                if isWaterByName then
                    pcall(function() part.Disabled = true end)
                end
            end
            
            -- Disable water-related particles or effects
            if part:IsA("ParticleEmitter") or part:IsA("Beam") or part:IsA("Trail") then
                part.Enabled = false
            end
        end
        
        -- Try to modify water shader/material if it exists
        pcall(function()
            if MaterialService:FindFirstChild("Water") then
                MaterialService.Water.Transparency = 1
            end
        end)
        
        -- Look for and disable custom water systems in ReplicatedStorage
        pcall(function()
            for _, item in pairs(ReplicatedStorage:GetDescendants()) do
                local name = item.Name:lower()
                for _, keyword in ipairs(waterKeywords) do
                    if name:match(keyword) and item:IsA("ModuleScript") then
                        item.Disabled = true
                    end
                end
            end
        end)
    end

    -- Function to remove map elements
    local function removeMapElements()
        -- For terrain, make it invisible but still collidable
        if Terrain then
            -- Disable terrain rendering
            pcall(function()
                Terrain.Decoration = false
                
                -- Make terrain transparent
                for _, material in pairs(Enum.Material:GetEnumItems()) do
                    pcall(function()
                        Terrain:SetMaterialColor(material, Color3.new(0, 0, 0))
                        if material ~= Enum.Material.Water then
                            local transparency = 0.9
                            -- Keep only basic platforms
                            if material == Enum.Material.Plastic or 
                               material == Enum.Material.Concrete or 
                               material == Enum.Material.Brick then
                                transparency = 0.7
                            end
                            Terrain:SetMaterialTransparency(material, transparency)
                        end
                    end)
                end
            end)
        end
        
        -- Remove decorative elements from the map
        local decorKeywords = {"tree", "bush", "plant", "flower", "grass", "rock", "stone", "decoration", 
                              "detail", "prop", "fence", "wall", "building", "structure", "decor", "foliage"}
        
        -- Remove or make transparent map elements
        for _, obj in pairs(workspace:GetDescendants()) do
            -- Skip player characters and important gameplay elements
            if not (obj:IsA("Model") and Players:GetPlayerFromCharacter(obj)) then
                -- Check if the object is decorative
                local isDecorative = false
                local name = obj.Name:lower()
                
                for _, keyword in ipairs(decorKeywords) do
                    if name:match(keyword) then
                        isDecorative = true
                        break
                    end
                end
                
                -- Handle different types of objects
                if obj:IsA("BasePart") then
                    -- Handle decorative parts
                    if isDecorative then
                        obj.Transparency = 1
                    end
                    
                    -- Make less important parts translucent
                    if not obj:FindFirstChildOfClass("HumanoidRootPart") and 
                       not obj.Name:lower():match("platform") and
                       not obj.Name:lower():match("spawn") and
                       not obj.Name:lower():match("player") then
                        -- Don't completely hide but make very transparent
                        obj.Transparency = math.max(obj.Transparency, 0.8)
                    end
                    
                    -- Remove texture
                    if obj:IsA("Part") or obj:IsA("MeshPart") then
                        obj.Material = Enum.Material.SmoothPlastic
                        obj.TextureID = ""
                    end
                end
                
                -- Disable all meshes that are not critical
                if (obj:IsA("SpecialMesh") or obj:IsA("MeshPart")) and isDecorative then
                    if obj:IsA("SpecialMesh") then
                        obj.MeshId = ""
                        obj.TextureId = ""
                    else
                        obj.Transparency = 1
                    end
                end
            end
        end
    end

    -- Function to remove all effects
    local function removeAllEffects()
        -- Remove all effects
        for _, obj in pairs(game:GetDescendants()) do
            -- Disable particles and effects
            if obj:IsA("ParticleEmitter") or obj:IsA("Beam") or 
               obj:IsA("Trail") or obj:IsA("Smoke") or 
               obj:IsA("Fire") or obj:IsA("Sparkles") or
               obj:IsA("BillboardGui") or obj:IsA("Explosion") then
                obj.Enabled = false
            end
            
            -- Remove textures from parts
            if obj:IsA("BasePart") then
                if obj.Transparency < 0.9 and not obj.Name:lower():match("character") then
                    obj.Material = Enum.Material.SmoothPlastic
                    obj.Reflectance = 0
                end
            end
            
            -- Attempt to disable animations
            local success, err = pcall(function()
                if obj:IsA("AnimationController") then
                    obj.Name = obj.Name .. "_disabled"
                end
            end)
            
            -- Disable scripts related to visual effects
            if (obj:IsA("Script") or obj:IsA("LocalScript")) and not obj.Disabled then
                local name = obj.Name:lower()
                if name:match("effect") or name:match("visual") or name:match("particle") or 
                   name:match("anim") or name:match("emitter") then
                    pcall(function() obj.Disabled = true end)
                end
            end
        end
        
        -- Completely disable Lighting effects
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.Brightness = 2
        Lighting.GlobalShadows = false
        Lighting.ShadowSoftness = 0
        Lighting.ClockTime = 12 -- Mid-day for maximum brightness
        
        -- Disable all post-processing effects
        for _, effect in pairs(Lighting:GetChildren()) do
            if effect:IsA("PostEffect") or
               effect:IsA("Atmosphere") or 
               effect:IsA("Sky") or 
               effect:IsA("BloomEffect") or 
               effect:IsA("BlurEffect") or 
               effect:IsA("ColorCorrectionEffect") or 
               effect:IsA("DepthOfFieldEffect") or 
               effect:IsA("SunRaysEffect") then
                effect.Enabled = false
            end
        end
    end

    -- Function to optimize graphics
    local function optimizeGraphics()
        -- First completely remove map elements
        removeMapElements()
        
        -- Then remove water
        removeAllWater()
        
        -- Remove all visual effects
        removeAllEffects()
        
        -- Disable all sound
        SoundService.Volume = 0
        
        -- Optimize rendering for mobile
        settings().Rendering.QualityLevel = 1
        
        -- Mobile-specific optimizations
        if UserInputService.TouchEnabled then
            settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
            settings().Rendering.EagerBulkExecution = false
        end
        
        -- Reduce graphics quality to minimum
        UserSettings().GameSettings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
        settings().Rendering.QualityLevel = 1
        
        -- Try to minimize rendering distance
        pcall(function()
            settings().Network.IncomingReplicationLag = 0
            settings().Rendering.MaxPartCount = 100000
        end)
        
        -- Other graphics settings
        pcall(function()
            settings().Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Disabled
            settings().Physics.AllowSleep = true
            settings().Physics.DisableCSGv2 = true
            settings().Rendering.AutoFRMLevel = true
            settings().Rendering.EditQualityLevel = 1
            settings().Rendering.QualityLevel = 1
            settings().Rendering.ReloadAssets = false
            settings().Rendering.GraphicsMode = 2
        end)
    end

    -- FPS Counter update
    local fpsCount = 0
    local fpsTimer = tick()

    RunService.RenderStepped:Connect(function()
        fpsCount = fpsCount + 1
        
        if (tick() - fpsTimer) >= 1 then
            TextLabel.Text = "FPS: "..tostring(fpsCount)
            fpsCount = 0
            fpsTimer = tick()
        end
    end)

    -- Toggle FPS counter with button for mobile
    ToggleButton.TouchTap:Connect(function()
        if TextLabel.Visible then
            TextLabel.Visible = false
            ToggleButton.Text = "Show"
        else
            TextLabel.Visible = true
            ToggleButton.Text = "Hide"
        end
    end)

    -- Setup automatic optimization every few seconds
    spawn(function()
        while wait(5) do
            removeAllWater()
            removeAllEffects()
        end
    end)

    -- Run optimization
    optimizeGraphics()

    print("Mobile FPS Boost Script đã được kích hoạt!")
    print("Nhấn nút ở góc màn hình để ẩn/hiện bộ đếm FPS")
    print("Đã loại bỏ map, nước và tất cả hiệu ứng đồ họa!")
