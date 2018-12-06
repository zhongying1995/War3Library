
local path_block = require 'war3library.libraries.types.path_block.path_block'
Router.path_block = path_block
path_block.init(config.SYS_NO_MODEL_UNIT_ID)
local game = Router.game
game.register_observer('path_block', path_block.update)
