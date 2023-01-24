local capi = {
    awesome = awesome,
    mouse = mouse,
}
local table = table
local awful = require("awful")
local wibox = require("wibox")
local binding = require("io.binding")
local mod = binding.modifier
local btn = binding.button
local beautiful = require("beautiful")
local weather_service = require("services.weather")
local weather_popup = require("ui.popup.weather")
local dpi = dpi
local config = require("config")
local capsule = require("widget.capsule")
local mebox = require("widget.mebox")
local gtable = require("gears.table")
local setmetatable = setmetatable
local aplacement = require("awful.placement")
local widget_helper = require("helpers.widget")
local pango = require("utils.pango")


local function set_text(widget, id, index, text, color)
    widget:get_children_by_id(id)[index]:set_markup(pango.span { foreground = color, text, })
end

local function set_icon(widget, id, index, icon, color)
    local icon_widget = widget:get_children_by_id(id)[index]
    if icon then
        icon_widget:set_image(icon)
    end
    if color then
        icon_widget:set_stylesheet("path { fill: " .. color .. "; }")
    end
end

local weather_widget = { mt = {} }

function weather_widget:refresh()
    local response = weather_service.last_response

    local list_layout = self.widget
    list_layout:reset()
    if response.success then
        local data = response.data
        local is_rain = data.precipitation_rate > 0
        local style = is_rain
            and beautiful.capsule.styles.palette.blue
            or beautiful.capsule.styles.normal
        self:apply_style(style)

        if is_rain then
            local precipitation_rate_text = string.format("%.1f" .. pango.thin_space .. "mm/h", data.precipitation_rate)
            set_text(self._private.widgets.precipitation, "text", 1, precipitation_rate_text, style.foreground)
            set_icon(self._private.widgets.precipitation, "icon", 1, nil, style.foreground)
            list_layout:add(self._private.widgets.precipitation)
        end

        local temperature_text = string.format("%.1f" .. pango.thin_space .. "&#176;C", data.temperature)
        set_text(self._private.widgets.temperature, "text", 1, temperature_text, style.foreground)
        set_icon(self._private.widgets.temperature, "icon", 1, nil, style.foreground)
        list_layout:add(self._private.widgets.temperature)

        local indoor_text = string.format("%.1f" .. pango.thin_space .. "&#176;C", data.indoor_temperature)
        set_text(self._private.widgets.indoor, "text", 1, indoor_text, style.foreground)
        set_icon(self._private.widgets.indoor, "icon", 1, nil, style.foreground)
        list_layout:add(self._private.widgets.indoor)
    else
        local style = beautiful.capsule.styles.disabled
        self:apply_style(style)

        local text = response.success == nil and "loading" or "unknown"
        set_text(self._private.widgets.info, "text", 1, text, style.foreground)
        set_icon(self._private.widgets.info, "icon", 1, nil, style.foreground)

        list_layout:add(self._private.widgets.info)
    end
end

function weather_widget.new(wibar)
    local self = capsule()

    gtable.crush(self, weather_widget, true)

    self._private.wibar = wibar

    self._private.widgets = {
        info = wibox.widget {
            layout = wibox.layout.fixed.horizontal,
            spacing = beautiful.capsule.item_content_spacing,
            {
                id = "icon",
                widget = wibox.widget.imagebox,
                resize = true,
                image = beautiful.dir .. "/icons/thermometer.svg",
            },
            {
                id = "text",
                widget = wibox.widget.textbox,
            },
        },
        precipitation = wibox.widget {
            layout = wibox.layout.fixed.horizontal,
            spacing = beautiful.capsule.item_content_spacing,
            {
                id = "icon",
                widget = wibox.widget.imagebox,
                resize = true,
                image = beautiful.dir .. "/icons/weather-pouring.svg",
            },
            {
                id = "text",
                widget = wibox.widget.textbox,
            },
        },
        temperature = wibox.widget {
            layout = wibox.layout.fixed.horizontal,
            spacing = beautiful.capsule.item_content_spacing,
            buttons = binding.awful_buttons {
                binding.awful({}, btn.left, function()
                    if wibar then
                        self._private.popups.indoor:hide()
                        self._private.popups.temperature:toggle()
                    end
                end),
            },
            {
                id = "icon",
                widget = wibox.widget.imagebox,
                resize = true,
                image = beautiful.dir .. "/icons/thermometer.svg",
            },
            {
                id = "text",
                widget = wibox.widget.textbox,
            },
        },
        indoor = wibox.widget {
            layout = wibox.layout.fixed.horizontal,
            spacing = beautiful.capsule.item_content_spacing,
            buttons = binding.awful_buttons {
                binding.awful({}, btn.left, function()
                    if wibar then
                        self._private.popups.temperature:hide()
                        self._private.popups.indoor:toggle()
                    end
                end),
            },
            {
                id = "icon",
                widget = wibox.widget.imagebox,
                resize = true,
                image = beautiful.dir .. "/icons/home-thermometer.svg",
            },
            {
                id = "text",
                widget = wibox.widget.textbox,
            },
        },
    }

    if wibar then
        self._private.popups = {
            temperature = weather_popup.new_temperature {
                wibar = wibar,
                widget = self._private.widgets.temperature,
            },
            indoor = weather_popup.new_indoor {
                wibar = wibar,
                widget = self._private.widgets.indoor,
            },
        }
    end

    self._private.menu = mebox {
        item_width = dpi(180),
        placement = function(menu)
            aplacement.wibar(menu, {
                geometry = widget_helper.find_geometry(self, self._private.wibar),
                position = "bottom",
                anchor = "middle",
                honor_workarea = true,
                honor_padding = false,
                margins = beautiful.wibar_popup_margin,
            })
        end,
        {
            text = "open dashboard",
            icon = beautiful.dir .. "/icons/open-in-new.svg",
            icon_color = beautiful.palette.gray,
            callback = function()
                awful.spawn.spawn(config.commands.open(weather_service.config.dashboard_url))
            end,
        },
        mebox.separator,
        {
            text = "refresh",
            icon = beautiful.dir .. "/icons/refresh.svg",
            icon_color = beautiful.palette.gray,
            callback = function()
                weather_service.update()
            end,
        },
    }

    self.buttons = binding.awful_buttons {
        binding.awful({}, btn.right, function()
            self._private.menu:toggle()
        end),
    }

    self.widget = {
        layout = wibox.layout.fixed.horizontal,
        spacing = beautiful.capsule.item_spacing,
    }

    self:refresh()

    capi.awesome.connect_signal("weather::updated", function() self:refresh() end)

    return self
end

function weather_widget.mt:__call(...)
    return weather_widget.new(...)
end

return setmetatable(weather_widget, weather_widget.mt)
