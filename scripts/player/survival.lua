-- scripts/player/survival.lua

local survival = {
    health = 100,
    maxHealth = 100,
    hunger = 100,
    maxHunger = 100,
    thirst = 100,
    maxThirst = 100,
    
    -- Скорости изменения (в секунду)
    hungerDecayRate = 0.5,    -- голод падает на 0.5 в секунду
    thirstDecayRate = 0.8,    -- жажда падает быстрее
    healthRegenRate = 2,      -- восстановление здоровья при сытости
    
    -- Пороговые значения
    healthDamageThreshold = 20,  -- при голоде <20 теряем здоровье
    slowdownThreshold = 30,      -- при голоде <30 замедляемся
    
    lastHealthDamage = 0,
    healthDamageInterval = 2,    -- урон каждые 2 секунды
}

function survival.load()
    survival.health = survival.maxHealth
    survival.hunger = survival.maxHunger  
    survival.thirst = survival.maxThirst
end

function survival.update(dt)
    -- Уменьшаем голод и жажду со временем
    survival.hunger = math.max(0, survival.hunger - survival.hungerDecayRate * dt)
    survival.thirst = math.max(0, survival.thirst - survival.thirstDecayRate * dt)
    
    -- Если сыт и не испытываем жажду - восстанавливаем здоровье
    if survival.hunger > 50 and survival.thirst > 50 and survival.health < survival.maxHealth then
        survival.health = math.min(survival.maxHealth, survival.health + survival.healthRegenRate * dt)
    end
    
    -- Урон от голода/жажды
    local currentTime = love.timer.getTime()
    if (survival.hunger < survival.healthDamageThreshold or survival.thirst < survival.healthDamageThreshold) then
        if currentTime - survival.lastHealthDamage >= survival.healthDamageInterval then
            survival.health = math.max(0, survival.health - 5)
            survival.lastHealthDamage = currentTime
            print("Теряешь здоровье от голода/жажды! Здоровье: " .. math.floor(survival.health))
        end
    end
end

function survival.eat(foodValue)
    survival.hunger = math.min(survival.maxHunger, survival.hunger + foodValue)
    print("Поел! Сытость: " .. math.floor(survival.hunger))
end

function survival.drink(drinkValue)
    survival.thirst = math.min(survival.maxThirst, survival.thirst + drinkValue)
    print("Попил! Жажда утолена: " .. math.floor(survival.thirst))
end

function survival.takeDamage(damage)
    survival.health = math.max(0, survival.health - damage)
    if survival.health <= 0 then
        print("Ты умер! Respawn...")
        survival.respawn()
    end
end

function survival.respawn()
    survival.health = survival.maxHealth
    survival.hunger = survival.maxHunger * 0.5  -- респаун с половинной сытостью
    survival.thirst = survival.maxThirst * 0.5
    -- TODO: телепорт к spawn point
end

function survival.getSpeedMultiplier()
    -- Замедление при низком голоде/жажде
    if survival.hunger < survival.slowdownThreshold or survival.thirst < survival.slowdownThreshold then
        return 0.6  -- 60% от обычной скорости
    end
    return 1.0
end

function survival.drawUI()
    local screenWidth = love.graphics.getWidth()
    
    -- Фон для UI
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 10, 10, 400, 80)
    
    -- Здоровье (красный)
    love.graphics.setColor(0.8, 0.2, 0.2, 1)
    love.graphics.rectangle("fill", 20, 20, (survival.health / survival.maxHealth) * 200, 15)
    love.graphics.setColor(0.3, 0.1, 0.1, 1)
    love.graphics.rectangle("line", 20, 20, 200, 15)
    
    -- Голод (оранжевый)
    love.graphics.setColor(0.8, 0.6, 0.2, 1)  
    love.graphics.rectangle("fill", 20, 40, (survival.hunger / survival.maxHunger) * 200, 15)
    love.graphics.setColor(0.3, 0.2, 0.1, 1)
    love.graphics.rectangle("line", 20, 40, 200, 15)
    
    -- Жажда (синий)
    love.graphics.setColor(0.2, 0.6, 0.8, 1)
    love.graphics.rectangle("fill", 20, 60, (survival.thirst / survival.maxThirst) * 200, 15)
    love.graphics.setColor(0.1, 0.2, 0.3, 1)
    love.graphics.rectangle("line", 20, 60, 200, 15)
    
    -- Текст
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Health: " .. math.floor(survival.health), 230, 20)
    love.graphics.print("Food: " .. math.floor(survival.hunger), 230, 40)  
    love.graphics.print("Water: " .. math.floor(survival.thirst), 230, 60)
    
    -- Предупреждения
    if survival.hunger < survival.slowdownThreshold then
        love.graphics.setColor(1, 1, 0, 1)
        love.graphics.print("ГОЛОДЕН!", screenWidth/2 - 50, 100)
    end
    if survival.thirst < survival.slowdownThreshold then
        love.graphics.setColor(0, 1, 1, 1)  
        love.graphics.print("ЖАЖДА!", screenWidth/2 - 40, 120)
    end
    
    -- Подсказки по строительству
    local screenHeight = love.graphics.getHeight()
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    love.graphics.print("TAB - Инвентарь", 10, screenHeight - 40)
    love.graphics.print("1 - Костёр (3 wood) | 2 - Стена (2 stone) | 3 - Грядка (1 wood, 1 stone)", 10, screenHeight - 20)
end

return survival