local floor = math.floor
local format = string.format
local gcolor = require("gears.color")
local config = require("config")


local color = {
    black = "#000000",
    white = "#FFFFFF",
    transparent = "#00000000",
}

function color.change(value, args)
    if not args then
        return value or color.black
    end

    local r, g, b, a = gcolor.parse_color(value)
    if r == nil then
        return color.black
    end

    if args.lighten then
        if args.lighten > 0 then
            r = r + ((1 - r) * args.lighten)
            g = g + ((1 - g) * args.lighten)
            b = b + ((1 - b) * args.lighten)
        elseif args.lighten < 0 then
            r = r + (r * args.lighten)
            g = g + (g * args.lighten)
            b = b + (b * args.lighten)
        end
    end

    if args.alpha then
        a = args.alpha
    end

    local function get_channel_value(channel)
        channel = channel * 255
        return floor(channel < 0 and 0 or (channel > 255 and 255 or channel))
    end

    r = get_channel_value(r)
    g = get_channel_value(g)
    b = get_channel_value(b)
    a = get_channel_value(a)

    if a < 255 then
        return format("#%02x%02x%02x%02x", r, g, b, a)
    else
        return format("#%02x%02x%02x", r, g, b)
    end
end

if config.features.screenshot_tools or config.features.magnifier_tools then
    function color.format_slop(color)
        local r, g, b, a = gcolor.parse_color(color)
        return string.format("%.3f,%.3f,%.3f,%.3f", r, g, b, a)
    end
end

return color
