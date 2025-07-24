-- scripts/world/world.lua

local settings = require("scripts.main.settings")
local tiles = require("scripts.world.tiles")
local player = require("scripts.player.player")
local camera = require("scripts.player.camera")
local resources = require("scripts.world.resources")
local buildings = require("scripts.world.buildings")

local world = {
    map = {}
}

function world.load()
    world.map = tiles.generateMap()
    tiles.map = world.map

    local centerX = math.floor(settings.WORLD_WIDTH / 2) * settings.TILE_SIZE
    local centerY = math.floor(settings.WORLD_HEIGHT / 2) * settings.TILE_SIZE
    player.x = centerX
    player.y = centerY

    -- Генерируем ресурсы по всей карте
    resources.clear()  -- очищаем старые ресурсы
    resources.generateInArea(1, 1, settings.WORLD_WIDTH-1, settings.WORLD_HEIGHT-1, "plains")
    
    print("Мир загружен. Размер карты: ", #world.map, #world.map[1])
end

function world.update(dt)
    resources.update(dt)
    buildings.update(dt)
end

function world.draw()
    -- Рисуем фон за границами карты
    local settings = require("scripts.main.settings")
    love.graphics.setColor(0.1, 0.3, 0.1, 1)  -- Тёмно-зелёный фон
    love.graphics.rectangle("fill", -1000, -1000, 
                           settings.WORLD_WIDTH * settings.TILE_SIZE + 2000, 
                           settings.WORLD_HEIGHT * settings.TILE_SIZE + 2000)
    
    -- Рисуем карту
    love.graphics.setColor(1, 1, 1, 1)  -- Сбрасываем цвет
    tiles.draw(world.map)
    
    -- Рисуем ресурсы
    resources.draw()
    
    -- Рисуем постройки
    buildings.draw()
    
    player.draw(camera)
end

-- Функция для полива грядки
function world.waterGardenBed(x, y)
    local tileX = math.floor(x / settings.TILE_SIZE) + 1
    local tileY = math.floor(y / settings.TILE_SIZE) + 1
    
    if world.map[tileY] and world.map[tileY][tileX] and world.map[tileY][tileX].isGardenBed then
        world.map[tileY][tileX].isWatered = true
        print("Грядка полита на позиции: ", tileX, tileY)
    end
end

-- Экспортируем функции зданий для внешнего использования
world.buildStructure = buildings.build
world.canBuild = buildings.canBuild
world.checkWarmth = buildings.checkWarmth

return world