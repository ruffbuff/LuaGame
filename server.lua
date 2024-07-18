local socket = require('socket')

local settings = {
    playerColors = {
        {1, 0, 0},
        {0, 0, 1},
        {0, 1, 0},
        {1, 1, 0},
        {1, 0, 1},
    }
}

local server = {
    udp = socket.udp(),
    clients = {},
    gameStarted = true,
    lastUpdate = socket.gettime(),
    chatMessages = {}
}

function server.start()
    server.udp:setsockname('*', 12345)
    server.udp:settimeout(0)
    print("Server started on *:12345")
end

function server.update()
    local currentTime = socket.gettime()
    local data, msg_or_ip, port_or_nil = server.udp:receivefrom()
    if data then
        if data:sub(1, 5) == "PING:" then
            server.udp:sendto(data, msg_or_ip, port_or_nil)
        elseif data == "JOIN" then
            local id = #server.clients + 1
            local colorIndex = (id - 1) % #settings.playerColors + 1
            local color = settings.playerColors[colorIndex]
            server.clients[id] = {ip = msg_or_ip, port = port_or_nil, x = 1568, y = 1568, lastUpdate = currentTime, color = color}
            server.udp:sendto("ID:" .. id .. "," .. color[1] .. "," .. color[2] .. "," .. color[3], msg_or_ip, port_or_nil)
            server.udp:sendto("START", msg_or_ip, port_or_nil)
            print("New client connected with ID: " .. id)

            for clientId, client in pairs(server.clients) do
                if clientId ~= id then
                    server.udp:sendto("COLOR:" .. clientId .. "," .. client.color[1] .. "," .. client.color[2] .. "," .. client.color[3], msg_or_ip, port_or_nil)
                end
            end

            for _, message in ipairs(server.chatMessages) do
                server.udp:sendto("CHAT:" .. message, msg_or_ip, port_or_nil)
            end

            for _, client in pairs(server.clients) do
                server.udp:sendto("SPAWN:" .. id, client.ip, client.port)
            end
        elseif data:sub(1, 6) == "SPAWN:" then
            local spawnId = tonumber(data:sub(7))
            for _, client in pairs(server.clients) do
                server.udp:sendto(data, client.ip, client.port)
            end
        elseif data:sub(1, 11) == "DISCONNECT:" then
            local id = tonumber(data:sub(12))
            if server.clients[id] then
                server.clients[id] = nil
                print("Client " .. id .. " disconnected")
            end
        elseif data:sub(1, 5) == "CHAT:" then
            local message = data:sub(6)
            table.insert(server.chatMessages, message)
            for id, client in pairs(server.clients) do
                server.udp:sendto("CHAT:" .. message, client.ip, client.port)
            end
        elseif data:sub(1, 6) == "COLOR:" then
            local id, r, g, b = data:match("COLOR:(%d+),([%d%.]+),([%d%.]+),([%d%.]+)")
            id, r, g, b = tonumber(id), tonumber(r), tonumber(g), tonumber(b)
            if server.clients[id] then
                server.clients[id].color = {r, g, b}
                print("Client " .. id .. " changed color to {" .. r .. ", " .. g .. ", " .. b .. "}")
                for clientId, client in pairs(server.clients) do
                    server.udp:sendto("COLOR:" .. id .. "," .. r .. "," .. g .. "," .. b, client.ip, client.port)
                end
            else
                print("Received color change for unknown client ID:", id)
            end
        else
            local id, x, y = data:match("(%d+),(%d+),(%d+)")
            id, x, y = tonumber(id), tonumber(x), tonumber(y)
            if server.clients[id] then
                server.clients[id].x, server.clients[id].y = x, y
                server.clients[id].lastUpdate = currentTime
            end
        end
    end

    for id, client in pairs(server.clients) do
        if currentTime - client.lastUpdate > 5 then
            server.clients[id] = nil
            print("Client " .. id .. " timed out")
        end
    end

    if currentTime - server.lastUpdate >= 1/20 then
        local allData = ""
        for id, client in pairs(server.clients) do
            if allData ~= "" then
                allData = allData .. ";"
            end
            allData = allData .. id .. "," .. math.floor(client.x) .. "," .. math.floor(client.y) .. "," .. client.color[1] .. "," .. client.color[2] .. "," .. client.color[3]
        end
        for id, client in pairs(server.clients) do
            server.udp:sendto(allData, client.ip, client.port)
        end
        server.lastUpdate = currentTime
    end
end

function server.quit()
    server.clients = {}
    server.chatMessages = {}
end

server.start()

while true do
    server.update()
    socket.sleep(1/60)
end