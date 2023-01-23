-- Global variables, only as shorthands
-- In other files define local variables, for example `local dpi = dpi`

local gdebug = require("gears.debug")
local notification = require("naughty.notification")

dump = DEBUG and gdebug.dump or function(data, tag, depth)
    notification {
        title = "<TUMP>",
        text = gdebug.dump_return(data, tag, depth),
        timeout = 0,
    }
end

dpi = require("beautiful.xresources").apply_dpi

function span(text, foreground, background, args)
    local s = "<span "
    if background then
        s = s .. "background='" .. background .. "' "
    end
    if foreground then
        s = s .. "foreground='" .. foreground .. "' "
    end
    if args then
        for k, v in pairs(args) do
            s = s .. k .. "='" .. v .. "' "
        end
    end
    return s .. ">" .. text .. "</span>"
end
