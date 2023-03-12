---@meta wibox.widget

---@class wibox.widget : gears.object
---@field is_widget true
---@field children wibox.widget[]
---@field all_children wibox.widget[]
---@field forced_height? number
---@field forced_width? number
---@field opacity number
---@field visible boolean
---@field buttons awful.button[]
local widget

---@param id string
---@return wibox.widget[]|nil
function widget:get_children_by_id(id)
end

---@param context { screen: screen, dpi: number, drawable: unknown }
---@param max_width number
---@param max_height number
function widget:fit(context, max_width, max_height)
end


---@class _wibox.widget
---@field base wibox.widget.base
local M

return M
