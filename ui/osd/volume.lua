local capi = {
    awesome = awesome,
    mousegrabber = mousegrabber,
    screen = screen,
}
local awful = require("awful")
local wibox = require("wibox")
local gtimer = require("gears.timer")
local tcolor = require("theme.color")
local binding = require("io.binding")
local mod = binding.modifier
local btn = binding.button
local beautiful = require("beautiful")
local dpi = dpi
local gshape = require("gears.shape")
local gtable = require("gears.table")
local capsule = require("widget.capsule")
local pango = require("utils.pango")
local config = require("config")
local htable = require("helpers.table")


local volume_osd = {}

local styles = {
    normal = htable.crush_clone(beautiful.capsule.styles.normal, { border_width = 0 }),
    boosted = htable.crush_clone(beautiful.capsule.styles.palette.yellow, { border_width = 0 }),
    muted = htable.crush_clone(beautiful.capsule.styles.palette.gray, { border_width = 0 }),
}
local text_format = "%2d" .. pango.thin_space .. "%%"
local error_text = "--" .. pango.thin_space .. "%"

function volume_osd:refresh()
    local data = self._private.data

    local style = (data.muted and styles.muted)
        or (data.is_set and data.volume > 100 and styles.boosted)
        or styles.normal
    local container = self.widget:get_children_by_id("container")[1]
    container:apply_style(style)
    self.border_color = style.border_color

    local volume_text = data.is_set and string.format(text_format, data.volume) or error_text
    local volume_color = style.foreground
    local volume_background_color = beautiful.get_progressbar_background_color(style.foreground)

    local text_widget = self.widget:get_children_by_id("text")[1]
    text_widget:set_markup(pango.span { foreground = volume_color, volume_text })

    local wave1_fill = (not data.muted and data.volume <= 0) and volume_background_color or volume_color
    local wave2_fill = (not data.muted and data.volume <= 30) and volume_background_color or volume_color
    local wave3_fill = (not data.muted and data.volume <= 70) and volume_background_color or volume_color
    local icon_stylesheet = ""
        .. ".repro { fill: " .. volume_color .. "; } "
        .. "#wave1 { fill: " .. wave1_fill .. "; } "
        .. "#wave2 { fill: " .. wave2_fill .. "; } "
        .. "#wave3 { fill: " .. wave3_fill .. "; } "
        .. ".wave { visibility: " .. (not data.muted and "visible" or "collapse") .. "; } "
        .. ".cross { visibility: " .. (data.muted and "visible" or "collapse")
        .. "; stroke: " .. volume_color .. "; } "
    local icon_widget = self.widget:get_children_by_id("icon")[1]
    icon_widget:set_stylesheet(icon_stylesheet)

    local bar_widget = self.widget:get_children_by_id("bar")[1]
    bar_widget:set_value(data.volume)
    bar_widget:set_color(volume_color)
    bar_widget:set_background_color(volume_background_color)
end

function volume_osd:update(data)
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

function volume_osd:hide()
    self.visible = false
    self.screen = nil

    self._private.timer:stop()
end

function volume_osd:try_show(data)
    if data.skip_osd then
        return
    end

    local screen = awful.screen.focused()
    if not screen then
        return
    end

    self:update(data)

    self.screen = screen
    self.visible = true

    self._private.timer:again()
end

function volume_osd.new()
    local self = awful.popup {
        ontop = true,
        visible = false,
        placement = function(d)
            awful.placement.top(d, {
                honor_workarea = true,
                margins = dpi(32),
            })
        end,
        shape = function(cr, width, height)
            gshape.rounded_rect(cr, width, height, dpi(16))
        end,
        bg = tcolor.transparent,
        border_width = dpi(2),
        widget = {
            layout = wibox.container.constraint,
            strategy = "exact",
            width = dpi(360),
            height = dpi(84),
            {
                id = "container",
                enabled = false,
                widget = capsule,
                paddings = {
                    left = dpi(32),
                    right = dpi(32),
                    top = dpi(16),
                    bottom = dpi(16),
                },
                {
                    layout = wibox.layout.fixed.horizontal,
                    spacing = dpi(16),
                    {
                        id = "icon",
                        widget = wibox.widget.imagebox,
                        resize = true,
                        image = config.places.theme .. "/icons/volume.svg",
                    },
                    {
                        id = "text",
                        widget = wibox.widget.textbox,
                        font = beautiful.build_font(1.6),
                    },
                    {
                        layout = wibox.container.place,
                        valign = "center",
                        {
                            id = "bar",
                            widget = wibox.widget.progressbar,
                            shape = function(cr, width, height) gshape.rounded_rect(cr, width, height, dpi(6)) end,
                            bar_shape = function(cr, width, height) gshape.rounded_rect(cr, width, height, dpi(4)) end,
                            max_value = 100,
                            forced_height = dpi(24),
                        },
                    },
                },
            },
        },
    }

    gtable.crush(self, volume_osd, true)

    self._private.data = {}

    self._private.timer = gtimer {
        timeout = 2,
        call_now = false,
        autostart = false,
        callback = function() self:hide() end,
    }

    self.buttons = binding.awful_buttons {
        binding.awful({}, { btn.left }, function() self:hide() end),
    }

    capi.awesome.connect_signal("volume::update", function(data) self:try_show(data) end)

    self:update()

    return self
end

return volume_osd.new()
