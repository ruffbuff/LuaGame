-- scripts/world/resources.lua

local settings = require("scripts.main.settings")

local resources = {
    items = {},  -- все ресурсы на карте
    types = {
        -- Базовые ресурсы
        wood = {
            name = "Wood",
            color = {0.6, 0.4, 0.2},
            size = 8,
            value = 1,
            spawnChance = 0.3,
            biomes = {"forest", "plains"}
        },
        stone = {
            name = "Stone", 
            color = {0.5, 0.5, 0.5},
            size = 6,
            value = 1,
            spawnChance = 0.2,
            biomes = {"mountains", "plains"}
        },
        berry = {
            name = "Berry",
            color = {0.8, 0.2, 0.4},
            size = 4,
            value = 15,  -- восстанавливает голод
            spawnChance = 0.1,
            biomes = {"forest", "plains"},
            consumable = true,
            effect = "food"
        },
        water = {
            name = "Water Drop",
            color = {0.2, 0.6, 1.0},
            size = 5,
            value = 20,  -- восстанавливает жажду
            spawnChance = 0.08,
            biomes = {"swamp", "plains"},
            consumable = true,
            effect = "drink"
        }
    }
}

function resources.spawn(x, y, resourceType)
    local resource = {
        x = x,
        y = y,
        type = resourceType,
        collected = false,
        spawnTime = love.timer.getTime()
    }
    table.insert(resources.items, resource)
end

function resources.generateInArea(startX, startY, width, height, biome)
    biome = biome or "plains"
    
    for resourceType, data in pairs(resources.types) do
        -- Проверяем, может ли этот ресурс появиться в данном биоме
        local canSpawn = false
        for _, allowedBiome in ipairs(data.biomes) do
            if allowedBiome == biome then
                canSpawn = true
                break
            end
        end
        
        if canSpawn then
            -- Генерируем ресурсы с определённой вероятностью
            for x = startX, startX + width do
                for y = startY, startY + height do
                    if love.math.random() < data.spawnChance * 0.01 then  -- снижаем плотность
                        -- Добавляем случайный offset чтобы не все были в центре тайла
                        local offsetX = love.math.random(-settings.TILE_SIZE/3, settings.TILE_SIZE/3)
                        local offsetY = love.math.random(-settings.TILE_SIZE/3, settings.TILE_SIZE/3)
                        resources.spawn(
                            x * settings.TILE_SIZE + offsetX, 
                            y * settings.TILE_SIZE + offsetY, 
                            resourceType
                        )
                    end
                end
            end
        end
    end
    
    print("Generated " .. #resources.items .. " resources in " .. biome .. " biome")
end

function resources.update(dt)
    -- Пока что простая логика - можно добавить респавн ресурсов
    for i = #resources.items, 1, -1 do
        local resource = resources.items[i]
        if resource.collected then
            table.remove(resources.items, i)
        end
    end
end

function resources.checkCollection(playerX, playerY, playerSize)
    local collectedResources = {}
    
    for _, resource in ipairs(resources.items) do
        if not resource.collected then
            local distance = math.sqrt((playerX - resource.x)^2 + (playerY - resource.y)^2)
            if distance < playerSize then
                resource.collected = true
                table.insert(collectedResources, resource)
            end
        end
    end
    
    return collectedResources
end

function resources.draw()
    for _, resource in ipairs(resources.items) do
        if not resource.collected then
            local data = resources.types[resource.type]
            if data then
                love.graphics.setColor(data.color[1], data.color[2], data.color[3], 1)
                love.graphics.circle("fill", resource.x, resource.y, data.size)
                
                -- Контур для лучшей видимости
                love.graphics.setColor(0, 0, 0, 0.8)
                love.graphics.circle("line", resource.x, resource.y, data.size)
            end
        end
    end
    love.graphics.setColor(1, 1, 1, 1)  -- сброс цвета
end

function resources.clear()
    resources.items = {}
end

return resources