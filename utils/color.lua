local rawset = rawset
local tonumber = tonumber
local math = math
local string = string
local gcolor = require("gears.color")
local gdebug = require("gears.debug")


local M = {
    black = "#000000",
    white = "#FFFFFF",
    transparent = "#00000000",
    unknown = "#FFFF00", -- Something bright, easy to spot
}

function M.change(value, args)
    if not args then
        return value or M.black
    end

    local r, g, b, a = gcolor.parse_color(value)
    if r == nil then
        return M.black
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
        return math.floor(channel < 0 and 0 or (channel > 255 and 255 or channel))
    end

    r = get_channel_value(r)
    g = get_channel_value(g)
    b = get_channel_value(b)
    a = get_channel_value(a)

    if a < 255 then
        return string.format("#%02x%02x%02x%02x", r, g, b, a)
    else
        return string.format("#%02x%02x%02x", r, g, b)
    end
end

M.palette_metatable = {}

function M.palette_metatable.__index(t, k)
    local name, value = string.match(k, "^([_%a]+)_(%d+)$")
    if not name then
        gdebug.print_warning("Unknown color '" .. k .. "'")
        rawset(t, k, M.unknown)
        return M.unknown
    end
    value = (tonumber(value) - 100) / 100
    local source_color = t[name]
    local new_color = M.change(source_color, { lighten = value })

    rawset(t, k, new_color)
    return new_color
end

-- TODO: Move this somewhere else
function M.format_slop(color)
    local r, g, b, a = gcolor.parse_color(color)
    return string.format("%.3f,%.3f,%.3f,%.3f", r, g, b, a)
end

return M
