local rawset = rawset
local tonumber = tonumber
local math = math
local string = string
local gcolor = require("gears.color")
local gdebug = require("gears.debug")
local config = require("config")


local M = {
    black = "#000000",
    white = "#FFFFFF",
    transparent = "#00000000",
    unknown = "#FFFF00", -- Something bright, easy to spot
}

function M.to_rgb(color)
    return gcolor.parse_color(color)
end

local function rgb_to_hex(r, g, b, a)
    r = math.min(math.max(0, math.floor(0.5 + r * 255), 255))
    g = math.min(math.max(0, math.floor(0.5 + g * 255), 255))
    b = math.min(math.max(0, math.floor(0.5 + b * 255), 255))
    a = math.min(math.max(0, math.floor(0.5 + a * 255), 255))
    if a < 255 then
        return string.format("#%02x%02x%02x%02x", r, g, b, a)
    else
        return string.format("#%02x%02x%02x", r, g, b)
    end
end

function M.to_hsl(color)
    local R, G, B, A = gcolor.parse_color(color)
    if not R then
        return
    end

    local min = math.min(R, G, B)
    local max = math.max(R, G, B)
    local delta = max - min
    local sum = max + min

    local h = 0
    local s = 0
    local l = sum / 2

    if delta > 0 then
        if max > 0 then
            if R == max then
                h = (G - B) / delta
            elseif G == max then
                h = 2 + (B - R) / delta
            else
                h = 4 + (R - G) / delta
            end

            if h < 0 then
                h = h + 6
            end
        end

        if l <= 0.5 then
            s = delta / sum
        else
            s = delta / (2 - sum)
        end
    end

    return h / 6, s, l, A
end

local function hsl_to_rgb_channel(p, q, h)
    if h < 0 then
        h = h + 6
    elseif h > 6 then
        h = h - 6
    end

    if h < 1 then
        return p + (q - p) * h
    elseif h < 3 then
        return q
    elseif h < 4 then
        return p + (q - p) * (4 - h)
    else
        return p
    end
end

local function hsl_to_rgb(H, S, L, A)
    if S == 0 then
        return L, L, L, A
    else
        local q = L <= 0.5
            and L * (1 + S)
            or L + S - L * S
        local p = 2 * L - q
        local h = H * 6

        local r = hsl_to_rgb_channel(p, q, h + 2);
        local g = hsl_to_rgb_channel(p, q, h);
        local b = hsl_to_rgb_channel(p, q, h - 2);
        return r, g, b, A
    end
end

local function hsl_to_hex(h, s, l, a)
    return rgb_to_hex(hsl_to_rgb(h, s, l, a))
end

function M.change_hsl(color, channels)
    local h, s, l, a = M.to_hsl(color)
    if not h then
        return
    end
    channels = channels or {}
    h = h + (tonumber(channels.h) or 0)
    s = s + (tonumber(channels.s) or 0)
    l = l + (tonumber(channels.l) or 0)
    a = a + (tonumber(channels.a) or 0)
    return hsl_to_hex(h, s, l, a)
end

function M.lighten(color, value)
    local h, s, l, a = M.to_hsl(color)
    if not h then
        return
    end
    return hsl_to_hex(h, s, l + (tonumber(value) or 0), a)
end

function M.darken(color, value)
    local h, s, l, a = M.to_hsl(color)
    if not h then
        return
    end
    return hsl_to_hex(h, s, l - (tonumber(value) or 0), a)
end

return M
