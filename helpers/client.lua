local capi = {
    mouse = mouse,
}
local sqrt = math.sqrt
local sort = table.sort


local client_helper = {}

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
        return sqrt(x * x + y * y)
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

return client_helper
