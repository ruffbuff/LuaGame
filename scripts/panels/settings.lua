-- scripts/panels/settings.lua

local settings = require("scripts.main.settings")

local settingsModal = {}

function settingsModal.load()
    settingsModal.active = false
    settingsModal.selectedTab = 1
    settingsModal.tabs = {"Server", "Player", "Graphics"}
end

function settingsModal.update(dt)
end

function settingsModal.draw()
    if not settingsModal.active then return end

    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    love.graphics.setColor(0.2, 0.2, 0.2, 0.9)
    local modalWidth = 600
    local modalHeight = 400
    local modalX = (love.graphics.getWidth() - modalWidth) / 2
    local modalY = (love.graphics.getHeight() - modalHeight) / 2
    love.graphics.rectangle("fill", modalX, modalY, modalWidth, modalHeight)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.printf("Settings", modalX, modalY + 20, modalWidth, "center")

    local tabWidth = modalWidth / #settingsModal.tabs
    for i, tab in ipairs(settingsModal.tabs) do
        local tabX = modalX + (i - 1) * tabWidth
        local tabY = modalY + 60
        love.graphics.setColor(0.4, 0.4, 0.4)
        if settingsModal.selectedTab == i then
            love.graphics.setColor(0.6, 0.6, 0.6)
        end
        love.graphics.rectangle("fill", tabX, tabY, tabWidth, 40)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(tab, tabX, tabY + 10, tabWidth, "center")
    end

    local contentX = modalX + 20
    local contentY = modalY + 120
    if settingsModal.selectedTab == 1 then
        love.graphics.printf("Server settings", contentX, contentY, modalWidth - 40, "left")
    elseif settingsModal.selectedTab == 2 then
        love.graphics.printf("Player settings", contentX, contentY, modalWidth - 40, "left")
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Player Color:", contentX, contentY + 40)
        for i, color in ipairs(settings.playerColors) do
            local rectX = contentX + 120 + (i - 1) * 50
            local rectY = contentY + 30
            love.graphics.setColor(color[1], color[2], color[3])
            love.graphics.rectangle("fill", rectX, rectY, 40, 40)
            if settings.playerColor == color then
                love.graphics.setColor(1, 1, 1)
                love.graphics.rectangle("line", rectX, rectY, 40, 40)
            end
        end
    elseif settingsModal.selectedTab == 3 then
        love.graphics.printf("Graphics settings", contentX, contentY, modalWidth - 40, "left")
    end
end

function settingsModal.mousepressed(x, y, button, network)
    if not settingsModal.active then return end

    local modalWidth = 600
    local modalHeight = 400
    local modalX = (love.graphics.getWidth() - modalWidth) / 2
    local modalY = (love.graphics.getHeight() - modalHeight) / 2

    local tabWidth = modalWidth / #settingsModal.tabs
    for i, tab in ipairs(settingsModal.tabs) do
        local tabX = modalX + (i - 1) * tabWidth
        local tabY = modalY + 60
        if x >= tabX and x <= tabX + tabWidth and y >= tabY and y <= tabY + 40 then
            settingsModal.selectedTab = i
            break
        end
    end

    if settingsModal.selectedTab == 2 then
        local contentX = modalX + 20
        local contentY = modalY + 120
        for i, color in ipairs(settings.playerColors) do
            local rectX = contentX + 120 + (i - 1) * 50
            local rectY = contentY + 30
            if x >= rectX and x <= rectX + 40 and y >= rectY and y <= rectY + 40 then
                settings.playerColor = color
                network.setPlayerColor(color)
                network.sendPlayerColor(color)
                break
            end
        end
    end
end

return settingsModal