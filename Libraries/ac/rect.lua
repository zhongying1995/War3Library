
local jass = require 'jass.common'
local Point = require 'libraries.ac.point'

local Rect = {}
setmetatable(Rect, Rect)

--矩形区域结构
local mt = {}
Rect.__index = mt

--类型
mt.type = 'rect'

--4个数值
mt.minx = 0
mt.miny = 0
mt.maxx = 0
mt.maxy = 0

--获取4个值
function mt:get()
	return self.minx, self.miny, self.maxx, self.maxy
end

--获取点
function mt:get_point()
	return Point.new((self.minx + self.maxx) / 2, (self.miny + self.maxy) / 2)
end


--创建矩形区域
---Rect.new(最小x, 最小y, 最大x, 最大y)
function Rect.new(minx, miny, maxx, maxy)
	return setmetatable({minx = minx, miny = miny, maxx = maxx, maxy = maxy}, Rect)
end

--扩展矩形区域
function Rect:__add(dest)
	local minx0, miny0, maxx0, maxy0 = self:get()
	local minx1, miny1, maxx1, maxy1 = table.unpack(dest)
	return Rect.new(minx0 + minx1, miny0 + miny1, maxx0 + maxx1, maxy0 + maxy1)
end

--转化jass中的矩形区域
Rect.j_rects = {}

function Rect.j_rect(name)
	if not Rect.j_rects[name] then
		local jRect = jass['gg_rct_' .. name]
		Rect.j_rects[name] = Rect.new(jass.GetRectMinX(jRect), jass.GetRectMinY(jRect), jass.GetRectMaxX(jRect), jass.GetRectMaxY(jRect))
	end
	return Rect.j_rects[name]
end

--转化jass中的矩形区域为点
Rect.j_points = {}

function Rect.j_point(name)
	if not Rect.j_points[name] then
		local jRect = jass['gg_rct_' .. name]
		Rect.j_points[name] = Point.new(jass.GetRectCenterX(jRect), jass.GetRectCenterY(jRect))
	end
	return Rect.j_points[name]
end

--获得一个临时的jass区域
function Rect.j_temp(rct)
	jass.SetRect(Rect.dummy, rct:get())
	return Rect.dummy
end

--注册
function Rect.init()
	Rect.MAP = Rect.new(
		jass.GetCameraBoundMinX() - jass.GetCameraMargin(jass.CAMERA_MARGIN_LEFT) + 32,
		jass.GetCameraBoundMinY() - jass.GetCameraMargin(jass.CAMERA_MARGIN_BOTTOM) + 32,
		jass.GetCameraBoundMaxX() + jass.GetCameraMargin(jass.CAMERA_MARGIN_RIGHT) - 32,
		jass.GetCameraBoundMaxY() + jass.GetCameraMargin(jass.CAMERA_MARGIN_TOP) - 32
	)

	Rect.dummy = jass.Rect(0, 0, 0, 0)
end

Rect.init()

return Rect