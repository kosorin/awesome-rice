---------------------------------------------------------------------------
--- Handling of drawables. A drawable is something that can be drawn to.
--
-- @author Uli Schlachter
-- @copyright 2012 Uli Schlachter
-- @classmod wibox.drawable
---------------------------------------------------------------------------

local drawable = {}
local capi = {
    awesome = awesome,
    root = root,
    screen = screen
}
local beautiful = require("beautiful")
local base = require("wibox.widget.base")
local cairo = require("lgi").cairo
local color = require("gears.color")
local object = require("gears.object")
local surface = require("gears.surface")
local timer = require("gears.timer")
local grect =  require("gears.geometry").rectangle
local matrix = require("gears.matrix")
local whierarchy = require("wibox.hierarchy")
local unpack = unpack or table.unpack -- luacheck: globals unpack (compatibility with Lua 5.1)

local visible_drawables = {}

local systray_widget

-- Get the widget context. This should always return the same table (if
-- possible), so that our draw and fit caches can work efficiently.
local function get_widget_context(self)
    local geom = self.drawable:geometry()

    local s = self._forced_screen
    if not s then
        local sgeos = {}

        for scr in capi.screen do
            sgeos[scr] = scr.geometry
        end

        s = grect.get_by_coord(sgeos, geom.x, geom.y) or capi.screen.primary
    end

    local context = self._widget_context
    local dpi = s and s.dpi or 96
    if (not context) or context.screen ~= s or context.dpi ~= dpi then
        context = {
            screen = s,
            dpi = dpi,
            drawable = self,
        }
        for k, v in pairs(self._widget_context_skeleton) do
            context[k] = v
        end
        self._widget_context = context

        -- Give widgets a chance to react to the new context
        self._need_complete_repaint = true
    end
    return context
end

local function do_redraw(self)
    if not self.drawable.valid then return end
    if self._forced_screen and not self._forced_screen.valid then return end

    local surf = surface.load_silently(self.drawable.surface, false)
    -- The surface can be nil if the drawable's parent was already finalized
    if not surf then return end
    local cr = cairo.Context(surf)
    local geom = self.drawable:geometry();
    local x, y, width, height = geom.x, geom.y, geom.width, geom.height
    local context = get_widget_context(self)

    -- Relayout
    if self._need_relayout or self._need_complete_repaint then
        self._need_relayout = false
        if self._widget_hierarchy and self._widget then
            local had_systray = systray_widget and self._widget_hierarchy:get_count(systray_widget) > 0

            self._widget_hierarchy:update(context,
                self._widget, width, height, self._dirty_area)

            local has_systray = systray_widget and self._widget_hierarchy:get_count(systray_widget) > 0
            if had_systray and not has_systray then
                systray_widget:_kickout(context)
            end
        else
            self._need_complete_repaint = true
            if self._widget then
                self._widget_hierarchy_callback_arg = {}
                self._widget_hierarchy = whierarchy.new(context, self._widget, width, height,
                        self._redraw_callback, self._layout_callback, self._widget_hierarchy_callback_arg)
                if self._widget._stylable and not self._widget._stylable.ignore_hierarchy then
                    self._widget:set_hierarchy_root(self:get_wibox())
                end
            else
                self._widget_hierarchy = nil
            end
        end

        if self._need_complete_repaint then
            self._need_complete_repaint = false
            self._dirty_area:union_rectangle(cairo.RectangleInt{
                x = 0, y = 0, width = width, height = height
            })
        end
    end

    -- Clip to the dirty area
    if self._dirty_area:is_empty() then
        return
    end
    for i = 0, self._dirty_area:num_rectangles() - 1 do
        local rect = self._dirty_area:get_rectangle(i)
        cr:rectangle(rect.x, rect.y, rect.width, rect.height)
    end
    self._dirty_area = cairo.Region.create()
    cr:clip()

    -- Draw the background
    cr:save()

    if not capi.awesome.composite_manager_running then
        -- This is pseudo-transparency: We draw the wallpaper in the background
        local wallpaper = surface.load_silently(capi.root.wallpaper(), false)
        cr.operator = cairo.Operator.SOURCE
        if wallpaper then
            cr:set_source_surface(wallpaper, -x, -y)
        else
            cr:set_source_rgb(0, 0, 0)
        end
        cr:paint()
        cr.operator = cairo.Operator.OVER
    else
        -- This is true transparency: We draw a translucent background
        cr.operator = cairo.Operator.SOURCE
    end

    cr:set_source(self.background_color)
    cr:paint()

    cr:restore()

    -- Paint the background image
    if self.background_image then
        cr:save()
        if type(self.background_image) == "function" then
            self.background_image(context, cr, width, height, unpack(self.background_image_args))
        else
            local pattern = cairo.Pattern.create_for_surface(self.background_image)
            cr:set_source(pattern)
            cr:paint()
        end
        cr:restore()
    end

    -- Draw the widget
    if self._widget_hierarchy then
        cr:set_source(self.foreground_color)
        self._widget_hierarchy:draw(context, cr)
    end

    self.drawable:refresh()

    assert(cr.status == "SUCCESS", "Cairo context entered error state: " .. cr.status)
end

local function find_widgets(self, result, hierarchy, x, y)
    local m = hierarchy:get_matrix_from_device()

    -- Is (x,y) inside of this hierarchy or any child (aka the draw extents)
    local x1, y1 = m:transform_point(x, y)
    local x2, y2, w2, h2 = hierarchy:get_draw_extents()
    if x1 < x2 or x1 >= x2 + w2 then
        return
    end
    if y1 < y2 or y1 >= y2 + h2 then
        return
    end

    -- Is (x,y) inside of this widget?
    local width, height = hierarchy:get_size()
    if x1 >= 0 and y1 >= 0 and x1 <= width and y1 <= height then
        -- Get the extents of this widget in the device space
        local x3, y3, w3, h3 = matrix.transform_rectangle(hierarchy:get_matrix_to_device(),
            0, 0, width, height)
        table.insert(result, {
            x = x3, y = y3, width = w3, height = h3,
            widget_width = width,
            widget_height = height,
            drawable = self,
            widget = hierarchy:get_widget(),
            hierarchy = hierarchy
        })
    end
    for _, child in ipairs(hierarchy:get_children()) do
        find_widgets(self, result, child, x, y)
    end
end

-- Find a widget by a point.
-- The drawable must have drawn itself at least once for this to work.
-- @param x X coordinate of the point
-- @param y Y coordinate of the point
-- @treturn table A table containing a description of all the widgets that
-- contain the given point. Each entry is a table containing this drawable as
-- its `.drawable` entry, the widget under `.widget` and the instance of
-- `wibox.hierarchy` describing the size and position of the widget under
-- `.hierarchy`. For convenience, `.x`, `.y`, `.width` and `.height` contain an
-- approximation of the widget's extents on the surface. `widget_width` and
-- `widget_height` contain the exact size of the widget in its own, local
-- coordinate system (which may e.g. be rotated and scaled).
function drawable:find_widgets(x, y)
    local result = {}
    if self._widget_hierarchy then
        find_widgets(self, result, self._widget_hierarchy, x, y)
    end
    return result
end

-- Private API. Not documented on purpose.
function drawable._set_systray_widget(widget)
    whierarchy.count_widget(widget)
    systray_widget = widget
end

--- Set the widget that the drawable displays
function drawable:set_widget(widget)
    self._widget = base.make_widget_from_value(widget)

    -- Make sure the widget gets drawn
    self._need_relayout = true
    self.draw()
end

function drawable:get_widget()
    return rawget(self, "_widget")
end

--- Set the background of the drawable
-- @param c The background to use. This must either be a cairo pattern object,
--   nil or a string that gears.color() understands.
-- @see gears.color
function drawable:set_bg(c)
    c = c or "#000000"
    local t = type(c)

    if t == "string" or t == "table" then
        c = color(c)
    end

    -- If the background is completely opaque, we don't need to redraw when
    -- the drawable is moved
    -- XXX: This isn't needed when awesome.composite_manager_running is true,
    -- but a compositing manager could stop/start and we'd have to properly
    -- handle this. So for now we choose the lazy approach.
    local redraw_on_move = not color.create_opaque_pattern(c)
    if self._redraw_on_move ~= redraw_on_move then
        self._redraw_on_move = redraw_on_move
        if redraw_on_move then
            self.drawable:connect_signal("property::x", self._do_complete_repaint)
            self.drawable:connect_signal("property::y", self._do_complete_repaint)
        else
            self.drawable:disconnect_signal("property::x", self._do_complete_repaint)
            self.drawable:disconnect_signal("property::y", self._do_complete_repaint)
        end
    end

    self.background_color = c
    self._do_complete_repaint()
end

--- Set the background image of the drawable
-- If `image` is a function, it will be called with `(context, cr, width, height)`
-- as arguments. Any other arguments passed to this method will be appended.
-- @param image A background image or a function
function drawable:set_bgimage(image, ...)
    if type(image) ~= "function" then
        image = surface(image)
    end

    self.background_image = image
    self.background_image_args = {...}

    self._do_complete_repaint()
end

--- Set the foreground of the drawable
-- @param c The foreground to use. This must either be a cairo pattern object,
--   nil or a string that gears.color() understands.
-- @see gears.color
function drawable:set_fg(c)
    c = c or "#FFFFFF"
    if type(c) == "string" or type(c) == "table" then
        c = color(c)
    end
    self.foreground_color = c
    self._do_complete_repaint()
end

function drawable:_force_screen(s)
    self._forced_screen = s
end

function drawable:_inform_visible(visible)
    self._visible = visible
    if visible then
        visible_drawables[self] = true
        -- The wallpaper or widgets might have changed
        self:_do_complete_repaint()
    else
        visible_drawables[self] = nil
    end
end

local function emit_difference(name, list, skip)
    local function in_table(table, val)
        for _, v in pairs(table) do
            if v.widget == val.widget then
                return true
            end
        end
        return false
    end

    for _, v in pairs(list) do
        if not in_table(skip, v) then
            v.widget:emit_signal(name,v)
        end
    end
end

local function handle_leave(self)
    emit_difference("mouse::leave", self._widgets_under_mouse, {})
    self._widgets_under_mouse = {}
end

local function handle_motion(self, x, y)
    local dgeo = self.drawable:geometry()

    if x < 0 or y < 0 or x > dgeo.width or y > dgeo.height then
        return handle_leave(self)
    end

    -- Build a plain list of all widgets on that point
    local widgets_list = self:find_widgets(x, y)

    -- First, "leave" all widgets that were left
    emit_difference("mouse::leave", self._widgets_under_mouse, widgets_list)
    -- Then enter some widgets
    emit_difference("mouse::enter", widgets_list, self._widgets_under_mouse)

    self._widgets_under_mouse = widgets_list
end

local function setup_signals(self)
    local d = self.drawable

    local function clone_signal(name)
        -- When "name" is emitted on wibox.drawin, also emit it on wibox
        d:connect_signal(name, function(_, ...)
            self:emit_signal(name, ...)
        end)
    end
    clone_signal("button::press")
    clone_signal("button::release")
    clone_signal("mouse::enter")
    clone_signal("mouse::leave")
    clone_signal("mouse::move")
    clone_signal("property::surface")
    clone_signal("property::width")
    clone_signal("property::height")
    clone_signal("property::x")
    clone_signal("property::y")
end

function drawable.new(d, widget_context_skeleton, drawable_name)
    local self = object()
    self.drawable = d
    self._widget_context_skeleton = widget_context_skeleton
    self._need_complete_repaint = true
    self._need_relayout = true
    self._dirty_area = cairo.Region.create()
    setup_signals(self)

    for k, v in pairs(drawable) do
        if type(v) == "function" then
            self[k] = v
        end
    end

    -- Only redraw a drawable once, even when we get told to do so multiple times.
    self._redraw_pending = false
    self._do_redraw = function()
        self._redraw_pending = false
        do_redraw(self)
    end

    -- Connect our signal when we need a redraw
    self.draw = function()
        if not self._redraw_pending then
            timer.delayed_call(self._do_redraw)
            self._redraw_pending = true
        end
    end
    self._do_complete_repaint = function()
        self._need_complete_repaint = true
        self:draw()
    end

    -- Do a full redraw if the surface changes (the new surface has no content yet)
    d:connect_signal("property::surface", self._do_complete_repaint)

    -- Do a normal redraw when the drawable moves. This will likely do nothing
    -- in most cases, but it makes us do a complete repaint when we are moved to
    -- a different screen.
    d:connect_signal("property::x", self.draw)
    d:connect_signal("property::y", self.draw)

    -- Currently we aren't redrawing on move (signals not connected).
    -- :set_bg() will later recompute this.
    self._redraw_on_move = false

    -- Set the default background
    self:set_bg(beautiful.bg_normal)
    self:set_fg(beautiful.fg_normal)

    -- Initialize internals
    self._widgets_under_mouse = {}

    local function button_signal(name)
        d:connect_signal(name, function(_, x, y, button, modifiers)
            local widgets = self:find_widgets(x, y)
            for _, v in pairs(widgets) do
                -- Calculate x/y inside of the widget
                local lx, ly = v.hierarchy:get_matrix_from_device():transform_point(x, y)
                v.widget:emit_signal(name, lx, ly, button, modifiers, v)
            end
        end)
    end
    button_signal("button::press")
    button_signal("button::release")

    d:connect_signal("mouse::move", function(_, x, y) handle_motion(self, x, y) end)
    d:connect_signal("mouse::leave", function() handle_leave(self) end)

    -- Set up our callbacks for repaints
    self._redraw_callback = function(hierar, arg)
        -- Avoid crashes when a drawable was partly finalized and dirty_area is broken.
        if not self._visible then
            return
        end
        if self._widget_hierarchy_callback_arg ~= arg then
            return
        end
        local m = hierar:get_matrix_to_device()
        local x, y, width, height = matrix.transform_rectangle(m, hierar:get_draw_extents())
        local x1, y1 = math.floor(x), math.floor(y)
        local x2, y2 = math.ceil(x + width), math.ceil(y + height)
        self._dirty_area:union_rectangle(cairo.RectangleInt {
            x = x1, y = y1, width = x2 - x1, height = y2 - y1,
        })
        self:draw()
    end
    self._layout_callback = function(_, arg)
        if self._widget_hierarchy_callback_arg ~= arg then
            return
        end
        self._need_relayout = true
        -- When not visible, we will be redrawn when we become visible. In the
        -- mean-time, the layout does not matter much.
        if self._visible then
            self:draw()
        end
    end

    -- Add __tostring method to metatable.
    self.drawable_name = drawable_name or object.modulename(3)
    local mt = {}
    local orig_string = tostring(self)
    mt.__tostring = function()
        return string.format("%s (%s)", self.drawable_name, orig_string)
    end
    self = setmetatable(self, mt)

    -- Make sure the drawable is drawn at least once
    self._do_complete_repaint()

    return setmetatable(self, {
        __index = function(t, k)
            if rawget(t, "get_" .. k) then
                return rawget(t, "get_" .. k)(t)
            else
                return rawget(t, k)
            end
        end,
        __newindex = function(t, k, v)
            if rawget(t, "set_" .. k) then
                rawget(t, "set_" .. k)(t, v)
            else
                rawset(t, k, v)
            end
        end,
    })
end

-- Redraw all drawables when the wallpaper changes
capi.awesome.connect_signal("wallpaper_changed", function()
    for d in pairs(visible_drawables) do
        d:_do_complete_repaint()
    end
end)

-- Give drawables a chance to react to screen changes
local function draw_all()
    for d in pairs(visible_drawables) do
        d:draw()
    end
end
screen.connect_signal("property::geometry", draw_all)
screen.connect_signal("added", draw_all)
screen.connect_signal("removed", draw_all)

return setmetatable(drawable, { __call = function(_, ...) return drawable.new(...) end })

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
