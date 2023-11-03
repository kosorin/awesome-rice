local power = {}

power.timer = {
    default_timeout = 3600,
    minimum_timeout = 15,
    alert_threshold = 60,
}

power.commands = {
    shutdown = "systemctl poweroff",
    reboot = "systemctl reboot",
    suspend = "systemctl suspend",
    kill_session = "loginctl kill-session ''",
    lock_session = "loginctl lock-session",
    lock_screen = "light-locker-command --lock",
}

return power
