local capi = Capi
local time = os.time
local execute = os.execute
local gtimer = require("gears.timer")


local power_service = {
    config = {
        default_timeout = 30, -- minutes
    },
}

function power_service.shutdown()
    execute("systemctl poweroff")
end

function power_service.reboot()
    execute("systemctl reboot")
end

function power_service.suspend()
    execute("systemctl suspend")
end

function power_service.kill_session()
    execute("loginctl kill-session")
end

function power_service.lock_session()
    execute("loginctl lock-session")
end

function power_service.lock_screen()
    execute("light-locker-command --lock")
end

do
    local current_timer

    function power_service.get_timer_status()
        local remaining_seconds
        if current_timer then
            remaining_seconds = (current_timer.start + current_timer.seconds) - time()
            if remaining_seconds < 0 then
                remaining_seconds = true
            end
        else
            remaining_seconds = false
        end

        return remaining_seconds
    end

    local function timer_tick()
        capi.awesome.emit_signal("power::timer", power_service.get_timer_status())
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

    function power_service.start_timer(minutes, action)
        local seconds = (tonumber(minutes) or power_service.config.default_timeout) * 60
        action = action or power_service.shutdown

        power_service.stop_timer()

        current_timer = {
            start = time(),
            seconds = seconds,
            countdown_timer = gtimer {
                timeout = 1,
                callback = timer_tick,
            },
            action_timer = gtimer {
                timeout = seconds,
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
