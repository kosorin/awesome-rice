require("develop")

require("globals")

require("config")

local dark = true
---@return Theme.default
local function toggle_light_dark()
    local theme = dark
        and require("theme.styles.default")
        or require("theme.styles.default_light")
    dark = not dark
    ---@diagnostic disable-next-line: return-type-mismatch
    return theme
end

require("theme.manager").load(toggle_light_dark())

local awful = require("awful")
local wibox = require("wibox")
local gshape = require("gears.shape")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local gears = require("gears")
local gfilesystem = require("gears.filesystem")
local binding = require("io.binding")
local btn = binding.button
local mod = binding.modifier
local stylable = require("theme.stylable")
local manager = require("theme.manager")
local pango = require("utils.pango")
local uui = require("utils.ui")
local umouse = require("utils.mouse")
local capi = Capi

capi.screen.connect_signal("request::desktop_decoration", function(screen)
    for index = 1, 5 do
        awful.tag.add(tostring(index), {
            screen = screen,
            selected = index == 1,
        })
    end
end)

capi.screen.connect_signal("request::desktop_decoration", function(screen)
    awful.wibar {
        class = "topbar",
        widget = {
            layout = wibox.container.margin,
            class = "paddings",
            {
                layout = wibox.layout.align.horizontal,
                class = "container",
                {
                    layout = wibox.layout.fixed.horizontal,
                    sid = "left",
                    wibox.widget.textbox("Hello World"),
                },
                {
                    layout = wibox.layout.fixed.horizontal,
                    sid = "middle",
                    awful.widget.taglist {
                        screen = screen,
                        filter = awful.widget.taglist.filter.all,
                        base_layout = {
                            layout = wibox.layout.fixed.horizontal,
                            class = "layout",
                        },
                        widget_template = {
                            layout = wibox.container.capsule,
                            class = "tag",
                            {
                                id = "text_role",
                                widget = wibox.widget.textbox,
                            },
                        },
                    },
                },
                {
                    layout = wibox.layout.fixed.horizontal,
                    sid = "right",
                    {
                        widget = wibox.widget.textclock,
                        class = "date",
                    },
                    {
                        widget = wibox.widget.textclock,
                        class = "time",
                    },
                    awful.widget.layoutbox(),
                },
            },
        },
    }
end)
