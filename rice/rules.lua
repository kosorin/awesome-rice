local awful = require("awful")
local ruled = require("ruled")
local beautiful = require("theme.theme")
local core_tag = require("core.tag")


---@class Rice.Rules
local rules = {}

ruled.client.connect_signal("request::rules", function()
    ----------------------------------------------------------------------------------------------------
    ruled.client.append_rules {
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
    ----------------------------------------------------------------------------------------------------
    ruled.client.append_rules {
        {
            rule = {
                class = "SpeedCrunch",
            },
            properties = {
                floating = true,
                ontop = true,
                titlebars_enabled = true,
            },
        },
    }
    ----------------------------------------------------------------------------------------------------
    ruled.client.append_rules {
        {
            rule = {
                class = "^1Password$",
            },
            properties = {
                floating = true,
                titlebars_enabled = true,
            },
        },
        {
            rule = {
                class = "^1Password$",
                name = "Quick Access",
            },
            properties = {
                skip_taskbar = true,
                titlebars_enabled = "toolbox",
            },
        },
    }
    ----------------------------------------------------------------------------------------------------
    ruled.client.append_rules {
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
    ----------------------------------------------------------------------------------------------------
    ruled.client.append_rules {
        {
            rule = {
                class = "Dragon-drop",
            },
            properties = {
                floating = true,
                ontop = true,
                sticky = true,
                placement = awful.placement.centered,
                titlebars_enabled = "toolbox",
                border_color = beautiful.common.secondary_bright,
            },
        },
    }
    ----------------------------------------------------------------------------------------------------
    ruled.client.append_rules {
        {
            rule = {
                class = "^Xephyr$",
            },
            properties = {
                floating = false,
                switch_to_tags = true,
                new_tag = core_tag.build {
                    selected = true,
                    volatile = true,
                },
            },
        },
    }
    ----------------------------------------------------------------------------------------------------
    ruled.client.append_rules {
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
    ----------------------------------------------------------------------------------------------------
end)

return rules
