---------------------------------------------------------------------------
-- Add a margin around a widget.
--
--@DOC_wibox_container_defaults_margin_EXAMPLE@
-- @author Uli Schlachter
-- @copyright 2010 Uli Schlachter
-- @containermod wibox.container.margin
-- @supermodule wibox.widget.base
---------------------------------------------------------------------------

local pairs = pairs
local setmetatable = setmetatable
local base = require("wibox.widget.base")
local gcolor = require("gears.color")
local cairo = require("lgi").cairo
local gtable = require("gears.table")
local gthickness = require("gears.thickness")
local noice = require("theme.manager")
local stylable = require("theme.stylable")
local Nil = require("theme.nil")

local margin = { mt = {} }

noice.register_element(margin, "margin", "widget", {
    margins = gthickness(0),
    color = Nil,
    draw_empty = Nil,
})

-- Draw a margin layout
function margin:draw(_, cr, width, height)
    local t, r, b, l = self:get_style_value("margins"):all()
    local extra_w = l + r
    local extra_h = t + b

    if not self._private.widget or width <= extra_w or height <= extra_h then
        return
    end

    local color = self:get_style_value("color")
    if color then
        cr:set_source(gcolor(color))
        cr:rectangle(0, 0, width, height)
        cr:rectangle(l, t, width - extra_w, height - extra_h)
        cr:set_fill_rule(cairo.FillRule.EVEN_ODD)
        cr:fill()
    end
end

-- Layout a margin layout
function margin:layout(_, width, height)
    if self._private.widget then
        local t, r, b, l = self:get_style_value("margins"):all()
        local extra_w = l + r
        local extra_h = t + b

        local resulting_width = width - extra_w
        local resulting_height = height - extra_h

        if resulting_width >= 0 and resulting_height >= 0 then
            return { base.place_widget_at(self._private.widget, l, t, resulting_width, resulting_height) }
        end
    end
end

-- Fit a margin layout into the given space
function margin:fit(context, width, height)
    local t, r, b, l = self:get_style_value("margins"):all()
    local extra_w = l + r
    local extra_h = t + b

    local w, h = 0, 0
    if self._private.widget then
        w, h = base.fit_widget(self, context, self._private.widget, width - extra_w, height - extra_h)
    end

    if self:get_style_value("draw_empty") == false and (w == 0 or h == 0) then
        return 0, 0
    end

    return w + extra_w, h + extra_h
end

--- The widget to be wrapped the the margins.
--
-- @property widget
-- @tparam[opt=nil] widget|nil widget
-- @interface container

margin.set_widget = base.set_widget_common

function margin:get_widget()
    return self._private.widget
end

function margin:get_children()
    return { self._private.widget }
end

function margin:set_children(children)
    self:set_widget(children[1])
end

--- Set all the margins to val.
--
-- @property margins
-- @tparam[opt=0] number|table margins
-- @tparam[opt=0] number margins.left
-- @tparam[opt=0] number margins.right
-- @tparam[opt=0] number margins.top
-- @tparam[opt=0] number margins.bottom
-- @propertytype number A single value for all margins.
-- @propertytype table A different value for each side.
-- @propertyunit pixel
-- @negativeallowed false
-- @propemits false false

function margin:set_margins(margins)
    margins = gthickness(margins)
    if self:set_style_value("margins", margins) then
        self:emit_signal("widget::layout_changed")
        self:emit_signal("property::margins", margins)
    end
end

function margin:get_margins()
    return self:get_style_value("margins")
end

--- Set the margins color to create a border.
--
-- @property color
-- @tparam[opt=nil] color|nil color A color used to fill the margin.
-- @propertytype nil Transparent margins.
-- @propemits true false

function margin:set_color(color)
    if self:set_style_value("color", color) then
        self:emit_signal("widget::redraw_needed")
        self:emit_signal("property::color", color)
    end
end

function margin:get_color()
    return self:get_style_value("color")
end

--- Draw the margin even if the content size is 0x0.
--
-- @property draw_empty
-- @tparam[opt=true] boolean draw_empty Draw nothing is content is `0x0` or draw
--  the margin anyway.
-- @propemits true false

function margin:set_draw_empty(draw_empty)
    if self:set_style_value("draw_empty", draw_empty) then
        self:emit_signal("widget::layout_changed")
        self:emit_signal("property::draw_empty", draw_empty)
    end
end

function margin:get_draw_empty()
    return self:get_style_value("draw_empty")
end

--- Reset this layout.
-- The widget will be unreferenced, the margins set to 0
-- and the color erased
-- @method reset
-- @noreturn
-- @interface container
function margin:reset()
    self:clear_local_style()
    self:set_widget(nil)
end

--- Returns a new margin container.
--
-- @tparam[opt] widget widget A widget to use.
-- @tparam[opt] number left A margin to use on the left side of the widget.
-- @tparam[opt] number right A margin to use on the right side of the widget.
-- @tparam[opt] number top A margin to use on the top side of the widget.
-- @tparam[opt] number bottom A margin to use on the bottom side of the widget.
-- @tparam[opt] gears.color color A color for the margins.
-- @tparam[opt] boolean draw_empty Whether or not to draw the margin when the content is empty
-- @treturn table A new margin container
-- @constructorfct wibox.container.margin
local function new(widget, margins, color, draw_empty)
    local ret = base.make_widget(nil, nil, { enable_properties = true })

    gtable.crush(ret, margin, true)
    stylable.initialize(ret, margin)

    if margins then
        ret:set_margins(margins)
    end
    if draw_empty then
        ret:set_draw_empty(draw_empty)
    end
    if color then
        ret:set_color(color)
    end

    if widget then
        ret:set_widget(widget)
    end

    return ret
end

function margin.mt:__call(...)
    return new(...)
end

return setmetatable(margin, margin.mt)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
