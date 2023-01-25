-- DEPENDENCIES (feature flag "screenshot_tools"): maim, xdotool, xclip, date

local config = require("config")
if not config.features.screenshot_tools then
    return
end

local table = table
local string = string
local awful = require("awful")
local beautiful = require("beautiful")
local gtable = require("gears.table")
local gcolor = require("gears.color")


local screenshot = {}

local function parse_color(color)
    local channels = table.pack(gcolor.parse_color(color))
    return table.concat(gtable.map(
        function(channel)
            return string.sub(tostring(channel), 1, 5)
        end, channels), ",")
end

function screenshot.take(args)
    args = args or {}

    args.format = args.format or "png"

    local command = "maim --quiet --hidecursor --format " .. args.format

    if args.delay then
        command = string.format("%s --delay %.0f", command, args.delay)
    end

    if args.mode == "selection" then
        command = string.format("%s --select --highlight --bordersize %.0f --color %s", command,
            beautiful.screenshot_area_border_width,
            parse_color(beautiful.screenshot_area_color))
    elseif args.mode == "window" then
        command = string.format("%s --window %s", command, args.window or "$(xdotool getactivewindow)")
    elseif args.display then
        command = string.format("%s --xdisplay %s", command, args.display)
    end

    if args.output == "clipboard" then
        command = string.format("%s | xclip -selection clipboard -t image/%s", command, args.format)
    elseif args.output then
        command = string.format("%s \"%s\"", command, args.output)
    else
        local file_name = "$(date '+%y%m%d-%H%M-%S')"
        command = string.format("%s \"%s/%s.%s\"", command, config.places.screenshots, file_name, args.format)
    end

    awful.spawn.with_shell(command)
end

return screenshot
