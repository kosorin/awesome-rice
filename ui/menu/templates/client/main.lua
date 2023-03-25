local tostring = tostring
local beautiful = require("theme.theme")
local dpi = Dpi
local mebox = require("widget.mebox")
local aspawn = require("awful.spawn")
local config = require("config")
local common = require("ui.menu.templates.client._common")
local opacity_menu_template = require("ui.menu.templates.client.opacity")
local signals_menu_template = require("ui.menu.templates.client.signals")
local tags_menu_template = require("ui.menu.templates.client.tags")


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
                text = "tags",
                icon = config.places.theme .. "/icons/tag-multiple.svg",
                icon_color = beautiful.palette.green,
                submenu = tags_menu_template.shared,
            },
            mebox.separator,
            common.build_simple_toggle("minimize", "minimized", nil, "/icons/window-minimize.svg", beautiful.palette.white),
            common.build_simple_toggle("maximize", "maximized", nil, "/icons/window-maximize.svg", beautiful.palette.white),
            common.build_simple_toggle("fullscreen", "fullscreen", nil, "/icons/fullscreen.svg", beautiful.palette.white),
            mebox.separator,
            common.build_simple_toggle("on top", "ontop", nil, "/icons/chevron-double-up.svg", beautiful.palette.white),
            common.build_simple_toggle("floating", "floating", nil, "/icons/arrange-bring-forward.svg", beautiful.palette.white),
            {
                text = "opacity",
                icon = config.places.theme .. "/icons/circle-opacity.svg",
                icon_color = beautiful.palette.cyan,
                submenu = opacity_menu_template.shared,
            },
            mebox.separator,
            {
                text = "more",
                icon = config.places.theme .. "/icons/cogs.svg",
                icon_color = beautiful.palette.blue,
                submenu = {
                    item_width = dpi(184),
                    on_show = common.on_show,
                    on_hide = common.on_hide,
                    items_source = {
                        mebox.header("layer"),
                        common.build_simple_toggle("top", "ontop", "radiobox", "/icons/chevron-double-up.svg", beautiful.palette.white),
                        common.build_simple_toggle("above", "above", "radiobox", "/icons/chevron-up.svg", beautiful.palette.white),
                        {
                            text = "normal",
                            checkbox_type = "radiobox",
                            icon = config.places.theme .. "/icons/unfold-less-vertical.svg",
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
                        common.build_simple_toggle("below", "below", "radiobox", "/icons/chevron-down.svg", beautiful.palette.white),
                        mebox.separator,
                        common.build_simple_toggle("dockable", "dockable", nil, "/icons/dock-left.svg", beautiful.palette.white),
                        common.build_simple_toggle("focusable", "focusable", nil, "/icons/image-filter-center-focus.svg", beautiful.palette.white),
                        common.build_simple_toggle("size hints", "size_hints_honor", nil, "/icons/move-resize.svg", beautiful.palette.white),
                        mebox.separator,
                        mebox.header("process"),
                        {
                            icon = config.places.theme .. "/icons/identifier.svg",
                            icon_color = beautiful.palette.white,
                            on_show = function(item, menu)
                                local client = menu.client --[[@as client]]
                                item.text = tostring(client.pid)
                            end,
                            callback = function(item, menu)
                                local client = menu.client --[[@as client]]
                                aspawn.with_shell(config.commands.copy_text(tostring(client.pid)))
                            end,
                        },
                        {
                            text = "send signal",
                            icon = config.places.theme .. "/icons/target.svg",
                            icon_color = beautiful.palette.red,
                            submenu = signals_menu_template.shared,
                        },
                        mebox.separator,
                        {
                            text = "hide",
                            icon = config.places.theme .. "/icons/eye-off.svg",
                            icon_color = beautiful.palette.gray,
                            callback = function(item, menu)
                                local client = menu.client --[[@as client]]
                                client.hidden = true
                            end,
                        },
                    },
                },
            },
            mebox.separator,
            {
                text = "quit",
                icon = config.places.theme .. "/icons/close.svg",
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
