local capi = Capi
local tonumber = tonumber
local maxinteger = math.maxinteger
local beautiful = require("theme.theme")
local wibox = require("wibox")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local dpi = Dpi
local mebox = require("widget.mebox")
local binding = require("core.binding")
local mod = binding.modifier
local btn = binding.button
local power_service = require("services.power")
local config = require("rice.config")
local power = require("rice.power")
local pango = require("utils.pango")
local humanizer = require("utils.humanizer")
local capsule = require("widget.capsule")
local hui = require("utils.thickness")
local umath = require("utils.math")
local core_system = require("core.system")
local now = os.time
local timer_menu_template = require("ui.menu.templates.power.timer")


local uptime_args = {
    formats = {
        year = { text = "year" },
        month = { text = "month" },
        week = { text = "week" },
        day = { text = "day" },
        hour = { text = "hour" },
        minute = { text = "min" },
        second = { text = "sec" },
    },
    part_count = 2,
    part_separator = ", ",
    unit_separator = pango.thin_space,
}

local function get_uptime()
    return humanizer.relative_time(now() - core_system.up_since, uptime_args)
end


local M = {}

---@return Mebox.new.args
function M.new()
    ---@param text string
    ---@param icon path
    ---@param icon_color color
    ---@param callback function
    ---@return MeboxItem
    local function confirmation_item(text, icon, icon_color, callback)
        ---@type MeboxItem
        local item = {
            text = text,
            icon = icon,
            icon_color = icon_color,
            mouse_move_show_submenu = false,
            submenu_icon = beautiful.icon("_blank.svg"),
            submenu = {
                border_color = beautiful.common.urgent_bright,
                placement = mebox.placement.confirmation,
                on_show = function(menu, args, context)
                    menu.item_width = menu._private.parent.item_width
                end,
                items_source = {
                    {
                        text = "Yes, " .. text,
                        icon = icon,
                        icon_color = icon_color,
                        callback = callback,
                    },
                    {
                        text = "No, Cancel",
                        callback = function(item, menu, context)
                            menu:hide({ select_parent = context.source ~= "mouse" })
                            return false
                        end,
                    },
                },
            },
        }
        return item
    end

    ---@type Mebox.new.args
    local args = {
        item_width = dpi(200),
        items_source = {
            mebox.header("Power"),
            confirmation_item("Shut Down", beautiful.icon("power.svg"), beautiful.palette.red, power_service.shutdown),
            confirmation_item("Reboot", beautiful.icon("restart.svg"), beautiful.palette.yellow, power_service.reboot),
            confirmation_item("Suspend", beautiful.icon("sleep.svg"), beautiful.palette.magenta, power_service.suspend),
            mebox.header("Session"),
            confirmation_item("Log Out", beautiful.icon("exit-run.svg"), beautiful.palette.green, power_service.kill_session),
            {
                text = "Lock Session",
                icon = beautiful.icon("lock.svg"),
                icon_color = beautiful.palette.gray,
                callback = power_service.lock_session,
            },
            mebox.separator,
            mebox.header("Timer"),
            {
                icon = beautiful.icon("timer-outline.svg"),
                submenu = timer_menu_template.shared,
                on_hide = function(item, menu)
                    -- TODO: Pass `item_widget` in `on_hide` callback?
                    local item_widget = menu._private.item_widgets[item.index]
                    timer_menu_template.refresh.disconnect(item_widget, item, menu)
                end,
                on_ready = function(item_widget, item, menu)
                    timer_menu_template.refresh.connect(item_widget, item, menu, function(status)
                        if status then
                            local text
                            if status == true then
                                text = "..."
                            else
                                text = humanizer.relative_time(status, {
                                    formats = humanizer.short_time_formats,
                                    part_count = 2,
                                    unit_separator = pango.thin_space,
                                })
                            end
                            item.text = text
                            item.style = ((tonumber(status) or maxinteger) <= power.timer.alert_threshold)
                                and beautiful.capsule.styles.palette.red
                                or beautiful.capsule.styles.palette.orange
                            item.icon_color = item.style.fg
                        else
                            item.text = "Not Scheduled"
                            item.style = nil
                            item.icon_color = beautiful.palette.orange
                        end
                    end)
                end,
            },
            mebox.separator,
            {
                text = "Awesome",
                icon = beautiful.icon("awesomewm.svg"),
                icon_color = beautiful.palette.blue,
                submenu = {
                    item_width = dpi(120),
                    border_color = beautiful.common.urgent_bright,
                    items_source = {
                        {
                            text = "Restart",
                            icon = beautiful.icon("restart.svg"),
                            icon_color = beautiful.palette.orange,
                            callback = function() capi.awesome.restart() end,
                        },
                        {
                            text = "Quit",
                            icon = beautiful.icon("exit-run.svg"),
                            icon_color = beautiful.palette.red,
                            callback = function() capi.awesome.quit() end,
                        },
                    },
                },
            },
            mebox.separator,
            mebox.header("Uptime"),
            {
                enabled = false,
                opacity = 1,
                icon = beautiful.icon("timer-play.svg"),
                icon_color = beautiful.palette.cyan,
                on_hide = function(item)
                    item.timer:stop()
                    item.timer = nil
                end,
                on_show = function(item, menu)
                    item.timer = gtimer {
                        timeout = 1,
                        autostart = true,
                        call_now = true,
                        callback = function()
                            item.text = get_uptime()
                            menu:update_item(item.index)
                        end,
                    }
                end,
            },
        },
    }

    return args
end

M.shared = M.new()

return M
