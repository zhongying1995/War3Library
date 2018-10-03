Rount.texttag = require 'libraries.types.texttag.texttag'

local game = Rount.game
game.register_observer('texttag', Rount.texttag.update)