
local slk = require 'jass.slk'
local jass = require 'jass.common'
local dbg = require 'jass.debug'
local skill = require 'Libraries.types.skill'
local table = table
local japi = require 'jass.japi'
local runtime = require 'jass.runtime'
local Player = require 'Libraries.ac.player'
local Unit = require 'Libraries.types.unit'
local setmetatable = setmetatable
local xpcall = xpcall
local select = select
local error_handle = runtime.error_handle

local Item = {}
setmetatable(Item, Item)

local mt = {}
Item.__index = mt

mt.id = 0

--类型
mt.type = 'item'

--物品分类
mt.item_type = '无'

--物品等级
mt.level = 1

--价格
mt.gold = 0

--物品所在的格子,1-6
mt.slotid = nil

--物品是否唯一
mt.unique = false

--物品创建时间
mt.create_time = nil

--类型
mt.slot_type = '物品'

--当前使用者,指单位
mt.owner = nil

--原始拥有者
mt.player = nil

--系统丢弃物品标志
--该状态时，不应该执行获得、失去、移动物品的逻辑
local drop_flag = false

local dummy_id = Base.string2id 'ches'

--格子，1-6
function Unit.__index:get_slot_item(slotid)
	local handle = jass.UnitItemInSlot(self.handle, slotid-1)
	return Item(handle)
end

function Item.new(handle)
	
	if handle == 0 then
		return nil
	end
	local war3_id = Base.id2string(jass.GetItemTypeId(handle))
	local name = jass.GetItemName(handle)
	local data = ac.item[war3_id] 
	if type(data) == 'function' then
		data = ac.item[name]
	end
	if type(data) ~= 'type' then
		data = Item
	end
	local it = {}
	setmetatable(it, it)
	it.__index = data
	it.handle = handle
	it.id = war3_id
	it.war3_id = war3_id
	it.player = p or Player[jass.GetItemPlayer(handle)]

	--保存到全局物品表中
	Item.all_items[handle] = it
	
	return it
end

--根据句柄获取物品，对外唯一接口
function Item:__call(handle)
	if not handle or handle == 0 then
		return nil
	end
	local it = Item.all_items[handle]
	if not it then
		it = Item.new(handle)
	end
	return it
end

function Item.get_slk_by_id(id, name, default)
	local item_data = slk.item[id]
	if not item_data then
		Log.error('物品数据未找到', id)
		return default
	end
	local data = item_data[name]
	if data == nil then
		return default
	end
	if type(default) == 'number' then
		return tonumber(data) or default
	end
	return data
end

function mt:get_slk(name, default)
	return Item.get_slk_by_id(self.id, name, default)
end

--获取物品的物编id
function mt:get_id()
	if not self.id then
		self.id = jass.GetItemTypeId(self.handle)
	end
	return self.id
end

--需要修改
local function add_item_slot(skill, slotid)
	if skill.removed or not skill.item_id then
		return false
	end
	local u = skill.owner
	if not u:is_alive() then
		u:event '单位-复活' (function(trg)
			trg:remove()
			add_item_slot(skill, slotid)
		end)
		return false
	end
	local j_its = {}
	for i = 1, slotid - 1 do
		--创建占位物品
		if jass.UnitItemInSlot(u.handle, i - 1) == 0 then
			local j_it = jass.CreateItem(dummy_id, 0, 0)
			dbg.handle_ref(j_it)
			jass.UnitAddItem(u.handle, j_it)
			table.insert(j_its, j_it)
		end
	end
	local res = jass.UnitAddItem(u.handle, skill.handle)
	--移除占位物品
	for i = 1, #j_its do
		jass.RemoveItem(j_its[i])
		dbg.handle_unref(j_its[i])
	end
	if res then
		skill._in_slot = true
		return true
	else
		u:wait(100, function()
			add_item_slot(skill, slotid)
		end)
		return false
	end
end

function mt:is_removed()
	return self.removed
end

--删除物品
function mt:remove()
	if not self.removed then
		return
	end
	self.removed = true
	self._in_slot = false
	self.id = nil
	jass.RemoveItem(self.handle)
	dbg.handle_unref(self.handle)
	Item[self.handle] = nil
	self.handle = nil
end

--卖出物品给钱
function mt:sell()
	self:remove()
end

function mt:get_gold()
	return self:get_slk('goldcost')
end

function mt:get_lumber()
	return self:get_slk('lumbercost')
end

--获取使用次数
function mt:get_stack()
	return jass.GetItemCharges(self.handle)
end

--设置使用次数
function mt:set_stack(count)
	jass.SetItemCharges(self.handle, count)
end

--增加使用次数
function mt:add_stack(count)
	jass.SetItemCharges(self.handle, jass.GetItemCharges(self.handle) + (count or 1))
end

function mt:is_visible()
	return not self.removed and self._in_slot and not self.owner:is_illusion()
end

function mt:fresh()
	if not self:is_visible() then
		return
	end
	if not self.owner:is_alive() then
		self._wait_fresh_item = true
		return
	end
	local u = self.owner
	local slotid = self.slotid
	drop_flag = true
	jass.SetItemPosition(self.handle, 0, 0)
	local j_its = {}
	for i = 1, slotid - 1 do
		--创建占位物品
		if jass.UnitItemInSlot(u.handle, i - 1) == 0 then
			local j_it = jass.CreateItem(dummy_id, 0, 0)
			dbg.handle_ref(j_it)
			jass.UnitAddItem(u.handle, j_it)
			table.insert(j_its, j_it)
		end
	end
	jass.UnitAddItem(u.handle, self.handle)
	--移除占位物品
	for i = 1, #j_its do
		jass.RemoveItem(j_its[i])
		dbg.handle_unref(j_its[i])
	end
	drop_flag = false
end

--显示冷却时间
function mt:set_show_cd(cool, max_cool)
	if not self:is_visible() then
		return
	end
	local _max_cool, _cool = self.skill:get_show_cd()
	local cool = cool or _cool
	local max_cool = max_cool or _max_cool
	if self.skill then
		if max_cool then
			japi.EXSetAbilityDataReal(self.skill:get_handle(), 1, 0x69, max_cool)
		end
		japi.EXSetAbilityState(self.skill:get_handle(), 0x01, cool)
		if max_cool then
			japi.EXSetAbilityDataReal(self.skill:get_handle(), 1, 0x69, 0)
		end
	end
end

function mt:get_slotid(is_force)
	if self:is_removed() then
		return nil
	end
	if not self.slotid or is_force then
		if not self.owner then
			self.slotid = -1
			return -1
		end
		for i = 0, 5 do
			if jass.UnitItemInSlot(self.owner.handle, i) == self.handle then
				self.slotid = i+1
				break
			end
		end
	end
	return self.slotid
end

function mt:get_owner()
	return self.owner
end

function mt:get_player()
	if not self.player then
		self.player = jass.GetItemPlayer(self.handle)
	end
	return self.player
end

function mt:set_player(dest)
	local player = dest
	if dest.type == 'unit' then
		player = dest:get_owner()
	end
	jass.SetItemPlayer(self.handle, player.handle)
end

--获取说明
function mt:get_tip()
	return self:get_slk('Ubertip')
end

--获取名称
function mt:get_title()
	return self:get_slk('name')
end

function mt:set_tip(tip, player)
	if player then
		if Player.self == player then
			japi.EXSetItemDataString(Base.string2id(self.id), 3, tip)
		end
	else
		japi.EXSetItemDataString(Base.string2id(self.id), 3, tip)
	end
end

function mt:set_title(title)
	if player then
		if Player.self == player then
			japi.EXSetItemDataString(Base.string2id(self.id), 4, tip)
		end
	else
		japi.EXSetItemDataString(Base.string2id(self.id), 4, tip)
	end
end

--设置物品图标
function mt:set_art(art)
	if player then
		if Player.self == player then
			japi.EXSetItemDataString(Base.string2id(self.id), 1, art)
		end
	else
		japi.EXSetItemDataString(Base.string2id(self.id), 1, art)
	end
	self:fresh()
end

--设置可丢弃性
function mt:set_dropable(drop)
	if drop == nil then
		drop = true
	end
	self._is_dropable = drop
	jass.SetItemDroppable(self.handle, drop)
end

function mt:get_dropable()
	return self._is_dropable and true
end

function mt:is_owned()
	return jass.IsItemOwned(self.handle)
end

--物品的通用属性
--生命、魔法、攻击、攻速、防御、移速、三维属性、技能
function mt:on_add_attribute()
	local unit = self.owner

	if self.life then
		unit:add_max_life(self.life)
	end

	if self.mana then
		unit:add_max_mana(self.mana)
	end

	if self.attack then
		unit:add_add_attack(self.attack)
	end

	if self.attack_speed then
		unit:add_attack_speed(self.attack_speed)
	end

	if self.defence then
		unit:add_defence(self.defence)
	end

	if self.move_speed then
		local max_speed = 0
		local sum_speed = 0
		for i = 0, 5 do
			local handle = jass.UnitItemInSlot(unit.handle, i)
			local it = Item(handle)
			if it.is_move_speed_overlay then
				sum_speed = sum_speed + it.move_speed
			else
				if max_speed < it.move_speed then
					max_speed = it.move_speed
				end
			end
		end
		unit._item_move_speed = max_speed + sum_speed
		unit:add_move_speed(unit._item_move_speed)
	end

	if self.str then
		if unit:is_hero() then
			unit:add_add_str(self.str)
		end
	end

	if self.agi then
		if unit:is_hero() then
			unit:add_add_agi(self.agi)
		end
	end

	if self.int then
		if unit:is_hero() then
			unit:add_add_int(self.int)
		end
	end

	if it.skills then
		if type(it.skills) == 'string' then
			for name in it.skills:gmatch('%S+') do
				local skl = ac.skill[name]
				if skl then
					unit:add_skill(skl, '物品')
				else
					Log.error(('物品%s的skills字段存在没初始化的技能%s(被添加的)，请检查！！'):format(self:get_title(), name))
				end
			end
		else
			Log.error(('物品%s的skills字段不为字符串，请检查！！'):format(self:get_title()))
		end
	end

end

function mt:on_remove_attribute()
	local unit = self.owner

	if self.life then
		unit:add_max_life(-self.life)
	end

	if self.mana then
		unit:add_max_mana(-self.mana)
	end

	if self.attack then
		unit:add_add_attack(-self.attack)
	end

	if self.attack_speed then
		unit:add_attack_speed(-self.attack_speed)
	end

	if self.defence then
		unit:add_defence(-self.defence)
	end

	if self.move_speed then
		unit:add_move_speed(-unit._item_move_speed)
		local max_speed = 0
		local sum_speed = 0
		for i = 0, 5 do
			local handle = jass.UnitItemInSlot(unit.handle, i)
			local it = Item(handle)
			if it.is_move_speed_overlay then
				sum_speed = sum_speed + it.move_speed
			else
				if max_speed < it.move_speed then
					max_speed = it.move_speed
				end
			end
		end
		unit._item_move_speed = max_speed + sum_speed
		unit:add_move_speed(unit._item_move_speed)
	end

	if self.str then
		if unit:is_hero() then
			unit:add_add_str(-self.str)
		end
	end

	if self.agi then
		if unit:is_hero() then
			unit:add_add_agi(-self.agi)
		end
	end

	if self.int then
		if unit:is_hero() then
			unit:add_add_int(-self.int)
		end
	end

	if it.skills then
		if type(it.skills) == 'string' then
			for name in it.skills:gmatch('%S+') do
				local skl = ac.skill[name]
				if skl then
					unit:remove_skill(skl)
				else
					Log.error(('物品%s的skills字段存在没初始化的技能%s(被移除的)，请检查！！'):format(self:get_title(), name))
				end
			end
		else
			Log.error(('物品%s的skills字段不为字符串，请检查！！'):format(self:get_title()))
		end
	end

end


--获得物品,加成属性
function mt:on_adding()
	if self.on_add_before then
		self:on_add_before()
	end

	self:on_add_attribute()

	if self.on_add then
		self:on_add()
	end
end

--失去物品,减少属性
function mt:on_dropping()
	if self.on_drop then
		self:on_drop()
	end

	self:on_remove_attribute()

	if self.on_drop_after then
		self:on_drop_after()
	end
end

--使用物品
function mt:on_using()
	if self.on_use then
		self:on_use()
	end
end

ac.game:event '单位-失去物品' (function(trg, unit, it)
	if it.removed then
		return
	end
	it.owner = nil
	it.last_owner = unit
	it:on_dropping()
end)


ac.game:event '单位-获得物品' (function(trg, unit, it)
	if it.removed then
		return
	end
	it.owner = unit
	it:on_adding()
end)

ac.game:event '单位-使用物品' (function(trg, unit, it)
	if it.removed then
		return
	end
	it.owner = unit
	it:on_using()
end)

--监听在物品栏中移动物品
ac.game:event '单位-发布指令' (function(trg, hero, order, target, order_id)
	local slotid = order_id - 852001
	if slotid >= 1 and slotid <= 6 and not drop_flag then
		local j_it = jass.GetOrderTargetItem()
		local it = Item(j_it)
		--原地移动物品(右键双击)
		if it.slotid == slotid then
			hero:event_notify('单位-右键双击物品', hero, it)
			return
		end
		local last_slotid = it.slotid
		it.slotid = slotid
		local dest = jass.UnitItemInSlot(hero.handle, last_slotid)

		hero:event_notify('单位-移动物品', hero, it)
		if dest then
			hero:event_notify('单位-移动物品', hero, dest)
		end

	end
end)

--获得物品、捡起物品
local j_trg = War3.CreateTrigger(function()
	if drop_flag then
		return
	end
	local unit = Unit(jass.GetTriggerUnit())
	local it = Item(GetManipulatedItem())
	unit:event_notify('单位-获得物品', unit, it)
end)
for i = 1, 16 do
	jass.TriggerRegisterPlayerUnitEvent(j_trg, Player[i].handle, jass.EVENT_PLAYER_UNIT_PICKUP_ITEM, nil)
end

--失去物品、丢弃物品
local j_trg = War3.CreateTrigger(function()
	if drop_flag then
		return
	end
	local unit = Unit(jass.GetTriggerUnit())
	local it = Item(jass.GetManipulatedItem())
	unit:event_notify('单位-失去物品', unit, it)
end)
for i = 1, 16 do
	jass.TriggerRegisterPlayerUnitEvent(j_trg, Player[i].handle, jass.EVENT_PLAYER_UNIT_DROP_ITEM, nil)
end

--失去物品
local j_trg = War3.CreateTrigger(function()
	if drop_flag then
		return
	end
	local unit = Unit(jass.GetTriggerUnit())
	local it = Item(jass.GetSoldItem())
	local shop = Unit(jass.GetBuyingUnit())
	ac.wait(0, function()
		unit:event_notify('单位-失去物品', unit, it)
		unit:event_notify('单位-抵押物品', unit, it, shop)
		shop:event_notify('单位-收购物品', shop, it, unit)
		it:remove()
	end)
end)
for i = 1, 16 do
	jass.TriggerRegisterPlayerUnitEvent(j_trg, Player[i].handle, jass.EVENT_PLAYER_UNIT_PAWN_ITEM, nil)
end

--获得物品、购买物品
local j_trg = War3.CreateTrigger(function()
	if drop_flag then
		return
	end
	local unit = Unit(jass.GetBuyingUnit())
	local it = Item(jass.GetSoldItem())
	local shop = Unit(jass.GetSellingUnit())
	it:set_player(unit)
	unit:event_notify('单位-获得物品', unit, it)
	unit:event_notify('单位-购买物品', unit, it, shop)
	shop:event_notify('单位-出售物品', shop, it, unit)
end)
for i = 1, 16 do
	jass.TriggerRegisterPlayerUnitEvent(j_trg, Player[i].handle, jass.EVENT_PLAYER_UNIT_SELL_ITEM, nil)
end

--使用物品
local j_trg = War3.CreateTrigger(function()
	local unit = Unit(jass.GetTriggerUnit())
	local it = Item(jass.GetManipulatedItem())
	unit:event_notify('单位-使用物品', unit, it)
end)
for i = 1, 16 do
	jass.TriggerRegisterPlayerUnitEvent(j_trg, Player[i].handle, jass.EVENT_PLAYER_UNIT_USE_ITEM, nil)
end

--注册物品
local function register_item(self, data)
	self.has_inited = true
	if not data then
		data = {}
	end
	self.data = data
	for k, v in pairs(data) do
		self[k] = v
	end
	if data.war3_id then
		ac.item[data.war3_id] = self
	end
	setmetatable(self, self)
	self.__index = Item
	return self
end

local registered_items = {}
local function init()

	Item.all_items = {}

	ac.item = setmetatable({}, {__index = function(self, name)
		if registered_items[name] then
			Log.error(('物品%s已经被注册，不应该重复注册！'):format(name))
			return
		end
		registered_items[name] = true
		self[name] = {}
		self[name].name = name
		return function(data)
			return register_item(self[name], data)
		end
	end})

end

init()

return item