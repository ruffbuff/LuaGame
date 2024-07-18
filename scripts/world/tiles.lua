-- scripts/world/tiles.lua

local settings = require("scripts.main.settings")
local debug = require("scripts.main.debug")

local tiles = {}

local floorTile = {
    color = {0.9, 0.7, 0.3},
    debugColor = {1, 0, 0}
}

local buildingTile = {
    color = {0.6, 0.6, 0.6},
    debugColor = {1, 0, 0}
}

local entranceTile = {
    color = {0.9, 0.7, 0.3},
    debugColor = {0, 1, 0},
    isEntrance = true
}

function tiles.generateMap()
    local map = {}
    for y = 1, settings.WORLD_HEIGHT do
        map[y] = {}
        for x = 1, settings.WORLD_WIDTH do
            map[y][x] = nil
        end
    end

    local pathStartX1 = 25
    local pathStartY1 = 25
    for x = pathStartX1, pathStartX1 + 15 do
        map[pathStartY1][x] = floorTile
    end

    local pathStartX2 = 25
    local pathStartY2 = 26
    for x = pathStartX2, pathStartX2 + 14 do
        map[pathStartY2][x] = floorTile
    end

    local buildingStartX = pathStartX1 + 15
    local buildingStartY = pathStartY1 - 3
    for y = buildingStartY, buildingStartY + 7 do
        for x = buildingStartX, buildingStartX + 7 do
            if (x == buildingStartX + 0 and y == buildingStartY + 3) or
               (x == buildingStartX + 0 and y == buildingStartY + 4) then
                map[y][x] = entranceTile
            else
                map[y][x] = buildingTile
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
               checkY >= 1 and checkY <= settings.WORLD_HEIGHT then
                local tile = tiles.map[checkY][checkX]
                if tile and tile ~= floorTile and tile ~= entranceTile then
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
    end
    return false
end

function tiles.isOnEntrance(x, y, size)
    local tileX = math.floor(x / settings.TILE_SIZE) + 1
    local tileY = math.floor(y / settings.TILE_SIZE) + 1
    local tile = tiles.map[tileY] and tiles.map[tileY][tileX]
    local isEntrance = tile and tile.isEntrance
    return isEntrance
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