local capi = Capi
local pairs = pairs
local awful = require("awful")
local core_tag = require("core.tag")
local layouts = require("rice.layouts")


---@class Rice.Tags
---@field names string[] # List of default tag names for each screen
local tags = {
    names = {
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

capi.awesome.connect_signal("tag::build", function(tag, args)
    tag.layout = layouts.list[1]
    tag.gap_single_client = false
    tag.master_fill_policy = "master_width_factor"
    tag.master_width_factor = 0.6
end)

capi.screen.connect_signal("request::desktop_decoration", function(screen)
    for index, name in pairs(tags.names) do
        awful.tag.add(name, core_tag.build {
            name = name,
            screen = screen,
            selected = index == 1,
        })
    end
end)

return tags
