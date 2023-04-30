local setmetatable = setmetatable
local type = type
local pairs = pairs
local table = table
local string = string
local dpi = Dpi
local aplacement = require("awful.placement")
local gshape = require("gears.shape")
local gtable = require("gears.table")
local wibox = require("wibox")
local hcolor = require("utils.color")
local hui = require("utils.ui")
local hwidget = require("utils.widget")
local css = require("utils.css")
local pango = require("utils.pango")
local config = require("config")
local Nil = require("theme.nil")


---@class Theme.default
local theme = {}

----------------------------------------------------------------------------------------------------

theme.palette = setmetatable({
    black          = "#3c4044",
    white          = "#eaeaea",
    red            = "#d54e53",
    yellow         = "#e7c547",
    green          = "#b9ca4a",
    cyan           = "#70c0b1",
    blue           = "#7aa6da",
    magenta        = "#c397d8",
    --
    black_bright   = "#1d1f21",
    white_bright   = "#c5c8c6",
    red_bright     = "#cc6666",
    yellow_bright  = "#f0c674",
    green_bright   = "#b5bd68",
    cyan_bright    = "#8abeb7",
    blue_bright    = "#81a2be",
    magenta_bright = "#b294bb",
}, hcolor.palette_metatable)

theme.color_names = {
    palette = {
        "black",
        "white",
        "red",
        "yellow",
        "green",
        "cyan",
        "blue",
        "magenta",
    },
    common = {
        bg        = "white",
        fg        = "black",
        primary   = "blue",
        secondary = "green",
        urgent    = "red",
    },
}

theme.common = setmetatable({}, hcolor.palette_metatable)
for k, v in pairs(theme.color_names.common) do
    theme.common[k] = theme.palette[v]
    theme.common[k .. "_bright"] = theme.palette[v .. "_bright"]
end

----------------------------------------------------------------------------------------------------

---@type style_sheet.source
theme.style_sheet = {
    {
        "wibox",
        bg = theme.common.bg,
        fg = theme.common.primary_bright,
        border_color = theme.common.secondary,
        border_width = 4,
        shape = gshape.rounded_rect,
    },
    {
        "progressbar",
        forced_height = 50,
        border_color = theme.palette.red,
        border_width = 1,
        color = theme.palette.red_bright,
        background_color = theme.palette.red_33,
        shape = gshape.rounded_bar,
        bar_shape = gshape.rounded_bar,
    },
    {
        ".test",
        border_color = theme.palette.yellow,
        border_width = 4,
        bar_border_color = theme.palette.yellow,
        bar_border_width = 2,
        color = theme.palette.blue,
        background_color = theme.palette.blue_33,
    },
    {
        ".test.powerline",
        forced_height = 100,
        shape = gshape.powerline,
        bar_shape = gshape.powerline,
        paddings = hui.thickness { 10, 24 },
    },
    {
        "slider",
        bar_shape = gshape.rounded_rect,
    },
    {
        "slider:hover",
        bar_border_color = theme.common.secondary,
    },
    {
        "checkbox",
        forced_width = 20,
        forced_height = 20,
        shape = function(cr, w, h) gshape.rounded_rect(cr, w, h, 3) end,
        bg = theme.common.bg_66,
        color = theme.common.primary_bright,
        border_color = theme.common.fg_66,
        border_width = 2,
        paddings = 3,
        check_border_color = theme.common.fg_bright,
        check_shape = function(cr, w, h)
            local cross = function(cr2, w2, h2) gshape.cross(cr2, w2, h2, w2 / 5) end
            gshape.transform(cross)
                :rotate_at(w / 2, h / 2, math.pi / 4)(cr, w, h)
        end,
    },
    {
        "checkbox:hover",
        bg = theme.common.bg_110,
        color = theme.common.primary_bright_125,
    },
    {
        "checkbox:active",
        bg = theme.common.bg_120,
    },
    {
        "#profile",
        halign = "center",
        image = config.places.theme .. "/soy.png",
        clip_shape = gshape.circle,
    },
    {
        "#profile:hover",
        image = config.places.theme .. "/soy_gigachad.png",
        clip_shape = gshape.rounded_rect,
    },
    {
        "#profile:active",
        opacity = 0.5,
    },
    {
        "textbox",
        "textclock",
        font = "JetBrains Mono 12",
    },
    {
        "progressbar + textbox",
        halign = "center",
    },
    {
        "progressbar:hover",
        background_color = theme.palette.green_33,
    },
    {
        ".myclock",
        format = "%a, %b %-e (%H:%M:%S)",
        refresh = 1,
    },
    {
        "separator",
        color = theme.palette.cyan,
        span_ratio = 0.75,
        thickness = 2,
    },
    {
        "separator + separator",
        color = theme.palette.magenta,
    },
    {
        ".arrow:hover",
        border_color = theme.palette.red,
    },
    {
        "tile textbox",
        font = "Iosevka 16",
    },
    {
        "wibox #profile",
        height = 120,
    },
}

return theme
