local capi = Capi
local ipairs = ipairs


local M = {}

---@class core.widget.find_geometry
---@field drawable wibox.drawable
---@field hierarchy wibox.hierarchy
---@field widget wibox.widget.base
---@field widget_width number
---@field widget_height number
---@field x number
---@field y number
---@field width number
---@field height number

---@param widget wibox.widget.base
---@param drawable wibox.drawable
---@param hierarchy wibox.hierarchy
---@return core.widget.find_geometry|nil
local function find_geometry_core(widget, drawable, hierarchy)
    local hierarchy_widget = hierarchy:get_widget()
    if hierarchy_widget == widget then
        local width, height = hierarchy:get_size()
        local matrix = hierarchy:get_matrix_to_device()
        local x, y, w, h = matrix:transform_rectangle(0, 0, width, height)
        return {
            drawable = drawable,
            hierarchy = hierarchy,
            widget = hierarchy_widget,
            widget_width = width,
            widget_height = height,
            x = x,
            y = y,
            width = w,
            height = h,
        }
    end

    for _, child in ipairs(hierarchy:get_children()) do
        local geometry = find_geometry_core(widget, drawable, child)
        if geometry then
            return geometry
        end
    end
end

---@param widget wibox.widget.base
---@param wibox wibox
---@return core.widget.find_geometry|nil
function M.find_geometry(widget, wibox)
    local drawable = wibox and wibox._drawable
    local hierarchy = drawable and drawable._widget_hierarchy
    if not hierarchy then
        return
    end
    return find_geometry_core(widget, drawable, hierarchy)
end

local function is_under_pointer_core(widget, x, y, hierarchy)
    local matrix = hierarchy:get_matrix_from_device()
    local x1, y1 = matrix:transform_point(x, y)
    local x2, y2, w2, h2 = hierarchy:get_draw_extents()
    if x1 < x2 or x1 >= x2 + w2 then
        return
    end
    if y1 < y2 or y1 >= y2 + h2 then
        return
    end

    if widget == hierarchy:get_widget() then
        local width, height = hierarchy:get_size()
        return x1 >= 0 and y1 >= 0 and x1 <= width and y1 <= height
    end

    for _, child in ipairs(hierarchy:get_children()) do
        local result = is_under_pointer_core(widget, x, y, child)
        if result ~= nil then
            return result
        end
    end
end

function M.is_under_pointer(widget)
    local wibox = capi.mouse.current_wibox
    if not wibox then
        return
    end

    local drawable = wibox._drawable
    local hierarchy = drawable and drawable._widget_hierarchy
    if not hierarchy then
        return
    end

    local coords = capi.mouse:coords()
    local geometry = wibox:geometry()
    local border_width = wibox.border_width
    local x = coords.x - geometry.x - border_width
    local y = coords.y - geometry.y - border_width
    return is_under_pointer_core(widget, x, y, hierarchy)
end

return M
