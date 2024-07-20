-- scripts/player/minimap.lua

local settings = require("scripts.main.settings")
local player = require("scripts.player.player")
local network = require("scripts.network.network")
local world = require("scripts.world.world")

local minimap = {}

function minimap.draw()
    local mapWidth = 200
    local mapHeight = 200
    local mapX = 10
    local mapY = 10

    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.rectangle("fill", mapX, mapY, mapWidth, mapHeight)

    local mapScale = mapWidth / (settings.world.width * settings.world.tileSize)
    local viewportWidth = love.graphics.getWidth() * mapScale
    local viewportHeight = love.graphics.getHeight() * mapScale
    local playerX = player.x * mapScale
    local playerY = player.y * mapScale

    local viewportX = math.max(mapX, math.min(mapX + mapWidth - viewportWidth, mapX + playerX - viewportWidth / 2))
    local viewportY = math.max(mapY, math.min(mapY + mapHeight - viewportHeight, mapY + playerY - viewportHeight / 2))

    love.graphics.setColor(1, 0, 0, 0.1)
    love.graphics.rectangle("fill", viewportX, viewportY, viewportWidth, viewportHeight)

    for y = 1, settings.WORLD_HEIGHT do
        for x = 1, settings.WORLD_WIDTH do
            local tileType = world.map[y][x]
            if tileType and tileType > 0 then
                love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
                love.graphics.rectangle("fill", 
                    mapX + (x-1) * mapScale * settings.TILE_SIZE, 
                    mapY + (y-1) * mapScale * settings.TILE_SIZE, 
                    mapScale * settings.TILE_SIZE, 
                    mapScale * settings.TILE_SIZE)
            end
        end
    end

    local playerColor = {1, 0, 0}
    if settings.playerColor == "blue" then
        playerColor = {0, 0, 1}
    elseif settings.playerColor == "green" then
        playerColor = {0, 1, 0}
    elseif settings.playerColor == "yellow" then
        playerColor = {1, 1, 0}
    elseif settings.playerColor == "purple" then
        playerColor = {1, 0, 1}
    end

    love.graphics.setColor(playerColor[1], playerColor[2], playerColor[3])
    love.graphics.circle("fill", mapX + playerX, mapY + playerY, 4)

    for id, otherPlayer in pairs(player.otherPlayers) do
        local otherPlayerColor = {1, 0, 0}
        if otherPlayer.color == "blue" then
            otherPlayerColor = {0, 0, 1}
        elseif otherPlayer.color == "green" then
            otherPlayerColor = {0, 1, 0}
        elseif otherPlayer.color == "yellow" then
            otherPlayerColor = {1, 1, 0}
        elseif otherPlayer.color == "purple" then
            otherPlayerColor = {1, 0, 1}
        end
        love.graphics.setColor(otherPlayerColor[1], otherPlayerColor[2], otherPlayerColor[3])
        love.graphics.circle("fill", mapX + (otherPlayer.x * mapScale), mapY + (otherPlayer.y * mapScale), 3)
    end
end

return minimap