---@class core.system
---@field up_since integer # Number of seconds the system has been running.
local M = {}

do
    local year, month, day, hour, min, sec = io
        .popen("uptime --since")
        :read("*all")
        :match("(%d+)%-(%d+)%-(%d+) (%d+):(%d+):(%d+)")
    M.up_since = os.time {
        year = year,
        month = month,
        day = day,
        hour = hour,
        min = min,
        sec = sec,
    }
end

return M
