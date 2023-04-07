local capi = Capi
local next = next
local pairs = pairs
local amouse = require("awful.mouse")
local gtimer = require("gears.timer")
local binding = require("io.binding")
local mod = binding.modifier
local btn = binding.button


---@class Popup : wibox
---@field hide fun()

---@class Controller
---@field current { [Popup]: boolean }
local M = { current = setmetatable({}, { __mode = "k" }) }

local can_hide = false
local enter_timer

local function start_enter_timer()
    can_hide = false
    enter_timer:again()
end

local function stop_enter_timer()
    can_hide = true
    enter_timer:stop()
end

local function clear_enter_timer()
    local ch = can_hide
    stop_enter_timer()
    return ch
end

enter_timer = gtimer {
    timeout = 0.5,
    callback = stop_enter_timer,
}

---@param wibox Popup
function M.leave(wibox)
    M.current[wibox] = nil
    wibox.visible = false

    if not next(M.current) then
        capi.mousegrabber.stop()
    end
end

---@param wibox Popup
function M.enter(wibox)
    M.current[wibox] = true

    if not capi.mousegrabber.isrunning() then
        capi.mousegrabber.run(function() return true end, nil)
        start_enter_timer()
    end

    wibox.drawin.ignore_mousegrabber = true
    wibox.visible = true
end

amouse.append_mousegrabber_bindings(binding.awful_buttons {
    binding.awful({}, { btn.left, btn.right }, nil, function()
        if clear_enter_timer() then
            for wibox in pairs(M.current) do
                wibox:hide()
            end
        end
    end),
})

return M
