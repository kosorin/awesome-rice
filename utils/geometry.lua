local uthickness = require("utils.thickness")

local M = {}

---@param geometry geometry
---@param thickness? thickness_value
---@return geometry
function M.inflate(geometry, thickness)
    thickness = uthickness.new(thickness)
    return thickness and {
        x = geometry.x - thickness.left,
        y = geometry.y - thickness.top,
        width = geometry.width + thickness.left + thickness.right,
        height = geometry.height + thickness.top + thickness.bottom,
    } or geometry
end

---@param geometry geometry
---@param thickness? thickness_value
---@return geometry
function M.shrink(geometry, thickness)
    return M.inflate(geometry, -uthickness.new(thickness))
end

return M
