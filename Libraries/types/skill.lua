local jass = require 'jass.common'
local japi = require 'jass.japi'
local Unit = require 'libraries.types.unit'
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
	return japi.EXGetUnitAbility(self.owner.handle, Base.string2id(self.war3_id))
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

--刷新技能cd
function mt:fresh_cool()

end

--暂停技能
function mt:pause_skill()

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
	if self.on_remove then
		self:on_remove()
	end
	self.removed = true

	local name = self.name

	unit._skills[name] = nil
	unit._skills[self.war3_id] = nil

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
--	[类型]：单位技能(默认)、物品
--	[初始数据]
--	@技能对象
function Unit.__index:add_skill(name, skill_type)
	return function(skl)
		--优先通过名字查找，再通过war3_id
		local data = ac.skill[name]
		
		if type(data) == 'function' then
			if not skl or not skl.war3_id then
				Log.error(('%s无法添加技能：%s'):format(self:tostring(), name))
				return false
			end
			data = ac.skill[skl.war3_id]
		end

		--当前技能没有被注册，直接继承自Unit
		if type(data) == 'function' then
			Log.error(('%s无法添加技能：%s'):format(self:tostring(), name))
			return false
		end
		
		local skill = skl or {}
		setmetatable(skill, skill)
		skill.__index = data
		skill.owner = self
		skill:fresh()
		skill.skill_type = skill_type or '单位'

		if skill.on_add then
			skill:on_add()
		end

		if skill_type ~= '物品' then
			if not skl.war3_id then
				Log.error( ('给单位%s添加的技能没有war3_id'):format(self:tostring()) )
			end
			self:add_ability(skl.war3_id)
		end
		
		if not self._skills then
			self._skills = {}
		end

		-- table.insert(self._skills, skill)
		local war3_id = skl.war3_id
		if not war3_id then
			war3_id = data.war3_id
		end
		self._skills[name] = skill
		self._skills[war3_id] = skill

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
	if not self._skills[name] then
		local data = ac.skill[name]
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

-- 命令强制使用技能
function Unit.__index:force_cast(name, target, data)
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
	-- setmetatable(skill, cast_mt)
	-- for k in pairs(self.data) do
	-- 	skill[k] = read_value(self, skill, k)
	-- end
	setmetatable(skill, skill)
	skill.__index = self
	return skill
end

--注册物品
local function register_skill(self, name, data)
	self[name] = data
	self[name].name = name
	setmetatable(data, data)
	data.__index = Skill
	if data.war3_id then
		self[data.war3_id] = self[name]
	end
	return self[name]
end

local function init()
	
	--单位发动技能事件，及其回调
	local j_trg = War3.CreateTrigger(function()
		local unit = Unit(jass.GetTriggerUnit())
		local id = Base.id2string(jass.GetSpellAbilityId())
		local target = Unit(jass.GetSpellTargetUnit()) or ac.point(jass.GetSpellTargetX(), jass.GetSpellTargetY())
		local name = jass.GetObjectName(id)
		
		--优先通过id查找,id作为拦截器
		--如果id存在，那么name一定存在
		local skill = ac.skill[id] or ac.skill[name]
		-- for k, v in pairs(ac.skill) do
		-- 	print('ac.skill:', k, v)
		-- end
		-- print('id:', id)
		if not skill then
			return
		end

		local skl = unit:find_skill(id)
		if not skl then
			skl = unit:add_skill(name){war3_id = id}
		end
		-- print('发动技能效果：', skl)
		ac.wait(0, function()
			skl:cast(target)
		end)
	end)
	for i = 0, 15 do
		jass.TriggerRegisterPlayerUnitEvent(j_trg, jass.Player(i), jass.EVENT_PLAYER_UNIT_SPELL_EFFECT, nil)
	end
	
	--不允许同名技能
	ac.skill = setmetatable({}, {__index = function(self, name)
		return function(data)
			return register_skill(self, name, data)
		end
	end})

end

init()


return Skill
