-- scripts/main/main.lua

local settings = require("scripts.main.settings")
local debug = require("scripts.main.debug")
local player = require("scripts.player.player")
local world = require("scripts.world.world")
local camera = require("scripts.player.camera")
local menu = require("scripts.panels.menu")
local pause = require("scripts.panels.pause")
local network = require("scripts.network.network")

local gameState = "menu"  -- "menu", "waiting", "game", "pause"

local function startGame()
    network.connectToServer()
    gameState = "connecting"  -- Изменено с "waiting" на "connecting"
end

local function resetGame()
    world.load()
    player.load()
    camera.load()
end

function love.load()
    love.window.setMode(settings.WINDOW_WIDTH, settings.WINDOW_HEIGHT, {
        resizable = settings.WINDOW_RESIZABLE,
        minwidth = 800,
        minheight = 600
    })
    love.window.setTitle(settings.GAME_NAME)

    menu.load()
    pause.load()
    
    menu.startGame = startGame
    
    pause.resume = function()
        gameState = "game"
    end
    
    pause.quitToMenu = function()
        network.disconnect()
        gameState = "menu"
    end
end

function love.update(dt)
    local networkStatus = network.update()
    if networkStatus then
        print("Network status: " .. networkStatus)
        if networkStatus == "ID_RECEIVED" or networkStatus == "START" then
            if gameState ~= "game" then
                print("Game is starting")
                resetGame()
                gameState = "game"
            end
        end
    end

    if gameState == "game" then
        world.update(dt)
        player.update(dt)
        camera.update(dt)
    elseif gameState == "menu" then
        menu.update(dt)
    elseif gameState == "pause" then
        pause.update(dt)
        world.update(dt)
        player.update(dt)
        camera.update(dt)
    end
end

function love.draw()
    if gameState == "game" then
        camera.set()
        world.draw()
        player.draw()
        camera.unset()
        debug.draw(player, network)
        love.graphics.print("Network players: " .. tostring(#network.players), 10, love.graphics.getHeight() - 30)
    elseif gameState == "menu" then
        menu.draw()
    elseif gameState == "pause" then
        camera.set()
        world.draw()
        player.draw()
        camera.unset()
        pause.draw()
    end
end

function love.keypressed(key)
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

function love.mousepressed(x, y, button)
    if gameState == "menu" then
        menu.mousepressed(x, y, button)
    elseif gameState == "pause" then
        pause.mousepressed(x, y, button)
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