local awful = require("awful")
local beautiful = require("theme.theme")

return {
    {
        rule = {
            class = "^Protonvpn$",
        },
        properties = {
            titlebars_enabled = false,
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
