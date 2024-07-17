-- scripts/world/world.lua

local settings = require("scripts.main.settings")
local tiles = require("scripts.world.tiles")
local debug = require("scripts.main.debug")

local world = {
    map = {},
    showEntranceModal = false
}

function world.load()
    world.map = tiles.generateMap()
    tiles.map = world.map
end

function world.update(dt, player)
    world.showEntranceModal = player.isOnEntrance
end

function world.draw()
    tiles.draw(world.map, debug.isEnabled())

    if world.showEntranceModal then
        love.graphics.push()
        love.graphics.origin()

        love.graphics.setColor(0, 0, 0, 0.7)
        local modalWidth = 300
        local modalHeight = 150
        local modalX = (love.graphics.getWidth() - modalWidth) / 2
        local modalY = (love.graphics.getHeight() - modalHeight) / 2
        love.graphics.rectangle('fill', modalX, modalY, modalWidth, modalHeight)

        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Entrance is closed! Please come back later...", modalX, modalY + modalHeight/2 - 10, modalWidth, "center")

        love.graphics.pop()
    end
end

return world