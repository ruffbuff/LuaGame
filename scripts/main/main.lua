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
local lobby = require("scripts.panels.lobby")

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
    love.mouse.setVisible(false)

    love.window.setTitle(settings.GAME_NAME)
    globalFont = love.graphics.newFont(settings.FONT_PATH, settings.FONT_SIZE)

    love.graphics.setFont(globalFont)
    lobby.load()
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
    local networkStatus, data = network.update()
    if networkStatus then
        print("Network status:", networkStatus)
        if networkStatus == "ID_RECEIVED" then
            gameState = "waiting"
        elseif networkStatus == "LOBBY_READY" then
            gameState = "lobby"
            lobby.playerCount = data
            print("Entered lobby with " .. data .. " players")
        elseif networkStatus == "LOBBY_UPDATE" then
            print("Received lobby update")
            print("Lobby timer:", network.lobbyTimer)
            lobby.updatePlayers(network.lobbyPlayers)
        elseif networkStatus == "GAME_START" then
            print("Received GAME_START signal, changing to game state")
            gameState = "game"
            resetGame()
            player.x = data.spawnX
            player.y = data.spawnY
        end
    end

    cursor.update()

    if gameState == "game" then
        local networkPlayer = network.players[network.id]
        if networkPlayer then
            player.update(dt, camera, networkPlayer)
            camera.update(dt, networkPlayer.x, networkPlayer.y, player.size)
        else
            print("Error: network.players[network.id] is nil")
        end
    elseif gameState == "menu" then
        menu.update(dt)
    elseif gameState == "waiting" then
    elseif gameState == "lobby" then
        lobby.update(dt)
    elseif gameState == "pause" then
        if network.id and network.players[network.id] then
            player.update(dt, camera)
            camera.update(dt, player.x, player.y, player.size)
        else
            print("Error: network.id or network.players[network.id] is nil")
        end
        pause.update(dt)
    end

    if settingsModal.active then
        settingsModal.update(dt)
    end
end

function love.draw()
    love.graphics.setFont(globalFont)
    if gameState == "waiting" then
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Waiting for players...", 0, love.graphics.getHeight() / 2, love.graphics.getWidth(), "center")
    elseif gameState == "lobby" then
        lobby.draw()
    elseif gameState == "game" then
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
        
        local player = network.players[network.id]
        if not clickedOnPlayer and player and settings.MOVEMENT_TYPE == "mouse" and button == 1 then
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
