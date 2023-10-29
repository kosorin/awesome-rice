local capi = Capi
local pairs = pairs
local core = require("core")
local layouts = require("rice.layouts")


local tags = {
    list = {
        "1",
        "2",
        "3",
        "4",
        "5",
        "6",
        "7",
        "8",
        "9",
    },
}

capi.awesome.connect_signal("tag::build", function(tag)
    tag.layout = layouts.list[1]
    tag.gap_single_client = false
    tag.master_fill_policy = "master_width_factor"
    tag.master_width_factor = 0.6
end)

capi.screen.connect_signal("request::desktop_decoration", function(screen)
    for index, name in pairs(tags.list) do
        core.tag.add {
            name = name,
            screen = screen,
            selected = index == 1,
        }
    end
end)

return tags
