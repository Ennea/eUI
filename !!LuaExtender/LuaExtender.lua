-- helper frame
local f = CreateFrame('frame')

f:SetScript('OnEvent', function()
    this[event](this, arg1)
end)


-- the almighty _G :]
setglobal('_G', getfenv(0))

-- some not yet available Lua functions
_G['select'] = function(num, ...)
    -- return number of arguments
    if num == '#' then
        return getn(arg)
    end

    -- return arguments from a certain point on
    num = tonumber(num)
    if num then
        if num == 0 then
            error('index out of range', 2)
        elseif num < 0 then
            if abs(num) > getn(arg) then
                error('index out of range', 2)
            end

            num = num + getn(arg)
        else
            num = num - 1
        end

        if num > 0 then
            local i
            for i = 1, num do
                table.remove(arg, 1)
            end
        end

        return unpack(arg)
    else
        error('bad argument, number expected', 2)
    end
end

-- print
_G['print'] = function(str)
    DEFAULT_CHAT_FRAME:AddMessage(str)
end

-- string functions
_G['string'].match = function(str, pattern)
    local r = { string.find(str, pattern) }

    -- no match
    if getn(r) == 0 then
        return nil
    end

    local s, e = table.remove(r, 1), table.remove(r, 1)

    -- match without captures, return the whole match
    if getn(r) == 0 then
        return string.sub(str, s, e)

    -- more than two return values, return only the captures
    else
        return unpack(r)
    end
end

-- non-standard
_G['string'].join = function(sep, ...)
    return table.concat(arg, sep)
end

-- non-standard
_G['string'].trim = function(str)
    return string.gsub(str, '^%s*(.-)%s*$', '%1')
end

-- math functions
_G['math'].modf = function(number)
    local fractional = math.mod(number, 1)
    local integral = number - fractional
    return integral, fractional
end

-- non-standard
_G['math'].round = function(number, place)
    if not number or not place then
        error('bad argument(s)', 2)
    end

    return math.floor(number / place + 0.5) * place
end


-- future WoW API functions
local loggedIn = false
_G['IsLoggedIn'] = function()
    return loggedIn and 1 or nil
end

f:RegisterEvent('PLAYER_LOGIN')
function f.PLAYER_LOGIN(self)
    loggedIn = true
end

_G['IsModifierKeyDown'] = function()
    return IsShiftKeyDown() or IsAltKeyDown() or IsControlKeyDown()
end


-- non-standard WoW API additions
local function get_function_id(func)
    assert(type(func) == 'function')
    return string.sub(string.match(tostring(func), ': .+$'), 3)
end

-- acts like hooksecurefunc would
_G['post_hook'] = function(...)
    -- hook global function
    if type(arg[1]) == 'string' then
        local functionName = arg[1]
        local hookFunction = arg[2]

        local func = _G[functionName]
        if not func then
            return false
        end

        local functionId = get_function_id(func)
        _G[functionId .. functionName] = func
        _G[functionName] = function(...)
            _G[functionId .. functionName](unpack(arg))
            hookFunction(unpack(arg))
        end

    -- hook member function
    else
        local tbl = arg[1]
        local functionName = arg[2]
        local hookFunction = arg[3]

        if not tbl or not tbl[functionName] then
            return false
        end

        local functionId = get_function_id(tbl[functionName])
        tbl[functionId .. functionName] = tbl[functionName]
        tbl[functionName] = function(...)
            tbl[functionId .. functionName](unpack(arg))
            hookFunction(unpack(arg))
        end

        return true
    end
end

-- like post_hook, but executes the hook function before the original
_G['pre_hook'] = function(...)
    -- hook global function
    if type(arg[1]) == 'string' then
        local functionName = arg[1]
        local hookFunction = arg[2]

        local func = _G[functionName]
        if not func then
            return false
        end

        local functionId = get_function_id(func)
        _G[functionId .. functionName] = func
        _G[functionName] = function(...)
            hookFunction(unpack(arg))
            _G[functionId .. functionName](unpack(arg))
        end

    -- hook member function
    else
        local tbl = arg[1]
        local functionName = arg[2]
        local hookFunction = arg[3]

        if not tbl or not tbl[functionName] then
            return false
        end

        local functionId = get_function_id(tbl[functionName])
        tbl[functionId .. functionName] = tbl[functionName]
        tbl[functionName] = function(...)
            hookFunction(unpack(arg))
            tbl[functionId .. functionName](unpack(arg))
        end

        return true
    end
end

-- replace a function, but pass the original as the first argument
_G['replace_hook'] = function(...)
    -- hook global function
    if type(arg[1]) == 'string' then
        local functionName = arg[1]
        local hookFunction = arg[2]

        local func = _G[functionName]
        if not func then
            return false
        end

        local functionId = get_function_id(func)
        _G[functionId .. functionName] = func
        _G[functionName] = function(...)
            hookFunction(_G[functionId .. functionName], unpack(arg))
        end

    -- hook member function
    else
        local tbl = arg[1]
        local functionName = arg[2]
        local hookFunction = arg[3]

        if not tbl or not tbl[functionName] then
            return false
        end

        local functionId = get_function_id(tbl[functionName])
        tbl[functionId .. functionName] = tbl[functionName]
        tbl[functionName] = function(...)
            hookFunction(tbl[functionId .. functionName], unpack(arg))
        end

        return true
    end
end

_G['GetContainerItemByName'] = function(findName)
    if not findName then
        return
    end

    local totalCount = 0
    local link, name
    local bag, slot, texture, count
    for i = 0, NUM_BAG_FRAMES do
        for k = 1, GetContainerNumSlots(i) do
            link = GetContainerItemLink(i, k)
            name = link and string.match(link, '%[([^%]]+)%]') or nil
            if name and string.lower(name) == string.lower(findName) then
                bag, slot = i, k
                texture, count = GetContainerItemInfo(i, k)
                totalCount = totalCount + count
            end
        end
    end

    return bag, slot, totalCount, texture
end

_G['UseItemByName'] = function(name)
    local bag, slot = GetContainerItemByName(name)
    if bag and slot then
        UseContainerItem(bag, slot)
    else
        UIErrorsFrame:AddMessage(ERR_ITEM_NOT_FOUND, 1, 0.1, 0.1)
    end
end
