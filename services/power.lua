local capi = Capi
local os_execute = os.execute
local os_time = os.time
local gtimer = require("gears.timer")
local config = require("config")
local naughty = require("naughty")
local maxinteger = math.maxinteger


local power_service = {
    config = {
        default_timeout = 3600, -- seconds
        minimum_timeout = 15, -- seconds
        alert_threshold = 60, -- seconds
    },
}

local function execute(command)
    if DEBUG then
        print("power timer command: ", command)
    else
        os_execute(command)
    end
end

function power_service.shutdown()
    execute(config.power.shutdown)
end

function power_service.reboot()
    execute(config.power.reboot)
end

function power_service.suspend()
    execute(config.power.suspend)
end

function power_service.kill_session()
    execute(config.power.kill_session)
end

function power_service.lock_session()
    execute(config.power.lock_session)
end

function power_service.lock_screen()
    execute(config.power.lock_screen)
end

do
    local current_timer
    local alert_notification

    function power_service.get_timer_status()
        local remaining_seconds
        if current_timer then
            remaining_seconds = (current_timer.start + current_timer.seconds) - os_time()
            if remaining_seconds < 0 then
                remaining_seconds = true
            end
        else
            remaining_seconds = false
        end

        return remaining_seconds
    end

    local function timer_tick()
        local status = power_service.get_timer_status()

        if (tonumber(status) or maxinteger) <= power_service.config.alert_threshold then
            local reason = current_timer and current_timer.reason or "Execute"
            if not alert_notification then
                local execute_action = naughty.action { name = string.format("%s now", reason) }
                local stop_action = naughty.action { name = "Stop timer" }
                execute_action:connect_signal("invoked", power_service.execute_now)
                stop_action:connect_signal("invoked", power_service.stop_timer)
                alert_notification = naughty.notification {
                    title = "Power timer",
                    urgency = "critical",
                    timeout = status,
                    category = "awesome.power.timer",
                    actions = { execute_action, stop_action },
                }
            end
            alert_notification.message = string.format("%s in %i seconds", reason or "Execute", status)
        end

        if not status then
            if alert_notification then
                alert_notification:destroy()
            end
            alert_notification = nil
        end

        capi.awesome.emit_signal("power::timer", status)
    end

    function power_service.stop_timer()
        if not current_timer then
            return
        end

        current_timer.action_timer:stop()
        current_timer.countdown_timer:stop()
        current_timer = nil

        timer_tick()
    end

    function power_service.execute_now()
        if not current_timer then
            return
        end

        local action = current_timer.action

        power_service.stop_timer()
        action()
    end

    function power_service.start_timer(request)
        power_service.stop_timer()

        local timeout = tonumber(request.timeout) or power_service.config.default_timeout
        if timeout < power_service.config.minimum_timeout then
            timeout = power_service.config.minimum_timeout
        end

        local action = request.action or power_service.shutdown

        current_timer = {
            action = action,
            reason = request.reason,
            start = os_time(),
            seconds = timeout,
            countdown_timer = gtimer {
                timeout = 1,
                callback = timer_tick,
            },
            action_timer = gtimer {
                timeout = timeout,
                single_shot = true,
                callback = function()
                    power_service.stop_timer()
                    action()
                end,
            },
        }

        current_timer.countdown_timer:start()
        current_timer.action_timer:start()

        timer_tick()

        return true
    end
end

return power_service
