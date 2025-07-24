-- scripts/main/main.lua

local settings = require("scripts.main.settings")
local debug = require("scripts.main.debug")
local player = require("scripts.player.player")
local world = require("scripts.world.world")
local tiles = require("scripts.world.tiles")
local camera = require("scripts.player.camera")
local menu = require("scripts.panels.menu")
local pause = require("scripts.panels.pause")
local settingsModal = require("scripts.panels.settings")
local network = require("scripts.network.network")
local input = require("scripts.utils.input")
local cursor = require("scripts.ui.cursor")
local survival = require("scripts.player.survival")
local inventory = require("scripts.player.inventory")

local gameState = "menu"  -- "menu", "waiting", "game", "pause"
local customFont

local function startGame(address, port)
    network.connectToServer(address, port)
    gameState = "connecting"
end

local function resetGame()
    tiles.load()
    world.load()
    player.load()
    camera.load(player.x, player.y, player.size)
end

globalFont = nil

function love.load(dt)
    love.window.setMode(settings.WINDOW_WIDTH, settings.WINDOW_HEIGHT, {
        resizable = settings.WINDOW_RESIZABLE,
        minwidth = 800,
        minheight = 600
    })
    love.mouse.setVisible(false)  -- Скрыть системный курсор

    love.window.setTitle(settings.GAME_NAME)
    globalFont = love.graphics.newFont(settings.FONT_PATH, settings.FONT_SIZE)

    love.graphics.setFont(globalFont)
    tiles.load()
    world.load()

    player.load()
    menu.load()
    pause.load()
    settingsModal.load()

    menu.startGame = startGame
    love.keyboard.setKeyRepeat(true)

    pause.resume = function()
        gameState = "game"
    end

    pause.openSettings = function()
        settingsModal.active = true
    end

    pause.quitToMenu = function()
        network.disconnect()
        gameState = "menu"
    end
end

function love.update(dt)
    local networkStatus = network.update()
    if networkStatus then
        print("Network status received:", networkStatus)
        if networkStatus == "ID_RECEIVED" or networkStatus == "START" then
            if gameState ~= "game" then
                print("Switching to game state")
                resetGame()
                gameState = "game"
                print("Game state set to:", gameState)
            end
        end
    end

    cursor.update()  -- Обновление позиции курсора

    if gameState == "game" then
        player.update(dt, camera)
        camera.update(dt, player.x, player.y, player.size)
        world.update(dt)
    elseif gameState == "menu" then
        menu.update(dt)
    elseif gameState == "pause" then
        player.update(dt, camera)
        camera.update(dt, player.x, player.y, player.size)
        world.update(dt)
        pause.update(dt)
    end

    if settingsModal.active then
        settingsModal.update(dt)
    end
end

function love.draw()
    love.graphics.setFont(globalFont)
    if gameState == "game" then
        camera.set()
        world.draw()
        camera.unset()
        survival.drawUI()  -- UI отрисовывается после camera.unset()
        inventory.drawUI()  -- Инвентарь поверх всего
        debug.draw(player, network, gameState)
    elseif gameState == "menu" then
        menu.draw()
    elseif gameState == "pause" then
        camera.set()
        world.draw()
        camera.unset()
        survival.drawUI()  -- UI и в режиме паузы тоже
        inventory.drawUI()  -- Инвентарь и в паузе
        pause.draw()
        if settingsModal.active then
            settingsModal.draw()
        end
        if debug.isEnabled() then
            debug.draw(player, network, gameState)
        end
    -- else
    --     -- Debug: показываем текущее состояние если оно не распознано
    --     love.graphics.print("Current gameState: " .. tostring(gameState), 10, 10)
    --     love.graphics.print("Network connected: " .. tostring(network.connected), 10, 30)
    --     love.graphics.print("Network ID: " .. tostring(network.id), 10, 50)
    end
    cursor.draw()
end

function love.keypressed(key)
    if settingsModal.active then
        if key == settings.PAUSE_TOGGLE_KEY then
            settingsModal.active = false
        else
            settingsModal.keypressed(key)
        end
    else
        if key == settings.DEBUG_TOGGLE_KEY then
            debug.toggle()
        elseif key == settings.PAUSE_TOGGLE_KEY then
            if gameState == "game" then
                gameState = "pause"
            elseif gameState == "pause" then
                gameState = "game"
            end
        elseif key == settings.FULLSCREEN_TOGGLE_KEY then
            love.window.setFullscreen(not love.window.getFullscreen())
        elseif key == "tab" then
            inventory.toggle()
        elseif gameState == "game" then
            -- Система строительства
            if key == "1" then
                -- Костёр
                local worldX, worldY = camera:mousePosition()
                world.buildStructure("campfire", worldX, worldY, inventory)
            elseif key == "2" then
                -- Стена
                local worldX, worldY = camera:mousePosition()
                world.buildStructure("wall", worldX, worldY, inventory)
            elseif key == "3" then
                -- Грядка
                local worldX, worldY = camera:mousePosition()
                world.buildStructure("garden_bed", worldX, worldY, inventory)
            else
                input.keypressed(key)
            end
        end
    end
end

function love.keyreleased(key)
    if settingsModal.active then
        settingsModal.keyreleased(key)
    end
end

function love.mousepressed(x, y, button)
    if gameState == "game" then
        local worldX, worldY = camera:mousePosition()
        local clickedOnPlayer = false
        
        for id, p in pairs(network.players) do
            if id ~= network.id then
                local dx = worldX - p.x
                local dy = worldY - p.y
                if dx*dx + dy*dy < player.size*player.size then
                    print("Clicked on player " .. id)
                    clickedOnPlayer = true
                    break
                end
            end
        end
        
        if not clickedOnPlayer and settings.MOVEMENT_TYPE == "mouse" and button == 1 then
            player.setTarget(worldX, worldY)
        end
    elseif gameState == "menu" then
        menu.mousepressed(x, y, button)
    elseif gameState == "pause" then
        if settingsModal.active then
            settingsModal.mousepressed(x, y, button, network)
        else
            pause.mousepressed(x, y, button)
        end
    end
end

function love.resize(w, h)
    if camera.resize then
        camera.resize(w, h)
    end
end

function love.quit()
    network.disconnect()
end
