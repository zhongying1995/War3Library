
local mover = require 'war3library.libraries.types.mover.mover'
Router.mover = mover
mover.init(SYS_NO_MODEL_UNIT_ID)
local game = Router.game
game.register_observer('mover move', mover.move)
game.register_observer('mover hit', mover.hit)
