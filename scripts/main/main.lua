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
    camera.load()
end

globalFont = nil

function love.load(dt)
    love.window.setMode(settings.WINDOW_WIDTH, settings.WINDOW_HEIGHT, {
        resizable = settings.WINDOW_RESIZABLE,
        minwidth = 800,
        minheight = 600
    })
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
        if networkStatus == "ID_RECEIVED" or networkStatus == "START" then
            if gameState ~= "game" then
                resetGame()
                gameState = "game"
            end
        end
    end

    if gameState == "game" then
        player.update(dt)
        camera.update(dt)
    elseif gameState == "menu" then
        menu.update(dt)
    elseif gameState == "pause" then
        player.update(dt)
        camera.update(dt)
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
        debug.draw(player, network, gameState)
    elseif gameState == "menu" then
        menu.draw()
    elseif gameState == "pause" then
        camera.set()
        world.draw()
        camera.unset()
        pause.draw()
        if settingsModal.active then
            settingsModal.draw()
        end
        if debug.isEnabled() then
            debug.draw(player, network, gameState)
        end
    end
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
        elseif gameState == "game" then
            input.keypressed(key)
        end
    end
end

function love.keyreleased(key)
    if settingsModal.active then
        settingsModal.keyreleased(key)
    end
end

function love.mousepressed(x, y, button)
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
