require("develop")

require("globals")

require("config")

local dark = true
---@return Theme
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
local beautiful = require("theme.manager")._beautiful
local stylable = require("theme.stylable")
local manager = require("theme.manager")
local pango = require("utils.pango")
local uui = require("utils.ui")
local umouse = require("utils.mouse")


awful.wibar {
    position = "top",
    widget = {
        layout = wibox.container.background,
        forced_height = 50,
        wibox.widget.textbox("WIBAR A"),
    },
}

awful.wibar {
    position = "right",
    height = 200,
    widget = {
        layout = wibox.container.background,
        forced_width = 50,
        wibox.widget.textbox("WIBAR C"),
    },
}

awful.wibar {
    position = "top",
    stretch = false,
    width = 200,
    widget = {
        layout = wibox.container.background,
        forced_height = 50,
        wibox.widget.textbox("WIBAR B"),
    },
}

if true then
    -- return
end

local icon_path = gfilesystem.get_configuration_dir() .. "/theme/icons/calendar-month.svg"
local icon = gears.color.recolor_image(icon_path, "#ff00ff")

local w = wibox {
    visible = true,
    x = 50,
    y = 50,
    width = 500,
    height = 1200,
    -- bg = "#333300",
    -- fg = "#aa00aa",
    -- border_color = "#ffff00",
    -- border_width = 2,
    widget = {
        sid = "fuu",
        layout = wibox.container.margin,
        {
            layout = wibox.container.constraint,
            width = 400,
            {
                layout = wibox.layout.fixed.vertical,
                spacing = 20,
                {
                    id = "pfp",
                    layout = wibox.container.constraint,
                    buttons = {
                        awful.button({}, 3, function()
                            manager.load(toggle_light_dark())
                        end),
                    },
                    {
                        layout = wibox.container.mirror,
                        reflection = "horizontal",
                        {
                            sid = "profile",
                            widget = wibox.widget.imagebox,
                        },
                    },
                },
                {
                    layout = wibox.container.place,
                    halign = "right",
                    {
                        widget = wibox.widget.textbox,
                        text = "foo bar place right",
                    },
                },
                {
                    widget = wibox.widget.separator,
                    forced_height = 5,
                },
                {
                    id = "pfp_slider",
                    widget = wibox.widget.slider { bar_active_color = beautiful.palette.yellow },
                    forced_height = 30,
                    bar_height = 20,
                    value = 70,
                    minimum = 20,
                    maximum = 500,
                },
                {
                    layout = wibox.layout.fixed.horizontal,
                    spacing = 10,
                    fill_space = true,
                    wibox.widget.checkbox(false),
                    wibox.widget.checkbox(true),
                },
                {
                    forced_height = 50,
                    widget = wibox.container.radialprogressbar(nil, 0, 10),
                    value = 5,
                },
                {
                    layout = wibox.container.rotate,
                    direction = "east",
                    {
                        class = "arrow",
                        widget = wibox.container.background,
                        shape = gshape.arrow,
                        bg = beautiful.palette.cyan,
                        border_width = 4,
                        {
                            widget = wibox.container.margin,
                            draw_empty = true,
                            forced_width = 50,
                        },
                    },
                },
                {
                    forced_height = 50,
                    widget = wibox.widget.progressbar,
                    class = "test",
                    value = 5,
                    max_value = 12,
                },
                {
                    widget = wibox.widget.textclock,
                    class = "myclock",
                    style = {
                        halign = "right",
                    },
                },
                {
                    forced_height = 25,
                    widget = wibox.widget.progressbar,
                    class = "test",
                    value = 5,
                    max_value = 12,
                    color = "#00ff00",
                },
                {
                    layout = wibox.container.scroll.horizontal,
                    {
                        layout = wibox.container.background,
                        bg = beautiful.palette.green_66,
                        {
                            widget = wibox.widget.textbox,
                            text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc eget auctor ligula, sed pretium nulla.",
                        },
                    },
                },
                {
                    layout = wibox.container.background,
                    bg = beautiful.palette.cyan_66,
                    fg = "#ff0000",
                    {
                        widget = wibox.container.tile,
                        horizontal_spacing = 10,
                        forced_height = 80,
                        {
                            widget = wibox.widget.textbox,
                            text = "tile",
                        },
                    },
                },
                {
                    forced_height = 50,
                    widget = wibox.widget.progressbar,
                    class = "test powerline",
                    value = 5,
                    max_value = 12,
                },
                {
                    widget = wibox.container.arcchart,
                    values = { 10, 20, 36 },
                    max_value = 100,
                    forced_height = 100,
                    colors = { "#660000", "#006600", "#000066" },
                    bg = "#555555",
                    paddings = 8,
                    thickness = 10,
                    {
                        widget = wibox.widget.textbox,
                        text = "archchart",
                    },
                },
            },
        },
    },
}

local pfp = w.widget:get_children_by_id("pfp")[1] --[[@as wibox.container.constraint]]
local pfp_slider = w.widget:get_children_by_id("pfp_slider")[1] --[[@as wibox.widget.slider]]

pfp_slider:connect_signal("property::value", function(_, value)
    pfp.height = value
end)
