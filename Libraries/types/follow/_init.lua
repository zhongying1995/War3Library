local Follow = require 'war3library.libraries.types.follow.follow'
Follow.init()
local game = Router.game
game.register_observer('follow move', Follow.move)