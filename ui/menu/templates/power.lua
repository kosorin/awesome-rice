-- DEPENDENCIES: systemctl, loginctl

local capi = {
    awesome = awesome,
    mouse = mouse,
    screen = screen,
}
local awful = require("awful")
local beautiful = require("beautiful")
local dpi = dpi
local mebox = require("widget.mebox")
local config = require("config")


local power_menu_template = { mt = { __index = {} } }

local confirmation_border_color = beautiful.common.urgent_bright

local function confirmation_placement(self, args)
    local border_width = self.border_width
    local width = self.width + 2 * border_width
    local height = self.height + 2 * border_width
    local min_x = args.bounding_rect.x
    local min_y = args.bounding_rect.y
    local max_x = min_x + args.bounding_rect.width - width
    local max_y = min_y + args.bounding_rect.height - height

    local parent_border_width = self._private.parent.border_width
    local parent_paddings = self._private.parent.paddings
    local paddings = self.paddings
    local x = args.geometry.x - parent_paddings.left - parent_border_width
    local y = args.geometry.y - paddings.top - border_width

    self.x = x < min_x and min_x or (x > max_x and max_x or x)
    self.y = y < min_y and min_y or (y > max_y and max_y or y)
end

local cancel_item = {
    text = "no, cancel",
    callback = function(_, _, menu, context)
        menu:hide({ select_parent = context.source ~= "mouse" })
        return false
    end,
}

local item_width = dpi(192)

function power_menu_template.new()
    return {
        item_width = item_width,
        mouse_move_show_submenu = false,
        mebox.header("power"),
        {
            text = "shut down",
            icon = config.places.theme .. "/icons/power.svg",
            icon_color = beautiful.palette.red,
            submenu_icon = config.places.theme .. "/icons/_blank.svg",
            submenu = {
                item_width = item_width,
                border_color = confirmation_border_color,
                placement = confirmation_placement,
                {
                    text = "yes, shut down",
                    icon = config.places.theme .. "/icons/power.svg",
                    icon_color = beautiful.palette.red,
                    callback = function()
                        local command = "systemctl poweroff"
                        awful.spawn.easy_async_with_shell(command)
                    end,
                },
                {
                    enabled = false,
                    text = "schedule",
                    icon = config.places.theme .. "/icons/timer-sand.svg",
                    icon_color = beautiful.palette.orange,
                    submenu = {
                        item_width = dpi(300),
                        {
                            text = "schedule",
                            icon = config.places.theme .. "/icons/timer-sand.svg",
                            icon_color = beautiful.palette.orange,
                        },
                    }
                },
                cancel_item,
            },
        },
        {
            text = "reboot",
            icon = config.places.theme .. "/icons/restart.svg",
            icon_color = beautiful.palette.yellow,
            submenu_icon = config.places.theme .. "/icons/_blank.svg",
            submenu = {
                item_width = item_width,
                border_color = confirmation_border_color,
                placement = confirmation_placement,
                {
                    text = "yes, reboot",
                    icon = config.places.theme .. "/icons/restart.svg",
                    icon_color = beautiful.palette.yellow,
                    callback = function()
                        local command = "systemctl reboot"
                        awful.spawn.easy_async_with_shell(command)
                    end,
                },
                cancel_item,
            },
        },
        {
            text = "suspend",
            icon = config.places.theme .. "/icons/sleep.svg",
            icon_color = beautiful.palette.magenta,
            submenu_icon = config.places.theme .. "/icons/_blank.svg",
            submenu = {
                item_width = item_width,
                border_color = confirmation_border_color,
                placement = confirmation_placement,
                {
                    text = "yes, suspend",
                    icon = config.places.theme .. "/icons/sleep.svg",
                    icon_color = beautiful.palette.magenta,
                    callback = function()
                        local command = "systemctl suspend"
                        awful.spawn.easy_async_with_shell(command)
                    end,
                },
                cancel_item,
            },
        },
        mebox.separator,
        mebox.header("session"),
        {
            text = "log out",
            icon = config.places.theme .. "/icons/exit-run.svg",
            icon_color = beautiful.palette.green,
            submenu_icon = config.places.theme .. "/icons/_blank.svg",
            submenu = {
                item_width = item_width,
                border_color = confirmation_border_color,
                placement = confirmation_placement,
                {
                    text = "yes, log out",
                    icon = config.places.theme .. "/icons/exit-run.svg",
                    icon_color = beautiful.palette.green,
                    callback = function()
                        local command = "loginctl kill-session ${XDG_SESSION_ID-}"
                        awful.spawn.easy_async_with_shell(command)
                    end,
                },
                cancel_item,
            },
        },
        {
            text = "lock session",
            icon = config.places.theme .. "/icons/lock.svg",
            icon_color = beautiful.palette.gray,
            callback = function()
                local command = "loginctl lock-session ${XDG_SESSION_ID-}"
                awful.spawn.easy_async_with_shell(command)
            end,
        },
        mebox.separator,
        {
            text = "awesome",
            icon = config.places.theme .. "/icons/awesomewm.svg",
            icon_color = beautiful.palette.blue,
            mouse_move_show_submenu = true,
            submenu = {
                item_width = dpi(120),
                border_color = confirmation_border_color,
                {
                    text = "restart",
                    icon = config.places.theme .. "/icons/restart.svg",
                    icon_color = beautiful.palette.orange,
                    callback = function() capi.awesome.restart() end,
                },
                {
                    text = "quit",
                    icon = config.places.theme .. "/icons/exit-run.svg",
                    icon_color = beautiful.palette.red,
                    callback = function() capi.awesome.quit() end,
                },
            },
        },
    }
end

power_menu_template.mt.__index.shared = power_menu_template.new()

return setmetatable(power_menu_template, power_menu_template.mt)
