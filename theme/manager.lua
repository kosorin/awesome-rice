local beautiful = require("beautiful")
local pretty = require("theme.pretty")
local theme = require("theme.theme")


local manager = {}

function manager.initialize()
    beautiful.init(pretty(theme))
end

return manager
