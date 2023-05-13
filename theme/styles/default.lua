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

---@type style_sheet.source[]
theme.style_sheets = {
    {
        {
            "*",
            font = "FantasqueSansM Nerd Font 12",
        },
        {
            "wibar.topbar",
            position = "top",
            height = dpi(46),
            bg = theme.common.bg,
            fg = theme.common.fg,
            border_color = theme.common.bg_110,
            border_width = dpi(1),
            shape = function(cr, w, h)
                gshape.rounded_rect(cr, w, h, dpi(12))
            end,
            margins = dpi(12),
        },
        {
            "wibar.topbar .paddings",
            margins = { dpi(8), dpi(16) },
        },
        {
            "wibar.topbar .container",
            expand = "outside",
        },
        {
            "wibar.topbar #left",
            "wibar.topbar #middle",
            "wibar.topbar #right",
            spacing = dpi(32),
            spacing_widget = wibox.widget.separator,
        },
        {
            "wibar.topbar fixed#right",
            reverse = true,
        },
        {
            "wibar.topbar separator",
            orientation = "vertical",
            span_ratio = 0.6,
            thickness = dpi(1),
            color = theme.common.bg_120,
        },
        {
            "wibar.topbar taglist .layout",
            spacing = dpi(8),
        },
        {
            "wibar.topbar taglist .tag",
            forced_width = dpi(32),
            shape = function(cr, w, h)
                gshape.rounded_rect(cr, w, h, dpi(8))
            end,
        },
        {
            "wibar.topbar taglist .tag:empty",
            bg = theme.common.bg_105,
            fg = theme.common.fg_50,
            border_color = theme.common.bg_115,
            border_width = 0,
        },
        {
            "wibar.topbar taglist .tag:!empty",
            bg = theme.common.bg_110,
            fg = theme.common.fg,
            border_color = theme.common.bg_130,
            border_width = dpi(1),
        },
        {
            "wibar.topbar taglist .tag:selected",
            bg = theme.common.primary_50,
            fg = theme.common.fg_bright,
            border_color = theme.common.primary_75,
            border_width = dpi(1),
        },
        {
            "wibar.topbar taglist .tag:volatile",
            border_color = theme.common.secondary_75,
            border_width = dpi(1),
        },
        {
            "wibar.topbar taglist .tag:volatile:selected",
            bg = theme.common.secondary_50,
        },
        {
            "wibar.topbar taglist .tag:urgent",
            bg = theme.palette.red_66,
            fg = theme.common.fg_bright,
            border_color = theme.palette.red,
            border_width = dpi(1),
        },
        {
            "wibar.topbar taglist .tag textbox",
            halign = "center",
            valign = "center",
        },
        {
            "wibar.topbar textclock.date",
            format = "%a, %b %-e",
        },
        {
            "wibar.topbar textclock.time",
            format = "%-H:%M:%S",
            refresh = 1,
        },
        {
            "#bar",
            bg = theme.palette.green_33,
            border_color = theme.palette.green_50,
            shape = function(cr, w, h)
                gshape.rounded_rect(cr, w, h, dpi(6))
            end,
        },
        {
            "#foo",
            bg = theme.palette.green_66,
            fg = theme.palette.white_bright,
            border_color = theme.palette.green,
            paddings = { dpi(4), dpi(12) },
            margins = { bottom = dpi(4) },
        },
        {
            "#bar",
            "#foo",
            border_width = dpi(1),
            shape = function(cr, w, h)
                gshape.rounded_rect(cr, w, h, dpi(6))
            end,
        },
        {
            "#bar:hover",
            bg = theme.palette.green_50,
        },
        {
            "#foo:hover",
            bg = theme.palette.green_75,
        },
        {
            "#bar:active",
            margins = { top = dpi(4) },
        },
        {
            "#foo:active",
            margins = { top = dpi(2), bottom = dpi(2) },
        },
    },
}

return theme
