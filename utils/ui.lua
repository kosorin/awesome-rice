local rawget = rawget
local rawset = rawset
local setmetatable = setmetatable
local getmetatable = getmetatable
local type = type
local format = string.format


local M = {}

---@class thickness : { top: number, right: number, bottom: number, left: number }
---@operator add(thickness_value): thickness
---@operator sub(thickness_value): thickness
---@operator mul(thickness_value): thickness
---@operator div(thickness_value): thickness
---@operator idiv(thickness_value): thickness
---@operator unm(): thickness

local thickness_mt = {
    __index = function(self, key)
        if key == 1 then
            local value = rawget(self, "top")
            rawset(self, 1, value)
            return value
        elseif key == 2 then
            local value = rawget(self, "right")
            rawset(self, 2, value)
            return value
        elseif key == 3 then
            local value = rawget(self, "bottom")
            rawset(self, 3, value)
            return value
        elseif key == 4 then
            local value = rawget(self, "left")
            rawset(self, 4, value)
            return value
        end
    end,
    __newindex = function()
        error("thickness is readonly")
    end,
    __tostring = function(self)
        return format("thickness { top=%d, right=%d, bottom=%d, left=%d }", self.top, self.right, self.bottom, self.left)
    end,
}

thickness_mt.__add = function(self, other)
    other = M.thickness(other)
    return setmetatable({
        top = self.top + other.top,
        right = self.right + other.right,
        bottom = self.bottom + other.bottom,
        left = self.left + other.left,
    }, thickness_mt)
end
thickness_mt.__sub = function(self, other)
    other = M.thickness(other)
    return setmetatable({
        top = self.top - other.top,
        right = self.right - other.right,
        bottom = self.bottom - other.bottom,
        left = self.left - other.left,
    }, thickness_mt)
end
thickness_mt.__mul = function(self, other)
    other = M.thickness(other)
    return setmetatable({
        top = self.top * other.top,
        right = self.right * other.right,
        bottom = self.bottom * other.bottom,
        left = self.left * other.left,
    }, thickness_mt)
end
thickness_mt.__div = function(self, other)
    other = M.thickness(other)
    return setmetatable({
        top = self.top / other.top,
        right = self.right / other.right,
        bottom = self.bottom / other.bottom,
        left = self.left / other.left,
    }, thickness_mt)
end
thickness_mt.__idiv = function(self, other)
    other = M.thickness(other)
    return setmetatable({
        top = self.top // other.top,
        right = self.right // other.right,
        bottom = self.bottom // other.bottom,
        left = self.left // other.left,
    }, thickness_mt)
end
thickness_mt.__unm = function(self)
    return setmetatable({
        top = -self.top,
        right = -self.right,
        bottom = -self.bottom,
        left = -self.left,
    }, thickness_mt)
end

---@alias thickness_value number|number[]|thickness

---@param value? thickness_value
---@return thickness # Returns the same table instance (i.e. the `value` parameter).
function M.thickness(value)
    if not value then
        return M.zero_thickness
    end

    if type(value) == "table" then
        if getmetatable(value) == thickness_mt then
            return value
        end

        local top, right, bottom, left

        local length = #value
        if length == 1 then
            local v = value[1]
            top = v
            right = v
            bottom = v
            left = v
        elseif length == 2 then
            local y = value[1]
            local x = value[2]
            top = y
            right = x
            bottom = y
            left = x
        elseif length == 3 then
            local x = value[2]
            top = value[1]
            right = x
            bottom = value[3]
            left = x
        elseif length == 4 then
            top = value[1]
            right = value[2]
            bottom = value[3]
            left = value[4]
        end

        value.top = value.top or top or 0
        value.right = value.right or right or 0
        value.bottom = value.bottom or bottom or 0
        value.left = value.left or left or 0
        return setmetatable(value, thickness_mt)
    else
        return setmetatable({
            top = value,
            right = value,
            bottom = value,
            left = value,
        }, thickness_mt)
    end
end

M.zero_thickness = M.thickness(0)

---@param geometry geometry
---@param thickness? thickness_value
---@return geometry
function M.inflate(geometry, thickness)
    thickness = M.thickness(thickness)
    return thickness and {
        x = geometry.x - thickness.left,
        y = geometry.y - thickness.top,
        width = geometry.width + thickness.left + thickness.right,
        height = geometry.height + thickness.top + thickness.bottom,
    } or geometry
end

---@param geometry geometry
---@param thickness? thickness_value
---@return geometry
function M.shrink(geometry, thickness)
    return M.inflate(geometry, -M.thickness(thickness))
end

return M
