local capi = {
    awesome = awesome,
}
local table = table
local awful = require("awful")
local beautiful = require("beautiful")
local config = require("config")
local mebox = require("widget.mebox")
local menu_templates = require("ui.menu.templates")
local dpi = dpi


local main_menu

local menu_items = {}

table.insert(menu_items, {
    text = "terminal",
    icon = config.places.theme .. "/icons/console-line.svg",
    icon_color = beautiful.palette.gray,
    callback = function() awful.spawn(config.apps.terminal) end,
})
table.insert(menu_items, {
    text = "applications",
    icon = config.places.theme .. "/icons/apps.svg",
    icon_color = beautiful.palette.orange,
    cache_submenu = false,
    submenu = menu_templates.applications.shared,
})

if config.features.wallpaper_menu then
    table.insert(menu_items, mebox.separator)
    table.insert(menu_items, {
        text = "wallpaper",
        icon = config.places.theme .. "/icons/image-size-select-actual.svg",
        icon_color = beautiful.palette.green,
        submenu = menu_templates.wallpaper.shared,
    })
end

table.insert(menu_items, mebox.separator)
table.insert(menu_items, {
    text = "shortcuts",
    icon = config.places.theme .. "/icons/apple-keyboard-command.svg",
    icon_color = beautiful.palette.blue,
    callback = function() capi.awesome.emit_signal("main_bindbox::show") end,
})
table.insert(menu_items, mebox.separator)
table.insert(menu_items, {
    text = "exit",
    icon = config.places.theme .. "/icons/power.svg",
    icon_color = beautiful.palette.red,
    submenu = menu_templates.power.shared,
})

main_menu = mebox {
    item_width = dpi(192),
    items_source = menu_items,
}

return main_menu
