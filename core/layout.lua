local setmetatable = setmetatable
local ipairs = ipairs
local type = type


---@class core.layout
local M = {}

---@param layouts awful.layout[]
---@return awful.layout[]
function M.initialize_list(layouts)
    return setmetatable(layouts, {
        __index = function(self, key)
            ---@cast self awful.layout[]
            if type(key) == "string" then
                for _, layout in ipairs(self) do
                    if layout.name == key then
                        return layout
                    end
                end
            end
        end,
    })
end

return M
