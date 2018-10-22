local jass = require 'jass.common'
local Player = require 'war3library.libraries.ac.player'

local Multiboard = {}
setmetatable(Multiboard, Multiboard)

--结构
local mt = {}
Multiboard.__index = mt

--类型
mt.type = 'multiboard'

--句柄
mt.handle = 0

--列数
mt.x = 0

--行数
mt.y = 0

--修改列数
function mt:set_x(x)
	jass.MultiboardSetColumnCount(self.handle, x)
	self.x = x
	return self
end

--修改行数
function mt:set_y(y)
	jass.MultiboardSetRowCount(self.handle, y)
	self.y = y
	return self
end

--修改标题文字
function mt:set_title(title)
	jass.MultiboardSetTitleText(self.handle, title)
	return self
end

--显示多面板
--	单独的某玩家，默认所有玩家
function mt:show(player)
	if player and player == Player.self then
		jass.MultiboardDisplay(self.handle, true)
	end
	if not player then
		jass.MultiboardDisplay(self.handle, true)
	end
	return self
end

--隐藏多面板
--	单独的某玩家，默认所有玩家
function mt:hide(player)
	if player and player == Player.self then
		jass.MultiboardDisplay(self.handle, false)
	end
	if not player then
		jass.MultiboardDisplay(self.handle, false)
	end
	return self
end

--最小化多面板
function mt:minimize()
	jass.MultiboardMinimize(self.handle, true)
	return self
end

--最大化多面板
function mt:maximize()
	jass.MultiboardMinimize(self.handle, false)
	return self
end

--获得项目
function mt:get_item(x, y)
	local t = self[x]
	if t then
		return t[y]
	end
	return 0
end

--设置项目图标
function mt:set_icon(x, y, src)
	jass.MultiboardSetItemIcon(self:get_item(x, y), src)
	return self
end

--设置某个Item的文字
function mt:set_text(x, y, txt)
	jass.MultiboardSetItemValue(self:get_item(x, y), txt)
	return self
end

--设置某个Item的图标和文字是否显示
function mt:set_style(x, y, show_txt, show_icon)
	jass.MultiboardSetItemStyle(self:get_item(x, y), show_txt, show_icon)
	return self
end

--设置某个Item的宽度
--	w：宽度采用百分比表示： 1 - 100
function mt:set_width(x, y, w)
	local w = (w or 3) / 100
	jass.MultiboardSetItemWidth(self:get_item(x, y), w)
	return self
end

--设置所有item的style
function mt:set_all_style(show_txt, show_icon)
	jass.MultiboardSetItemsStyle(self.handle ,show_txt, show_icon)
	return self
end

--设置Item的宽度
--	w：宽度采用百分比表示： 1 - 100
function mt:set_all_width(w)
	local w = (w or 3) / 100
	jass.MultiboardSetItemsWidth(self.handle, w)
	self:hide()
	self:show()
	return self
end

--删除多面板
function mt:remove()
	if self.removed then
		return
	end
	self.removed = true
	jass.DestroyMultiboard(self.handle)
end

--创建一个多面板
function Multiboard:new(x, y)
	local mb =	setmetatable({}, self)
	mb.handle = jass.CreateMultiboard()
	mb:set_x(x or 0)
		:set_y(y or 0)
		:show()
		:minimize()

	--保存多面板项目
	for x = 1, x do
		mb[x] = {}
		for y = 1, y do
			mb[x][y] = jass.MultiboardGetItem(mb.handle, y - 1, x - 1)
		end
	end
	
	return mb
end

return Multiboard