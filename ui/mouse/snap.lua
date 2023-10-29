--------------------------------------------------------------------------------
---Mouse snapping related functions
---@author Julien Danjou &lt;julien@danjou.info&gt;
---@copyright 2008 Julien Danjou
---@copyright 2023 David Kosorin
---@submodule mouse
--------------------------------------------------------------------------------

local capi = Capi
local ipairs = ipairs
local sfind = string.find
local aclient = require("awful.client")
local beautiful = require("theme.theme")
local uui = require("utils.thickness")
local ugeometry = require("utils.geometry")

local M = {}

---@param func fun(geometry: geometry, thickness: thickness_value): geometry
---@param client client
---@param geometry geometry
---@param gap thickness
---@return geometry
local function fix_client_geometry(func, client, geometry, gap)
    return func(geometry, gap + { right = 2 * client.border_width, bottom = 2 * client.border_width })
end

-- Move
do
    ---@param g geometry
    ---@param og geometry
    ---@param distance number
    ---@return geometry
    local function snap_inside(g, og, distance)
        local diff

        diff = g.x - og.x
        if 0 < diff and diff < distance then
            g.x = g.x - diff
        else
            diff = (og.x + og.width) - (g.x + g.width)
            if 0 < diff and diff < distance then
                g.x = g.x + diff
            end
        end

        diff = g.y - og.y
        if 0 < diff and diff < distance then
            g.y = g.y - diff
        else
            diff = (og.y + og.height) - (g.y + g.height)
            if 0 < diff and diff < distance then
                g.y = g.y + diff
            end
        end

        return g
    end

    ---@param g geometry
    ---@param og geometry
    ---@param distance number
    ---@return geometry
    local function snap_outside(g, og, distance)
        local diff

        diff = g.x - (og.x + og.width)
        if 0 < diff and diff < distance then
            g.x = g.x - diff
        else
            diff = og.x - (g.x + g.width)
            if 0 < diff and diff < distance then
                g.x = g.x + diff
            end
        end

        diff = g.y - (og.y + og.height)
        if 0 < diff and diff < distance then
            g.y = g.y - diff
        else
            diff = og.y - (g.y + g.height)
            if 0 < diff and diff < distance then
                g.y = g.y + diff
            end
        end

        return g
    end

    ---Snap a client to the closest client or screen edge.
    ---@param client? client # The client to snap. Default: `client.focus`
    ---@param geo? geometry # The geometry.
    ---@return geometry|nil # The new geometry.
    function M.move(client, geo)
        client = client or capi.client.focus
        if not client then
            return
        end

        local distance = beautiful.snap.distance or 10
        local gap = uui.new(beautiful.snap.gap or 5)

        geo = fix_client_geometry(ugeometry.inflate, client, geo or client:geometry(), gap)

        geo = snap_inside(geo, ugeometry.shrink(client.screen.geometry, gap), distance)
        geo = snap_inside(geo, ugeometry.shrink(client.screen.tiling_area, gap), distance)

        for _, other in ipairs(aclient.visible(client.screen)) do
            if other ~= client then
                local other_geo = fix_client_geometry(ugeometry.inflate, other, other:geometry(), gap)
                geo = snap_inside(geo, other_geo, distance)
                geo = snap_outside(geo, other_geo, distance)
            end
        end

        return fix_client_geometry(ugeometry.shrink, client, geo, gap)
    end
end

-- Resize
do
    ---@param g geometry
    ---@param og geometry
    ---@param distance number
    ---@param origin edge|corner
    ---@return geometry
    local function snap_inside(g, og, distance, origin)
        if sfind(origin, "left", nil, true) then
            local diff = g.x - og.x
            if 0 < diff and diff < distance then
                g.x = og.x
                g.width = g.width + diff
            end
        elseif sfind(origin, "right", nil, true) then
            local diff = (og.x + og.width) - (g.x + g.width)
            if 0 < diff and diff < distance then
                g.width = g.width + diff
            end
        end
        if sfind(origin, "top", nil, true) then
            local diff = g.y - og.y
            if 0 < diff and diff < distance then
                g.y = og.y
                g.height = g.height + diff
            end
        elseif sfind(origin, "bottom", nil, true) then
            local diff = (og.y + og.height) - (g.y + g.height)
            if 0 < diff and diff < distance then
                g.height = g.height + diff
            end
        end
        return g
    end

    ---@param g geometry
    ---@param og geometry
    ---@param distance number
    ---@param origin edge|corner
    ---@return geometry
    local function snap_outside(g, og, distance, origin)
        if sfind(origin, "left", nil, true) then
            local diff = g.x - (og.x + og.width)
            if 0 < diff and diff < distance then
                g.x = g.x - diff
                g.width = g.width + diff
            end
        elseif sfind(origin, "right", nil, true) then
            local diff = og.x - (g.x + g.width)
            if 0 < diff and diff < distance then
                g.width = g.width + diff
            end
        end
        if sfind(origin, "top", nil, true) then
            local diff = g.y - (og.y + og.height)
            if 0 < diff and diff < distance then
                g.y = g.y - diff
                g.height = g.height + diff
            end
        elseif sfind(origin, "bottom", nil, true) then
            local diff = og.y - (g.y + g.height)
            if 0 < diff and diff < distance then
                g.height = g.height + diff
            end
        end
        return g
    end

    ---Snap a client to the closest client or screen edge.
    ---@param client? client # The client to snap. Default: `client.focus`
    ---@param geo? geometry # The geometry.
    ---@param origin? edge|corner
    ---@return geometry|nil # The new geometry.
    function M.resize(client, geo, origin)
        client = client or capi.client.focus
        if not client then
            return
        end
        if not origin then
            return
        end

        local original_geo = geo or client:geometry()

        local distance = beautiful.snap.distance or 10
        local gap = uui.new(beautiful.snap.gap or 5)

        geo = fix_client_geometry(ugeometry.inflate, client, original_geo, gap)

        geo = snap_inside(geo, ugeometry.shrink(client.screen.geometry, gap), distance, origin)
        geo = snap_inside(geo, ugeometry.shrink(client.screen.tiling_area, gap), distance, origin)

        for _, other in ipairs(aclient.visible(client.screen)) do
            if other ~= client then
                local other_geo = fix_client_geometry(ugeometry.inflate, other, other:geometry(), gap)
                geo = snap_inside(geo, other_geo, distance, origin)
                geo = snap_outside(geo, other_geo, distance, origin)
            end
        end

        geo = fix_client_geometry(ugeometry.shrink, client, geo, gap)

        return geo
    end
end

return M
