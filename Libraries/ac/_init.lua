
require 'war3library.libraries.ac.utility'
Router.point = require 'war3library.libraries.ac.point'
Router.rect = require 'war3library.libraries.ac.rect'
Router.region = require 'war3library.libraries.ac.region'
Router.fogmodifier = require 'war3library.libraries.ac.fogmodifier'
Router.circle = require 'war3library.libraries.ac.circle'
require 'war3library.libraries.ac.trigger'
require 'war3library.libraries.ac.event'
Router.player = require 'war3library.libraries.ac.player'
require 'war3library.libraries.ac.timer'
Router.dialog = require 'war3library.libraries.ac.dialog'
Router.game = require 'war3library.libraries.ac.game'
Router.lightning = require 'war3library.libraries.ac.lightning'

Router.game.register_observer('lightning', Router.lightning.update)