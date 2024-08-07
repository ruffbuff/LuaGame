-- scripts/player/player.lua

local settings = require("scripts.main.settings")
local network = require("scripts.network.network")
local tiles = require("scripts.world.tiles")
local debug = require("scripts.main.debug")
local items = require("scripts.items.items")
local darknessShader = require("scripts.shaders.darkness")
local camera = require("scripts.player.camera")

local player = {
    x = 1568,
    y = 1568,
    velocityX = 0,
    velocityY = 0,
    size = settings.PLAYER_SIZE,
    colliderSize = settings.TILE_SIZE * 0.8,
    colliderOffset = settings.TILE_SIZE * 0.1,
    currentSpeed = 0,
    dashCooldown = 0,
    dashCooldownDuration = 1,
    baseSpeed = settings.PLAYER_SPEED,
    fastMultiplier = 1.5,
    otherPlayers = {},
    currentItem = items.grapplingHook,
    direction = "down",
    state = "idle",
    animationTimer = 0,
    currentFrame = 1,
    animations = {},
    hookAnimationTimer = 0,
    hookAnimationFrame = 1,
    isHooking = false,
    targetX = nil,
    targetY = nil,
    moveThreshold = 5
}

local function loadAnimations()
    player.animations = {}

    for colorName, colorValue in pairs(settings.playerColors) do
        player.animations[colorName] = {}
        local directions = {"down", "up", "left", "right"}
        for _, dir in ipairs(directions) do
            player.animations[colorName][dir] = {
                idle = love.graphics.newImage("assets/images/" .. colorName .. "-cat/" .. dir .. "/0.png"),
                walk = {},
                run = {}
            }
            player.animations[colorName][dir].idle:setFilter("nearest", "nearest")
            for i = 0, 3 do
                local frame = love.graphics.newImage("assets/images/" .. colorName .. "-cat/" .. dir .. "/" .. i .. ".png")
                frame:setFilter("nearest", "nearest")
                table.insert(player.animations[colorName][dir].walk, frame)
                table.insert(player.animations[colorName][dir].run, frame)
            end
        end
    end

    player.animations["red"].hook = {}
    for i = 0, 3 do
        local hookFrame = love.graphics.newImage("assets/images/red-cat/hook/" .. i .. ".png")
        hookFrame:setFilter("nearest", "nearest")
        table.insert(player.animations["red"].hook, hookFrame)
    end
end

function player.setTarget(x, y)
    player.targetX = x
    player.targetY = y
end

function player.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    loadAnimations()
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

function player.updateStateAfterHook()
    local dx, dy = 0, 0
    if love.keyboard.isDown(settings.MOVE_LEFT_KEY) then dx = dx - 1 end
    if love.keyboard.isDown(settings.MOVE_RIGHT_KEY) then dx = dx + 1 end
    if love.keyboard.isDown(settings.MOVE_UP_KEY) then dy = dy - 1 end
    if love.keyboard.isDown(settings.MOVE_DOWN_KEY) then dy = dy + 1 end

    if dx ~= 0 or dy ~= 0 then
        player.state = "walk"
        if dx < 0 then player.direction = "left"
        elseif dx > 0 then player.direction = "right"
        elseif dy < 0 then player.direction = "up"
        elseif dy > 0 then player.direction = "down"
        end
    else
        player.state = "idle"
    end
    player.currentFrame = 1
end

function player.update(dt, camera, networkPlayer)
    if player.currentItem and player.currentItem.state ~= "idle" then
        player.isHooking = true
        player.state = "hook"
    else
        player.isHooking = false
    end

    local dx, dy = 0, 0
    local oldDirection = player.direction

    if settings.MOVEMENT_TYPE == "mouse" then
        if player.targetX and player.targetY then
            dx = player.targetX - player.x
            dy = player.targetY - player.y
            local length = math.sqrt(dx*dx + dy*dy)
            if length > player.moveThreshold then
                dx = dx / length
                dy = dy / length
            else
                player.targetX = nil
                player.targetY = nil
                dx, dy = 0, 0
            end
        end
    elseif settings.MOVEMENT_TYPE == "wasd" then
        if love.keyboard.isDown(settings.MOVE_LEFT_KEY) then dx = dx - 1 end
        if love.keyboard.isDown(settings.MOVE_RIGHT_KEY) then dx = dx + 1 end
        if love.keyboard.isDown(settings.MOVE_UP_KEY) then dy = dy - 1 end
        if love.keyboard.isDown(settings.MOVE_DOWN_KEY) then dy = dy + 1 end
    elseif settings.MOVEMENT_TYPE == "arrows" then
        if love.keyboard.isDown("left") then dx = dx - 1 end
        if love.keyboard.isDown("right") then dx = dx + 1 end
        if love.keyboard.isDown("up") then dy = dy - 1 end
        if love.keyboard.isDown("down") then dy = dy + 1 end
    end

    if dx < 0 then player.direction = "left"
    elseif dx > 0 then player.direction = "right"
    elseif dy < 0 then player.direction = "up"
    elseif dy > 0 then player.direction = "down"
    end

    if dx ~= 0 and dy ~= 0 then
        dx = dx / math.sqrt(2)
        dy = dy / math.sqrt(2)
    end

    if dx ~= 0 or dy ~= 0 then
        if math.abs(dx) > math.abs(dy) then
            player.direction = dx > 0 and "right" or "left"
        else
            player.direction = dy > 0 and "down" or "up"
        end
    end

    if dx == 0 and dy == 0 and not player.isHooking then
        player.state = "idle"
    elseif not player.isHooking then
        player.state = love.keyboard.isDown(settings.MOVE_FAST_KEY) and "run" or "walk"
    end

    if player.isHooking then
        player.state = "hook"
        player.hookAnimationTimer = player.hookAnimationTimer + dt
        if player.hookAnimationTimer >= 0.1 then
            player.hookAnimationTimer = player.hookAnimationTimer - 0.1
            player.hookAnimationFrame = player.hookAnimationFrame % 4 + 1
        end
    else
        local animationSpeed = (player.state == "run") and 0.1 or 0.2
        player.animationTimer = player.animationTimer + dt
        if player.animationTimer >= animationSpeed then
            player.animationTimer = player.animationTimer - animationSpeed
            player.currentFrame = player.currentFrame % 4 + 1
        end
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

    if not tiles.checkCollision(newX, player.y, player.size) then
        player.x = newX
    end
    if not tiles.checkCollision(player.x, newY, player.size) then
        player.y = newY
    end

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

    player.otherPlayers = {}
    for id, p in pairs(network.players) do
        if id ~= network.id then
            player.otherPlayers[id] = p
        end
    end
end

function player.draw(camera)
    for id, p in pairs(network.players) do
        love.graphics.setColor(1, 1, 1)
        local direction = p.direction or "down"
        local state = p.state or "idle"
        local currentFrame = p.currentFrame or 1
        local colorName = p.colorName or nil
        
        if not colorName or not settings.playerColors[colorName] then
            print("Warning: Invalid color for player " .. id .. ": " .. tostring(colorName))
            colorName = "red"
        end
        
        local animation = player.animations[colorName][direction]
        local image

        if state == "hook" and colorName == "red" then
            image = player.animations["red"].hook[p.hookAnimationFrame or 1]
        else
            image = (state == "idle") and animation.idle or animation[state][currentFrame]
        end

        local drawScale = settings.PLAYER_SPRITE_SCALE
        local drawWidth = image:getWidth() * drawScale
        local drawHeight = image:getHeight() * drawScale
        local drawX = p.x + (player.size - drawWidth) / 2
        local drawY = p.y + (player.size - drawHeight) / 2

        love.graphics.draw(image, drawX, drawY, 0, drawScale, drawScale)

        love.graphics.setColor(1, 1, 1, 1)

        if debug.isEnabled() then
            love.graphics.setColor(1, 0, 0, 0.5)
            love.graphics.rectangle('line', p.x + player.colliderOffset, p.y + player.colliderOffset, player.colliderSize, player.colliderSize)
            love.graphics.setColor(1, 1, 1, 1)
        end
    end

    love.graphics.setColor(1, 1, 1, 1)

    if player.currentItem then
        player.currentItem:draw(player)
    end

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