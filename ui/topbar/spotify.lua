local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("theme.theme")
local binding = require("core.binding")
local btn = binding.button
local gears = require("gears")

local spotify_button = wibox.widget {
    {
        {
            id = "icon",
            widget = wibox.widget.imagebox,
            image = beautiful.icon("music.svg"),
        },
        widget = wibox.container.margin,
        margins = 5,
    },
    widget = wibox.container.background,
    bg = "#808080",
    shape = gears.shape.rounded_rect,
    shape_border_width = 1,
    shape_border_color = "#000000",
}

local previous_tag = nil

local function check_spotify_tag()
    local spotify_tag = awful.tag.find_by_name(awful.screen.focused(), "Spotify")
    if spotify_tag and spotify_tag.selected then
        spotify_button.bg = "#1DB954"
    else
        spotify_button.bg = "#808080"
    end
end

tag.connect_signal("property::selected", function()
    check_spotify_tag()
end)

check_spotify_tag()

spotify_button:connect_signal("mouse::enter", function()
    spotify_button.bg = "#1DB954"
end)

spotify_button:connect_signal("mouse::leave", function()
    check_spotify_tag()
end)

spotify_button:buttons(
    binding.awful_buttons {
        binding.awful({}, btn.left, function()
            local spotify_tag = awful.tag.find_by_name(awful.screen.focused(), "Spotify")
            if spotify_tag then
                if spotify_tag.selected then
                    if previous_tag then
                        previous_tag:view_only()
                    end
                else
                    previous_tag = awful.screen.focused().selected_tag
                    spotify_tag:view_only()
                end
            else
                awful.spawn("spotify")
            end
        end),
    }
)

return spotify_button
