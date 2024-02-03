local awful = require("awful")
local beautiful = require("theme.theme")
local core_rule = require("core.rule")

return {
    {
        rule = {
            name = "^JetBrains Toolbox$",
        },
        properties = {
            floating = true,
            titlebars_enabled = "toolbox",
        },
        callback = core_rule.delayed_callback(function(client)
            awful.placement.top_right(client, {
                honor_workarea = true,
                honor_padding = false,
                margins = beautiful.popup.margins,
            })
        end),
    },
    {
        rule_every = {
            class = {
                "jetbrains-rider",
                "jetbrains-rustrover",
            },
            name = {
                "^Welcome to JetBrains Rider$",
                "^Welcome to RustRover$",
            },
        },
        properties = {
            floating = false,
            titlebars_enabled = true,
        },
    },
    {
        rule_every = {
            class = {
                "jetbrains-rider",
                "jetbrains-rustrover",
            },
            name = { "^splash$" },
        },
        properties = {
            skip_taskbar = true,
            floating = true,
            titlebars_enabled = false,
            placement = awful.placement.centered,
        },
    },
    {
        rule_every = {
            class = {
                "jetbrains-rider",
                "jetbrains-rustrover",
            },
            name = {
                "^ $",
                " – ",
            },
        },
        properties = {
            shape = false,
            titlebars_enabled = false,
        },
    },
}
