
local mover = require 'framework.mover.mover'
Rount.mover = mover
mover.init(SYS_NO_MODEL_UNIT_ID)
local game = Rount.game
game.register_observer('mover move', mover.move)
game.register_observer('mover hit', mover.hit)
