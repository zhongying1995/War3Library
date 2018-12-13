local Dzapi = require 'war3library.libraries.interact.dzapi.dzapi'

local Player = Router.Player

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
