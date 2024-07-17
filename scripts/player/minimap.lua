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

    love.graphics.setColor(1, 1, 1, 0.2)
    love.graphics.rectangle("fill", viewportX, viewportY, viewportWidth, viewportHeight)

    local playerColorIndex = (network.id - 1) % #settings.playerColors + 1
    local playerColor = settings.playerColors[playerColorIndex]


    love.graphics.setColor(settings.playerColor[1], settings.playerColor[2], settings.playerColor[3])
    love.graphics.circle("fill", mapX + playerX, mapY + playerY, 4)

    for y = 1, settings.WORLD_HEIGHT do
        for x = 1, settings.WORLD_WIDTH do
            local tile = world.map[y][x]
            if tile then
                love.graphics.setColor(tile.color[1], tile.color[2], tile.color[3], 0.5)
                love.graphics.rectangle("fill", 
                    mapX + (x-1) * mapScale * settings.TILE_SIZE, 
                    mapY + (y-1) * mapScale * settings.TILE_SIZE, 
                    mapScale * settings.TILE_SIZE, 
                    mapScale * settings.TILE_SIZE)
            end
        end
    end

    for id, otherPlayer in pairs(player.otherPlayers) do
        if otherPlayer.color then
            love.graphics.setColor(otherPlayer.color[1], otherPlayer.color[2], otherPlayer.color[3])
        else
            local colorIndex = (id - 1) % #settings.playerColors + 1
            local color = settings.playerColors[colorIndex]
            love.graphics.setColor(color[1], color[2], color[3])
        end
        love.graphics.circle("fill", mapX + (otherPlayer.x * mapScale), mapY + (otherPlayer.y * mapScale), 3)
    end
end

return minimap