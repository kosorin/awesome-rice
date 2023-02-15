-- DEPENDENCIES (feature flag "redshift_widget"): sct

local config = require("config")
if not config.features.redshift_widget then
    return
end

local capi = {
    awesome = awesome,
    mousegrabber = mousegrabber,
}
local math = math
local string = string
local awful = require("awful")
local wibox = require("wibox")
local binding = require("io.binding")
local mod = binding.modifier
local btn = binding.button
local beautiful = require("beautiful")
local dpi = dpi
local capsule = require("widget.capsule")
local gshape = require("gears.shape")
local gtable = require("gears.table")
local widget_helper = require("helpers.widget")
local tcolor = require("theme.color")
local mouse_helper = require("helpers.mouse")
local pango = require("utils.pango")
local css = require("utils.css")


local redshift_widget = { mt = {} }

local min_temperature = 1000
local max_temperature = 10000
local default_temperature = 6500
local temperature_step = 100
local text_format = "%.1f" .. pango.thin_space .. "K"
local style = beautiful.capsule.styles.normal

local function clamp(temperature)
    if not temperature then
        temperature = default_temperature
    end

    temperature = math.ceil(temperature)
    temperature = temperature - math.fmod(temperature, temperature_step)

    if temperature < min_temperature then
        temperature = min_temperature
    elseif temperature > max_temperature then
        temperature = max_temperature
    end

    return temperature
end

function redshift_widget:refresh()
    local data = self._private.data

    local temperature_text = string.format(text_format, data.temperature * 0.001)

    local text_markup = temperature_text
    local text_widget = self:get_children_by_id("text")[1]
    text_widget:set_markup(text_markup)

    local bar_widget = self:get_children_by_id("bar")[1]
    bar_widget:set_value(100 * (data.temperature - min_temperature) / (max_temperature - min_temperature))
end

function redshift_widget:update_local_only(temperature)
    self._private.data.temperature = clamp(temperature)
    self:refresh()
end

function redshift_widget:update(temperature)
    self:update_local_only(temperature)
    awful.spawn("sct " .. tostring(self._private.data.temperature))
end

function redshift_widget.new(wibar, on_dashboard)
    local self = wibox.widget {
        widget = capsule,
        margins = not on_dashboard
            and {
                left = beautiful.capsule.default_style.margins.left,
                right = beautiful.capsule.default_style.margins.right,
                top = beautiful.wibar.padding.top,
                bottom = beautiful.wibar.padding.bottom,
            }
            or nil,
        {
            layout = wibox.layout.fixed.horizontal,
            spacing = beautiful.capsule.item_content_spacing,
            {
                id = "icon",
                widget = wibox.widget.imagebox,
                resize = true,
                image = config.places.theme .. "/icons/lightbulb-on.svg",
                stylesheet = css.style { path = { fill = style.foreground } },
            },
            {
                id = "text",
                widget = wibox.widget.textbox,
            },
            {
                id = "bar_container",
                layout = wibox.container.place,
                valign = "center",
                {
                    id = "bar",
                    widget = wibox.widget.progressbar,
                    shape = function(cr, width, height) gshape.rounded_rect(cr, width, height, dpi(4)) end,
                    bar_shape = function(cr, width, height) gshape.rounded_rect(cr, width, height, dpi(3)) end,
                    max_value = 100,
                    forced_width = not on_dashboard and beautiful.capsule.bar_width,
                    forced_height = beautiful.capsule.bar_height,
                    color = style.foreground,
                    background_color = beautiful.get_progressbar_background_color(style.foreground),
                },
            },
        },
    }

    gtable.crush(self, redshift_widget, true)

    self._private.data = {}

    self._private.wibar = wibar

    self.buttons = binding.awful_buttons {
        binding.awful({}, btn.middle, function() self:update() end),
        binding.awful({}, {
            { trigger = btn.wheel_up, direction = 1 },
            { trigger = btn.wheel_down, direction = -1 },
        }, function(trigger)
            self:update(self._private.data.temperature + (trigger.direction * temperature_step))
        end),
    }

    mouse_helper.grab_horizontal {
        wibox = self._private.wibar,
        widget = self:get_children_by_id("bar_container")[1],
        minimum = min_temperature,
        maximum = max_temperature,
        change = function(temperature, finish)
            if finish then
                self:update(temperature)
            else
                self:update_local_only(temperature)
            end
        end,
    }

    -- TODO: this resets the value, but it should just read the value and update the widget
    -- (currently it's "not" possible)
    self:update()

    return self
end

function redshift_widget.mt:__call(...)
    return redshift_widget.new(...)
end

return setmetatable(redshift_widget, redshift_widget.mt)
