-- scripts/effects/spawnEffect.lua

local spawnEffect = {}

local frames = {}
local currentFrame = 1
local animationTime = 0
local animationDuration = 1
local frameCount = 5
local playCount = 0
local maxPlayCount = 1
local scale = 4

function spawnEffect.load()
    for i = 0, frameCount - 1 do
        frames[i+1] = love.graphics.newImage("assets/images/effects/spawn/" .. i .. ".png")
    end
end

function spawnEffect.play()
    spawnEffect.isPlaying = true
    animationTime = 0
    currentFrame = 1
    playCount = 0
end

function spawnEffect.update(dt)
    if spawnEffect.isPlaying then
        animationTime = animationTime + dt
        currentFrame = math.floor((animationTime / animationDuration) * frameCount) + 1
        
        if currentFrame > frameCount then
            playCount = playCount + 1
            if playCount >= maxPlayCount then
                spawnEffect.isPlaying = false
            else
                animationTime = animationTime % animationDuration
                currentFrame = 1
            end
        end
    end
end

function spawnEffect.draw(x, y)
    if spawnEffect.isPlaying then
        love.graphics.setColor(1, 1, 1, 1)
        local frame = frames[currentFrame]
        local frameWidth, frameHeight = frame:getDimensions()
        love.graphics.draw(frame, x, y, 0, scale, scale, frameWidth / 2, frameHeight / 2)
    end
end

return spawnEffect