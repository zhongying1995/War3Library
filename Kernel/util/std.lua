

local std_require = require
function require(path, is_reload)
    path = path:lower()
    if is_reload then
        package.loaded[path] = nil
    end
    return std_require(path)
end

function reload(path)
    require(path, true)
end
