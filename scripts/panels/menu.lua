-- scripts/panels/menu.lua

local settings = require("scripts.main.settings")
local serverSelector = require("scripts.panels.serverSelector")

local menu = {}

local buttons = {
    {text = "Start Game", action = function() serverSelector.active = true end},
    {text = "Quit Game", action = function() love.event.quit() end}
}

function menu.load()
end

function menu.update(dt)
end

function menu.draw()
    if serverSelector.active then
        serverSelector.draw()
    else
        local windowWidth, windowHeight = love.graphics.getDimensions()
        love.graphics.setFont(globalFont)
        for i, button in ipairs(buttons) do
            local buttonWidth = 200
            local buttonHeight = 50
            local x = windowWidth / 2 - buttonWidth / 2
            local y = windowHeight / 2 - (#buttons * buttonHeight) / 2 + (i-1) * buttonHeight * 1.5
            
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.rectangle('fill', x, y, buttonWidth, buttonHeight)
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(button.text, x, y + buttonHeight / 2 - globalFont:getHeight() / 2, buttonWidth, 'center')
        end
    end
end

function menu.mousepressed(x, y, button)
    if serverSelector.active then
        if serverSelector.mousepressed(x, y, button) then
            menu.startGame(serverSelector.selectedServer.address, serverSelector.selectedServer.port)
            serverSelector.active = false
        end
    elseif button == 1 then
        local windowWidth, windowHeight = love.graphics.getDimensions()
        for i, btn in ipairs(buttons) do
            local buttonWidth = 200
            local buttonHeight = 50
            local bx = windowWidth / 2 - buttonWidth / 2
            local by = windowHeight / 2 - (#buttons * buttonHeight) / 2 + (i-1) * buttonHeight * 1.5
            
            if x >= bx and x <= bx + buttonWidth and y >= by and y <= by + buttonHeight then
                btn.action()
            end
        end
    end
end

function menu.startGame(address, port)
end

return menu