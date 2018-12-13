local Game = {}

Game.FRAME = 0.03

local observer = {}

function Game.register_observer(name, ob)
	Log.info('注册观察者', name)
	table.insert(observer, ob)
end

function Game.init()
	Game.timer = ac.loop(Game.FRAME * 1000, function()
		for _, ob in ipairs(observer) do
			ob()
		end
	end)
end

Game.init()

return Game
