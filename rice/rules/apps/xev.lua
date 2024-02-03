local awful = require("awful")
local beautiful = require("theme.theme")

return {
    {
        rule = {
            name = "^Event Tester$",
        },
        properties = {
            titlebars_enabled = "toolbox",
            floating = true,
            ontop = true,
            sticky = true,
            placement = function(client)
                awful.placement.bottom_left(client, {
                    honor_workarea = true,
                    margins = beautiful.edge_gap,
                })
            end,
        },
    },
}
