
local path_block = require 'libraries.types.path_block.path_block'
Router.path_block = path_block
path_block.init(SYS_NO_MODEL_UNIT_ID)
local game = Router.game
game.register_observer('path_block', path_block.update)
