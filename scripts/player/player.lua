-- scripts/player/player.lua

local settings = require("scripts.main.settings")
local network = require("scripts.network.network")

local player = {
    x = 1568,
    y = 1568,
    size = settings.TILE_SIZE,
    currentSpeed = 0,
    baseSpeed = settings.PLAYER_SPEED,
    fastMultiplier = 2,
    otherPlayers = {}
}

local playerColors = {
    {1, 0, 0},  -- красный
    {0, 0, 1},  -- синий
    {0, 1, 0},  -- зеленый
    {1, 1, 0},  -- желтый
    {1, 0, 1},  -- пурпурный
}

function player.load()
    -- Начальная позиция уже установлена в x и y
end

function player.update(dt)
    local dx, dy = 0, 0

    if love.keyboard.isDown(unpack(settings.MOVE_LEFT_KEY)) then dx = dx - 1 end
    if love.keyboard.isDown(unpack(settings.MOVE_RIGHT_KEY)) then dx = dx + 1 end
    if love.keyboard.isDown(unpack(settings.MOVE_UP_KEY)) then dy = dy - 1 end
    if love.keyboard.isDown(unpack(settings.MOVE_DOWN_KEY)) then dy = dy + 1 end

    if dx ~= 0 and dy ~= 0 then
        dx = dx / math.sqrt(2)
        dy = dy / math.sqrt(2)
    end

    local speedMultiplier = love.keyboard.isDown(settings.MOVE_FAST_KEY) and player.fastMultiplier or 1
    local currentSpeed = player.baseSpeed * speedMultiplier

    local newX = player.x + dx * currentSpeed * dt
    local newY = player.y + dy * currentSpeed * dt

    player.currentSpeed = math.sqrt((newX - player.x)^2 + (newY - player.y)^2) / dt

    player.x = newX
    player.y = newY

    player.x = math.max(0, math.min(player.x, settings.WORLD_WIDTH * settings.TILE_SIZE - player.size))
    player.y = math.max(0, math.min(player.y, settings.WORLD_HEIGHT * settings.TILE_SIZE - player.size))

    if network.id and network.players[network.id] then
        network.players[network.id].x = player.x
        network.players[network.id].y = player.y
    end

    -- Обновляем позиции других игроков
    player.otherPlayers = {}
    for id, p in pairs(network.players) do
        if id ~= network.id then
            player.otherPlayers[id] = p
        end
    end
end

function player.draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Player ID: " .. tostring(network.id), 10, 10)
    love.graphics.print("Number of other players: " .. tostring(#player.otherPlayers), 10, 30)
    love.graphics.print("Player position: " .. math.floor(player.x) .. ", " .. math.floor(player.y), 10, 50)
    
    local i = 1
    for id, otherPlayer in pairs(player.otherPlayers) do
        love.graphics.print("Player " .. id .. ": " .. math.floor(otherPlayer.x) .. ", " .. math.floor(otherPlayer.y), 10, 70 + 20 * i)
        i = i + 1
    end

    -- Рисуем сетку мира
    love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
    for x = 0, settings.WORLD_WIDTH do
        love.graphics.line(x * settings.TILE_SIZE, 0, x * settings.TILE_SIZE, settings.WORLD_HEIGHT * settings.TILE_SIZE)
    end
    for y = 0, settings.WORLD_HEIGHT do
        love.graphics.line(0, y * settings.TILE_SIZE, settings.WORLD_WIDTH * settings.TILE_SIZE, y * settings.TILE_SIZE)
    end

    -- Рисуем всех игроков
    for id, p in pairs(network.players) do
        local colorIndex = (id - 1) % #playerColors + 1
        love.graphics.setColor(playerColors[colorIndex])
        love.graphics.rectangle('fill', p.x, p.y, player.size, player.size)
    end
end

return player