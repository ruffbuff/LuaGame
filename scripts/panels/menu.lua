-- scripts/panels/menu.lua

local settings = require("scripts.main.settings")

local menu = {}

local buttons = {
    {text = "Start Game", action = function() menu.startGame() end},
    {text = "Quit Game", action = function() love.event.quit() end}
}

function menu.load()
    menu.font = love.graphics.newFont(24)
end

function menu.update(dt)
end

function menu.draw()
    love.graphics.setFont(menu.font)
    for i, button in ipairs(buttons) do
        local buttonWidth = 200
        local buttonHeight = 50
        local x = love.graphics.getWidth() / 2 - buttonWidth / 2
        local y = love.graphics.getHeight() / 2 - (#buttons * buttonHeight) / 2 + (i-1) * buttonHeight * 1.5
        
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.rectangle('fill', x, y, buttonWidth, buttonHeight)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(button.text, x, y + buttonHeight / 2 - menu.font:getHeight() / 2, buttonWidth, 'center')
    end
end

function menu.mousepressed(x, y, button)
    if button == 1 then
        for i, btn in ipairs(buttons) do
            local buttonWidth = 200
            local buttonHeight = 50
            local bx = love.graphics.getWidth() / 2 - buttonWidth / 2
            local by = love.graphics.getHeight() / 2 - (#buttons * buttonHeight) / 2 + (i-1) * buttonHeight * 1.5
            
            if x >= bx and x <= bx + buttonWidth and y >= by and y <= by + buttonHeight then
                btn.action()
            end
        end
    end
end

function menu.startGame()
end

return menu