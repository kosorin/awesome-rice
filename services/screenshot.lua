-- DEPENDENCIES (feature flag "screenshot_tools"): maim, xclip, xdotool, date

local config = require("config")
if not config.features.screenshot_tools then
    return
end

local format = string.format
local awful = require("awful")
local beautiful = require("theme.theme")
local tcolor = require("utils.color")


local screenshot = {}

function screenshot.take(args)
    args = args or {}

    args.format = args.format or "png"

    local command = "maim --quiet --hidecursor --format " .. args.format

    if args.delay then
        command = format("%s --delay %.0f", command, args.delay)
    end

    if args.shader then
        command = format("%s --shader %s", command, args.shader)
    end

    if args.mode == "selection" then
        command = format("%s --select --highlight --bordersize %.0f --color %s", command,
            beautiful.screen_selection_border_width,
            tcolor.format_slop(beautiful.screen_selection_color))
    elseif args.mode == "window" then
        command = format("%s --window %s", command, args.window or "$(xdotool getactivewindow)")
    elseif args.display then
        command = format("%s --xdisplay %s", command, args.display)
    end

    if args.output == "clipboard" then
        command = format("%s | xclip -selection clipboard -t image/%s", command, args.format)
    elseif args.output then
        command = format("%s \"%s\"", command, args.output)
    else
        local file_name = "$(date '+%y%m%d-%H%M-%S')"
        command = format("%s \"%s/%s.%s\"", command, config.places.screenshots, file_name, args.format)
    end

    awful.spawn.with_shell(command)
end

return screenshot
