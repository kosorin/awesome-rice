---------------------------------------------------------------------------
--- The main AwesomeWM "bar" module.
--
-- This module allows you to easily create wibox and attach them to the edge of
-- a screen.
--
--@DOC_awful_wibar_default_EXAMPLE@
--
-- You can even have vertical bars too.
--
--@DOC_awful_wibar_left_EXAMPLE@
--
-- @author Emmanuel Lepage Vallee &lt;elv1313@gmail.com&gt;
-- @copyright 2016 Emmanuel Lepage Vallee
-- @popupmod awful.wibar
-- @supermodule awful.popup
---------------------------------------------------------------------------

-- Grab environment we need
local capi =
{
    screen = screen,
    client = client,
}
local setmetatable = setmetatable
local tostring = tostring
local ipairs = ipairs
local error = error
local wibox = require("wibox")
local beautiful = require("beautiful")
local gdebug = require("gears.debug")
local placement = require("awful.placement")
local gtable = require("gears.table")
local gthickness = require("gears.thickness")
local noice = require("theme.manager")
local stylable = require("theme.stylable")
local Nil = require("theme.nil")

local function get_screen(s)
    return s and capi.screen[s]
end

local awfulwibar = { mt = {} }

local default_style = {
    margins = gthickness(0),
    position = "top",
    stretch = true,
    align = "centered",
    restrict_workarea = true,
}

noice.register_element(awfulwibar, "wibar", "wibox", default_style)

--- Array of table with wiboxes inside.
-- It's an array so it is ordered.
local wiboxes = setmetatable({}, { __mode = "v" })

local opposite_margin = {
    top    = "bottom",
    bottom = "top",
    left   = "right",
    right  = "left",
}

local positions = {
    left   = true,
    right  = true,
    top    = true,
    bottom = true,
}

local aligns = {
    top      = true,
    left     = true,
    bottom   = true,
    right    = true,
    centered = true,
}

local align_map = {
    top      = "left",
    left     = "top",
    bottom   = "right",
    right    = "bottom",
    centered = "centered",
}

--- If the wibar needs to be stretched to fill the screen.
--
-- @DOC_awful_wibar_stretch_EXAMPLE@
--
-- @property stretch
-- @tparam[opt=true] boolean|nil stretch
-- @propbeautiful
-- @propemits true false
-- @see align

--- How to align non-stretched wibars.
--
--  @DOC_awful_wibar_align_EXAMPLE@
--
-- @property align
-- @tparam[opt="centered"] string|nil align
-- @propertyvalue "top"
-- @propertyvalue "bottom"
-- @propertyvalue "left"
-- @propertyvalue "right"
-- @propertyvalue "centered"
-- @propbeautiful
-- @propemits true false
-- @see stretch

--- Margins on each side of the wibar.
--
-- It can either be a table with `top`, `bottom`, `left` and `right`
-- properties, or a single number that applies to all four sides.
--
-- @DOC_awful_wibar_margins_EXAMPLE@
--
-- @property margins
-- @tparam[opt=0] number|table|nil margins
-- @tparam[opt=0] number margins.left
-- @tparam[opt=0] number margins.right
-- @tparam[opt=0] number margins.top
-- @tparam[opt=0] number margins.bottom
-- @negativeallowed true
-- @propertytype number A single value for each side.
-- @propertytype table A different value for each side.
-- @propertytype nil Fallback to `beautiful.wibar_margins`.
-- @propertyunit pixel
-- @propbeautiful
-- @propemits true false

--- If the wibar needs to be stretched to fill the screen.
--
-- @beautiful beautiful.wibar_stretch
-- @tparam boolean stretch

--- Allow or deny the tiled clients to cover the wibar.
--
-- In the example below, we can see that the first screen workarea
-- shrunk by the height of the wibar while the second screen is
-- unchanged.
--
-- @DOC_screen_wibar_workarea_EXAMPLE@
--
-- @property restrict_workarea
-- @tparam[opt=true] boolean restrict_workarea
-- @propemits true false
-- @see client.struts
-- @see screen.workarea

--- If there is both vertical and horizontal wibar, give more space to vertical ones.
--
-- By default, if multiple wibars risk overlapping, it will be resolved
-- by giving more space to the horizontal one:
--
-- ![wibar position](../images/AUTOGEN_awful_wibar_position.svg)
--
-- If this variable is to to `true`, it will behave like:
--
-- @DOC_awful_wibar_position2_EXAMPLE@
--
-- @beautiful beautiful.wibar_favor_vertical
-- @tparam[opt=false] boolean favor_vertical

--- The wibar border width.
-- @beautiful beautiful.wibar_border_width
-- @tparam integer border_width

--- The wibar border color.
-- @beautiful beautiful.wibar_border_color
-- @tparam string border_color

--- If the wibar is to be on top of other windows.
-- @beautiful beautiful.wibar_ontop
-- @tparam boolean ontop

--- The wibar's mouse cursor.
-- @beautiful beautiful.wibar_cursor
-- @tparam string cursor

--- The wibar opacity, between 0 and 1.
-- @beautiful beautiful.wibar_opacity
-- @tparam number opacity

--- The window type (desktop, normal, dock, …).
-- @beautiful beautiful.wibar_type
-- @tparam string type

--- The wibar's width.
-- @beautiful beautiful.wibar_width
-- @tparam integer width

--- The wibar's height.
-- @beautiful beautiful.wibar_height
-- @tparam integer height

--- The wibar's background color.
-- @beautiful beautiful.wibar_bg
-- @tparam color bg

--- The wibar's background image.
-- @beautiful beautiful.wibar_bgimage
-- @tparam surface bgimage

--- The wibar's foreground (text) color.
-- @beautiful beautiful.wibar_fg
-- @tparam color fg

--- The wibar's shape.
-- @beautiful beautiful.wibar_shape
-- @tparam gears.shape shape

--- The wibar's margins.
-- @beautiful beautiful.wibar_margins
-- @tparam number|table margins

--- The wibar's alignments.
-- @beautiful beautiful.wibar_align
-- @tparam string align


-- Compute the margin on one side
local function get_placement_margin(self, position, auto_stop)
    local size_name = (position == "top" or position == "bottom") and "height" or "width"
    local margin = 0

    for _, other in ipairs(wiboxes) do
        -- Ignore the wibars placed after this one
        if auto_stop and other == self then
            break
        end

        if other.visible and other.screen == self.screen and ((other:get_style_value("position") or "top") == position) then
            margin = margin + other:get_style_value(size_name)
            local other_margins = other:get_style_value("margins")
            if other_margins then
                margin = margin + other_margins[position] + other_margins[opposite_margin[position]]
            end
        end
    end

    return margin
end

-- `honor_workarea` cannot be used as it does modify the workarea itself.
-- a manual padding has to be generated.
local function get_placement_margins(self)
    local position = self:get_style_value("position") or "top"
    local margins = (self:get_style_value("margins") or gthickness.zero):clone(false)

    margins[position] = margins[position] + get_placement_margin(self, position, true)

    -- Avoid overlapping wibars
    if (position == "left" or position == "right") and not beautiful.wibar_favor_vertical then
        margins.top    = get_placement_margin(self, "top")
        margins.bottom = get_placement_margin(self, "bottom")
    elseif (position == "top" or position == "bottom") and beautiful.wibar_favor_vertical then
        margins.left  = get_placement_margin(self, "left")
        margins.right = get_placement_margin(self, "right")
    end

    return gthickness(margins)
end

-- Create the placement function
local function build_placement(position, align, stretch)
    local maximize = (position == "right" or position == "left") and "maximize_vertically" or "maximize_horizontally"

    local corner = nil

    if align ~= "centered" then
        if position == "right" or position == "left" then
            corner = placement[align .. "_" .. position] or placement[align_map[align] .. "_" .. position]
        else
            corner = placement[position .. "_" .. align] or placement[position .. "_" .. align_map[align]]
        end
    end

    corner = corner or placement[position]

    return corner + (stretch and placement[maximize] or nil)
end

-- Attach the placement function.
local function reattach(self)
    if self._private.skip_reattach then
        return
    end

    if self.detach_callback then
        self.detach_callback()
        self.detach_callback = nil
    end

    local position = self:get_style_value("position") or "top"
    local align = self:get_style_value("align") or "centered"
    local stretch = self:get_style_value("stretch")
    local placement = build_placement(position, align, stretch)

    local restrict_workarea = self:get_style_value("restrict_workarea")
    local margins = get_placement_margins(self)
    placement(self, {
        attach          = true,
        update_workarea = restrict_workarea,
        margins         = margins,
    })
end

-- Re-attach all wibars on a given wibar screen
local function reattach_all(self)
    if self._private.skip_reattach then
        return
    end

    -- Changing the position will also cause the other margins to be invalidated.
    -- For example, adding a wibar to the top will change the margins of any left
    -- or right wibars. To solve, this, they need to be re-attached.

    local s = self.screen
    for _, w in ipairs(wiboxes) do
        if w.screen == s then
            reattach(w)
        end
    end
end

--- The wibox position.
--
-- @DOC_awful_wibar_position_EXAMPLE@
--
-- @property position
-- @tparam[opt="top"] string position
-- @propertyvalue "left"
-- @propertyvalue "right"
-- @propertyvalue "top"
-- @propertyvalue "bottom"
-- @propemits true false

function awfulwibar.set_position(self, position)
    local old_position = self:get_style_value("position")

    if not positions[position] then
        position = "top"
    end
    if self:set_style_value("position", position) then
        reattach_all(self)
        self:emit_signal("property::position", position)
    end
end

function awfulwibar:get_position()
    return self:get_style_value("position")
end

function awfulwibar:set_margins(margins)
    margins = gthickness(margins)
    if self:set_style_value("margins", margins) then
        reattach_all(self)
        self:emit_signal("property::margins", margins)
    end
end

function awfulwibar:get_margins()
    return self:get_style_value("margins")
end

function awfulwibar.set_align(self, align)
    if not aligns[align] then
        align = "centered"
    end
    if self:set_style_value("align", align) then
        reattach(self)
        self:emit_signal("property::align", align)
    end
end

function awfulwibar.get_align(self)
    return self:get_style_value("align")
end

function awfulwibar:set_restrict_workarea(value)
    if self:set_style_value("restrict_workarea", value) then
        reattach_all(self)
        self:emit_signal("property::restrict_workarea", value)
    end
end

function awfulwibar:get_restrict_workarea()
    return self:get_style_value("restrict_workarea")
end

function awfulwibar:set_stretch(stretch)
    stretch = not not stretch
    if self:set_style_value("stretch", stretch) then
        reattach(self)
        self:emit_signal("property::stretch", stretch)
    end
end

function awfulwibar:get_stretch()
    return self:get_style_value("stretch")
end

--- Remove a wibar.
-- @method remove
-- @noreturn

function awfulwibar:remove()
    self.visible = false

    if self.detach_callback then
        self.detach_callback()
        self.detach_callback = nil
    end

    for k, w in ipairs(wiboxes) do
        if w == self then
            table.remove(wiboxes, k)
        end
    end

    self._screen = nil
end

--- Stretch a wibox so it takes all screen width or height.
--
-- **This function has been removed.**
--
-- @deprecated awful.wibox.stretch
-- @see awful.placement
-- @see awful.wibar.stretch

--- Create a new wibox and attach it to a screen edge.
-- You can add also position key with value top, bottom, left or right.
-- You can also use width or height in % and set align to center, right or left.
-- You can also set the screen key with a screen number to attach the wibox.
-- If not specified, the primary screen is assumed.
-- @see wibox
-- @tparam[opt=nil] table args
-- @tparam string args.position The position.
-- @tparam string args.stretch If the wibar need to be stretched to fill the screen.
-- @tparam boolean args.restrict_workarea Allow or deny the tiled clients to cover the wibar.
-- @tparam string args.align How to align non-stretched wibars.
-- @tparam table|number args.margins The wibar margins.
--@DOC_wibox_constructor_COMMON@
-- @return The new wibar
-- @constructorfct awful.wibar
-- @usebeautiful beautiful.wibar_favor_vertical
-- @usebeautiful beautiful.wibar_border_width
-- @usebeautiful beautiful.wibar_border_color
-- @usebeautiful beautiful.wibar_ontop
-- @usebeautiful beautiful.wibar_cursor
-- @usebeautiful beautiful.wibar_opacity
-- @usebeautiful beautiful.wibar_type
-- @usebeautiful beautiful.wibar_width
-- @usebeautiful beautiful.wibar_height
-- @usebeautiful beautiful.wibar_bg
-- @usebeautiful beautiful.wibar_bgimage
-- @usebeautiful beautiful.wibar_fg
-- @usebeautiful beautiful.wibar_shape
function awfulwibar.new(args)
    args = args or {}
    args.type = args.type or "dock"

    local position = args.position
    if not positions[position] then
        position = "top"
    end

    local screen = get_screen(args.screen or 1)

    args.screen = nil

    local self = wibox(args)

    self:set_screen(screen)
    self._screen = screen --HACK When a screen is removed, then getbycoords won't work

    -- `self` needs to be inserted in `wiboxes` before reattach or its own offset
    -- will not be taken into account by the "older" wibars when `reattach` is
    -- called. `skip_reattach` is required.
    self._private.skip_reattach = true

    gtable.crush(self, awfulwibar, true)
    stylable.initialize(self, awfulwibar)

    if args.stretch ~= nil then
        self:set_stretch(args.stretch)
    end

    if args.restrict_workarea ~= nil then
        self:set_restrict_workarean(args.restrict_workarea)
    end

    if args.align then
        self:set_align(args.align)
    end

    if args.margins then
        self:set_margins(args.margins)
    end

    if args.position then
        self:set_position(args.position)
    end

    -- Now, let set_position behave normally.
    table.insert(wiboxes, self)
    self._private.skip_reattach = false

    -- Force all the wibars to be moved
    reattach_all(self)

    self:connect_signal("property::visible", function() reattach_all(self) end)

    self:request_style()

    return self
end

capi.screen.connect_signal("removed", function(s)
    local removed_wibars = {}
    for _, wibar in ipairs(wiboxes) do
        if wibar._screen == s then
            table.insert(removed_wibars, wibar)
        end
    end
    for _, wibar in ipairs(removed_wibars) do
        wibar:remove()
    end
end)

function awfulwibar.mt:__call(...)
    return awfulwibar.new(...)
end

return setmetatable(awfulwibar, awfulwibar.mt)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
