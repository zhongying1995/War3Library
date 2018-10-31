local jass = require 'jass.common'

local Unit_button = {}
setmetatable(Unit_button, Unit_button)


local mt = {}
Unit_button.__index = mt

--点击按钮
function mt:click()
    if self.on_click then
        self:on_click()
    end
    if self.clicker then
        self.clicker:event_notify('单位-点击单位按钮', self.clicker, self)
    end
end

--进行标记
--	标记索引
function mt:set(key, value)
    local parent = self.parent or self
    parent[key] = value
end

--获取标记
--	标记索引
function mt:get(key)
    local parent = self.parent or self
    parent[key] = value
end

--新建一个Unit_button
--  名称（要求已经注册）
--  点击的单位
--  出售的伤害
function mt:new(name, unit, shop)
    local Button = ac.unit_button[name]
    if type(Button) == 'function' then
        return false
    end
    local parent = Button[unit]
    if not parent then
        parent = setmetatable({}, {__index = Button})
        Button[unit] = parent
        parent.is_parent = true
        parent.owner = unit
    end
    local new = setmetatable({}, {__index = parent})
    new.parent = parent
    new.clicker = unit
    new.seller = shop

    if not unit._unit_buttons then
        unit._unit_buttons = {}
    end
    if not unit._unit_buttons[name] then
        unit._unit_buttons[name] = parent
    end

    return new
end

--移除
--其实移除方法没什么必要的，要清除的应该是ac.unit_button[name][unit]
function mt:remove()
    if self.is_parent then
        ac.unit_button[self.name][self.owner] = nil
    end
end

local function register_unit_button(self, name, data)
    if not data.war3_id then
        Log.error(('注册%s 按钮单位时，不能没有war3_id'):format(name) )
		return
    end
    
    Registry:register(name, data.war3_id)

    setmetatable(data, data)
    data.__index = Unit_button

    local button = {}
    setmetatable(button, button)
    button.__index = data
    button.__call = function(self, data)
        self.data = data
        return self
    end
    button.name = name
    button.data = data
    
    self[name] = button
    self[data.war3_id] = button

    return button
end

local function init()
    
    ac.unit_button = setmetatable({}, {__index = function(self, name)
        return function(data)
            return register_unit_button(self, name, data)
        end
    end})

end

init()

return Unit_button