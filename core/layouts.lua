local capi = Capi
local ipairs = ipairs
local awful = require("awful")
local suit = require("awful.layout.suit")
local tilted = require("layouts.tilted")


local layouts = {
    default = setmetatable({
        tilted.new("tiling"),
        suit.floating,
        suit.max,
        suit.max.fullscreen,
    }, {
        __index = function(t, k)
            if type(k) == "string" then
                for _, layout in ipairs(t) do
                    if layout.name == k then
                        return layout
                    end
                end
            end
        end,
    }),
}

capi.tag.connect_signal("request::default_layouts", function()
    awful.layout.append_default_layouts(layouts.default)
end)

return layouts
