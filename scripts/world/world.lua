-- scripts/world/world.lua

local settings = require("scripts.main.settings")

local world = {
    tiles = {}
}

function world.load()
    for y = 1, settings.WORLD_HEIGHT do
        world.tiles[y] = {}
        for x = 1, settings.WORLD_WIDTH do
            world.tiles[y][x] = 1
        end
    end
end

function world.update(dt)
end

function world.draw()
    for y = 1, settings.WORLD_HEIGHT do
        for x = 1, settings.WORLD_WIDTH do
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.rectangle('line', 
                (x-1) * settings.TILE_SIZE, 
                (y-1) * settings.TILE_SIZE, 
                settings.TILE_SIZE, 
                settings.TILE_SIZE)
        end
    end
end

return world