--------------------------------------------------------------------------------
---Mouse snapping related functions
---@author Julien Danjou &lt;julien@danjou.info&gt;
---@copyright 2008 Julien Danjou
---@copyright 2023 David Kosorin
---@submodule mouse
--------------------------------------------------------------------------------

local capi = Capi
local abs = math.abs
local alayout = require("awful.layout")
local aplacement = require("awful.placement")
local gshape = require("gears.shape")
local wibox = require("wibox")
local cairo = require("lgi").cairo
local beautiful = require("theme.theme")
local uui = require("utils.thickness")

local M = {}

local stored_geometries = setmetatable({}, { __mode = "k" })

---@type wibox|nil
local preview_wibox = nil

---@type { edge?: edge|corner, placement?: (fun(client: client): geometry) }
local current_state = {}

---@param geo geometry
---@param shape shape
---@param border_width number
local function draw_border_preview(geo, shape, border_width)
    ---@cast shape -false

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

---@param client client
---@param geo? geometry
local function show_preview(client, geo)
    if not geo then
        if preview_wibox then
            preview_wibox.visible = false
        end
        return
    end

    local bg = beautiful.snap.edge.bg and (beautiful.snap.edge.bg or "#ffffff33")
    local border_color = beautiful.snap.edge.border_color or "#ff0000"
    local border_width = beautiful.snap.edge.border_width or 5
    local shape = beautiful.snap.edge.shape or gshape.rectangle

    preview_wibox = preview_wibox or wibox {
        ontop = true,
        bg = bg and bg or border_color,
        border_color = bg and border_color or nil,
        border_width = bg and border_width or 0,
        shape = shape,
    }

    if bg then
        geo.width = geo.width + 2 * (client.border_width - border_width)
        geo.height = geo.height + 2 * (client.border_width - border_width)
    else
        geo.width = geo.width + 2 * client.border_width
        geo.height = geo.height + 2 * client.border_width
    end

    preview_wibox:geometry(geo)

    if not bg then
        draw_border_preview(geo, shape, border_width)
    end

    preview_wibox.visible = true
end

---@param client client
---@return boolean
local function update(client)
    local coords = capi.mouse.coords()
    local sg = client.screen.geometry

    local distance = beautiful.snap.edge.distance or 10
    local gap = uui.new(beautiful.snap.gap or 5) * 2

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
            current_state.placement = function(c)
                return placement(c, {
                    pretend = true,
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
function M.detect(client)
    if (not client.floating) and alayout.get(client.screen) ~= alayout.suit.floating then
        return
    end

    if not update(client) then
        return
    end

    local placement = current_state.placement
    local geo = placement and placement(client)
    show_preview(client, geo)
end

---@param client client
function M.store(client)
    stored_geometries[client] = client:geometry()
end

---@param client client
---@return geometry|nil
function M.try_restore(client)
    local geo = stored_geometries[client]
    stored_geometries[client] = nil
    return geo
end

---@param client client
---@param args awful.placement.args.common
---@return geometry|nil
function M.apply(client, args)
    local placement = current_state.placement
    if not placement then
        return
    end

    args.offset = {}

    preview_wibox.visible = false

    M.store(client)

    return placement(client)
end

return M
