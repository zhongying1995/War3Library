
local jass = require 'jass.common'
local japi = require 'jass.japi'
local dbg = require 'jass.debug'
local Point = require 'libraries.ac.point'
local Player = require 'libraries.ac.player'
local Unit = require 'libraries.types.unit'
local math = math
local table_insert = table.insert

local Effect = {}
setmetatable(Effect, Effect)

--结构
local mt = {}
Effect.__index = mt

--类型
mt.type = 'effect'

--句柄
mt.handle = 0

--模型
mt.model = ''

--单位(unit - 绑定在单位身上)
mt.unit = nil

--部位(字符串 - 绑在单位身上的哪个位置)
mt.socket = nil

--点(创建在哪个点上)
mt.point = nil

--内置马甲
Effect.DUMMY_ID = 'nalb'


--创建在地上
--	模型路径
--	表数据
function Point.__index:add_effect(model, data)
	local ang = 270
	local eff = setmetatable({}, Effect)
	if data and type(data) == 'table' then
		ang = data.angle
		japi.EXSetUnitString(Base.string2id(effect.UNIT_ID), 13, model)
		local dummy = Unit.create_dummy(Player(16), Effect.DUMMY_ID, self, angle)
		eff.dummy = dummy
	else
		local x, y = self:get()
		local j_eff = jass.AddSpecialEffect(model, x, y)
		eff.point = self
		eff.handle = j_eff
	end
	eff.model = model
	return eff
end

function Unit.__index:add_effect(model, socket)
	local socket = socket or 'origin'
	local j_eff = jass.AddSpecialEffectTarget(model, self.handle, socket)
	dbg.handle_ref(j_eff)
	local eff = setmetatable({handle = j_eff}, Effect)
	eff.model = model
	eff.unit = self
	if not self._effect_list then
		self._effect_list = {}
	end
	table_insert(self._effect_list, eff)
	return eff
end

--设置动画
function mt:set_animation(name)
	if self.dummy then
		self._has_animation = true
		self.dummy:set_animation(name)
		return true
	end
	return false
end

--设置缩放
function mt:set_size(size)
	if self.dummy then
		self.dummy:set_size(size)
	elseif( type(size) == 'table') then
		japi.EXEffectMatScale(self.handle, size[1] or 1, size[2] or 1, size[3] or 1)
	else
    	japi.EXSetEffectSize(self.handle, size)
	end
end

function mt:rotate_x(val)
	if self.handle then
		japi.EXEffectMatRotateX(self.handle, val)
	end
end

function mt:rotate_y(val)
	if self.handle then
		japi.EXEffectMatRotateY(self.handle, val)
	end
end

function mt:rotate_z(val)
	if self.handle then
		japi.EXEffectMatRotateZ(self.handle, val)
	end
end

function mt:reset()
	if self.handle then
		japi.EXEffectMatReset(self.handle)
	end
end

function mt:move(point)
	if self.handle then
		local x, y = point:get()
		japi.EXSetEffectXY(self.handle, x, y)
	end
end

--设置速度
function mt:set_speed(speed)
	if self.dummy then
		self.dummy:set_animation_speed(speed)
	else
		japi.EXSetEffectSpeed(self.handle, speed)
	end
end

--设置高度
function mt:set_height(height)
	if self.dummy then
		self.dummy:set_high(height)
	else
		japi.EXSetEffectZ(self.handle, height)
	end
end

--设置透明
function mt:set_alpha(alpha)
	if self.dummy then
		self.dummy:set_alpha(alpha)
	end
end

--移除
function mt:remove()
	if self.removed then
		return
	end
	self.removed = true
	
	if self.handle then
		jass.DestroyEffect(self.handle)
		dbg.handle_unref(self.handle)
		self.handle = nil
	end

	if self.dummy then
		self.dummy:show(false)
		self.dummy:remove()
	end

	--从单位身上删除记录
	if self.unit then
		for i, v in ipairs(self.unit._effect_list) do
			if v == self then
				table.remove(self.unit._effect_list, i)
				break
			end
		end
	end
end

function mt:kill()
	return self:remove()
end

return Effect
