DEBUG = (os.getenv("DEBUG") or "") ~= ""

Capi = {
    ---@diagnostic disable: undefined-global
    awesome = awesome --[[@as _awesome]],
    button = button,
    client = client --[[@as _client]],
    dbus = dbus,
    drawable = drawable,
    drawin = drawin,
    key = key,
    keygrabber = keygrabber,
    mouse = mouse --[[@as _mouse]],
    mousegrabber = mousegrabber --[[@as _mousegrabber]],
    root = root --[[@as _root]],
    screen = screen --[[@as _screen]],
    selection = selection --[[@as _selection]],
    tag = tag --[[@as _tag]],
    window = window,
    ---@diagnostic enable: undefined-global
}

---@type fun(value: number): number
Dpi = require("beautiful.xresources").apply_dpi

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
