local capi = Capi
local setmetatable = setmetatable
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("theme.theme")
local config = require("rice.config")
local binding = require("core.binding")
local mod = binding.modifier
local btn = binding.button
local dpi = Dpi
local capsule = require("widget.capsule")
local gtable = require("gears.table")
local mebox = require("widget.mebox")
local tools_popup = require("ui.popup.tools")
local css = require("utils.css")
local hui = require("utils.thickness")


local power_widget = { mt = {} }

function power_widget:refresh()
    local style = self._private.popup.visible
        and beautiful.capsule.styles.selected
        or beautiful.capsule.styles.normal
    self:apply_style(style)

    local icon_stylesheet = css.style { path = { fill = style.fg } }
    local icon_widget = self:get_children_by_id("#icon")[1]
    icon_widget:set_stylesheet(icon_stylesheet)
end

function power_widget.new(wibar)
    local self = wibox.widget {
        widget = capsule,
        margins = {
            top = beautiful.wibar.paddings.top,
            bottom = beautiful.wibar.paddings.bottom,
        },
        paddings = hui.new {
            beautiful.capsule.default_style.paddings.top,
            dpi(10),
            beautiful.capsule.default_style.paddings.bottom,
        },
        {
            layout = wibox.layout.stack,
            {
                id = "#icon",
                widget = wibox.widget.imagebox,
                image = beautiful.icon("toolbox.svg"),
            },
        },
    }

    gtable.crush(self, power_widget, true)

    self._private.wibar = wibar

    local popup_placement = beautiful.wibar.build_placement(self, self._private.wibar)

    self._private.popup = tools_popup.new {
        placement = popup_placement,
    }

    self._private.popup:connect_signal("property::visible", function() self:refresh() end)

    self.buttons = binding.awful_buttons {
        binding.awful({}, btn.left, function()
            self._private.popup:toggle()
        end),
    }

    self:refresh()

    return self
end

function power_widget.mt:__call(...)
    return power_widget.new(...)
end

return setmetatable(power_widget, power_widget.mt)
