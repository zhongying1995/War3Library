Router.texttag = require 'war3library.libraries.types.texttag.texttag'

local game = Router.game
game.register_observer('texttag', Router.texttag.update)