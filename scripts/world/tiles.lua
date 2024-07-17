-- scripts/world/tiles.lua

local settings = require("scripts.main.settings")
local debug = require("scripts.main.debug")

local tiles = {}

local testTile = {
    color = {0, 0, 1},
    debugColor = {1, 0, 0}
}

function tiles.generateMap()
    love.math.setRandomSeed(12345)
    local map = {}
    for y = 1, settings.WORLD_HEIGHT do
        map[y] = {}
        for x = 1, settings.WORLD_WIDTH do
            if love.math.random() < 0.1 then  -- 10% chance
                map[y][x] = testTile
            else
                map[y][x] = nil
            end
        end
    end
    return map
end

function tiles.checkCollision(x, y, size)
    local tileX = math.floor(x / settings.TILE_SIZE) + 1
    local tileY = math.floor(y / settings.TILE_SIZE) + 1
    
    for dy = -1, 1 do
        for dx = -1, 1 do
            local checkX = tileX + dx
            local checkY = tileY + dy
            if checkX >= 1 and checkX <= settings.WORLD_WIDTH and
               checkY >= 1 and checkY <= settings.WORLD_HEIGHT and
               tiles.map[checkY][checkX] then
                local tileLeft = (checkX - 1) * settings.TILE_SIZE
                local tileTop = (checkY - 1) * settings.TILE_SIZE
                if x < tileLeft + settings.TILE_SIZE and
                   x + size > tileLeft and
                   y < tileTop + settings.TILE_SIZE and
                   y + size > tileTop then
                    return true
                end
            end
        end
    end
    return false
end

function tiles.draw(map)
    for y = 1, settings.WORLD_HEIGHT do
        for x = 1, settings.WORLD_WIDTH do
            local tile = map[y][x]
            if tile then
                love.graphics.setColor(tile.color)
                love.graphics.rectangle('fill', 
                    (x-1) * settings.TILE_SIZE, 
                    (y-1) * settings.TILE_SIZE, 
                    settings.TILE_SIZE, 
                    settings.TILE_SIZE)
                
                if debug.isEnabled() then
                    love.graphics.setColor(tile.debugColor)
                    love.graphics.rectangle('line', 
                        (x-1) * settings.TILE_SIZE, 
                        (y-1) * settings.TILE_SIZE, 
                        settings.TILE_SIZE, 
                        settings.TILE_SIZE)
                end
            end
        end
    end

    if debug.isEnabled() then
        love.graphics.setColor(1, 0, 0, 0.5)
        for y = 1, settings.WORLD_HEIGHT do
            for x = 1, settings.WORLD_WIDTH do
                if tiles.checkCollision((x-1) * settings.TILE_SIZE, (y-1) * settings.TILE_SIZE, 1) then
                    love.graphics.rectangle('fill', 
                        (x-1) * settings.TILE_SIZE, 
                        (y-1) * settings.TILE_SIZE, 
                        settings.TILE_SIZE, 
                        settings.TILE_SIZE)
                end
            end
        end
    end
end

return tiles