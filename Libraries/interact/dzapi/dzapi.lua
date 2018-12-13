local jass = require 'jass.common'
local globals = require 'jass.globals'
local Interactive = globals.Interactive
local save_str = jass.SaveStr
local load_str = jass.LoadStr
local save_player = jass.SavePlayerHandle
local load_integer = jass.LoadInteger
local execute_func = jass.ExecuteFunc
local load_boolean = jass.LoadBoolean

local Dzapi = {}

--设置玩家服务器信息
--  玩家
--  key：键
--  val：值
--  @是否保持成功
function Dzapi.set_server_value( player, key, val )
    local key = tostring(key)
    local val = tostring(val)
    save_player(Interactive, 0, 1, player.handle)
    save_str(Interactive, 0, 2, key)
    save_str(Interactive, 0, 3, val)
    execute_func("dz_set_server_value")
    local b = load_boolean(Interactive, 0, 0)
    return b
end

--获取玩家服务器信息
--  玩家
--  键
function Dzapi.get_server_value( player, key )
    local key = tostring(key)
    save_player(Interactive, 0, 1, player.handle)
    save_str(Interactive, 0, 2, key)
    execute_func("dz_get_server_value")
    local s = load_str(Interactive, 0, 0)
    return s
end

--是否从rpg大厅来的
--  @本地yd测试时返回 true
--  @平台自主c房间时返回 false
function Dzapi.is_rpg_robby(  )
    execute_func("dz_is_rpg_robby")
    local robby = load_boolean(Interactive, 0, 0)
    return robby
end

--获取游戏时间
function Dzapi.get_game_time(  )
    execute_func("dz_get_game_time")
    local time = load_integer(Interactive, 0, 0)
    return time
end

--获取玩家地图等级排名
function Dzapi.get_map_level_rank( player )
    save_player(Interactive, 0, 1, player.handle)
    execute_func("dz_get_map_level_rank")
    local rank = load_integer(Interactive, 0, 0)
    return rank
end

--获取玩家地图等级
function Dzapi.get_map_level( player )
    save_player(Interactive, 0, 1, player.handle)
    execute_func("dz_get_map_level")
    local lv = load_integer(Interactive, 0, 0)
    return lv
end

--获取玩家服务器存档
--  @0：成功， ~0：失败
function Dzapi.get_server_value_error_code( player )
    save_player(Interactive, 0, 1, player.handle)
    execute_func("dz_get_server_value_error_code")
    local code = load_integer(Interactive, 0, 0)
    return code
end

--获得玩家的公会名称
function Dzapi.get_guild_name(player)
    save_player(Interactive, 0, 1, player.handle)
    execute_func("get_guild_name")
    local name = load_str(Interactive, 0, 0)
    return name
end

--获取玩家在公会的地位
--  @10:成员，20:管理员，30:创建者
function Dzapi.get_guild_role( player )
    save_player(Interactive, 0, 1, player.handle)
    execute_func("get_guild_role")
    local code = load_integer(Interactive, 0, 0)
    return code
end

return Dzapi