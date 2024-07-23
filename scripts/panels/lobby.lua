-- scripts/panels/lobby.lua

local network = require("scripts.network.network")
local settings = require("scripts.main.settings")

local lobby = {
    players = {},
    playerCount = 0
}

function lobby.load()
end

function lobby.update(dt)
end

function lobby.draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(32))
    love.graphics.printf("Lobby", 0, 50, love.graphics.getWidth(), "center")
    
    love.graphics.setFont(love.graphics.newFont(24))
    if network.lobbyTimer then
        love.graphics.printf("Time left: " .. math.ceil(network.lobbyTimer), 0, 100, love.graphics.getWidth(), "center")
    end
    love.graphics.printf("Players: " .. lobby.playerCount .. "/2", 0, 130, love.graphics.getWidth(), "center")

    love.graphics.setFont(love.graphics.newFont(20))
    for id, player in pairs(lobby.players) do
        local colorName = player.colorName or "unknown"
        local color = settings.playerColors[colorName] or {1, 1, 1}
        love.graphics.setColor(color[1], color[2], color[3])
        love.graphics.printf("Player " .. id .. ": " .. colorName, 100, 200 + id * 40, love.graphics.getWidth() - 200, "left")
    end
end

function lobby.updatePlayers(players)
    lobby.players = players
end

return lobby