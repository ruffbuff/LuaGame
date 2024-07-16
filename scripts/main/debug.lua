-- scripts/main/debug.lua

local settings = require("scripts.main.settings")

local debug = {
    active = false
}

function debug.toggle()
    debug.active = not debug.active
end

function debug.draw(player)
    if debug.active then
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(16))
        love.graphics.print("Version: " .. settings.GAME_VERSION, 10, 10)
        love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 30)
        love.graphics.print("Player X: " .. math.floor(player.x), 10, 50)
        love.graphics.print("Player Y: " .. math.floor(player.y), 10, 70)
        love.graphics.print("Speed: " .. math.floor(player.currentSpeed), 10, 90)
    end
end

return debug