---------------------------------------------------------------------------
-- A circular progressbar wrapper.
--
-- If no child `widget` is set, then the radialprogressbar will take all the
-- available size. Use a `wibox.container.constraint` to prevent this.
--
--@DOC_wibox_container_defaults_radialprogressbar_EXAMPLE@
-- @author Emmanuel Lepage Vallee &lt;elv1313@gmail.com&gt;
-- @copyright 2013 Emmanuel Lepage Vallee
-- @containermod wibox.container.radialprogressbar
-- @supermodule wibox.widget.base
---------------------------------------------------------------------------

local setmetatable = setmetatable
local base = require("wibox.widget.base")
local shape = require("gears.shape")
local gtable = require("gears.table")
local color = require("gears.color")
local beautiful = require("beautiful")
local gthickness = require("gears.thickness")
local noice = require("theme.manager")
local stylable = require("theme.stylable")
local Nil = require("theme.nil")

local default_outline_width = 2

local radialprogressbar = { mt = {} }

local default_style = {
    paddings = gthickness(0),
    color = Nil,
    border_color = Nil,
    border_width = Nil,
}

noice.register_element(radialprogressbar, "radialprogressbar", "widget", default_style)

for prop in pairs(default_style) do
    radialprogressbar["set_" .. prop] = function(self, value)
        if self:set_style_value(prop, value) then
            self:emit_signal("widget::redraw_needed")
            self:emit_signal("property::" .. prop, value)
        end
    end
    radialprogressbar["get_" .. prop] = function(self)
        return self:get_style_value(prop)
    end
end

--- The progressbar border background color.
--
-- @beautiful beautiful.radialprogressbar_border_color
-- @param color

--- The progressbar foreground color.
--
-- @beautiful beautiful.radialprogressbar_color
-- @param color

--- The progressbar border width.
--
-- @beautiful beautiful.radialprogressbar_border_width
-- @param number

--- The padding between the outline and the progressbar.
-- @beautiful beautiful.radialprogressbar_paddings
-- @tparam[opt=0] table|number paddings A number or a table
-- @tparam[opt=0] number paddings.top
-- @tparam[opt=0] number paddings.bottom
-- @tparam[opt=0] number paddings.left
-- @tparam[opt=0] number paddings.right

local function outline_workarea(self, width, height)
    local border_width = self:get_style_value("border_width") or default_outline_width

    local x, y = 0, 0

    -- Make sure the border fit in the clip area
    local offset = border_width/2
    x, y = x + offset, y+offset
    width, height = width-2*offset, height-2*offset

    return {x=x, y=y, width=width, height=height}, offset
end

-- The child widget area
local function content_workarea(self, width, height)
    local padding = self:get_style_value("paddings") or {}
    local wa = outline_workarea(self, width, height)

    wa.x      = wa.x + (padding.left or 0)
    wa.y      = wa.y + (padding.top  or 0)
    wa.width  = wa.width  - (padding.left or 0) - (padding.right  or 0)
    wa.height = wa.height - (padding.top  or 0) - (padding.bottom or 0)

    return wa
end

-- Draw the radial outline and progress
function radialprogressbar:after_draw_children(_, cr, width, height)
    cr:restore()

    local border_width = self:get_style_value("border_width") or default_outline_width

    local wa = outline_workarea(self, width, height)
    cr:translate(wa.x, wa.y)

    -- Draw the outline
    shape.rounded_bar(cr, wa.width, wa.height)
    cr:set_source(color(self:get_style_value("border_color") or "#0000ff"))
    cr:set_line_width(border_width)
    cr:stroke()

    -- Draw the progress
    cr:set_source(color(self:get_style_value("color") or "#ff00ff"))
    shape.radial_progress(cr,  wa.width, wa.height, self._private.percent or 0)
    cr:set_line_width(border_width)
    cr:stroke()

end

-- Set the clip
function radialprogressbar:before_draw_children(_, cr, width, height)
    cr:save()
    local wa = content_workarea(self, width, height)
    cr:translate(wa.x, wa.y)
    shape.rounded_bar(cr, wa.width, wa.height)
    cr:clip()
    cr:translate(-wa.x, -wa.y)
end

-- Layout this layout
function radialprogressbar:layout(_, width, height)
    if self._private.widget then
        local wa = content_workarea(self, width, height)

        return { base.place_widget_at(
            self._private.widget, wa.x, wa.y, wa.width, wa.height
        ) }
    end
end

-- Fit this layout into the given area
function radialprogressbar:fit(context, width, height)
    if self._private.widget then
        local wa = content_workarea(self, width, height)
        local w, h = base.fit_widget(self, context, self._private.widget, wa.width, wa.height)
        return wa.x + w, wa.y + h
    end

    return width, height
end

--- The widget to wrap in a radial proggressbar.
--
-- @property widget
-- @tparam[opt=nil] widget|nil widget
-- @interface container

radialprogressbar.set_widget = base.set_widget_common

function radialprogressbar:get_children()
    return {self._private.widget}
end

function radialprogressbar:set_children(children)
    self._private.widget = children and children[1]
    self:emit_signal("widget::layout_changed")
end

--- Reset this container.
--
-- @method reset
-- @noreturn
-- @interface container
function radialprogressbar:reset()
    self:clear_local_style()
    self:set_widget(nil)
end

--- The padding between the outline and the progressbar.
--
--@DOC_wibox_container_radialprogressbar_padding_EXAMPLE@
-- @property paddings
-- @tparam[opt=0] table|number|nil paddings A number or a table
-- @tparam[opt=0] number paddings.top
-- @tparam[opt=0] number paddings.bottom
-- @tparam[opt=0] number paddings.left
-- @tparam[opt=0] number paddings.right
-- @propertytype number A single value for each sides.
-- @propertytype table A different value for each side.
-- @negativeallowed false
-- @propertyunit pixel
-- @propbeautiful
-- @propemits false false

function radialprogressbar:set_paddings(paddings)
    paddings = gthickness(paddings)
    if self:set_style_value("paddings", paddings) then
        self:emit_signal("widget::redraw_needed")
        self:emit_signal("widget::layout_changed")
        self:emit_signal("property::paddings", paddings)
    end
end

--- The progressbar value.
--
--@DOC_wibox_container_radialprogressbar_value_EXAMPLE@
-- @property value
-- @tparam[opt=0] number value
-- @rangestart `min_value`
-- @rangestop `max_value`
-- @negativeallowed true
-- @propemits true false

function radialprogressbar:set_value(val)
    val = val or 0
    local delta = self._private.max_value - self._private.min_value
    local percent = (val - self._private.min_value) / delta
    if self._private.percent == percent then
        return
    end
    self._private.percent = percent
    self:emit_signal("widget::redraw_needed")
    self:emit_signal("property::value", val)
end

--- The border background color.
--
--@DOC_wibox_container_radialprogressbar_border_color_EXAMPLE@
-- @property border_color
-- @tparam color|nil border_color
-- @propbeautiful
-- @propemits true false

--- The border foreground color.
--
--@DOC_wibox_container_radialprogressbar_color_EXAMPLE@
-- @property color
-- @tparam color|nil color
-- @propbeautiful
-- @propemits true false

--- The border width.
--
--@DOC_wibox_container_radialprogressbar_border_width_EXAMPLE@
-- @property border_width
-- @tparam[opt=2] number|nil border_width
-- @negativeallowed false
-- @propertyunit pixel
-- @propbeautiful
-- @propemits true false

--- The minimum value.
--
-- @property min_value
-- @tparam[opt=0] number min_value
-- @negativeallowed true
-- @propemits true false

--- The maximum value.
--
-- @property max_value
-- @tparam[opt=1] number max_value
-- @negativeallowed true
-- @propemits true false

function radialprogressbar:set_max_value(max_value)
    if self._private.max_value == max_value then
        return
    end

    self._private.max_value = max_value
    self:emit_signal("widget::redraw_needed")
    self:emit_signal("property::max_value", max_value)
end

function radialprogressbar:get_max_value()
    return self._private.max_value
end

function radialprogressbar:set_min_value(min_value)
    if self._private.min_value == min_value then
        return
    end

    self._private.min_value = min_value
    self:emit_signal("widget::redraw_needed")
    self:emit_signal("property::min_value", min_value)
end

function radialprogressbar:get_min_value()
    return self._private.min_value
end

--- Returns a new radialprogressbar layout.
--
-- A radialprogressbar layout  radialprogressbars a given widget. Use `.widget`
-- to set the widget.
--
-- @tparam[opt] widget widget The widget to display.
-- @constructorfct wibox.container.radialprogressbar
local function new(widget, min_value, max_value)
    local ret = base.make_widget(nil, nil, {
        enable_properties = true,
    })

    gtable.crush(ret, radialprogressbar)
    stylable.initialize(ret, radialprogressbar)

    ret._private.min_value = min_value or 0
    ret._private.max_value = max_value or 1

    ret:set_widget(widget)

    return ret
end

function radialprogressbar.mt:__call(...)
    return new(...)
end

return setmetatable(radialprogressbar, radialprogressbar.mt)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
