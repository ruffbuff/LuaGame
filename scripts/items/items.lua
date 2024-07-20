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
    swingDamping = 0.98,
}

function grapplingHook:use(player)
    local mx, my = love.mouse.getPosition()
    local worldX, worldY = camera.x + mx, camera.y + my
    self:shoot(player, worldX, worldY)
end

function grapplingHook:shoot(player, mouseX, mouseY)
    if self.state == "idle" then
        local offsetY = player.size * 0.18
        self.x = player.x + player.size / 2
        self.y = player.y + player.size / 2 + offsetY

        self.targetX = mouseX
        self.targetY = mouseY
        self.angle = math.atan2(self.targetY - self.y, self.targetX - self.x)
        self.length = 0
        self.state = "shooting"
        player.velocityX = 0
        player.velocityY = 0
        player.isHooking = true
        player.hookAnimationFrame = 1
        player.hookAnimationTimer = 0
    end
end

function grapplingHook:detach(player)
    self.state = "idle"
    if player then
        player.isHooking = false
        player.hookAnimationFrame = 1
        player.hookAnimationTimer = 0
        player.state = "idle"
        player:updateStateAfterHook()
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

        local pullForce = self.pullSpeed * dt
        player.velocityX = player.velocityX + (dx / distance) * pullForce
        player.velocityY = player.velocityY + (dy / distance) * pullForce

        local perpX, perpY = -dy / distance, dx / distance
        local swingInput = 0
        if love.keyboard.isDown(settings.MOVE_LEFT_KEY) then swingInput = swingInput - 1 end
        if love.keyboard.isDown(settings.MOVE_RIGHT_KEY) then swingInput = swingInput + 1 end

        player.velocityX = player.velocityX + perpX * swingInput * self.swingForce * dt
        player.velocityY = player.velocityY + perpY * swingInput * self.swingForce * dt

        player.velocityX = player.velocityX * self.swingDamping
        player.velocityY = player.velocityY * self.swingDamping

        local newX = player.x + player.velocityX * dt
        local newY = player.y + player.velocityY * dt

        if not tiles.checkCollision(newX + player.colliderOffset, newY + player.colliderOffset, player.colliderSize) then
            player.x = newX
            player.y = newY
        else
            player.velocityX = 0
            player.velocityY = 0
            self.state = "idle"
        end

        local newDistance = math.sqrt((self.targetX - (player.x + player.size / 2))^2 + (self.targetY - (player.y + player.size / 2))^2)
        if newDistance > self.length then
            local angle = math.atan2(self.targetY - (player.y + player.size / 2), self.targetX - (player.x + player.size / 2))
            player.x = self.targetX - math.cos(angle) * self.length - player.size / 2
            player.y = self.targetY - math.sin(angle) * self.length - player.size / 2
        end
    elseif self.state == "retracting" then
        self.length = self.length - self.speed * dt
        if self.length <= 0 then
            self:detach(player)
        end
    end
end

function grapplingHook:draw(player)
    if self.state ~= "idle" then
        local offsetY = player.size * 0.18
        local startX = player.x + player.size / 2
        local startY = player.y + player.size / 2 + offsetY
        local endX, endY

        if self.state == "shooting" or self.state == "retracting" then
            endX = startX + math.cos(self.angle) * self.length
            endY = startY + math.sin(self.angle) * self.length
        elseif self.state == "attached" then
            endX = self.targetX
            endY = self.targetY
        end

        local ropeLength = math.sqrt((endX - startX)^2 + (endY - startY)^2)
        local segments = 40
        local segmentLength = ropeLength / segments

        local ropeWidth = 8
        local twistFrequency = 0.5

        love.graphics.setColor(0.6, 0.4, 0.2)
        love.graphics.setLineWidth(ropeWidth)
        love.graphics.line(startX, startY, endX, endY)

        for i = 0, segments do
            local t = i / segments
            local x = startX + (endX - startX) * t
            local y = startY + (endY - startY) * t
            
            local sag = math.sin(t * math.pi) * 3
            x = x + sag * math.cos(self.angle + math.pi/2)
            y = y + sag * math.sin(self.angle + math.pi/2)

            local detailAngle = t * math.pi * 2 * twistFrequency
            love.graphics.setColor(0.7, 0.5, 0.3)
            love.graphics.line(
                x + math.cos(detailAngle) * ropeWidth/2, y + math.sin(detailAngle) * ropeWidth/2,
                x - math.cos(detailAngle) * ropeWidth/2, y - math.sin(detailAngle) * ropeWidth/2
            )
        end

        love.graphics.setColor(0.8, 0.6, 0.4, 0.5)
        love.graphics.setLineWidth(2)
        local highlightOffset = ropeWidth/2 - 1
        local highlightX1 = startX + highlightOffset * math.cos(self.angle + math.pi/2)
        local highlightY1 = startY + highlightOffset * math.sin(self.angle + math.pi/2)
        local highlightX2 = endX + highlightOffset * math.cos(self.angle + math.pi/2)
        local highlightY2 = endY + highlightOffset * math.sin(self.angle + math.pi/2)
        love.graphics.line(highlightX1, highlightY1, highlightX2, highlightY2)

        love.graphics.setColor(0.7, 0.7, 0.7)
        local hookSize = 18
        local hookAngle = math.atan2(endY - startY, endX - startX)

        love.graphics.arc("fill", endX, endY, hookSize, hookAngle - math.pi/2, hookAngle + math.pi/2)

        local tipLength = hookSize * 1.5
        local tipEndX = endX + math.cos(hookAngle) * tipLength
        local tipEndY = endY + math.sin(hookAngle) * tipLength
        love.graphics.polygon("fill", 
            endX + math.cos(hookAngle - math.pi/2) * hookSize,
            endY + math.sin(hookAngle - math.pi/2) * hookSize,
            endX + math.cos(hookAngle + math.pi/2) * hookSize,
            endY + math.sin(hookAngle + math.pi/2) * hookSize,
            tipEndX, tipEndY
        )

        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.arc("line", endX, endY, hookSize - 2, hookAngle - math.pi/4, hookAngle + math.pi/4)
        love.graphics.line(
            endX + math.cos(hookAngle - math.pi/4) * (hookSize - 2),
            endY + math.sin(hookAngle - math.pi/4) * (hookSize - 2),
            tipEndX - math.cos(hookAngle) * 5,
            tipEndY - math.sin(hookAngle) * 5
        )
    end

    love.graphics.setLineWidth(1)
end

items.grapplingHook = grapplingHook

return items