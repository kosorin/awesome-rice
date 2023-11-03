local setmetatable = setmetatable
local ipairs = ipairs
local type = type
local beautiful = require("theme.theme")
local gtable = require("gears.table")
local gcolor = require("gears.color")
local gshape = require("gears.shape")
local base = require("wibox.widget.base")
local cairo = require("lgi").cairo
local noice = require("core.style")
local uui = require("utils.thickness")
local binding = require("core.binding")


---@class Capsule.module
---@operator call: Capsule
local M = { mt = {} }

function M.mt:__call(...)
    return M.new(...)
end


---@class Capsule : wibox.container, stylable
---@field package _private Capsule.private
---@field package _style stylable.data
---
---@field get_bg fun(self: Capsule): lgi.cairo.Pattern
---@field get_fg fun(self: Capsule): lgi.cairo.Pattern
---@field get_border_color fun(self: Capsule): lgi.cairo.Pattern
---@field get_border_width fun(self: Capsule): number
---@field get_shape fun(self: Capsule): shape|nil
---@field get_margins fun(self: Capsule): thickness
---@field get_paddings fun(self: Capsule): thickness
---@field get_hover_overlay fun(self: Capsule): lgi.cairo.Pattern
---@field get_press_overlay fun(self: Capsule): lgi.cairo.Pattern
---
---@field set_bg fun(self: Capsule, bg: color)
---@field set_fg fun(self: Capsule, fg: color)
---@field set_border_color fun(self: Capsule, border_color: color)
---@field set_border_width fun(self: Capsule, border_width: number)
---@field set_shape fun(self: Capsule, shape?: shape)
---@field set_margins fun(self: Capsule, margins: thickness_value)
---@field set_paddings fun(self: Capsule, paddings: thickness_value)
---@field set_hover_overlay fun(self: Capsule, hover_overlay: color)
---@field set_press_overlay fun(self: Capsule, press_overlay: color)
M.object = { allow_empty_widget = true }
---@class Capsule.private : wibox.widget.base.private
---@field widget? wibox.widget.base
---@field background_widget? wibox.widget.base
---@field enable_overlay boolean
---@field hover_overlay boolean
---@field press_overlay boolean

noice.define_style(M.object, {
    bg = { convert = gcolor.create_pattern, emit_redraw_needed = true },
    fg = { convert = gcolor.create_pattern, emit_redraw_needed = true },
    border_color = { convert = gcolor.create_pattern, emit_redraw_needed = true },
    border_width = { emit_redraw_needed = true },
    shape = { emit_redraw_needed = true },
    margins = { convert = uui.new, emit_layout_changed = true, emit_redraw_needed = true },
    paddings = { convert = uui.new, emit_layout_changed = true, emit_redraw_needed = true },
    hover_overlay = { convert = gcolor.create_pattern, emit_redraw_needed = true },
    press_overlay = { convert = gcolor.create_pattern, emit_redraw_needed = true },
})

local function dispose_pattern(pattern)
    local status, surface = pattern:get_surface()
    if status == "SUCCESS" then
        surface:finish()
    end
end

---@param self Capsule
---@param include_paddings boolean
---@param include_border boolean
local function get_layout_geometry(self, width, height, include_paddings, include_border)
    local margins = self._style.current.margins or uui.zero
    local paddings = include_paddings and self._style.current.paddings or uui.zero
    local bw = include_border and self._style.current.border_width or 0

    local x1 = bw + margins.left + paddings.left
    local y1 = bw + margins.top + paddings.top
    local x2 = bw + margins.right + paddings.right
    local y2 = bw + margins.bottom + paddings.bottom

    local ew = x1 + x2
    local eh = y1 + y2
    local w = width - ew
    local h = height - eh

    return x1, y1, w, h, ew, eh
end

---@param _ widget_context
---@param cr cairo_context
---@param width number
---@param height number
function M.object:before_draw_children(_, cr, width, height)
    local bw = self._style.current.border_width or 0
    local shape = self._style.current.shape or (bw > 0 and gshape.rectangle or nil)
    if shape then
        cr:push_group_with_content(cairo.Content.COLOR_ALPHA)
    end

    local bg = self._style.current.bg
    local hover = self._private.enable_overlay and self._private.hover_overlay and self._style.current.hover_overlay
    local press = self._private.enable_overlay and self._private.press_overlay and self._style.current.press_overlay

    if bg or hover or press then
        local x, y, w, h = get_layout_geometry(self, width, height, false, false)
        cr:save()
        if bg then
            cr:set_source(bg)
            cr:rectangle(x, y, w, h)
            cr:fill()
        end
        if hover then
            cr:set_source(hover)
            cr:rectangle(x, y, w, h)
            cr:fill()
        end
        if press then
            cr:set_source(press)
            cr:rectangle(x, y, w, h)
            cr:fill()
        end
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
    local bw = self._style.current.border_width or 0
    local shape = self._style.current.shape or (bw > 0 and gshape.rectangle or nil)
    if not shape then
        return
    end

    do
        local x, y, w, h = get_layout_geometry(self, width, height, false, true)
        cr:translate(x, y)
        shape(cr, w, h)
        cr:translate(-x, -y)
    end

    if bw > 0 then
        local border_color = self._style.current.border_color

        cr:push_group_with_content(cairo.Content.ALPHA)

        cr:set_source_rgba(0, 0, 0, 1)
        cr:paint()

        cr:set_operator(cairo.Operator.SOURCE)
        cr:set_source_rgba(0, 0, 0, 0)
        cr:fill_preserve()

        local mask = cr:pop_group()

        cr:set_source(border_color)
        cr:set_operator(cairo.Operator.SOURCE)
        cr:mask(mask)

        dispose_pattern(mask)
    end

    cr:push_group_with_content(cairo.Content.ALPHA)
    cr.line_width = 2 * bw
    cr:set_source_rgba(0, 0, 0, 1)
    cr:stroke_preserve()
    cr:fill()

    local mask = cr:pop_group()
    local source = cr:pop_group()

    cr:set_operator(cairo.Operator.OVER)
    cr:set_source(source)
    cr:mask(mask)

    dispose_pattern(mask)
    dispose_pattern(source)
end

---@param context widget_context
---@param width number
---@param height number
---@return widget_layout_result[]|nil
function M.object:layout(context, width, height)
    local results = {}

    local background_widget = self._private.background_widget
    if background_widget then
        local x, y, w, h = get_layout_geometry(self, width, height, false, false)
        if w >= 0 and h >= 0 then
            results[#results + 1] = base.place_widget_at(background_widget, x, y, w, h)
        end
    end

    local widget = self._private.widget
    if widget then
        local x, y, w, h = get_layout_geometry(self, width, height, true, false)
        if w >= 0 and h >= 0 then
            results[#results + 1] = base.place_widget_at(widget, x, y, w, h)
        end
    end

    return results
end

---@param context widget_context
---@param width number
---@param height number
---@return number width
---@return number height
function M.object:fit(context, width, height)
    local widget = self._private.widget
    if widget then
        local _, _, w, h, ew, eh = get_layout_geometry(self, width, height, true, false)
        if w >= 0 and h >= 0 then
            w, h = base.fit_widget(self, context, widget, w, h)
            return w + ew, h + eh
        end
    end
    return 0, 0
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

---@return wibox.widget.base|nil
function M.object:get_background_widget()
    return self._private.background_widget
end

---@param widget? widget_value
function M.object:set_background_widget(widget)
    if self._private.background_widget == widget then
        return
    end

    widget = widget and base.make_widget_from_value(widget)
    if widget then
        base.check_widget(widget)
    end

    self._private.background_widget = widget
    self:emit_signal("property::background_widget")
    self:emit_signal("widget::layout_changed")
    self:emit_signal("widget::redraw_needed")
end

---@return wibox.widget.base[]
function M.object:get_children()
    return {
        self._private.widget,
        self._private.background_widget,
    }
end

---@param children wibox.widget.base[]
function M.object:set_children(children)
    self:set_widget(children[1])
    self:set_background_widget(children[2])
end

---@return boolean
function M.object:get_enable_overlay()
    return self._private.enable_overlay
end

---@param enable? boolean
function M.object:set_enable_overlay(enable)
    self._private.enable_overlay = not not enable
    self:emit_signal("property::enable_overlay")
    self:emit_signal("widget::redraw_needed")
end

---@param self Capsule
---@param value boolean
local function set_hover_overlay(self, value)
    if self._private.hover_overlay == value then
        return
    end
    self._private.hover_overlay = value
    if self._private.enable_overlay then
        self:emit_signal("widget::redraw_needed")
    end
end

---@param self Capsule
---@param value boolean
local function set_press_overlay(self, value)
    if self._private.press_overlay == value then
        return
    end
    self._private.press_overlay = value
    if self._private.enable_overlay then
        self:emit_signal("widget::redraw_needed")
    end
end

---@class Capsule.new.args
---@field widget? widget_value
---@field enable_overlay? boolean

---@param args? Capsule.new.args
---@return Capsule
function M.new(args)
    args = args or {}

    local self = base.make_widget(nil, nil, { enable_properties = true }) --[[@as Capsule]]

    gtable.crush(self, M.object, true)

    self:set_widget(args.widget)


    self:set_enable_overlay(args.enable_overlay ~= false)
    set_hover_overlay(self, false)
    set_press_overlay(self, false)

    self:connect_signal("mouse::enter", function()
        set_hover_overlay(self, true)
        set_press_overlay(self, false)
    end)
    self:connect_signal("mouse::leave", function()
        set_hover_overlay(self, false)
        set_press_overlay(self, false)
    end)
    self:connect_signal("button::press", function(_, _, _, button, modifiers)
        if not self._private.buttons_formatted then
            return
        end
        for _, b in ipairs(self._private.buttons_formatted) do
            if binding.match_button(button, b.button, modifiers, b.modifiers) then
                set_press_overlay(self, true)
                return
            end
        end
    end)
    self:connect_signal("button::release", function(_, _, _, button)
        if not self._private.buttons_formatted then
            set_press_overlay(self, false)
            return
        end
        for _, b in ipairs(self._private.buttons_formatted) do
            if binding.match_button(button, b.button) then
                set_press_overlay(self, false)
                return
            end
        end
    end)


    self:initialize_style(beautiful.capsule.default_style)

    self:apply_style(args)

    return self
end

return setmetatable(M, M.mt)
