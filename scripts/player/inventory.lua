-- scripts/player/inventory.lua

local inventory = {
    items = {},  -- {type = "wood", count = 5}
    maxSlots = 20,
    isOpen = false
}

function inventory.add(itemType, count)
    count = count or 1
    
    -- Ищем существующий стак
    for _, item in ipairs(inventory.items) do
        if item.type == itemType then
            item.count = item.count + count
            return true
        end
    end
    
    -- Создаём новый стак если есть место
    if #inventory.items < inventory.maxSlots then
        table.insert(inventory.items, {type = itemType, count = count})
        return true
    end
    
    return false  -- нет места
end

function inventory.remove(itemType, count)
    count = count or 1
    
    for i, item in ipairs(inventory.items) do
        if item.type == itemType then
            if item.count >= count then
                item.count = item.count - count
                if item.count <= 0 then
                    table.remove(inventory.items, i)
                end
                return true
            end
        end
    end
    
    return false  -- недостаточно предметов
end

function inventory.getCount(itemType)
    for _, item in ipairs(inventory.items) do
        if item.type == itemType then
            return item.count
        end
    end
    return 0
end

function inventory.has(itemType, count)
    count = count or 1
    return inventory.getCount(itemType) >= count
end

function inventory.toggle()
    inventory.isOpen = not inventory.isOpen
end

function inventory.drawUI()
    if not inventory.isOpen then return end
    
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Фон инвентаря
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", screenWidth/2 - 200, screenHeight/2 - 150, 400, 300)
    
    -- Заголовок
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Inventory", screenWidth/2 - 40, screenHeight/2 - 140)
    
    -- Отображаем предметы
    local startX = screenWidth/2 - 180
    local startY = screenHeight/2 - 100
    
    for i, item in ipairs(inventory.items) do
        local x = startX + ((i-1) % 8) * 40
        local y = startY + math.floor((i-1) / 8) * 40
        
        -- Слот
        love.graphics.setColor(0.3, 0.3, 0.3, 1)
        love.graphics.rectangle("fill", x, y, 35, 35)
        love.graphics.setColor(0.6, 0.6, 0.6, 1)
        love.graphics.rectangle("line", x, y, 35, 35)
        
        -- Предмет (используем цвета из resources)
        local resources = require("scripts.world.resources")
        local itemData = resources.types[item.type]
        if itemData then
            love.graphics.setColor(itemData.color[1], itemData.color[2], itemData.color[3], 1)
            love.graphics.rectangle("fill", x + 5, y + 5, 25, 25)
        end
        
        -- Количество
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(item.count, x + 2, y + 20)
    end
    
    -- Инструкция
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.print("Press TAB to close", screenWidth/2 - 70, screenHeight/2 + 120)
end

return inventory