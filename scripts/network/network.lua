-- scripts/network/network.lua

local socket = require("socket")

local network = {
    udp = socket.udp(),
    address = "localhost",
    port = 12345,
    players = {},
    id = nil,
    lastUpdate = socket.gettime()
}

function network.connectToServer()
    network.udp:setpeername(network.address, network.port)
    network.udp:settimeout(0)
    network.udp:send("JOIN")
    print("Attempting to connect to server...")
end

function network.update()
    local currentTime = socket.gettime()
    local data = network.udp:receive()
    if data then
        if data:sub(1,3) == "ID:" then
            network.id = tonumber(data:sub(4))
            network.players[network.id] = {x = 1568, y = 1568}
            print("Received ID: " .. network.id)
            return "ID_RECEIVED"
        elseif data == "START" then
            print("Received START signal")
            return "START"
        else
            local newPlayers = {}
            for playerData in data:gmatch("[^;]+") do
                local id, x, y = playerData:match("(%d+),(%d+),(%d+)")
                if id and x and y then
                    id, x, y = tonumber(id), tonumber(x), tonumber(y)
                    newPlayers[id] = {x = x, y = y}
                else
                    print("Invalid player data received: " .. playerData)
                end
            end
            network.players = newPlayers
        end
    end

    if network.id and network.players[network.id] then
        if currentTime - network.lastUpdate >= 1/20 then
            network.sendPosition(network.players[network.id].x, network.players[network.id].y)
            network.lastUpdate = currentTime
        end
    end

    return nil
end

function network.sendPosition(x, y)
    if network.id then
        local message = string.format("%d,%d,%d", network.id, math.floor(x), math.floor(y))
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
    print("Disconnected from server")
end

return network