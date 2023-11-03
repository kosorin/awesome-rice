local capi = Capi
local math = math
local awful = require("awful")
local wibox = require("wibox")
local config = require("rice.config")
local binding = require("core.binding")
local mod = binding.modifier
local btn = binding.button
local beautiful = require("theme.theme")
local volume_service = require("services.volume")
local dpi = Dpi
local gshape = require("gears.shape")
local gtable = require("gears.table")
local capsule = require("widget.capsule")
local aplacement = require("awful.placement")
local widget_helper = require("core.widget")
local mebox = require("widget.mebox")
local mouse_helper = require("core.mouse")
local pango = require("utils.pango")
local css = require("utils.css")
local hui = require("utils.thickness")


local volume_widget = { mt = {} }

local styles = {
    normal = beautiful.capsule.styles.normal,
    boosted = beautiful.capsule.styles.palette.yellow,
    muted = beautiful.capsule.styles.disabled,
}
local text_format = "%2d" .. pango.thin_space .. "%%"
local error_text = "--" .. pango.thin_space .. "%"

function volume_widget:refresh()
    local data = self._private.data

    local style = (data.muted and styles.muted)
        or (data.is_set and data.volume > 100 and styles.boosted)
        or styles.normal
    self:apply_style(style)

    local volume_text = data.is_set and string.format(text_format, data.volume) or error_text
    local bar_fg = style.fg
    local bar_bg = beautiful.get_progressbar_bg(style.fg)

    local text_widget = self:get_children_by_id("text")[1]
    text_widget:set_markup(pango.span { fgcolor = bar_fg, volume_text })

    local wave1_fill = (not data.muted and data.volume <= 0) and bar_bg or bar_fg
    local wave2_fill = (not data.muted and data.volume <= 30) and bar_bg or bar_fg
    local wave3_fill = (not data.muted and data.volume <= 70) and bar_bg or bar_fg
    local icon_stylesheet = css.style {
        [".repro"] = { fill = bar_fg },
        ["#wave1"] = { fill = wave1_fill },
        ["#wave2"] = { fill = wave2_fill },
        ["#wave3"] = { fill = wave3_fill },
        [".wave"] = { visibility = not data.muted and "visible" or "collapse" },
        [".cross"] = {
            visibility = data.muted and "visible" or "collapse",
            stroke = bar_fg,
        },
    }
    local icon_widget = self:get_children_by_id("icon")[1]
    icon_widget:set_stylesheet(icon_stylesheet)

    local bar_widget = self:get_children_by_id("bar")[1]
    bar_widget:set_value(data.volume)
    bar_widget:set_color(bar_fg)
    bar_widget:set_background_color(bar_bg)
end

function volume_widget:update(data)
    if self._private.is_dragging then
        return
    end

    if data then
        self._private.data.is_set = not not data.volume
        self._private.data.volume = data.volume or 0
        self._private.data.muted = data.muted or data.muted == nil or not self._private.data.is_set
    else
        self._private.data.is_set = false
        self._private.data.volume = 0
        self._private.data.muted = true
    end

    self:refresh()
end

function volume_widget:show_tools(command)
    awful.spawn.single_instance(command, {
        titlebars_enabled = "toolbox",
        floating = true,
        ontop = true,
        sticky = true,
    }, nil, nil, function(client)
        local placement = beautiful.wibar.build_placement(self, self._private.wibar)
        placement(client)
    end)
end

function volume_widget.new(wibar)
    local self = wibox.widget {
        widget = capsule,
        margins = hui.new {
            top = beautiful.wibar.paddings.top,
            right = beautiful.capsule.default_style.margins.right,
            bottom = beautiful.wibar.paddings.bottom,
            left = beautiful.capsule.default_style.margins.left,
        },
        {
            layout = wibox.layout.fixed.horizontal,
            spacing = beautiful.capsule.item_content_spacing,
            {
                id = "icon",
                widget = wibox.widget.imagebox,
                resize = true,
                image = beautiful.icon("volume.svg"),
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
                    bar_shape = function(cr, width, height) gshape.rounded_rect(cr, width, height, dpi(4)) end,
                    max_value = 100,
                    forced_width = beautiful.capsule.bar_width,
                    forced_height = beautiful.capsule.bar_height,
                },
            },
        },
    }

    gtable.crush(self, volume_widget, true)

    self._private.data = {}

    self._private.wibar = wibar

    self._private.menu = mebox {
        item_width = dpi(180),
        placement = beautiful.wibar.build_placement(self, self._private.wibar),
        {
            text = "Open Mixer",
            icon = beautiful.icon("tune.svg"),
            icon_color = beautiful.palette.orange,
            callback = function() self:show_tools(config.apps.mixer) end,
        },
        {
            text = "Open Bluetooth",
            icon = beautiful.icon("bluetooth-settings.svg"),
            icon_color = beautiful.palette.blue,
            callback = function() self:show_tools(config.apps.bluetooth_control) end,
        },
    }

    local bar_container = self:get_children_by_id("bar_container")[1]

    self.buttons = binding.awful_buttons {
        binding.awful({}, btn.middle, function()
            if self._private.menu.visible then
                return
            end
            volume_service.toggle_mute(true)
        end),
        binding.awful({}, btn.right, function()
            self._private.menu:toggle()
        end),
        binding.awful({}, {
            { trigger = btn.wheel_up, direction = 1 },
            { trigger = btn.wheel_down, direction = -1 },
        }, function(trigger)
            if self._private.menu.visible then
                return
            end
            volume_service.change_volume(trigger.direction * 2, true)
        end),
    }

    mouse_helper.attach_slider {
        wibox = self._private.wibar,
        widget = bar_container,
        minimum = 0,
        maximum = 100,
        coerce_value = function(volume)
            return math.floor(volume)
        end,
        start = function()
            if self._private.menu.visible or self._private.is_dragging then
                return false
            end
            self._private.is_dragging = true
            return true
        end,
        update = function(volume)
            self._private.data.volume = volume
            self:refresh()
        end,
        finish = function(volume)
            self._private.is_dragging = false
            volume_service.set_volume(volume, true)
        end,
    }

    capi.awesome.connect_signal("volume::update", function(data) self:update(data) end)

    self:update()

    return self
end

function volume_widget.mt:__call(...)
    return volume_widget.new(...)
end

return setmetatable(volume_widget, volume_widget.mt)
