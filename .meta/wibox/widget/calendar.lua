---@meta wibox.widget.calendar

---@class wibox.widget.calendar : wibox.widget
local M

-- Gets the calendar date.
---@return osdate|nil date
function M:get_date(date)
end

-- Sets the calendar date.
---@param date? osdate
---@param focus_date? osdate
function M:set_date(date, focus_date)
end


---@class _wibox.widget.calendar
local S

---@param date? osdate
---@param font? font
---@return wibox.widget.calendar
function S.month(date, font)
end

---@param date? osdate
---@param font? font
---@return wibox.widget.calendar
function S.year(date, font)
end

return S
