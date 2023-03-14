---@meta wibox

---@alias cairo_context unknown
---@alias cairo_surface unknown

---@alias widget_context { screen: screen, dpi: number, drawable: unknown }

---@class wibox : gears.object
---@field _drawable unknown
---@field x number
---@field y number
---@field width number
---@field height number
---@field bg color
---@field fg color
---@field border_color color
---@field border_width number
---@field shape shape
---@field widget wibox.widget
---@field visible boolean
---@field screen screen|integer|"primary"
local M

---Get or set wibox geometry. That's the same as accessing or setting the x, y, width or height properties of a wibox.
---@param geometry? { x?: number, y?: number, width?: number, height?: number } # A table with coordinates to modify. If nothing is specified, it only returns the current geometry. Default: `nil`
---@return geometry # A table with wibox coordinates and geometry.
function M:geometry(geometry)
end

---@param id string
---@return wibox.widget[]|nil
function M:get_children_by_id(id)
end


---@class _wibox
---@field widget _wibox.widget
---@field container _wibox.container
---@field layout _wibox.layout
---@field hierarchy _wibox.hierarchy
---@field drawable _wibox.drawable
---@operator call: wibox
local S

return S
