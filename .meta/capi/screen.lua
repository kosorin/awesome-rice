---@meta _

---@class screen.base
---@field geometry geometry # The screen coordinates.
---@field index integer # The internal screen number.
---@field workarea geometry # The screen workarea.
---@field tiling_area geometry # The area where clients can be tiled.
---@field padding thickness # The screen padding. This adds a "buffer" section on each side of the screen.
---@field clients client[]
---@field hidden_clients client[]
---@field all_clients client[]
---@field tiled_clients client[]
---@field tags tag[]
---@field selected_tags tag[]
---@field selected_tag? tag
---@field dpi number
local M

---@param args table
---@return geometry
function M:get_bounding_geometry(args)
end


---@class _screen
---@field [integer|screen] screen
local S

return S
