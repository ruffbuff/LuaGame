-- scripts/player/camera.lua

local settings = require("scripts.main.settings")
local player = require("scripts.player.player")

local camera = {
    x = 0,
    y = 0,
    scale = 1,
    smoothness = 0.04,
    width = love.graphics.getWidth(),
    height = love.graphics.getHeight()
}

function camera.load()
    camera.x = player.x - camera.width / 2 + player.size / 2
    camera.y = player.y - camera.height / 2 + player.size / 2
end

function camera.update(dt)
    local targetX = player.x - camera.width / 2 + player.size / 2
    local targetY = player.y - camera.height / 2 + player.size / 2

    camera.x = camera.x + (targetX - camera.x) * camera.smoothness
    camera.y = camera.y + (targetY - camera.y) * camera.smoothness

    camera.x = math.max(0, math.min(camera.x, settings.WORLD_WIDTH * settings.TILE_SIZE - camera.width))
    camera.y = math.max(0, math.min(camera.y, settings.WORLD_HEIGHT * settings.TILE_SIZE - camera.height))
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

return camera