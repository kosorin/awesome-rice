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
    black          = "#282828",
    white          = "#a89984",
    red            = "#cc241d",
    yellow         = "#d79921",
    green          = "#98971a",
    cyan           = "#689d6a",
    blue           = "#458588",
    magenta        = "#b16286",
    --
    black_bright   = "#928374",
    white_bright   = "#ebdbb2",
    red_bright     = "#fb4934",
    yellow_bright  = "#fabd2f",
    green_bright   = "#b8bb26",
    cyan_bright    = "#8ec07c",
    blue_bright    = "#83a598",
    magenta_bright = "#d3869b",
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
        border_width = dpi(3),
        shape = function(cr, width, height)
            gshape.rounded_rect(cr, width, height, dpi(6))
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
            gshape.rounded_rect(cr, width, height, dpi(2))
        end,
        margins = hui.thickness { 0 },
        paddings = hui.thickness { dpi(8), dpi(16) },
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
        bg = theme.palette.blue_33,
        fg = theme.palette.blue_bright,
        border_color = theme.palette.blue_bright,
        border_width = dpi(3),
        shape = gshape.squircle,
    },
    {
        "progressbar",
        forced_height = 48,
        border_color = theme.palette.yellow_bright,
        border_width = 1,
        color = theme.palette.yellow_66,
        background_color = theme.palette.yellow_33,
        shape = gshape.powerline,
    },
    {
        "layout-fixed > :even",
        bg = theme.palette.red_50,
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
