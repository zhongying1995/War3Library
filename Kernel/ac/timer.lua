local setmetatable = setmetatable
local ipairs = ipairs
local pairs = pairs
local table_insert = table.insert
local math_max = math.max
local math_floor = math.floor

local cur_frame = 0
local max_frame = 0
local cur_index = 0
local free_queue = {}
local timer = {}
--初始化一个时刻的回调表
local function alloc_queue()
	local n = #free_queue
	if n > 0 then
		local r = free_queue[n]
		free_queue[n] = nil
		return r
	else
		return {}
	end
end
--让目标时刻的表队列的末尾，插入自己
local function m_timeout(self, timeout)
	local ti = cur_frame + timeout
	local q = timer[ti]
	if q == nil then
		q = alloc_queue()
		timer[ti] = q
	end
	self.timeout_frame = ti
	q[#q + 1] = self
end

local function m_wakeup(self)
	if self.removed then
		return
	end
	--执行callback
	self:on_timer()
	if self.removed or self.pause_remaining then
		return
	end
	if self.timeout then
		--让当前的动作，插到timeout时刻后
		--同时timeout作为标志，是否重复执行下一步
		m_timeout(self, self.timeout)
	else
		self.removed = true
	end
end

local function on_tick()
	local q = timer[cur_frame]
	if q == nil then
		cur_index = 0
		return
	end
	--cur_index用来补帧
	for i = cur_index + 1, #q do
		local callback = q[i]
		cur_index = i
		--释放callback
		q[i] = nil
		if callback then
			m_wakeup(callback)
		end
	end
	cur_index = 0
	--释放当前时刻的表
	timer[cur_frame] = nil
	free_queue[#free_queue + 1] = q
end

function ac.clock()
	return cur_frame
end

function ac.timer_size()
	local n = 0
	for _, ts in pairs(timer) do
		n = n + #ts
	end
	return n
end

local jass = require 'jass.common'
local jtimer = jass.CreateTimer()
require('jass.debug').handle_ref(jtimer)
jass.TimerStart(jtimer, 0.01, true, function ()
	local delta = 10
	if cur_index ~= 0 then
		--[[上一帧还没有完全执行完
		只是一种健壮性补全，实际一般用不到
		cur_frame回滚一帧
		--]]
		cur_frame = cur_frame - 1
	end
	max_frame = max_frame + delta
	while cur_frame < max_frame do
		cur_frame = cur_frame + 1
		on_tick()
	end
end)


local mt = {}
local api = {}
mt.__index = api
mt.type = 'timer'

function api:remove()
	self.removed = true
end

function api:get_remaining()
	if self.removed then
		return 0
	end
    if self.pause_remaining then
        return self.pause_remaining
    end
    if self.timeout_frame == cur_frame then
        return self.timeout or 0
    end
    return self.timeout_frame - cur_frame
end

function api:pause()
	self.pause_remaining = self:get_remaining()
	local ti = self.timeout_frame
	local q = timer[ti]
	if q then
		for i= #q, 1, -1 do
			if q[i] == self then
				q[i] = false
				return
			end
		end
	end
end

function api:resume()
	if self.pause_remaining then
		m_timeout(self, self.pause_remaining)
		self.pause_remaining = nil
	end
end

function ac.wait(timeout, on_timer)
	local timeout = math_max(math_floor(timeout) or 1, 1)
	local t = setmetatable({
		['on_timer'] = on_timer,
	}, mt)
	m_timeout(t, timeout)
	return t
end
--on_timer就是callback
--无限循环
function ac.loop(timeout, on_timer)
	local t = setmetatable({
		['timeout'] = math_max(math_floor(timeout) or 1, 1),
		['on_timer'] = on_timer,
	}, mt)
	m_timeout(t, t.timeout)
	return t
end
--count代表次数
function ac.timer(timeout, count, on_timer)
	if count == 0 then
		return ac.loop(timeout, on_timer)
	end
	local t = ac.loop(timeout, function(t)
		--on_timer里面的t是干嘛的？从使用的角度，并没有看到哪里会
		--调用
		on_timer(t)
		count = count - 1
		if count <= 0 then
			t:remove()
		end
	end)
	return t
end

local function utimer_initialize(u)
	if not u._timers then
		u._timers = {}
	end
	if #u._timers > 0 then
		return
	end
	u._timers[1] = ac.loop(10000, function()
		local timers = u._timers
		for i = #timers, 2, -1 do
			if timers[i].removed then
				local len = #timers
				timers[i] = timers[len]
				timers[len] = nil
			end
		end
		if #timers == 1 then
			timers[1]:remove()
			timers[1] = nil
		end
	end)
end

function ac.uwait(u, timeout, on_timer)
	utimer_initialize(u)
	local t = ac.wait(timeout, on_timer)
	table_insert(u._timers, t)
	return t
end

function ac.uloop(u, timeout, on_timer)
	utimer_initialize(u)
	local t = ac.loop(timeout, on_timer)
	table_insert(u._timers, t)
	return t
end

function ac.utimer(u, timeout, count, on_timer)
	utimer_initialize(u)
	local t = ac.timer(timeout, count, on_timer)
	table_insert(u._timers, t)
	return t
end
