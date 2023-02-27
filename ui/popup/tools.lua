local os = os
local awful = require("awful")
local wibox = require("wibox")
local gtable = require("gears.table")
local tcolor = require("theme.color")
local binding = require("io.binding")
local mod = binding.modifier
local btn = binding.button
local beautiful = require("beautiful")
local dpi = dpi
local capsule = require("widget.capsule")
local noice = require("theme.style")
local config = require("config")
local redshift_widget = require("ui.topbar.redshift")


local tools_popup = { mt = {} }

function tools_popup:show()
    if self.visible then
        return
    end

    self.visible = true
end

function tools_popup:hide()
    self.visible = false
end

function tools_popup:toggle()
    if self.visible then
        self:hide()
    else
        self:show()
    end
end

noice.define_style_properties(tools_popup, {
    bg = { proxy = true },
    fg = { proxy = true },
    border_color = { proxy = true },
    border_width = { proxy = true },
    shape = { proxy = true },
    placement = { proxy = true },
    paddings = { property = "paddings" },
})

function tools_popup.new(args)
    args = args or {}

    local self
    self = awful.popup {
        ontop = true,
        visible = false,
        widget = {
            enabled = false,
            widget = capsule,
            background = tcolor.transparent,
            {
                id = "#container",
                forced_width = dpi(250),
                layout = wibox.layout.fixed.vertical,
                spacing = beautiful.wibar.spacing,
            },
        },
    }

    gtable.crush(self, tools_popup, true)

    noice.initialize_style(self, self.widget, beautiful.tools_popup.default_style)

    self:apply_style(args)

    local container = self.widget:get_children_by_id("#container")[1]
    if config.features.redshift_widget then
        container:add(wibox.container.constraint(
            redshift_widget(self, true),
            "max", nil, beautiful.wibar.item_height))
    end

    self.buttons = binding.awful_buttons {}

    return self
end

function tools_popup.mt:__call(...)
    return tools_popup.new(...)
end

return setmetatable(tools_popup, tools_popup.mt)
