local capi = Capi
local beautiful = require("theme.theme")
local wibox = require("wibox")
local dpi = Dpi
local capsule = require("widget.capsule")
local gtable = require("gears.table")
local hui = require("utils.thickness")


local systray = { mt = {} }

function systray:refresh()
    local app_count = capi.awesome.systray()
    self:set_visible(app_count > 0)
end

function systray.new(wibar)
    local self = wibox.widget {
        widget = capsule,
        enable_overlay = false,
        margins = hui.new {
            top = beautiful.wibar.paddings.top,
            right = beautiful.capsule.default_style.margins.right,
            bottom = beautiful.wibar.paddings.bottom,
            left = beautiful.capsule.default_style.margins.left,
        },
        paddings = hui.new { dpi(4), dpi(10) },
        wibox.widget.systray(),
    }

    gtable.crush(self, systray, true)

    self._private.wibar = wibar

    capi.awesome.connect_signal("systray::update", function() self:refresh() end)

    self:refresh()

    return self
end

function systray.mt:__call(...)
    return systray.new(...)
end

return setmetatable(systray, systray.mt)
