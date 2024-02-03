return {
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
