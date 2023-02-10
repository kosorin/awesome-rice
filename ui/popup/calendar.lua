local os = os
local awful = require("awful")
local wibox = require("wibox")
local gtable = require("gears.table")
local tcolor = require("theme.color")
local binding = require("io.binding")
local mod = binding.modifier
local btn = binding.button
local beautiful = require("beautiful")
local dpi = dpi
local capsule = require("widget.capsule")
local noice = require("widget.noice")
local config = require("config")


local calendar_popup = { mt = {} }

function calendar_popup:show()
    if self.visible then
        return
    end

    self:today()

    self.visible = true
end

function calendar_popup:hide()
    self.visible = false
end

function calendar_popup:toggle()
    if self.visible then
        self:hide()
    else
        self:show()
    end
end

local function set_year_month(self, year, month)
    local date = os.date("*t", os.time {
        year = year,
        month = month,
        day = 1,
    })
    local today = os.date("*t")

    self:set_date(date, today)
end

function calendar_popup:refresh()
    local date = self:get_date()
    set_year_month(self, date.year, date.month)
end

function calendar_popup:today()
    local date = os.date("*t")
    set_year_month(self, date.year, date.month)
end

function calendar_popup:move(direction)
    local date = self:get_date()
    set_year_month(self, date.year, date.month + direction)
end

function calendar_popup:get_date()
    return self._private.calendar_widget:get_date()
end

function calendar_popup:set_date(date, focus_date)
    self._private.calendar_widget:set_date(date, focus_date)
end

noice.define_style_properties(calendar_popup, {
    bg = { proxy = true },
    fg = { proxy = true },
    border_color = { proxy = true },
    border_width = { proxy = true },
    shape = { proxy = true },
    placement = { proxy = true },
    paddings = { property = "paddings" },
    embed = { id = "#calendar", property = "fn_embed" },
})

function calendar_popup.new(args)
    args = args or {}

    local self
    self = awful.popup {
        ontop = true,
        visible = false,
        widget = {
            enabled = false,
            widget = capsule,
            background = tcolor.transparent,
            {
                layout = wibox.layout.fixed.vertical,
                spacing = dpi(16),
                {
                    layout = wibox.layout.stack,
                    {
                        id = "#calendar",
                        widget = wibox.widget.calendar.month,
                        font = beautiful.font,
                        fill_month = true,
                        week_numbers = true,
                        long_weekdays = true,
                        start_sunday = false,
                    },
                    {
                        layout = wibox.container.place,
                        valign = "top",
                        halign = "left",
                        {
                            widget = capsule,
                            buttons = binding.awful_buttons {
                                binding.awful({}, { btn.left }, function() self:move(-1) end),
                            },
                            {
                                widget = wibox.widget.imagebox,
                                forced_width = dpi(18),
                                forced_height = dpi(18),
                                resize = true,
                                image = config.places.theme .. "/icons/chevron-left.svg",
                                stylesheet = "path { fill: " .. beautiful.capsule.default_style.foreground .. "; }",
                            },
                        },
                    },
                    {
                        layout = wibox.container.place,
                        valign = "top",
                        halign = "right",
                        {
                            widget = capsule,
                            buttons = binding.awful_buttons {
                                binding.awful({}, { btn.left }, function() self:move(1) end),
                            },
                            {
                                widget = wibox.widget.imagebox,
                                forced_width = dpi(18),
                                forced_height = dpi(18),
                                resize = true,
                                image = config.places.theme .. "/icons/chevron-right.svg",
                                stylesheet = "path { fill: " .. beautiful.capsule.default_style.foreground .. "; }",
                            },
                        },
                    },
                },
                {
                    widget = capsule,
                    buttons = binding.awful_buttons {
                        binding.awful({}, { btn.left }, function() self:today() end),
                    },
                    {
                        widget = wibox.widget.textbox,
                        text = "today",
                        halign = "center",
                    },
                },
            },
        },
    }

    gtable.crush(self, calendar_popup, true)

    self._private.calendar_widget = self.widget:get_children_by_id("#calendar")[1]

    noice.initialize_style(self, self.widget, beautiful.calendar_popup.default_style)

    self:apply_style(args)

    self.buttons = binding.awful_buttons {
        binding.awful({}, { btn.middle }, function() self:today() end),
        binding.awful({}, {
            { trigger = btn.wheel_up, direction = -1 },
            { trigger = btn.wheel_down, direction = 1 },
        }, function(trigger) self:move(trigger.direction) end),
    }

    self:set_date(os.date("*t"))

    return self
end

function calendar_popup.mt:__call(...)
    return calendar_popup.new(...)
end

return setmetatable(calendar_popup, calendar_popup.mt)
