local table = table

function table.getn(t)
    local len = 0
    for k, v in pairs(t) do
        len = len + 1
    end
    return len
end

function table.find( t, val )
    for k, v in pairs(t) do
        if v == val then
            return true, k
        end
    end
    return false
end