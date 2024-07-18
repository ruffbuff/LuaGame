-- scripts/utils/eventManager.lua

local eventManager = {}
local listeners = {}

function eventManager.addListener(eventName, listener)
    if not listeners[eventName] then
        listeners[eventName] = {}
    end
    table.insert(listeners[eventName], listener)
end

function eventManager.removeListener(eventName, listener)
    if listeners[eventName] then
        for i, l in ipairs(listeners[eventName]) do
            if l == listener then
                table.remove(listeners[eventName], i)
                break
            end
        end
    end
end

function eventManager.triggerEvent(eventName, ...)
    if listeners[eventName] then
        for _, listener in ipairs(listeners[eventName]) do
            listener(...)
        end
    end
end

return eventManager