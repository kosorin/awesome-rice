---------------------------------------------------------------------------
--- Mouse snapping related functions
--
-- @author Julien Danjou &lt;julien@danjou.info&gt;
-- @copyright 2008 Julien Danjou
-- @copyright 2023 David Kosorin
-- @submodule mouse
---------------------------------------------------------------------------

local capi = Capi
local abs = math.abs
local alayout = require("awful.layout")
local amresize = require("awful.mouse.resize")
local aplacement = require("awful.placement")
local gcolor = require("gears.color")
local gshape = require("gears.shape")
local wibox = require("wibox")
local cairo = require("lgi").cairo
local beautiful = require("theme.theme")
local uui = require("utils.ui")


local placement_context = "edge_snap"

---@type wibox|nil
local preview_wibox = nil

---@type { edge?: edge|corner, placement?: (fun(client: client, preview?: boolean): geometry) }
local current_state = {}

---@param geo geometry
local function draw_preview(geo)
    local shape = beautiful.snap.edge.shape or gshape.rectangle
    local border_width = beautiful.snap.edge.border_width or 5

    local img = cairo.ImageSurface(cairo.Format.A1, geo.width + border_width, geo.height + border_width)
    local cr = cairo.Context(img)

    cr:set_operator(cairo.Operator.CLEAR)
    cr:set_source_rgba(0, 0, 0, 1)
    cr:paint()
    cr:set_operator(cairo.Operator.SOURCE)
    cr:set_source_rgba(1, 1, 1, 1)

    cr:set_line_width(border_width)
    cr:translate(border_width, border_width)
    shape(cr, geo.width - 2 * border_width, geo.height - 2 * border_width)
    cr:stroke()

    preview_wibox.shape_bounding = img._native
    img:finish()
end

---@param geo? geometry
local function show_preview(geo)
    if not geo then
        if preview_wibox then
            preview_wibox.visible = false
        end
        return
    end

    preview_wibox = preview_wibox or wibox {
        ontop = true,
        bg = gcolor(beautiful.snap.edge.bg or "#ff0000"),
    }

    preview_wibox:geometry(geo)

    draw_preview(geo)

    preview_wibox.visible = true
end

---@param client client
---@return boolean
local function update(client)
    local coords = capi.mouse.coords()
    local sg = client.screen.geometry

    local distance = beautiful.snap.edge.distance or 10
    local gap = uui.thickness(beautiful.snap.gap or 5) * 2

    local v, h

    if abs(coords.x) <= distance + sg.x and coords.x >= sg.x then
        h = "left"
        gap.right = gap.right / 2
    elseif abs((sg.x + sg.width) - coords.x) <= distance then
        h = "right"
        gap.left = gap.left / 2
    end

    if abs(coords.y) <= distance + sg.y and coords.y >= sg.y then
        v = "top"
        gap.bottom = gap.bottom / 2
    elseif abs((sg.y + sg.height) - coords.y) <= distance then
        v = "bottom"
        gap.top = gap.top / 2
    end

    local edge, axis
    if v and h then
        edge = v .. "_" .. h
    elseif h then
        edge = h
        axis = "vertically"
    elseif v then
        edge = v
        axis = "horizontally"
    end

    local changed = current_state.edge ~= edge

    current_state.edge = edge

    if changed then
        if edge then
            local placement = edge and (aplacement.scale
                + aplacement[edge]
                + (axis and aplacement["maximize_" .. axis] or nil))
            current_state.placement = function(c, preview)
                return placement(c, {
                    pretend = preview,
                    store_geometry = not preview,
                    context = placement_context,
                    to_percent = 0.5,
                    honor_workarea = true,
                    honor_padding = true,
                    margins = gap,
                })
            end
        else
            current_state.placement = nil
        end
    end

    return changed
end


---@param client client
local function detect(client)
    if (not client.floating) and alayout.get(client.screen) ~= alayout.suit.floating then
        return
    end

    if not update(client) then
        return
    end

    local geo
    if current_state.placement then
        geo = current_state.placement(client, true)
        geo.width = geo.width + 2 * client.border_width
        geo.height = geo.height + 2 * client.border_width
    end
    show_preview(geo)
end

---@param client client
---@param args awful.placement.args.common
---@return geometry|nil
local function apply(client, args)
    if not current_state.placement then
        return nil
    end

    -- Remove the move offset
    args.offset = {}

    preview_wibox.visible = false

    return current_state.placement(client, false)
end

amresize.add_move_callback(function(client, geo, args)
    aplacement.restore(client, { context = placement_context, clear_stored_geometry = true })
    detect(client)
end, "mouse.move")

amresize.add_leave_callback(function(client, geo, args)
    return apply(client, args)
end, "mouse.move")
