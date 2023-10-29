local floor = math.floor
local fmod = math.fmod


---@class Tilted.ColumnStrategy
---@field get_column_index fun(column_display_index: integer, size: integer, reverse: boolean): integer
---@field get_column_display_index fun(column_index: integer, size: integer, reverse: boolean): integer

local column_strategy = {}

--[[
```
+─────+─────+─────+─────+─────+
|  1  |  2  |  3  |  4  |  5  |
+─────+─────+─────+─────+─────+
```
]]
---@type Tilted.ColumnStrategy
column_strategy.linear = {
    get_column_index = function(column_display_index, size, reverse)
        return reverse
            and (size - column_display_index + 1)
            or column_display_index
    end,
    get_column_display_index = function(column_index, size, reverse)
        return reverse
            and (size - column_index + 1)
            or column_index
    end,
}

--[[
```
+─────+─────+─────+─────+─────+
|  5  |  3  |  1  |  2  |  4  |
+─────+─────+─────+─────+─────+
```
]]
---@type Tilted.ColumnStrategy
column_strategy.center = {
    get_column_index = function(column_display_index, size, reverse)
        if size > 2 then
            if reverse then
                local half = floor(size / 2)
                if column_display_index <= half then
                    return 2 * (half - column_display_index + 1)
                else
                    local carry = fmod(size, 2)
                    return carry + (2 * column_display_index) - 1 - size
                end
            else
                local half = floor((size + 1) / 2)
                if column_display_index > half then
                    return 2 * (column_display_index - half)
                else
                    local carry = fmod(size + 1, 2)
                    return size - (2 * (column_display_index - 1)) - carry
                end
            end
        else
            return reverse
                and (size - column_display_index + 1)
                or column_display_index
        end
    end,
    get_column_display_index = function(column_index, size, reverse)
        if size > 2 then
            if reverse then
                if (column_index % 2) == 0 then
                    local half = floor(size / 2)
                    return half - (column_index / 2) + 1
                else
                    local carry = fmod(size, 2)
                    return (1 + size - carry + column_index) / 2
                end
            else
                if (column_index % 2) == 0 then
                    local half = floor((size + 1) / 2)
                    return half + (column_index / 2)
                else
                    local carry = fmod(size + 1, 2)
                    return (2 + size - carry - column_index) / 2
                end
            end
        else
            return reverse
                and (size - column_index + 1)
                or column_index
        end
    end,
}

return column_strategy
