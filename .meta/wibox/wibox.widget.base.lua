---@meta wibox.widget.base

---@class wibox.widget.base
local M

---@param template widget_template
---@return wibox.widget
function M.make_widget_declarative(template)
end

---@param template widget_value
---@return wibox.widget
function M.make_widget_from_value(template)
end

---@param proxy? wibox.widget
---@param name? string
---@param args? { enable_properties?: boolean, class?: table }
---@return wibox.widget
function M.make_widget(proxy, name, args)
end

---@return wibox.widget
function M.empty_widget()
end

return M
