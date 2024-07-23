-- scripts/world/tiles.lua
local settings = require("scripts.main.settings")

local tiles = {}

function tiles.load()
end

function tiles.generateMap()
    local map = {}
    for y = 1, settings.WORLD_HEIGHT do
        map[y] = {}
        for x = 1, settings.WORLD_WIDTH do
            map[y][x] = {
                type = "empty"
            }
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
end

return tiles