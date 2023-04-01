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


---@class Theme
local theme = {}

----------------------------------------------------------------------------------------------------

local main_border_radius = dpi(16)

----------------------------------------------------------------------------------------------------

theme.gap = dpi(6)

----------------------------------------------------------------------------------------------------

theme.icon_theme = "Archdroid-Amber"

----------------------------------------------------------------------------------------------------

theme.font_name = "FantasqueSansMono Nerd Font"
theme.font_size = 12

-- TODO: Move to the utils?
---@param args? { name?: string, size?: number, size_factor?: number, style?: string|string[] }
---@return string
function theme.build_font(args)
    if not args then
        return theme.font_name .. " " .. theme.font_size
    end

    local font = args.name or theme.font_name

    if args.style then
        local style
        if type(args.style) == "table" then
            style = table.concat(args.style --[[@as table]], " ")
        elseif type(args.style) == "string" then
            style = args.style
        end
        if style then
            font = font .. " " .. style
        end
    end

    args.size = args.size or theme.font_size
    args.size_factor = args.size_factor or 1
    font = font .. " " .. string.format("%.0f", args.size * args.size_factor)

    return font
end

----------------------------------------------------------------------------------------------------

-- Tomorrow Night (https://github.com/chriskempson/tomorrow-theme)
theme.palette = setmetatable({
    black          = "#1d1f21",
    white          = "#c5c8c6",
    red            = "#cc6666",
    orange         = "#de935f",
    yellow         = "#f0c674",
    green          = "#7cb36b", -- original: #b5bd68
    cyan           = "#78bab9", -- original: #8abeb7
    blue           = "#81a2be",
    magenta        = "#b294bb",
    gray           = "#767876",
    --
    black_bright   = "#3c4044",
    white_bright   = "#eaeaea",
    red_bright     = "#d54e53",
    orange_bright  = "#e78c45",
    yellow_bright  = "#e7c547",
    green_bright   = "#71c464", -- original: #b9ca4a
    cyan_bright    = "#6acdcc", -- original: #70c0b1
    blue_bright    = "#7aa6da",
    magenta_bright = "#c397d8",
    gray_bright    = "#a7aaa8",
}, hcolor.palette_metatable)

theme.color_names = {
    palette = {
        "black",
        "white",
        "red",
        "orange",
        "yellow",
        "green",
        "cyan",
        "blue",
        "magenta",
        "gray",
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

function theme.get_progressbar_bg(color)
    -- TODO: Solid color instead of alpha
    return hcolor.change(color, { alpha = 0.25 })
end

----------------------------------------------------------------------------------------------------

theme.screen_selection_border_width = dpi(1)
theme.screen_selection_color = hcolor.change(theme.common.primary, { alpha = 0.20 --[[ 0x33 ]] })

----------------------------------------------------------------------------------------------------

theme.wibar = {
    bg = theme.common.bg,
    spacing = dpi(12),
    paddings = hui.thickness { dpi(8), dpi(16) },
}

theme.wibar.item_height = dpi(30)
theme.wibar.height = theme.wibar.item_height + theme.wibar.paddings.top + theme.wibar.paddings.bottom

-- TODO: Rename `theme.wibar.build_placement`
function theme.wibar.build_placement(widget, wibar, args)
    return function(d)
        aplacement.next_to_widget(d, gtable.crush({
            geometry = hwidget.find_geometry(widget, wibar),
            position = "bottom",
            anchor = "middle",
            outside = true,
            screen = wibar.screen,
            margins = theme.popup.margins,
        }, args or {}))
    end
end

----------------------------------------------------------------------------------------------------

theme.capsule = {
    -- TODO: Move these into `default_style`?
    item_content_spacing = dpi(8),
    item_spacing = dpi(16),
    bar_width = dpi(80),
    bar_height = dpi(12),
    border_radius = dpi(8),
}

theme.capsule.default_style = {
    default = {
        bg = theme.common.bg_110,
        fg = theme.common.fg,
        border_color = theme.common.bg_130,
        border_width = 0,
        shape = function(cr, width, height)
            gshape.rounded_rect(cr, width, height, theme.capsule.border_radius)
        end,
        margins = hui.thickness { 0 },
        paddings = hui.thickness { dpi(6), dpi(14) },
        highlight = Nil,
    },
    precedence = { "mouse" },
    mouse = {
        states = {
            mouse_over = {
                highlight = hcolor.white .. "10",
            },
            button_pressed = {
                highlight = hcolor.white .. "20",
            },
        },
    },
}

theme.capsule.styles = {
    normal = {
        bg = theme.common.bg_110,
        fg = theme.common.fg,
        border_color = theme.common.bg_130,
        border_width = 0,
    },
    disabled = {
        bg = theme.common.bg_105,
        fg = theme.common.fg_50,
        border_color = theme.common.bg_115,
        border_width = 0,
    },
    selected = {
        bg = theme.common.bg_125,
        fg = theme.common.fg_bright,
        border_color = theme.common.bg_145,
        border_width = dpi(1),
    },
    urgent = {
        bg = theme.palette.red_66,
        fg = theme.common.fg_bright,
        border_color = theme.palette.red,
        border_width = dpi(1),
    },
}

theme.capsule.styles.palette = {}
do
    local function generate_capsule_color_style(color)
        return {
            bg = theme.palette[color .. "_33"],
            fg = theme.palette[color .. "_bright"],
            border_color = theme.palette[color .. "_66"],
            border_width = dpi(1),
        }
    end

    for _, color in pairs(theme.color_names.palette) do
        theme.capsule.styles.palette[color] = generate_capsule_color_style(color)
    end
end

----------------------------------------------------------------------------------------------------

theme.popup = {
    margins = hui.thickness { dpi(6) },
}

theme.popup.default_style = {
    default = {
        width = Nil,
        height = Nil,
        opacity = 1,
        bg = theme.common.bg,
        fg = theme.common.fg,
        border_color = theme.common.bg_bright,
        border_width = dpi(1),
        shape = function(cr, width, height)
            gshape.rounded_rect(cr, width, height, main_border_radius)
        end,
        paddings = hui.thickness { dpi(20) },
    },
}

----------------------------------------------------------------------------------------------------

theme.mebox = {
    checkmark = {
        [false] = {
            icon = config.places.theme .. "/icons/_blank.svg",
            color = theme.palette.gray,
        },
        [true] = {
            icon = config.places.theme .. "/icons/check.svg",
            color = theme.common.fg,
        },
    },
    checkbox = {
        [false] = {
            icon = config.places.theme .. "/icons/checkbox-blank-outline.svg",
            color = theme.palette.gray,
        },
        [true] = {
            icon = config.places.theme .. "/icons/checkbox-marked.svg",
            color = theme.palette.gray_bright,
        },
    },
    radiobox = {
        [false] = {
            icon = config.places.theme .. "/icons/radiobox-blank.svg",
            color = theme.palette.gray,
        },
        [true] = {
            icon = config.places.theme .. "/icons/radiobox-marked.svg",
            color = theme.palette.gray_bright,
        },
    },
    switch = {
        [false] = {
            icon = config.places.theme .. "/icons/toggle-switch-off-outline.svg",
            color = theme.palette.gray,
        },
        [true] = {
            icon = config.places.theme .. "/icons/toggle-switch.svg",
            color = theme.palette.gray_bright,
        },
    },
    item_styles = {
        normal = {
            normal = {
                hover_overlay = hcolor.white .. "20",
                press_overlay = hcolor.white .. "20",
                bg = hcolor.transparent,
                fg = theme.common.fg,
                border_color = theme.common.bg_130,
                border_width = 0,
            },
            active = {
                hover_overlay = hcolor.white .. "20",
                press_overlay = hcolor.white .. "20",
                bg = hcolor.transparent,
                fg = theme.common.secondary_bright,
                border_color = theme.common.bg_130,
                border_width = 0,
            },
            urgent = {
                hover_overlay = theme.common.urgent_bright .. "40",
                press_overlay = hcolor.white .. "10",
                bg = hcolor.transparent,
                fg = theme.common.fg,
                border_color = theme.common.bg_130,
                border_width = 0,
            },
        },
        selected = {
            normal = setmetatable({ border_width = 0 }, { __index = theme.capsule.styles.palette[theme.color_names.common.primary] }),
            active = setmetatable({ border_width = 0 }, { __index = theme.capsule.styles.palette[theme.color_names.common.secondary] }),
            urgent = setmetatable({ border_width = 0 }, { __index = theme.capsule.styles.palette.red }),
        },
    },
}

theme.mebox.default_style = {
    default = {
        placement_bounding_args = {
            honor_workarea = true,
            honor_padding = false,
            margins = theme.popup.margins,
        },
        placement = false,
        submenu_offset = dpi(4),
        active_opacity = 1,
        inactive_opacity = 1,
        paddings = hui.thickness { dpi(8) },
        item_width = dpi(128),
        item_height = dpi(36),
    },
}

----------------------------------------------------------------------------------------------------

theme.bindbox = {}

theme.bindbox.default_style = {
    default = {
        bg = hcolor.change(theme.common.bg, { alpha = 0.85 }),
        font = theme.build_font(),
        placement = function(d)
            aplacement.centered(d, {
                honor_workarea = true,
                honor_padding = false,
            })
        end,
        page_paddings = hui.thickness { dpi(8), bottom = dpi(16) },
        page_width = dpi(1400),
        page_height = dpi(1000),
        page_columns = 2,
        group_spacing = dpi(16),
        item_spacing = dpi(8),
        trigger_bg = theme.common.fg,
        trigger_bg_alpha = "20%",
        trigger_fg = theme.common.fg,
        group_bg = theme.common.primary_50,
        group_fg = theme.common.fg_bright,
        group_ruled_bg = theme.common.urgent_50,
        group_ruled_fg = theme.common.fg_bright,
        find_dim_bg = nil,
        find_dim_fg = theme.common.fg_66,
        find_highlight_bg = nil,
        find_highlight_fg = theme.common.urgent_bright,
        group_path_separator_markup = pango.span { fgalpha = "50%", "  " },
        slash_separator_markup = pango.span { fgalpha = "50%", size = "smaller", " / " },
        plus_separator_markup = pango.span { fgalpha = "50%", "+" },
        range_separator_markup = pango.span { fgalpha = "50%", ".." },
        status_style = {
            -- TODO: Fix me - capsule:set_style() no longer exists
            bg = theme.palette.black_50,
            fg = theme.common.fg,
            border_color = theme.palette.black_115,
            border_width = dpi(1),
            paddings = hui.thickness { dpi(12), dpi(16) },
        },
        status_spacing = dpi(24),
        find_placeholder_fg = theme.common.fg_66,
        find_cursor_bg = theme.common.secondary_66,
        find_cursor_fg = theme.common.fg_bright,
    },
}

----------------------------------------------------------------------------------------------------

theme.media_player = {}

theme.media_player.content_styles = {
    normal = setmetatable({
        bg = theme.common.bg_105,
        fg = theme.common.fg,
        border_width = 0,
    }, { __index = theme.capsule.styles.normal }),
    disabled = setmetatable({
        bg = theme.common.bg_105,
        fg = theme.common.fg_50,
        border_width = 0,
    }, { __index = theme.capsule.styles.disabled }),
}

----------------------------------------------------------------------------------------------------

theme.volume_osd = {
    default_style = {
        default = {
            width = dpi(320),
            height = dpi(80),
            bg = theme.common.bg,
            fg = theme.common.fg,
            border_color = theme.common.bg_bright,
            border_width = dpi(1),
            paddings = hui.thickness { dpi(24), dpi(32) },
            spacing = dpi(16),
            bar_style = {
                color = theme.common.fg,
                background_color = theme.get_progressbar_bg(theme.common.fg),
                margins = hui.thickness { 4, 0 },
                shape = function(cr, width, height) gshape.rounded_rect(cr, width, height, dpi(6)) end,
                bar_shape = function(cr, width, height) gshape.rounded_rect(cr, width, height, dpi(6)) end,
            },
            font = theme.build_font { size_factor = 1.6 },
        },
        precedence = { "volume" },
        volume = {
            states = {
                boosted = {
                    bg = theme.capsule.styles.palette.yellow.bg,
                    fg = theme.capsule.styles.palette.yellow.fg,
                    border_color = theme.capsule.styles.palette.yellow.border_color,
                    bar_style = {
                        color = theme.capsule.styles.palette.yellow.fg,
                        background_color = theme.get_progressbar_bg(theme.capsule.styles.palette.yellow.fg),
                    },
                },
                muted = {
                    fg = theme.common.fg_50,
                    bar_style = {
                        color = theme.common.fg_50,
                        background_color = theme.get_progressbar_bg(theme.common.fg_50),
                    },
                },
            },
        },
    },
    placement = function(d)
        aplacement.top(d, {
            honor_workarea = true,
            margins = hui.thickness { dpi(32) },
        })
    end,
}

----------------------------------------------------------------------------------------------------

theme.tools_popup = {
    default_style = {},
}

----------------------------------------------------------------------------------------------------

theme.calendar_popup = {
    default_style = {},
}

do
    local function is_weekend(date)
        return date.wday == 1 or date.wday == 7
    end

    local function calendar_item_shape(cr, width, height)
        gshape.rounded_rect(cr, width, height, dpi(3))
    end

    function theme.calendar_popup.default_style.embed(widget, flag, date)
        if flag == "normal" then
            widget.halign = "center"
            widget.valign = "center"
            return wibox.widget {
                widget = wibox.container.background,
                bg = is_weekend(date) and theme.common.bg_127 or theme.common.bg_115,
                shape = calendar_item_shape,
                widget,
            }
        elseif flag == "focus" then
            widget.halign = "center"
            widget.valign = "center"
            return wibox.widget {
                widget = wibox.container.background,
                bg = theme.common.primary_66,
                fg = theme.common.fg_bright,
                shape = calendar_item_shape,
                widget,
            }
        elseif flag == "normal_other" then
            widget.halign = "center"
            widget.valign = "center"
            widget.markup = pango.span { fgcolor = theme.common.fg_50, widget.text }
            return widget
        elseif flag == "focus_other" then
            widget.halign = "center"
            widget.valign = "center"
            return wibox.widget {
                widget = wibox.container.background,
                bg = theme.common.primary_50,
                fg = theme.common.fg,
                shape = calendar_item_shape,
                widget,
            }
        elseif flag == "weeknumber" then
            widget.halign = "right"
            widget.valign = "center"
            widget.markup = pango.span { fgcolor = theme.common.fg_50, weight = "bold", widget.text, " " }
            return wibox.widget {
                widget = wibox.container.margin,
                margins = hui.thickness { dpi(6), 0 },
                widget,
            }
        elseif flag == "weekday" then
            widget.halign = "center"
            return wibox.widget {
                widget = wibox.container.margin,
                margins = hui.thickness { dpi(2), dpi(4) },
                widget,
            }
        elseif flag == "monthheader" or flag == "header" then
            widget.halign = "center"
            widget.markup = pango.b(widget.text)
            return wibox.widget {
                widget = wibox.container.margin,
                margins = hui.thickness { dpi(6), 0, dpi(14) },
                widget,
            }
        elseif flag == "month" then
            return widget
        else
            return widget
        end
    end
end

----------------------------------------------------------------------------------------------------

theme.taglist = {
    rename = {
        bg = theme.common.secondary_66,
        fg = theme.common.fg_bright,
    },
}

theme.taglist.item = {
    normal = setmetatable({
        border_width = dpi(1),
    }, { __index = theme.capsule.styles.normal }),
    active = setmetatable({
        bg           = theme.common.primary_50,
        fg           = theme.common.fg_bright,
        border_color = theme.common.primary_75,
        border_width = dpi(1),
    }, { __index = theme.capsule.styles.normal }),
    urgent = setmetatable({
    }, { __index = theme.capsule.styles.urgent }),
    empty = setmetatable({
    }, { __index = theme.capsule.styles.disabled }),
    volatile = setmetatable({
        border_color = theme.common.secondary_75,
        border_width = dpi(1),
    }, { __index = theme.capsule.styles.normal }),
}

----------------------------------------------------------------------------------------------------

theme.clientlist = {
    rename = {
        bg = theme.common.secondary_66,
        fg = theme.common.fg_bright,
    },
    enable_glyphs = false,
    glyphs = {
        sticky = " ",
        ontop = " ",
        above = " ",
        below = " ",
        floating = " ",
        maximized = " ",
        maximized_horizontal = " ",
        maximized_vertical = "",
        minimized = " ",
    },
}

theme.clientlist.item = {
    normal = setmetatable({
    }, { __index = theme.capsule.styles.normal }),
    active = setmetatable({
    }, { __index = theme.capsule.styles.selected }),
    urgent = setmetatable({
    }, { __index = theme.capsule.styles.urgent }),
    minimized = setmetatable({
    }, { __index = theme.capsule.styles.disabled }),
}

----------------------------------------------------------------------------------------------------

local client_border_width = dpi(1)
local client_border_radius = main_border_radius

theme.client = {
    normal = {
        bg = theme.common.bg_66,
        fg = theme.common.fg,
        border_color = theme.common.bg_140,
        border_width = client_border_width,
    },
    active = {
        bg = theme.common.bg,
        fg = theme.common.fg_bright,
        border_color = theme.common.primary_bright,
        border_width = client_border_width,
    },
    urgent = {
        bg = theme.common.urgent_bright,
        fg = theme.common.fg_bright,
        border_color = theme.common.urgent_bright,
        border_width = client_border_width,
    },
}

function theme.client.shape(cr, width, height)
    gshape.rounded_rect(cr, width, height, client_border_radius)
end

----------------------------------------------------------------------------------------------------

do
    local button_shape = function(cr, width, height)
        gshape.rounded_rect(cr, width, height, dpi(3))
    end
    local button_paddings = hui.thickness { dpi(5), dpi(5) }
    local button_margins = hui.thickness { dpi(3), 0, dpi(7) }
    theme.titlebar = {
        height = dpi(36),
        paddings = hui.thickness { 0, dpi(12) },
        button = {
            opacity_normal = 0.5,
            opacity_focus = 1,
            spacing = dpi(4),
            styles = {
                normal = {
                    hover_overlay = hcolor.white .. "30",
                    press_overlay = hcolor.white .. "30",
                    bg = hcolor.transparent,
                    fg = theme.common.fg,
                    border_width = 0,
                    shape = button_shape,
                    paddings = button_paddings,
                    margins = button_margins,
                },
                active = {
                    hover_overlay = hcolor.white .. "20",
                    press_overlay = hcolor.white .. "20",
                    bg = theme.common.primary_50,
                    fg = theme.common.fg_bright,
                    border_color = theme.common.primary_75,
                    border_width = 0,
                    shape = button_shape,
                    paddings = button_paddings,
                    margins = button_margins,
                },
                close = {
                    hover_overlay = theme.common.urgent_bright,
                    press_overlay = theme.palette.white .. "30",
                    bg = hcolor.transparent,
                    fg = theme.common.fg_bright,
                    border_width = 0,
                    shape = button_shape,
                    paddings = button_paddings,
                    margins = button_margins,
                },
            },
            icons = {
                menu = config.places.theme .. "/icons/menu.svg",
                floating = config.places.theme .. "/icons/arrange-bring-forward.svg",
                on_top = config.places.theme .. "/icons/chevron-double-up.svg",
                sticky = config.places.theme .. "/icons/pin.svg",
                minimize = config.places.theme .. "/icons/window-minimize.svg",
                maximize = config.places.theme .. "/icons/window-maximize.svg",
                close = config.places.theme .. "/icons/window-close.svg",
            },
        },
    }
end

do
    local toolbox_button_shape = function(cr, width, height)
        gshape.rounded_rect(cr, width, height, dpi(2))
    end
    local toolbox_button_paddings = hui.thickness { dpi(4) }
    local toolbox_button_margins = hui.thickness { 0 }
    theme.toolbox_titlebar = {
        height = dpi(24),
        paddings = hui.thickness { dpi(2) },
        button = {
            opacity_normal = theme.titlebar.button.opacity_normal,
            opacity_focus = theme.titlebar.button.opacity_focus,
            spacing = dpi(2),
            styles = {
                normal = {
                    hover_overlay = theme.titlebar.button.styles.normal.hover_overlay,
                    press_overlay = theme.titlebar.button.styles.normal.press_overlay,
                    bg = theme.titlebar.button.styles.normal.bg,
                    fg = theme.titlebar.button.styles.normal.fg,
                    border_width = theme.titlebar.button.styles.normal.border_width,
                    shape = toolbox_button_shape,
                    paddings = toolbox_button_paddings,
                    margins = toolbox_button_margins,
                },
                active = {
                    hover_overlay = theme.titlebar.button.styles.active.hover_overlay,
                    press_overlay = theme.titlebar.button.styles.active.press_overlay,
                    bg = theme.titlebar.button.styles.active.bg,
                    fg = theme.titlebar.button.styles.active.fg,
                    border_color = theme.titlebar.button.styles.active.border_width,
                    border_width = dpi(1),
                    shape = toolbox_button_shape,
                    paddings = toolbox_button_paddings,
                    margins = toolbox_button_margins,
                },
                close = {
                    hover_overlay = theme.titlebar.button.styles.close.hover_overlay,
                    press_overlay = theme.titlebar.button.styles.close.press_overlay,
                    bg = theme.titlebar.button.styles.close.bg,
                    fg = theme.titlebar.button.styles.close.fg,
                    border_width = theme.titlebar.button.styles.close.border_width,
                    shape = toolbox_button_shape,
                    paddings = toolbox_button_paddings,
                    margins = toolbox_button_margins,
                },
            },
            icons = theme.titlebar.button.icons,
        },
    }
end

----------------------------------------------------------------------------------------------------

function theme.build_layout_stylesheet(color)
    color = color or theme.common.fg
    return css.style {
        [".primary"] = {
            fill = color,
        },
        [".secondary"] = {
            fill = color,
            opacity = 0.6,
        },
    }
end

theme.layout_icons = {
    tile = config.places.theme .. "/icons/layouts/tile.right.svg",
    floating = config.places.theme .. "/icons/layouts/floating.svg",
    max = config.places.theme .. "/icons/layouts/max.svg",
    fullscreen = config.places.theme .. "/icons/layouts/fullscreen.svg",
}

----------------------------------------------------------------------------------------------------

theme.application = {
    ---@type string|nil # The default icon for applications that don't provide any icon in their .desktop files.
    default_icon = nil,
    fallback_category = {
        name = "other",
    },
    categories = {
        utility = {
            id = "Utility",
            name = "Accessories",
            icon_name = "applications-accessories",
            icon_color = theme.palette.green,
        },
        development = {
            id = "Development",
            name = "Development",
            icon_name = "applications-development",
            icon_color = theme.palette.cyan,
        },
        education = {
            id = "Education",
            name = "Education",
            icon_name = "applications-science",
            icon_color = theme.palette.gray,
        },
        games = {
            id = "Game",
            name = "Games",
            icon_name = "applications-games",
            icon_color = theme.palette.red,
        },
        graphics = {
            id = "Graphics",
            name = "Graphics",
            icon_name = "applications-graphics",
            icon_color = theme.palette.yellow,
        },
        internet = {
            id = "Network",
            name = "Internet",
            icon_name = "applications-internet",
            icon_color = theme.palette.blue,
        },
        multimedia = {
            id = "AudioVideo",
            name = "Multimedia",
            icon_name = "applications-multimedia",
            icon_color = theme.palette.cyan,
        },
        office = {
            id = "Office",
            name = "Office",
            icon_name = "applications-office",
            icon_color = theme.palette.white,
        },
        science = {
            id = "Science",
            name = "Science",
            icon_name = "applications-science",
            icon_color = theme.palette.magenta,
        },
        settings = {
            id = "Settings",
            name = "Settings",
            icon_name = "applications-utilities",
            icon_color = theme.palette.orange,
        },
        tools = {
            id = "System",
            name = "System Tools",
            icon_name = "applications-system",
            icon_color = theme.palette.gray,
        },
    },
}

----------------------------------------------------------------------------------------------------

theme.systray = {
    bg = theme.capsule.default_style.default.bg,
    spacing = dpi(12),
}

----------------------------------------------------------------------------------------------------

theme.snap = {
    gap = theme.gap,
    distance = dpi(16),
    edge = {
        distance = dpi(8),
        bg = theme.common.fg .. "33",
        border_color = nil,
        border_width = 0,
        shape = function(cr, width, height)
            gshape.rounded_rect(cr, width, height, client_border_radius)
        end,
    },
}

----------------------------------------------------------------------------------------------------

---@type style_sheet.source
theme.style_sheet = {
    {
        "capsule",
        bg = theme.common.bg_110,
        fg = theme.common.fg,
        border_color = theme.common.bg_130,
        border_width = 0,
        shape = function(cr, width, height)
            gshape.rounded_rect(cr, width, height, theme.capsule.border_radius)
        end,
        margins = hui.thickness { 0 },
        paddings = hui.thickness { dpi(6), dpi(14) },
        highlight = Nil,
    },
    {
        "capsule:hover",
        highlight = hcolor.white .. "10",
    },
    {
        "capsule:active",
        highlight = hcolor.white .. "20",
    },
    {
        "capsule.foobar",
        bg = theme.palette.orange_66,
        border_color = theme.palette.orange_bright,
        border_width = 1,
        shape = gshape.arrow,
    },
    {
        ".foobar",
        border_width = 5,
    },
    {
        ".volume_osd",
        width = dpi(320),
        height = dpi(80),
        bg = theme.common.bg,
        fg = theme.common.fg,
        border_color = theme.common.bg_bright,
        border_width = dpi(1),
        paddings = hui.thickness { dpi(24), dpi(32) },
        spacing = dpi(16),
        font = theme.build_font { size_factor = 1.6 },
    },
    {
        "bar.volume_osd",
        color = theme.common.fg,
        background_color = theme.get_progressbar_bg(theme.common.fg),
        margins = hui.thickness { 4, 0 },
        shape = function(cr, width, height) gshape.rounded_rect(cr, width, height, dpi(6)) end,
        bar_shape = function(cr, width, height) gshape.rounded_rect(cr, width, height, dpi(6)) end,
    },
}

theme.beautiful =
{
    ----------------------------------------------------------------------------------------------------
    useless_gap = theme.gap,
    ----------------------------------------------------------------------------------------------------
    font = theme.build_font(),
    ----------------------------------------------------------------------------------------------------
    border_width = theme.client.normal.border_width,
    bg_normal = theme.client.normal.bg,
    fg_normal = theme.client.normal.fg,
    border_color_normal = theme.client.normal.border_color,
    border_width_normal = theme.client.normal.border_width,
    titlebar_bg_normal = theme.client.normal.bg,
    titlebar_fg_normal = theme.client.normal.fg,
    bg_focus = theme.client.active.bg,
    fg_focus = theme.client.active.fg,
    border_color_active = theme.client.active.border_color,
    border_width_active = theme.client.active.border_width,
    titlebar_bg_focus = theme.client.active.bg,
    titlebar_fg_focus = theme.client.active.fg,
    bg_urgent = theme.client.urgent.bg,
    fg_urgent = theme.client.urgent.fg,
    border_color_urgent = theme.client.urgent.border_color,
    border_width_urgent = theme.client.urgent.border_width,
    titlebar_bg_urgent = theme.client.urgent.bg,
    titlebar_fg_urgent = theme.client.urgent.fg,
    ----------------------------------------------------------------------------------------------------
    bg_systray = theme.systray.bg,
    systray_icon_spacing = theme.systray.spacing,
    ----------------------------------------------------------------------------------------------------
    snapper_gap = theme.snap.gap,
    snap_bg = theme.snap.edge.bg,
    snap_border_width = theme.snap.edge.border_width,
    snap_shape = theme.snap.edge.shape,
    ----------------------------------------------------------------------------------------------------
    wibar_bg = theme.wibar.bg,
    wibar_height = theme.wibar.height,
    ----------------------------------------------------------------------------------------------------
    taglist_bg_occupied = theme.taglist.item.normal.bg,
    taglist_fg_occupied = theme.taglist.item.normal.fg,
    taglist_shape_border_color = theme.taglist.item.normal.border_color,
    taglist_shape_border_width = theme.taglist.item.normal.border_width,
    taglist_bg_focus = theme.taglist.item.active.bg,
    taglist_fg_focus = theme.taglist.item.active.fg,
    taglist_shape_border_color_focus = theme.taglist.item.active.border_color,
    taglist_shape_border_width_focus = theme.taglist.item.active.border_width,
    taglist_bg_urgent = theme.taglist.item.urgent.bg,
    taglist_fg_urgent = theme.taglist.item.urgent.fg,
    taglist_shape_border_color_urgent = theme.taglist.item.urgent.border_color,
    taglist_shape_border_width_urgent = theme.taglist.item.urgent.border_width,
    taglist_bg_empty = theme.taglist.item.empty.bg,
    taglist_fg_empty = theme.taglist.item.empty.fg,
    taglist_shape_border_color_empty = theme.taglist.item.empty.border_color,
    taglist_shape_border_width_empty = theme.taglist.item.empty.border_width,
    taglist_bg_volatile = theme.taglist.item.volatile.bg,
    taglist_fg_volatile = theme.taglist.item.volatile.fg,
    taglist_shape_border_color_volatile = theme.taglist.item.volatile.border_color,
    taglist_shape_border_width_volatile = theme.taglist.item.volatile.border_width,
    ----------------------------------------------------------------------------------------------------
    tasklist_bg_normal = theme.clientlist.item.normal.bg,
    tasklist_fg_normal = theme.clientlist.item.normal.fg,
    tasklist_shape_border_color = theme.clientlist.item.normal.border_color,
    tasklist_shape_border_width = theme.clientlist.item.normal.border_width,
    tasklist_bg_focus = theme.clientlist.item.active.bg,
    tasklist_fg_focus = theme.clientlist.item.active.fg,
    tasklist_shape_border_color_focus = theme.clientlist.item.active.border_color,
    tasklist_shape_border_width_focus = theme.clientlist.item.active.border_width,
    tasklist_bg_urgent = theme.clientlist.item.urgent.bg,
    tasklist_fg_urgent = theme.clientlist.item.urgent.fg,
    tasklist_shape_border_color_urgent = theme.clientlist.item.urgent.border_color,
    tasklist_shape_border_width_urgent = theme.clientlist.item.urgent.border_width,
    tasklist_bg_minimize = theme.clientlist.item.minimized.bg,
    tasklist_fg_minimize = theme.clientlist.item.minimized.fg,
    tasklist_shape_border_color_minimized = theme.clientlist.item.minimized.border_color,
    tasklist_shape_border_width_minimized = theme.clientlist.item.minimized.border_width,
    tasklist_plain_task_name = not theme.clientlist.enable_glyphs,
    tasklist_sticky = theme.clientlist.glyphs.sticky,
    tasklist_ontop = theme.clientlist.glyphs.ontop,
    tasklist_above = theme.clientlist.glyphs.above,
    tasklist_below = theme.clientlist.glyphs.below,
    tasklist_floating = theme.clientlist.glyphs.floating,
    tasklist_maximized = theme.clientlist.glyphs.maximized,
    tasklist_maximized_horizontal = theme.clientlist.glyphs.maximized_horizontal,
    tasklist_maximized_vertical = theme.clientlist.glyphs.maximized_vertical,
    tasklist_minimized = theme.clientlist.glyphs.minimized,
    ----------------------------------------------------------------------------------------------------
    notification_width = dpi(400),
    notification_spacing = dpi(16),
    notification_margin = dpi(8),
    notification_border_width = theme.client.normal.border_width,
    notification_shape = function(cr, width, height)
        gshape.rounded_rect(cr, width, height, dpi(8))
    end,
    ----------------------------------------------------------------------------------------------------
}

return theme
