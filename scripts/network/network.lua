-- scripts/network/network.lua

local socket = require("socket")
local settings = require("scripts.main.settings")
local eventManager = require("scripts.utils.eventManager")

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
    chatCallback = nil
}

function network.connectToServer(address, port)
    network.address = address
    network.port = port
    network.udp:setpeername(network.address, network.port)
    network.udp:settimeout(0)
    network.udp:send("JOIN")
    network.connected = true
    print("Connecting to " .. address .. ":" .. port)
end

function network.setPlayerColor(color)
    if network.id and network.players[network.id] then
        network.players[network.id].color = color
    end
end

function network.sendPlayerColor(color)
    if network.id then
        local message = string.format("COLOR:%d,%f,%f,%f", network.id, color[1], color[2], color[3])
        network.udp:send(message)
        print("Sent color change message:", message)
    end
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
                local id, r, g, b = data:match("ID:(%d+),([%d%.]+),([%d%.]+),([%d%.]+)")
                network.id = tonumber(id)
                settings.playerColor = {tonumber(r), tonumber(g), tonumber(b)}
                network.players[network.id] = {x = 1568, y = 1568}
                print("Connected to server with ID: " .. network.id)
                eventManager.triggerEvent("playerSpawned", network.id)
                return "ID_RECEIVED"
            elseif data:sub(1, 6) == "SPAWN:" then
                local id = tonumber(data:sub(7))
                if network.players[id] then
                    eventManager.triggerEvent("otherPlayerSpawned", id)
                end
            elseif data:sub(1, 6) == "COLOR:" then
                local id, r, g, b = data:match("COLOR:(%d+),([%d%.]+),([%d%.]+),([%d%.]+)")
                id, r, g, b = tonumber(id), tonumber(r), tonumber(g), tonumber(b)
                if network.players[id] then
                    network.players[id].color = {r, g, b}
                    if id == network.id then
                        settings.playerColor = {r, g, b}
                    end
                end
            elseif data == "START" then
                return "START"
            elseif data:sub(1, 5) == "CHAT:" then
                local message = data:sub(6)
                if network.chatCallback then
                    network.chatCallback(message)
                end
            else
                local newPlayers = {}
                for playerData in data:gmatch("[^;]+") do
                    local id, x, y, r, g, b = playerData:match("(%d+),(%d+),(%d+),([%d%.]+),([%d%.]+),([%d%.]+)")
                    if id and x and y and r and g and b then
                        id, x, y, r, g, b = tonumber(id), tonumber(x), tonumber(y), tonumber(r), tonumber(g), tonumber(b)
                        newPlayers[id] = {x = x, y = y, color = {r, g, b}}
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
    end

    return nil
end

function network.sendSpawnEffect()
    if network.id then
        network.udp:send("SPAWN:" .. network.id)
    end
end

function network.sendPosition(x, y)
    if network.id then
        local message = string.format("%d,%d,%d", network.id, math.floor(x), math.floor(y))
        network.udp:send(message)
    end
end

function network.sendChatMessage(message)
    if network.id then
        network.udp:send("CHAT:" .. message)
    end
end

function network.setChatCallback(callback)
    network.chatCallback = callback
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

return network
