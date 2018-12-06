local jass = require 'jass.common'
local japi = require 'jass.japi'
local Unit = require 'war3library.libraries.types.unit'
local Player = require 'war3library.libraries.ac.player'
local Point = require 'war3library.libraries.ac.point'
local setmetatable = setmetatable
local table_insert = table.insert
local table_remove = table.remove

local Damage = {}
setmetatable(Damage, Damage)

function Damage:new(data)
	local data = data or {}
	setmetatable(data, data)
	data.__index = self
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

--这是一种反弹伤害类型，会触发特殊的事件
mt.is_rebounding = false

--消逝的伤害类型，不会触发任何事件
mt.is_missing = false

--马甲伤害类型
_DAMAGE_DUMMY_UNIT_ID = config.SYS_DAMAGE_DUMMY_UNIT_ID or 'ndog'

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
	local dummy = Unit.create_dummy(Player[16], _DAMAGE_DUMMY_UNIT_ID, Point:new(0,0))
	dummy._is_damage_dummy = true
	dummy:pause(true)
	dummy:show(false)
	init_damage_dummy(dummy)
	table.insert(_all_damage_dummies, dummy)
	return dummy
end

local function get_leisure_dummy( )
	for _, u in pairs(_all_damage_dummies) do
		if u._is_leisure then
			return u
		end
	end
	return add_damage_dummy()
end

--伤害是否为攻击伤害
function mt:is_attack()
	return self.is_attacking and true or japi.EXGetEventDamageData(2) ~= 0
end

--伤害是否为远程
function mt:is_range()
	return self.is_ranging and true or japi.EXGetEventDamageData(3) ~= 0
end

--伤害是否为物理
function mt:is_physical()
	return self.is_physicality and true or japi.EXGetEventDamageData(1) ~= 0
end

--获得原始伤害
function mt:get_original_damage()
	return self.original_damage
end

--获得当前伤害
function mt:get_damage()
	return self.damage
end

--设置伤害
function mt:set_damage(damage)
	self.damage = damage
end

--增加伤害
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
	damage.source = source
	damage.original_damage = damage.damage
	dummy.damage = damage

	local is_attacking = damage.is_attacking or false
	local is_ranging = damage.is_ranging or false
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

	jass.UnitDamageTarget(dummy.handle, target.handle, damage.damage, is_attacking, is_ranging, attack_type, damage_type, weapon_type)
end

--单位对目标造成伤害
--	伤害表
function Unit.__index:damage(data)
	if not data then
		Log.error(('%s欲造成伤害，但无伤害数据表！'):format(self:tostring()))
		return
	end
	if not data.target then
		data.target = self
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
	
	if damage_val <= 0 then
		--这些是非法伤害，不做捕捉
		return
	end

	if not source or source:is_removed() then
		if source then
			Log.warn(('【已被移除的%s】对%s造成伤害'):format(source and source:tostring(), target:tostring()))
		end
		return
	end

	local damage = Damage:new()
	damage.source = source
	damage.target = target
	if source._is_damage_dummy then
		damage = source.damage
		init_damage_dummy(source)
		source = damage.source
	end

	if damage.is_missing then
		return
	end

	damage.damage = damage_val
	if not damage.original_damage then
		damage.original_damage = damage_val
	end


	if damage.is_rebounding then

		local tmp_damage = damage.damage
		source:event_notify('单位-即将造成伤害效果-反弹的', damage)
		if damage.damage ~= tmp_damage then
			damage.damage = tmp_damage
		end
		target:event_notify('单位-即将受到伤害效果-反弹的', damage)
		if damage.damage ~= tmp_damage then
			damage.damage = tmp_damage
		end
	
		if damage.damage + 0.5 > target:get_life() then
			source:event_notify('单位-即将造成致命伤害-反弹的', damage)
			target:event_notify('单位-即将受到致命伤害-反弹的', damage)
		end
	
	else
		
		source:event_notify('单位-即将造成伤害-加减', damage)
		source:event_notify('单位-即将受到伤害-加减', damage)
		source:event_notify('单位-即将造成伤害-乘除', damage)
		source:event_notify('单位-即将受到伤害-乘除', damage)

		--在伤害效果事件中，不允许改变伤害值
		local tmp_damage = damage.damage
		source:event_notify('单位-即将造成伤害效果', damage)
		if damage.damage ~= tmp_damage then
			damage.damage = tmp_damage
		end
		target:event_notify('单位-即将受到伤害效果', damage)
		if damage.damage ~= tmp_damage then
			damage.damage = tmp_damage
		end
	
		if damage.damage + 0.5 > target:get_life() then
			source:event_notify('单位-即将造成致命伤害', damage)
			target:event_notify('单位-即将受到致命伤害', damage)
		end
			
	end

	if damage.damage ~= damage_val then
		japi.EXSetEventDamage(damage.damage)
	end

end)

ac.game:event '单位-创建'(function(trg, unit)
	jass.TriggerRegisterUnitEvent(j_trg, unit.handle, jass.EVENT_UNIT_DAMAGED)
end)

return Damage
