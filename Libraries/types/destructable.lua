local jass = require 'jass.common'
local dbg = require 'jass.debug'
local Point = require 'war3library.libraries.ac.point'


local Destructable = {}
setmetatable(Destructable, Destructable)

local mt = {}
Destructable.__index = mt

--现存的所有可破坏物
Destructable.all_destrucables = {}


--根据handle创建可破坏物
function Destructable.new(handle)
    if handle == 0 or not handle then
		return nil
	end
    local war3_id = base.id2string(jass.GetDestructableTypeId(handle))
    local data = ac.destructable[war3_id]
    if type(data) == 'function' then
        data = Destructable
    end

    local dest = {}
    setmetatable(dest, dest)
    dest.__index = data
    dest.handle = handle
    dest.id = war3_id
    dest.war3_id = war3_id
    dest.name = jass.GetDestructableName(handle)

    Destructable.all_destrucables[handle] = dest

    return dest
end

--根据句柄获取可破坏物
function Destructable:__call(handle)
    if not handle or handle == 0 then
		return nil
	end
	local dest = Destructable.all_destrucables[handle]
	if not dest then
		dest = Destructable.new(handle)
	end
	return dest
end


--创建可破坏物
--  可破坏物名字
--  面向角度
--  放缩
--  样式
function Destructable.create_destructable(id, x, y, facing, scale, variation)
    local handle = jass.CreateDestructable(base.string2id(id), x, y, facing or 0, scale or 1, variation or 0)
    dbg:handle_ref(handle)
    local dest = Destructable.new(handle)
    if not dest then
        return
    end
    return dest
end

--删除可破坏物
function mt:remove()
	if not self.removed then
		return
	end
	if self.on_remove then
		self:on_remove()
	end
    self.removed = true
    self._is_alive = false
    self._last_point = Point:new(jass.GetDestructableX(self.handle), jass.GetDestructableY(self.handle))
    jass.RemoveDestructable(self.handle)
	dbg.handle_unref(self.handle)
	Destructable.all_destrucables[self.handle] = nil
	self.handle = nil
end

function mt:open()
    self:killed()
    self:set_animation('death alternate')
end

function mt:close()
    if self:is_alive() then
        self:restore()
    end
end

function mt:killed(  )
    if self.is_alive() then
        jass.KillDestructable(self.handle)
        self._is_alive = false
    end
end

--显示复活效果
function mt:restore( is_show_candy )
    jass.DestructableRestoreLife(self.handle, jass.GetDestructableMaxLife(self.handle), is_show_candy == nil or (is_show_candy and true) )
end

function mt:is_alive(  )
    if self._is_alive == nil then
        self._is_alive = self:get_life() > 0
    end
    return self._is_alive
end

function mt:get_life(  )
    return jass.GetDestructableLife(self.handle)
end

--播放动画
function mt:set_animation( animation )
    jass.SetDestructableAnimation(self.handle, animation)
end

--获取点
function mt:get_point()
    if self.removed then
		return self._last_point:copy()
	else
        return Point:new(jass.GetDestructableX(self.handle), jass.GetDestructableY(self.handle))
	end
end

--在点创建可破坏物
--  可破坏物名字
--  面向角度
--  放缩
--  样式
function Point.__index:add_destructable( name, facing, scale, variation )
    local id = Registry:name_to_id('destructable', name)
    local x, y = self:get()
    local dest = Destructable.create_destructable(id, x, y, facing, scale, variation)
end


return Destructable