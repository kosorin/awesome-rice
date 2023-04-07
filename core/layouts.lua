local capi = Capi
local awful = require("awful")
local suit = require("awful.layout.suit")
local tilted = require("layouts.tilted")


local layouts = {
    default = {
        tile = tilted.new("tile"),
        floating = suit.floating,
        max = suit.max,
        fullscreen = suit.max.fullscreen,
    },
    name = {
        tile = "Tiling",
        floating = "Floating",
        max = "Maximize",
        fullscreen = "Fullscreen",
    },
}

capi.tag.connect_signal("request::default_layouts", function()
    awful.layout.append_default_layouts {
        layouts.default.tile,
        layouts.default.floating,
        layouts.default.max,
        layouts.default.fullscreen,
    }
end)

return layouts
