-- love-server.lua - LÖVE2D сервер

local socket = require('socket')

local settings = {
    playerColors = {"red", "blue", "green", "yellow", "purple"}
}

local server = {
    udp = socket.udp(),
    clients = {},
    gameStarted = true,
    lastUpdate = socket.gettime(),
    chatMessages = {}
}

function love.load()
    server.udp:setsockname('*', 12345)
    server.udp:settimeout(0)
    print("LÖVE2D Server started on *:12345")
end

function love.update(dt)
    local currentTime = socket.gettime()
    local data, msg_or_ip, port_or_nil = server.udp:receivefrom()
    
    if data then
        print("Server received data:", data, "from", msg_or_ip, port_or_nil)
        
        if data:sub(1, 5) == "PING:" then
            server.udp:sendto(data, msg_or_ip, port_or_nil)
            print("Ping response sent to", msg_or_ip, port_or_nil)
        elseif data == "JOIN" then
            local id = #server.clients + 1
            local colorIndex = (id - 1) % #settings.playerColors + 1
            local color = settings.playerColors[colorIndex]
            server.clients[id] = {ip = msg_or_ip, port = port_or_nil, x = 1568, y = 1568, lastUpdate = currentTime, color = color}
            
            server.udp:sendto("ID:" .. id .. "," .. color, msg_or_ip, port_or_nil)
            server.udp:sendto("START", msg_or_ip, port_or_nil)
            print("New client connected with ID: " .. id .. " color: " .. color)

            -- Отправляем информацию о других игроках новому клиенту
            for clientId, client in pairs(server.clients) do
                if clientId ~= id then
                    server.udp:sendto("COLOR:" .. clientId .. "," .. client.color, msg_or_ip, port_or_nil)
                end
            end
        elseif data:sub(1, 11) == "DISCONNECT:" then
            local id = tonumber(data:sub(12))
            if server.clients[id] then
                server.clients[id] = nil
                print("Client " .. id .. " disconnected")
            end
        elseif data:sub(1, 6) == "COLOR:" then
            local id, color = data:match("COLOR:(%d+),(%w+)")
            id = tonumber(id)
            if server.clients[id] then
                server.clients[id].color = color
                print("Client " .. id .. " changed color to " .. color)
                -- Рассылаем изменение цвета всем клиентам
                for clientId, client in pairs(server.clients) do
                    server.udp:sendto("COLOR:" .. id .. "," .. color, client.ip, client.port)
                end
            else
                print("Received color change for unknown client ID:", id)
            end
        else
            -- Обработка позиции игрока
            local id, x, y, direction, state, currentFrame = data:match("(%d+),(%d+),(%d+),(%w+),(%w+),(%d+)")
            id, x, y, currentFrame = tonumber(id), tonumber(x), tonumber(y), tonumber(currentFrame)
            if server.clients[id] then
                server.clients[id].x, server.clients[id].y = x, y
                server.clients[id].direction = direction
                server.clients[id].state = state
                server.clients[id].currentFrame = currentFrame
                server.clients[id].lastUpdate = currentTime
            else
                local clientIds = {}
                for k in pairs(server.clients) do 
                    table.insert(clientIds, tostring(k)) 
                end
                print("Received position data for unknown client ID:", id, "Available clients:", table.concat(clientIds, ", "))
            end
        end
    end

    -- Удаляем отключившихся клиентов
    for id, client in pairs(server.clients) do
        if currentTime - client.lastUpdate > 5 then
            server.clients[id] = nil
            print("Client " .. id .. " timed out (last update:", currentTime - client.lastUpdate, "seconds ago)")
        end
    end

    -- Рассылаем позиции всех игроков (20 FPS)
    if currentTime - server.lastUpdate >= 1/20 then
        local allData = ""
        local clientCount = 0
        for id, client in pairs(server.clients) do
            clientCount = clientCount + 1
            if allData ~= "" then
                allData = allData .. ";"
            end
            allData = allData .. string.format("%d,%d,%d,%s,%s,%d,%s",
                id, 
                math.floor(client.x), 
                math.floor(client.y),
                client.direction or "down", 
                client.state or "idle", 
                client.currentFrame or 1,
                client.color or "red"
            )
        end
        
        -- Отправляем данные всем подключенным клиентам
        if allData ~= "" then
            print("Sending to", clientCount, "clients:", allData)
            for _, client in pairs(server.clients) do
                server.udp:sendto(allData, client.ip, client.port)
            end
        end
        server.lastUpdate = currentTime
    end
end

function love.draw()
    love.graphics.print("LÖVE2D Server running on port 12345", 10, 10)
    love.graphics.print("Connected clients: " .. #server.clients, 10, 30)
    
    local y = 50
    for id, client in pairs(server.clients) do
        love.graphics.print("Client " .. id .. ": " .. client.color .. " at (" .. client.x .. ", " .. client.y .. ")", 10, y)
        y = y + 20
    end
end

function love.quit()
    server.clients = {}
    if server.udp then
        server.udp:close()
    end
end