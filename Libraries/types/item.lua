
local slk = require 'jass.slk'
local game = require 'types.game'
local jass = require 'jass.common'
local dbg = require 'jass.debug'
local skill = require 'ac.skill'
local table = table
local japi = require 'jass.japi'
local runtime = require 'jass.runtime'
local Player = require 'Libraries.ac.player'
local setmetatable = setmetatable
local xpcall = xpcall
local select = select
local error_handle = runtime.error_handle

local Item = {}
local mt = {}
ac.item = Item

Item.__index = mt
setmetatable(mt, Item)

mt.id = 0

--类型
mt.type = 'item'

--物品分类
mt.item_type = '无'

--物品等级
mt.level = 1

--价格
mt.gold = 0

--附魔价格
mt.enchant_gold = nil

--物品所在的格子
mt.slotid = nil

--物品是否唯一
mt.unique = false

--物品创建时间
mt.create_time = nil

--类型
mt.slot_type = '物品'

local drop_flag = false

local dummy_id = base.string2id 'ches'
local j_items = {}

--根据句柄获取物品
function Item:__call(handle)
	return j_items[handle]
end

function Item.get_slk_by_id(id, name, default)
	local item_data = slk.item[id]
	if not item_data then
		log.error('物品数据未找到', id)
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


--删除物品
function mt:remove()
	if not self.removed then
		return
	end
	self.removed = true
	if self.on_drop then
		self:on_drop()
	end
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
	drop_flag = false
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

function mt:get_slotid()
	return self.slotid 
end

function mt:get_owner()
	if not self.player then
		self.player = jass.GetItemPlayer(self.handle)
	end
	return self.player
end

function mt:set_owner(player)
	jass.GetItemPlayer(player.handle)
end

--获取说明
function mt:get_tip()
	return self:get_slk('Ubertip')
end

function mt:get_title()
	return self:get_slk('name')
end

function mt:set_tip(tip, player)
	if player then
		if Player.self == player then
			japi.EXSetItemDataString(base.string2id(self.id), 3, tip)
		end
	else
		japi.EXSetItemDataString(base.string2id(self.id), 3, tip)
	end
end

function mt:set_title(title)
	if player then
		if Player.self == player then
			japi.EXSetItemDataString(base.string2id(self.id), 4, tip)
		end
	else
		japi.EXSetItemDataString(base.string2id(self.id), 4, tip)
	end
end

--设置物品图标
function mt:set_art(art)
	if player then
		if Player.self == player then
			japi.EXSetItemDataString(base.string2id(self.id), 1, art)
		end
	else
		japi.EXSetItemDataString(base.string2id(self.id), 1, art)
	end
	self:fresh()
end

--设置可丢弃性
function mt:set_dropable(drop)
	if drop == nil then
		drop = true
	end
	jass.SetItemDroppable(self.handle, drop)
end

function mt:is_owned()
	return jass.IsItemOwned(self.handle)
end

--阻止物品丢弃
ac.game:event '单位-丢弃物品' (function(trg, hero, it)
	if it.removed then
		return
	end
	self:on_drop()
end)


--获得物品加成属性
function mt:on_add()
	
end

--失去物品减少属性
function mt:on_drop()
	
end

--监听在物品栏中移动物品
ac.game:event '单位-发布指令' (function(trg, hero, order, target, player_order, order_id)
	local slotid = order_id - 852001
	if slotid >= 1 and slotid <= 6 then
		local j_it = jass.GetOrderTargetItem()
		local it = Item(j_it)
		--原地移动物品(右键双击)
		if it.slotid == slotid then
			hero:event_notify('单位-右键双击物品', hero, it)
			return
		end
		local dest = hero:find_skill(slotid, '物品')
		local last_slot = it:get_slotid()
		hero.skills['物品'][slotid] = it
		hero.skills['物品'][last_slot] = dest
		it.slotid = slotid
		if dest then
			dest.slotid = last_slot
		end
		drop_flag = true
		item.remove(it)
		if dest then
			item.remove(dest)
		end
		drop_flag = false
		item.bind_item(it)
		hero:event_notify('单位-移动物品', hero, it)
		if dest then
			item.bind_item(dest)
			hero:event_notify('单位-移动物品', hero, dest)
		end
		hero:get_owner().shop:fresh()
		if hero:is_hero() then
			log.info(('[%s]移动物品'):format(hero:get_name()))
			for i = 1, 6 do
				local it = hero:find_skill(i, '物品')
				if it then
					log.info(('物品栏[%s][%s][%s]'):format(i, it:get_name(), it.id))
				else
					log.info(('物品栏[%s][nil]'):format(i))
				end
			end
		end
	end
end)


local j_trg = war3.CreateTrigger(function()
	local unit = Unit(jass.GetTriggerUnit())
	local it = Item(GetManipulatedItem())
	unit:event_notify('单位-获得物品', unit, it)
end)
for i = 1, 16 do
	jass.TriggerRegisterPlayerUnitEvent(j_trg, player[i].handle, jass.EVENT_PLAYER_UNIT_PICKUP_ITEM, nil)
end

local j_trg = war3.CreateTrigger(function()
	local unit = Unit(jass.GetTriggerUnit())
	local it = Item(jass.GetManipulatedItem())
	unit:event_notify('单位-失去物品', unit, it)
end)
for i = 1, 16 do
	jass.TriggerRegisterPlayerUnitEvent(j_trg, player[i].handle, jass.EVENT_PLAYER_UNIT_DROP_ITEM, nil)
end

local j_trg = war3.CreateTrigger(function()
	local unit = Unit(jass.GetTriggerUnit())
	local it = Item(jass.GetSoldItem())
	local shop = Unit(jass.GetBuyingUnit())
	unit:event_notify('单位-失去物品', unit, it)
	unit:event_notify('单位-抵押物品', unit, it, shop)
	shop:event_notify('单位-收购物品', shop, it, unit)
end)
for i = 1, 16 do
	jass.TriggerRegisterPlayerUnitEvent(j_trg, player[i].handle, jass.EVENT_PLAYER_UNIT_PAWN_ITEM, nil)
end

local j_trg = war3.CreateTrigger(function()
	local unit = Unit(jass.GetBuyingUnit())
	local it = Item(jass.GetSoldItem())
	local shop = Unit(jass.GetSellingUnit())
	unit:event_notify('单位-获得物品', unit, it)
	unit:event_notify('单位-购买物品', unit, it, shop)
	shop:event_notify('单位-出售物品', shop, it, unit)
end)
for i = 1, 16 do
	jass.TriggerRegisterPlayerUnitEvent(j_trg, player[i].handle, jass.EVENT_PLAYER_UNIT_SELL_ITEM, nil)
end


return item
