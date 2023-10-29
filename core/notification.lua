local naughty = require("naughty")
local selection = require("core.selection")


local M = {}

naughty.connect_signal("request::display_error", function(message, startup)
    local copy_action = naughty.action {
        name = "Copy message",
    }

    copy_action:connect_signal("invoked", function()
        selection.clipboard:copy(message)
    end)

    naughty.notification {
        urgency = "critical",
        title = "Oops, an error happened" .. (startup and " during startup!" or "!"),
        message = message,
        actions = { copy_action },
    }
end)

return M
