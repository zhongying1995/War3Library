
require 'libraries.ac.utility'
Rount.point = require 'libraries.ac.point'
Rount.rect = require 'libraries.ac.rect'
Rount.region = require 'libraries.ac.region'
Rount.fogmodifier = require 'libraries.ac.fogmodifier'
Rount.circle = require 'libraries.ac.circle'
require 'libraries.ac.trigger'
require 'libraries.ac.event'
Rount.player = require 'libraries.ac.player'
require 'libraries.ac.timer'
Rount.game = require 'libraries.ac.game'
Rount.lightning = require 'libraries.ac.lightning'

Rount.game.register_observer('lightning', Rount.lightning.update)