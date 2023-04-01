local capi = Capi
local awful = require("awful")
local wibox = require("wibox")
local gtimer = require("gears.timer")
local tcolor = require("utils.color")
local binding = require("io.binding")
local mod = binding.modifier
local btn = binding.button
local beautiful = require("theme.manager")._beautiful
local dpi = Dpi
local aplacement = require("awful.placement")
local gshape = require("gears.shape")
local gtable = require("gears.table")
local gcolor = require("gears.color")
local capsule = require("widget.capsule")
local pango = require("utils.pango")
local css = require("utils.css")
local config = require("config")
local uui = require("utils.ui")
local noice = require("theme.stylable")
local popup = require("widget.popup")
local progressbar = require("widget.progressbar")


---@class VolumeOsd.module
local M = {}


---@class VolumeOsd.data
---@field is_set boolean
---@field volume number
---@field muted boolean
---@field skip_osd? boolean

---@class VolumeOsd : Popup
---@field package _private VolumeOsd.private
M.object = {}
---@class VolumeOsd.private : Popup.private
---@field timer gears.timer
---@field data VolumeOsd.data

noice.define {
    object = M.object,
    name = "volume_osd",
    properties = {
        spacing = { property = "spacing" },
        bar_style = { id = "#bar", property = "style" },
        font = { id = "#text", property = "font" },
    },
}

do
    local text_format = "%2d" .. pango.thin_space .. "%%"
    local error_text = "--" .. pango.thin_space .. "%"

    function M.object:refresh()
        local data = self._private.data

        -- TODO:
        -- self:set_states {
        --     volume = (data.muted and "muted")
        --         or (data.is_set and data.volume > 100 and "boosted")
        --         or false,
        -- }

        local text = data.is_set and string.format(text_format, data.volume) or error_text
        local text_widget = self:get_children_by_id("#text")[1] --[[@as wibox.widget.textbox]]
        text_widget:set_markup(text)

        local bar_fg = gcolor.ensure_pango_color(self._style.current.bar_fg)
        local bar_bg = gcolor.ensure_pango_color(self._style.current.bar_bg)
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
        local icon_widget = self:get_children_by_id("#icon")[1] --[[@as wibox.widget.imagebox]]
        icon_widget:set_stylesheet(icon_stylesheet)

        local bar_widget = self:get_children_by_id("#bar")[1] --[[@as wibox.widget.progressbar]]
        bar_widget:set_value(data.volume)
    end
end

---@param data? VolumeOsd.data
function M.object:update(data)
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

---@override
function M.object:hide()
    popup.object.hide(self)

    self._private.timer:stop()
end

---@param data VolumeOsd.data
function M.object:try_show(data)
    if data.skip_osd then
        return
    end

    self._private.timer:again()

    self:update(data)
    self:show()
end


---@return VolumeOsd
function M.new()
    local self = popup.new {
        placement = beautiful.volume_osd.placement,
        widget = {
            layout = wibox.layout.fixed.horizontal,
            {
                id = "#icon",
                widget = wibox.widget.imagebox,
                resize = true,
                image = config.places.theme .. "/icons/volume.svg",
            },
            {
                id = "#text",
                widget = wibox.widget.textbox,
            },
            {
                layout = wibox.container.place,
                valign = "center",
                {
                    id = "#bar",
                    widget = progressbar,
                    max_value = 100,
                },
            },
        },
    } --[[@as VolumeOsd]]

    gtable.crush(self, M.object, true)
    noice.initialize(self, nil, self:get_widget())

    self._private.data = {}

    self._private.timer = gtimer {
        timeout = 2,
        call_now = false,
        autostart = false,
        callback = function() self:hide() end,
    }

    capi.awesome.connect_signal("volume::update", function(data) self:try_show(data) end)

    self:update()

    self:set_buttons(binding.awful_buttons {
        binding.awful({}, btn.any, function() self:hide() end),
    })

    return self
end

return M.new()
