-- scripts/panels/serverSelector.lua

local serverSelector = {
    active = false,
    servers = {
        {name = "Local Server", address = "localhost", port = 12345},
        {name = "Empty Slot", address = nil, port = nil},
        {name = "Empty Slot", address = nil, port = nil}
    },
    selectedServer = nil
}

function serverSelector.draw()
    if not serverSelector.active then return end

    local windowWidth, windowHeight = love.graphics.getDimensions()

    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, windowWidth, windowHeight)

    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Select Server", 0, windowHeight * 0.1, windowWidth, "center")

    local buttonWidth = math.min(400, windowWidth * 0.8)
    local buttonHeight = 50
    local spacing = 20
    local totalHeight = #serverSelector.servers * (buttonHeight + spacing) - spacing

    local startY = (windowHeight - totalHeight) / 2

    for i, server in ipairs(serverSelector.servers) do
        local y = startY + (i-1) * (buttonHeight + spacing)
        local x = (windowWidth - buttonWidth) / 2

        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.rectangle("fill", x, y, buttonWidth, buttonHeight)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(server.name, x, y + (buttonHeight - love.graphics.getFont():getHeight()) / 2, buttonWidth, "center")
    end
end

function serverSelector.mousepressed(x, y, button)
    if not serverSelector.active then return end

    local windowWidth, windowHeight = love.graphics.getDimensions()
    local buttonWidth = math.min(400, windowWidth * 0.8)
    local buttonHeight = 50
    local spacing = 20
    local totalHeight = #serverSelector.servers * (buttonHeight + spacing) - spacing

    local startY = (windowHeight - totalHeight) / 2
    local startX = (windowWidth - buttonWidth) / 2

    for i, server in ipairs(serverSelector.servers) do
        local buttonY = startY + (i-1) * (buttonHeight + spacing)
        if x >= startX and x <= startX + buttonWidth and y >= buttonY and y <= buttonY + buttonHeight then
            if server.address then
                serverSelector.selectedServer = server
                return true
            end
        end
    end
    return false
end

return serverSelector