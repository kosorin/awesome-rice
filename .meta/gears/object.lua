---@meta gears.object

---@class gears.object
local M

---Connect to a signal.
---@param name string # The name of the signal.
---@param callback fun(self: gears.object, ...) # The callback to call when the signal is emitted.
function M:connect_signal(name, callback)
end

---Connect to a signal weakly.
---
---This allows the callback function to be garbage collected and automatically disconnects the signal when that happens.
---
---**Warning:** Only use this function if you really, really, really know what you are doing.
---@param name string # The name of the signal.
---@param callback fun(self: gears.object, ...) # The callback to call when the signal is emitted.
function M:weak_connect_signal(name, callback)
end

---Disonnect from a signal.
---@param name string # The name of the signal.
---@param callback fun(self: gears.object, ...) # The callback that should be disconnected.
function M:disconnect_signal(name, callback)
end

---Emit a signal. 
---@param name string # The name of the signal.
---@param ... any # Extra arguments for the callback functions. Each connected function receives the object as first argument and then any extra arguments that are given to `emit_signal`.
function M:emit_signal(name, ...)
end


---@class _gears.object
---@operator call: gears.object
local S

---@param level? integer
---@return string
function S.modulename(level)
end

return S
