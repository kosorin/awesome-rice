local capi = Capi
local tostring = tostring
local beautiful = require("theme.theme")
local dpi = Dpi
local core_client = require("core.client")
local mebox = require("widget.mebox")
local aspawn = require("awful.spawn")
local awful = require("awful")
local gdebug = require("gears.debug")
local config = require("rice.config")
local common = require("ui.menu.templates.client._common")
local opacity_menu_template = require("ui.menu.templates.client.opacity")
local signals_menu_template = require("ui.menu.templates.client.signals")
local tags_menu_template = require("ui.menu.templates.client.tags")
local screens_menu_template = require("ui.menu.templates.client.screens")
local selection = require("core.selection")
local json = require("dkjson")


local M = {}

---@return Mebox.new.args
function M.new()
    ---@type Mebox.new.args
    local args = {
        item_width = dpi(184),
        on_show = common.on_show,
        on_hide = common.on_hide,
        items_source = {
            {
                text = "Tags",
                icon = beautiful.icon("tag-multiple.svg"),
                icon_color = beautiful.palette.green,
                submenu = tags_menu_template.shared,
            },
            {
                text = "Screen",
                icon = beautiful.icon("monitor.svg"),
                icon_color = beautiful.palette.blue,
                submenu = screens_menu_template.shared,
                on_show = function() return capi.screen.count() > 1 end,
            },
            mebox.separator,
            common.build_simple_toggle("Sticky", "sticky", nil, beautiful.icon("pin.svg"), beautiful.palette.white),
            common.build_simple_toggle("Floating", "floating", nil, beautiful.icon("arrange-bring-forward.svg"), beautiful.palette.white),
            common.build_simple_toggle("On Top", "ontop", nil, beautiful.icon("chevron-double-up.svg"), beautiful.palette.white),
            mebox.separator,
            common.build_simple_toggle("Minimize", "minimized", nil, beautiful.icon("window-minimize.svg"), beautiful.palette.white),
            common.build_simple_toggle("Maximize", "maximized", nil, beautiful.icon("window-maximize.svg"), beautiful.palette.white),
            common.build_simple_toggle("Fullscreen", "fullscreen", nil, beautiful.icon("fullscreen.svg"), beautiful.palette.white),
            mebox.separator,
            {
                text = "More",
                icon = beautiful.icon("cogs.svg"),
                icon_color = beautiful.palette.blue,
                submenu = {
                    item_width = dpi(184),
                    on_show = common.on_show,
                    on_hide = common.on_hide,
                    items_source = {
                        mebox.header("Layer"),
                        common.build_simple_toggle("Top", "ontop", "radiobox", beautiful.icon("chevron-double-up.svg"), beautiful.palette.white),
                        common.build_simple_toggle("Above", "above", "radiobox", beautiful.icon("chevron-up.svg"), beautiful.palette.white),
                        {
                            text = "Normal",
                            checkbox_type = "radiobox",
                            icon = beautiful.icon("unfold-less-vertical.svg"),
                            icon_color = beautiful.palette.white,
                            on_show = function(item, menu)
                                local client = menu.client --[[@as client]]
                                item.checked = not (client.ontop or client.above or client.below)
                            end,
                            callback = function(item, menu)
                                local client = menu.client --[[@as client]]
                                client.ontop = false
                                client.above = false
                                client.below = false
                            end,
                        },
                        common.build_simple_toggle("Below", "below", "radiobox", beautiful.icon("chevron-down.svg"), beautiful.palette.white),
                        mebox.separator,
                        mebox.header("Window"),
                        {
                            text = "Title Bar",
                            icon = beautiful.icon("dock-top.svg"),
                            icon_color = beautiful.palette.white,
                            on_show = function(item, menu)
                                local client = menu.client --[[@as client]]
                                local _, size = client:titlebar_top()
                                item.checked = size > 0
                            end,
                            callback = function(item, menu)
                                local client = menu.client --[[@as client]]
                                awful.titlebar.toggle(client, "top")
                            end,
                        },
                        {
                            text = "Opacity",
                            icon = beautiful.icon("circle-opacity.svg"),
                            icon_color = beautiful.palette.cyan,
                            submenu = opacity_menu_template.shared,
                        },
                        {
                            text = "Hide",
                            icon = beautiful.icon("eye-off.svg"),
                            icon_color = beautiful.palette.gray,
                            callback = function(item, menu)
                                local client = menu.client --[[@as client]]
                                client.hidden = true
                            end,
                        },
                        mebox.separator,
                        common.build_simple_toggle("Dockable", "dockable", nil, beautiful.icon("dock-left.svg"), beautiful.palette.white),
                        common.build_simple_toggle("Focusable", "focusable", nil, beautiful.icon("image-filter-center-focus.svg"), beautiful.palette.white),
                        common.build_simple_toggle("Size Hints", "size_hints_honor", nil, beautiful.icon("move-resize.svg"), beautiful.palette.white),
                        mebox.separator,
                        mebox.header("Process"),
                        {
                            icon = beautiful.icon("identifier.svg"),
                            icon_color = beautiful.palette.white,
                            on_show = function(item, menu)
                                local client = menu.client --[[@as client]]
                                item.text = tostring(client.pid)
                            end,
                            callback = function(item, menu)
                                local client = menu.client --[[@as client]]
                                selection.clipboard:copy(client.pid)
                            end,
                        },
                        {
                            text = "Send Signal",
                            icon = beautiful.icon("target.svg"),
                            icon_color = beautiful.palette.red,
                            submenu = signals_menu_template.shared,
                        },
                        mebox.separator,
                        {
                            text = "Copy rule",
                            icon = beautiful.icon("content-copy.svg"),
                            icon_color = beautiful.palette.gray,
                            callback = function(item, menu)
                                local client = menu.client --[[@as client]]
                                local rule_string = core_client.get_rule_string(client)
                                selection.clipboard:copy(rule_string)
                            end,
                        },
                    },
                },
            },
            mebox.separator,
            {
                text = "Quit",
                icon = beautiful.icon("close.svg"),
                icon_color = beautiful.palette.red,
                callback = function(item, menu)
                    local client = menu.client --[[@as client]]
                    client:kill()
                end,
            },
        },
    }

    return args
end

M.shared = M.new()

return M
