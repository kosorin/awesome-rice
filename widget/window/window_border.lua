local setmetatable = setmetatable
local ipairs = ipairs
local type = type
local beautiful = require("theme.theme")
local gtable = require("gears.table")
local gcolor = require("gears.color")
local gshape = require("gears.shape")
local base = require("wibox.widget.base")
local cairo = require("lgi").cairo
local noice = require("theme.style")
local uui = require("utils.ui")
local binding = require("io.binding")


---@class WindowBorder.module
---@operator call: WindowBorder
local M = { mt = {} }

function M.mt:__call(...)
    return M.new(...)
end


---@class WindowBorder : wibox.container, stylable
---@field package _private WindowBorder.private
---@field package _style stylable.data
---
---@field get_bg fun(self: WindowBorder): lgi.cairo.Pattern
---@field get_fg fun(self: WindowBorder): lgi.cairo.Pattern
---@field get_outer_color fun(self: WindowBorder): lgi.cairo.Pattern
---@field get_outer_width fun(self: WindowBorder): number
---@field get_inner_color fun(self: WindowBorder): lgi.cairo.Pattern
---@field get_inner_width fun(self: WindowBorder): number
---@field get_paddings fun(self: WindowBorder): thickness
---
---@field set_bg fun(self: WindowBorder, bg: color)
---@field set_fg fun(self: WindowBorder, fg: color)
---@field set_outer_color fun(self: WindowBorder, color: color)
---@field set_outer_width fun(self: WindowBorder, width: number)
---@field set_inner_color fun(self: WindowBorder, color: color)
---@field set_inner_width fun(self: WindowBorder, width: number)
---@field set_paddings fun(self: WindowBorder, paddings: thickness_value)
M.object = {}
---@class WindowBorder.private : wibox.widget.base.private
---@field widget? wibox.widget.base
---@field position edge
---@field corners boolean

noice.define_style(M.object, {
    bg = { convert = gcolor.create_pattern, emit_redraw_needed = true },
    fg = { convert = gcolor.create_pattern, emit_redraw_needed = true },
    outer_color = { convert = gcolor.create_pattern, emit_redraw_needed = true },
    outer_width = { emit_layout_changed = true, emit_redraw_needed = true },
    inner_color = { convert = gcolor.create_pattern, emit_redraw_needed = true },
    inner_width = { emit_layout_changed = true, emit_redraw_needed = true },
    paddings = { convert = uui.thickness, emit_layout_changed = true, emit_redraw_needed = true },
})

---@return edge
function M.object:get_position()
    return self._private.position
end

---@param position? edge
function M.object:set_position(position)
    position = position or "top"
    if self._private.position == position then
        return
    end
    self._private.position = position
    self:emit_signal("property::position")
    self:emit_signal("widget::layout_changed")
    self:emit_signal("widget::redraw_needed")
end

---@return boolean
function M.object:get_corners()
    return self._private.corners
end

---@param corners? boolean
function M.object:set_corners(corners)
    corners = not not corners
    if self._private.corners == corners then
        return
    end
    self._private.corners = corners
    self:emit_signal("property::corners")
    self:emit_signal("widget::layout_changed")
    self:emit_signal("widget::redraw_needed")
end

---@param _ widget_context
---@param cr cairo_context
---@param width number
---@param height number
function M.object:before_draw_children(_, cr, width, height)
    local bg = self._style.current.bg
    if bg then
        cr:save()
        cr:set_source(bg)
        cr:rectangle(0, 0, width, height)
        cr:fill()
        cr:restore()
    end

    local fg = self._style.current.fg
    if fg then
        cr:set_source(fg)
    end
end

---@param _ widget_context
---@param cr cairo_context
---@param width number
---@param height number
function M.object:after_draw_children(_, cr, width, height)
    local outer_width = self._style.current.outer_width or 0
    local inner_width = self._style.current.inner_width or 0
    local corners = self._private.corners
    local position = self._private.position
    local rotate = position == "top" or position == "bottom"
    local mirror = position == "right" or position == "bottom"

    local x, y, w, h

    if rotate then
        width, height = height, width
    end

    local inner_color = self._style.current.inner_color
    if inner_width > 0 and inner_color then
        cr:save()
        cr:set_line_width(inner_width * 2)
        cr:set_source(inner_color)
        x = (mirror and -width or 0) + outer_width
        y = corners and outer_width or -inner_width
        w = width * 2 - outer_width * 2
        h = height + (corners and -outer_width * 2 or inner_width * 2)
        if rotate then
            x, y = y, x
            w, h = h, w
        end
        cr:rectangle(x, y, w, h)
        cr:stroke()
        cr:restore()
    end

    local outer_color = self._style.current.outer_color
    if outer_width > 0 and outer_color then
        cr:save()
        cr:set_line_width(outer_width * 2)
        cr:set_source(outer_color)
        x = mirror and -width or 0
        y = corners and 0 or -outer_width
        w = width * 2
        h = height + (corners and 0 or outer_width * 2)
        if rotate then
            x, y = y, x
            w, h = h, w
        end
        cr:rectangle(x, y, w, h)
        cr:stroke()
        cr:restore()
    end
end

---@param _ widget_context
---@param width number
---@param height number
---@return widget_layout_result[]|nil
function M.object:layout(_, width, height)
    local widget = self._private.widget
    if not widget then
        return
    end

    local paddings = self._style.current.paddings or uui.zero_thickness
    local left = paddings.left
    local right = paddings.right
    local top = paddings.top
    local bottom = paddings.bottom

    local bw = (self._style.current.outer_width or 0) + (self._style.current.inner_width or 0)
    if bw > 0 then
        local corners = self._private.corners
        local position = self._private.position
        local rotate = position == "top" or position == "bottom"

        if position == "left" or (rotate and corners) then
            left = left + bw
        end
        if position == "right" or (rotate and corners) then
            right = right + bw
        end
        if position == "top" or (not rotate and corners) then
            top = top + bw
        end
        if position == "bottom" or (not rotate and corners) then
            bottom = bottom + bw
        end
    end

    width = width - (left + right)
    height = height - (top + bottom)

    if width >= 0 and height >= 0 then
        return { base.place_widget_at(widget, left, top, width, height) }
    end
end

---@param _ widget_context
---@param width number
---@param height number
---@return number width
---@return number height
function M.object:fit(_, width, height)
    return width, height
end

---@return wibox.widget.base|nil
function M.object:get_widget()
    return self._private.widget
end

---@param widget? widget_value
function M.object:set_widget(widget)
    if self._private.widget == widget then
        return
    end

    widget = widget and base.make_widget_from_value(widget)
    if widget then
        base.check_widget(widget)
    end

    self._private.widget = widget
    self:emit_signal("property::widget")
    self:emit_signal("widget::layout_changed")
    self:emit_signal("widget::redraw_needed")
end

---@return wibox.widget.base[]
function M.object:get_children()
    return { self._private.widget }
end

---@param children wibox.widget.base[]
function M.object:set_children(children)
    self:set_widget(children[1])
end

---@class WindowBorder.new.args

---@param args? WindowBorder.new.args
---@return WindowBorder
function M.new(args)
    args = args or {}

    local self = base.make_widget(nil, nil, { enable_properties = true }) --[[@as WindowBorder]]

    gtable.crush(self, M.object, true)

    self:set_position("top")
    self:set_corners(false)

    self:initialize_style(beautiful.drawin_border.default_style)

    return self
end

return setmetatable(M, M.mt)
