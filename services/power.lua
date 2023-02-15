local execute = os.execute


local power_service = {}

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

return power_service
