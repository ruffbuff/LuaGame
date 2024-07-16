-- scripts/panels/pause.lua

local settings = require("scripts.main.settings")

local pause = {}

local buttons = {
    {text = "Resume", action = function() pause.resume() end},
    {text = "Quit to Menu", action = function() pause.quitToMenu() end}
}

function pause.load()
    pause.font = love.graphics.newFont(24)
end

function pause.update(dt)
    -- Обновление паузы, если нужно
end

function pause.draw()
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    love.graphics.setFont(pause.font)
    for i, button in ipairs(buttons) do
        local buttonWidth = 200
        local buttonHeight = 50
        local x = love.graphics.getWidth() / 2 - buttonWidth / 2
        local y = love.graphics.getHeight() / 2 - (#buttons * buttonHeight) / 2 + (i-1) * buttonHeight * 1.5
        
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.rectangle('fill', x, y, buttonWidth, buttonHeight)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(button.text, x, y + buttonHeight / 2 - pause.font:getHeight() / 2, buttonWidth, 'center')
    end
end

function pause.mousepressed(x, y, button)
    if button == 1 then  -- Left mouse button
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

function pause.resume()
    -- Эта функция будет определена в main.lua
end

function pause.quitToMenu()
    -- Эта функция будет определена в main.lua
end

return pause