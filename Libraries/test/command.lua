local table_insert = table.insert
local table_unpack = table.unpack
local jass = require 'jass.common'


local Debug_command = {}
setmetatable(Debug_command, Debug_command)

local mt = {}
Debug_command.__index = mt

mt._IS_DEBUGING = false

ac.game:event '玩家-聊天'(function(trg, player, chat)

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

    if (not callback.debug or Debug_command._IS_DEBUGING) and (not callback.condition or callback:condition(player, table_unpack(strs, 2))) then
        callback:action(player, table_unpack(strs, 2))
    end

end)

local function player_select_hero(self, player, i)
    local u = player:get_selecting_unit()
    return u and u:is_hero() and type(i) == 'number'
end

mt['debug'] = {
    action = function (self, player )
        local msg = ('玩家%s开启测试指令!'):format(player:tostring())
        ac.player.self:send_msg(msg, 10)
        Debug_command._IS_DEBUGING = true
    end
}

mt['level'] = {
    debug = true,
    condition = player_select_hero,
    action = function(self, player, lv)
        local u = player:get_selecting_unit()
        u:add_level(lv, true)
    end
}

mt['str'] = {
    debug = true,
    condition = player_select_hero,
    action = function(self, player, str)
        local u = player:get_selecting_unit()
        u:add_str(str)
    end
}

mt['agi'] = {
    debug = true,
    condition = player_select_hero,
    action = function(self, player, agi)
        local u = player:get_selecting_unit()
        u:add_agi(agi)
    end
}

mt['int'] = {
    debug = true,
    condition = player_select_hero,
    action = function(self, player, int)
        local u = player:get_selecting_unit()
        u:add_int(int)
    end
}

local is_open_fog = true
mt['fog'] = {
    debug = true,
    action = function(self)
        is_open_fog = not is_open_fog
        jass.FogEnable(is_open_fog)
        jass.FogMaskEnable(is_open_fog)
    end
}

mt['gold'] = {
    debug = true,
    action = function(self, player, gold)
        player:add_gold(gold)
    end
}

mt['lumber'] = {
    debug = true,
    action = function(self, player, lumber)
        player:add_lumber(lumber)
    end
}

mt['puppet'] = {
    debug = true,
    action = function(self, player, x, y)
        local x = x or 0
        local y = y or 0
        local u = ac.player[15]:create_unit('hfoo', ac.point(x, y))
        u:add_max_life(1000000)
        u:remove_ability('Amov')
        u:add_size(2)
        u._puppet_trg = u:event '单位-即将受到伤害'(function(trg, damage)
            ac.texttag:new{
                text = ('%.f'):format(damage.damage),
                player = damage.source:get_owner(),
                angle = 90,
                speed = 40,
                size = 16,
                red = 255,
                blue = 0,
                green = 0,
                life = 3,
                show = ac.texttag.SHOW_SELF,
                point = u:get_point(),
            }
            u:set_life(1000000)
        end)
    end
}

local function init()
    if not base.release then
        Debug_command._IS_DEBUGING = true
    end
end

init()

return Debug_command