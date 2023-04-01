---@class Controller
---@field current { instance?: wibox }
local M = { current = setmetatable({}, { __mode = "v" }) }

---@param wibox wibox
function M.leave(wibox)
    local c = M.current
    if c.instance == wibox then
        c.instance = nil
    end
end

---@param wibox wibox
---@return boolean
function M.enter(wibox)
    local enable = false

    local c = M.current
    if c.instance then
        enable = c.instance == wibox
    else
        c.instance = wibox
        enable = true
    end

    if enable and wibox then
        wibox.drawin.ignore_mousegrabber = true
    end

    return enable
end

return M
