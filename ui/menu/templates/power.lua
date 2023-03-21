-- DEPENDENCIES: systemctl, loginctl

local capi = Capi
local beautiful = require("theme.theme")
local wibox = require("wibox")
local gtable = require("gears.table")
local dpi = Dpi
local mebox = require("widget.mebox")
local binding = require("io.binding")
local mod = binding.modifier
local btn = binding.button
local power_service = require("services.power")
local config = require("config")
local pango = require("utils.pango")
local humanizer = require("utils.humanizer")
local capsule = require("widget.capsule")
local hui = require("utils.ui")
local umath = require("utils.math")


local timer_menu_template = { mt = { __index = {} } }

timer_menu_template.refresh_item = {
    callbacks = setmetatable({}, { __mode = "k" }),
}

function timer_menu_template.refresh_item.disconnect(item_widget, item, menu)
    local rc = item_widget and timer_menu_template.refresh_item.callbacks[item_widget]
    if rc then
        timer_menu_template.refresh_item.callbacks[item_widget] = nil
        capi.awesome.disconnect_signal("power::timer", rc)
    end
end

function timer_menu_template.refresh_item.connect(item_widget, item, menu, refresh_callback)
    timer_menu_template.refresh_item.disconnect(item_widget, item, menu)

    if not refresh_callback then
        return
    end

    local rc = function(status)
        refresh_callback(status, item_widget, item, menu)
        menu:update_item(item.index)
    end

    timer_menu_template.refresh_item.callbacks[item_widget] = rc

    capi.awesome.connect_signal("power::timer", rc)

    rc(power_service.get_timer_status())
end

function timer_menu_template.new(minutes)
    minutes = minutes or power_service.config.default_timeout

    local settings_time_args = {
        part_count = 1,
        include_leading_zero = true,
        formats = humanizer.long_time_formats,
    }

    local hours_step = 60
    local hours_widget
    local hours_args = setmetatable({ from_part = "hour" }, { __index = settings_time_args })
    local function update_hours_text()
        if not hours_widget then
            return
        end
        local text = humanizer.relative_time(minutes * 60, hours_args)
        hours_widget:set_markup(text)
    end

    local minutes_step = 1
    local minutes_widget
    local minutes_args = setmetatable({ from_part = "minute" }, { __index = settings_time_args })
    local function update_minutes_text()
        if not minutes_widget then
            return
        end
        local text = humanizer.relative_time((minutes % 60) * 60, minutes_args)
        minutes_widget:set_markup(text)
    end

    local function change_minutes(change)
        minutes = umath.clamp(minutes + change, 1, 10 * 24 * 60)
        update_hours_text()
        update_minutes_text()
    end

    return {
        item_width = dpi(192),
        layout_template = {
            layout = wibox.layout.fixed.vertical,
            {
                widget = capsule,
                enable_overlay = false,
                bg = beautiful.common.bg_33,
                fg = beautiful.common.fg,
                margins = hui.thickness { dpi(8), dpi(0) },
                paddings = hui.thickness { dpi(2), dpi(4) },
                {
                    id = "#hours",
                    layout = wibox.layout.align.horizontal,
                },
            },
            {
                widget = capsule,
                enable_overlay = false,
                bg = beautiful.common.bg_33,
                fg = beautiful.common.fg,
                paddings = hui.thickness { dpi(2), dpi(4) },
                {
                    id = "#minutes",
                    layout = wibox.layout.align.horizontal,
                },
            },
        },
        {
            layout_add = function(layout, item_widget) layout:insert(1, item_widget) end,
            text = "start",
            icon = config.places.theme .. "/icons/play.svg",
            icon_color = beautiful.palette.green,
            callback = function()
                power_service.start_timer(minutes)
            end,
        },
        {
            layout_add = function(layout, item_widget) layout:insert(2, item_widget) end,
            enabled = false,
            text = "stop",
            icon = config.places.theme .. "/icons/stop.svg",
            icon_color = beautiful.palette.red,
            callback = function()
                power_service.stop_timer()
            end,
            on_hide = function(item, menu)
                local item_widget = menu._private.item_widgets[item.index]
                timer_menu_template.refresh_item.disconnect(item_widget, item, menu)
            end,
            on_ready = function(item_widget, item, menu)
                timer_menu_template.refresh_item.connect(item_widget, item, menu, function(status)
                    item.enabled = not not status
                    if item.selected and not item.enabled then
                        menu:unselect()
                    end
                end)
            end,
        },
        {
            layout_id = "#hours",
            layout_add = wibox.layout.align.set_first,
            width = beautiful.mebox.default_style.item_height,
            icon = config.places.theme .. "/icons/minus.svg",
            icon_color = beautiful.palette.white,
            callback = function()
                change_minutes(-hours_step)
                return false
            end,
        },
        {
            enabled = false,
            layout_id = "#hours",
            layout_add = wibox.layout.align.set_second,
            buttons_builder = function()
                return binding.awful_buttons {
                    binding.awful({}, binding.group.mouse_wheel, function(trigger)
                        change_minutes(trigger.y * hours_step)
                    end),
                }
            end,
            template = {
                widget = wibox.widget.textbox,
                halign = "center",
                update_callback = function()
                    update_hours_text()
                end,
            },
            on_ready = function(item_widget)
                hours_widget = item_widget
            end,
        },
        {
            layout_id = "#hours",
            layout_add = wibox.layout.align.set_third,
            width = beautiful.mebox.default_style.item_height,
            icon = config.places.theme .. "/icons/plus.svg",
            icon_color = beautiful.palette.white,
            callback = function()
                change_minutes(hours_step)
                return false
            end,
        },
        {
            layout_id = "#minutes",
            layout_add = wibox.layout.align.set_first,
            width = beautiful.mebox.default_style.item_height,
            icon = config.places.theme .. "/icons/minus.svg",
            icon_color = beautiful.palette.white,
            callback = function()
                change_minutes(-minutes_step)
                return false
            end,
        },
        {
            enabled = false,
            layout_id = "#minutes",
            layout_add = wibox.layout.align.set_second,
            buttons_builder = function()
                return binding.awful_buttons {
                    binding.awful({}, binding.group.mouse_wheel, function(trigger)
                        change_minutes(trigger.y * minutes_step)
                    end),
                }
            end,
            template = {
                widget = wibox.widget.textbox,
                halign = "center",
                update_callback = function()
                    update_minutes_text()
                end,
            },
            on_ready = function(item_widget)
                minutes_widget = item_widget
            end,
        },
        {
            layout_id = "#minutes",
            layout_add = wibox.layout.align.set_third,
            width = beautiful.mebox.default_style.item_height,
            icon = config.places.theme .. "/icons/plus.svg",
            icon_color = beautiful.palette.white,
            callback = function()
                change_minutes(minutes_step)
                return false
            end,
        },
    }
end

timer_menu_template.mt.__index.shared = timer_menu_template.new()

setmetatable(timer_menu_template, timer_menu_template.mt)


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
    callback = function(item, menu, context)
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
                    callback = power_service.shutdown,
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
                    callback = power_service.reboot,
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
                    callback = power_service.suspend,
                },
                cancel_item,
            },
        },
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
                    callback = power_service.kill_session,
                },
                cancel_item,
            },
        },
        {
            text = "lock session",
            icon = config.places.theme .. "/icons/lock.svg",
            icon_color = beautiful.palette.gray,
            callback = power_service.lock_session,
        },
        mebox.separator,
        mebox.header("shut down timer"),
        {
            icon = config.places.theme .. "/icons/power.svg",
            icon_color = beautiful.palette.orange,
            mouse_move_show_submenu = true,
            submenu = timer_menu_template.shared,
            on_hide = function(item, menu)
                local item_widget = menu._private.item_widgets[item.index]
                timer_menu_template.refresh_item.disconnect(item_widget, item, menu)
            end,
            on_ready = function(item_widget, item, menu)
                timer_menu_template.refresh_item.connect(item_widget, item, menu, function(status)
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
                    else
                        item.text = "off"
                    end
                end)
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
