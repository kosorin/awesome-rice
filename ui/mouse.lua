local awful = require("awful")
local beautiful = require("theme.theme")


awful.mouse.snap.edge_enabled = true
awful.mouse.snap.aerosnap_distance = beautiful.snap.edge.distance

awful.mouse.snap.client_enabled = true
awful.mouse.snap.default_distance = beautiful.snap.distance

awful.mouse.drag_to_tag.enabled = false
