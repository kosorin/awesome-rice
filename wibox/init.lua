---------------------------------------------------------------------------
-- Box where widget can be displayed.
--
-- @author Uli Schlachter
-- @copyright 2010 Uli Schlachter
-- @popupmod wibox
---------------------------------------------------------------------------

local capi = {
    drawin = drawin,
    root = root,
    awesome = awesome,
    screen = screen,
}
local setmetatable = setmetatable
local pairs, ipairs = pairs, ipairs
local type = type
local object = require("gears.object")
local grect = require("gears.geometry").rectangle
local beautiful = require("beautiful")
local base = require("wibox.widget.base")
local cairo = require("lgi").cairo
local noice = require("theme.manager")
local stylable = require("theme.stylable")
local Nil = require("theme.nil")


--- This provides widget box windows. Every wibox can also be used as if it were
-- a drawin. All drawin functions and properties are also available on wiboxes!
-- wibox
local wibox = { mt = {}, object = {} }
wibox.layout = require("wibox.layout")
wibox.container = require("wibox.container")
wibox.widget = require("wibox.widget")
wibox.drawable = require("wibox.drawable")
wibox.hierarchy = require("wibox.hierarchy")

local force_forward = {
    shape_bounding = true,
    shape_clip = true,
    shape_input = true,
}

local default_style = {
    bgimage = Nil,
    bg = "#000022",
    fg = "#0000ff",
    shape = Nil,
    border_color = "#008800",
    border_width = 1,
    opacity = 1,
    visible = true,
    ontop = false,
    cursor = "left_ptr",
    input_passthrough = false,
}

noice.register_element(wibox, "wibox", nil, default_style)

for _, prop in ipairs { "bgimage", "bg", "fg" } do
    wibox["set_" .. prop] = function(self, value)
        if self:set_style_value(prop, value) then
            self._drawable[prop] = value
        end
    end
    wibox["get_" .. prop] = function(self)
        return self:get_style_value(prop)
    end
end

for _, prop in ipairs { "border_color", "border_width", "opacity" } do
    wibox["set_" .. prop] = function(self, value)
        if self:set_style_value(prop, value) then
            self["_" .. prop] = value
        end
    end
    wibox["get_" .. prop] = function(self)
        return self:get_style_value(prop)
    end
end

for _, prop in ipairs { "visible", "ontop", "cursor" } do
    wibox["set_" .. prop] = function(self, value)
        if self:set_style_value(prop, value) then
            self.drawin[prop] = value
        end
    end
    wibox["get_" .. prop] = function(self)
        return self:get_style_value(prop)
    end
end

function wibox:set_shape(shape)
    if self:set_style_value("shape", shape) then
        self:_apply_shape()
        self:emit_signal("property::shape", shape)
    end
end

function wibox:get_shape()
    return self:get_style_value("shape")
end

function wibox:set_input_passthrough(value)
    if self:set_style_value("input_passthrough", value) then
        if not value then
            self.shape_input = nil
        else
            local img = cairo.ImageSurface(cairo.Format.A1, 0, 0)
            self.shape_input = img._native
            img:finish()
        end
        self:emit_signal("property::input_passthrough", value)
    end
end

function wibox:get_input_passthrough()
    return self:get_style_value("input_passthrough")
end

--@DOC_wibox_COMMON@

function wibox:set_widget(widget)
    local w = base.make_widget_from_value(widget)
    self._drawable:set_widget(w)
    self:emit_signal("property::widget", widget)
end

function wibox:get_widget()
    return self._drawable.widget
end

wibox.setup = base.widget.setup

function wibox:find_widgets(x, y)
    return self._drawable:find_widgets(x, y)
end

function wibox:_buttons(btns)
    -- The C code uses the argument count, `nil` counts.
    return btns and self.drawin:_buttons(btns) or self.drawin:_buttons()
end

--- Create a widget that reflects the current state of this wibox.
-- @treturn widget A new widget.
-- @method to_widget
function wibox:to_widget()
    local bw = self:get_style_value("border_width") or beautiful.border_width or 0
    return wibox.widget {
        widget        = wibox.container.background,
        bg            = self:get_style_value("bg") or beautiful.bg_normal or "#ffffff",
        fg            = self:get_style_value("fg") or beautiful.fg_normal or "#000000",
        border_color  = self:get_style_value("border_color") or beautiful.border_color or "#000000",
        border_width  = bw * 2,
        shape         = self:get_style_value("shape"),
        forced_width  = self:geometry().width + 2 * bw,
        forced_height = self:geometry().height + 2 * bw,
        {
            widget  = wibox.container.margin,
            margins = bw,
            self:get_widget(),
        },
    }
end

--- Save a screenshot of the wibox to `path`.
-- @tparam string path The path.
-- @tparam[opt=nil] table context A widget context.
-- @method save_to_svg
-- @noreturn
function wibox:save_to_svg(path, context)
    wibox.widget.draw_to_svg_file(
        self:to_widget(), path, self:geometry().width, self:geometry().height, context
    )
end

function wibox:_apply_shape()
    local shape = self:get_style_value("shape")

    if not shape then
        self.shape_bounding = nil
        self.shape_clip = nil
        return
    end

    local geo = self:geometry()
    local bw = self:get_style_value("border_width")

    -- First handle the bounding shape (things including the border)
    local img = cairo.ImageSurface(cairo.Format.A1, geo.width + 2 * bw, geo.height + 2 * bw)
    local cr = cairo.Context(img)

    -- We just draw the shape in its full size
    shape(cr, geo.width + 2 * bw, geo.height + 2 * bw)
    cr:set_operator(cairo.Operator.SOURCE)
    cr:fill()
    self.shape_bounding = img._native
    img:finish()

    -- Now handle the clip shape (things excluding the border)
    img = cairo.ImageSurface(cairo.Format.A1, geo.width, geo.height)
    cr = cairo.Context(img)

    -- We give the shape the same arguments as for the bounding shape and draw
    -- it in its full size (the translate is to compensate for the smaller
    -- surface)
    cr:translate(-bw, -bw)
    shape(cr, geo.width + 2 * bw, geo.height + 2 * bw)
    cr:set_operator(cairo.Operator.SOURCE)
    cr:fill_preserve()
    -- Now we remove an area of width 'bw' again around the shape (We use 2*bw
    -- since half of that is on the outside and only half on the inside)
    cr:set_source_rgba(0, 0, 0, 0)
    cr:set_line_width(2 * bw)
    cr:stroke()
    self.shape_clip = img._native
    img:finish()
end

function wibox:get_screen()
    if self.screen_assigned and self.screen_assigned.valid then
        return self.screen_assigned
    else
        self.screen_assigned = nil
    end
    local sgeos = {}

    for s in capi.screen do
        sgeos[s] = s.geometry
    end

    return grect.get_closest_by_coord(sgeos, self.x, self.y)
end

function wibox:set_screen(s)
    s = capi.screen[s or 1]
    if s ~= self:get_screen() then
        self.x = s.geometry.x
        self.y = s.geometry.y
    end

    -- Remember this screen so things work correctly if screens overlap and
    -- (x,y) is not enough to figure out the correct screen.
    self.screen_assigned = s
    self._drawable:_force_screen(s)
    self:emit_signal("property::screen", s)
end

function wibox:get_children_by_id(name)
    --TODO v5: Move the ID management to the hierarchy.
    if rawget(self, "_by_id") then
        --TODO v5: Remove this, it's `if` nearly dead code, keep the `elseif`
        return rawget(self, "_by_id")[name]
    elseif self._drawable.widget
        and self._drawable.widget._private
        and self._drawable.widget._private.by_id then
        return self._drawable.widget._private.by_id[name]
    end

    return {}
end

for _, k in ipairs { "struts", "geometry", "get_xproperty", "set_xproperty" } do
    wibox[k] = function(self, ...)
        return self.drawin[k](self.drawin, ...)
    end
end

object.properties._legacy_accessors(wibox.object, "buttons", "_buttons", true, function(new_btns)
    return new_btns[1] and (
        type(new_btns[1]) == "button" or new_btns[1]._is_capi_button
    ) or false
end, true)

local function setup_signals(self)
    local obj
    local function clone_signal(name)
        -- When "name" is emitted on wibox.drawin, also emit it on wibox
        obj:connect_signal(name, function(_, ...)
            self:emit_signal(name, ...)
        end)
    end

    obj = self.drawin
    clone_signal("property::border_color")
    clone_signal("property::border_width")
    clone_signal("property::buttons")
    clone_signal("property::cursor")
    clone_signal("property::height")
    clone_signal("property::ontop")
    clone_signal("property::opacity")
    clone_signal("property::struts")
    clone_signal("property::visible")
    clone_signal("property::width")
    clone_signal("property::x")
    clone_signal("property::y")
    clone_signal("property::geometry")
    clone_signal("property::shape_bounding")
    clone_signal("property::shape_clip")
    clone_signal("property::shape_input")

    obj = self._drawable
    clone_signal("button::press")
    clone_signal("button::release")
    clone_signal("mouse::enter")
    clone_signal("mouse::leave")
    clone_signal("mouse::move")
    clone_signal("property::surface")
end

--- Create a wibox.
-- @tparam[opt=nil] table args
--@DOC_wibox_constructor_COMMON@
-- @treturn wibox The new wibox
-- @constructorfct wibox

local function new(args)
    args = args or {}

    local self = object()

    local drawin = capi.drawin(args)
    self.drawin = drawin
    function drawin.get_wibox()
        return self
    end

    local drawable = wibox.drawable(drawin.drawable, { wibox = self }, "wibox drawable (" .. object.modulename(3) .. ")")
    self._drawable = drawable
    function drawable.get_wibox()
        return self
    end

    --TODO v5 deprecate this and use `wibox.object`.
    for k, v in pairs(wibox) do
        if (not rawget(self, k)) and type(v) == "function" then
            self[k] = v
        end
    end

    setup_signals(self)
    self:connect_signal("property::geometry", self._apply_shape)
    self:connect_signal("property::border_width", self._apply_shape)

    -- Add __tostring method to metatable.
    local orig_string = tostring(self)

    -- If a value is not found, look in the drawin
    setmetatable(self, {
        __tostring = function()
            return string.format("wibox: %s (%s)", tostring(drawable), orig_string)
        end,
        __index = function(t, k)
            if rawget(t, "get_" .. k) then
                return t["get_" .. k](t)
            else
                return drawin[k]
            end
        end,
        __newindex = function(t, k, v)
            if rawget(t, "set_" .. k) then
                t["set_" .. k](t, v)
            elseif force_forward[k] or drawin[k] ~= nil then
                drawin[k] = v
            else
                rawset(t, k, v)
            end
        end,
    })

    drawable:_inform_visible(drawin.visible)
    drawin:connect_signal("property::visible", function()
        drawable:_inform_visible(drawin.visible)
    end)

    stylable.initialize(self, wibox)

    -- Make sure the wibox is drawn at least once
    self.draw = drawable.draw
    self.draw()

    -- Set other wibox specific arguments
    if args.bg then
        self:set_bg(args.bg)
    end

    if args.fg then
        self:set_fg(args.fg)
    end

    if args.bgimage then
        self:set_bgimage(args.bgimage)
    end

    if args.shape then
        self:set_shape(args.shape)
    end

    if args.border_color then
        self:set_border_color(args.border_color)
    end

    if args.border_width then
        self:set_border_width(args.border_width)
    end

    if args.opacity then
        self:set_opacity(args.opacity)
    end

    if args.input_passthrough ~= nil then
        self:set_input_passthrough(args.input_passthrough)
    end

    if args.widget then
        self:set_widget(args.widget)
    end

    if args.screen then
        self:set_screen(args.screen)
    end

    -- Make sure all signals bubble up
    self:_connect_everything(wibox.emit_signal)

    self:request_style()

    return self
end

--- Redraw a wibox. You should never have to call this explicitely because it is
-- automatically called when needed.
-- @param wibox
-- @method draw
-- @noreturn

--- Connect a global signal on the wibox class.
--
-- Functions connected to this signal source will be executed when any
-- wibox object emits the signal.
--
-- It is also used for some generic wibox signals such as
-- `request::geometry`.
--
-- @tparam string name The name of the signal
-- @tparam function func The function to attach
-- @staticfct wibox.connect_signal
-- @noreturn
-- @usage wibox.connect_signal("added", function(notif)
--    -- do something
-- end)

--- Emit a wibox signal.
-- @tparam string name The signal name.
-- @param ... The signal callback arguments
-- @staticfct wibox.emit_signal
-- @noreturn

--- Disconnect a signal from a source.
-- @tparam string name The name of the signal
-- @tparam function func The attached function
-- @staticfct wibox.disconnect_signal
-- @treturn boolean If the disconnection was successful

function wibox.mt:__call(...)
    return new(...)
end

-- Extend the luaobject
object.properties(capi.drawin, {
    getter_class = wibox.object,
    setter_class = wibox.object,
    auto_emit    = true,
})

capi.drawin.object = wibox.object

object._setup_class_signals(wibox)

return setmetatable(wibox, wibox.mt)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
