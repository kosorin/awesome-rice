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
        bg        = "white",
        fg        = "black",
        primary   = "green",
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
            height = dpi(36),
            bg = theme.common.bg,
            fg = theme.common.fg,
            border_width = 0,
        },
        {
            "wibar.topbar .paddings",
            margins = { 0, dpi(16) },
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
            span_ratio = 0.4,
            thickness = dpi(1),
            color = theme.common.fg_160,
        },
        {
            ".tag",
            forced_width = dpi(32),
        },
        {
            ".tag:empty .top_border",
            visible = false,
        },
        {
            ".tag:empty capsule",
            bg = hcolor.transparent,
            fg = theme.common.fg_160,
        },
        {
            ".tag:!empty .top_border",
            visible = true,
            margins = { top = dpi(6) },
            color = theme.common.primary_75,
        },
        {
            ".tag:!empty capsule",
            bg = theme.common.bg_110,
            fg = theme.common.fg,
        },
        {
            ".tag:selected capsule",
            bg = theme.common.primary,
            fg = theme.common.fg_bright,
        },
        {
            ".tag:!volatile .bottom_border",
            visible = false,
        },
        {
            ".tag:volatile .bottom_border",
            visible = true,
            margins = { bottom = dpi(6) },
            color = theme.common.secondary_75,
        },
        {
            ".tag:urgent capsule",
            bg = theme.palette.red_66,
            fg = theme.common.fg_bright,
            border_color = theme.palette.red,
            border_width = dpi(1),
        },
        {
            ".tag textbox",
            halign = "center",
            valign = "center",
        },
        {
            "wibar.topbar textclock.date",
            format = "%b %-e (%A)",
        },
        {
            "wibar.topbar textclock.time",
            format = "%-H:%M",
        },
    },
}

return theme
