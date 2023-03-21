local capi = Capi
local tonumber = tonumber
local ipairs = ipairs
local unpack = table.unpack
local min, max = math.min, math.max
local binding = require("io.binding")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local umath = require("utils.math")
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

    ---@alias utils.mouse.attach.modifiers { exact_match?: boolean, [integer]: key_modifier }

    ---@class utils.mouse.attach_slider.args
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
    ---@field modifiers? utils.mouse.attach.modifiers # Modifiers required to trigger the drag action.
    ---@field orientation? orientation # Dragging orientation.
    ---@field coerce_value? fun(value: number): number # Adjust the value that is passed to other callback functions.
    ---@field start? fun(value: number): boolean|nil # A callback function called at the start. Must return `true` to continue in dragging.
    ---@field update? fun(value: number) # A callback function called on every change.
    ---@field finish? fun(value: number, interrupted: boolean) # A callback function called at the end of dragging.
    ---@field interrupt? fun(value: number): boolean # An interrupt callback function. Called before every `update` callback.

    ---@param args utils.mouse.attach_slider.args
    ---@return function # A detach function. When called detach the drag action from the widget. Does not interrupt current drag action.
    function M.attach_slider(args)
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
                        value = minimum + umath.clamp(position * total_size, 0, total_size)
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

            if args.modifiers and not binding.modifiers_match(modifiers, args.modifiers, args.modifiers.exact_match) then
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

                if args.interrupt and args.interrupt(value) then
                    if args.finish then
                        args.finish(value, true)
                    end
                    return
                end

                if args.update then
                    args.update(value)
                end
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

                if args.update then
                    args.update(value)
                end

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

        local function detach()
            args.widget:disconnect_signal("button::press", callback)
        end

        return detach
    end

    ---@class utils.mouse.attach_wheel.args
    ---@field widget wibox.widget.base
    ---@field step? number # Default: `1`
    ---@field debounce? number # Default: `0.5`
    ---@field modifiers? utils.mouse.attach.modifiers # Modifiers required to trigger the action.
    ---@field start? fun(delta: number): boolean|nil # A callback function called at the start. Must return `true` to continue.
    ---@field update? fun(total_delta: number) # A callback function called on every change.
    ---@field finish? fun(total_delta: number, interrupted: boolean) # A callback function called at the end.

    ---@param args utils.mouse.attach_wheel.args
    ---@return function # An interrupt function.
    ---@return function # A detach function. When called detach the drag action from the widget. Does not interrupt current drag action.
    function M.attach_wheel(args)
        ---@type gears.timer
        local timer
        local is_running = false
        local total_delta = 0

        local function stop(interrupted)
            if not is_running then
                return
            end

            timer:stop()
            is_running = false

            if args.finish then
                args.finish(total_delta, interrupted)
            end

            total_delta = 0
        end

        timer = gtimer {
            timeout = args.debounce or 0.5,
            single_shot = true,
            callback = function()
                stop(false)
            end,
        }

        local step = args.step or 1
        local buttons = {
            [btn.wheel_up] = step,
            [btn.wheel_down] = -step,
        }

        local function callback(_, _, _, button, modifiers, _)
            if capi.mousegrabber.isrunning() then
                return
            end

            local delta = buttons[button]
            if not delta then
                return
            end
            if args.modifiers and not binding.modifiers_match(modifiers, args.modifiers, args.modifiers.exact_match) then
                return
            end

            if not is_running then
                if args.start and not args.start(delta) then
                    return
                end
                is_running = true
                total_delta = 0
            end

            timer:again()
            total_delta = total_delta + delta

            if args.update then
                args.update(total_delta)
            end
        end

        args.widget:connect_signal("button::press", callback)

        local function interrupt()
            stop(true)
        end

        local function detach()
            args.widget:disconnect_signal("button::press", callback)
        end

        return interrupt, detach
    end
end

return M
