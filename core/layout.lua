local setmetatable = setmetatable
local ipairs = ipairs
local type = type


---@class core.layout
local M = {}

---@param layouts awful.layout[]
---@return awful.layout[]
function M.list(layouts)
    return setmetatable(layouts, {
        __index = function(t, k)
            if type(k) == "string" then
                for _, layout in ipairs(t) do
                    ---@cast layout awful.layout
                    if layout.name == k then
                        return layout
                    end
                end
            end
        end,
    })
end

return M
