-- DEPENDENCIES (feature flag "magnifier_tools"): slop, xclip

local config = require("rice.config")
if not config.features.magnifier_tools then
    return
end

local format = string.format
local awful = require("awful")
local beautiful = require("theme.theme")
local tcolor = require("utils.color")


local magnifier = {}

function magnifier.run(args)
    args = args or {}

    local command = "slop --quiet --tolerance 0"
    command = format("%s --tolerance %.0f", command, args.tolerance or 0)
    command = format("%s --highlight --bordersize %.0f --color %s", command,
        beautiful.screen_selection_border_width,
        tcolor.format_slop(beautiful.screen_selection_color))

    if args.shader ~= false then
        command = format("%s --shader %s", command, args.shader or "boxzoom")
    end

    if args.format then
        command = format("%s --format %s", command, args.format)
    end

    command = format("%s | xclip -rmlastnl -selection clipboard", command)

    awful.spawn.with_shell(command)
end

return magnifier
