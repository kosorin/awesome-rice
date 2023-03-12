---@meta gears.debug

---@class gears.debug
local M

---Inspect the value in data.
---@param data any Value to inspect.
---@param tag? string The name of the value.
---@param depth? integer Depth of recursion.
---@return string A string that contains the expanded value of data.
function M.dump_return(data, tag, depth)
end

---Print the table (or any other value) to the console.
---@param data any Table to print.
---@param tag? string The name of the table.
---@param depth? integer Depth of recursion.
function M.dump(data, tag, depth)
end

---Print an warning message.
---@param message string The warning message to print.
function M.print_warning(message)
end

---Print an error message.
---@param message string The error message to print.
function M.print_error(message)
end

return M
