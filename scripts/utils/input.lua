-- scripts/utils/input.lua

local settings = require("scripts.main.settings")
local player = require("scripts.player.player")
local camera = require("scripts.player.camera")

local input = {}

function input.keypressed(key)
    if key == settings.GRAPPLING_HOOK_SHOOT_KEY and player.currentItem then
        local mx, my = love.mouse.getPosition()
        local worldX, worldY = camera.x + mx, camera.y + my
        player.currentItem:shoot(player, worldX, worldY)
    elseif key == settings.GRAPPLING_HOOK_DETACH_KEY and player.currentItem then
        player.currentItem:detach()
    end
end

return input