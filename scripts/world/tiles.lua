-- scripts/world/tiles.lua

local settings = require("scripts.main.settings")

local tiles = {}
tiles.images = {}
tiles.gardenBedImage = nil
tiles.waterDropImage = nil

function tiles.load()
    -- Загружаем разные тайлы для создания интересной карты
    local tileTypes = {1, 2, 3, 4, 5, 10, 15, 20, 25, 30}  -- Основные тайлы
    
    for _, tileId in ipairs(tileTypes) do
        tiles.images[tileId] = love.graphics.newImage("assets/tiles/" .. tileId .. ".png")
        tiles.images[tileId]:setFilter("nearest", "nearest")
    end
    
    -- Загрузка изображения грядки
    tiles.gardenBedImage = love.graphics.newImage("assets/items/weed/0.png")
    tiles.gardenBedImage:setFilter("nearest", "nearest")
    
    -- Загрузка изображения капли воды
    tiles.waterDropImage = love.graphics.newImage("assets/items/32x32/waterDropIcon.png")
    tiles.waterDropImage:setFilter("nearest", "nearest")

    print("Изображения загружены успешно")
end

function tiles.generateMap()
    local map = {}
    local centerX = math.floor(settings.WORLD_WIDTH / 2)
    local centerY = math.floor(settings.WORLD_HEIGHT / 2)
    
    -- Создаём базовую карту с травой (тип 1)
    for y = 1, settings.WORLD_HEIGHT do
        map[y] = {}
        for x = 1, settings.WORLD_WIDTH do
            local distanceFromCenter = math.sqrt((x - centerX)^2 + (y - centerY)^2)
            local tileType = 1  -- По умолчанию трава
            
            -- Создаём зоны с разными тайлами
            if distanceFromCenter < 3 then
                tileType = 3  -- Центральная зона
            elseif distanceFromCenter < 8 then
                -- Случайный выбор между несколькими типами
                local rand = love.math.random()
                if rand < 0.3 then
                    tileType = 2
                elseif rand < 0.6 then
                    tileType = 4
                else
                    tileType = 1
                end
            elseif distanceFromCenter < 12 then
                tileType = love.math.random() < 0.5 and 5 or 1
            else
                -- Внешние области - более "дикие" тайлы
                local rand = love.math.random()
                if rand < 0.2 then
                    tileType = 10
                elseif rand < 0.4 then
                    tileType = 15
                elseif rand < 0.6 then
                    tileType = 20
                else
                    tileType = 1
                end
            end
            
            map[y][x] = {
                type = tileType,
                isGardenBed = false,
                isWatered = false
            }
        end
    end
    
    -- Создание нескольких грядок рядом со спавном игрока  
    local gardenBedPositions = {
        {x = centerX - 3, y = centerY - 3},
        {x = centerX + 3, y = centerY - 3},
        {x = centerX - 3, y = centerY + 3},
        {x = centerX + 3, y = centerY + 3}
    }
    
    for _, pos in ipairs(gardenBedPositions) do
        if map[pos.y] and map[pos.y][pos.x] then
            map[pos.y][pos.x].isGardenBed = true
        end
    end
    
    return map
end

function tiles.checkCollision(x, y, size)
    local tileX = math.floor(x / settings.TILE_SIZE) + 1
    local tileY = math.floor(y / settings.TILE_SIZE) + 1

    -- Проверяем границы мира
    if tileX < 1 or tileX > settings.WORLD_WIDTH or tileY < 1 or tileY > settings.WORLD_HEIGHT then
        return true
    end
    
    -- Проверяем коллизию с постройками (только если передан размер)
    if size then
        local buildings = require("scripts.world.buildings")
        if buildings.checkCollision(x + size/2, y + size/2, size) then
            return true
        end
    end

    return false
end

function tiles.draw(map)
    for y = 1, settings.WORLD_HEIGHT do
        for x = 1, settings.WORLD_WIDTH do
            local tileType = map[y][x].type
            local tileImage = tiles.images[tileType]
            
            if tileImage then
                love.graphics.draw(
                    tileImage,
                    (x-1) * settings.TILE_SIZE,
                    (y-1) * settings.TILE_SIZE,
                    0,
                    settings.TILE_SIZE / tileImage:getWidth(),
                    settings.TILE_SIZE / tileImage:getHeight()
                )
            end
            
            -- Отрисовка грядки
            if map[y][x].isGardenBed then
                love.graphics.draw(
                    tiles.gardenBedImage,
                    (x-1) * settings.TILE_SIZE,
                    (y-1) * settings.TILE_SIZE,
                    0,
                    2,  -- Увеличиваем размер в 2 раза по ширине
                    2   -- Увеличиваем размер в 2 раза по высоте
                )
                
                -- Отрисовка капли воды, если грядка полита
                if map[y][x].isWatered then
                    love.graphics.draw(
                        tiles.waterDropImage,
                        (x-1) * settings.TILE_SIZE + settings.TILE_SIZE / 2,  -- Смещаем каплю вправо
                        (y-1) * settings.TILE_SIZE,
                        0,
                        1,  -- Оставляем оригинальный размер
                        1
                    )
                end
            end
        end
    end
end

return tiles