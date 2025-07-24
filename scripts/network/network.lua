-- scripts/network/network.lua

local socket = require("socket")
local settings = require("scripts.main.settings")

print("Socket module info:")
print("Socket version:", socket._VERSION or "unknown")
print("Socket type:", type(socket))
print("Socket.udp type:", type(socket.udp))

local network = {
    udp = nil,
    address = nil,
    port = nil,
    players = {},
    id = nil,
    lastUpdate = socket.gettime(),
    lastPingSent = 0,
    ping = nil,
    connected = false,
}

-- Создаём UDP сокет при инициализации
print("Creating UDP socket...")
network.udp = socket.udp()
if network.udp then
    print("UDP socket created successfully")
else
    print("Failed to create UDP socket")
end

function network.connectToServer(address, port)
    network.address = address
    network.port = port
    print("Setting up UDP socket...")
    
    -- Привязываем сокет к любому локальному порту
    local success, err = network.udp:setsockname("*", 0)
    if not success then
        print("Failed to bind socket:", err)
    else
        print("Socket bound successfully")
    end
    
    network.udp:settimeout(0)
    
    -- Пробуем отправить JOIN сообщение
    local success, err = network.udp:sendto("JOIN", network.address, network.port)
    if success then
        print("JOIN sent successfully")
    else
        print("Failed to send JOIN:", err)
    end
    
    network.connected = true
    print("Connecting to " .. address .. ":" .. port)
    print("UDP socket info:", network.udp)
end

function network.setPlayerColor(color)
    if network.id and network.players[network.id] then
        network.players[network.id].color = color
    end
end

function network.sendPlayerColor(color)
    if network.id then
        local message = string.format("COLOR:%d,%s", network.id, color)
        network.udp:sendto(message, network.address, network.port)
        print("Sent color change message:", message)
    end
end

function network.update()
    local currentTime = socket.gettime()

    if network.connected then
        if currentTime - network.lastPingSent >= 1 then
            network.udp:sendto("PING:" .. currentTime, network.address, network.port)
            network.lastPingSent = currentTime
        end

        local data, ip, port = network.udp:receivefrom()
        if data then
            print("Received data from server:", data, "from", ip, port)
            if data:sub(1, 5) == "PING:" then
                local pingTime = tonumber(data:sub(6))
                network.ping = (currentTime - pingTime) * 1000
                print("Ping response received:", network.ping .. "ms")
            elseif data:sub(1,3) == "ID:" then
                local id, color = data:match("ID:(%d+),(%w+)")
                network.id = tonumber(id)
                settings.playerColor = color
                network.players[network.id] = {x = 1568, y = 1568, color = color}
                print("Connected to server with ID: " .. network.id .. " and color: " .. color)
                return "ID_RECEIVED"
            elseif data:sub(1, 6) == "COLOR:" then
                local id, color = data:match("COLOR:(%d+),(%w+)")
                id = tonumber(id)
                if network.players[id] then
                    network.players[id].color = color
                    if id == network.id then
                        settings.playerColor = color
                    end
                end
            elseif data == "START" then
                print("START message received from server")
                return "START"
            else
                local newPlayers = {}
                for playerData in data:gmatch("[^;]+") do
                    local id, x, y, direction, state, currentFrame, color = playerData:match("(%d+),(%d+),(%d+),(%w+),(%w+),(%d+),(%w+)")
                    if id and x and y and direction and state and currentFrame and color then
                        id, x, y, currentFrame = tonumber(id), tonumber(x), tonumber(y), tonumber(currentFrame)
                        newPlayers[id] = {x = x, y = y, direction = direction, state = state, currentFrame = currentFrame, color = color}
                    else
                        print("Invalid player data received: " .. playerData)
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

    -- Обновление анимации для всех игроков
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
        network.udp:sendto(message, network.address, network.port)
    end
end

function network.disconnect()
    if network.id then
        network.udp:sendto("DISCONNECT:" .. network.id, network.address, network.port)
    end
    network.udp:close()
    network.id = nil
    network.players = {}
    network.connected = false
    print("Disconnected from server")
end

return network
