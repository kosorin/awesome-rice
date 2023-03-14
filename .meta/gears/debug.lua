---@meta gears.debug

---@class _gears.debug
local S

---Inspect the value in data.
---@param data any Value to inspect.
---@param tag? string The name of the value.
---@param depth? integer Depth of recursion.
---@return string A string that contains the expanded value of data.
function S.dump_return(data, tag, depth)
end

---Print the table (or any other value) to the console.
---@param data any Table to print.
---@param tag? string The name of the table.
---@param depth? integer Depth of recursion.
function S.dump(data, tag, depth)
end

---Print an warning message.
---@param message string The warning message to print.
function S.print_warning(message)
end

---Print an error message.
---@param message string The error message to print.
function S.print_error(message)
end

return S
