local capi = Capi
local beautiful = require("theme.theme")
local wibox = require("wibox")
local dpi = Dpi
local binding = require("io.binding")
local mod = binding.modifier
local btn = binding.button
local power_service = require("services.power")
local config = require("config")
local humanizer = require("utils.humanizer")
local capsule = require("widget.capsule")
local hui = require("utils.ui")
local umath = require("utils.math")
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

M.action_item_template = {
    id = "#container",
    widget = capsule,
    margins = hui.thickness { dpi(2), 0 },
    paddings = hui.thickness { dpi(8), dpi(8) },
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
local function action_callback(item, menu, context)
    menu.action = item.power_action
    for i, x in ipairs(menu._private.items) do
        if x.power_action then
            x.checked = x == item
            menu:update_item(i)
        end
    end
    return false
end

---@param default_timeout? integer
---@return Mebox.new.args
function M.new(default_timeout)
    local minutes = default_timeout or power_service.config.default_timeout

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

    ---@type Mebox.new.args
    local args = {
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
        items_source = {
            {
                layout_add = function(layout, item_widget) layout:insert(1, item_widget) end,
                text = "Start",
                icon = config.places.theme .. "/icons/play.svg",
                icon_color = beautiful.palette.green,
                callback = function(item, menu)
                    power_service.start_timer(minutes, menu.action)
                end,
            },
            {
                layout_add = function(layout, item_widget) layout:insert(2, item_widget) end,
                enabled = false,
                text = "Stop",
                icon = config.places.theme .. "/icons/stop.svg",
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
            mebox.separator,
            mebox.header("Action"),
            {
                power_action = power_service.shutdown,
                text = "Shut down",
                checked = true,
                callback = action_callback,
                template = M.action_item_template,
            },
            {
                power_action = power_service.suspend,
                text = "Suspend",
                checked = false,
                callback = action_callback,
                template = M.action_item_template,
            },
        },
    }

    return args
end

M.shared = M.new()

return M
