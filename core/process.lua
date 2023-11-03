local capi = Capi
local ipairs = ipairs
local type = type
local aspawn = require("awful.spawn")
local gtable = require("gears.table")


---@class command
---@field shell? string|string[]|boolean
---@field terminal? string|string[]|boolean
---@field async? fun(stdout: string, stderr: string, exit_reason: "exit"|"signal", exit_code: integer)
---@field line? { stdout?: fun(line: string), stderr?: fun(line: string), done?: function, exit?: fun(exit_reason: "exit"|"signal", exit_code: integer) }
---@field [integer] string

local M = {
    shell = "sh",
    terminal = "alacritty",
}

local function append(table, value, default_value)
    if value == true then
        value=default_value
    end
    local t = type(value)

    if t=="string" then

        table[#table + 1] = default_value
        table[#table + 1] = "-c"
        
        shell = value
    end
    if shell then
        args[#args + 1] = shell
        args[#args + 1] = "-c"
    end
end

---@param command command|string
function M.run(command)
    if not command then
        return
    elseif type(command) == "string" then
        aspawn.spawn(command)
        return
    end

    local args = {}

    local shell
    if command.shell == true then
        shell = M.shell
    elseif command.shell then
        shell = command.shell
    end
    if shell then
        args[#args + 1] = shell
        args[#args + 1] = "-c"
    end

    local terminal
    if command.terminal == true then
        terminal = M.terminal
    elseif command.terminal then
        terminal = command.terminal
    end
    if terminal then
        args[#args + 1] = terminal
        args[#args + 1] = "-e"
    end

    for _, x in ipairs(command) do
        args[#args + 1] = x
    end

    if command.async then
        aspawn.easy_async(args, command.async)
    elseif command.line then
        aspawn.with_line_callback(args, command.line)
    else
        aspawn.spawn(args)
    end
end

return M
