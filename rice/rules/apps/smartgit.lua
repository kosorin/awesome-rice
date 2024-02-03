return {
    {
        rule = {
            class = "^SmartGit$",
        },
        properties = {
            workspace = "git",
            shape = false,
            titlebars_enabled = "toolbox",
        },
    },
    {
        rule = {
            class = "^SmartGit$",
            name = "SmartGit %d+(%.%d+)+?%s*$",
        },
        properties = {
            titlebars_enabled = false,
        },
    },
}
