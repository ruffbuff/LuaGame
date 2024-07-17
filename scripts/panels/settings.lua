-- scripts/panels/settings.lua

local settings = require("scripts.main.settings")
local json = require("scripts.utils.json")

local settingsModal = {}
local pressedKeys = {}

local function keyPressed(key)
    pressedKeys[key] = true
end

local function keyReleased(key)
    pressedKeys[key] = nil
end

local function getFirstPressedKey()
    for key, _ in pairs(pressedKeys) do
        return key
    end
    return nil
end

function settingsModal.load()
    settingsModal.active = false
    settingsModal.selectedTab = 1
    settingsModal.tabs = {"Server", "Player", "Graphics"}
    settingsModal.selectedHotkey = nil
    settingsModal.waitingForInput = false
    settingsModal.loadSettings()
end

function settingsModal.loadSettings()
    local success, contents = pcall(love.filesystem.read, "settings.json")
    if success and contents then
        local loadedSettings = json.decode(contents)
        for key, value in pairs(loadedSettings) do
            settings[key] = value
        end
    end
end

function settingsModal.saveSettings()
    local settingsToSave = {
        MOVE_UP_KEY = settings.MOVE_UP_KEY,
        MOVE_DOWN_KEY = settings.MOVE_DOWN_KEY,
        MOVE_LEFT_KEY = settings.MOVE_LEFT_KEY,
        MOVE_RIGHT_KEY = settings.MOVE_RIGHT_KEY,
        MOVE_FAST_KEY = settings.MOVE_FAST_KEY,
        PAUSE_TOGGLE_KEY = settings.PAUSE_TOGGLE_KEY,
        playerColor = settings.playerColor
    }
    love.filesystem.write("settings.json", json.encode(settingsToSave))
end

function settingsModal.update(dt)
    if settingsModal.waitingForInput then
        local key = getFirstPressedKey()
        if key then
            settings[settingsModal.selectedHotkey] = key
            settingsModal.waitingForInput = false
            settingsModal.selectedHotkey = nil
            settingsModal.saveSettings()
            pressedKeys = {} -- Очистить список нажатых клавиш
        end
    end
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
    if settingsModal.selectedTab == 2 then
        love.graphics.printf("Player settings", contentX, contentY, modalWidth - 40, "left")

        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Player Color:", contentX, contentY + 40)
        for i, color in ipairs(settings.playerColors) do
            local rectX = contentX + 120 + (i - 1) * 50
            local rectY = contentY + 30
            love.graphics.setColor(color[1], color[2], color[3])
            love.graphics.rectangle("fill", rectX, rectY, 40, 40)
            if settings.playerColor[1] == color[1] and settings.playerColor[2] == color[2] and settings.playerColor[3] == color[3] then
                love.graphics.setColor(1, 1, 1)
                love.graphics.rectangle("line", rectX, rectY, 40, 40)
            end
        end

        local hotkeyY = contentY + 100
        local hotkeySettings = {
            {"Move Up", "MOVE_UP_KEY"},
            {"Move Down", "MOVE_DOWN_KEY"},
            {"Move Left", "MOVE_LEFT_KEY"},
            {"Move Right", "MOVE_RIGHT_KEY"},
            {"Move Fast", "MOVE_FAST_KEY"},
            {"Pause", "PAUSE_TOGGLE_KEY"}
        }

        for i, hotkey in ipairs(hotkeySettings) do
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(hotkey[1] .. ":", contentX, hotkeyY + (i-1) * 30)
            love.graphics.rectangle("line", contentX + 150, hotkeyY + (i-1) * 30, 100, 25)
            
            if settingsModal.waitingForInput and settingsModal.selectedHotkey == hotkey[2] then
                love.graphics.print("Press a key...", contentX + 155, hotkeyY + (i-1) * 30 + 5)
            else
                love.graphics.print(settings[hotkey[2]], contentX + 155, hotkeyY + (i-1) * 30 + 5)
            end
        end
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
                settingsModal.saveSettings()
                break
            end
        end

        local hotkeyY = contentY + 100
        local hotkeySettings = {
            {"Move Up", "MOVE_UP_KEY"},
            {"Move Down", "MOVE_DOWN_KEY"},
            {"Move Left", "MOVE_LEFT_KEY"},
            {"Move Right", "MOVE_RIGHT_KEY"},
            {"Move Fast", "MOVE_FAST_KEY"},
            {"Pause", "PAUSE_TOGGLE_KEY"}
        }

        for i, hotkey in ipairs(hotkeySettings) do
            if x >= contentX + 150 and x <= contentX + 250 and
               y >= hotkeyY + (i-1) * 30 and y <= hotkeyY + (i-1) * 30 + 25 then
                settingsModal.selectedHotkey = hotkey[2]
                settingsModal.waitingForInput = true
                break
            end
        end
    end
end

function settingsModal.keypressed(key)
    keyPressed(key)
end

function settingsModal.keyreleased(key)
    keyReleased(key)
end

function settingsModal.close()
    settingsModal.active = false
    settingsModal.selectedHotkey = nil
    settingsModal.waitingForInput = false
end

return settingsModal