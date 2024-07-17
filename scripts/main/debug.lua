-- scripts/main/debug.lua

local settings = require("scripts.main.settings")

local debug = {
    active = false
}

function debug.toggle()
    debug.active = not debug.active
end

function debug.isEnabled()
    return debug.active
end

function debug.draw(player, network)
    if debug.active then
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(16))
        love.graphics.print("Version: " .. settings.GAME_VERSION, 220, 10)
        love.graphics.print("Player X: " .. math.floor(player.x), 220, 50)
        love.graphics.print("Player Y: " .. math.floor(player.y), 220, 70)
        love.graphics.print("Speed: " .. math.floor(player.currentSpeed), 220, 90)
        love.graphics.print("FPS: " .. love.timer.getFPS(), 220, 30)

        if network.ping then
            love.graphics.print("Ping: " .. math.floor(network.ping) .. " ms", 220, 110)
        end
        if network.id then
            love.graphics.print("Player ID: " .. network.id, 220, 130)
        end
        love.graphics.print("Total Players: " .. tostring(#network.players), 220, 150)
        
        local i = 1
        for id, otherPlayer in pairs(player.otherPlayers) do
            love.graphics.print("Player " .. id .. ": " .. math.floor(otherPlayer.x) .. ", " .. math.floor(otherPlayer.y), 220, 170 + 20 * i)
            i = i + 1
        end
    end
end

return debug