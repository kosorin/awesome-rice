---@meta awful.screen

---@class _awful.screen
local S

---Return the screen index corresponding to the given (pixel) coordinates.
---@param x number
---@param y number
---@return integer|nil
function S.getbycoord(x, y)
end

---@return screen|nil
function S.focused()
end

return S
