local type = type


local M = {}

---@param value? number|number[]|thickness
---@return thickness|nil # Returns the same table instance (i.e. the `value` parameter).
function M.thickness(value)
    if not value then
        return nil
    end

    if type(value) == "table" then
        local top, right, bottom, left

        local length = #value
        if length == 1 then
            local v = value[1]
            top = v
            right = v
            bottom = v
            left = v
        elseif length == 2 then
            local y = value[1]
            local x = value[2]
            top = y
            right = x
            bottom = y
            left = x
        elseif length == 3 then
            local x = value[2]
            top = value[1]
            right = x
            bottom = value[3]
            left = x
        elseif length == 4 then
            top = value[1]
            right = value[2]
            bottom = value[3]
            left = value[4]
        end

        value.top = value.top or top or 0
        value.right = value.right or right or 0
        value.bottom = value.bottom or bottom or 0
        value.left = value.left or left or 0
        value[1] = value.top
        value[2] = value.right
        value[3] = value.bottom
        value[4] = value.left
        return value
    else
        return { top = value, right = value, bottom = value, left = value }
    end
end

return M
