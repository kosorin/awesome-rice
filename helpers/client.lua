local capi = {
    mouse = mouse,
    screen = screen,
}
local ipairs = ipairs
local math = math
local sort = table.sort
local aclient = require("awful.client")
local alayout = require("awful.layout")
local grectangle = require("gears.geometry").rectangle
local tilted_layout_descriptor = require("layouts.tilted.layout_descriptor")


local floating_move_step = 50
local tiled_resize_factor = 0.02

local directions = {
    left = { x = -1, y = 0 },
    right = { x = 1, y = 0 },
    up = { x = 0, y = -1 },
    down = { x = 0, y = 1 },
}


local client_helper = {}

function client_helper.is_floating(client)
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

function client_helper.get_distance(client, coords)
    local x, y

    local g = client:geometry()
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

    if x and y then
        return math.sqrt(x * x + y * y)
    elseif not x then
        return y
    elseif not y then
        return x
    else
        return true
    end
end

function client_helper.find_closest(clients, coords)
    local clients = clients or (capi.mouse.screen and capi.mouse.screen.tiled_clients)
    local client_count = clients and #clients or 0
    if client_count == 0 then
        return
    end

    local coords = coords or capi.mouse.coords()
    local distances = {}
    for i = 1, client_count do
        local client = clients[i]
        local distance = client_helper.get_distance(client, coords)
        if distance == true then
            return client
        end
        distances[i] = { client = client, distance = distance }
    end

    sort(distances, function(a, b) return a.distance < b.distance end)
    return distances[1].client
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
        client.immobilized_horizontal and 0 or (rc.x * floating_move_step),
        client.immobilized_vertical and 0 or (rc.y * floating_move_step),
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
        client.immobilized_horizontal and 0 or (rc.x * floating_move_step),
        client.immobilized_vertical and 0 or (rc.y * floating_move_step))
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
    resize_factor = resize_factor * tiled_resize_factor
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

function client_helper.move(client, direction)
    if client_helper.is_floating(client) then
        move_floating(client, direction)
    else
        move_tiled(client, direction)
    end
end

function client_helper.resize(client, direction)
    if client_helper.is_floating(client) then
        resize_floating(client, direction)
    else
        resize_tiled(client, direction)
    end
end

return client_helper
