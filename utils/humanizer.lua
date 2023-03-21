local type = type
local ipairs = ipairs
local tostring = tostring
local math = math
local table = table
local string = string
local gtable = require("gears.table")
local umath = require("utils.math")


local humanizer = {}

function humanizer.humanize_units(units, value, from_unit)
    if not value then
        if not units.unknown_formatted then
            units.unknown_formatted = string.format("%s%s%s", units.unknown or "--", units.space or " ", units[1].text)
        end
        return units.unknown_formatted
    end
    from_unit = from_unit or 1
    local previous_to = 1
    for i, unit in ipairs(units) do
        if i >= from_unit and value < unit.to then
            return string.format(
                unit.format or units.format or ("%." .. tostring(units.precision or unit.precision or 0) .. "f%s%s"),
                value / previous_to,
                units.space or " ",
                unit.text)
        end
        if unit.next ~= false then
            previous_to = unit.to
        end
    end
    return units.over or "it's over 9000!"
end

humanizer.io_speed_units = {
    { precision = 0, text = "B/s", to = 1000 },
    { precision = 0, text = "kB/s", to = 1000 * 1000 },
    { precision = 2, text = "MB/s", to = 1000 * 1000 * 1000 },
    { precision = 2, text = "GB/s", to = 1000 * 1000 * 1000 * 1000 },
    { precision = 2, text = "TB/s", to = 1000 * 1000 * 1000 * 1000 * 1000 },
}

function humanizer.io_speed(bytes, ...)
    return humanizer.humanize_units(humanizer.io_speed_units, bytes, ...)
end

humanizer.file_size_units = {
    { precision = 0, text = "B", to = 1000 },
    { precision = 1, text = "kB", to = 1000 * 1000 },
    { precision = 1, text = "MB", to = 1000 * 1000 * 1000 },
    { precision = 1, text = "GB", to = 1000 * 1000 * 1000 * 1000 },
    { precision = 1, text = "TB", to = 1000 * 1000 * 1000 * 1000 * 1000 },
}

function humanizer.file_size(bytes, ...)
    return humanizer.humanize_units(humanizer.file_size_units, bytes, ...)
end

do
    local days_in_year = 365.2425
    local days_in_month = days_in_year / 12
    local weeks_in_month = days_in_month / 7
    local time_parts = {
        { id = "year", count = nil, div = 60 * 60 * 24 * days_in_month * 12 },
        { id = "month", count = 12, div = 60 * 60 * 24 * days_in_month },
        { id = "week", count = weeks_in_month, div = 60 * 60 * 24 * 7, is_week = true },
        { id = "day", count = days_in_month, div = 60 * 60 * 24 },
        { id = "hour", count = 24, div = 60 * 60 },
        { id = "minute", count = 60, div = 60 },
        { id = "second", count = 60, div = 1 },
    }

    ---@alias utils.humanizer.time.part.id
    ---| "year"
    ---| "month"
    ---| "week"
    ---| "day"
    ---| "hour"
    ---| "minute"
    ---| "second"

    ---@class utils.humanizer.relative_time.format
    ---@field format? string # Formatting string.
    ---@field text? string # Unit text.
    ---@field plural? string # Unit text if the `value ~= 1`.

    humanizer.long_time_formats = {
        year = { text = "year", plural = "years" },
        month = { text = "month", plural = "months" },
        week = { text = "week", plural = "weeks" },
        day = { text = "day", plural = "days" },
        hour = { text = "hour", plural = "hours" },
        minute = { text = "minute", plural = "minutes" },
        second = { text = "second", plural = "seconds" },
    }

    humanizer.short_time_formats = {
        year = { text = "yr" },
        month = { text = "mo" },
        week = { text = "wk" },
        day = { text = "d" },
        hour = { text = "h" },
        minute = { text = "min" },
        second = { text = "s" },
    }

    ---@param value number
    ---@param format utils.humanizer.relative_time.format
    ---@param unit_separator string
    ---@return string
    local function format_time_part(value, format, unit_separator)
        local value_text = format.format
            and string.format(format.format, value)
            or tostring(value)
        local unit_text = (value ~= 1 and format.plural)
            and format.plural
            or format.text
            or ""
        return value_text .. unit_separator .. unit_text
    end

    ---@class utils.humanizer.relative_time.args
    ---@field unit_separator? string # Default: `" "`
    ---@field part_separator? string # Default: `" "`
    ---@field prefix? string
    ---@field suffix? string
    ---@field formats? table<utils.humanizer.time.part.id, utils.humanizer.relative_time.format>
    ---@field from_part? integer|utils.humanizer.time.part.id
    ---@field force_from_part? integer|utils.humanizer.time.part.id # Must be greater than `from_part`.
    ---@field part_count? integer
    ---@field skip_week? boolean # Default: `false`
    ---@field include_leading_zero? boolean # Default: `false`
    ---@field include_zero? boolean # Default: `true`
    ---@field stop_on_zero? boolean # Default: `true`

    ---@param seconds number
    ---@param args? utils.humanizer.relative_time.args
    ---@return string
    function humanizer.relative_time(seconds, args)
        seconds = umath.round(math.max(0, seconds))
        args = args or {}

        local all_part_count = #time_parts
        local formats = args.formats or humanizer.short_time_formats
        local unit_separator = args.unit_separator or " "
        local part_separator = args.part_separator or " "
        local skip_week = args.skip_week
        local include_leading_zero = args.include_leading_zero
        local include_zero = args.include_zero ~= false
        local stop_on_zero = args.stop_on_zero ~= false

        ---@param arg integer|utils.humanizer.time.part.id
        ---@return integer|nil
        local function get_from_part(arg)
            if arg then
                if type(arg) == "string" then
                    for i, v in ipairs(time_parts) do
                        if v.id == arg then
                            return i
                        end
                    end
                elseif type(arg) == "number" then
                    return arg
                end
            end
            return nil
        end

        local from_part = get_from_part(args.from_part)
        local force_from_part = get_from_part(args.force_from_part)
        local part_count = args.part_count or gtable.count_keys(formats)

        if not from_part then
            for i, v in ipairs(time_parts) do
                if formats[v.id] then
                    from_part = i
                    break
                end
            end
            assert(from_part, "Bad `formats`.")
        end

        from_part = umath.clamp(from_part or 1, 1, all_part_count)
        force_from_part = force_from_part and umath.clamp(force_from_part, 1, all_part_count)
        part_count = umath.clamp(part_count or 1, 1, all_part_count - from_part + 1)

        if force_from_part then
            assert(from_part < force_from_part)
        end

        local parts = {}
        local rest = seconds
        for i = from_part, all_part_count do
            local time_part = time_parts[i]
            if not skip_week or not time_part.is_week then
                local value = rest / time_part.div
                local format = formats[time_part.id]

                value = math.floor(value)
                if value >= 1 then
                    rest = rest - (value * time_part.div)
                    parts[#parts + 1] = format_time_part(value, format, unit_separator)
                elseif rest == seconds then
                    if include_leading_zero or (force_from_part and force_from_part <= i) then
                        parts[#parts + 1] = format_time_part(0, format, unit_separator)
                    end
                else
                    if include_zero or (force_from_part and force_from_part <= i) then
                        parts[#parts + 1] = format_time_part(0, format, unit_separator)
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
            local time_part = time_parts[umath.clamp(from_part + math.max(1, part_count), 1, all_part_count)]
            local format = formats[time_part.id]
            parts[1] = format_time_part(0, format, unit_separator)
        end

        local text = table.concat(parts, part_separator)

        if args.prefix then
            text = args.prefix .. text
        end
        if args.suffix then
            text = text .. args.suffix
        end

        return text
    end
end

return humanizer
