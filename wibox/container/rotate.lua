---------------------------------------------------------------------------
-- A container rotating the conained widget by 90 degrees.
--
--@DOC_wibox_container_defaults_rotate_EXAMPLE@
-- @author Uli Schlachter
-- @copyright 2010 Uli Schlachter
-- @containermod wibox.container.rotate
-- @supermodule wibox.widget.base
---------------------------------------------------------------------------

local error = error
local pi = math.pi
local setmetatable = setmetatable
local tostring = tostring
local base = require("wibox.widget.base")
local matrix = require("gears.matrix")
local gtable = require("gears.table")
local noice = require("theme.manager")
local stylable = require("theme.stylable")
local Nil = require("theme.nil")

local rotate = { mt = {} }

noice.register_element(rotate, "rotate", "widget", {
    direction = "north",
})

local function transform(self, width, height)
    local dir = self:get_style_value("direction")
    if dir == "east" or dir == "west" then
        return height, width
    end
    return width, height
end

-- Layout this layout
function rotate:layout(_, width, height)
    if not self._private.widget or not self._private.widget._private.visible then
        return
    end

    local dir = self:get_style_value("direction")

    local m = matrix.identity
    if dir == "west" then
        m = m:rotate(pi / 2)
        m = m:translate(0, -width)
    elseif dir == "south" then
        m = m:rotate(pi)
        m = m:translate(-width, -height)
    elseif dir == "east" then
        m = m:rotate(3 * pi / 2)
        m = m:translate(-height, 0)
    end

    -- Since we rotated, we might have to swap width and height.
    -- transform() does that for us.
    return { base.place_widget_via_matrix(self._private.widget, m, transform(self, width, height)) }
end

-- Fit this layout into the given area
function rotate:fit(context, width, height)
    if not self._private.widget then
        return 0, 0
    end
    return transform(self, base.fit_widget(self, context, self._private.widget, transform(self, width, height)))
end

--- The widget to be rotated.
--
-- @property widget
-- @tparam[opt=nil] widget|nil widget
-- @interface container

rotate.set_widget = base.set_widget_common

function rotate:get_widget()
    return self._private.widget
end

function rotate:get_children()
    return {self._private.widget}
end

function rotate:set_children(children)
    self:set_widget(children[1])
end

--- Reset this layout.
--
-- The widget will be removed and the rotation reset.
--
-- @method reset
-- @noreturn
-- @interface container
function rotate:reset()
    self:clear_local_style()
    self:set_widget(nil)
end

--- The direction of this rotating container.
--
--@DOC_wibox_container_rotate_angle_EXAMPLE@
-- @property direction
-- @tparam[opt="north"] string direction
-- @propertyvalue "north"
-- @propertyvalue "east"
-- @propertyvalue "south"
-- @propertyvalue "north"
-- @propemits true false

local valid_directions = {
    north = true,
    east = true,
    south = true,
    west = true,
}

function rotate:set_direction(dir)
    if not valid_directions[dir] then
        dir = "north"
    end
    if self:set_style_value("direction", dir) then
        self:emit_signal("widget::layout_changed")
        self:emit_signal("property::direction")
    end
end

-- Get the direction of this rotating layout
function rotate:get_direction()
    return self:get_style_value("direction")
end

--- Returns a new rotate container.
--
-- A rotate container rotates a given widget. Use the `widget` property
-- to set the widget and `direction` property for the direction.
-- The default direction is "north" which doesn't change anything.
-- @tparam[opt] widget widget The widget to display.
-- @tparam[opt] string dir The direction to rotate to.
-- @treturn table A new rotate container.
-- @constructorfct wibox.container.rotate
local function new(widget, dir)
    local ret = base.make_widget(nil, nil, {enable_properties = true})

    gtable.crush(ret, rotate, true)
    stylable.initialize(ret, rotate)

    if dir then
        ret:set_direction(dir)
    end

    if widget then
        ret:set_widget(widget)
    end

    return ret
end

function rotate.mt:__call(...)
    return new(...)
end

return setmetatable(rotate, rotate.mt)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
