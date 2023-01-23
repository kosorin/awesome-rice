local capi = {
    awesome = awesome,
}
local awful = require("awful")
local beautiful = require("beautiful")
local config = require("config")
local mebox = require("widget.mebox")
local menu_templates = require("ui.menu.templates")
local dpi = dpi


local main_menu

main_menu = mebox {
    item_width = dpi(192),
    {
        text = "terminal",
        icon = beautiful.dir .. "/icons/console-line.svg",
        icon_color = beautiful.palette.gray,
        callback = function() awful.spawn(config.apps.terminal) end,
    },
    {
        text = "applications",
        icon = beautiful.dir .. "/icons/apps.svg",
        icon_color = beautiful.palette.orange,
        submenu = menu_templates.applications.shared,
    },
    mebox.separator,
    {
        text = "wallpaper",
        icon = beautiful.dir .. "/icons/image-size-select-actual.svg",
        icon_color = beautiful.palette.green,
        submenu = menu_templates.wallpaper.shared,
    },
    mebox.separator,
    {
        text = "shortcuts",
        icon = beautiful.dir .. "/icons/apple-keyboard-command.svg",
        icon_color = beautiful.palette.blue,
        callback = function() capi.awesome.emit_signal("main_bindbox::show") end,
    },
    mebox.separator,
    {
        text = "exit",
        icon = beautiful.dir .. "/icons/power.svg",
        icon_color = beautiful.palette.red,
        submenu = menu_templates.power.shared,
    },
}

return main_menu
