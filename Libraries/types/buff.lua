
local Unit = require 'war3library.libraries.types.unit'
local dbg = require 'jass.debug'
local table = table
local math = math

local Buff = {}
setmetatable(Buff, Buff)

local mt = {}

Buff.__index = mt

--类型
mt.type = 'buff'

--名字
mt.name = ''

--来源
mt.source = nil

--所有者
mt.target = nil

--共存方式(0 = 不共存,1 = 共存)
mt.cover_type = 0

--最大生效数量(仅用于共存的Buff)
mt.cover_max = 0

--本次持续时间
mt.time = -1

--总持续时间
mt.life_time = 0

--周期
mt.pulse = nil

mt.cycle_timer = nil

--已经循环的次数
mt.pulse_count = 0

--添加时间
mt.add_time = 0

--关联计时器
mt.timer = nil

--buff说明
mt.tip = ''

--获得buff时提示说明
mt.send_tip = false

--是否是正常到期而移除
mt.is_finish = false

--禁用计数
mt.disable_count = 0

--暂停计数
mt.pause_count = 0

--无视暂停
mt.force = false

--暂停
function mt:pause(flag)
	if self.force then
		return
	end
	if flag == nil then
		flag = true
	end
	if flag then
		self.pause_count = self.pause_count + 1
		if self.pause_count == 1 then
			if self.timer then
				self.timer:pause()
			end
			if self.cycle_timer then
				self.cycle_timer:pause()
			end
		end
	else
		self.pause_count = self.pause_count - 1
		if self.pause_count == 0 then
			if self.timer then
				self.timer:resume()
			end
			if self.cycle_timer then
				self.cycle_timer:resume()
			end
		end
	end
end

--设置Buff时间
--	时间
function mt:set_remaining(time_out)
	if time_out < 0 then
		return
	end
	local target_time = ac.clock() / 1000 + time_out
	self.life_time = target_time - self.add_time
	if self.timer then
		self.timer:remove()
	end
	self.timer = self.target:wait(time_out * 1000, function()
		--是否需要补上一跳(计时器误差)
		if self.pulse then
			local target_pulse_count = self.life_time / self.pulse
			if target_pulse_count - 1 == self.pulse_count and self:get_pulse() < 0.1 then
				self.pulse_count = self.pulse_count + 1
				--Log.error('buff on_finish')
				if self.on_pulse then
					self:on_pulse(self.pulse_count)
				end
			end
		end
		self.is_finish = true
		if self.on_finish then
			self:on_finish()
		end
		self:remove()
	end)
end

--获得剩余时间
function mt:get_remaining()
	return math.max(0, self.life_time + self.add_time - ac.clock() / 1000)
end

--设置buff时间
function mt:set_time(time)
	self.time = time
end

--获得buff时间
function mt:get_time()
	return self.time
end

--获得当前循环剩余时间
function mt:get_pulse()
	return self.cycle_timer:get_remaining()
end

--设置循环周期
--	周期
function mt:set_pulse(pulse)
	self.pulse = pulse
end

--获取Buff说明
function mt:get_tip()
	return self.tip:gsub('%%([%w_]*)%%', function(k)
		local value = self[k]
		local tp = type(value)
		if tp == 'function' then
			return value(self)
		end
		return value
	end)
end

--层数
mt.stack_count = 0

--获取buff层数
function mt:get_stack()
	return self.stack_count
end

--设置buff层数
function mt:set_stack(count)
	self.stack_count = count
end

--增加buff层数
function mt:add_stack(count)
	self.stack_count = self.stack_count + (count or 1)
end

--是否是控制状态
function mt:is_control()
	return self.control ~= nil
end

--发送tip
function mt:send_tips(time)
	local p = self.target:get_owner()
	p:send_msg(self.name, time or 60)
	p:send_msg(self:get_tip(), time or 60)
end

--移除buff
function mt:remove()
	if self.removed then
		return
	end
	self.removed = true
	self.target:event_notify('单位-失去状态', self.target, self)
	if self.timer then
		self.timer:remove()
	end

	if self.cycle_timer then
		self.cycle_timer:remove()
	end
	
	--print('buff移除', self.name)
	self.target._buffs[self] = nil
	local new_buff
	if self.cover_type == 1 then
		--可以共存的Buff,查表
		if self.target._buff_list and self.target._buff_list[self.name] then
			local list = self.target._buff_list[self.name]
			for i = 1, #list do
				if self == list[i] then
					table.remove(list, i)
					--进入有效区的buff生效
					if self.cover_max >= i then
						new_buff = list[self.cover_max]
					end
					break
				end
			end
		end
	end
	if self:is_enable() and self.added and self.has_on_add then
		self.added = nil
		self.has_on_add = nil
		if self.on_remove then
			self:on_remove(new_buff)
		end
	end
	if new_buff then
		new_buff:enable()
	end
	self.is_finish = false
end

--buff获得时的回调
mt.on_add = nil

--buff失去时的回调
mt.on_remove = nil

--buff正常到期时的回调
mt.on_finish = nil

--buff在每个周期时的回调
mt.on_pulse = nil

--覆盖同名buff
mt.on_cover = nil


--添加buff
function Unit.__index:add_buff(name, delay)
	return function(bff)
		local data = ac.buff[name]
		if type(data) == 'function' then
			Log.error('未找到buff：', name)
			return
		end

		local bff = bff or {}
		setmetatable(bff, bff)
		bff.__index = data
		if not self._buffs then
			self._buffs = {}
		end

		--初始化数据
		bff.name = bff.name or name
		bff.target = self
		if not bff.source then
			bff.source = self
		end
		if delay then
			ac.timer(delay * 1000, 1, function()
				if bff.removed then
					return
				end
				bff:add()
			end)
			return bff
		else
			return bff:add()
		end
	end
end

--添加
function mt:add()
	if self.removed or self.added then
		return
	end
	self.added = true
	local name = self.name
	

	if self.target:is_enemy(self.source) then
		self.source:set_active(self.target)
		self.target:set_active(self.source)
	end

	if not self.target:is_alive() and not self.keep then
		return
	end

	self.add_time = ac.clock() / 1000

	if self.target:event_dispatch('单位-即将获得状态', self.target, self) then
		return
	end

	if self.cover_type == 0 then
		--不可共存的Buff,只会有一个,直接找到即可
		local this_buff = self.target:find_buff(name)
		if this_buff then
			local result = true
			if this_buff.on_cover then
				result = this_buff:on_cover(self)
			end
			--true表示新Buff覆盖,false表示新Buff添加失败.默认true
			if result then
				this_buff:remove()
			else
				return
			end
		end
	elseif self.cover_type == 1 then
		--可以共存的Buff,查表
		if not self.target._buff_list then
			self.target._buff_list = {}
		end
		if not self.target._buff_list[name] then
			self.target._buff_list[name] = {}
		end
		local list = self.target._buff_list[name]
		for i = 1, #list + 1 do
			local this_buff = list[i]
			if not this_buff then
				--没有其他buff了,就放这吧
				table.insert(list, i, self)
				--如果自己不在有效区内,则禁用
				if self.cover_max ~= 0 and i > self.cover_max then
					self:disable()
				end
				break
			end
			local result = false
			if this_buff.on_cover then
				result = this_buff:on_cover(self)
			end
			--true表示插入到当前位置,否则继续询问
			if result then
				table.insert(list, i, self)
				--如果刚好把原来的buff挤出有效区,则禁用他
				if self.target.cover_max == i then
					this_buff:disable()
				end
				--如果自己不在有效区内,则禁用
				if self.cover_max ~= 0 and i > self.cover_max then
					self:disable()
				end
				break
			end
		end
	end

	--回调buff获得
	--
	--print('获得状态', self.name)
	self.target._buffs[self] = true

	--开启计时器
	--周期buff
	if self.pulse then
		local last_pulse
		local function pulse()
			last_pulse = self.pulse
			self.cycle_timer = self.target:loop(last_pulse * 1000, function(t)
				if self.target then
					--print('buff周期', self.name)
					self.pulse_count = self.pulse_count + 1
					if self.on_pulse and self:is_enable() then
						self:on_pulse(self.pulse_count)
					end

					if self.pulse ~= last_pulse then
						t:remove()
						if not self.removed then
							pulse()
						end
					end

				else
					t:remove()
				end
			end)
		end
		
		pulse()
	end

	if self.time >= 0 then
		self:set_remaining(self.time)
	end

	self.removed = nil

	if self:is_enable() then
		if not self.has_on_add then
			self.has_on_add = true
			if self.on_add then
				self:on_add()
			end
		end

		if self.removed then
			return
		end

		if self.send_tip then
			self:send_tips()
		end

		self.target:event_notify('单位-获得状态', self.target, self)
	end

	if self.target:is_pause_buff() then
		self:pause(true)
	end
	
	return self
end

--是否可用
function mt:is_enable()
	return self.disable_count == 0
end

--允许buff
function mt:enable()
	if not self.target:is_alive() and not self.keep then
		return
	end
	self.disable_count = self.disable_count - 1
	if not self.removed and self.added and self.disable_count == 0 and not self.has_on_add then
		self.has_on_add = true
		if self.on_add then
			self:on_add()
		end
	end
end

--禁用buff
function mt:disable()
	self.disable_count = self.disable_count + 1
	if not self.removed and self.added and self.disable_count == 1 and self.has_on_add then
		self.has_on_add = nil
		if self.on_remove then
			self:on_remove()
		end
	end
end

--遍历单位的buff
--	buff name
function Unit.__index:each_buff( name)
	if not self._buffs then
		return function () end
	end
	local _buffs = {}
	for buff in pairs(self._buffs) do
		_buffs[buff] = true
	end
	if not name then
		return pairs(_buffs)
	end
	local next, s, var = pairs(_buffs)
	return function (s, var)
		while true do
			local r = next(s, var)
			if not r then return nil end
			if r.name == name then return r end
			var = r
		end
	end, s, var
end

--移除buff
function Unit.__index:remove_buff( name)
	if not self._buffs then
		return
	end
	local tbl = {}
	for buff in pairs(self._buffs) do
		if buff.name == name then
			tbl[#tbl + 1] = buff
		end
	end
	for i = 1, #tbl do
		tbl[i]:remove()
	end
end

--找buff
function Unit.__index:find_buff(name)
	if not self._buffs then
		return
	end
	for buff in pairs(self._buffs) do
		if buff.name == name then
			return buff
		end
	end
end

local function register_buff(self, name, data)

	setmetatable(data, data)
	data.__index = Buff
	buff = {}
	setmetatable(buff, buff)
	buff.__index = data
	buff.__call = function(self, data) self.data = data; end
	buff.name = name
	buff.data = data
	
	self[name] = buff
	return self[name]
end

local function init()

	--注册buff
	ac.buff = setmetatable({}, {__index = function (self, name)
		return function(data)
			return register_buff(self, name, data)
		end
	end})
	
end

init()

return Buff