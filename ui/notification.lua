local awful = require("awful")
local naughty = require("naughty")
local ruled = require("ruled")
local beautiful = require("beautiful")
local dpi = Dpi


naughty.connect_signal("request::display_error", function(message, startup)
    naughty.notification {
        urgency = "critical",
        title   = "Oops, an error happened" .. (startup and " during startup!" or "!"),
        message = message,
    }
end)

naughty.connect_signal("request::display", function(n)
    naughty.layout.box { notification = n }
end)


ruled.notification.connect_signal('request::rules', function()
    ruled.notification.append_rule {
        rule = {},
        properties = {
            screen = awful.screen.preferred,
            max_width = dpi(400),
        }
    }
    ruled.notification.append_rule {
        rule = { urgency = "low" },
        properties = {
            implicit_timeout = 10,
            bg = beautiful.palette.gray_66,
            fg = beautiful.palette.white_bright,
            border_color = beautiful.palette.gray_bright,
        }
    }
    ruled.notification.append_rule {
        rule = { urgency = "normal" },
        properties = {
            implicit_timeout = 30,
            bg = beautiful.palette.blue_66,
            fg = beautiful.palette.white_bright,
            border_color = beautiful.palette.blue_bright_150,
        }
    }
    ruled.notification.append_rule {
        rule = { urgency = "critical" },
        properties = {
            never_timeout = true,
            bg = beautiful.palette.red_66,
            fg = beautiful.palette.white_bright,
            border_color = beautiful.palette.red_bright_150,
        }
    }
end)
