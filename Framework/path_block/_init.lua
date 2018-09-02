
local patch_block = require 'framework.block.patch_block'
Rount.patch_block = patch_block
patch_block.init(NO_MODEL_UNIT_ID)
local game = Rount.game
game.register_observer('path_block', path_block.update)
