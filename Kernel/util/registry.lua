Registry = {}

function Registry:name_to_id(type, name)
    if not self._NAME_TO_IDS[type] then
        self._NAME_TO_IDS[type] = {}
    end
    return self._NAME_TO_IDS[type][name] or name
end

function Registry:id_to_name(type, id)
    if not self._ID_TO_NAMES[type] then
        self._ID_TO_NAMES[type] = {}
    end
    return self._ID_TO_NAMES[type][id] or id
end

function Registry:register(type, name, id)
    if not self._NAME_TO_IDS[type] then
        self._NAME_TO_IDS[type] = {}
    end
    if not self._ID_TO_NAMES[type] then
        self._ID_TO_NAMES[type] = {}
    end
    self._NAME_TO_IDS[type][name] = id
    self._ID_TO_NAMES[type][id] = name
end

local function init()
    Registry._NAME_TO_IDS = {}
    Registry._ID_TO_NAMES = {}
end
init()