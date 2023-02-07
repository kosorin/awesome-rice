local capi = {
    awesome = awesome,
    mousegrabber = mousegrabber,
    screen = screen,
}
local awful = require("awful")
local wibox = require("wibox")
local tcolor = require("theme.color")
local binding = require("io.binding")
local mod = binding.modifier
local btn = binding.button
local beautiful = require("beautiful")
local widget_helper = require("helpers.widget")
local dpi = dpi


local calendar_popup = {}

local CalendarPopup = {}

local function create_calendar_widget()

    local styles = {
        normal = {
            bg_color = tcolor.change(beautiful.common.foreground_66, { alpha = 0.25 }),
        },
        focus = {
            bg_color = beautiful.common.primary_66,
            fg_color = beautiful.common.foreground_bright,
        },
        normal_other = {
            markup = function(text)
                return "<span fgalpha='50%'>" .. text .. "</span>"
            end,
        },
        focus_other = {
            bg_color = beautiful.common.primary_50,
            fg_color = beautiful.common.foreground,
        },
        header = {
            markup = function(text)
                return "<b>" .. text .. "</b>"
            end,
        },
        weekday = {
            markup = function(text)
                return "<span weight='bold' fgalpha='75%'>" .. text .. "</span>"
            end,
        },
        weeknumber = {
            markup = function(text)
                return "<span weight='bold' fgalpha='50%'>" .. text .. "</span>"
            end,
        }
    }

    local function embed(widget, flag, date)
        if flag == "month" then
            return wibox.widget {
                widget = wibox.container.place,
                halign = "center",
                valign = "top",
                widget,
            }
        end

        if flag == "monthheader" and not styles.monthheader then
            flag = "header"
        end
        if flag == "normal_other" and not styles.normal_other then
            flag = "normal"
        end
        if flag == "focus_other" and not styles.focus_other then
            flag = "focus"
        end

        local style = styles[flag] or {}

        if style.markup then
            widget:set_markup(style.markup(widget:get_text()))
        end

        return wibox.widget {
            widget = wibox.container.background,
            bg = style.bg_color or tcolor.transparent,
            fg = style.fg_color or beautiful.common.foreground,
            {
                widget = wibox.container.margin,
                margins = style.padding or dpi(2),
                {
                    widget = wibox.container.place,
                    halign = "center",
                    widget,
                },
            },
        }
    end

    return wibox.widget {
        widget = wibox.widget.calendar.month,
        date = os.date("*t"),
        font = beautiful.font,
        fill_month = true,
        week_numbers = true,
        long_weekdays = true,
        start_sunday = false,
        flex_height = false,
        fn_embed = embed,
    }
end

function CalendarPopup:set_date(date, focus_date)
    self.calendar_widget:set_date(date, focus_date)
end

function CalendarPopup:can_show()
    return self.parent.wibar and self.parent.widget
end

function CalendarPopup:show()
    if self.popup.visible or not self:can_show() then
        return
    end

    self:set_date(os.date("*t"))

    local parent_geometry = widget_helper.find_geometry(
        self.parent.widget,
        self.parent.wibar)
    awful.placement.infobubble(self.popup, {
        geometry = parent_geometry,
        position = self.position,
        anchor = self.anchor,
        honor_workarea = true,
        honor_padding = true,
        margins = self.margins,
        corner_radius = self.corner_radius,
        arrow_size = self.arrow_size,
    })

    self.popup.visible = true
end

function CalendarPopup:hide()
    self.popup.visible = false
end

function CalendarPopup:toggle()
    if self.popup.visible then
        self:hide()
    else
        self:show()
    end
end

local function set_year_month(self, year, month)
    if not self.popup.visible or not self:can_show() then
        return
    end

    local date = os.date("*t", os.time {
        year = year,
        month = month,
        day = 1,
    })
    local today = os.date("*t")

    self:set_date(date, today)
end

function CalendarPopup:refresh()
    local date = self.calendar_widget:get_date()
    set_year_month(self, date.year, date.month)
end

function CalendarPopup:today()
    local date = os.date("*t")
    set_year_month(self, date.year, date.month)
end

function CalendarPopup:move(direction)
    local date = self.calendar_widget:get_date()
    set_year_month(self, date.year, date.month + direction)
end

function calendar_popup.new(parent, args)
    args = args or {}
    local self = setmetatable({
        parent = parent,
        popup = nil,
        calendar_widget = nil,
        corner_radius = args.corner_radius or dpi(0),
        arrow_size = args.arrow_size or dpi(12),
        position = args.placement or "bottom",
        anchor = args.placement or "middle",
        width = args.width or dpi(320),
        height = args.height or dpi(272),
        bg = args.bg or beautiful.popup.default_style.bg,
        opacity = args.opacity or 1,
        border_width = args.border_width or beautiful.border_width,
        border_color = args.border_color or beautiful.common.primary_66,
        padding = args.padding or dpi(12),
    }, { __index = CalendarPopup })

    self.margins = args.margins or {
        left = beautiful.useless_gap,
        right = beautiful.useless_gap,
        top = beautiful.useless_gap - (self.arrow_size / 2) - self.border_width,
        bottom = beautiful.useless_gap,
    }

    self.calendar_widget = create_calendar_widget()

    self.popup = awful.popup {
        ontop = true,
        visible = false,
        placement = false,
        width = self.width,
        height = self.height,
        bg = self.bg,
        opacity = self.opacity,
        shape = nil,
        border_width = self.border_width,
        border_color = self.border_color,
        widget = {
            layout = wibox.container.constraint,
            strategy = "exact",
            width = self.width,
            height = self.height,
            {
                widget = wibox.container.margin,
                top = self.arrow_size,
                {
                    widget = wibox.container.margin,
                    margins = self.padding,
                    self.calendar_widget,
                },
            },
        },
    }

    self.popup.buttons = binding.awful_buttons {
        binding.awful({}, { btn.left }, function() self:hide() end),
        binding.awful({}, { btn.right }, function() self:today() end),
        binding.awful({}, {
            { trigger = btn.wheel_up, direction = -1 },
            { trigger = btn.wheel_down, direction = 1 },
        }, function(trigger) self:move(trigger.direction) end),
    }

    return self
end

return calendar_popup
