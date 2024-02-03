local core_tag = require("core.tag")

return {
    {
        rule = {
            class = "^FreeTube$",
        },
        properties = {
            new_tag = core_tag.build {
                name = "FreeTube",
                volatile = true,
            },
        },
    },
}
