local capi = {
    screen = screen,
    tag = tag,
}
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local config = require("config")
local binding = require("io.binding")
local mod = binding.modifier
local btn = binding.button
local dpi = dpi
local capsule = require("widget.capsule")
local gtable = require("gears.table")
local mebox = require("widget.mebox")
local power_menu_template = require("ui.menu.templates.power")
local aplacement = require("awful.placement")
local widget_helper = require("helpers.widget")


local power_widget = { mt = {} }

function power_widget:refresh()
    local style = beautiful.capsule.styles.normal
    self:apply_style(style)

    local icon_stylesheet = "path { fill: " .. style.foreground .. "; }"
    local icon_widget = self:get_children_by_id("icon")[1]
    icon_widget:set_stylesheet(icon_stylesheet)
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
            layout = wibox.layout.stack,
            {
                id = "icon",
                widget = wibox.widget.imagebox,
                image = config.places.theme .. "/icons/power.svg",
            },
        }
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

    self:refresh()

    return self
end

function power_widget.mt:__call(...)
    return power_widget.new(...)
end

return setmetatable(power_widget, power_widget.mt)
