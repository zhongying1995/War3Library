
local jass = require 'jass.common'
local debug = require 'jass.debug'
local Rect = require 'libraries.ac.rect'

local Fogmodifier = {}
setmetatable(Fogmodifier, Fogmodifier)

local mt = {}
Fogmodifier.__index = mt

--类型
mt.type = 'fogmodifier'

--句柄
mt.handle = 0

--可见状态
--	1:黑色迷雾
--	2:战争迷雾
--	4:可见

--创建可见度修正器
--	玩家
--	位置
--	可见状态：默认可见
--	[是否共享]：默认共享
--	[是否覆盖单位视野]：默认否
function Fogmodifier:new(p, where, see, share, over)
	--默认可见
	see = see == false and 2 or 4

	--默认共享视野
	share = share ~= false and true or false

	--是否覆盖单位视野
	over = over and true or false
	
	local j_handle
	if where.type == 'rect' then
		j_handle = jass.CreateFogModifierRect(p.handle, see, Rect.j_temp(where), share, over)
	elseif where.type == 'circle' then
		local x, y, r = where:get()
		j_handle = jass.CreateFogModifierRadius(p.handle, see, x, y, r, share, over)
	end
	debug.handle_ref(j_handle)
	jass.FogModifierStart(j_handle)
	return setmetatable({handle = j_handle}, self)
end

--启用修正器
function mt:start()
	jass.FogModifierStart(self.handle)
	return self
end

--暂停修正器
function mt:stop()
	jass.FogModifierStop(self.handle)
	return self
end

--摧毁修正器
function mt:remove()
	jass.DestroyFogModifier(self.handle)
	debug.handle_unref(self.handle)
	self.handle = nil
end

return Fogmodifier