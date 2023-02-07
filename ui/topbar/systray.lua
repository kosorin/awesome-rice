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
    local container = self._private.container
    if not container then
        return
    end

    local is_added = container:index(self)
    local app_count = capi.awesome.systray()
    if app_count > 0 and not is_added then
        container:add(self)
    elseif app_count == 0 and is_added then
        container:remove_widgets(self)
    end
end

function systray:get_container()
    return self._private.container
end

function systray:set_container(container)
    if self._private.container == container then
        return
    end

    local old_container = self._private.container
    if old_container then
        old_container:remove_widgets(self)
    end

    self._private.container = container
    self:refresh()
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
