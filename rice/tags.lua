local capi = Capi
local pairs = pairs
local awful = require("awful")
local core_tag = require("core.tag")
local layouts = require("rice.layouts")


---@class Rice.Tags
---@field names string[] # List of default tag names for each screen
local tags = {
    names = {
        "Main",
    },
}

capi.awesome.connect_signal("tag::build", function(tag, args)
    tag.layout = layouts.list[1]
    tag.gap_single_client = false
    tag.master_fill_policy = "master_width_factor"
    tag.master_width_factor = 0.7
    tag.volatile = true
end)

capi.screen.connect_signal("request::desktop_decoration", function(screen)
    for index, name in pairs(tags.names) do
        awful.tag.add(nil, core_tag.build {
            name = name,
            screen = screen,
            selected = index == 1,
            volatile = false,
        })
    end
end)

return tags
