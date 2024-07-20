-- scripts/world/world.lua

local settings = require("scripts.main.settings")
local tiles = require("scripts.world.tiles")
local debug = require("scripts.main.debug")
local player = require("scripts.player.player")
local camera = require("scripts.player.camera")

local world = {
    map = {},
    showEntranceModal = false
}

function world.load()
    world.map = tiles.generateMap()
    tiles.map = world.map
end

function world.update()
end

function world.draw()
    tiles.draw(world.map)
    player.draw(camera)
end

return world