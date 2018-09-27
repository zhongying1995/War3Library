local jass = require 'jass.common'

local Unit_button = {}
setmetatable(Unit_button, Unit_button)


local mt = {}
Unit_button.__index = mt


_UNIT_BUTTON_LIST = {}

function Unit_button.is_unit_button_by_handle(handle)
    local id = Base.id2string(jass.GetUnitTypeId(handle))
    return _UNIT_BUTTON_LIST[id] and true
end

--[[
function Unit_button:new(handle)
    if not self.is_unit_button_by_handle(handle) then
        return
    end
    local id = Base.id2string(jass.GetUnitTypeId(handle))
    
    local data = ac.unit_button[id]
    
    local button = {}
    setmetatable(button, button)
    button.__index = data
    button.handle = handle
    button.id = id
    button.name = jass.GetUnitName(handle)
    
    return button
end

function mt:click()
    if self.on_click then
        self:on_click()
    end
end

function Unit_button.__call(handle)
    return Unit_button:new(handle)
end
--]]
local function register_unit_button(self, name, data)
    if not data.war3_id then
        Log.error(('注册%s 按钮单位时，不能没有war3_id'):format(name) )
		return
    end
    _UNIT_BUTTON_LIST[data.war3_id] = true

    --[[没必要使用这种注册
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
    self[war3_id] = button
    --]]
    return data
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