-- scripts/main/main.lua

local settings = require("scripts.main.settings")
local debug = require("scripts.main.debug")
local player = require("scripts.player.player")
local world = require("scripts.world.world")
local camera = require("scripts.player.camera")
local menu = require("scripts.panels.menu")
local pause = require("scripts.panels.pause")
local settingsModal = require("scripts.panels.settings")
local network = require("scripts.network.network")
local minimap = require("scripts.player.minimap")
local chat = require("scripts.player.chat")

local gameState = "menu"  -- "menu", "waiting", "game", "pause"

local function startGame(address, port)
    network.connectToServer(address, port)
    gameState = "connecting"
end

local function resetGame()
    world.load()
    player.load()
    camera.load()
end

function love.load(dt)
    love.window.setMode(settings.WINDOW_WIDTH, settings.WINDOW_HEIGHT, {
        resizable = settings.WINDOW_RESIZABLE,
        minwidth = 800,
        minheight = 600
    })
    love.window.setTitle(settings.GAME_NAME)

    menu.load()
    pause.load()
    settingsModal.load()

    menu.startGame = startGame
    chat.load()
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

    network.setChatCallback(chat.receiveMessage)
end

function love.update(dt)
    local networkStatus = network.update()
    if networkStatus then
        if networkStatus == "ID_RECEIVED" or networkStatus == "START" then
            if gameState ~= "game" then
                resetGame()
                gameState = "game"
            end
        end
    end

    if gameState == "game" then
        world.update(dt)
        player.update(dt, chat)
        camera.update(dt)
    elseif gameState == "menu" then
        menu.update(dt)
    elseif gameState == "pause" then
        pause.update(dt)
        world.update(dt)
        player.update(dt, chat)
        camera.update(dt)
    end

    if settingsModal.active then
        settingsModal.update(dt)
    end

    chat.update(dt)
end

function love.draw()
    if gameState == "game" then
        camera.set()
        world.draw()
        player.draw()
        camera.unset()
        minimap.draw()
        chat.draw()
        debug.draw(player, network)
    elseif gameState == "menu" then
        menu.draw()
    elseif gameState == "pause" then
        camera.set()
        world.draw()
        player.draw()
        camera.unset()
        pause.draw()
        if settingsModal.active then
            settingsModal.draw()
        end
        debug.draw(player, network)
    end
end

function love.textinput(t)
    chat.textinput(t)
end

function love.keypressed(key)
    if settingsModal.active then
        if key == settings.PAUSE_TOGGLE_KEY then
            settingsModal.active = false
        else
            settingsModal.keypressed(key)
        end
    elseif not chat.keypressed(key) then
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
        end
    end
end

function love.keyreleased(key)
    if settingsModal.active then
        settingsModal.keyreleased(key)
    end
end

function love.wheelmoved(x, y)
    chat.wheelmoved(x, y)
end

function love.mousepressed(x, y, button)
    chat.mousepressed(x, y, button)
    if gameState == "menu" then
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
