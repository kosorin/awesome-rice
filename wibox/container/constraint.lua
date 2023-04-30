---------------------------------------------------------------------------
-- Restrict a widget size using one of multiple available strategies.
--
--@DOC_wibox_container_defaults_constraint_EXAMPLE@
-- @author Lukáš Hrázký
-- @copyright 2012 Lukáš Hrázký
-- @containermod wibox.container.constraint
-- @supermodule wibox.widget.base
---------------------------------------------------------------------------

local setmetatable = setmetatable
local base = require("wibox.widget.base")
local gtable = require("gears.table")
local noice = require("theme.manager")
local stylable = require("theme.stylable")
local Nil = require("theme.nil")
local math = math

local constraint = { mt = {} }

local default_style = {
    strategy = "max",
    width = Nil,
    height = Nil,
}

noice.register_element(constraint, "constraint", "widget", default_style)

for prop in pairs(default_style) do
    constraint["set_" .. prop] = function(self, value)
        if self:set_style_value(prop, value) then
            self:emit_signal("widget::layout_changed")
            self:emit_signal("property::" .. prop, value)
        end
    end
    constraint["get_" .. prop] = function(self)
        return self:get_style_value(prop)
    end
end

local strategies = {
    min = function(real_size, limit)
        return limit and math.max(limit, real_size) or real_size
    end,
    max = function(real_size, limit)
        return limit and math.min(limit, real_size) or real_size
    end,
    exact = function(real_size, limit)
        return limit or real_size
    end,
}

-- Layout a constraint layout
function constraint:layout(_, width, height)
    if self._private.widget then
        return { base.place_widget_at(self._private.widget, 0, 0, width, height) }
    end
end

-- Fit a constraint layout into the given space
function constraint:fit(context, width, height)
    local strategy = strategies[self:get_style_value("strategy")]
    if not strategy then
        return width, height
    end

    local limit_w, limit_h = self:get_style_value("width"), self:get_style_value("height")
    local w, h

    if self._private.widget then
        w = strategy(width, limit_w)
        h = strategy(height, limit_h)

        w, h = base.fit_widget(self, context, self._private.widget, w, h)
    else
        w, h = 0, 0
    end

    w = strategy(w, limit_w)
    h = strategy(h, limit_h)

    return w, h
end

--- The widget to be constrained.
--
-- @property widget
-- @tparam[opt=nil] widget|nil widget
-- @interface container

constraint.set_widget = base.set_widget_common

function constraint:get_widget()
    return self._private.widget
end

function constraint:get_children()
    return {self._private.widget}
end

function constraint:set_children(children)
    self:set_widget(children[1])
end

--- Set the strategy to use for the constraining.
--
-- @property strategy
-- @tparam[opt="max"] string strategy
-- @propertyvalue "max" Never allow the size to be larger than the limit.
-- @propertyvalue "min" Never allow the size to tbe below the limit.
-- @propertyvalue "exact" Force the widget size.
-- @propemits true false

--- Set the maximum width to val. nil for no width limit.
--
-- @property width
-- @tparam[opt=nil] number|nil width
-- @negativeallowed false
-- @propertyunit pixel
-- @propertytype nil Do not set a width limit.
-- @propertytype number Set a width limit.
-- @propemits true false

--- Set the maximum height to val. nil for no height limit.
--
-- @property height
-- @tparam[opt=nil] number|nil height
-- @negativeallowed false
-- @propertyunit pixel
-- @propertytype nil Do not set a height limit.
-- @propertytype number Set a height limit.
-- @propemits true false

--- Reset this layout.
--
--The widget will be unreferenced, strategy set to "max"
-- and the constraints set to nil.
--
-- @method reset
-- @noreturn
-- @interface container
function constraint:reset()
    self:clear_local_style()
    self:set_widget(nil)
end

--- Returns a new constraint container.
--
-- This container will constraint the size of a
-- widget according to the strategy. Note that this will only work for layouts
-- that respect the widget's size, eg. fixed layout. In layouts that don't
-- (fully) respect widget's requested size, the inner widget still might get
-- drawn with a size that does not fit the constraint, eg. in flex layout.
-- @param[opt] widget A widget to use.
-- @param[opt] strategy How to constraint the size. 'max' (default), 'min' or
-- 'exact'.
-- @param[opt] width The maximum width of the widget. nil for no limit.
-- @param[opt] height The maximum height of the widget. nil for no limit.
-- @treturn table A new constraint container
-- @constructorfct wibox.container.constraint
local function new(widget, strategy, width, height)
    local ret = base.make_widget(nil, nil, { enable_properties = true })

    gtable.crush(ret, constraint, true)
    stylable.initialize(ret, constraint)

    if strategy then
        ret:set_strategy(strategy)
    end
    if width then
        ret:set_width(width)
    end
    if height then
        ret:set_height(height)
    end

    if widget then
        ret:set_widget(widget)
    end

    return ret
end

function constraint.mt:__call(...)
    return new(...)
end

return setmetatable(constraint, constraint.mt)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
