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
    black          = "#1d1f21",
    white          = "#c5c8c6",
    red            = "#cc6666",
    yellow         = "#f0c674",
    green          = "#b5bd68",
    cyan           = "#8abeb7",
    blue           = "#81a2be",
    magenta        = "#b294bb",
    --
    black_bright   = "#3c4044",
    white_bright   = "#eaeaea",
    red_bright     = "#d54e53",
    yellow_bright  = "#e7c547",
    green_bright   = "#b9ca4a",
    cyan_bright    = "#70c0b1",
    blue_bright    = "#7aa6da",
    magenta_bright = "#c397d8",
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
        bg        = "black",
        fg        = "white",
        primary   = "yellow",
        secondary = "blue",
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
        "textbox",
        font = "JetBrains Mono 12",
    },
    {
        "progressbar + textbox",
        halign = "center",
    },
}

return theme
