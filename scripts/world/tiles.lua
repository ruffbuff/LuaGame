-- scripts/world/tiles.lua

local settings = require("scripts.main.settings")

local tiles = {}
tiles.images = {}

function tiles.load()
    tiles.images[1] = love.graphics.newImage("assets/tiles/1.png")
    tiles.images[1]:setFilter("nearest", "nearest")
end

function tiles.generateMap()
    local map = {}
    for y = 1, settings.WORLD_HEIGHT do
        map[y] = {}
        for x = 1, settings.WORLD_WIDTH do
            map[y][x] = 1
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
        end
    end
end

return tiles