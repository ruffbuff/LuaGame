-- scripts/player/player.lua

local settings = require("scripts.main.settings")
local network = require("scripts.network.network")
local tiles = require("scripts.world.tiles")
local debug = require("scripts.main.debug")
local items = require("scripts.items.items")

local player = {
    x = 1568,
    y = 1568,
    velocityX = 0,
    velocityY = 0,
    size = settings.TILE_SIZE,
    colliderSize = settings.TILE_SIZE * 0.8,
    colliderOffset = settings.TILE_SIZE * 0.1,
    currentSpeed = 0,
    dashCooldown = 0,
    dashCooldownDuration = 1,
    baseSpeed = settings.PLAYER_SPEED,
    fastMultiplier = 2,
    otherPlayers = {},
    currentItem = items.grapplingHook
}

function player.load()
end

local function resolveCollision(newX, newY)
    if not tiles.checkCollision(newX + player.colliderOffset, newY + player.colliderOffset, player.colliderSize) then
        return newX, newY
    else
        if not tiles.checkCollision(player.x + player.colliderOffset, newY + player.colliderOffset, player.colliderSize) then
            return player.x, newY
        elseif not tiles.checkCollision(newX + player.colliderOffset, player.y + player.colliderOffset, player.colliderSize) then
            return newX, player.y
        else
            return player.x, player.y
        end
    end
end

function player.dash(dx, dy)
    if player.dashCooldown <= 0 then
        local dashDistance = 3 * settings.TILE_SIZE
        local newX, newY = player.x, player.y
        
        if dx ~= 0 then
            newX = player.x + dx * dashDistance
        end
        if dy ~= 0 then
            newY = player.y + dy * dashDistance
        end

        newX, newY = resolveCollision(newX, newY)
        newX = math.max(0, math.min(newX, settings.WORLD_WIDTH * settings.TILE_SIZE - player.size))
        newY = math.max(0, math.min(newY, settings.WORLD_HEIGHT * settings.TILE_SIZE - player.size))

        local actualDashX = newX - player.x
        local actualDashY = newY - player.y

        if math.abs(actualDashX) > dashDistance then
            newX = player.x + (actualDashX / math.abs(actualDashX)) * dashDistance
        end
        if math.abs(actualDashY) > dashDistance then
            newY = player.y + (actualDashY / math.abs(actualDashY)) * dashDistance
        end

        player.x, player.y = newX, newY

        if network.id and network.players[network.id] then
            network.players[network.id].x = player.x
            network.players[network.id].y = player.y
        end

        player.dashCooldown = player.dashCooldownDuration
    end
end

function player.update(dt, chat)
    if not chat.isActive then
        local dx, dy = 0, 0

        if love.keyboard.isDown(settings.MOVE_LEFT_KEY) then dx = dx - 1 end
        if love.keyboard.isDown(settings.MOVE_RIGHT_KEY) then dx = dx + 1 end
        if love.keyboard.isDown(settings.MOVE_UP_KEY) then dy = dy - 1 end
        if love.keyboard.isDown(settings.MOVE_DOWN_KEY) then dy = dy + 1 end

        if dx ~= 0 and dy ~= 0 then
            dx = dx / math.sqrt(2)
            dy = dy / math.sqrt(2)
        end

        player.dashCooldown = math.max(0, player.dashCooldown - dt)

        if love.keyboard.isDown(settings.DASH_KEY) then
            if dx ~= 0 or dy ~= 0 then
                player.dash(dx, dy)
            end
        end

        local speedMultiplier = love.keyboard.isDown(settings.MOVE_FAST_KEY) and player.fastMultiplier or 1
        local currentSpeed = player.baseSpeed * speedMultiplier

        local oldX, oldY = player.x, player.y
        local newX = player.x + dx * currentSpeed * dt
        local newY = player.y + dy * currentSpeed * dt

        player.x, player.y = resolveCollision(newX, newY)

        player.currentSpeed = math.sqrt((player.x - oldX)^2 + (player.y - oldY)^2) / dt

        player.x = math.max(0, math.min(player.x, settings.WORLD_WIDTH * settings.TILE_SIZE - player.size))
        player.y = math.max(0, math.min(player.y, settings.WORLD_HEIGHT * settings.TILE_SIZE - player.size))

        if network.id and network.players[network.id] then
            network.players[network.id].x = player.x
            network.players[network.id].y = player.y
        end

        if player.currentItem then
            player.currentItem:update(dt, player)
        end

        if not (player.currentItem and player.currentItem.state == "attached") then
            player.velocityX = 0
            player.velocityY = 0
        end

        player.otherPlayers = {}
        for id, p in pairs(network.players) do
            if id ~= network.id then
                player.otherPlayers[id] = p
            end
        end
    end
end

function player.draw()
    love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
    for x = 0, settings.WORLD_WIDTH do
        love.graphics.line(x * settings.TILE_SIZE, 0, x * settings.TILE_SIZE, settings.WORLD_HEIGHT * settings.TILE_SIZE)
    end
    for y = 0, settings.WORLD_HEIGHT do
        love.graphics.line(0, y * settings.TILE_SIZE, settings.WORLD_WIDTH * settings.TILE_SIZE, y * settings.TILE_SIZE)
    end

    for id, p in pairs(network.players) do
        if id == network.id then
            love.graphics.setColor(settings.playerColor[1], settings.playerColor[2], settings.playerColor[3])
        elseif p.color then
            love.graphics.setColor(p.color[1], p.color[2], p.color[3])
        else
            local colorIndex = (id - 1) % #settings.playerColors + 1
            local color = settings.playerColors[colorIndex]
            love.graphics.setColor(color[1], color[2], color[3])
        end
        love.graphics.rectangle('fill', p.x, p.y, player.size, player.size)

        if debug.isEnabled() then
            love.graphics.setColor(1, 0, 0, 0.5)
            love.graphics.rectangle('line', p.x + player.colliderOffset, p.y + player.colliderOffset, player.colliderSize, player.colliderSize)
        end
    end

    if player.currentItem then
        player.currentItem:draw(player)  -- Передаем player в качестве аргумента
    end
end

return player