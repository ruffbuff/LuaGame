-- scripts/world/world.lua

local settings = require("scripts.main.settings")
local tiles = require("scripts.world.tiles")
local player = require("scripts.player.player")
local camera = require("scripts.player.camera")
local debug = require("scripts.main.debug")
local network = require("scripts.network.network")

local world = {
    map = {}
}

function world.load()
    world.map = tiles.generateMap()
    tiles.map = world.map
    
    local spawnPoint = settings.MAP.SPAWN_POINTS[1]
    if network.id then
        spawnPoint = settings.MAP.SPAWN_POINTS[network.id] or spawnPoint
    end
    player.x = (spawnPoint.x - 1) * settings.TILE_SIZE + settings.TILE_SIZE / 2
    player.y = (spawnPoint.y - 1) * settings.TILE_SIZE + settings.TILE_SIZE / 2
end

function world.update(dt)
end

function world.draw()
    love.graphics.setColor(1, 1, 1, 1)
    tiles.draw(world.map)
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