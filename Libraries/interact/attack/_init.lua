--这些写法不正确，应该封装对应的对象，然后添加给单位，下次大重构时，再那样把

local Crit = require 'war3library.libraries.interact.attack.crit'
local Cleave = require 'war3library.libraries.interact.attack.cleave'
local Stun = require 'war3library.libraries.interact.attack.stun'

--初始化
Crit.init()
Cleave.init()
Stun.init()