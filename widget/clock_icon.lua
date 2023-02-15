local math = math
local string = string
local css = require("utils.css")


local clock_icon = {}

local svg_pattern = [[<svg viewBox="0 0 1 1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
<mask id="mask">
    <rect x="0" y="0" width="100%%" height="100%%" fill="white" />
    <line x1="0.5" y1="0.5" x2="%.2f" y2="%.2f" stroke-width="0.1" stroke-linecap="round" stroke="black" />
    <line x1="0.5" y1="0.5" x2="%.2f" y2="%.2f" stroke-width="0.1" stroke-linecap="round" stroke="black" />
</mask>
<circle mask="url(#mask)" cx="0.5" cy="0.5" r="0.425" />
</svg>]]

local hour_hand_size = 0.45
local minute_hand_size = 0.7

local function fix_hand_position(value, size)
    return 0.5 + 0.5 * (value * size)
end

local function get_hand_x(value, size)
    return fix_hand_position(math.sin(value), size)
end

local function get_hand_y(value, size)
    return fix_hand_position(-math.cos(value), size)
end

function clock_icon.generate_svg(hours, minutes)
    if not hours or not minutes then
        local date = os.date("*t")
        hours = date.hour
        minutes = date.min
    end
    hours = math.floor(tonumber(hours) or 0)
    minutes = math.floor(tonumber(minutes) or 0)

    local hour = (((hours + (minutes / 60)) % 12) / 12) * 2 * math.pi
    local minute = (minutes / 60) * 2 * math.pi
    return string.format(svg_pattern,
        get_hand_x(hour, hour_hand_size), get_hand_y(hour, hour_hand_size),
        get_hand_x(minute, minute_hand_size), get_hand_y(minute, minute_hand_size))
end

function clock_icon.generate_style(color)
    return css.style { circle = { fill = color } }
end

return clock_icon
