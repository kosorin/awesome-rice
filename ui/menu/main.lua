local capi = Capi
local table = table
local awful = require("awful")
local beautiful = require("theme.theme")
local config = require("rice.config")
local gtimer = require("gears.timer")
local mebox = require("widget.mebox")
local bindbox = require("widget.bindbox")
local menu_templates = require("ui.menu.templates")
local app_menu = require("rice.apps").menu
local dpi = Dpi


return mebox {
    item_width = dpi(192),
    items_source = function()
        local items = {}

        local function add_separator()
            if #items > 0 and items[#items] ~= mebox.separator then
                table.insert(items, mebox.separator)
            end
        end

        if app_menu.favorites then
            for _, favorite in ipairs(menu_templates.applications.get_favorites_items()) do
                table.insert(items, favorite)
            end
        end

        if app_menu.categories then
            add_separator()
            table.insert(items, {
                text = "Applications",
                icon = beautiful.icon("apps.svg"),
                icon_color = beautiful.palette.orange,
                cache_submenu = false,
                submenu = menu_templates.applications.get_categories_menu,
            })
        end

        if config.features.wallpaper_menu then
            add_separator()
            table.insert(items, {
                text = "Wallpaper",
                icon = beautiful.icon("image-size-select-actual.svg"),
                icon_color = beautiful.palette.green,
                submenu = menu_templates.wallpaper.shared,
            })
        end

        add_separator()
        table.insert(items, {
            text = "Shortcuts",
            icon = beautiful.icon("apple-keyboard-command.svg"),
            icon_color = beautiful.palette.blue,
            callback = function()
                gtimer.delayed_call(function()
                    bindbox.main:show()
                end)
            end,
        })
        add_separator()
        table.insert(items, {
            text = "Exit",
            icon = beautiful.icon("power.svg"),
            icon_color = beautiful.palette.red,
            submenu = menu_templates.power.shared,
        })

        return items
    end,
}
