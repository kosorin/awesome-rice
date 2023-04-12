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
