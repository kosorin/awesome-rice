local naughty = require("naughty")


local M = {}

naughty.connect_signal("request::display_error", function(message, startup)
    naughty.notification {
        urgency = "critical",
        title = "Oops, an error happened" .. (startup and " during startup!" or "!"),
        message = message,
    }
end)

return M
