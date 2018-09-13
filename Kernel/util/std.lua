

local std_require = require
function require(path)
    path = path:lower()
    std_require(path)
end
