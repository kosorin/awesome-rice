local dpi = Dpi
local gshape = require("gears.shape")


---@param theme Theme
return function(theme)
    local pretty = {}

    ----------------------------------------------------------------------------------------------------

    pretty.useless_gap = theme.gap

    ----------------------------------------------------------------------------------------------------

    pretty.font = theme.build_font()

    ----------------------------------------------------------------------------------------------------

    pretty.border_width = theme.client.normal.border_width

    pretty.bg_normal = theme.client.normal.bg
    pretty.fg_normal = theme.client.normal.fg
    pretty.border_color_normal = theme.client.normal.border_color
    pretty.border_width_normal = theme.client.normal.border_width
    pretty.titlebar_bg_normal = theme.client.normal.bg
    pretty.titlebar_fg_normal = theme.client.normal.fg

    pretty.bg_focus = theme.client.active.bg
    pretty.fg_focus = theme.client.active.fg
    pretty.border_color_active = theme.client.active.border_color
    pretty.border_width_active = theme.client.active.border_width
    pretty.titlebar_bg_focus = theme.client.active.bg
    pretty.titlebar_fg_focus = theme.client.active.fg

    pretty.bg_urgent = theme.client.urgent.bg
    pretty.fg_urgent = theme.client.urgent.fg
    pretty.border_color_urgent = theme.client.urgent.border_color
    pretty.border_width_urgent = theme.client.urgent.border_width
    pretty.titlebar_bg_urgent = theme.client.urgent.bg
    pretty.titlebar_fg_urgent = theme.client.urgent.fg

    ----------------------------------------------------------------------------------------------------

    pretty.bg_systray = theme.systray.bg
    pretty.systray_icon_spacing = theme.systray.spacing

    ----------------------------------------------------------------------------------------------------

    pretty.snapper_gap = theme.snap.gap
    pretty.snap_bg = theme.snap.edge.bg
    pretty.snap_border_width = theme.snap.edge.border_width
    pretty.snap_shape = theme.snap.edge.shape

    ----------------------------------------------------------------------------------------------------

    pretty.wibar_bg = theme.wibar.bg
    pretty.wibar_height = theme.wibar.height

    ----------------------------------------------------------------------------------------------------

    pretty.taglist_bg_occupied = theme.taglist.item.normal.bg
    pretty.taglist_fg_occupied = theme.taglist.item.normal.fg
    pretty.taglist_shape_border_color = theme.taglist.item.normal.border_color
    pretty.taglist_shape_border_width = theme.taglist.item.normal.border_width

    pretty.taglist_bg_focus = theme.taglist.item.active.bg
    pretty.taglist_fg_focus = theme.taglist.item.active.fg
    pretty.taglist_shape_border_color_focus = theme.taglist.item.active.border_color
    pretty.taglist_shape_border_width_focus = theme.taglist.item.active.border_width

    pretty.taglist_bg_urgent = theme.taglist.item.urgent.bg
    pretty.taglist_fg_urgent = theme.taglist.item.urgent.fg
    pretty.taglist_shape_border_color_urgent = theme.taglist.item.urgent.border_color
    pretty.taglist_shape_border_width_urgent = theme.taglist.item.urgent.border_width

    pretty.taglist_bg_empty = theme.taglist.item.empty.bg
    pretty.taglist_fg_empty = theme.taglist.item.empty.fg
    pretty.taglist_shape_border_color_empty = theme.taglist.item.empty.border_color
    pretty.taglist_shape_border_width_empty = theme.taglist.item.empty.border_width

    pretty.taglist_bg_volatile = theme.taglist.item.volatile.bg
    pretty.taglist_fg_volatile = theme.taglist.item.volatile.fg
    pretty.taglist_shape_border_color_volatile = theme.taglist.item.volatile.border_color
    pretty.taglist_shape_border_width_volatile = theme.taglist.item.volatile.border_width

    ----------------------------------------------------------------------------------------------------

    pretty.tasklist_bg_normal = theme.clientlist.item.normal.bg
    pretty.tasklist_fg_normal = theme.clientlist.item.normal.fg
    pretty.tasklist_shape_border_color = theme.clientlist.item.normal.border_color
    pretty.tasklist_shape_border_width = theme.clientlist.item.normal.border_width

    pretty.tasklist_bg_focus = theme.clientlist.item.active.bg
    pretty.tasklist_fg_focus = theme.clientlist.item.active.fg
    pretty.tasklist_shape_border_color_focus = theme.clientlist.item.active.border_color
    pretty.tasklist_shape_border_width_focus = theme.clientlist.item.active.border_width

    pretty.tasklist_bg_urgent = theme.clientlist.item.urgent.bg
    pretty.tasklist_fg_urgent = theme.clientlist.item.urgent.fg
    pretty.tasklist_shape_border_color_urgent = theme.clientlist.item.urgent.border_color
    pretty.tasklist_shape_border_width_urgent = theme.clientlist.item.urgent.border_width

    pretty.tasklist_bg_minimize = theme.clientlist.item.minimized.bg
    pretty.tasklist_fg_minimize = theme.clientlist.item.minimized.fg
    pretty.tasklist_shape_border_color_minimized = theme.clientlist.item.minimized.border_color
    pretty.tasklist_shape_border_width_minimized = theme.clientlist.item.minimized.border_width

    pretty.tasklist_plain_task_name = not theme.clientlist.enable_glyphs
    pretty.tasklist_sticky = theme.clientlist.glyphs.sticky
    pretty.tasklist_ontop = theme.clientlist.glyphs.ontop
    pretty.tasklist_above = theme.clientlist.glyphs.above
    pretty.tasklist_below = theme.clientlist.glyphs.below
    pretty.tasklist_floating = theme.clientlist.glyphs.floating
    pretty.tasklist_maximized = theme.clientlist.glyphs.maximized
    pretty.tasklist_maximized_horizontal = theme.clientlist.glyphs.maximized_horizontal
    pretty.tasklist_maximized_vertical = theme.clientlist.glyphs.maximized_vertical
    pretty.tasklist_minimized = theme.clientlist.glyphs.minimized

    ----------------------------------------------------------------------------------------------------

    pretty.notification_width = dpi(400)
    pretty.notification_spacing = dpi(16)
    pretty.notification_margin = dpi(8)
    pretty.notification_border_width = pretty.border_width
    pretty.notification_shape = function(cr, width, height)
        gshape.rounded_rect(cr, width, height, dpi(8))
    end

    ----------------------------------------------------------------------------------------------------

    pretty.tooltip_bg = theme.tooltip.default_style.bg
    pretty.tooltip_fg = theme.tooltip.default_style.fg
    pretty.tooltip_border_color = theme.tooltip.default_style.border_color
    pretty.tooltip_border_width = theme.tooltip.default_style.border_width
    pretty.tooltip_shape = theme.tooltip.default_style.shape
    pretty.tooltip_gaps = theme.tooltip.default_style.margins

    ----------------------------------------------------------------------------------------------------

    return pretty
end
