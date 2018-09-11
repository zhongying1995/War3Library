local jass = require 'jass.common'
local japi = require 'jass.japi'
local Unit = require 'Libraries.types.unit'
local setmetatable = setmetatable
local table_insert = table.insert
local table_remove = table.remove

local Damage = {}
setmetatable(Damage, Damage)

function Damage:new(data)
	local data = data or {}
	setmetatable(data, Damage)
	return data
end

local mt = {}
Damage.__index = mt

_all_damage_dummies = {}

--类型
mt.type = 'damage'

--来源
mt.source = nil

--目标
mt.target = nil

--初始伤害
mt.damage = 0

--当前伤害
mt.current_damage = 0

--攻击类型
local ATTACK_TYPE = {
	['混乱'] = jass.ATTACK_TYPE_CHAOS,
	--技术护甲，无视魔免
	['普通'] = jass.ATTACK_TYPE_MELEE,
	--无视护甲，对魔免无效
	['魔法'] = jass.ATTACK_TYPE_MAGIC,
	['英雄'] = jass.ATTACK_TYPE_HERO,
}

--伤害类型
local DAMAGE_TYPE = {
	--该种伤害受到目标护甲的影响，且通常无法对虚无形态的目标造成伤害，但无视目标的魔法免疫。
	['普通'] = jass.DAMAGE_TYPE_NORMAL,
	--对虚无形态的目标无效，同样无视魔法免疫，但是无视目标的护甲
	['加强'] = jass.DAMAGE_TYPE_ENHANCED,
	--无视护甲，不能伤害魔免，在法术攻击(也就是绝大多数技能的攻击类型)类型下对虚无有效。
	['魔法'] = jass.DAMAGE_TYPE_FIRE,
	--无视护甲，无视魔免，配合法术攻击可以伤害虚无
	['神圣'] = jass.DAMAGE_TYPE_UNIVERSAL,
}

--武器类型
local WEAPON_TYPE = {
	['普通'] = jass.WEAPON_TYPE_WHOKNOWS,
}

local function get_leisure_dummy( )
	for _, u in pairs(_all_damage_dummies) do
		if u._is_leisure then
			return u
		end
	end
	return add_damage_dummy()
end

local function init_damage_dummy(self, u)
	if u then
		self._is_leisure = false
		self:set_owner(u:get_owner())
	else
		self._is_leisure = true
		self:set_owner(Player[16])
	end
end

local function add_damage_dummy()
	local dummy = Unit.create_dummy(Player[16], 'ndog', Point:new(0,0))
	dummy._is_damage_dummy = true
	dummy:pause(true)
	dummy:show(false)
	init_damage_dummy(dummy)
	table.insert(_all_damage_dummies, dummy)
	return dummy
end

function mt:is_attack()
	return self.is_attack and true
end

function mt:is_range()
	return self.is_range and true
end

function mt:is_physical()
	return self.is_physical and true
end

function mt:get_original_damage()
	return self.original_damage
end

function mt:get_damage()
	return self.damage
end

function mt:set_damage(damage)
	self.damage = damage
end

function mt:add_damage(damage)
	self:set_damage(self:get_damage()+damage)
end

function Damage:__call(data)
	local damage = Damage:new(data)
	local source = damage.source
	local target = damage.target

	local dummy = get_leisure_dummy()
	init_damage_dummy(dummy, source)

	damage.original_source = source
	damage.source = dummy
	damage.original_damage = damage.damage
	dummy.damage = damage

	local is_attack = damage.is_attack or false
	local is_range = damage.is_range or false
	local attack_type = ATTACK_TYPE[damage.attack_type]
	if not attack_type then
		if damage.skill then
			damage.attack_type = '魔法'
		elseif source:is_hero() then
			damage.attack_type = '英雄'
		else
			damage.attack_type = '普通'
		end
		attack_type = ATTACK_TYPE[damage.attack_type]
	end

	local damage_type = DAMAGE_TYPE[damage.damage_type]
	if not damage_type then
		if damage.skill then
			damage.damage_type = '魔法'
		else
			damage.damage_type = '普通'
		end
		damage_type = DAMAGE_TYPE[damage.damage_type]
	end

	local weapon_type = WEAPON_TYPE['普通']
	damage.weapon_type = '普通'

	jass.UnitDamageTarget(damage.source, damage.target.handle, damage.damage, is_attack, is_range, attack_type, damage_type, weapon_type)
end

function Unit.__index:damage(data)
	if not data or data and not data.target then
		return
	end
	if not data.source then
		data.source = self
	end
	Damage(data)
end

local j_trg = War3.CreateTrigger(function()
	local source = Unit(jass.GetEventDamageSource())
	local target = Unit(jass.GetTriggerUnit())
	local damage_val = jass.GetEventDamage()

	if damage_val < 0 then
		return
	end

	if not target or target:is_removed() then
		if target then
			Log.info(('%s对【已被移除的%s】造成伤害'):format(source and source:tostring(), target:tostring()))
		end
		return
	end

	local damage = Damage:new()
	if source._is_damage_dummy then
		damage = source.damage
		init_damage_dummy(source)
		source = damage.source
	end
	damage.damage = damage_val

	if source:is_removed() then
		Log.info(('【已被移除的%s】对%s造成伤害'):format(source:tostring(), target:tostring()))
		return
	end

	if japi.EXGetEventDamageData(1) ~= 0 then
		damage.is_physical = true
	end

	if japi.EXGetEventDamageData(2) ~= 0 then
		damage.is_attack = true
	end

	if japi.EXGetEventDamageData(3) ~= 0 then
		damage.is_range = true
	end

	source:event_notify('单位-即将造成伤害', damage)
	target:event_notify('单位-即将受到伤害', damage)

	if damage.damage + 0.5 > target:get_life() then
		source:event_notify('单位-即将造成致命伤害', damage)
		target:event_notify('单位-即将受到致命伤害', damage)
	end
	
	if damage.damage ~= damage_val then
		japi.EXSetEventDamage(damage.damage)
	end
end)

ac.game:event '单位-创建'(function(trg, unit)
	jass.TriggerRegisterUnitEvent(j_trg, unit.handle, jass.EVENT_UNIT_DAMAGED)
end)

return Damage
