---@meta

---@class gears.object
local M

---@param name string
---@param callback fun(self: gears.object, ...)
function M:connect_signal(name, callback)
end

---@param name string
function M:emit_signal(name, ...)
end
