DEBUG = (os.getenv("DEBUG") or "") ~= ""

Capi = {
    ---@diagnostic disable: undefined-global
    awesome = awesome,
    button = button,
    client = client,
    dbus = dbus,
    drawable = drawable,
    drawin = drawin,
    key = key,
    keygrabber = keygrabber,
    mouse = mouse,
    mousegrabber = mousegrabber,
    root = root,
    screen = screen,
    selection = selection,
    tag = tag,
    window = window,
    ---@diagnostic enable: undefined-global
}

---@type fun(value: number): number
Dpi = require("beautiful.xresources").apply_dpi

local dump
if DEBUG then
    local gdebug = require("gears.debug")

    ---@type fun(data: any, tag: string|nil, depth: integer|nil)
    dump = gdebug.dump
else
    local gdebug = require("gears.debug")
    local notification = require("naughty.notification")

    ---@param data any
    ---@param tag string|nil
    ---@param depth integer|nil
    function dump(data, tag, depth)
        notification {
            title = "DUMP",
            text = gdebug.dump_return(data, tag, depth),
            timeout = 0,
        }
    end
end

Dump = dump
