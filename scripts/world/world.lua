-- scripts/world/world.lua

local settings = require("scripts.main.settings")
local tiles = require("scripts.world.tiles")
local debug = require("scripts.main.debug")

local world = {
    map = {}
}

function world.load()
    world.map = tiles.generateMap()
    tiles.map = world.map
end

function world.update(dt)
end

function world.draw()
    tiles.draw(world.map, debug.isEnabled())
end

return world