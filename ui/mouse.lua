local awful = require("awful")
local dpi = dpi


local distance = dpi(16)

awful.mouse.snap.edge_enabled = true
awful.mouse.snap.aerosnap_distance = distance

awful.mouse.snap.client_enabled = true
awful.mouse.snap.default_distance = distance

awful.mouse.drag_to_tag.enabled = false
