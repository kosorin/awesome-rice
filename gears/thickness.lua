local ui = require("utils.ui")

local M = {}

M.zero = ui.zero_thickness

return setmetatable(M, {
    __call = function(_, ...)
        return ui.thickness(...)
    end,
})
