return {
    {
        rule = {
            class = "^Xephyr$",
        },
        properties = {
            floating = false,
            switch_to_tags = true,
            new_tag = {
                name = "Xephyr",
                volatile = true,
                selected = true,
            },
        },
    },
}
