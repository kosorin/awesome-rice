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


---@class Theme.tomorrow_night
local theme = {}

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
        "popup",
        width = Nil,
        height = Nil,
        bg = theme.common.bg,
        fg = theme.common.fg,
        border_color = theme.common.bg_bright,
        border_width = dpi(1),
        shape = function(cr, width, height)
            gshape.rounded_rect(cr, width, height, dpi(16))
        end,
        paddings = hui.thickness { dpi(20) },
    },
    {
        "capsule",
        bg = theme.common.bg_110,
        fg = theme.common.fg,
        border_color = theme.common.bg_130,
        border_width = 0,
        shape = function(cr, width, height)
            gshape.rounded_rect(cr, width, height, dpi(8))
        end,
        margins = hui.thickness { 0 },
        paddings = hui.thickness { dpi(6), dpi(14) },
        highlight = Nil,
    },
    {
        "button:hover",
        highlight = hcolor.white .. "10",
    },
    {
        "button:active",
        highlight = hcolor.white .. "20",
    },
    {
        ".foobar",
        bg = theme.palette.yellow_33,
        fg = theme.palette.yellow_bright,
        border_color = theme.palette.yellow_bright,
        border_width = dpi(1),
        shape = false,
    },
    {
        "progressbar",
        forced_height = 24,
        border_color = theme.palette.red_bright,
        border_width = 1,
        color = theme.palette.red_bright,
        background_color = theme.palette.red_33,
        shape = gshape.rounded_bar,
        bar_shape = gshape.rounded_bar,
    },
    {
        "capsule > capsule.child",
        bg = "#000066",
    },
    {
        ".descendant capsule > progressbar",
        bar_border_color = "#009900",
        bar_border_width = 4,
    },
}

do
    local function generate_capsule_color_style(color)
        return {
            "." .. color,
            bg = theme.palette[color .. "_33"],
            fg = theme.palette[color .. "_bright"],
            border_color = theme.palette[color .. "_66"],
        }
    end

    for _, color in pairs(theme.color_names.palette) do
        theme.style_sheet[#theme.style_sheet + 1] = generate_capsule_color_style(color)
    end
end

return theme
