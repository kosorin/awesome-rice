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
local ipairs = ipairs
local aclient = require("awful.client")
local mresize = require("awful.mouse.resize")
local beautiful = require("theme.theme")
local uui = require("utils.ui")

local M = {}

---@param g geometry
---@param og geometry
---@param distance number
---@return geometry
local function snap_outside(g, og, distance)
    if g.x < distance + og.x + og.width and g.x > og.x + og.width then
        g.x = og.x + og.width
    elseif g.x + g.width < og.x and g.x + g.width > og.x - distance then
        g.x = og.x - g.width
    end
    if g.y < distance + og.y + og.height and g.y > og.y + og.height then
        g.y = og.y + og.height
    elseif g.y + g.height < og.y and g.y + g.height > og.y - distance then
        g.y = og.y - g.height
    end
    return g
end

---@param g geometry
---@param og geometry
---@param distance number
---@return geometry
---@return "none"|edge
local function snap_inside(g, og, distance)
    local edgev = "none"
    local edgeh = "none"

    if abs(g.x) < distance + og.x and g.x > og.x then
        edgev = "left"
        g.x = og.x
    elseif abs((og.x + og.width) - (g.x + g.width)) < distance then
        edgev = "right"
        g.x = og.x + og.width - g.width
    end
    if abs(g.y) < distance + og.y and g.y > og.y then
        edgeh = "top"
        g.y = og.y
    elseif abs((og.y + og.height) - (g.y + g.height)) < distance then
        edgeh = "bottom"
        g.y = og.y + og.height - g.height
    end

    -- What is the dominant dimension?
    if g.width > g.height then
        return g, edgeh
    else
        return g, edgev
    end
end

---Snap a client to the closest client or screen edge.
---@param client? client # The client to snap. Default: `client.focus`
---@param x integer # The client x coordinate.
---@param y integer # The client y coordinate.
---@param fixed_x? boolean # True if the client isn't allowed to move in the x direction.
---@param fixed_y? boolean # True if the client isn't allowed to move in the y direction.
---@return geometry|nil # The new geometry.
function M.snap(client, x, y, fixed_x, fixed_y)
    client = client or capi.client.focus
    if not client then
        return nil
    end

    local geo = client:geometry()
    local bw = client.border_width

    local distance = beautiful.snap.distance or 10
    local gap = uui.thickness(beautiful.snap.gap or 5)

    local bounds = uui.inflate({
        x = (x or geo.x),
        y = (y or geo.y),
        width = geo.width + 2 * bw,
        height = geo.height + 2 * bw,
    }, gap)

    local edge
    bounds, edge = snap_inside(bounds, uui.shrink(client.screen.geometry, gap), distance)
    bounds = snap_inside(bounds, uui.shrink(client.screen.tiling_area, gap), distance)

    -- Allow certain windows to snap to the edge of the workarea.
    -- Only allow docking to workarea for consistency/to avoid problems.
    if client.dockable then
        local struts = uui.thickness(0)
        if edge ~= "none" and client.floating then
            if edge == "left" or edge == "right" then
                struts[edge] = bounds.width
            elseif edge == "top" or edge == "bottom" then
                struts[edge] = bounds.height
            end
        end
        client:struts(struts)
    end

    for _, other in ipairs(aclient.visible(client.screen)) do
        if other ~= client then
            local other_geo = other:geometry()

            other_geo = uui.inflate({
                x = other_geo.x,
                y = other_geo.y,
                width = other_geo.width + 2 * bw,
                height = other_geo.height + 2 * bw,
            }, gap)

            bounds = snap_outside(bounds, other_geo, distance)
        end
    end

    bounds = uui.shrink({
        x = bounds.x,
        y = bounds.y,
        width = bounds.width - 2 * bw,
        height = bounds.height - 2 * bw,
    }, gap)

    -- It's easiest to undo changes afterwards if they're not allowed
    if fixed_x then
        bounds.x = geo.x
    end
    if fixed_y then
        bounds.y = geo.y
    end

    return bounds
end

mresize.add_move_callback(function(client, geo, args)
    return M.snap(client, geo.x, geo.y)
end, "mouse.move")

return M
