local floor = math.floor
local max = math.max
local format = string.format
local concat = table.concat

local humanizer = {
    thin_space = "<span size='xx-small'> </span>",
}

local function round(value) return floor(value + 0.5) end

local function clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

local unknown_cache = {}

local function initialize_units(units)
    units.size = units.size or 1000
    local value = units.size
    for i = 1, #units do
        units[i].value = value
        value = value * units.size
    end
    return units
end

local function humanize_units(units, value, precision, from_unit)
    if not value then
        if not unknown_cache.io_speed then
            unknown_cache.io_speed = format("%s%s%s", units.unknown, humanizer.thin_space,
                units[1].text)
        end
        return unknown_cache.io_speed
    end
    from_unit = from_unit or 1
    for i = 1, #units do
        local unit = units[i]
        if i >= from_unit and value < unit.value then
            return format("%." .. tostring(precision or unit.precision) .. "f%s%s",
                value / (unit.value / units.size),
                humanizer.thin_space,
                unit.text)
        end
    end
    return units.over
end

local io_speed_units = initialize_units {
    unknown = "-",
    over = "it's over 9000!",
    { precision = 0, text = "B/s" },
    { precision = 0, text = "kB/s" },
    { precision = 2, text = "MB/s" },
    { precision = 2, text = "GB/s" },
    { precision = 2, text = "TB/s" },
}

function humanizer.io_speed(bytes, ...)
    return humanize_units(io_speed_units, bytes, ...)
end

local file_size_units = initialize_units {
    unknown = "-",
    over = "it's over 9000!",
    { precision = 0, text = "B" },
    { precision = 1, text = "kB" },
    { precision = 1, text = "MB" },
    { precision = 1, text = "GB" },
    { precision = 1, text = "TB" },
}

function humanizer.file_size(bytes, ...)
    return humanize_units(file_size_units, bytes, ...)
end

local days_in_year = 365.2425
local days_in_month = days_in_year / 12
local weeks_in_month = days_in_month / 7
local time_data = {
    { text = "year", count = nil, div = 60 * 60 * 24 * days_in_month * 12 },
    { text = "month", count = 12, div = 60 * 60 * 24 * days_in_month },
    { text = "week", count = weeks_in_month, div = 60 * 60 * 24 * 7, is_week = true },
    { text = "day", count = days_in_month, div = 60 * 60 * 24 },
    { text = "hour", count = 24, div = 60 * 60 },
    { text = "minute", count = 60, div = 60 },
    { text = "second", count = 60, div = 1 },
}

local function get_time_part(value, unit)
    return tostring(value) .. " "
        .. (value == 1 and unit.text or (unit.text .. "s"))
end

function humanizer.relative_time(seconds, args)
    seconds = round(max(0, seconds))
    args = args or {}

    local available_part_count = #time_data
    local separator = args.separator or " "
    local from_unit = clamp(args.from_unit or 1, 1, available_part_count)
    local part_count = args.part_count or 1
    local skip_week = args.skip_week
    local include_leading_zero = args.skip_leading_zero
    local include_zero = args.include_zero
    local stop_on_zero = args.stop_on_zero == nil and true or args.stop_on_zero
    local single_format = args.single_format

    local parts = {}
    local rest = seconds
    for i = from_unit, available_part_count do
        local unit = time_data[i]
        if not skip_week or not unit.is_week then

            local value = rest / unit.div
            if single_format then
                parts[#parts + 1] = get_time_part(format(single_format, value), unit)
                break
            end

            value = floor(value)
            if value >= 1 then
                rest = rest - (value * unit.div)
                parts[#parts + 1] = get_time_part(value, unit)
            elseif rest == seconds then
                if include_leading_zero then
                    parts[#parts + 1] = get_time_part(0, unit)
                end
            else
                if include_zero then
                    parts[#parts + 1] = get_time_part(0, unit)
                elseif stop_on_zero then
                    break
                end
            end

            if part_count > 0 and part_count == #parts then
                break
            end
        end
    end

    if #parts == 0 then
        parts[1] = get_time_part(0, time_data[clamp(from_unit + max(1, part_count), 1, available_part_count)])
    end

    local text = concat(parts, separator)

    if args.prefix then
        text = args.prefix .. text
    end
    if args.suffix then
        text = text .. args.suffix
    end

    return text
end

return humanizer
