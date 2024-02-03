local core_tag = require("core.tag")

return {
    {
        rule = {
            class = "^Xephyr$",
        },
        properties = {
            floating = false,
            switch_to_tags = true,
            new_tag = core_tag.build {
                name = "Xephyr",
                volatile = true,
                selected = true,
            },
        },
    },
}
