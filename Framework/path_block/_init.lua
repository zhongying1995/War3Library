
local path_block = require 'framework.path_block.path_block'
Rount.path_block = path_block
path_block.init(NO_MODEL_UNIT_ID)
local game = Rount.game
game.register_observer('path_block', path_block.update)
