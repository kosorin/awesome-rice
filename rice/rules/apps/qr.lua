local awful = require("awful")

return {
    {
        rule = {
            class = "qr_code_clipboard",
        },
        properties = {
            floating = true,
            ontop = true,
            sticky = true,
            placement = awful.placement.centered,
            titlebars_enabled = "toolbox",
        },
    },
}
