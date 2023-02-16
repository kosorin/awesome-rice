local capi = {
    awesome = awesome,
    screen = screen,
    tag = tag,
}
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local config = require("config")
local binding = require("io.binding")
local pango = require("utils.pango")
local css = require("utils.css")
local mod = binding.modifier
local btn = binding.button
local dpi = dpi
local capsule = require("widget.capsule")
local gtable = require("gears.table")
local mebox = require("widget.mebox")
local power_menu_template = require("ui.menu.templates.power")
local humanizer = require("utils.humanizer")


local power_widget = { mt = {} }

local time_formats = {
    formats = {
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
        and beautiful.capsule.styles.palette.orange
        or beautiful.capsule.styles.normal
    self:apply_style(style)

    local icon_stylesheet = css.style { path = { fill = style.foreground } }
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
            text = humanizer.relative_time(status, time_formats)
        end
        text_widget:set_markup(text)
        text_widget.visible = true
    end
end

function power_widget.new(wibar)
    local self = wibox.widget {
        widget = capsule,
        margins = {
            left = beautiful.capsule.default_style.margins.left,
            right = beautiful.wibar.padding.right,
            top = beautiful.wibar.padding.top,
            bottom = beautiful.wibar.padding.bottom,
        },
        paddings = {
            left = dpi(10),
            right = dpi(10),
            top = beautiful.capsule.default_style.paddings.top,
            bottom = beautiful.capsule.default_style.paddings.bottom,
        },
        {
            layout = wibox.layout.fixed.horizontal,
            {
                id = "#icon",
                widget = wibox.widget.imagebox,
                image = config.places.theme .. "/icons/power.svg",
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
    }

    capi.awesome.connect_signal("power::timer", function(status) self:refresh(status) end)

    self:refresh(false)

    return self
end

function power_widget.mt:__call(...)
    return power_widget.new(...)
end

return setmetatable(power_widget, power_widget.mt)
