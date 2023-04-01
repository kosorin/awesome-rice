local setmetatable = setmetatable
local wibox = require("wibox")
local gtable = require("gears.table")
local noice = require("theme.stylable")


local M = { mt = {} }

function M.mt:__call(...)
    return M.new(...)
end


M.object = {}

noice.define {
    object = M.object,
    name = "progressbar",
    properties = {
        forced_width = { proxy = true },
        forced_height = { proxy = true },
        border_color = { proxy = true },
        border_width = { proxy = true },
        bar_border_color = { proxy = true },
        bar_border_width = { proxy = true },
        color = { proxy = true },
        background_color = { proxy = true },
        bar_shape = { proxy = true },
        shape = { proxy = true },
        clip = { proxy = true },
        ticks = { proxy = true },
        ticks_gap = { proxy = true },
        ticks_size = { proxy = true },
        max_value = { proxy = true },
        margins = { proxy = true },
        paddings = { proxy = true },
    },
}


---@return wibox.widget.progressbar
function M.new(...)
    local self = wibox.widget.progressbar(...) --[[@as stylable]]

    gtable.crush(self, M.object, true)
    noice.initialize(self)

    return self --[[@as wibox.widget.progressbar]]
end

return setmetatable(M, M.mt)
