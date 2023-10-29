local capi = Capi
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("theme.theme")
local binding = require("core.binding")
local mod = binding.modifier
local btn = binding.button
local dpi = Dpi
local capsule = require("widget.capsule")
local alayout = require("awful.layout")
local gtable = require("gears.table")
local aplacement = require("awful.placement")
local widget_helper = require("core.widget")
local mebox = require("widget.mebox")
local tag_layout_menu_template = require("ui.menu.templates.tag.layout")
local main_menu = require("ui.menu.main")
local hui = require("utils.thickness")


local layoutbox = { mt = {} }

function layoutbox:update_from_tag(tag)
    if tag.screen == self._private.wibar.screen then
        self:update()
    end
end

function layoutbox:update()
    local layout = alayout.get(self._private.wibar.screen)
    local name = alayout.getname(layout)
    local style = beautiful.layouts[name] or {}
    self.widget.text.text = style.icon and "" or name
    self.widget.icon.image = style.icon
end

function layoutbox.new(wibar)
    local self = wibox.widget {
        widget = capsule,
        margins = hui.new {
            top = beautiful.wibar.paddings.top,
            right = beautiful.capsule.default_style.margins.right,
            bottom = beautiful.wibar.paddings.bottom,
            left = beautiful.wibar.paddings.left,
        },
        paddings = hui.new {
            beautiful.capsule.default_style.paddings.top,
            dpi(10),
            beautiful.capsule.default_style.paddings.bottom,
        },
        {
            layout = wibox.layout.stack,
            {
                id = "text",
                widget = wibox.widget.textbox,
            },
            {
                id = "icon",
                widget = wibox.widget.imagebox,
                stylesheet = beautiful.build_layout_stylesheet(),
            },
        },
    }

    gtable.crush(self, layoutbox, true)

    self._private.wibar = wibar

    self._private.menu = mebox(tag_layout_menu_template.shared)

    self.buttons = binding.awful_buttons {
        binding.awful({}, btn.left, function()
            main_menu:toggle({
                placement = beautiful.wibar.build_placement(self, self._private.wibar),
            }, { source = "mouse" })
        end),
        binding.awful({}, btn.right, function()
            self._private.menu:toggle({
                tag = self._private.wibar.screen.selected_tag,
                placement = beautiful.wibar.build_placement(self, self._private.wibar),
            }, { source = "mouse" })
        end),
        binding.awful({}, btn.middle, nil, function()
            if self._private.menu.visible then
                return
            end
            local tag = self._private.wibar.screen.selected_tag
            if tag then
                tag.layout = tag.layouts[1] or tag.layout
            end
        end),
        binding.awful({}, {
            { trigger = btn.wheel_up, direction = -1 },
            { trigger = btn.wheel_down, direction = 1 },
        }, function(trigger)
            if self._private.menu.visible then
                return
            end
            alayout.inc(trigger.direction)
        end),
    }

    capi.tag.connect_signal("property::layout", function(tag) self:update_from_tag(tag) end)
    capi.tag.connect_signal("property::selected", function(tag) self:update_from_tag(tag) end)

    self:update()

    return self
end

function layoutbox.mt:__call(...)
    return layoutbox.new(...)
end

return setmetatable(layoutbox, layoutbox.mt)
