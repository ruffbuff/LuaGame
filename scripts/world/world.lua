-- scripts/world/world.lua
local settings = require("scripts.main.settings")
local tiles = require("scripts.world.tiles")
local player = require("scripts.player.player")
local camera = require("scripts.player.camera")
local debug = require("scripts.main.debug")

local world = {
    map = {}
}

function world.load()
    world.map = tiles.generateMap()
    local centerX = math.floor(settings.WORLD_WIDTH / 2) * settings.TILE_SIZE
    local centerY = math.floor(settings.WORLD_HEIGHT / 2) * settings.TILE_SIZE
    player.x = centerX
    player.y = centerY
end

function world.update(dt)
end

function world.draw()
    love.graphics.setColor(1, 1, 1, 1)
    player.draw(camera)
    
    if debug.isEnabled() then
        love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
        for x = 0, settings.WORLD_WIDTH do
            love.graphics.line(x * settings.TILE_SIZE, 0, x * settings.TILE_SIZE, settings.WORLD_HEIGHT * settings.TILE_SIZE)
        end
        for y = 0, settings.WORLD_HEIGHT do
            love.graphics.line(0, y * settings.TILE_SIZE, settings.WORLD_WIDTH * settings.TILE_SIZE, y * settings.TILE_SIZE)
        end
        love.graphics.setColor(1, 1, 1, 1)
    end
end

return world