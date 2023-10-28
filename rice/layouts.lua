local core_layout = require("core.layout")
local suit = require("awful.layout.suit")
local tilted = require("layouts.tilted")


local layouts = {
    default = core_layout.list {
        tilted.new("tiling"),
        suit.floating,
        suit.max,
        suit.max.fullscreen,
    },
}

return layouts
