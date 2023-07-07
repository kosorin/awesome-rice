local capi = Capi
local os_execute = os.execute
local os_time = os.time
local gtimer = require("gears.timer")
local config = require("config")


local power_service = {
    config = {
        default_timeout = 60, -- minutes
        alert_threshold = 60, -- seconds
    },
}

local function execute(command)
    if false then
        print("power timer: " .. command)
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
            start = os_time(),
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
