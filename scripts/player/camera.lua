-- scripts/player/camera.lua

local settings = require("scripts.main.settings")

local camera = {
    x = 0,
    y = 0,
    scale = 1,
    smoothness = 0.04,
    width = love.graphics.getWidth(),
    height = love.graphics.getHeight()
}

function camera.load(playerX, playerY, playerSize)
    camera.width = love.graphics.getWidth()
    camera.height = love.graphics.getHeight()
    camera.x = playerX - camera.width / 2 + playerSize / 2
    camera.y = playerY - camera.height / 2 + playerSize / 2
end

function camera.update(dt, playerX, playerY, playerSize)
    local targetX = playerX - camera.width / 2 + playerSize / 2
    local targetY = playerY - camera.height / 2 + playerSize / 2

    camera.x = camera.x + (targetX - camera.x) * camera.smoothness
    camera.y = camera.y + (targetY - camera.y) * camera.smoothness

    -- Обновляем размеры камеры на случай изменения окна
    camera.width = love.graphics.getWidth()
    camera.height = love.graphics.getHeight()
    
    -- Ограничиваем камеру границами мира с небольшим запасом
    local worldWidth = settings.WORLD_WIDTH * settings.TILE_SIZE
    local worldHeight = settings.WORLD_HEIGHT * settings.TILE_SIZE
    
    camera.x = math.max(-camera.width * 0.1, math.min(camera.x, worldWidth - camera.width * 0.9))
    camera.y = math.max(-camera.height * 0.1, math.min(camera.y, worldHeight - camera.height * 0.9))
end

function camera.set()
    love.graphics.push()
    love.graphics.translate(-math.floor(camera.x), -math.floor(camera.y))
    love.graphics.scale(camera.scale)
end

function camera.unset()
    love.graphics.pop()
end

function camera.resize(w, h)
    camera.width = w
    camera.height = h
end

function camera:mousePosition()
    local mx, my = love.mouse.getPosition()
    return self.x + mx, self.y + my
end

return camera