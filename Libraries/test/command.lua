local table_insert = table.insert
local table_unpack = table.unpack
local jass = require 'jass.common'


local Debug_command = {}
setmetatable(Debug_command, Debug_command)

local mt = {}
Debug_command.__index = mt

_IS_NOT_DEBUGING = false

ac.game:event '玩家-聊天'(function(trg, player, chat)

    if _IS_NOT_DEBUGING then
        return
    end

    if chat:sub(1, 1) ~= '-' then
        return
    end

    chat = chat:lower():sub(2)
    local strs = {}
    for s in chat:gmatch('%S+') do
        local s2i = tonumber(s)
        if type(s2i) == 'number' then
            s = s2i
        end
        table_insert(strs, s)
    end
    local index = strs[1]

    local callback =  Debug_command[index]

    if not callback then
        return
    end

    if not callback.condition or callback.condition(player, table_unpack(strs, 2)) then
        callback.action(player, table_unpack(strs, 2))
    end

end)

local function player_select_hero(player, i)
    local u = player:get_selecting_unit()
    return u and u:is_hero() and type(i) == 'number'
end

mt['level'] = {
    condition = player_select_hero,
    action = function(player, lv)
        local u = player:get_selecting_unit()
        u:add_level(lv, true)
    end
}

mt['str'] = {
    condition = player_select_hero,
    action = function(player, str)
        local u = player:get_selecting_unit()
        u:add_str(str)
    end
}

mt['agi'] = {
    condition = player_select_hero,
    action = function(player, agi)
        local u = player:get_selecting_unit()
        u:add_agi(agi)
    end
}

mt['int'] = {
    condition = player_select_hero,
    action = function(player, int)
        local u = player:get_selecting_unit()
        u:add_int(int)
    end
}

local is_open_fog = true
mt['fog'] = {
    action = function()
        is_open_fog = not is_open_fog
        jass.FogEnable(is_open_fog)
        jass.FogMaskEnable(is_open_fog)
    end
}

mt['gold'] = {
    action = function(player, gold)
        player:add_gold(gold)
    end
}

mt['lumber'] = {
    action = function(player, lumber)
        player:add_lumber(lumber)
    end
}

local function init()
    if base.release then
        _IS_NOT_DEBUGING = true
    end
end

init()

return Debug_command