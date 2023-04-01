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
    name = "layout-fixed",
    properties = {
        spacing_widget = { proxy = true },
        fill_space = { proxy = true },
        spacing = { proxy = true },
    },
}


function M.horizontal(...)
    local self = wibox.layout.fixed.horizontal(...) --[[@as stylable]]

    gtable.crush(self, M.object, true)
    noice.initialize(self)

    return self
end

function M.vertical(...)
    local self = wibox.layout.fixed.vertical(...) --[[@as stylable]]

    gtable.crush(self, M.object, true)
    noice.initialize(self)

    return self
end

return setmetatable(M, M.mt)
