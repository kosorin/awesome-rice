local capi = {
    awesome = awesome,
}
local beautiful = require("beautiful")
local wibox = require("wibox")
local dpi = dpi
local capsule = require("widget.capsule")
local gtable = require("gears.table")


local systray = { mt = {} }

function systray:refresh()
    local app_count = capi.awesome.systray()
    self:set_visible(app_count > 0)
end

function systray.new(wibar)
    local self = wibox.widget {
        widget = capsule,
        enabled = false,
        margins = {
            left = beautiful.capsule.default_style.margins.left,
            right = beautiful.capsule.default_style.margins.right,
            top = beautiful.wibar.padding.top,
            bottom = beautiful.wibar.padding.bottom,
        },
        paddings = {
            left = dpi(10),
            right = dpi(10),
            top = dpi(4),
            bottom = dpi(4),
        },
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
