---------------------------------------------------------------------------
-- A container capable of changing the background color, foreground color and
-- widget shape.
--
--@DOC_wibox_container_defaults_background_EXAMPLE@
-- @author Uli Schlachter
-- @copyright 2010 Uli Schlachter
-- @containermod wibox.container.background
-- @supermodule wibox.widget.base
---------------------------------------------------------------------------

local base = require("wibox.widget.base")
local color = require("gears.color")
local surface = require("gears.surface")
local beautiful = require("beautiful")
local cairo = require("lgi").cairo
local gtable = require("gears.table")
local gshape = require("gears.shape")
local gdebug = require("gears.debug")
local noice = require("theme.manager")
local stylable = require("theme.stylable")
local Nil = require("theme.nil")
local setmetatable = setmetatable
local type = type
local unpack = unpack or table.unpack -- luacheck: globals unpack (compatibility with Lua 5.1)

local background = { mt = {} }

local default_style = {
    bgimage = Nil,
    bg = Nil,
    fg = Nil,
    shape = Nil,
    border_width = Nil,
    border_color = Nil,
    border_strategy = "none",
}

noice.register_element(background, "background", "widget", default_style)

for _, prop in ipairs { "bg", "fg", "shape", "border_color", "border_width" } do
    background["set_" .. prop] = function(self, value)
        if self:set_style_value(prop, value) then
            self:emit_signal("widget::redraw_needed")
            self:emit_signal("property::" .. prop, value)
        end
    end
    background["get_" .. prop] = function(self)
        return self:get_style_value(prop)
    end
end

for _, prop in ipairs { "border_strategy" } do
    background["set_" .. prop] = function(self, value)
        if self:set_style_value(prop, value) then
            self:emit_signal("widget::layout_changed")
            self:emit_signal("property::" .. prop, value)
        end
    end
    background["get_" .. prop] = function(self)
        return self:get_style_value(prop)
    end
end

-- The Cairo SVG backend doesn't support surface as patterns correctly.
-- The result is both glitchy and blocky. It is also impossible to introspect.
-- Calling this function replace the normal code path is a "less correct", but
-- more widely compatible version.
function background._use_fallback_algorithm()
    background.before_draw_children = function(self, _, cr, width, height)
        local bw = self:get_style_value("border_width") or 0

        if bw > 0 then
            cr:translate(bw, bw)
            width, height = width - 2*bw, height - 2*bw
        end

        local shape = self:get_style_value("shape") or gshape.rectangle
        shape(cr, width, height)

        local bg = self:get_style_value("bg")
        if bg then
            cr:save() --Save to avoid messing with the original source
            cr:set_source(color(bg))
            cr:fill_preserve()
            cr:restore()
        end

        cr:translate(-bw, -bw)
        cr:clip()

        local fg = self:get_style_value("fg")
        if fg then
            cr:set_source(color(fg))
        end
    end

    background.after_draw_children = function(self, _, cr, width, height)
        local bw = self:get_style_value("border_width") or 0

        if bw > 0 then
            cr:save()
            cr:reset_clip()

            local mat = cr:get_matrix()

            -- Prevent the inner part of the border from being written.
            local mask = cairo.RecordingSurface(cairo.Content.COLOR_ALPHA,
                cairo.Rectangle { x = 0, y = 0, width = mat.x0 + width, height = mat.y0 + height })

            local mask_cr = cairo.Context(mask)
            mask_cr:set_matrix(mat)

            -- Clear the surface.
            mask_cr:set_operator(cairo.Operator.CLEAR)
            mask_cr:set_source_rgba(0, 1, 0, 0)
            mask_cr:paint()

            -- Paint the inner and outer borders.
            local shape = self:get_style_value("shape") or gshape.rectangle
            mask_cr:set_operator(cairo.Operator.SOURCE)
            mask_cr:translate(bw, bw)
            mask_cr:set_source_rgba(1, 0, 0, 1)
            mask_cr:set_line_width(2*bw)
            shape(mask_cr, width - 2*bw, height - 2*bw)
            mask_cr:stroke_preserve()

            -- Remove the inner part.
            mask_cr:set_source_rgba(0, 1, 0, 0)
            mask_cr:set_operator(cairo.Operator.CLEAR)
            mask_cr:fill()
            mask:flush()

            cr:set_source(color(self:get_style_value("border_color") or self:get_style_value("fg") or beautiful.fg_normal))
            cr:mask_surface(mask, 0,0)
            cr:restore()
        end
    end
end

-- Make sure a surface pattern is freed *now*
local function dispose_pattern(pattern)
    local status, s = pattern:get_surface()
    if status == "SUCCESS" then
        s:finish()
    end
end

-- Prepare drawing the children of this widget
function background:before_draw_children(context, cr, width, height)
    local bw    = self:get_style_value("border_width") or 0
    local shape = self:get_style_value("shape") or (bw > 0 and gshape.rectangle or nil)

    -- Redirect drawing to a temporary surface if there is a shape
    if shape then
        cr:push_group_with_content(cairo.Content.COLOR_ALPHA)
    end

    -- Draw the background
    local bg = self:get_style_value("bg")
    if bg then
        cr:save()
        cr:set_source(color(bg))
        cr:rectangle(0, 0, width, height)
        cr:fill()
        cr:restore()
    end
    if self._private.bgimage then
        cr:save()
        if type(self._private.bgimage) == "function" then
            self._private.bgimage(context, cr, width, height)
        else
            local pattern = cairo.Pattern.create_for_surface(self._private.bgimage)
            cr:set_source(pattern)
            cr:rectangle(0, 0, width, height)
            cr:fill()
        end
        cr:restore()
    end

    local fg = self:get_style_value("fg")
    if fg then
        cr:set_source(color(fg))
    end
end

-- Draw the border
function background:after_draw_children(_, cr, width, height)
    local bw    = self:get_style_value("border_width") or 0
    local shape = self:get_style_value("shape") or (bw > 0 and gshape.rectangle or nil)

    if not shape then
        return
    end

    -- Okay, there is a shape. Get it as a path.

    cr:translate(bw, bw)
    shape(cr, width - 2*bw, height - 2*bw)
    cr:translate(-bw, -bw)

    if bw > 0 then
        -- Now we need to do a border, somehow. We begin with another
        -- temporary surface.
        cr:push_group_with_content(cairo.Content.ALPHA)

        -- Mark everything as "this is border"
        cr:set_source_rgba(0, 0, 0, 1)
        cr:paint()

        -- Now remove the inside of the shape to get just the border
        cr:set_operator(cairo.Operator.SOURCE)
        cr:set_source_rgba(0, 0, 0, 0)
        cr:fill_preserve()

        local mask = cr:pop_group()
        -- Now actually draw the border via the mask we just created.
        cr:set_source(color(self:get_style_value("border_color") or self:get_style_value("fg") or beautiful.fg_normal))
        cr:set_operator(cairo.Operator.SOURCE)
        cr:mask(mask)

        dispose_pattern(mask)
    end

    -- We now have the right content in a temporary surface. Copy it to the
    -- target surface. For this, we need another mask
    cr:push_group_with_content(cairo.Content.ALPHA)

    -- Draw the border with 2 * border width (this draws both
    -- inside and outside, only half of it is outside)
    cr.line_width = 2 * bw
    cr:set_source_rgba(0, 0, 0, 1)
    cr:stroke_preserve()

    -- Now fill the whole inside so that it is also include in the mask
    cr:fill()

    local mask = cr:pop_group()
    local source = cr:pop_group() -- This pops what was pushed in before_draw_children

    -- This now draws the content of the background widget to the actual
    -- target, but only the part that is inside the mask
    cr:set_operator(cairo.Operator.OVER)
    cr:set_source(source)
    cr:mask(mask)

    dispose_pattern(mask)
    dispose_pattern(source)
end

-- Layout this widget
function background:layout(_, width, height)
    if self._private.widget then
        local bw = self:get_style_value("border_strategy") == "inner"
            and self:get_style_value("border_width")
            or 0

        return { base.place_widget_at(
            self._private.widget, bw, bw, width-2*bw, height-2*bw
        ) }
    end
end

-- Fit this widget into the given area
function background:fit(context, width, height)
    if not self._private.widget then
        return 0, 0
    end

    local bw = self:get_style_value("border_strategy") == "inner"
        and self:get_style_value("border_width")
        or 0

    local w, h = base.fit_widget(
        self, context, self._private.widget, width - 2*bw, height - 2*bw
    )

    return w+2*bw, h+2*bw
end

--- The widget displayed in the background widget.
-- @property widget
-- @tparam[opt=nil] widget|nil widget The widget to be disaplayed inside of
--  the background area.
-- @interface container

background.set_widget = base.set_widget_common

function background:get_widget()
    return self._private.widget
end

function background:get_children()
    return {self._private.widget}
end

function background:set_children(children)
    self:set_widget(children[1])
end

--- The background color/pattern/gradient to use.
--
--@DOC_wibox_container_background_bg_EXAMPLE@
--
-- @property bg
-- @tparam color bg
-- @propertydefault When unspecified, it will inherit the value from an higher
--  level `wibox.container.background` or directly from the `wibox.bg` property.
-- @see gears.color
-- @propemits true false

--- The foreground (text) color/pattern/gradient to use.
--
--@DOC_wibox_container_background_fg_EXAMPLE@
--
-- @property fg
-- @tparam color fg A color string, pattern or gradient
-- @propertydefault When unspecified, it will inherit the value from an higher
--  level `wibox.container.background` or directly from the `wibox.fg` property.
-- @propemits true false
-- @see gears.color

--- The background shape.
--
--@DOC_wibox_container_background_shape_EXAMPLE@
--
-- @property shape
-- @tparam[opt=gears.shape.rectangle] shape shape
-- @see gears.shape
-- @see set_shape

--- Set the background shape.
--
-- Any other arguments will be passed to the shape function.
--
-- @method set_shape
-- @tparam gears.shape|function shape A function taking a context, width and height as arguments
-- @noreturn
-- @propemits true false
-- @see gears.shape
-- @see shape

--- When a `shape` is set, also draw a border.
--
-- See `wibox.container.background.shape` for an usage example.
--
-- @deprecatedproperty shape_border_width
-- @tparam number width The border width
-- @renamedin 4.4 border_width
-- @see border_width

--- Add a border of a specific width.
--
-- If the shape is set, the border will also be shaped.
--
-- See `wibox.container.background.shape` for an usage example.
-- @property border_width
-- @tparam[opt=0] number border_width
-- @propertyunit pixel
-- @negativeallowed false
-- @propemits true false
-- @introducedin 4.4
-- @see border_color

function background.get_shape_border_width(...)
    gdebug.deprecate("Use `border_width` instead of `shape_border_width`",
        {deprecated_in=5})

    return background.get_border_width(...)
end

function background.set_shape_border_width(...)
    gdebug.deprecate("Use `border_width` instead of `shape_border_width`",
        {deprecated_in=5})

    background.set_border_width(...)
end

--- When a `shape` is set, also draw a border.
--
-- See `wibox.container.background.shape` for an usage example.
--
-- @deprecatedproperty shape_border_color
-- @usebeautiful beautiful.fg_normal Fallback when 'fg' and `border_color` aren't set.
-- @tparam color fg The border color, pattern or gradient
-- @renamedin 4.4 border_color
-- @see gears.color
-- @see border_color

--- Set the color for the border.
--
-- See `wibox.container.background.shape` for an usage example.
-- @property border_color
-- @tparam color border_color
-- @propertydefault `wibox.container.background.fg` if set, otherwise `beautiful.fg_normal`.
-- @propemits true false
-- @usebeautiful beautiful.fg_normal Fallback when 'fg' and `border_color` aren't set.
-- @introducedin 4.4
-- @see gears.color
-- @see border_width

function background.get_shape_border_color(...)
    gdebug.deprecate("Use `border_color` instead of `shape_border_color`",
        {deprecated_in=5})

    return background.get_border_color(...)
end

function background.set_shape_border_color(...)
    gdebug.deprecate("Use `border_color` instead of `shape_border_color`",
        {deprecated_in=5})

    background.set_border_color(...)
end

function background:set_shape_clip(value)
    if value then return end
    require("gears.debug").print_warning("shape_clip property of background container was removed."
        .. " Use wibox.layout.stack instead if you want shape_clip=false.")
end

function background:get_shape_clip()
    require("gears.debug").print_warning("shape_clip property of background container was removed."
        .. " Use wibox.layout.stack instead if you want shape_clip=false.")
    return true
end

--- How the border width affects the contained widget.
--
-- @property border_strategy
-- @tparam[opt="none"] string border_strategy
-- @propertyvalue "none" Just apply the border, do not affect the content size (default).
-- @propertyvalue "inner" Squeeze the size of the content by the border width.

--- The background image to use.
--
-- If `image` is a function, it will be called with `(context, cr, width, height)`
-- as arguments.
--
-- @property bgimage
-- @tparam[opt=nil] image|nil bgimage
-- @see gears.surface

function background:set_bgimage(image)
    if self:set_style_value("bgimage", image) then
        self._private.bgimage = type(image) == "function" and image or surface.load(image)
        self:emit_signal("widget::redraw_needed")
        self:emit_signal("property::bgimage", image)
    end
end

function background:get_bgimage()
    return self._private.bgimage
end

--- Returns a new background container.
--
-- A background container applies a background and foreground color
-- to another widget.
--
-- @tparam[opt] widget widget The widget to display.
-- @tparam[opt] color bg The background to use for that widget.
-- @tparam[opt] gears.shape|function shape A `gears.shape` compatible shape function
-- @constructorfct wibox.container.background
local function new(widget, bg, shape)
    local ret = base.make_widget(nil, nil, {
        enable_properties = true,
    })

    gtable.crush(ret, background, true)
    stylable.initialize(ret, background)

    if shape then
        ret:set_shape(shape)
    end

    if bg then
        ret:set_bg(bg)
    end

    ret:set_widget(widget)

    return ret
end

function background.mt:__call(...)
    return new(...)
end

return setmetatable(background, background.mt)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
