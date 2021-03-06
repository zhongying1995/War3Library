
local jass = require 'jass.common'
local japi = require 'jass.japi'
local slk = require 'jass.slk'
local dbg = require 'jass.debug'
local Player = require 'war3library.libraries.ac.player'
local Rect = require 'war3library.libraries.ac.rect'
local order2id = require 'war3library.kernel.war3.order_id'
local Point = require 'war3library.libraries.ac.point'
local Unit_button = require 'war3library.libraries.types.unit_button'
local math = math
local table_insert = table.insert
local table_remove = table.remove
local Follow = require 'war3library.libraries.types.follow.follow'

local _last_summoned_unit

local Unit = {}
setmetatable(Unit, Unit)


--结构
local mt = {}
Unit.__index = mt

function mt:tostring()
    local player = self:get_owner()
    return ('[%s|%s|handle:%s|owner:%s]'):format(self:get_name(), self, self.handle, player.base_name)
end

--类型
mt.type = 'unit'

--单位类型
mt.unit_type = 'unit'

--句柄
mt.handle = 0

--所有者
mt.owner = nil

--存活
mt._is_alive = true

--是否是背包单位
mt.is_backpack_container = nil

--技能,字符串，用于初始化单位身上的技能
mt.skill_names = nil

--单位所拥有的技能，表
mt._skills = nil


--选取半径
mt.selected_radius = 16

--单位计时器
mt._timers = nil

--已暂停时间
mt.paused_clock = 0

--上一次暂停开始的时间
mt.last_pause_clock = 0

_UNIT_FLYING_ABIL_ID = config.SYS_UNIT_FLYING_ABIL_ID or 'Arav'
_UNIT_TRANSFORM_ABIL_ID = config.SYS_UNIT_TRANSFORM_ABIL_ID or 'AEme'

--初始化单位身上的技能
local function init_skills(unit)
	if unit.skill_names then
		for name in unit.skill_names:gmatch('%S+') do
			unit:add_skill(name){}
		end
	end
end

--初始化单位（初始化单位属性，想想要怎么做吧）
local function init_attribute(unit)

end

--根据handle初始化单位
local function init_unit(handle)
	if Unit.all_units[handle] then
		return Unit.all_units[handle]
	end
	if handle == 0 then
		return nil
	end
	local id = base.id2string(jass.GetUnitTypeId(handle))
	
	local data = ac.unit[id]
	if type(data) == 'function' then
		data = Unit
	end

	local u = {}
	setmetatable(u, u)
	u.__index = data

	--保存到全局单位表中
	u.handle = handle
	u.id = id
	u.war3_id = id
	u.name = jass.GetUnitName(handle)
	u.owner = Player[jass.GetOwningPlayer(handle)]
	u.born_point = u:get_point()
	Unit.all_units[handle] = u
	
	--令物体可以飞行
	u:add_ability(_UNIT_FLYING_ABIL_ID)
	u:remove_ability(_UNIT_FLYING_ABIL_ID)
	
	--设置高度
	u:set_high(u:get_slk('moveHeight', 0))
	
	return u
end

local function init_unit_datas(unit)
	init_attribute(unit)

	init_skills(unit)
end

--根据handle创建单位
--	单位handle
--	是否根据数据初始化单位，默认：true
function Unit.new(handle, is_init_datas)
	if Unit.all_units[handle] then
		return Unit.all_units[handle]
	end
	local u = init_unit(handle)
	if not u then
		return nil
	end

	if is_init_datas == nil or is_init_datas then
		init_unit_datas(u)
	end

	if u:get_ability_level 'Aloc' == 0 then
		u:event_notify('单位-创建', u)
	end
	
	return u
end

--转换handle为单位,若没有，则创建
function Unit:__call(handle)
	if not handle or handle == 0 then
		return
	end
	local u = Unit.all_units[handle]
	if not u then
		u = Unit.new(handle)
	end
	return u
end

--获取玩家
function mt:get_player()
	return Player(jass.GetOwningPlayer(self.handle))
end

--获取单位的主属性
function mt:get_primary()
	if not self._primary and self:is_type_hero() then
		self._primary = self:get_slk('primary', false)
	end
	return self._primary
end

--主属性为力量
function mt:is_str_primary()
	return self:get_primary() == 'STR'
end

--主属性为敏捷
function mt:is_agi_primary()
	return self:get_primary() == 'AGI'
end

--主属性为力量
function mt:is_int_primary()
	return self:get_primary() == 'INT'
end

--单位是否是召唤物
function mt:is_minion(  )
	return self._is_minion
end

mt.pause_count = 0
--暂停单位
--	[暂停/不暂停]
function mt:pause(pause)
	if pause == nil then
		pause = true
	end
	if pause then
		self.pause_count = self.pause_count + 1
		if self.pause_count == 1 then
			jass.PauseUnit(self.handle, true)
		end
	else
		self.pause_count = self.pause_count - 1
		if self.pause_count == 0 then
			jass.PauseUnit(self.handle, false)
		end
	end
end

--单位是否是暂停的
function mt:is_pause(  )
	return self.pause_count>0
end

--显示单位
--	[显示/隐藏]
function mt:show(show)
	if show == nil then
		show = true
	end
	jass.ShowUnit(self.handle, show and true)
end

--是否是魔兽的英雄类型
function mt:is_type_hero()
	return jass.IsUnitType(self.handle, jass.UNIT_TYPE_HERO)
end

--是否是英雄
--	@默认返回 否
function mt:is_hero()
	return false
end

--是否是建筑
function mt:is_structure()
	if self._is_structure == nil then
		self._is_structure = self:is_type_structure()
	end
	return self._is_structure
end

--是否是魔兽的建筑
function mt:is_type_structure()
	return jass.IsUnitType(self.handle, jass.UNIT_TYPE_STRUCTURE)
end

--设置单位的生命周期类型
function mt:set_time_life( duration, type)
	local duration = duration or 1
	jass.UnitApplyTimedLife(self.handle, type, duration)
end

--注册单位事件
function mt:event(name)
	return ac.event_register(self, name)
end
local ac_game = ac.game

--发起事件
--分发会发给三者中的其中一个
function mt:event_dispatch(name, ...)
	local res = ac.event_dispatch(self, name, ...)
	if res ~= nil then
		return res
	end
	local player = self:get_owner()
	if player then
		local res = ac.event_dispatch(player, name, ...)
		if res ~= nil then
			return res
		end
	end
	local res = ac.event_dispatch(ac_game, name, ...)
	if res ~= nil then
		return res
	end
	return nil
end

--三者都会收到事件响应
function mt:event_notify(name, ...)
	ac.event_notify(self, name, ...)
	local player = self:get_owner()
	if player then
		ac.event_notify(player, name, ...)
	end
	ac.event_notify(ac_game, name, ...)
end

--id
mt.id = ''

--获取单位id,一般与get_type_id 一样
function mt:get_id()
	return self.id or self:get_type_id()
end

--获得单位id
function mt:get_type_id()
	return jass.GetUnitTypeId(self.handle)
end

--获取单位的魔兽名字
function mt:get_type_name()
	return jass.GetUnitName(self.handle)
end

--是否是目标类型
--	类型
function mt:is_type(type)
	return self.unit_type == type
end


--是否是幻象
function mt:is_illusion()
	return self._is_illusion
end

--是否是马甲单位
function mt:is_dummy()
	return self._is_dummy
end

--获得名字
function mt:get_name()
    return self.name
end

--根据单位id查找slk数据
function Unit.get_slk_by_id(id, name, default)
	local unit_data = slk.unit[id]
	if not unit_data then
		Log.error('单位数据未找到', id)
		return default
	end
	local data = unit_data[name]
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
	return Unit.get_slk_by_id(self:get_id(), name, default)
end


--自定义数据
mt.user_data = nil

--保存数据
--	索引
--	值
function mt:set_data(key, value)
	if not self.user_data then
		self.user_data = {}
	end
	self.user_data[key] = value
end

--获取数据
--	索引
function mt:get_data(key)
	if not self.user_data then
		self.user_data = {}
	end
	return self.user_data[key]
end

--杀死自己，killer是凶手
function mt:killed(killer)
	if not self:is_alive() then
		return false
	end
	
	if not killer then
		killer = self
	end

	self._is_alive = false
	
	jass.KillUnit(self.handle)

	if not self:is_dummy() then
		killer:event_notify('单位-杀死单位', killer, self)
		self:event_notify('单位-死亡', self, killer)
		if self == killer then
			self:event_notify('单位-自杀', self)
		end
	end

	--删除Buff
	if self._buffs then
		local _buffs = {}
		for bff in pairs(self._buffs) do
			if not bff.keep then
				_buffs[#_buffs + 1] = bff
			end
		end
		for i = 1, #_buffs do
			_buffs[i]:remove()
		end
	end

	if not self:is_hero() then
		local death_type = self:get_slk('deathtype')
		local time
		if death_type == 0 or death_type == 1 then
			time = self:get_slk('death', 5)
		else
			time = config.SYS_BONE_DECAY_TIME or 5
		end
		ac.wait(time * 1000, function (  )
			self:remove()
		end)
	end
	return true
end

--移除所有特效
function mt:remove_all_effects()
	if self._effect_list then
		for i, eff in ipairs(self._effect_list) do
			jass.DestroyEffect(eff.handle)
			dbg.handle_unref(eff.handle)
			eff.handle = nil
			eff.removed = true
		end
		self._effect_list = nil
	end
end

--是否单位已移除
function mt:is_removed()
	return self.removed and true
end

--删除单位
function mt:remove()
	if self:is_removed() then
		return
	end
	self.removed = true
	self._is_alive = false
	
	self._last_point = Point:new(jass.GetUnitX(self.handle), jass.GetUnitY(self.handle))
	self:event_notify('单位-移除', self)

	self:remove_all_effects()

	--移除单位的所有Buff
	if self._buffs then
		local _buffs = {}
		for bff in pairs(self._buffs) do
			_buffs[#_buffs + 1] = bff
		end
		for i = 1, #_buffs do
			_buffs[i]:remove()
		end
	end
	
	--移除单位的所有技能
	for skill in self:each_skill() do
		skill:remove()
	end

	--移除单位身上的物品
	for i = 1, 6 do
		local it = self:get_slot_item(i)
		if it then
			it:remove()
		end
	end

	--移除单位身上的计时器
	if self._timers then
		for i, t in ipairs(self._timers) do
			t:remove()
		end
	end

	--移除单位身上的Unit_button表
	if self._unit_buttons then
		for _, button in pairs(self._unit_buttons) do
			button:remove()
		end
	end

	jass.RemoveUnit(self.handle)
	
	--从表中删除单位
	Unit.all_units[self.handle] = nil

	dbg.handle_unref(self.handle)
end

--是否存活
function mt:is_alive()
	return not self.removed and self._is_alive
end

--队伍
--获得单位的队伍
function mt:get_team()
	return self:get_owner():get_team()
end

--是否是友方
--	对象
function mt:is_ally(dest)
	if dest.type ~= 'player' then
		dest = dest:get_owner()
	end
	return jass.IsUnitAlly(self.handle, dest.handle)
end

--调用jass效率可能比较低，可以考虑用self:get_team() ~= dest:get_team()优化
--是否是敌人
--	对象
function mt:is_enemy(dest)
	if dest.type ~= 'player' then
		dest = dest:get_owner()
	end
	return jass.IsUnitEnemy(self.handle, dest.handle)
end

--位置
--上一个位置
mt._last_point = nil

--获取位置
function mt:get_point()
	if self.removed then
		return self._last_point:copy()
	else
		return Point:new(jass.GetUnitX(self.handle), jass.GetUnitY(self.handle))
	end
end

--设置位置
function mt:set_point(point)
	if self:has_restriction '禁锢' then
		return false
	end
	local x, y = point:get()
	jass.SetUnitX(self.handle, x)
	jass.SetUnitY(self.handle, y)
	if self._dummy_point then
		self._dummy_point[1] = x
		self._dummy_point[2] = y
	end
	return true
end

--移动单位到指定位置(检查碰撞)
--	移动目标
--	[无视地形阻挡]
--	[无视地图边界]
function mt:set_position(where, path, super)
	if self:has_restriction '禁锢' then
		return false
	end
	if where:get_point():is_block(path, super) then
		return false
	end
	local x, y = where:get_point():get()
	local x1, y1, x2, y2 = Rect.MAP:get()
	if x < x1 then
		x = x1
	elseif x > x2 then
		x = x2
	end
	if y < y1 then
		y = y1
	elseif y > y2 then
		y = y2
	end
	self:set_point(Point:new(x, y))
	return true
end

--传送到指定位置
--	[无视地形]
function mt:blink(target, path, not_stop)
	local source = self:get_point()
	if self:set_position(target, path) then
		self:event_notify('单位-传送完成', self, source, target)
	end
	if not not_stop then self:issue_order 'stop' end
end


--获取出生点
function mt:get_born_point()
	return self.born_point
end

--是否在指定位置附近(计算碰撞)
function mt:is_in_range(p, radius)
	return self:get_point() * p:get_point() - self:get_selected_radius() <= radius
end

--高度
mt.high = 0

--获取高度
--	[是否是绝对高度(地面高度+飞行高度)]
function mt:get_high(b)
	if b then
		return self:get_point():getZ() + self.high
	else
		return self.high
	end
end

--设置高度
--	高度
--	[是否是绝对高度]
function mt:set_high(high, b, change_time)
	if b then
		self.high = high - self:get_point():getZ()
	else
		self.high = high
	end
	jass.UnitAddAbility(self.handle, base.string2id(_UNIT_FLYING_ABIL_ID))
	jass.UnitRemoveAbility(self.handle, base.string2id(_UNIT_FLYING_ABIL_ID))
	jass.SetUnitFlyHeight(self.handle, self.high, change_time or 0)
end

--增加高度
--	高度
--	[是否是绝对高度]
function mt:add_high(high, b)
	self:set_high(self:get_high(b) + high)
end

--朝向
--获得朝向
function mt:get_facing()
	return jass.GetUnitFacing(self.handle)
end

--设置朝向
--	朝向
--  瞬间转身
function mt:set_facing(angle, instant)
	if instant then
		japi.EXSetUnitFacing(self.handle, angle)
	else
		jass.SetUnitFacing(self.handle, angle)
	end
end

--大小
mt.size = 1
mt.default_size = nil

--设置大小
--	大小
function mt:set_size(size)
	self.size = size
	if not self.default_size then
		self.default_size = tonumber(self:get_slk 'modelScale') or 1
	end
	size = size * self.default_size
	jass.SetUnitScale(self.handle, size, size, size)
end

--获取大小
function mt:get_size()
	return self.size
end

--增加大小
--	大小
function mt:add_size(size)
	size = size + self:get_size()
	self:set_size(size)
end

--是否是近战
function mt:is_melee()
	return jass.IsUnitType(self.handle, jass.UNIT_TYPE_MELEE_ATTACKER)
end

--刷新所有技能的冷却
function mt:fresh_cool()
	local t = {}
	for skl in self:each_skill() do
		local f = skl:fresh_cool()
		table.insert(t, f)
	end
	return function()
		for _, f in ipairs(t) do
			f()
		end
	end
end

--更新数据
function mt:update()
	local life = self:get_life()
	local life_recover, life_recover_perc = self:get_life_recovery()
	life_recover = life_recover + life_recover_perc/100 * life

	local life_recover_inact, life_recover_inact_perc = self:get_inactive_life_recovery()

	local mana_recover, mana_recover_inact = self:get_mana_recovery(), self:get_inactive_mana_recovery()

	if not self.active then
		life_recover = life_recover + life_recover_inact + life_recover_inact_perc/100 * life
		mana_recover = mana_recover + mana_recover_inact
	end
	if life_recover ~= 0 then
		self:add_life(life_recover / Unit.frame)
	end
	if mana_recover ~= 0 then
		self:add_mana(mana_recover / Unit.frame)
	end
end

-- 变身
local dummy
function mt:transform(target_id)

	if not self:is_type_hero() then
		return
	end

	if not self:is_alive() then
		--死亡状态无法变身
		self.wait_to_transform_id = target_id
		return
	end

	if not dummy then
		dummy = ac.dummy
		dummy:add_ability(_UNIT_TRANSFORM_ABIL_ID)
	end
	--变身
	japi.EXSetAbilityDataInteger(japi.EXGetUnitAbility(dummy.handle, base.string2id(_UNIT_TRANSFORM_ABIL_ID)), 1, 117, base.string2id(self:get_id()))
	self:add_ability(_UNIT_TRANSFORM_ABIL_ID)
	japi.EXSetAbilityAEmeDataA(japi.EXGetUnitAbility(self.handle, base.string2id(_UNIT_TRANSFORM_ABIL_ID)), base.string2id(target_id))
	self:remove_ability(_UNIT_TRANSFORM_ABIL_ID)

	--修改ID
	self.id = target_id

	--可以飞行
	self:add_ability(_UNIT_FLYING_ABIL_ID)
	self:remove_ability(_UNIT_FLYING_ABIL_ID)

	--动画混合时间
	jass.SetUnitBlendTime(self.handle, self:get_slk('blend', 0))

    -- 恢复特效
    if self._effect_list then
        for _, eff in ipairs(self._effect_list) do
            if eff.handle then
                jass.DestroyEffect(eff.handle)
                dbg.handle_unref(eff.handle)
                eff.handle = jass.AddSpecialEffectTarget(eff.model, self.handle, eff.socket or 'origin')
                dbg.handle_ref(eff.handle)
            end
        end
	end
	return self
end

--变身为马甲
function mt:transform_dummy(  )
	self:add_ability('Aloc')
	self._is_dummy = true
end

--变身为非马甲
function mt:transform_non_dummy(  )
	self:remove_ability('Aloc')
	self:show(false)
	self:show(true)
	self._is_dummy = false
end

--等级
mt.level = 1

--获取等级
function mt:get_level()
	self.level = jass.GetUnitLevel(self.handle)
	return self.level
end

--技能(War3)
--添加技能
--	技能id
--	技能等级
function mt:add_ability(sid, lv)
	if not sid then
		return false
	end
	local id = base.string2id(sid)
	if not jass.UnitAddAbility(self.handle, id) then
		return false
	end
	if lv then
		jass.SetUnitAbilityLevel(self.handle, id, lv)
	end
	self:make_permanent(sid)
	return true
end

--移除技能
--	技能id
function mt:remove_ability(war3_id)
	if not war3_id then
		return false
	end
	local war3_id = base.string2id(war3_id)
	return jass.UnitRemoveAbility(self.handle, war3_id)
end

--允许技能
--	技能id
function mt:enable_ability(war3_id)
	self:get_owner():enable_ability(war3_id)
end

--禁用技能
--	技能id
function mt:disable_ability(war3_id)
	self:get_owner():disable_ability(war3_id)
end

--获取技能等级
--	技能id
function mt:get_ability_level(war3_id)
	local war3_id = base.string2id(war3_id)
	return jass.GetUnitAbilityLevel(self.handle, war3_id)
end

--设置技能等级
--	技能id
--	[技能等级]
function mt:set_ability_level(war3_id, lv)
	local war3_id = base.string2id(war3_id)
	jass.SetUnitAbilityLevel(self.handle, war3_id, lv or 1)
end

--命令单位使用技能
--	技能id
--	[目标]
function mt:cast_ability(war3_id, target)
	local order = slk.ability[war3_id].Order
	if not target then
		return jass.IssueImmediateOrder(self.handle, order)
	elseif target.owner then
		return jass.IssueTargetOrder(self.handle, order, target.handle)
	else
		return jass.IssuePointOrder(self.handle, order, target:get_point():get())
	end
end

--设置技能永久性
--	技能id
function mt:make_permanent(war3_id)
	if not war3_id then
		return
	end
	local war3_id = base.string2id(war3_id)
	jass.UnitMakeAbilityPermanent(self.handle, true, war3_id)
end


--发布命令
--	命令
--	[目标]
function mt:issue_order(order, target)
	local res
	if not target then
		res = jass.IssueImmediateOrder(self.handle, order)
	elseif target.owner then
		res = jass.IssueTargetOrder(self.handle, order, target.handle)
	else
		local x, y
		if target.type == 'point' then
			x, y = target:get()
		else
			x, y = target:get_point():get()
		end
		res = jass.IssuePointOrder(self.handle, order, x, y)
	end
	return res
end

--使用id发布命令
--	命令
--	[目标]
function mt:issue_order_by_id(id, target)
	local res
	if not target then
		res = jass.IssueImmediateOrderById(self.handle, id)
	elseif target.owner then
		res = jass.IssueTargetOrderById(self.handle, id, target.handle)
	else
		local x, y
		if target.type == 'point' then
			x, y = target:get()
		else
			x, y = target:get_point():get()
		end
		res = jass.IssuePointOrderById(self.handle, id, x, y)
	end
	return res
end

local id2order = setmetatable({}, {__index = function(self, k)
	Log.info('OrderId2String', k)
	local order = jass.OrderId2String(k)
	if order then
		Log.error(('%s = 0x%X,'):format(order, k))
		self[k] = order
	else
		self[k] = ''
	end
	return order
end})
for k, v in pairs(order2id) do
	id2order[v] = k
end

--获得命令
--	@命令
function mt:get_order()
	local order_id = jass.GetUnitCurrentOrder(self.handle)
	return id2order[order_id], order_id
end

--获取单位的碰撞体积
function mt:get_collision()
	return self:get_slk('collision', 0)
end

--获取单位的选取半径
function mt:get_selected_radius()
	return self.selected_radius
end

function mt:clock()
	return ac.clock() - self.paused_clock
end

mt.pause_timer_count = 0

--暂停单位计时器
function mt:pause_timer(flag)
	if flag == nil then
		flag = true
	end
	if flag then
		self.pause_timer_count = self.pause_timer_count + 1
		if self.pause_timer_count == 1 and self._timers then
			for _, t in ipairs(self._timers) do
				t:pause()
			end
		end
	else
		if self.pause_timer_count == 0 then
			Log.error '计数错误'
			return
		end
		self.pause_timer_count = self.pause_timer_count - 1
		if self.pause_timer_count == 0 and self._timers then
			for _, t in ipairs(self._timers) do
				t:resume()
			end
		end
	end
end

--是否暂停单位计时器
function mt:is_pause_timer()
	return self.pause_timer_count > 0
end

--暂停buff
mt.pause_buff_count = 0

--暂停buff
--	[暂停/释放]
function mt:pause_buff(flag)
	if flag == nil then
		flag = true
	end
	if flag then
		self.pause_buff_count = self.pause_buff_count + 1
		if self.pause_buff_count == 1 then
			if self._buffs then
				for buff in pairs(self._buffs) do
					buff:pause(true)
				end
			end
		end
	else
		if self.pause_buff_count == 0 then
			Log.error '计数错误'
			return
		end
		self.pause_buff_count = self.pause_buff_count - 1
		if self.pause_buff_count == 0 then
			if self._buffs then
				for buff in pairs(self._buffs) do
					buff:pause(false)
				end
			end
		end
	end
end

--判断是否暂停buff
function mt:is_pause_buff()
	return self.pause_buff_count > 0
end

--暂停技能
mt.pause_skill_count = 0

--暂停技能
--	[暂停/释放]
function mt:pause_skill(flag)
	if flag == nil then
		flag = true
	end
	if flag then
		self.pause_skill_count = self.pause_skill_count + 1
		if self.pause_skill_count == 1 then
			for skill in self:each_skill() do
				skill:pause(true)
			end
		end
	else
		if self.pause_skill_count == 0 then
			Log.error '计数错误'
			return
		end
		self.pause_skill_count = self.pause_skill_count - 1
		if self.pause_skill_count == 0 then
			for skill in self:each_skill() do
				skill:pause(false)
			end
		end
	end
end

--判断是否暂停技能
function mt:is_pause_skill()
	return self.pause_skill_count > 0
end

--暂停运动
mt.pause_mover_count = 0

--暂停运动
--	[暂停/释放]
function mt:pause_mover(flag)
	if flag == nil then
		flag = true
	end
	if flag then
		self.pause_mover_count = self.pause_mover_count + 1
		if self.pause_mover_count == 1 and self.movers then
			for mover in pairs(self.movers) do
				mover:pause(true)
			end
		end
	else
		if self.pause_mover_count == 0 then
			log.error '计数错误'
			return
		end
		self.pause_mover_count = self.pause_mover_count - 1
		if self.pause_mover_count == 0 and self.movers then
			for mover in pairs(self.movers) do
				mover:pause(false)
			end
		end
	end
end

--判断是否暂停运动
function mt:is_pause_mover()
	return self.pause_mover_count > 0
end

--跟随单位
function mt:follow(data)
	data.target = self
	return Follow(data)
end

--颜色
mt.red = 255
mt.green = 255
mt.blue = 255
mt.alpha = 255

--设置单位颜色
--	[红]
--	[绿]
--	[蓝]
function mt:set_color(red, green, blue)
	self.red, self.green, self.blue = red, green, blue
	jass.SetUnitVertexColor(
		self.handle,
		math.min(255, math.max(0, self.red)),
		math.min(255, math.max(0, self.green)),
		math.min(255, math.max(0, self.blue)),
		math.min(255, math.max(0, self.alpha))
	)
end

--获取rgb颜色
function mt:get_color()
	return self.red, self.green, self.blue
end

--增加rgb颜色
function mt:add_color(red, green, blue)
	local old_red, old_green, old_blue = self:get_color()
	self:set_color( old_red + red, old_green + green, old_blue + blue)
end

--设置单位透明度
--	透明度
function mt:set_alpha(alpha)
	self.alpha = alpha
	jass.SetUnitVertexColor(
		self.handle,
		math.min(255, math.max(0, self.red)),
		math.min(255, math.max(0, self.green)),
		math.min(255, math.max(0, self.blue)),
		math.min(255, math.max(0, self.alpha))
	)
end

--获取单位透明度
function mt:get_alpha()
	return self.alpha
end

--增加单位透明度
function mt:add_alpha(alpha)
	self:set_alpha(self:get_alpha() + alpha)
end

--动画
--设置单位动画
--	动画名或动画序号
function mt:set_animation(ani)
	if not self:is_alive() then
		return
	end
	if type(ani) == 'string' then
		jass.SetUnitAnimation(self.handle, self.animation_properties .. ani)
	else
		jass.SetUnitAnimationByIndex(self.handle, ani)
	end
end

--将动画添加到队列
--	动画序号
function mt:add_animation(ani)
	if not self:is_alive() then
		return
	end
	jass.QueueUnitAnimation(self.handle, ani)
end

--设置动画播放速度
--	速度
function mt:set_animation_speed(speed)
	jass.SetUnitTimeScale(self.handle, speed)
end

mt.animation_properties = ''

--添加动画附加名
--	附加名
function mt:add_animation_properties(name)
	jass.AddUnitAnimationProperties(self.handle, name, true)
	self.animation_properties = self.animation_properties .. name .. ' '
end

--移除动画附加名
--	附加名
function mt:remove_animation_properties(name)
	jass.AddUnitAnimationProperties(self.handle, name, false)
	self.animation_properties = self.animation_properties:gsub(name .. ' ', '')
end

--视野
--是否可见
--	对象
function mt:is_visible(dest)
	if dest.type ~= 'player' then
		dest = dest:get_owner()
	end
	return jass.IsUnitVisible(self.handle, dest.handle)
end

--设置索敌范围
function mt:set_search_range(r)
	jass.SetUnitAcquireRange(self.handle, r)
end

--视野技能
local _sight_ability = config.SYS_SIGHT_ABILITY

--添加单位视野(依然不能超过1800)
function mt:add_sight(r)
	self:add_ability(_sight_ability)
	local handle = japi.EXGetUnitAbility(self.handle, base.string2id(_sight_ability))
	japi.EXSetAbilityDataReal(handle, 2, 108, - r)
	self:set_ability_level(_sight_ability, 2)
	self:remove_ability(_sight_ability)
end

--获得所有者
function mt:get_owner()
	return self.owner
end

-- 设置所有者
function mt:set_owner(p, color)
	self.owner = p
	jass.SetUnitOwner(self.handle, p.handle, not not color)
end

--创建马甲
--	位置
--	朝向
function mt:create_dummy(name, where, face, is_aloc)
	local u = self:get_owner():create_dummy(name or self:get_type_id(), where, face, is_aloc)
	return u
end

local _illusion_ability = config.SYS_ILLUSION_ABILITY

--创建镜像
--	攻击力比
--	受到伤害比
--	持续时间
--	位置
function mt:create_illusion(attack, damaged, time, point)
	
	--设置幻象数据
	local attack = attack / 100
	local damaged = damaged / 100
	ac.dummy:remove_ability(_illusion_ability)
	ac.dummy:add_ability(_illusion_ability)
	local handle = japi.EXGetUnitAbility(ac.dummy.handle, base.string2id(_illusion_ability))
	japi.EXSetAbilityDataReal(handle, 2, 102, time or 1)
	japi.EXSetAbilityDataReal(handle, 2, 103, time or 1)
	japi.EXSetAbilityDataReal(handle, 2, 108, attack)
	japi.EXSetAbilityDataReal(handle, 2, 109, attdamagedack)
	ac.dummy:set_ability_level(_illusion_ability, 2)

	local player = self:get_owner()
	--852274 幻象权杖
	jass.SetUnitOwner( ac.dummy.handle, player.handle, false)
	jass.IssueTargetOrderById( ac.dummy.handle, 852274, self.handle) 
	jass.SetUnitOwner( ac.dummy.handle, Player[16].handle, false)
	
	if not _last_summoned_unit then
		player:send_warm_msg('|cffff0000创建幻象失败！|r')
		return
	end
	local handle = _last_summoned_unit
	if not handle then
		return
	end
	dbg.handle_ref(handle)
	_last_summoned_unit = nil
	jass.SetUnitOwner(handle, player.handle, true)
	local dummy = Unit.init_illusion(handle)
	jass.SetUnitBlendTime(handle, dummy:get_slk('blend', 0))
	dummy:set_position(point or self:get_point(), true, true)
	
	return dummy
end

mt.last_active_time = -99999
mt.active = true 
--设置战斗状态
function mt:set_active(dest)
	self.last_active_time = self:clock()
	if not self.active then
		self.active = true
		self:event_notify('单位-进入战斗', self, dest)
	end
end
  
--更新战斗状态
function mt:update_active()
	if self.active then 
		if not self:is_active() then
			self.active = false
			self:event_notify('单位-脱离战斗', self)
		end
	end
end

--单位是否处于战斗状态
function mt:is_active()
	return self:clock() - self.last_active_time < 3000
end

--共享视野
function mt:share_visible(p, flag)
	jass.UnitShareVision(self.handle, p.handle, flag ~= false and true or false)
end

--初始化幻象
function Unit.init_illusion(handle)
	local u = Unit.new(handle, false)
	u._is_illusion = true
	return u
end

--创建单位(以单位为参照)
--	单位名字
--	[位置(默认为参照单位)]
--	朝向
function mt:create_unit(name, where, face)
	if not where then
		where = self:get_point()
	end
	return self:get_owner():create_unit(name, where, face or self:get_facing())
end

--[[
	当查找已经不存在的name时，意味着这是一个id
	如果这是一个错误的名字，那我也没办法了~
--]]
--	name:可以是lua注册过的单位名字/或者war3的id
function Unit.create(player, name, where, face)
	
	local id = Registry:name_to_id('unit', name)
	print('unit create:', name, id)
	local j_id = base.string2id(id)
	local x, y
	if where.type == 'point' then
		x, y = where:get()
	else
		x, y = where:get_point():get()
	end
	
	local handle = jass.CreateUnit(player.handle, j_id, x, y, face or 0)
	dbg.handle_ref(handle)
	local u = Unit.new(handle)
	return u
end

--创建单位(以玩家为参照)
--	单位name
--	位置
--	[朝向]
function Player.__index:create_unit(name, where, face)
	return Unit.create(self, name, where, face)
end

--is_aloc:是否添加蝗虫，默认true
function Unit.create_dummy(player, name, where, face, is_aloc)
	local x, y
	if where.type == 'point' then
		x, y = where:get()
	else
		x, y = where:get_point():get()
	end
	local id = Registry:name_to_id('unit', name)
	local handle = jass.CreateUnit(player.handle, base.string2id(id), x, y, face or 0)
	dbg.handle_ref(handle)
	if is_aloc == nil then
		is_aloc = true
	end
	if is_aloc then
		jass.UnitAddAbility(handle, base.string2id('Aloc'))
	end
	local u = Unit.new(handle, false)
	
	u._is_dummy = true
	
	return u
end

--创建马甲
function Player.__index:create_dummy(name, where, face, is_aloc)
	return Unit.create_dummy(self, name, where, face, is_aloc)
end

--创建召唤物
function Player.__index:create_minion( name, where, face )
	local u = Unit.create(self, name, where, face)
	u._is_minion = true
	return u
end

function mt:event(name)
	return ac.event_register(self, name)
end

mt.wait = ac.uwait
mt.loop = ac.uloop
mt.timer = ac.utimer

mt.double_click_pulse = 0.5

local function register_jass_triggers()
	--单位发布指定目标事件
	local j_trg = War3.CreateTrigger(function()
		local u = Unit(jass.GetTriggerUnit())
		if not u then
			return
		end
		local j_target = jass.GetOrderTargetUnit()
		if not j_target or j_target == 0 then
			return
		end

		local order = jass.GetIssuedOrderId()
		local target
		target = Unit(j_target)
		u:event_notify('单位-发布指令', u, id2order[order], target, order)
		target:event_notify('单位-被指向', target, id2order[order], u, order)
	end)
	for i = 1, 16 do
		jass.TriggerRegisterPlayerUnitEvent(j_trg, Player[i].handle, jass.EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER, nil)
	end

	--单位发布点目标事件
	local j_trg = War3.CreateTrigger(function()
		local u = Unit(jass.GetTriggerUnit())
		if not u then
			return
		end
		local order = jass.GetIssuedOrderId()
		if u._last_point_order_id == order then
			u:event_notify('单位-发布双击指令', u, id2order[order], Point:new(jass.GetOrderPointX(), jass.GetOrderPointY()), order)
		end
		u._last_point_order_id = order
		ac.wait(u.double_click_pulse*1000, function (  )
			u._last_point_order_id = nil
		end)
		u:event_notify('单位-发布指令', u, id2order[order], Point:new(jass.GetOrderPointX(), jass.GetOrderPointY()), order)
	end)
	for i = 1, 16 do
		jass.TriggerRegisterPlayerUnitEvent(j_trg, Player[i].handle, jass.EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER, nil)
	end

	--单位发布无目标事件
	local j_trg = War3.CreateTrigger(function()
		local j_handle = jass.GetTriggerUnit()
		local order = jass.GetIssuedOrderId()
		local u = Unit(j_handle)
		if not u then
			return
		end
		u:event_notify('单位-发布指令', u, id2order[order], nil, order)
	end)
	for i = 1, 16 do
		jass.TriggerRegisterPlayerUnitEvent(j_trg, Player[i].handle, jass.EVENT_PLAYER_UNIT_ISSUED_ORDER, nil)
	end

	--单位攻击事件
	local j_trg = War3.CreateTrigger(function()
		local source = Unit(jass.GetAttacker())
		if not source then
			--此时可能由某些war3技能引起的攻击事件，例如刀阵旋风
			return
		end
		local target = Unit(jass.GetTriggerUnit())
		source:set_active()
		target:set_active()
		source:event_notify('单位-攻击', source, target)
		target:event_notify('单位-被攻击', target, source)
	end)
	for i = 1, 16 do
		jass.TriggerRegisterPlayerUnitEvent(j_trg, Player[i].handle, jass.EVENT_PLAYER_UNIT_ATTACKED, nil)
	end

	--单位死亡事件
	local j_trg = War3.CreateTrigger(function()
		local u = Unit(jass.GetTriggerUnit())
		local killer = Unit(jass.GetKillingUnit())

		if not killer then
			--此时凶手已经被移除
			return
		end
		
		--不需要初始化马甲，因为在伤害模块已经还原了
		if killer._is_damage_dummy then
			killer = killer.damage.source
		end
		
		u:killed(killer)
	end)
	for i = 1, 16 do
		jass.TriggerRegisterPlayerUnitEvent(j_trg, Player[i].handle, jass.EVENT_PLAYER_UNIT_DEATH, nil)
	end

	--单位召唤事件
	local j_trg = War3.CreateTrigger(function()
		local summoned_handle = jass.GetSummonedUnit()
		_last_summoned_unit = summoned_handle
		if not summoned_handle then
			--分身技能会导致两次召唤事件，第一次是无效的
			return
		end
		summoned = Unit(summoned_handle)
		summoned._is_minion = true
		local summoning = Unit(jass.GetSummoningUnit())
		summoned:event_notify( '单位-被召唤', summoned, summoning)
		summoning:event_notify( '单位-召唤', summoning, summoned)
	end)
	for i = 0, 15 do
		jass.TriggerRegisterPlayerUnitEvent(j_trg, jass.Player(i), jass.EVENT_PLAYER_UNIT_SUMMON, nil)
	end

	--单位出售单位事件
	local j_trg = War3.CreateTrigger(function()
		local handle = jass.GetSoldUnit()
		local shop = Unit(jass.GetTriggerUnit())
		local unit = Unit(jass.GetBuyingUnit())
		local id = base.id2string(jass.GetUnitTypeId(handle))
		local name = Registry:id_to_name('unit', id)

		local button = Unit_button:new(name, unit, shop)
		if button then
			button:click()
			jass.RemoveUnit(handle)
			return
		end
		local sold_unit = Unit(handle)
		unit:event_notify('单位-购买单位', unit, sold_unit, shop)
		shop:event_notify('单位-出售单位', shop, sold_unit, unit)
	end)
	for i = 1, 16 do
		jass.TriggerRegisterPlayerUnitEvent(j_trg, Player[i].handle, jass.EVENT_PLAYER_UNIT_SELL, nil)
	end

	--玩家选择单位
	local j_trg = War3.CreateTrigger(function()
		local unit = Unit(jass.GetTriggerUnit())
		local player = Player[jass.GetTriggerPlayer()]
		if player._last_select_unit == unit then
			player:event_notify('玩家-双击单位', player, unit)
			unit:event_notify('单位-被双击', unit, player)
			player._last_select_unit = nil
		else
			player._last_select_unit = unit
			ac.wait(500, function()
				player._last_select_unit = nil
			end)
			player:event_notify('玩家-选择单位', player, unit)
			unit:event_notify('单位-被选择', unit, player)
		end
		player.selecting_unit = unit
	end)
	for i = 1, 16 do
		jass.TriggerRegisterPlayerUnitEvent(j_trg, Player[i].handle, jass.EVENT_PLAYER_UNIT_SELECTED, nil)
	end

	--玩家取消选择单位
	local j_trg = War3.CreateTrigger(function()
		local unit = Unit(jass.GetTriggerUnit())
		local player = Player[jass.GetTriggerPlayer()]
		player:event_notify('玩家-取消选择单位', player, unit)
		unit:event_notify('单位-被取消选择', unit, player)
		player.selecting_unit = nil
		player.last_selected_unit = unit
	end)
	for i = 1, 16 do
		jass.TriggerRegisterPlayerUnitEvent(j_trg, Player[i].handle, jass.EVENT_PLAYER_UNIT_DESELECTED, nil)
	end
	
end


local _ac_dummy_id = config.SYS_AC_UNIT_DUMMY_ID
--创建单位马甲
function create_ac_dummy()
	ac.dummy = Unit.create(Player[16], _ac_dummy_id, Point:new(0, 0))
end

local function register_unit(self, name, data)
	local war3_id = data.war3_id
	if not war3_id or war3_id == '' then
		Log.error(('注册%s单位时，不能没有war3_id'):format(name) )
		return
	end
	
	Registry:register('unit', name, war3_id)
	
	setmetatable(data, data)
	data.__index = Unit

	local unit = {}
	setmetatable(unit, unit)
	unit.__index = data
	unit.__call = function(self, data)
		self.data = data
		return self
	end
	unit.name = name
	unit.data = data
	self[name] = unit
	self[war3_id] = unit
	return unit
end

--初始化
local function init()
	--全局单位索引
	Unit.all_units = {}

	ac.unit = setmetatable({}, {__index = function(self, name)
		return function(data)
			return register_unit(self, name, data)
		end
	end})

	--注册事件
	register_jass_triggers()

	--更新单位数据
	Unit.frame = 8
	ac.loop(1000 / Unit.frame, function()
		for _, u in pairs(Unit.all_units) do
			u:update()
		end
	end)

	--创建dummy
	create_ac_dummy()
end

init()

return Unit
