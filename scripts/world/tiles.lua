-- scripts/world/tiles.lua

local settings = require("scripts.main.settings")

local tiles = {}
tiles.images = {}
tiles.gardenBedImage = nil
tiles.waterDropImage = nil

function tiles.load()
    tiles.images[1] = love.graphics.newImage("assets/tiles/1.png")
    tiles.images[1]:setFilter("nearest", "nearest")
    
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
    for y = 1, settings.WORLD_HEIGHT do
        map[y] = {}
        for x = 1, settings.WORLD_WIDTH do
            map[y][x] = {
                type = 1,
                isGardenBed = false,
                isWatered = false
            }
        end
    end
    
    -- Создание нескольких грядок рядом со спавном игрока
    local centerX = math.floor(settings.WORLD_WIDTH / 2)
    local centerY = math.floor(settings.WORLD_HEIGHT / 2)
    local gardenBedPositions = {
        {x = centerX - 3, y = centerY - 3},
        {x = centerX + 3, y = centerY - 3},
        {x = centerX - 3, y = centerY + 3},
        {x = centerX + 3, y = centerY + 3}
    }
    
    for _, pos in ipairs(gardenBedPositions) do
        if map[pos.y] and map[pos.y][pos.x] then
            map[pos.y][pos.x].isGardenBed = true
            print("Грядка создана на позиции: ", pos.x, pos.y)
        end
    end
    
    return map
end

function tiles.checkCollision(x, y)
    local tileX = math.floor(x / settings.TILE_SIZE) + 1
    local tileY = math.floor(y / settings.TILE_SIZE) + 1

    return tileX < 1 or tileX > settings.WORLD_WIDTH or tileY < 1 or tileY > settings.WORLD_HEIGHT
end

function tiles.draw(map)
    for y = 1, settings.WORLD_HEIGHT do
        for x = 1, settings.WORLD_WIDTH do
            love.graphics.draw(
                tiles.images[1],
                (x-1) * settings.TILE_SIZE,
                (y-1) * settings.TILE_SIZE,
                0,
                settings.TILE_SIZE / tiles.images[1]:getWidth(),
                settings.TILE_SIZE / tiles.images[1]:getHeight()
            )
            
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
                print("Отрисовка грядки на позиции: ", x, y)
                
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
                    print("Отрисовка капли на позиции: ", x, y)
                end
            end
        end
    end
end

return tiles