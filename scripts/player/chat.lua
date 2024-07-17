-- scripts/player/chat.lua

local settings = require("scripts.main.settings")
local network = require("scripts.network.network")
local debug = require("scripts.main.debug")

local chat = {
    messages = {},
    visible = true,
    hasFocus = false,
    isActive = false,
    isMouseOver = false,
    inputText = "",
    chatBoxWidth = 400,
    chatBoxHeight = 200,
    inputBoxWidth = 300,
    inputBoxHeight = 30,
    fontSize = 16,
    messageSpacing = 5,
    scrollOffset = 0,
    maxScrollOffset = 0,
    transparency = 0.3,
    font = nil
}

function chat.load()
    love.keyboard.setKeyRepeat(true)
    chat.font = love.graphics.newFont(chat.fontSize)
end

function chat.update(dt)
    local mx, my = love.mouse.getPosition()
    local chatBoxX = 10
    local chatBoxY = love.graphics.getHeight() - chat.chatBoxHeight - chat.inputBoxHeight - 20
    
    chat.isMouseOver = mx >= chatBoxX and mx <= chatBoxX + chat.chatBoxWidth and
                       my >= chatBoxY and my <= chatBoxY + chat.chatBoxHeight + chat.inputBoxHeight

    if chat.isMouseOver then
        chat.transparency = math.min(chat.transparency + dt * 2, 1)
    else
        chat.transparency = math.max(chat.transparency - dt * 2, 0.3)
    end

    chat.updateMaxScrollOffset()
end

local function trim(s)
    return s:match("^%s*(.-)%s*$")
end

function chat.wrapText(text, maxWidth)
    local font = love.graphics.getFont()
    local lines = {}
    
    local function addLine(line)
        table.insert(lines, line)
    end

    local function wrapLine(line)
        local words = {}
        for word in line:gmatch("%S+") do
            table.insert(words, word)
        end

        local currentLine = ""
        for i, word in ipairs(words) do
            local testLine = currentLine .. (currentLine == "" and "" or " ") .. word
            if font:getWidth(testLine) <= maxWidth then
                currentLine = testLine
            else
                if currentLine ~= "" then
                    addLine(currentLine)
                    currentLine = word
                else
                    local subWord = ""
                    for j = 1, #word do
                        local char = word:sub(j, j)
                        if font:getWidth(subWord .. char) > maxWidth then
                            addLine(subWord)
                            subWord = char
                        else
                            subWord = subWord .. char
                        end
                    end
                    currentLine = subWord
                end
            end
        end
        if currentLine ~= "" then
            addLine(currentLine)
        end
    end

    local colonIndex = text:find(":")
    if colonIndex then
        local prefix = text:sub(1, colonIndex)
        local message = trim(text:sub(colonIndex + 1))
        
        addLine(prefix)
        wrapLine(message)
    else
        wrapLine(text)
    end

    return lines
end

function chat.draw()
    love.graphics.setFont(chat.font)

    local chatBoxX = 10
    local chatBoxY = love.graphics.getHeight() - chat.chatBoxHeight - chat.inputBoxHeight - 20

    love.graphics.setColor(0, 0, 0, 0.5 * chat.transparency)
    love.graphics.rectangle("fill", chatBoxX, chatBoxY, chat.chatBoxWidth, chat.chatBoxHeight)

    love.graphics.setColor(1, 1, 1, chat.transparency)
    love.graphics.setScissor(chatBoxX, chatBoxY, chat.chatBoxWidth, chat.chatBoxHeight)

    local messageY = chatBoxY + chat.chatBoxHeight

    for i = 1, #chat.messages do
        local message = chat.messages[i]
        local wrappedLines = chat.wrapText(message, chat.chatBoxWidth - 20)
        local messageHeight = #wrappedLines * chat.fontSize + chat.messageSpacing

        if messageY - messageHeight + chat.scrollOffset >= chatBoxY then
            for j = #wrappedLines, 1, -1 do
                local line = wrappedLines[j]
                if debug.active and j == 1 then
                    local playerId = tonumber(line:match("Player (%d+):"))
                    if playerId then
                        local colorIndex = (playerId - 1) % #settings.playerColors + 1
                        local color = settings.playerColors[colorIndex]
                        love.graphics.setColor(color[1], color[2], color[3], 0.3)
                        love.graphics.rectangle("fill", chatBoxX, messageY - chat.fontSize + chat.scrollOffset, chat.chatBoxWidth, chat.fontSize)
                    end
                end
                love.graphics.setColor(1, 1, 1, chat.transparency)
                love.graphics.print(line, chatBoxX + 10, messageY - chat.fontSize + chat.scrollOffset)
                messageY = messageY - chat.fontSize
            end
            messageY = messageY - chat.messageSpacing
        else
            messageY = messageY - messageHeight
        end

        if messageY + chat.scrollOffset < chatBoxY then
            break
        end
    end

    love.graphics.setScissor()

    love.graphics.setColor(1, 1, 1, chat.transparency)
    love.graphics.rectangle("line", chatBoxX, chatBoxY + chat.chatBoxHeight + 10, chat.inputBoxWidth, chat.inputBoxHeight)

    local visibleText = chat.inputText
    local maxWidth = chat.inputBoxWidth - 20
    while love.graphics.getFont():getWidth(visibleText) > maxWidth do
        visibleText = visibleText:sub(2)
    end
    love.graphics.print(visibleText, chatBoxX + 10, chatBoxY + chat.chatBoxHeight + 15)

    love.graphics.setColor(0, 0.5, 1, chat.transparency)
    love.graphics.rectangle("fill", chatBoxX + chat.inputBoxWidth + 10, chatBoxY + chat.chatBoxHeight + 10, 80, chat.inputBoxHeight)
    love.graphics.setColor(1, 1, 1, chat.transparency)
    love.graphics.print("Send", chatBoxX + chat.inputBoxWidth + 30, chatBoxY + chat.chatBoxHeight + 15)
end

function chat.textinput(t)
    if chat.hasFocus then
        chat.inputText = chat.inputText .. t
    end
end

function chat.keypressed(key)
    if key == "return" then
        if chat.isActive then
            chat.sendMessage()
        end
        chat.isActive = not chat.isActive
        chat.hasFocus = chat.isActive
        return true
    elseif chat.isActive then
        if key == "backspace" then
            chat.inputText = chat.inputText:sub(1, -2)
            return true
        elseif key == "escape" then
            chat.isActive = false
            chat.hasFocus = false
            return true
        end
    end
    return false
end

function chat.mousepressed(x, y, button)
    if button == 1 then
        local chatBoxX = 10
        local chatBoxY = love.graphics.getHeight() - chat.chatBoxHeight - chat.inputBoxHeight - 20

        if x >= chatBoxX and x <= chatBoxX + chat.chatBoxWidth and
           y >= chatBoxY and y <= chatBoxY + chat.chatBoxHeight + chat.inputBoxHeight + 10 then
            chat.isActive = true
            chat.hasFocus = true
        else
            chat.isActive = false
            chat.hasFocus = false
        end

        if chat.isActive and x >= chatBoxX + chat.inputBoxWidth + 10 and x <= chatBoxX + chat.inputBoxWidth + 90 and
           y >= chatBoxY + chat.chatBoxHeight + 10 and y <= chatBoxY + chat.chatBoxHeight + 40 then
            chat.sendMessage()
        end
    end
end

function chat.wheelmoved(x, y)
    if chat.visible and chat.isMouseOver then
        chat.scrollOffset = math.max(0, math.min(chat.scrollOffset - y * 20, chat.maxScrollOffset))
    end
end

function chat.sendMessage()
    if chat.inputText ~= "" then
        local trimmedInput = chat.inputText:sub(1, 500)
        local message = "Player " .. network.id .. ": " .. trimmedInput
        network.sendChatMessage(message)
        chat.inputText = ""
        chat.scrollOffset = 0
    end
end

function chat.receiveMessage(message)
    table.insert(chat.messages, 1, message)
    if #chat.messages > 100 then
        table.remove(chat.messages)
    end
    chat.updateMaxScrollOffset()
    if chat.scrollOffset == 0 then
        chat.scrollOffset = chat.maxScrollOffset
    end
end

function chat.updateMaxScrollOffset()
    local totalHeight = 0
    for i = 1, #chat.messages do
        local message = chat.messages[i]
        local wrappedLines = chat.wrapText(message, chat.chatBoxWidth - 20)
        totalHeight = totalHeight + #wrappedLines * chat.fontSize + chat.messageSpacing
    end
    chat.maxScrollOffset = math.max(0, totalHeight - chat.chatBoxHeight)
end

return chat