
require 'libraries.ac.utility'
Router.point = require 'libraries.ac.point'
Router.rect = require 'libraries.ac.rect'
Router.region = require 'libraries.ac.region'
Router.fogmodifier = require 'libraries.ac.fogmodifier'
Router.circle = require 'libraries.ac.circle'
require 'libraries.ac.trigger'
require 'libraries.ac.event'
Router.player = require 'libraries.ac.player'
require 'libraries.ac.timer'
Router.dialog = require 'libraries.ac.dialog'
Router.game = require 'libraries.ac.game'
Router.lightning = require 'libraries.ac.lightning'

Router.game.register_observer('lightning', Router.lightning.update)