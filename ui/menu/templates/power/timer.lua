local capi = Capi
local beautiful = require("theme.theme")
local wibox = require("wibox")
local dpi = Dpi
local floor = math.floor
local binding = require("core.binding")
local mod = binding.modifier
local btn = binding.button
local power_service = require("services.power")
local config = require("rice.config")
local power = require("rice.power")
local humanizer = require("utils.humanizer")
local capsule = require("widget.capsule")
local hui = require("utils.thickness")
local mebox = require("widget.mebox")
local pango = require("utils.pango")
local css = require("utils.css")


local M = {}

M.refresh = {
    callbacks = setmetatable({}, { __mode = "k" }),
}

function M.refresh.disconnect(item_widget, item, menu)
    local rcb = item_widget and M.refresh.callbacks[item_widget]
    if rcb then
        M.refresh.callbacks[item_widget] = nil
        capi.awesome.disconnect_signal("power::timer", rcb)
    end
end

function M.refresh.connect(item_widget, item, menu, refresh_callback)
    M.refresh.disconnect(item_widget, item, menu)

    if not refresh_callback then
        return
    end

    local rcb = function(status)
        refresh_callback(status, item_widget, item, menu)
        menu:update_item(item.index)
    end

    M.refresh.callbacks[item_widget] = rcb

    capi.awesome.connect_signal("power::timer", rcb)

    rcb(power_service.get_timer_status())
end

M.power_action_item_template = {
    id = "#container",
    widget = capsule,
    margins = hui.new { dpi(2), 0 },
    paddings = hui.new { dpi(8), dpi(8) },
    {
        layout = wibox.layout.align.horizontal,
        expand = "inside",
        nil,
        {
            id = "#text",
            widget = wibox.widget.textbox,
        },
        {
            widget = wibox.container.margin,
            {
                id = "#right_icon",
                widget = wibox.widget.imagebox,
                resize = true,
            },
        },
    },
    update_callback = function(self, item, menu)
        self.forced_width = item.width or menu.item_width
        self.forced_height = item.height or menu.item_height

        local styles = item.selected
            and beautiful.mebox.item_styles.selected
            or beautiful.mebox.item_styles.normal
        local style = item.urgent
            and styles.urgent
            or styles.normal
        self:apply_style(style)

        local text_widget = self:get_children_by_id("#text")[1]
        if text_widget then
            local text = item.text or ""
            text_widget:set_text(text)
        end

        local right_icon_widget = self:get_children_by_id("#right_icon")[1]
        if right_icon_widget then
            local checkbox_type = item.checkbox_type or "radiobox"
            local checkbox_style = beautiful.mebox[checkbox_type][not not item.checked]
            local icon = checkbox_style.icon
            local color = checkbox_style.color

            if item.selected then
                color = style.fg
            end

            right_icon_widget:set_stylesheet(css.style { path = { fill = color } })
            right_icon_widget:set_image(icon)
        end
    end,
}

---@param item MeboxItem
---@param menu Mebox
---@param context Mebox.context
---@return boolean?
local function change_power_action_callback(item, menu, context)
    menu.power_request = item.power_request
    for i, x in ipairs(menu._private.items) do
        if x.power_request then
            x.checked = x == item
            menu:update_item(i)
        end
    end
    return false
end

---@param default_timeout? integer
---@return Mebox.new.args
function M.new(default_timeout)
    local total_minutes = (default_timeout or power.timer.default_timeout) // 60
    local default_hours = floor(total_minutes / 60)
    local default_minutes = floor(total_minutes % 60)

    local hours, minutes = default_hours, default_minutes

    local settings_time_args = {
        part_count = 1,
        include_leading_zero = true,
        formats = humanizer.long_time_formats,
    }

    local hours_widget
    local hours_args = setmetatable({ from_part = "hour" }, { __index = settings_time_args })
    local function update_hours_text()
        if not hours_widget then
            return
        end
        local text = humanizer.relative_time(hours * 60 * 60, hours_args)
        hours_widget:set_markup(text)
    end

    local minutes_widget
    local minutes_args = setmetatable({ from_part = "minute" }, { __index = settings_time_args })
    local function update_minutes_text()
        if not minutes_widget then
            return
        end
        local text = humanizer.relative_time(minutes * 60, minutes_args)
        minutes_widget:set_markup(text)
    end

    local function set_hours(value)
        hours = value
        update_hours_text()
    end

    local function set_minutes(value)
        minutes = value
        update_minutes_text()
    end

    local function change_hours(change)
        local value = hours + change
        if value < 0 then
            value = 0
        end
        set_hours(value)
    end

    local function change_minutes(change)
        local value = minutes + change
        while value < 0 do
            value = value + 60
        end
        value = value % 60
        set_minutes(value)
    end

    local shutdown_request = {
        action = power_service.shutdown,
        reason = "Shut down",
    }
    local suspend_request = {
        action = power_service.suspend,
        reason = "Suspend",
    }

    local default_request = shutdown_request

    ---@type Mebox.new.args
    local args = {
        item_width = dpi(192),
        layout_template = {
            layout = wibox.layout.fixed.vertical,
            {
                id = "#top",
                layout = wibox.layout.fixed.vertical,
            },
            {
                widget = capsule,
                enable_overlay = false,
                bg = beautiful.capsule.styles.nested.bg,
                fg = beautiful.capsule.styles.nested.fg,
                border_color = beautiful.capsule.styles.nested.border_color,
                border_width = beautiful.capsule.styles.nested.border_width,
                margins = hui.new { dpi(8), dpi(0) },
                paddings = hui.new { dpi(2), dpi(4) },
                {
                    id = "#hours",
                    layout = wibox.layout.align.horizontal,
                },
            },
            {
                widget = capsule,
                enable_overlay = false,
                bg = beautiful.capsule.styles.nested.bg,
                fg = beautiful.capsule.styles.nested.fg,
                border_color = beautiful.capsule.styles.nested.border_color,
                border_width = beautiful.capsule.styles.nested.border_width,
                paddings = hui.new { dpi(2), dpi(4) },
                {
                    id = "#minutes",
                    layout = wibox.layout.align.horizontal,
                },
            },
        },
        items_source = {
            {
                layout_id = "#top",
                text = "Start",
                icon = beautiful.icon("play.svg"),
                icon_color = beautiful.palette.green,
                callback = function(item, menu)
                    local request = menu.power_request or default_request
                    power_service.start_timer {
                        timeout = hours * 3600 + minutes * 60,
                        action = request.action,
                        reason = request.reason,
                    }
                end,
            },
            {
                layout_id = "#top",
                enabled = false,
                text = "Stop",
                icon = beautiful.icon("stop.svg"),
                icon_color = beautiful.palette.red,
                callback = function()
                    power_service.stop_timer()
                end,
                on_hide = function(item, menu)
                    local item_widget = menu._private.item_widgets[item.index]
                    M.refresh.disconnect(item_widget, item, menu)
                end,
                on_ready = function(item_widget, item, menu)
                    M.refresh.connect(item_widget, item, menu, function(status)
                        item.enabled = not not status
                        if not item.enabled and item.selected then
                            menu:unselect()
                        end
                    end)
                end,
            },
            {
                layout_id = "#hours",
                layout_add = wibox.layout.align.set_first,
                width = beautiful.mebox.default_style.item_height,
                icon = beautiful.icon("minus.svg"),
                icon_color = beautiful.palette.white,
                callback = function()
                    change_hours(-1)
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
                            change_hours(trigger.y)
                        end),
                        binding.awful({}, btn.middle, function()
                            set_hours(0)
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
                icon = beautiful.icon("plus.svg"),
                icon_color = beautiful.palette.white,
                callback = function()
                    change_hours(1)
                    return false
                end,
            },
            {
                layout_id = "#minutes",
                layout_add = wibox.layout.align.set_first,
                width = beautiful.mebox.default_style.item_height,
                icon = beautiful.icon("minus.svg"),
                icon_color = beautiful.palette.white,
                callback = function()
                    change_minutes(-1)
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
                            change_minutes(trigger.y)
                        end),
                        binding.awful({}, btn.middle, function()
                            set_minutes(0)
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
                icon = beautiful.icon("plus.svg"),
                icon_color = beautiful.palette.white,
                callback = function()
                    change_minutes(1)
                    return false
                end,
            },
            mebox.separator,
            mebox.header("Action"),
            {
                power_request = shutdown_request,
                text = "Shut down",
                checked = default_request == shutdown_request,
                callback = change_power_action_callback,
                template = M.power_action_item_template,
            },
            {
                power_request = suspend_request,
                text = "Suspend",
                checked = default_request == suspend_request,
                callback = change_power_action_callback,
                template = M.power_action_item_template,
            },
        },
    }

    return args
end

M.shared = M.new()

return M
