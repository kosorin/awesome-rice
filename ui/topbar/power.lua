local capi = Capi
local tonumber = tonumber
local maxinteger = math.maxinteger
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("theme.theme")
local config = require("rice.config")
local binding = require("core.binding")
local pango = require("utils.pango")
local css = require("utils.css")
local mod = binding.modifier
local btn = binding.button
local dpi = Dpi
local capsule = require("widget.capsule")
local gtable = require("gears.table")
local mebox = require("widget.mebox")
local power_menu_template = require("ui.menu.templates.power")
local power_service = require("services.power")
local power = require("rice.power")
local humanizer = require("utils.humanizer")
local hui = require("utils.thickness")


local power_widget = { mt = {} }

local time_args = {
    formats = {
        year = { text = "yr" },
        month = { text = "mo" },
        week = { text = "wk" },
        day = { text = "d" },
        hour = { text = "h" },
        minute = { text = "min" },
        second = { text = "s", format = "%2d" },
    },
    part_count = 2,
    prefix = pango.thin_space,
    unit_separator = pango.thin_space,
}

function power_widget:refresh(status)
    local style = status
        and (((tonumber(status) or maxinteger) <= power.timer.alert_threshold)
            and beautiful.capsule.styles.palette.red
            or beautiful.capsule.styles.palette.orange)
        or beautiful.capsule.styles.normal
    self:apply_style(style)

    local icon_stylesheet = css.style { path = { fill = style.fg } }
    local icon_widget = self:get_children_by_id("#icon")[1]
    icon_widget:set_stylesheet(icon_stylesheet)

    local text_widget = self:get_children_by_id("#text")[1]
    if not status then
        text_widget.visible = false
    else
        local text
        if status == true then
            text = "..."
        else
            text = humanizer.relative_time(status, time_args)
        end
        text_widget:set_markup(text)
        text_widget.visible = true
    end
end

function power_widget.new(wibar)
    local self = wibox.widget {
        widget = capsule,
        margins = hui.new {
            top = beautiful.wibar.paddings.top,
            right = beautiful.wibar.paddings.right,
            bottom = beautiful.wibar.paddings.bottom,
            left = beautiful.capsule.default_style.margins.left,
        },
        paddings = hui.new {
            top = beautiful.capsule.default_style.paddings.top,
            right = dpi(10),
            bottom = beautiful.capsule.default_style.paddings.bottom,
            left = dpi(10),
        },
        {
            layout = wibox.layout.fixed.horizontal,
            {
                id = "#icon",
                widget = wibox.widget.imagebox,
                image = beautiful.icon("power.svg"),
            },
            {
                id = "#text",
                widget = wibox.widget.textbox,
            },
        },
    }

    gtable.crush(self, power_widget, true)

    self._private.wibar = wibar

    self._private.menu = mebox(power_menu_template.shared)

    self.buttons = binding.awful_buttons {
        binding.awful({}, btn.right, function()
            self._private.menu:toggle {
                placement = beautiful.wibar.build_placement(self, self._private.wibar),
            }
        end),
        binding.awful({}, btn.middle, function()
            power_service.stop_timer()
        end),
    }

    capi.awesome.connect_signal("power::timer", function(status) self:refresh(status) end)

    self:refresh(false)

    return self
end

function power_widget.mt:__call(...)
    return power_widget.new(...)
end

return setmetatable(power_widget, power_widget.mt)
