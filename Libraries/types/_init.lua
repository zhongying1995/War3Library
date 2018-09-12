
Rount.multiboard = require 'libraries.types.multiboard'
Rount.texttag = require 'libraries.types.texttag'
Rount.timerdialog = require 'libraries.types.timerdialog'
Rount.unit = require 'libraries.types.unit'
Rount.heal = require 'libraries.types.heal'
require 'libraries.types.attribute'
Rount.selector = require 'libraries.types.selector'
Rount.effect = require 'libraries.types.effect'
Rount.buff = require 'libraries.types.buff'
Rount.skill = require 'libraries.types.skill'
Rount.item = require 'libraries.types.item'
Rount.hero = require 'libraries.types.hero'
Rount.damage = require 'libraries.types.damage'

local game = Rount.game
game.register_observer('texttag', Rount.texttag.update)

