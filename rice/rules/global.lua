local awful = require("awful")
local beautiful = require("theme.theme")

return {
    {
        id = "global",
        rule = {},
        properties = {
            screen = awful.screen.preferred,
            focus = awful.client.focus.filter,
            titlebars_enabled = DEBUG,
            raise = true,
            shape = beautiful.client.shape,
        },
        callback = function(client)
            awful.client.setslave(client)
        end,
    },
    {
        id = "tools",
        rule_any = {
            floating = true,
            type = "dialog",
        },
        properties = {
            floating = true,
            titlebars_enabled = "toolbox",
        },
    },
    {
        id = "floating",
        rule_any = {
            class = {
                "Arandr",
            },
            role = {
                "pop-up",
            },
        },
        properties = {
            floating = true,
            titlebars_enabled = true,
        },
    },
    {
        id = "picture_in_picture",
        rule_any = {
            name = {
                "Picture in picture",
                "Picture-in-Picture",
            },
        },
        properties = {
            titlebars_enabled = "toolbox",
            floating = true,
            ontop = true,
            sticky = true,
            placement = function(client)
                awful.placement.bottom_right(client, {
                    honor_workarea = true,
                    margins = beautiful.edge_gap,
                })
            end,
        },
    },
    {
        id = "no_size_hints",
        rule_any = {
            class = {
                "XTerm",
            },
        },
        properties = {
            size_hints_honor = false,
        },
    },
    {
        id = "urgent",
        rule_any = {
            class = {
                "^Gcr-prompter$",
            },
            name = {
                "^Authenticate$",
            },
        },
        properties = {
            floating = true,
            ontop = true,
            sticky = true,
            titlebars_enabled = "toolbox",
            placement = awful.placement.centered,
        },
    },
}
