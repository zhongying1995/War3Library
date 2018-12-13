local Dzapi = require 'war3library.libraries.interact.dzapi.dzapi'

local Player = Router.player

local mt = Player.__index


--设置玩家服务器信息
--  key：键
--  val：值
--  @是否保持成功
function mt:set_server_value( key, val )
    return Dzapi.set_server_value( self, key, val )
end

--获取玩家服务器信息
--  键
function mt:get_server_value( key )
    return Dzapi.get_server_value( self, key )
end

--获取地图等级
function mt:get_map_level()
    return Dzapi.get_map_level(self)
end

--获取地图等级排名
function mt:get_map_level_rank()
    return Dzapi.get_map_level_rank(self)
end


--是否成功获取玩家服务器存档
--  @是否成功
--  @错误码
function mt:is_enable_get_server()
    local i = Dzapi.get_server_value_error_code(self)
    if i == 0 then
        return true, i
    end
    return false, i
end

--获取玩家的公会名称
function mt:get_guild_name()
    local name = Dzapi.get_guild_name(self)
    if name ~= '' then
        return name
    end
    return nil
end

--获取玩家在公会的职位
function mt:get_guild_role(  )
    local code = Dzapi.get_guild_role(self)
    if code == 10 then
        return '成员'
    elseif code == 20 then
        return '管理员'
    elseif code == 30 then
        return '创建者'
    else
        return '未知'
    end
end
