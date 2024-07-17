local socket = require('socket')

local server = {
    udp = socket.udp(),
    clients = {},
    gameStarted = true,
    lastUpdate = socket.gettime(),
    chatMessages = {}  -- Добавлено для хранения сообщений чата
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
            server.clients[id] = {ip = msg_or_ip, port = port_or_nil, x = 1568, y = 1568, lastUpdate = currentTime}
            server.udp:sendto("ID:" .. id, msg_or_ip, port_or_nil)
            server.udp:sendto("START", msg_or_ip, port_or_nil)
            print("New client connected with ID: " .. id)

            -- Отправляем историю чата новому игроку
            for _, message in ipairs(server.chatMessages) do
                server.udp:sendto("CHAT:" .. message, msg_or_ip, port_or_nil)
            end
        elseif data:sub(1, 11) == "DISCONNECT:" then
            local id = tonumber(data:sub(12))
            if server.clients[id] then
                server.clients[id] = nil
                print("Client " .. id .. " disconnected")
            end
        elseif data:sub(1, 5) == "CHAT:" then
            local message = data:sub(6)
            table.insert(server.chatMessages, message)  -- Сохраняем сообщение
            for id, client in pairs(server.clients) do
                server.udp:sendto("CHAT:" .. message, client.ip, client.port)
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
        local allPositions = ""
        for id, client in pairs(server.clients) do
            if allPositions ~= "" then
                allPositions = allPositions .. ";"
            end
            allPositions = allPositions .. id .. "," .. math.floor(client.x) .. "," .. math.floor(client.y)
        end
        for id, client in pairs(server.clients) do
            server.udp:sendto(allPositions, client.ip, client.port)
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
