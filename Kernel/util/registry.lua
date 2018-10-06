Registry = {}

function Registry:name_to_id(name)
    return self._NAME_TO_IDS[name] or name
end

function Registry:id_to_name(id)
    return self._ID_TO_NAMES[id] or id
end

function Registry:register(name, id)
    self._NAME_TO_IDS[name] = id
    self._ID_TO_NAMES[id] = name
end

local function init()
    Registry._NAME_TO_IDS = {}
    Registry._ID_TO_NAMES = {}
end
init()