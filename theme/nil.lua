return setmetatable({}, {
    __tostring = function() return "<nil>" end,
    __newindex = function() error("readonly") end,
})
