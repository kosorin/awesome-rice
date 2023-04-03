local capi = Capi
local ipairs = ipairs
local math = math
local aclient = require("awful.client")
local alayout = require("awful.layout")
local mresize = require("awful.mouse.resize")
local aplacement = require("awful.placement")
local grectangle = require("gears.geometry").rectangle


local directions = {
    left = { x = -1, y = 0 },
    right = { x = 1, y = 0 },
    up = { x = 0, y = -1 },
    down = { x = 0, y = 1 },
}


local M = {
    resize_corner_size = 50,
    resize_max_distance = 20,
    floating_move_step = 50,
    tiled_resize_factor = 0.02,
}

function M.is_floating(client)
    if not client then
        return nil
    end

    if client.floating then
        return true
    end

    local screen = client.screen
    if not screen then
        return nil
    end

    local tag = screen.selected_tag
    if not tag then
        return nil
    end

    return tag.layout == alayout.suit.floating
end

local resize_quadrants = {
    horizontal = {
        [1] = { primary = "top", secondary = "right" },
        [2] = { primary = "top", secondary = "left" },
        [3] = { primary = "bottom", secondary = "left" },
        [4] = { primary = "bottom", secondary = "right" },
    },
    vertical = {
        [1] = { primary = "right", secondary = "top" },
        [2] = { primary = "left", secondary = "top" },
        [3] = { primary = "left", secondary = "bottom" },
        [4] = { primary = "right", secondary = "bottom" },
    },
}

function M.get_resize_corner(client, coords)
    local g = client:geometry()
    g.width = g.width + 2 * client.border_width
    g.height = g.height + 2 * client.border_width

    local horizontal, vertical
    local dx, dy

    local corner_size = math.min(M.resize_corner_size, math.min(g.width, g.height) / 2)
    if coords.x <= g.x + corner_size then
        horizontal = "left"
    elseif g.x + g.width - corner_size < coords.x then
        horizontal = "right"
    else
        dx = (coords.x - g.x) - (g.width / 2)
    end

    if coords.y < g.y + corner_size then
        vertical = "top"
    elseif g.y + g.height - corner_size < coords.y then
        vertical = "bottom"
    else
        dy = (coords.y - g.y) - (g.height / 2)
    end

    local corner
    if horizontal and vertical then
        corner = vertical .. "_" .. horizontal
    elseif vertical then
        corner = vertical
    elseif horizontal then
        corner = horizontal
    else
        local x, y, w, h, quadrant
        local q = dy < 0
            and (dx < 0 and 2 or 1)
            or (dx < 0 and 3 or 4)
        if g.width > g.height then
            x, y = dx, dy
            w, h = g.width, g.height
            quadrant = resize_quadrants.horizontal[q]
        else
            x, y = dy, dx
            w, h = g.height, g.width
            quadrant = resize_quadrants.vertical[q]
        end
        corner = 2 * (math.abs(x) - math.abs(y)) <= w - h
            and quadrant.primary
            or quadrant.secondary
    end
    return corner
end

function M.get_distance(client, coords)
    local x, y

    local g = client:geometry()
    g.width = g.width + 2 * client.border_width
    g.height = g.height + 2 * client.border_width

    if g.x > coords.x then
        x = g.x - coords.x
    elseif g.x + g.width < coords.x then
        x = coords.x - (g.x + g.width)
    end

    if g.y > coords.y then
        y = g.y - coords.y
    elseif g.y + g.height < coords.y then
        y = coords.y - (g.y + g.height)
    end

    local distance
    if x and y then
        distance = math.sqrt(x * x + y * y)
    elseif x then
        distance = x
    elseif y then
        distance = y
    else
        distance = 0
    end
    return distance
end

function M.find_closest(args)
    args = args or {}
    local clients = args.clients or (capi.mouse.screen and capi.mouse.screen.clients)
    local client_count = clients and #clients or 0
    if client_count == 0 then
        return
    end

    local coords = args.coords or capi.mouse.coords()

    local closest_client
    local closest_distance = math.maxinteger
    for i = 1, client_count do
        local client = clients[i]
        local distance = M.get_distance(client, coords)
        if distance == 0 then
            closest_client = client
            closest_distance = distance
            break
        end
        if not args.max_distance or distance <= args.max_distance then
            if distance < closest_distance then
                closest_client = client
                closest_distance = distance
            end
        end
    end
    return closest_client, closest_distance
end

local function move_floating(client, direction)
    if not client or client.immobilized_horizontal or client.immobilized_vertical then
        return
    end

    local rc = directions[direction]
    if not rc then
        return
    end

    client:relative_move(
        client.immobilized_horizontal and 0 or (rc.x * M.floating_move_step),
        client.immobilized_vertical and 0 or (rc.y * M.floating_move_step),
        0, 0)
end

local function resize_floating(client, direction)
    if not client or client.immobilized_horizontal or client.immobilized_vertical then
        return
    end

    local rc = directions[direction]
    if not rc then
        return
    end

    client:relative_move(0, 0,
        client.immobilized_horizontal and 0 or (rc.x * M.floating_move_step),
        client.immobilized_vertical and 0 or (rc.y * M.floating_move_step))
end

local function move_tiled(client, direction)
    if not client or not client.screen then
        return
    end

    local clients = aclient.tiled(client.screen)
    local geometries = {}
    for i, c in ipairs(clients) do
        geometries[i] = c:geometry()
    end
    local target_client = grectangle.get_in_direction(direction, geometries, client:geometry())
    if target_client then
        clients[target_client]:swap(client)
    else
        local target_screen = client.screen:get_next_in_direction(direction)
        if target_screen then
            client.screen = target_screen
            client:activate { context = "move_to_screen" }
        end
    end
end

local function resize_descriptor(descriptor, parent_descriptor, resize_factor)
    resize_factor = resize_factor * M.tiled_resize_factor
    if resize_factor == 0 then
        return
    end
    for _, cd in ipairs(parent_descriptor) do
        local sign = cd ~= descriptor and -1 or 1
        cd.factor = math.min(math.max(cd.factor + sign * resize_factor, 0), 1)
    end
end

local function resize_tiled(client, direction)
    local screen = client and client.screen and capi.screen[client.screen]
    local tag = screen and screen.selected_tag
    local layout = tag and tag.layout
    if not layout.is_tilted then
        return
    end

    local layout_descriptor = tag.tilted_layout_descriptor
    if not layout_descriptor then
        return
    end

    local rc = directions[direction]
    if not rc then
        return
    end

    local clients = aclient.tiled(screen)
    local column_descriptor, item_descriptor = layout_descriptor:find_client(client, clients)

    if column_descriptor then
        resize_descriptor(column_descriptor, layout_descriptor, layout.is_horizontal and rc.x or -rc.y)
    end
    if item_descriptor then
        resize_descriptor(item_descriptor, column_descriptor, layout.is_horizontal and -rc.y or rc.x)
    end

    tag:emit_signal("property::tilted_layout_descriptor")
end

function M.move(client, direction)
    if M.is_floating(client) then
        move_floating(client, direction)
    else
        move_tiled(client, direction)
    end
end

function M.resize(client, direction)
    if M.is_floating(client) then
        resize_floating(client, direction)
    else
        resize_tiled(client, direction)
    end
end

function M.mouse_move(client)
    if not client
        or client.fullscreen
        or client.maximized
        or client.type == "desktop"
        or client.type == "splash"
        or client.type == "dock" then
        return
    end

    local mouse_coords = capi.mouse.coords()
    local geometry = client:geometry()
    local bw = client.border_width

    local relative_offset = {
        x = geometry.width < 1 and 0 or ((mouse_coords.x - geometry.x) / (geometry.width + 2 * bw)),
        y = geometry.height < 1 and 0 or ((mouse_coords.y - geometry.y) / (geometry.height + 2 * bw)),
    }

    mresize(client, "mouse.move", {
        placement = aplacement.client_move,
        relative_offset = relative_offset,
    })
end

function M.mouse_resize(client)
    if client == true then
        client = M.find_closest {
            max_distance = M.resize_max_distance,
        }
    end

    if not client
        or client.fullscreen
        or client.maximized
        or (client.immobilized_horizontal and client.immobilized_vertical)
        or client.type == "desktop"
        or client.type == "splash"
        or client.type == "dock" then
        return
    end

    local axis
    if client.immobilized_horizontal and client.immobilized_vertical then
        axis = "none"
    elseif client.immobilized_horizontal then
        axis = "vertical"
    elseif client.immobilized_vertical then
        axis = "horizontal"
    end

    local coords = capi.mouse.coords()
    local corner = M.get_resize_corner(client, coords)

    mresize(client, "mouse.resize", {
        placement = aplacement.resize_to_mouse,
        corner = corner,
        include_sides = true,
        axis = axis,
    })
end

return M
