---@meta gears.timer

---@class gears.timer : gears.object
---@operator call : gears.timer
---@field started boolean
---@field timeout number
local M

function M:start()
end

function M:stop()
end

function M:again()
end

---Call the given function at the end of the current GLib event loop iteration.
---@param callback fun(...) The function that should be called
---@param ... any Arguments to the callback function
function M.delayed_call(callback, ...)
end

return M
