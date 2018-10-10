
local jass = require 'jass.common'
local japi = require 'jass.japi'
local dbg = require 'jass.debug'
local Unit = require 'libraries.types.unit'
local Player = require 'libraries.ac.player'
local slk = require 'jass.slk'
local math = math

local Hero = {}
setmetatable(Hero, Hero)

--结构
local mt = {}
Hero.__index = mt

--hero继承unit
setmetatable(mt, Unit)

--单位类型
mt.unit_type = 'hero'

_HERO_ATTRIBUTE_ABIL_ID = SYS_HERO_ATTRIBUTE_ABIL_ID or 'Aamk'

--英雄属性的技能马甲
local ATTRIBUTE_ABIL_ID = _HERO_ATTRIBUTE_ABIL_ID

--当前经验值
mt.xp = 0

--是否是英雄
function mt:is_hero()
	return true
end

--获得经验值
function mt:addXp(xp, show)
	jass.SetHeroXP(self.handle, jass.GetHeroXP(self.handle) + xp, show and true)
	self.xp = jass.GetHeroXP(self.handle)
end


function mt:set_level(lv, is_show)
	local old_lv = self:get_level()
	if lv > old_lv then
		jass.SetHeroLevel(self.handle, lv, is_show and true)
	else
		jass.UnitStripHeroLevel(self.handle, old_lv - lv)
	end
end

function mt:add_level(lv, is_show)
	self:set_level(self:get_level() + lv, is_show)
end


function mt:get_str(is_all)
	return jass.GetHeroStr(self.handle, is_all and true)
end

function mt:set_str(n)
	jass.SetHeroStr(self.handle, n, true)
end

function mt:add_str(n)
	self:set_str(self:get_str()+n)
end


function mt:get_agi(is_all)
	return jass.GetHeroAgi(self.handle, is_all and true)
end

function mt:set_agi(n)
	jass.SetHeroAgi(self.handle, n, true)
end

function mt:add_agi(n)
	self:set_agi(self:get_agi()+n)
end


function mt:get_int(is_all)
	return jass.GetHeroInt(self.handle, is_all and true)
end

function mt:set_int(n)
	jass.SetHeroInt(self.handle, n, true)
end


function mt:add_int(n)
	self:set_int(self:get_int()+n)
end

function mt:get_extra_str()
	return self:get_str(true) - self:get_str()
end

mt._add_str = 0
function mt:get_add_str()
    return self._add_str
end

function mt:set_add_str(str)
	self._add_str = str
	local agi = self:get_add_agi()
	local int = self:get_add_int()
	self:remove_ability(ATTRIBUTE_ABIL_ID)
	self:add_ability(ATTRIBUTE_ABIL_ID)
	japi.EXSetAbilityDataReal(japi.EXGetUnitAbility(self.handle, Base.string2id(ATTRIBUTE_ABIL_ID)), 2, 110, str)
	japi.EXSetAbilityDataReal(japi.EXGetUnitAbility(self.handle, Base.string2id(ATTRIBUTE_ABIL_ID)), 2, 108, agi)
	japi.EXSetAbilityDataReal(japi.EXGetUnitAbility(self.handle, Base.string2id(ATTRIBUTE_ABIL_ID)), 2, 109, int)
	japi.EXSetAbilityDataReal(japi.EXGetUnitAbility(self.handle, Base.string2id(ATTRIBUTE_ABIL_ID)), 2, 111, 1)
	self:set_ability_level(ATTRIBUTE_ABIL_ID, 2)
end

function mt:add_add_str(str)
	self:set_add_str(self:get_add_str() + str)
end


function mt:get_extra_agi()
	return self:get_agi(true) - self:get_agi()
end

mt._add_agi = 0
function mt:get_add_agi()
    return self._add_agi
end

function mt:set_add_agi(agi)
	self._add_agi = agi
	local str = self:get_add_str()
	local int = self:get_add_int()
	self:remove_ability(ATTRIBUTE_ABIL_ID)
	self:add_ability(ATTRIBUTE_ABIL_ID)
	japi.EXSetAbilityDataReal(japi.EXGetUnitAbility(self.handle, Base.string2id(ATTRIBUTE_ABIL_ID)), 2, 110, str)
	japi.EXSetAbilityDataReal(japi.EXGetUnitAbility(self.handle, Base.string2id(ATTRIBUTE_ABIL_ID)), 2, 108, agi)
	japi.EXSetAbilityDataReal(japi.EXGetUnitAbility(self.handle, Base.string2id(ATTRIBUTE_ABIL_ID)), 2, 109, int)
	japi.EXSetAbilityDataReal(japi.EXGetUnitAbility(self.handle, Base.string2id(ATTRIBUTE_ABIL_ID)), 2, 111, 1)
	self:set_ability_level(ATTRIBUTE_ABIL_ID, 2)
end

function mt:add_add_agi(agi)
	self:set_add_agi(self:get_add_agi() + agi)
end


function mt:get_extra_int()
	return self:get_int(true) - self:get_int()
end

mt._add_int = 0
function mt:get_add_int()
    return self._add_int
end

function mt:set_add_int(int)
	self._add_int = int
	local str = self:get_add_str()
	local agi = self:get_add_agi()
	self:remove_ability(ATTRIBUTE_ABIL_ID)
	self:add_ability(ATTRIBUTE_ABIL_ID)
	japi.EXSetAbilityDataReal(japi.EXGetUnitAbility(self.handle, Base.string2id(ATTRIBUTE_ABIL_ID)), 2, 110, str)
	japi.EXSetAbilityDataReal(japi.EXGetUnitAbility(self.handle, Base.string2id(ATTRIBUTE_ABIL_ID)), 2, 108, agi)
	japi.EXSetAbilityDataReal(japi.EXGetUnitAbility(self.handle, Base.string2id(ATTRIBUTE_ABIL_ID)), 2, 109, int)
	japi.EXSetAbilityDataReal(japi.EXGetUnitAbility(self.handle, Base.string2id(ATTRIBUTE_ABIL_ID)), 2, 111, 1)
	self:set_ability_level(ATTRIBUTE_ABIL_ID, 2)
end

function mt:add_add_int(int)
	self:set_add_int(self:get_add_int() + int)
end

--复活英雄
function mt:revive(where)
	if self:is_alive() then
		return
	end
	if not where then
		where = self:get_born_point()
	end
	local origin = self:get_point()
	jass.ReviveHero(self.handle, where:get_point():get())
	self._is_alive = true
	if self.wait_to_transform_id then
		local target = self.wait_to_transform_id
		self.wait_to_transform_id = nil
		self:transform(target)
	end
	self:event_notify('英雄-复活', self)
end

--创建单位
--	id:单位名字
--	where:创建位置
--	face:面向角度
function Player.__index:create_hero(name, where, face)
	local u = self:create_unit(name, where, face)
	
	--这是一个没有注册过的英雄
	if not u.data then
		u.__index = Hero
	else
		local data = u.data
		if data.attribute then
			local str = data.attribute.str
			if str then
				u:set_str(str)
			end
			local agi = data.attribute.agi
			if data.attribute.agi then
				u:set_agi(agi)
			end
			local int = data.attribute.int
			if data.attribute.int then
				u:set_int(int)
			end
		end
	end
	return u
end


function register_jass_triggers()
	--英雄升级事件
	local j_trg = War3.CreateTrigger(function()
		local hero = Unit(jass.GetTriggerUnit())
		local new_lv = jass.GetHeroLevel(hero.handle)
		local old_lv = hero.level
		for i = hero.level + 1, new_lv do
			hero.level = i
			hero:event_notify('英雄-升级', hero, i)
		end

	end)
	for i = 1, 12 do
		jass.TriggerRegisterPlayerUnitEvent(j_trg, Player[i].handle, jass.EVENT_PLAYER_HERO_LEVEL, nil)
	end
end

local function register_hero(self, name, data)
	local war3_id = data.war3_id
	if not war3_id then
		Log.error(('注册%s英雄时，不能没有war3_id'):format(name) )
		return
	end
	Registry:register(name, war3_id)
	
	setmetatable(data, data)
	data.__index = Hero

	local hero = {}
	setmetatable(hero, hero)
	hero.__index = data
	hero.__call = function(self, data) 
		self.data = data
		return self
	end
	hero.name = name
	hero.data = data

	ac.unit[name] = hero
	ac.unit[war3_id] = hero

	return hero
end

local function init()
	
	ac.hero = setmetatable({}, {__index = function(self, name)
		return function(data)
			register_hero(self, name, data)
		end
	end})
	
	register_jass_triggers()
end

init()

return Hero
