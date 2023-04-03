local awful = require("awful")

awful.mouse.drag_to_tag.enabled = false

-- Order matters
require("ui.mouse.edge_snap")
require("ui.mouse.snap")
