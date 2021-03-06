local jass = require 'jass.common'
local japi = require 'jass.japi'
local Unit = require 'war3library.libraries.types.unit'
local Player = require 'war3library.libraries.ac.player'
local slk = require 'jass.slk'
local runtime = require 'jass.runtime'
local Point = require 'war3library.libraries.ac.point'
local Destructable = require 'war3library.libraries.types.Destructable'

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


local Skill = {}
setmetatable(Skill, Skill)

--结构
local mt = {}
Skill.__index = mt

--类型
mt.type = 'skill'

--技能名
mt.name = ''

--等级（等级为0时表示技能无效）
mt.level = 1

--技能拥有者
mt.owner = nil

--是被动技能
mt.passive = false

--war3技能id
mt.war3_id = nil

--技能数据
mt.data = nil


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

--获取物编数据
--	war3 id
--	数据项名称
--	[如果未找到,返回的默认值]
function Skill.get_slk_by_id(id, name, default)
	local ability_data = slk.ability[id]
	if not ability_data then
		-- print('技能数据未找到', id)
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

--禁用技能
mt.disable_count = nil

--禁用技能，不能先于enable运行
--	一般用于被动技能
function mt:disable()
	self.disable_count = self:get('disable_count')
	if not self.disable_count then
		self.disable_count = 0
	end
	self:set('disable_count', self.disable_count + 1)
	self.disable_count = self:get('disable_count')
	if self.disable_count == 1 then
		--print('禁用技能', self.name)
		self:fresh()
		self:_call_event('on_disable', true)
	end
end

--允许技能
--	一般用于被动技能
function mt:enable()
	self.disable_count = self:get('disable_count')
	if not self.disable_count then
		self.disable_count = 1
	end
	self:set('disable_count', self.disable_count - 1)
	self.disable_count = self:get('disable_count')
	if self.disable_count == 0 then
		self:fresh()
		self:_call_event('on_enable', true)
	end
end

--技能是否有效
function mt:is_enable()
	return (not self.disable_count) or self:get('disable_count') <= 0
end

--允许技能(War3)
mt.is_enable_ability = true

--允许技能
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

local event_name = {
	['on_add']          = '技能-获得',
	['on_remove']       = '技能-失去',
}

--触发技能事件
--	事件名
--	无视禁用状态
function mt:_call_event(name, force)
	if not force then
		if self.removed then
			return false
		end
		if not self:is_enable() then
			return false
		end
	end
	if event_name[name] then
		self.owner:event_notify(event_name[name], self.owner, self)
	end
	if not self[name] then
		return false
	end
	return select(2, xpcall(self[name], error_handle, self))
end

--预处理技能data表中的数据数据
local function read_value(parent_skill, skill)
	if not parent_skill then
		return
	end
	-- print('parent_skill:', parent_skill, skill, parent_skill.data)
	for k, v in pairs(parent_skill.data) do
		-- print(k, v)
		if type(v) == 'function' then
			skill[k] = v(skill)
		end
		if type(v) == 'table' and not v.type then
			skill[k] = v[skill.level] or v[#v]
		end
	end
end

-- 更新技能等级信息
function mt:update_data()
	read_value(self, self)
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

--刷新技能cd
function mt:fresh_cool()

end

--暂停技能
function mt:pause_skill()

end

function mt:get_level()
	return self.level
end

--设置技能等级
function mt:set_level(level)
	self.level = level
	if self.war3_id then
		local unit = self.owner
		unit:set_ability_level(self.war3_id, level)
	end
	if self.on_upgrade then
		self:on_upgrade()
	end
	self:fresh()
end

--增加技能等级
function mt:add_level(level)
	local level = level or 1
	self:set_level(self:get_level() + level)
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
	local unit = self.owner
	if not unit then
		return false
	end
	if not unit._skills then
		return false
	end

	if self.passive then
		self:disable()
	end
	
	self:_call_event('on_remove', true)
	self.removed = true

	local name = self.name

	unit._skills[name] = nil
	if self.war3_id then
		unit._skills[self.war3_id] = nil
	end

	self:remove_ability()
	
	return true
end

--添加war3 技能
function mt:add_ability()
	if self.war3_id then
		self.owner:add_ability(self.war3_id)
	end
end

--移除war3技能
function mt:remove_ability()
	if self.war3_id then
		self.owner:remove_ability(self.war3_id)
	end
end


--英雄添加技能
--	技能名
--	[类型]：单位技能(默认)、物品
--	[初始数据]
--	@技能对象
function Unit.__index:add_skill(name, skill_type)
	return function(skl)

		--通过名字查找
		local data = ac.skill[name]

		--无法找到技能，返回错误
		if type(data) == 'function' then
			Log.error(('%s无法添加技能：%s'):format(self:tostring(), name))
			return false
		end
		
		local skill = skl or {}
		setmetatable(skill, skill)
		skill.__index = data
		skill.owner = self
		skill.skill_type = skill_type or '单位'
		
		skill:fresh()
		skill:_call_event('on_add')
		
		if skill.passive then
			skill:enable()
		end
		
		local war3_id = skill.war3_id
		-- print('单位添加技能：', name, war3_id, data)
		if skill_type ~= '物品' then
			if war3_id then
				self:add_ability(war3_id)
			end
		end
		
		if not self._skills then
			self._skills = {}
		end

		-- table.insert(self._skills, skill)
		if war3_id then
			self._skills[war3_id] = skill
		end
		self._skills[name] = skill

		return skill
	end
end


--英雄移除技能
--	技能名
--	@是否成功
function Unit.__index:remove_skill(name)
	local skill = self:find_skill(name)
	if skill then
		return skill:remove()
	end
	return false
end

--从单位身上找技能
--	技能名称/或者war3_id
--	@技能对象
function Unit.__index:find_skill(name)
	if not self._skills then
		return nil
	end
	return self._skills[name]
end

--遍历单位身上的技能
--	@list
function Unit.__index:each_skill()
	if not self._skills then
		return function () end
	end
	local result = {}
	
	for _, v in pairs(self._skills) do
		table_insert(result, v)
	end
	 
	local n = 0
	return function (t, v)
		n = n + 1
		return t[n]
	end, result
end

-- 命令使用技能
function Unit.__index:cast(name, target, data)
	local skill = self:find_skill(name)
	if not skill then
		return false
	end
	return skill:cast(target, data)
end


--发动技能效果阶段
function mt:_on_cast_effect()
	if self.on_effect then
		self:on_effect()
	end
	self.owner:event_notify('单位-发动技能效果', self)
end

--发动技能结束
function mt:_on_cast_end()
	if self.on_end then
		self:on_end()
	end
end

--使用技能
function mt:cast(target, data)
	--把data封装并返回
	local s_1 = self
	local self = self:create_cast(data)
	-- print('cast：', s_1, self)
	self.target = target
	local unit = self.owner
	if not unit._casting_list then
		unit._casting_list = {}
	end
	table_insert(unit._casting_list, self)
	self:_on_cast_effect()
	return self
end

--发动技能结束
function mt:cast_end()
	local unit = self.owner
	local index = nil
	for i, skill in ipairs(unit._casting_list) do
		if skill.name == self.name then
			self = skill
			index = i
		end
	end
	self:_on_cast_end()
	table_remove(unit._casting_list, index)
	return self
end

-- 创建施法表
function mt:create_cast(data)
	local self = self.parent_skill or self
	local skill = data or {}
	skill.is_cast_flag = true
	skill.parent_skill = self
	setmetatable(skill, skill)
	skill.__index = self
	read_value(self, skill)
	return skill
end


--注册物品
local function register_skill(self, name, data)
	setmetatable(data, data)
	data.__index = Skill
	local skill = {}
	setmetatable(skill, skill)
	skill.__index = data
	skill.__call = function(self, data)
		self.data = data
		return self
	end
	skill.name = name
	skill.data = data
	if data.war3_id then
		local war3_id = data.war3_id
		self[war3_id] = skill
		skill.war3_id = war3_id
		-- print('注册技能：', name, war3_id, skill, data)
	end
	self[name] = skill
	return skill
end

local function init()
	
	--单位发动技能事件，及其回调
	local j_trg = War3.CreateTrigger(function()
		local unit = Unit(jass.GetTriggerUnit())
		local id = base.id2string(jass.GetSpellAbilityId())
		local target = Unit(jass.GetSpellTargetUnit()) or Destructable(jass.GetSpellTargetDestructable()) or Point:new(jass.GetSpellTargetX(), jass.GetSpellTargetY())

		--通过id查找,id作为拦截器
		local skill = ac.skill[id] 
		-- print('查找技能：', id, skill)
		if type(skill) == 'function' then
			return
		end

		local skl = unit:find_skill(id)
		if not skl then
			-- print('没有在单位身上找到技能，给单位添加技能')
			skl = unit:add_skill(id){war3_id = id}
		end
		print('发动技能效果：', skl)
		skl:cast(target)
	end)
	for i = 1, 16 do
		jass.TriggerRegisterPlayerUnitEvent(j_trg, Player[i].handle, jass.EVENT_PLAYER_UNIT_SPELL_EFFECT, nil)
	end

	--单位发动技能结束
	local j_trg = War3.CreateTrigger(function()
		local unit = Unit(jass.GetTriggerUnit())
		local id = base.id2string(jass.GetSpellAbilityId())

		--通过id查找,id作为拦截器
		local skill = ac.skill[id] 
		-- print('查找技能：', id, skill)
		if type(skill) == 'function' then
			return
		end

		local skl = unit:find_skill(id)
		-- print('发动技能结束：', skl)
		skl:cast_end()
	end)
	for i = 1, 16 do
		jass.TriggerRegisterPlayerUnitEvent(j_trg, Player[i].handle, jass.EVENT_PLAYER_UNIT_SPELL_ENDCAST, nil)
	end
	
	--不允许同名技能
	--	data中的函数会被处理成单一的数据
	ac.skill = setmetatable({}, {__index = function(self, name)
		return function(data)
			return register_skill(self, name, data)
		end
	end})

end

init()


return Skill
