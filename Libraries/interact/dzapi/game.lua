local Dzapi = require 'war3library.libraries.interact.dzapi.dzapi'

local Game = Router.game

--是否从rpg大厅来的
--  @本地yd测试时返回 true
--  @平台自主c房间，右键测试时返回 false
function Game.is_rpg_robby(  )
    return Dzapi.is_rpg_robby()
end

--获取游戏时间
--(奇怪的api，一直返回0)
function Game.get_game_stated_time(  )
    return Dzapi.get_game_time()
end

