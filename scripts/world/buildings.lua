-- scripts/world/buildings.lua

local settings = require("scripts.main.settings")

local buildings = {
    structures = {},  -- все построенные объекты
    
    -- Типы построек с рецептами
    types = {
        campfire = {
            name = "Костёр",
            color = {1, 0.5, 0},  -- оранжевый
            size = 16,
            recipe = {wood = 3},
            lightRadius = 4 * settings.TILE_SIZE,
            warmth = true
        },
        wall = {
            name = "Стена",
            color = {0.6, 0.6, 0.6},  -- серый
            size = 20,
            recipe = {stone = 2},
            solid = true  -- блокирует движение
        },
        garden_bed = {
            name = "Грядка",
            color = {0.4, 0.8, 0.3},  -- зелёный
            size = 18,
            recipe = {wood = 1, stone = 1},
            farmable = true
        }
    }
}

function buildings.canBuild(buildingType, inventory)
    local buildingData = buildings.types[buildingType]
    if not buildingData then return false end
    
    -- Проверяем наличие ресурсов
    for resource, needed in pairs(buildingData.recipe) do
        if not inventory.has(resource, needed) then
            return false
        end
    end
    
    return true
end

function buildings.build(buildingType, x, y, inventory)
    if not buildings.canBuild(buildingType, inventory) then
        print("Недостаточно ресурсов для " .. buildings.types[buildingType].name)
        return false
    end
    
    -- Проверяем, не занято ли место
    local tileX = math.floor(x / settings.TILE_SIZE)
    local tileY = math.floor(y / settings.TILE_SIZE)
    
    for _, structure in ipairs(buildings.structures) do
        local structTileX = math.floor(structure.x / settings.TILE_SIZE)
        local structTileY = math.floor(structure.y / settings.TILE_SIZE)
        if structTileX == tileX and structTileY == tileY then
            print("Здесь уже что-то построено!")
            return false
        end
    end
    
    -- Тратим ресурсы
    local buildingData = buildings.types[buildingType]
    for resource, needed in pairs(buildingData.recipe) do
        inventory.remove(resource, needed)
    end
    
    -- Создаём постройку
    local structure = {
        type = buildingType,
        x = tileX * settings.TILE_SIZE + settings.TILE_SIZE/2,
        y = tileY * settings.TILE_SIZE + settings.TILE_SIZE/2,
        buildTime = love.timer.getTime(),
        active = true
    }
    
    table.insert(buildings.structures, structure)
    print("Построен " .. buildingData.name .. "!")
    
    return true
end

function buildings.update(dt)
    -- Обновляем активные постройки
    for _, structure in ipairs(buildings.structures) do
        if structure.active then
            local buildingData = buildings.types[structure.type]
            
            -- Логика для костра
            if structure.type == "campfire" then
                -- Костёр может потухнуть через время без топлива
                -- TODO: добавить систему топлива
            end
        end
    end
end

function buildings.checkWarmth(playerX, playerY)
    -- Проверяем, находится ли игрок рядом с источником тепла
    for _, structure in ipairs(buildings.structures) do
        if structure.active and buildings.types[structure.type].warmth then
            local distance = math.sqrt((playerX - structure.x)^2 + (playerY - structure.y)^2)
            if distance < buildings.types[structure.type].lightRadius then
                return true
            end
        end
    end
    return false
end

function buildings.checkCollision(x, y, size)
    -- Проверяем коллизию с твёрдыми постройками
    for _, structure in ipairs(buildings.structures) do
        local buildingData = buildings.types[structure.type]
        if buildingData.solid then
            local distance = math.sqrt((x - structure.x)^2 + (y - structure.y)^2)
            if distance < buildingData.size + size/2 then
                return true
            end
        end
    end
    return false
end

function buildings.draw()
    for _, structure in ipairs(buildings.structures) do
        local buildingData = buildings.types[structure.type]
        
        -- Рисуем постройку
        love.graphics.setColor(buildingData.color[1], buildingData.color[2], buildingData.color[3], 1)
        love.graphics.circle("fill", structure.x, structure.y, buildingData.size)
        
        -- Контур
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.circle("line", structure.x, structure.y, buildingData.size)
        
        -- Эффекты
        if structure.type == "campfire" and structure.active then
            -- Свечение костра
            love.graphics.setColor(1, 0.8, 0.2, 0.3)
            love.graphics.circle("fill", structure.x, structure.y, buildingData.lightRadius)
        end
    end
    
    love.graphics.setColor(1, 1, 1, 1)  -- сброс цвета
end

function buildings.getBuildingAt(x, y)
    local tileX = math.floor(x / settings.TILE_SIZE)
    local tileY = math.floor(y / settings.TILE_SIZE)
    
    for _, structure in ipairs(buildings.structures) do
        local structTileX = math.floor(structure.x / settings.TILE_SIZE)
        local structTileY = math.floor(structure.y / settings.TILE_SIZE)
        if structTileX == tileX and structTileY == tileY then
            return structure
        end
    end
    
    return nil
end

return buildings