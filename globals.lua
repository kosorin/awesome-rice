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
