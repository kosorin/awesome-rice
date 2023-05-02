---------------------------------------------------------------------------
-- Reflect a widget along one or both axis.
--
--@DOC_wibox_container_defaults_mirror_EXAMPLE@
-- @author dodo
-- @copyright 2012 dodo
-- @containermod wibox.container.mirror
-- @supermodule wibox.widget.base
---------------------------------------------------------------------------

local type = type
local error = error
local ipairs = ipairs
local setmetatable = setmetatable
local base = require("wibox.widget.base")
local matrix = require("gears.matrix")
local gtable = require("gears.table")
local noice = require("theme.manager")
local stylable = require("theme.stylable")
local Nil = require("theme.nil")

local mirror = { mt = {} }

noice.register_element(mirror, "mirror", "widget", {
    reflection = Nil,
}, {
    reflection = {
        equality_comparer = function(a, b)
            if not a and not b then
                return true
            end
            return a.horizontal == b.horizontal and a.vertical == b.vertical
        end,
    },
})

local reflections = {
    none = {},
    horizontal = { horizontal = true },
    vertical = { vertical = true },
    both = { horizontal = true, vertical = true },
}

-- Layout this layout
function mirror:layout(_, width, height)
    if not self._private.widget then return end

    local reflection = self:get_style_value("reflection") or reflections.none
    local m = matrix.identity
    local t = { x = 0, y = 0 } -- translation
    local s = { x = 1, y = 1 } -- scale
    if reflection.horizontal then
        t.x = width
        s.x = -1
    end
    if reflection.vertical then
        t.y = height
        s.y = -1
    end
    m = m:translate(t.x, t.y)
    m = m:scale(s.x, s.y)

    return { base.place_widget_via_matrix(self._private.widget, m, width, height) }
end

-- Fit this layout into the given area.
function mirror:fit(context, ...)
    if not self._private.widget then
        return 0, 0
    end
    return base.fit_widget(self, context, self._private.widget, ...)
end

--- The widget to be reflected.
--
-- @property widget
-- @tparam[opt=nil] widget|nil widget
-- @interface container

mirror.set_widget = base.set_widget_common

function mirror:get_widget()
    return self._private.widget
end

function mirror:get_children()
    return { self._private.widget }
end

function mirror:set_children(children)
    self:set_widget(children[1])
end

--- Reset this layout. The widget will be removed and the axes reset.
--
-- @method reset
-- @noreturn
-- @interface container
function mirror:reset()
    self:clear_local_style()
    self:set_widget(nil)
end

local function parse_reflection(reflection)
    local t = type(reflection)
    if t == "string" then
        return reflections[reflection] or reflections.none
    elseif t == "table" then
        return {
            horizontal = not not reflection.horizontal,
            vertical = not not reflection.vertical,
        }
    else
        return reflections.none
    end
end

function mirror:set_reflection(reflection)
    reflection = parse_reflection(reflection)
    if self:set_style_value("reflection", reflection) then
        self:emit_signal("widget::layout_changed")
        self:emit_signal("property::reflection", reflection)
    end
end

--- Get the reflection of this mirror layout.
--
-- @property reflection
-- @tparam table reflection A table of booleans with the keys "horizontal", "vertical".
-- @tparam[opt=false] boolean reflection.horizontal
-- @tparam[opt=false] boolean reflection.vertical
-- @propemits true false

function mirror:get_reflection()
    return self:get_style_value("reflection")
end

--- Returns a new mirror container.
--
-- A mirror container mirrors a given widget. Use the `widget` property to set
-- the widget and `reflection` property to set the direction.
-- horizontal and vertical are by default false which doesn't change anything.
--
-- @tparam[opt] widget widget The widget to display.
-- @tparam[opt] table reflection A table describing the reflection to apply.
-- @treturn table A new mirror container
-- @constructorfct wibox.container.mirror
local function new(widget, reflection)
    local ret = base.make_widget(nil, nil, { enable_properties = true })

    gtable.crush(ret, mirror, true)
    stylable.initialize(ret, mirror)

    if reflection then
        ret:set_reflection(reflection)
    end

    if widget then
        ret:set_widget(widget)
    end

    return ret
end

function mirror.mt:__call(...)
    return new(...)
end

return setmetatable(mirror, mirror.mt)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
