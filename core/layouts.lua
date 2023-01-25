local capi = {
    tag = tag,
}
local awful = require("awful")
local suit = require("awful.layout.suit")
local tilted = require("layouts.tilted")


capi.tag.connect_signal("request::default_layouts", function()
    awful.layout.append_default_layouts {
        tilted.right,
        tilted.center,
        suit.floating,
        suit.max,
        suit.max.fullscreen,
    }
end)
