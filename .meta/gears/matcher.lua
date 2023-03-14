---@meta gears.matcher

---@class gears.matcher.rule
---@field rule? table<string, any>
---@field rule_any? table<string, any[]>
---@field except? table<string, any>
---@field except_any? table<string, any[]>

---@class gears.matcher : gears.object
---@field started boolean
---@field timeout number
local M

---@param object any
---@param rule gears.matcher.rule
---@return boolean
function M:matches_rule(object, rule)
end


---@class _gears.matcher
---@operator call : gears.matcher
local S

return S
