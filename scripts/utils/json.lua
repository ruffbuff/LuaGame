-- scripts/utils/json.lua

local json = {}

function json.encode(data)
    local t = type(data)
    if t == 'string' then
        return '"' .. data:gsub('"', '\\"') .. '"'
    elseif t == 'number' or t == 'boolean' or t == 'nil' then
        return tostring(data)
    elseif t == 'table' then
        local parts = {}
        local is_array = #data > 0
        for k, v in pairs(data) do
            if is_array then
                table.insert(parts, json.encode(v))
            else
                table.insert(parts, json.encode(k) .. ':' .. json.encode(v))
            end
        end
        if is_array then
            return '[' .. table.concat(parts, ',') .. ']'
        else
            return '{' .. table.concat(parts, ',') .. '}'
        end
    else
        error("Cannot encode " .. t .. " to JSON")
    end
end

function json.decode(str)
    local index = 1

    local function skipWhitespace()
        index = str:find("%S", index) or #str + 1
    end

    local parseValue

    local function parseString()
        local value = ""
        index = index + 1
        while index <= #str do
            local char = str:sub(index, index)
            if char == '"' then
                index = index + 1
                return value
            elseif char == '\\' then
                index = index + 1
                char = str:sub(index, index)
                if char == 'u' then
                    -- Unicode escape (simplified, doesn't handle all cases)
                    value = value .. string.char(tonumber(str:sub(index + 1, index + 4), 16))
                    index = index + 4
                else
                    value = value .. char
                end
            else
                value = value .. char
            end
            index = index + 1
        end
        error("Unterminated string")
    end

    local function parseNumber()
        local value = ""
        while index <= #str do
            local char = str:sub(index, index)
            if char:match("%d") or char == '-' or char == '.' or char:lower() == 'e' then
                value = value .. char
                index = index + 1
            else
                break
            end
        end
        return tonumber(value)
    end

    local function parseObject()
        local obj = {}
        index = index + 1
        skipWhitespace()
        if str:sub(index, index) == '}' then
            index = index + 1
            return obj
        end
        while true do
            local key = parseValue()
            skipWhitespace()
            if str:sub(index, index) ~= ':' then
                error("Expected ':' after object key")
            end
            index = index + 1
            local value = parseValue()
            obj[key] = value
            skipWhitespace()
            if str:sub(index, index) == '}' then
                index = index + 1
                return obj
            elseif str:sub(index, index) ~= ',' then
                error("Expected ',' or '}' in object")
            end
            index = index + 1
            skipWhitespace()
        end
    end

    local function parseArray()
        local arr = {}
        index = index + 1
        skipWhitespace()
        if str:sub(index, index) == ']' then
            index = index + 1
            return arr
        end
        while true do
            local value = parseValue()
            table.insert(arr, value)
            skipWhitespace()
            if str:sub(index, index) == ']' then
                index = index + 1
                return arr
            elseif str:sub(index, index) ~= ',' then
                error("Expected ',' or ']' in array")
            end
            index = index + 1
            skipWhitespace()
        end
    end

    parseValue = function()
        skipWhitespace()
        local char = str:sub(index, index)
        if char == '"' then
            return parseString()
        elseif char:match("%d") or char == '-' then
            return parseNumber()
        elseif char == '{' then
            return parseObject()
        elseif char == '[' then
            return parseArray()
        elseif str:sub(index, index + 3) == 'true' then
            index = index + 4
            return true
        elseif str:sub(index, index + 4) == 'false' then
            index = index + 5
            return false
        elseif str:sub(index, index + 3) == 'null' then
            index = index + 4
            return nil
        else
            error("Unexpected character: " .. char)
        end
    end

    return parseValue()
end

return json