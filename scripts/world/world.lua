-- scripts/world/world.lua

local settings = require("scripts.main.settings")
local tiles = require("scripts.world.tiles")
local player = require("scripts.player.player")
local camera = require("scripts.player.camera")

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

    print("Мир загружен. Размер карты: ", #world.map, #world.map[1])
end

function world.update(dt)
    -- Здесь можно добавить логику обновления мира, если необходимо
end

function world.draw()
    tiles.draw(world.map)
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

return world