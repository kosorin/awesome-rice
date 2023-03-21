local math = math


local M = {}

---@param value number
---@param min number
---@param max number
---@return number
function M.clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

---@param value number
---@return number
function M.round(value)
    return math.floor(value + 0.5)
end

---@param value number
---@param min number
---@param max number
---@param new_min number
---@param new_max number
---@return number
function M.translate(value, min, max, new_min, new_max)
    local range = max - min
    local new_range = new_max - new_min
    return new_min + (value - min) * (new_range / range)
end

return M
