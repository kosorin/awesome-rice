local capi = Capi
local tonumber = tonumber
local ipairs = ipairs
local unpack = table.unpack
local min, max = math.min, math.max
local binding = require("io.binding")
local gtable = require("gears.table")
local mod = binding.modifier
local btn = binding.button


local M = {}

do
    local orientations = {
        horizontal = {
            position = "x",
            size = "width",
        },
        vertical = {
            position = "y",
            size = "height",
        },
    }

    ---@alias helpers.mouse.attach_slider_grabber.args.modifiers { exact_match?: boolean, [integer]: key_modifier }

    ---@param required helpers.mouse.attach_slider_grabber.args.modifiers # Required modifiers. Modifiers may repeat!
    ---@param actual key_modifier[] # List of unique modifiers currently pressed.
    ---@return boolean
    local function modifier_match(required, actual)
        local exact_match = required.exact_match ~= false

        local diff = {}
        for _, m in ipairs(required) do
            diff[m] = true
        end
        for _, m in ipairs(actual) do
            if diff[m] then
                diff[m] = nil
            else
                if exact_match then
                    return false
                end
                diff[m] = false
            end
        end

        if exact_match then
            return gtable.count_keys(diff) == 0
        else
            for _, m in ipairs(required) do
                if diff[m] ~= nil then
                    return false
                end
            end
            return true
        end
    end

    ---@class helpers.mouse.attach_slider_grabber.args
    ---@field wibox wibox
    ---@field widget wibox.widget.base
    ---@field cursor? cursor # Cursor when dragging. Default: `"sb_up_arrow"`
    ---If `true`, the value will not be changed. The value may still affected by `minimum` and/or `maximum`.
    ---
    ---Otherwise if `false`, the value will be in the range `0..1` (relative to the widget size, thus may be less than 0 or greater than 1).
    ---Also if both `minimum` and `maximum` are set, the value will be translated to the range `minimum..maximum`.
    ---
    ---Default: `false`
    ---@field absolute? boolean
    ---@field minimum? number # Minimum value. Must be less than or equal to `maximum`.
    ---@field maximum? number # Maximum value. Must be greater than or equal to `minimum`.
    ---@field button? button # A mouse button required to trigger the drag action. Default: `1` (left mouse button)
    ---@field modifiers? helpers.mouse.attach_slider_grabber.args.modifiers # Modifiers required to trigger the drag action.
    ---@field orientation? orientation # Dragging orientation.
    ---@field coerce_value? fun(value: number): number # Adjust the value that is passed to other callback functions.
    ---@field start? fun(value: number): boolean|nil # A callback function called at the start. Must return `true` to continue in dragging.
    ---@field update? fun(value: number) # A callback function called on every change.
    ---@field finish? fun(value: number, interrupted: boolean) # A callback function called at the end of dragging.
    ---@field interrupt? fun(value: number): boolean # A callback function.

    ---@param args helpers.mouse.attach_slider_grabber.args
    ---@return function # A detach function. When called detach the drag action from the widget. Does not interrupt current drag action.
    function M.attach_slider_grabber(args)
        local relative = not args.absolute
        local minimum = tonumber(args.minimum)
        local maximum = tonumber(args.maximum)
        local orientation = assert(orientations[args.orientation or "horizontal"])

        local total_size
        if relative and minimum and maximum then
            assert(minimum <= maximum)
            total_size = maximum - minimum
        end

        ---@param position number
        ---@param size number
        ---@return integer
        local function calculate_value(position, size)
            local value = 0
            if relative then
                if size > 0 then
                    position = position / size
                    if total_size then
                        value = minimum + min(max(0, position * total_size), total_size)
                    else
                        value = position
                    end
                end
            else
                if minimum and position < minimum then
                    value = minimum
                elseif maximum and position > maximum then
                    value = maximum
                else
                    value = position
                end
            end
            return args.coerce_value and args.coerce_value(value) or value
        end

        local function callback(_, x, y, button, modifiers, geometry)
            if capi.mousegrabber.isrunning() then
                return
            end
            if button ~= (args.button or btn.left) then
                return
            end
            if args.modifiers and not modifier_match(args.modifiers, modifiers) then
                return
            end

            do
                local positions = { x = x, y = y }
                local position = positions[orientation.position]
                local size = geometry[orientation.size]
                local value = calculate_value(position, size)

                if args.start and not args.start(value) then
                    return
                end

                args.update(value)
            end

            local wibox_geometry = args.wibox and args.wibox:geometry()
            local wibox_position = wibox_geometry and wibox_geometry[orientation.position] or 0

            capi.mousegrabber.run(function(grab)
                local position = grab[orientation.position] - geometry[orientation.position] - wibox_position
                local size = geometry[orientation.size]
                local value = calculate_value(position, size)

                if args.interrupt and args.interrupt(value) then
                    if args.finish then
                        args.finish(value, true)
                    end
                    return false
                end

                args.update(value)

                if grab.buttons[button] then
                    return true
                else
                    if args.finish then
                        args.finish(value, false)
                    end
                    return false
                end
            end, args.cursor or "sb_up_arrow")
        end

        args.widget:connect_signal("button::press", callback)

        return function()
            args.widget:disconnect_signal("button::press", callback)
        end
    end
end

return M
