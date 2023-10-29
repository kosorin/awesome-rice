DEBUG = (os.getenv("DEBUG") or "") ~= ""
if DEBUG and os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
    require("lldebugger").start()
end

local dump
if DEBUG then
    local gdebug = require("gears.debug")

    ---@type fun(data: any, tag?: string, depth?: integer)
    dump = gdebug.dump
else
    local gdebug = require("gears.debug")
    local notification = require("naughty.notification")

    ---@param data any
    ---@param tag? string
    ---@param depth? integer
    function dump(data, tag, depth)
        notification {
            title = "DUMP",
            text = gdebug.dump_return(data, tag, depth),
            timeout = 0,
        }
    end
end
Dump = dump

---@param c client
function DumpClient(c)
    Dump({
        name = c.name,
        class = c.class,
        instance = c.instance,
        role = c.role,
        type = c.type,
    }, "", 1)
end
