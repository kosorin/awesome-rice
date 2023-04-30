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
local thickness_index = {}

local thickness_mt = {
    __index = thickness_index,
    __newindex = function()
        error("thickness is readonly")
    end,
    __tostring = function(self)
        return format("thickness { top=%d, right=%d, bottom=%d, left=%d }", self.top, self.right, self.bottom, self.left)
    end,
    __eq = function(self, other)
        other = M.thickness(other)
        return self.top == other.top
            and self.right == other.right
            and self.bottom == other.bottom
            and self.left == other.left
    end,
    __len = function() return 4 end,
}

function thickness_index:all()
    return self.top, self.right, self.bottom, self.left
end

function thickness_index:with(other)
    return setmetatable({
        top = other and other.top or self.top,
        right = other and other.right or self.right,
        bottom = other and other.bottom or self.bottom,
        left = other and other.left or self.left,
    }, thickness_mt)
end

function thickness_index:clone(with_metatable)
    local result = {
        top = self.top,
        right = self.right,
        bottom = self.bottom,
        left = self.left,
    }
    return with_metatable ~= false and setmetatable(result, thickness_mt) or result
end

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
---@return thickness
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

        value = {
            top = value.top or top or 0,
            right = value.right or right or 0,
            bottom = value.bottom or bottom or 0,
            left = value.left or left or 0,
        }
    else
        value = {
            top = value,
            right = value,
            bottom = value,
            left = value,
        }
    end
    value[1] = value.top
    value[2] = value.right
    value[3] = value.bottom
    value[4] = value.left
    return setmetatable(value, thickness_mt)
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
