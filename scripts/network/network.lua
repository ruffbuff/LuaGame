-- scripts/network/network.lua

local socket = require("socket")
local settings = require("scripts.main.settings")

local network = {
    udp = socket.udp(),
    address = nil,
    port = nil,
    players = {},
    id = nil,
    lastUpdate = socket.gettime(),
    lastPingSent = 0,
    ping = nil,
    connected = false,
    lobbyPlayers = {},
    lobbyReady = false
}

function network.connectToServer(address, port)
    network.address = address
    network.port = port
    local success, err = network.udp:setpeername(network.address, network.port)
    if not success then
        print("Failed to connect to server:", err)
        return false
    end
    network.udp:settimeout(0)
    network.udp:send("JOIN")
    network.connected = true
    return true
end

function network.update()
    local currentTime = socket.gettime()

    if network.connected then
        if currentTime - network.lastPingSent >= 1 then
            network.udp:send("PING:" .. currentTime)
            network.lastPingSent = currentTime
        end

        local data = network.udp:receive()
        if data then
            if data:sub(1, 5) == "PING:" then
                local pingTime = tonumber(data:sub(6))
                network.ping = (currentTime - pingTime) * 1000
            elseif data:sub(1,3) == "ID:" then
                local id = data:match("ID:(%d+)")
                if id then
                    network.id = tonumber(id)
                    network.players[network.id] = {x = 1568, y = 1568}
                    print("Connected to server with ID: " .. network.id)
                    return "ID_RECEIVED"
                end
            elseif data:sub(1, 12) == "LOBBY_READY:" then
                local playerCount = tonumber(data:sub(13))
                network.lobbyReady = true
                return "LOBBY_READY", playerCount
            elseif data:sub(1, 12) == "LOBBY_UPDATE:" then
                local lobbyTimer, playersData = data:match("LOBBY_UPDATE:(%d+):(.+)")
                network.lobbyTimer = tonumber(lobbyTimer)
                network.lobbyPlayers = {}
                for playerData in playersData:gmatch("[^;]+") do
                    local id, colorName = playerData:match("(%d+),(%w+)")
                    id = tonumber(id)
                    if id and colorName then
                        network.lobbyPlayers[id] = {colorName = colorName}
                        if id == network.id then
                            network.players[network.id].colorName = colorName
                        end
                    end
                end
                return "LOBBY_UPDATE"
            elseif data:sub(1, 11) == "GAME_START:" then
                local spawnX, spawnY = data:match("GAME_START:(%d+),(%d+)")
                spawnX, spawnY = tonumber(spawnX), tonumber(spawnY)
                if network.players[network.id] then
                    network.players[network.id].x = spawnX
                    network.players[network.id].y = spawnY
                end
                return "GAME_START", {spawnX = spawnX, spawnY = spawnY}
            elseif data == "START" then
                print("Received START signal from server")
                return "START"
            else
                local newPlayers = {}
                for playerData in data:gmatch("[^;]+") do
                    local id, x, y, direction, state, currentFrame, colorName = playerData:match("(%d+),(%d+),(%d+),(%w+),(%w+),(%d+),(%w+)")
                    if id and x and y and direction and state and currentFrame and colorName then
                        id, x, y, currentFrame = tonumber(id), tonumber(x), tonumber(y), tonumber(currentFrame)
                        newPlayers[id] = {x = x, y = y, direction = direction, state = state, currentFrame = currentFrame, colorName = colorName}
                    end
                end
                network.players = newPlayers
            end
        end

        if network.id and network.players[network.id] then
            if currentTime - network.lastUpdate >= 1/20 then
                local player = network.players[network.id]
                network.sendPosition(
                    player.x, 
                    player.y, 
                    player.direction, 
                    player.state, 
                    player.currentFrame
                )
                network.lastUpdate = currentTime
            end
        end
    end

    for id, p in pairs(network.players) do
        if p.state ~= "idle" then
            p.animationTimer = (p.animationTimer or 0) + love.timer.getDelta()
            local animationSpeed = (p.state == "run") and 0.1 or 0.2
            if p.animationTimer >= animationSpeed then
                p.animationTimer = p.animationTimer - animationSpeed
                p.currentFrame = (p.currentFrame or 1) % 4 + 1
            end
        else
            p.currentFrame = 1
        end
    end

    return nil
end

function network.sendPosition(x, y, direction, state, currentFrame)
    if network.id then
        direction = direction or "down" 
        state = state or "idle"         
        currentFrame = currentFrame or 1
        
        local message = string.format("%d,%d,%d,%s,%s,%d", 
            network.id, 
            math.floor(x), 
            math.floor(y), 
            direction, 
            state, 
            currentFrame
        )
        network.udp:send(message)
    end
end

function network.disconnect()
    if network.id then
        network.udp:send("DISCONNECT:" .. network.id)
    end
    network.udp:close()
    network.id = nil
    network.players = {}
    network.connected = false
    print("Disconnected from server")
end

function network.sendReadyStatus()
    if network.connected then
        network.udp:send("PLAYER_READY")
    end
end

return network
