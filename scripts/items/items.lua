-- scripts/items/items.lua

local settings = require("scripts.main.settings")
local tiles = require("scripts.world.tiles")

local items = {}

local grapplingHook = {
    name = "Grappling Hook",
    range = 700,
    speed = 1200,
    pullSpeed = 1200,
    state = "idle",
    x = 0,
    y = 0,
    targetX = 0,
    targetY = 0,
    angle = 0,
    length = 0,
    swingForce = 400,
    swingDamping = 0.98
}

function grapplingHook:shoot(player, mouseX, mouseY)
    if self.state == "idle" then
        self.x = player.x + player.size / 2
        self.y = player.y + player.size / 2
        self.targetX = mouseX
        self.targetY = mouseY
        self.angle = math.atan2(self.targetY - self.y, self.targetX - self.x)
        self.length = 0
        self.state = "shooting"
        player.velocityX = 0
        player.velocityY = 0
    end
end

function grapplingHook:detach()
    if self.state == "attached" or self.state == "shooting" then
        self.state = "idle"
    end
end

function grapplingHook:update(dt, player)
    local playerCenterX = player.x + player.size / 2
    local playerCenterY = player.y + player.size / 2

    if self.state == "shooting" then
        self.length = self.length + self.speed * dt
        local endX = playerCenterX + math.cos(self.angle) * self.length
        local endY = playerCenterY + math.sin(self.angle) * self.length

        if tiles.checkCollision(endX, endY, 1) then
            self.state = "attached"
            self.targetX = endX
            self.targetY = endY
            self.length = math.sqrt((self.targetX - playerCenterX)^2 + (self.targetY - playerCenterY)^2)
        elseif self.length >= self.range then
            self.state = "retracting"
        end
    elseif self.state == "attached" then
        local dx = self.targetX - playerCenterX
        local dy = self.targetY - playerCenterY
        local distance = math.sqrt(dx^2 + dy^2)
        
        -- Применяем силу притяжения
        local pullForce = self.pullSpeed * dt
        player.velocityX = player.velocityX + (dx / distance) * pullForce
        player.velocityY = player.velocityY + (dy / distance) * pullForce
        
        -- Позволяем игроку раскачиваться
        local perpX, perpY = -dy / distance, dx / distance
        local swingInput = 0
        if love.keyboard.isDown(settings.MOVE_LEFT_KEY) then swingInput = swingInput - 1 end
        if love.keyboard.isDown(settings.MOVE_RIGHT_KEY) then swingInput = swingInput + 1 end
        
        player.velocityX = player.velocityX + perpX * swingInput * self.swingForce * dt
        player.velocityY = player.velocityY + perpY * swingInput * self.swingForce * dt
        
        -- Применяем затухание к скорости
        player.velocityX = player.velocityX * self.swingDamping
        player.velocityY = player.velocityY * self.swingDamping
        
        -- Обновляем позицию игрока
        local newX = player.x + player.velocityX * dt
        local newY = player.y + player.velocityY * dt
        
        -- Проверяем коллизии
        if not tiles.checkCollision(newX + player.colliderOffset, newY + player.colliderOffset, player.colliderSize) then
            player.x = newX
            player.y = newY
        else
            player.velocityX = 0
            player.velocityY = 0
            self.state = "idle"
        end
        
        -- Ограничиваем длину веревки
        local newDistance = math.sqrt((self.targetX - (player.x + player.size / 2))^2 + (self.targetY - (player.y + player.size / 2))^2)
        if newDistance > self.length then
            local angle = math.atan2(self.targetY - (player.y + player.size / 2), self.targetX - (player.x + player.size / 2))
            player.x = self.targetX - math.cos(angle) * self.length - player.size / 2
            player.y = self.targetY - math.sin(angle) * self.length - player.size / 2
        end
    elseif self.state == "retracting" then
        self.length = self.length - self.speed * dt
        if self.length <= 0 then
            self.state = "idle"
        end
    end
end

function grapplingHook:draw(player)  -- Добавим player как аргумент
    if self.state ~= "idle" then
        love.graphics.setColor(1, 1, 1)
        local startX, startY, endX, endY

        if self.state == "shooting" or self.state == "retracting" then
            startX = player.x + player.size / 2
            startY = player.y + player.size / 2
            endX = startX + math.cos(self.angle) * self.length
            endY = startY + math.sin(self.angle) * self.length
        elseif self.state == "attached" then
            startX = player.x + player.size / 2
            startY = player.y + player.size / 2
            endX = self.targetX
            endY = self.targetY
        end

        love.graphics.line(startX, startY, endX, endY)
    end
end

items.grapplingHook = grapplingHook

return items