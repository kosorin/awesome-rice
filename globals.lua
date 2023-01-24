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
