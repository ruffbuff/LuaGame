-- server.lua

local socket = require('socket')

local settings = {
    playerColors = {"red", "blue", "green", "yellow", "purple"},
    playerColorOrder = {"red", "blue", "green", "yellow", "purple"},
    WORLD_WIDTH = 3200,
    WORLD_HEIGHT = 1800,
    TILE_SIZE = 64
}

local server = {
    udp = socket.udp(),
    clients = {},
    gameStarted = false,
    lastUpdate = socket.gettime(),
    chatMessages = {},
    lobbyTimer = 60,
    lobbyTimerLastUpdate = 0
}

math.randomseed(os.time())

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
            server.clients[id] = {
                ip = msg_or_ip,
                port = port_or_nil,
                x = 1568,
                y = 1568,
                lastUpdate = currentTime,
                color = {},
                colorName = nil
            }
            server.udp:sendto("ID:" .. id, msg_or_ip, port_or_nil)
            print("New client connected with ID: " .. id)

            if #server.clients >= 2 and not server.gameStarted then
                server.startLobby()
            end
        elseif data:sub(1, 11) == "DISCONNECT:" then
            local id = tonumber(data:sub(12))
            if server.clients[id] then
                server.clients[id] = nil
                print("Client " .. id .. " disconnected")
            end
        elseif data == "PLAYER_READY" then
            print("Player ready")
        else
            local id, x, y, direction, state, currentFrame = data:match("(%d+),(%d+),(%d+),(%w+),(%w+),(%d+)")
            id, x, y, currentFrame = tonumber(id), tonumber(x), tonumber(y), tonumber(currentFrame)
            if server.clients[id] then
                server.clients[id].x, server.clients[id].y = x, y
                server.clients[id].direction = direction
                server.clients[id].state = state
                server.clients[id].currentFrame = currentFrame
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

    if server.gameStarted and not server.gameInProgress then
        if currentTime - server.lobbyTimerLastUpdate >= 1 then
            server.lobbyTimer = server.lobbyTimer - 1
            server.lobbyTimerLastUpdate = currentTime
        end
        if server.lobbyTimer <= 0 and not server.gameInProgress then
            server.startGame()
        end
    end

    if currentTime - server.lastUpdate >= 1/20 then
        local allData = ""
        for id, client in pairs(server.clients) do
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
                client.colorName or "none"
            )
        end
        for _, client in pairs(server.clients) do
            server.udp:sendto(allData, client.ip, client.port)
        end
        server.lastUpdate = currentTime
    end
end

function server.startLobby()
    print("Starting lobby with " .. #server.clients .. " players")
    server.gameStarted = true
    server.gameInProgress = false
    server.lobbyTimer = 30

    local colors = {"red", "blue"}
    math.randomseed(os.time())
    local randomIndex = math.random(1, 2)
    
    for id, client in pairs(server.clients) do
        client.colorName = colors[randomIndex]
        randomIndex = 3 - randomIndex
    end

    for _, client in pairs(server.clients) do
        server.udp:sendto("LOBBY_READY:" .. #server.clients, client.ip, client.port)
    end
    server.broadcastLobbyUpdate()
end

function server.broadcastLobbyUpdate()
    local lobbyData = "LOBBY_UPDATE:" .. server.lobbyTimer .. ":"
    for id, client in pairs(server.clients) do
        lobbyData = lobbyData .. id .. "," .. (client.colorName or "none") .. ";"
    end
    lobbyData = lobbyData:sub(1, -2)
    for _, client in pairs(server.clients) do
        server.udp:sendto(lobbyData, client.ip, client.port)
    end
    print("Broadcasted lobby update:", lobbyData)
end

function server.startGame()
    server.gameInProgress = true
    local leftSide = true
    for _, client in pairs(server.clients) do
        server.udp:sendto("START", client.ip, client.port)
    end
    for id, client in pairs(server.clients) do
        local spawnX = leftSide and 2 * settings.TILE_SIZE or ((settings.WORLD_WIDTH - 2) * settings.TILE_SIZE)
        local spawnY = (settings.WORLD_HEIGHT / 2) * settings.TILE_SIZE
        client.x = spawnX
        client.y = spawnY
        server.udp:sendto("GAME_START:" .. spawnX .. "," .. spawnY, client.ip, client.port)
        leftSide = not leftSide
    end
end

function server.quit()
    server.clients = {}
end

server.start()

while true do
    server.update()
    socket.sleep(1/60)
end