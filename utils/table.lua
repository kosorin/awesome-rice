local pairs = pairs
local gtable = require("gears.table")


local M = {}

function M.crush_clone(source, crush)
    if not source then
        return crush or {}
    end
    if not crush then
        return gtable.clone(source, true)
    end

    local clone = {}
    local source_keys = {}
    for k in pairs(source) do
        source_keys[k] = true
    end
    for k, v in pairs(crush) do
        source_keys[k] = nil
        clone[k] = v
    end
    for k in pairs(source_keys) do
        local value = source[k]
        if type(value) == "table" then
            clone[k] = gtable.clone(value, true)
        else
            clone[k] = value
        end
    end
    return clone
end

function M.values(t)
    local result = {}
    for _, v in pairs(t) do
        result[#result + 1] = v
    end
    return result
end

return M
