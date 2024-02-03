return {
    {
        rule = {
            class = "^ArenaTracker$",
        },
        properties = {
            ontop = true,
            titlebars_enabled = false,
            border_width = true,
        },
    },
    {
        rule = {
            class = "^battle.net.exe$",
        },
        properties = {
            ontop = true,
            titlebars_enabled = true,
        },
    },
    {
        rule = {
            class = "^hearthstone.exe$",
        },
        properties = {
            ontop = false,
            titlebars_enabled = false,
        },
    },
    {
        rule_any = {
            class = {
                "^ArenaTracker$",
                "^battle.net.exe$",
                "^hearthstone.exe$",
            },
        },
        properties = {
            workspace = "hearthstone",
            floating = true,
            shape = false,
        },
    },
}
