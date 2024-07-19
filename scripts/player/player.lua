-- scripts/player/player.lua

local settings = require("scripts.main.settings")
local network = require("scripts.network.network")
local tiles = require("scripts.world.tiles")
local debug = require("scripts.main.debug")
local items = require("scripts.items.items")
local spawnEffect = require("scripts.effects.spawnEffect")
local eventManager = require("scripts.utils.eventManager")
local darknessShader = require("scripts.shaders.darkness")

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
    currentItem = items.grapplingHook,
    spawnEffectPlaying = false,
    direction = "down",
    state = "idle",
    animationTimer = 0,
    currentFrame = 1,
    animations = {}
}

local function loadAnimations()
    local directions = {"down", "up", "left", "right"}
    for _, dir in ipairs(directions) do
        player.animations[dir] = {
            idle = love.graphics.newImage("assets/images/cat/" .. dir .. "/0.png"),
            walk = {},
            run = {}
        }
        for i = 0, 3 do
            local frame = love.graphics.newImage("assets/images/cat/" .. dir .. "/" .. i .. ".png")
            table.insert(player.animations[dir].walk, frame)
            table.insert(player.animations[dir].run, frame)
        end
    end
end

function player.load()
    loadAnimations()
    spawnEffect.load()
    eventManager.addListener("playerSpawned", player.playSpawnEffect)
    eventManager.addListener("otherPlayerSpawned", player.playOtherPlayerSpawnEffect)
end

function player.playSpawnEffect()
    player.spawnEffectPlaying = true
    spawnEffect.play()
end

function player.playOtherPlayerSpawnEffect(id)
    if network.players[id] then
        network.players[id].spawnEffectPlaying = true
    end
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
    if player.spawnEffectPlaying then
        spawnEffect.update(dt)
        if not spawnEffect.isPlaying then
            player.spawnEffectPlaying = false
        end
    end

    if not chat.isActive then
        local dx, dy = 0, 0
        local oldDirection = player.direction

        if love.keyboard.isDown(settings.MOVE_LEFT_KEY) then dx = dx - 1; player.direction = "left" end
        if love.keyboard.isDown(settings.MOVE_RIGHT_KEY) then dx = dx + 1; player.direction = "right" end
        if love.keyboard.isDown(settings.MOVE_UP_KEY) then dy = dy - 1; player.direction = "up" end
        if love.keyboard.isDown(settings.MOVE_DOWN_KEY) then dy = dy + 1; player.direction = "down" end

        if dx ~= 0 and dy ~= 0 then
            dx = dx / math.sqrt(2)
            dy = dy / math.sqrt(2)
        end

        if dx == 0 and dy == 0 then
            player.state = "idle"
        else
            player.state = love.keyboard.isDown(settings.MOVE_FAST_KEY) and "run" or "walk"
        end

        local animationSpeed = (player.state == "run") and 0.1 or 0.2
        player.animationTimer = player.animationTimer + dt
        if player.animationTimer >= animationSpeed then
            player.animationTimer = player.animationTimer - animationSpeed
            player.currentFrame = player.currentFrame % 4 + 1
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
            network.players[network.id].direction = player.direction
            network.players[network.id].state = player.state
            network.players[network.id].currentFrame = player.currentFrame
        end

        if player.currentItem then
            player.currentItem:update(dt, player)
        end

        if not (player.currentItem and player.currentItem.state == "attached") then
            player.velocityX = 0
            player.velocityY = 0
        end

        player.isOnEntrance = tiles.isOnEntrance(player.x + player.size / 2, player.y + player.size / 2, player.size)

        player.otherPlayers = {}
        for id, p in pairs(network.players) do
            if id ~= network.id then
                player.otherPlayers[id] = p
            end
        end
    end
end

function player.draw(camera)
    -- local screenWidth, screenHeight = love.graphics.getDimensions()
    -- local baseRadius = 5 * settings.TILE_SIZE

    -- local scaleFactor = math.min(screenWidth, screenHeight) / math.min(settings.WINDOW_WIDTH, settings.WINDOW_HEIGHT)
    -- local adjustedRadius = baseRadius * scaleFactor

    -- love.graphics.setBlendMode('add')
    -- love.graphics.setColor(0.8, 0.6, 0.2, 0.2)
    -- local glowRadius = adjustedRadius * 1.2
    -- love.graphics.circle('fill', player.x + player.size / 2, player.y + player.size / 2, glowRadius)
    -- love.graphics.setBlendMode('alpha')

    for id, p in pairs(network.players) do
        love.graphics.setColor(1, 1, 1)
        local direction = p.direction or "down"
        local state = p.state or "idle"
        local currentFrame = p.currentFrame or 1
        local animation = player.animations[direction]
        local image = (state == "idle") and animation.idle or animation[state][currentFrame]

        local drawScale = settings.PLAYER_SPRITE_SCALE
        local drawWidth = image:getWidth() * drawScale
        local drawHeight = image:getHeight() * drawScale
        local drawX = p.x + (player.size - drawWidth) / 2
        local drawY = p.y + (player.size - drawHeight) / 2

        love.graphics.draw(image, drawX, drawY, 0, drawScale, drawScale)

        if debug.isEnabled() then
            love.graphics.setColor(1, 0, 0, 0.5)
            love.graphics.rectangle('line', p.x + player.colliderOffset, p.y + player.colliderOffset, player.colliderSize, player.colliderSize)
        end

        if id == network.id and player.spawnEffectPlaying then
            spawnEffect.draw(p.x - player.size / 2, p.y - player.size / 2)
        elseif p.spawnEffectPlaying then
            spawnEffect.draw(p.x - player.size / 2, p.y - player.size / 2)
        end
    end

    if player.currentItem then
        player.currentItem:draw(player)
    end

    -- love.graphics.setShader(darknessShader)

    -- local playerScreenX = player.x + player.size / 2 - camera.x
    -- local playerScreenY = player.y + player.size / 2 - camera.y

    -- darknessShader:send("playerPos", {playerScreenX, playerScreenY})
    -- darknessShader:send("radius", baseRadius)
    -- darknessShader:send("screenSize", {screenWidth, screenHeight})
    -- darknessShader:send("glowColor", {0.8, 0.6, 0.2})

    -- love.graphics.setColor(0, 0, 0, 1)
    -- love.graphics.rectangle('fill', camera.x, camera.y, camera.width, camera.height)

    -- love.graphics.setShader()

    -- WORLD GRID
    if debug.isEnabled() then
        love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
        for x = 0, settings.WORLD_WIDTH do
            love.graphics.line(x * settings.TILE_SIZE, 0, x * settings.TILE_SIZE, settings.WORLD_HEIGHT * settings.TILE_SIZE)
        end
        for y = 0, settings.WORLD_HEIGHT do
            love.graphics.line(0, y * settings.TILE_SIZE, settings.WORLD_WIDTH * settings.TILE_SIZE, y * settings.TILE_SIZE)
        end
    end
end

return player