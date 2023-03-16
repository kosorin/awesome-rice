if not DEBUG then
    return
end

local capi = Capi
local awful = require("awful")
local beautiful = require("theme.theme")
local wibox = require("wibox")


capi.screen.connect_signal("request::wallpaper", function(screen)
    awful.wallpaper {
        screen = screen,
        widget = {
            widget = wibox.container.background,
            bg = {
                type = "linear",
                from = { 0, 0 },
                to = { 0, screen.geometry.height },
                stops = {
                    { 0, beautiful.palette.blue_25 },
                    { 1, beautiful.palette.yellow_25 },
                },
            },
        },
    }
end)
