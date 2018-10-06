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

local function register_unit_button(self, name, data)
    if not data.war3_id then
        Log.error(('注册%s 按钮单位时，不能没有war3_id'):format(name) )
		return
    end
    _UNIT_BUTTON_LIST[data.war3_id] = true
    Registry:register(name, data.war3_id)

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