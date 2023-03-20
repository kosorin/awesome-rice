local beautiful = require("beautiful")
local pretty = require("theme.pretty")
local theme = require("theme.theme")
local desktop_utils = require("services.desktop")

local manager = {}

function manager.initialize()
    beautiful.init(pretty(theme))
    desktop_utils.icon_theme = theme.icon_theme
end

return manager
