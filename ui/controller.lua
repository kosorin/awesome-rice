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
    local c = M.current
    if c.instance then
        return c.instance == wibox
    else
        c.instance = wibox
        return true
    end
end

return M
