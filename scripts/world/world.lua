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
end

function world.update(dt)
end

function world.draw()
    tiles.draw(world.map)
    player.draw(camera)
end

return world