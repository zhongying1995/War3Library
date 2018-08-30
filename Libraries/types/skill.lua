local jass = require 'jass.common'
local japi = require 'jass.japi'
local hero = require 'types.hero'
local Unit = require 'types.unit'
local slk = require 'jass.slk'
local runtime = require 'jass.runtime'

local setmetatable = setmetatable
local rawset = rawset
local rawget = rawget
local type = type
local xpcall = xpcall
local select = select
local table_concat = table.concat
local math_floor = math.floor
local math_ceil = math.ceil
local error_handle = runtime.error_handle
local table_insert = table.insert
local table_remove = table.remove
local math_tointeger = math.tointeger

-- 充能动画帧数
local CHARGE_FRAME = 8

local Skill = {}
setmetatable(Skill, Skill)

--结构
local mt = {}
Skill.__index = mt

--类型
mt.type = 'skill'

--技能名
mt.name = ''

--最大等级
mt.max_level = 1

--等级（等级为0时表示技能无效）
mt.level = 1

--英雄
mt.unit = nil

--是被动技能
mt.passive = false

--war3技能id
mt.war3_id = nil

--技能数据
mt.data = nil

--瞬发技能
mt.instant = 0

--强制施法(无视技能限制)
mt.force_cast = 0


--获得技能句柄(jass)
function mt:get_handle()
	if self.owner.removed then
		return 0
	end
	return japi.EXGetUnitAbility(self.owner.handle, base.string2id(self.war3_id))
end


--获得技能名字
function mt:get_name()
	return self.name
end

--读取技能数据
local function read_value(self, skill, key)
	local value = self[key]
	local dvalue = self.data[key]
	local tp = type(value)
	local dtp = type(dvalue)
	if value == nil then
		value = dvalue
		tp = dtp
	elseif not (tp == 'function' or tp == 'table') and (dtp == 'function' or dtp == 'table') then
		value = dvalue
		tp = dtp
	end
	if tp == 'function' then
		value = value(skill, self.owner)
		tp = type(value)
	end
	if tp == 'table' and not value.type then
		if value[self.level] == nil then
			value = value[1]
		else
			value = value[self.level]
		end
	end
	return value
end

--初始化技能
local function init_skill(self)
	if self.has_inited then
		return
	end
	self.has_inited = true
	local data = self.data
	if not data then
		data = {}
		self.data = data
	end
	for k, v in pairs(data) do
		self[k] = v
	end
	if data.war3_id then
		ac.skill[data.war3_id] = self
	end
end

function Skill.get_slk_by_id(id, name, default)
	local ability_data = slk.ability[id]
	if not ability_data then
		print('技能数据未找到', id)
		return default
	end
	local data = ability_data[name]
	if data == nil then
		return default
	end
	if type(default) == 'number' then
		return tonumber(data) or default
	end
	return data
end

--获取物编数据
--	数据项名称
--	[如果未找到,返回的默认值]
function mt:get_slk(name, default)
	return Skill.get_slk_by_id(self.war3_id, name, default)
end

--允许技能(War3)
mt.is_enable_ability = true

function mt:enable_ability()
	self:set('is_enable_ability', true)
	self.owner:get_owner():enable_ability(self.war3_id)
	self:fresh()
	return false
end

--禁用技能(War3)
function mt:disable_ability()
	self:set('is_enable_ability', false)
	self.owner:get_owner():disable_ability(self.war3_id)
	return false
end

--技能是否允许(War3)
function mt:is_ability_enable()
	return self.is_enable_ability
end

local cast_mt = {
	__index = function(skill, key)
		local value = read_value(skill.parent_skill, skill, key)
		skill[key] = value
		return value
	end,
}

-- 更新技能等级信息
function mt:update_data()
	local self = self.parent_skill or self
	local data = self.data
	if not data then
		return
	end
	local skill = setmetatable({}, cast_mt)
	skill.parent_skill = self
	for k in pairs(data) do
		skill[k] = read_value(self, skill, k)
		self[k] = skill[k]
	end
end


-- 是否是施法表
function mt:is_cast()
	return self.is_cast_flag
end

-- 是否是同一个技能对象
function mt:is(skill)
	return (self.parent_skill or self) == (skill.parent_skill or skill)
end

--进行标记
--	标记索引
function mt:set(key, value)
	if self.parent_skill then
		self.parent_skill[key] = value
	else
		self[key] = value
	end
end

--获取标记
--	标记索引
function mt:get(key)
	if self.parent_skill then
		return self.parent_skill[key]
	else
		return self[key]
	end
end

--刷新物编技能
function mt:fresh()
	self:update_data()
end

-- 移除技能
function mt:remove()
	self = self.parent_skill or self
	if self.removed then
		return false
	end
	local hero = self.owner
	if not hero then
		return false
	end
	if not hero.skills then
		return false
	end

	self.removed = true
	
	local name = self.name

	hero.skills[name] = nil

	local order = self:get_order()
	if order and hero._order_skills then
		hero._order_skills[order] = nil
	end


	self:remove_ability()
	
	
	return true
end

function mt:add_ability()
	if self.war3_id and not self.no_ability then
		self.owner:add_ability(self.war3_id)
	end
end

function mt:remove_ability()
	if self.war3_id and not self.no_ability then
		self.owner:remove_ability(self.war3_id)
	end
end


--英雄添加技能
--	技能名
--	[初始数据]
--	[类型]：普通单位技能(默认)、物品
--	@技能对象
function unit.__index:add_skill(name, data, type)
	if not ac.skill[name] then
		log.error('技能不存在', name)
		return false
	end

	if not self._skills then
		self._skills = {}
	end
	
	if not data then
		data = {}
	end
	for k, v in pairs(ac.skill[name]) do
		if data[k] == nil then
			data[k] = v
		end
	end
	
	local skill = setmetatable(data, Skill)
	skill.__index = skill
	skill.owner = self
	skill:fresh()

	if skill.on_add then
		skill:on_add()
	end

	if type ~= '物品' then
		if not data.war3_id then
			log.error( ('给单位%s添加的技能没有war3_id'):format(self:tostring()) )
		end
		self:add_ability(data.war3_id)
	end

	table.insert(self._skills, skill)

	return skill
end


--英雄移除技能
--	技能名
--	@是否成功
function unit.__index:remove_skill(name)
	local skill = self:find_skill(name)
	if skill then
		return skill:remove()
	end
	return false
end

--从单位身上找技能
--	技能名称
--	@技能对象
function unit.__index:find_skill(name)
	if not self._skills and not self._skills[name] then
		return nil
	end
	return self._skills[name]
end

--遍历单位身上的技能
--	[技能类型]
--	[是否包含未学习的英雄技能]
--	@list
function unit.__index:each_skill(type, ignore_level)
	if not self.skills then
		return function () end
	end
	local result = {}
	if type then
		if not self.skills[type] then
			return function () end
		end
		for _, v in pairs(self.skills[type]) do
			if ignore_level or v:get_level() > 0 then
				table_insert(result, v)
			end
		end
	else
		for _, type_skills in pairs(self.skills) do
			for _, v in pairs(type_skills) do
				if ignore_level or v:get_level() > 0 then
					table_insert(result, v)
				end
			end
		end
	end
	local n = 0
	return function (t, v)
		n = n + 1
		return t[n]
	end, result
end

-- 命令使用技能
function unit.__index:cast(name, target, data)
	local skill = self:find_skill(name)
	if not skill then
		return false
	end
	return skill:cast(target, data)
end

-- 命令强制使用技能
function unit.__index:force_cast(name, target, data)
	local skill = self:find_skill(name)
	if not skill then
		return false
	end
	data = data or {}
	data.force_cast = 1
	return skill:cast(target, data)
end

--发动技能效果阶段
function mt:_on_cast_effect()
	if self.on_effect then
		self:on_effect()
	end
	self.owner:event_notify('单位-发动技能效果', self)
end

-- 使用技能
function mt:cast(target, data)
	--把data封装并返回
	local self = self:create_cast(data)
	self.target = target
	self:_on_cast_effect()
	return self
end

-- 创建施法表
function mt:create_cast(data)
	local self = self.parent_skill or self
	local skill = data or {}
	skill.is_cast_flag = true
	skill.parent_skill = self
	setmetatable(skill, cast_mt)
	for k in pairs(self.data) do
		skill[k] = read_value(self, skill, k)
	end
	return setmetatable(skill, self)
end


local function init()
	
	--单位发动技能事件，及其回调
	local j_trg = war3.CreateTrigger(function()
		local unit = Unit(jass.GetTriggerUnit())
		local id = base.id2string(jass.GetSpellAbilityId())
		local target = Unit(jass.GetSpellTargetUnit()) or ac.point(jass.GetSpellTargetX(), jass.GetSpellTargetY())
		local name = jass.GetObjectName(id)

		--优先通过id查找
		local skill = ac.skill[id] or ac.skill[name]
		
		if not skill then
			return
		end

		local skl = unit:find_skill(name)
		if not skl then
			skl = unit:add_skill(name)
		end

		ac.wait(0, function()
			skl:cast(target)
		end)
	end)
	for i = 1, 13 do
		jass.TriggerRegisterPlayerUnitEvent(j_trg, ac.player[i].handle, jass.EVENT_PLAYER_UNIT_SPELL_CHANNEL, nil)
	end

	ac.skill = setmetatable({}, {__index = function(self, name)
		self[name] = {}
		setmetatable(self[name], Skill)
		self[name].name = name
		init_skill(self[name])
		return self[name]
	end})
end

init()

--保存技能数据
function Skill:__call(data)
	self.data = data
	for k, v in pairs(data) do
		self[k] = v
	end
	self.has_inited = false
	init_skill(self)
	return self
end

return Skill
