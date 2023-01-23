-- DEPENDENCIES: maim, xdotool, xclip, date

local table = table
local awful = require("awful")
local config = require("config")
local beautiful = require("beautiful")
local gtable = require("gears.table")
local gcolor = require("gears.color")


local screenshot = {}

function screenshot.take(args)
    args = args or {}

    local format = "png"

    local command = "maim --quiet --hidecursor --format " .. format .. " "

    if args.delay then
        command = command .. "--delay \"" .. tostring(args.delay) .. "\" "
    end

    if args.mode == "selection" then
        local channels = table.pack(gcolor.parse_color(beautiful.screenshot_area_color))
        command = command
            .. "-s --highlight --bordersize 2 --color "
            .. table.concat(gtable.map(
                function(channel)
                    return string.sub(tostring(channel), 1, 5)
                end, channels), ",")
            .. " "
    elseif args.mode == "window" then
        command = command .. "--window \""
            .. (args.window and tostring(args.window) or "$(xdotool getactivewindow)")
            .. "\" "
    else
        if args.display then
            command = command .. "--xdisplay \"" .. args.display .. "\" "
        end
    end

    if args.output == "clipboard" then
        command = command .. "| xclip -selection clipboard -t image/" .. format
    else
        command = command .. "\""
            .. (args.output or (config.places.screenshots .. "/$(date '+%y%m%d-%H%M-%S')." .. format))
            .. "\""
    end

    awful.spawn.with_shell(command)
end

return screenshot
