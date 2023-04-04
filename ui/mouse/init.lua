local amouse = require("awful.mouse")
local amresize = require("awful.mouse.resize")

amouse.drag_to_tag.enabled = false

local M = {
    edge_snap = require("ui.mouse.edge_snap"),
    snap = require("ui.mouse.snap"),
}

amresize.add_move_callback(function(client, geo, args)
    M.edge_snap.detect(client)
    return M.snap.move(client, M.edge_snap.try_restore(client) or geo)
end, "mouse.move")

amresize.add_leave_callback(function(client, geo, args)
    return M.edge_snap.apply(client, args)
end, "mouse.move")

amresize.add_move_callback(function(client, geo, args)
    return M.snap.resize(client, geo, args.corner)
end, "mouse.resize")

return M
