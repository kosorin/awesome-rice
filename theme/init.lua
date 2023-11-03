---Maps a theme to the beautiful properties.
---@param theme Theme
---@return table
local function map(theme)
    local b = {}

    ----------------------------------------------------------------------------------------------------

    b.useless_gap = theme.gap

    ----------------------------------------------------------------------------------------------------

    b.font = theme.build_font()

    ----------------------------------------------------------------------------------------------------

    b.border_width = theme.client.normal.border_width

    b.bg_normal = theme.client.normal.bg
    b.fg_normal = theme.client.normal.fg
    b.border_color_normal = theme.client.normal.border_color
    b.border_width_normal = theme.client.normal.border_width
    b.titlebar_bg_normal = theme.client.normal.bg
    b.titlebar_fg_normal = theme.client.normal.fg

    b.bg_focus = theme.client.active.bg
    b.fg_focus = theme.client.active.fg
    b.border_color_active = theme.client.active.border_color
    b.border_width_active = theme.client.active.border_width
    b.titlebar_bg_focus = theme.client.active.bg
    b.titlebar_fg_focus = theme.client.active.fg

    b.bg_urgent = theme.client.urgent.bg
    b.fg_urgent = theme.client.urgent.fg
    b.border_color_urgent = theme.client.urgent.border_color
    b.border_width_urgent = theme.client.urgent.border_width
    b.titlebar_bg_urgent = theme.client.urgent.bg
    b.titlebar_fg_urgent = theme.client.urgent.fg

    ----------------------------------------------------------------------------------------------------

    b.bg_systray = theme.systray.bg
    b.systray_icon_spacing = theme.systray.spacing

    ----------------------------------------------------------------------------------------------------

    b.snapper_gap = theme.snap.gap
    b.snap_bg = theme.snap.edge.bg
    b.snap_border_width = theme.snap.edge.border_width
    b.snap_shape = theme.snap.edge.shape

    ----------------------------------------------------------------------------------------------------

    b.wibar_bg = theme.wibar.bg
    b.wibar_height = theme.wibar.height

    ----------------------------------------------------------------------------------------------------

    b.taglist_bg_occupied = theme.taglist.item.normal.bg
    b.taglist_fg_occupied = theme.taglist.item.normal.fg
    b.taglist_shape_border_color = theme.taglist.item.normal.border_color
    b.taglist_shape_border_width = theme.taglist.item.normal.border_width

    b.taglist_bg_focus = theme.taglist.item.active.bg
    b.taglist_fg_focus = theme.taglist.item.active.fg
    b.taglist_shape_border_color_focus = theme.taglist.item.active.border_color
    b.taglist_shape_border_width_focus = theme.taglist.item.active.border_width

    b.taglist_bg_urgent = theme.taglist.item.urgent.bg
    b.taglist_fg_urgent = theme.taglist.item.urgent.fg
    b.taglist_shape_border_color_urgent = theme.taglist.item.urgent.border_color
    b.taglist_shape_border_width_urgent = theme.taglist.item.urgent.border_width

    b.taglist_bg_empty = theme.taglist.item.empty.bg
    b.taglist_fg_empty = theme.taglist.item.empty.fg
    b.taglist_shape_border_color_empty = theme.taglist.item.empty.border_color
    b.taglist_shape_border_width_empty = theme.taglist.item.empty.border_width

    b.taglist_bg_volatile = theme.taglist.item.volatile.bg
    b.taglist_fg_volatile = theme.taglist.item.volatile.fg
    b.taglist_shape_border_color_volatile = theme.taglist.item.volatile.border_color
    b.taglist_shape_border_width_volatile = theme.taglist.item.volatile.border_width

    ----------------------------------------------------------------------------------------------------

    b.tasklist_bg_normal = theme.clientlist.item.normal.bg
    b.tasklist_fg_normal = theme.clientlist.item.normal.fg
    b.tasklist_shape_border_color = theme.clientlist.item.normal.border_color
    b.tasklist_shape_border_width = theme.clientlist.item.normal.border_width

    b.tasklist_bg_focus = theme.clientlist.item.active.bg
    b.tasklist_fg_focus = theme.clientlist.item.active.fg
    b.tasklist_shape_border_color_focus = theme.clientlist.item.active.border_color
    b.tasklist_shape_border_width_focus = theme.clientlist.item.active.border_width

    b.tasklist_bg_urgent = theme.clientlist.item.urgent.bg
    b.tasklist_fg_urgent = theme.clientlist.item.urgent.fg
    b.tasklist_shape_border_color_urgent = theme.clientlist.item.urgent.border_color
    b.tasklist_shape_border_width_urgent = theme.clientlist.item.urgent.border_width

    b.tasklist_bg_minimize = theme.clientlist.item.minimized.bg
    b.tasklist_fg_minimize = theme.clientlist.item.minimized.fg
    b.tasklist_shape_border_color_minimized = theme.clientlist.item.minimized.border_color
    b.tasklist_shape_border_width_minimized = theme.clientlist.item.minimized.border_width

    b.tasklist_plain_task_name = not theme.clientlist.enable_glyphs
    b.tasklist_sticky = theme.clientlist.glyphs.sticky
    b.tasklist_ontop = theme.clientlist.glyphs.ontop
    b.tasklist_above = theme.clientlist.glyphs.above
    b.tasklist_below = theme.clientlist.glyphs.below
    b.tasklist_floating = theme.clientlist.glyphs.floating
    b.tasklist_maximized = theme.clientlist.glyphs.maximized
    b.tasklist_maximized_horizontal = theme.clientlist.glyphs.maximized_horizontal
    b.tasklist_maximized_vertical = theme.clientlist.glyphs.maximized_vertical
    b.tasklist_minimized = theme.clientlist.glyphs.minimized

    ----------------------------------------------------------------------------------------------------

    b.notification_spacing = theme.notification.spacing

    ----------------------------------------------------------------------------------------------------

    b.tooltip_bg = theme.tooltip.default_style.bg
    b.tooltip_fg = theme.tooltip.default_style.fg
    b.tooltip_border_color = theme.tooltip.default_style.border_color
    b.tooltip_border_width = theme.tooltip.default_style.border_width
    b.tooltip_shape = theme.tooltip.default_style.shape
    b.tooltip_gaps = theme.tooltip.default_style.margins

    ----------------------------------------------------------------------------------------------------

    return b
end

local theme = require("theme.theme")
local beautiful_theme = map(theme)
local beautiful = require("beautiful")
beautiful.init(beautiful_theme)
