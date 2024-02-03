local core_tag = require("core.tag")

return {
    {
        rule = {
            class = "^Spotify$",
        },
        properties = {
            new_tag = core_tag.build {
                name = "Spotify",
                volatile = true,
            },
        },
    },
}
