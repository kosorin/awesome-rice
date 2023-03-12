---@meta wibox

---@class wibox : gears.object
---@field _drawable unknown
---@field x number
---@field y number
---@field width number
---@field height number
---@field bg unknown
---@field fg unknown
---@field border_color unknown
---@field border_width number
---@field shape fun(cr, width: number, height: number)
local wibox

---@return geometry
function wibox:geometry()
end


---@class _wibox
---@field widget _wibox.widget
---@field container unknown
---@field layout unknown
---@field hierarchy unknown
local M

return M
