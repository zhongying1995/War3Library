local Point = require 'war3library.libraries.ac.point'

local Circle = {}
setmetatable(Circle, Circle)

--圆形区域结构
local mt = {}
Circle.__index = mt

--类型
mt.type = 'circle'

--圆心
mt.x = 0
mt.y = 0

--半径
mt.r = 0

--获取3个值
function mt:get()
	return self.x, self.y, self.r
end

--获取圆心
function mt:get_point()
	return Point:new(self.x, self.y)
end


function Circle:new(...)
	local x, y, r
	if select('#', ...) == 3 then
		x, y, r = ...
	elseif select('#', ...) == 2 then
		local p
		p, r = ...
		x, y = p:get_point():get()
	end
	return setmetatable({x = x, y = y, r = r}, self)
end

return Circle