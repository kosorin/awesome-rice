local awful = require("awful")
local beautiful = require("theme.theme")

return {
    {
        rule = {
            class = "^Localsend$",
        },
        properties = {
            titlebars_enabled = "toolbox",
            floating = true,
            ontop = true,
            sticky = true,
            placement = function(client)
                awful.placement.top_right(client, {
                    honor_workarea = true,
                    margins = beautiful.popup.margins,
                })
            end,
        },
    },
}
