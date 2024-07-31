-- scripts/world/tiles.lua

local settings = require("scripts.main.settings")
local debug = require("scripts.main.debug")

local tiles = {}

local TILE_TYPES = {
    EMPTY = 0,
    WALL = 1,
    SPAWN = 2,
    MAIN_BUILDING = 3,
    TOWER = 4
}

function tiles.load()
end

function tiles.generateMap()
    local map = {}

    for y = 1, settings.WORLD_HEIGHT do
        map[y] = {}
        for x = 1, settings.WORLD_WIDTH do
            map[y][x] = TILE_TYPES.EMPTY
        end
    end

    for x = 1, settings.WORLD_WIDTH do
        map[1][x] = TILE_TYPES.WALL
        map[settings.WORLD_HEIGHT][x] = TILE_TYPES.WALL
    end

    for y = 1, settings.WORLD_HEIGHT do
        map[y][1] = TILE_TYPES.WALL
        map[y][settings.WORLD_WIDTH] = TILE_TYPES.WALL
    end

    for _, wall in ipairs(settings.MAP.WALLS) do
        for y = wall.y, wall.y + wall.height - 1 do
            for x = wall.x, wall.x + wall.width - 1 do
                map[y][x] = TILE_TYPES.WALL
            end
        end
    end

    for _, point in ipairs(settings.MAP.SPAWN_POINTS) do
        map[point.y][point.x] = TILE_TYPES.SPAWN
    end

    for _, building in ipairs(settings.MAP.MAIN_BUILDINGS) do
        map[building.y][building.x] = TILE_TYPES.MAIN_BUILDING
    end

    for _, tower in ipairs(settings.MAP.TOWER_POINTS) do
        map[tower.y][tower.x] = TILE_TYPES.TOWER
    end

    return map
end

function tiles.checkCollision(x, y, size)
    local left = math.floor(x / settings.TILE_SIZE) + 1
    local right = math.floor((x + size - 1) / settings.TILE_SIZE) + 1
    local top = math.floor(y / settings.TILE_SIZE) + 1
    local bottom = math.floor((y + size - 1) / settings.TILE_SIZE) + 1

    for tileY = top, bottom do
        for tileX = left, right do
            if tileX < 1 or tileX > settings.WORLD_WIDTH or tileY < 1 or tileY > settings.WORLD_HEIGHT or
               tiles.map[tileY][tileX] == TILE_TYPES.WALL or
               tiles.map[tileY][tileX] == TILE_TYPES.MAIN_BUILDING or
               tiles.map[tileY][tileX] == TILE_TYPES.TOWER then
                return true
            end
        end
    end
    return false
end

function tiles.draw(map)
    for y = 1, settings.WORLD_HEIGHT do
        for x = 1, settings.WORLD_WIDTH do
            local tile = map[y][x]
            if tile == TILE_TYPES.WALL then
                love.graphics.setColor(0.5, 0.5, 0.5)
            elseif tile == TILE_TYPES.SPAWN then
                love.graphics.setColor(0, 1, 0)
            elseif tile == TILE_TYPES.MAIN_BUILDING then
                love.graphics.setColor(1, 0, 0)
            elseif tile == TILE_TYPES.TOWER then
                love.graphics.setColor(0, 0, 1)
            else
                love.graphics.setColor(0.8, 0.8, 0.8)
            end
            love.graphics.rectangle("fill", (x-1) * settings.TILE_SIZE, (y-1) * settings.TILE_SIZE, settings.TILE_SIZE, settings.TILE_SIZE)

            if debug.isEnabled() and (tile == TILE_TYPES.WALL or tile == TILE_TYPES.MAIN_BUILDING or tile == TILE_TYPES.TOWER) then
                love.graphics.setColor(1, 0, 0, 0.5)
                love.graphics.rectangle("line", (x-1) * settings.TILE_SIZE, (y-1) * settings.TILE_SIZE, settings.TILE_SIZE, settings.TILE_SIZE)
            end
        end
    end
end

return tiles