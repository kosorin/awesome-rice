---@meta wibox.widget.textbox

---@class wibox.widget.textbox : wibox.widget
---@field text string # Set a textbox plain text.
---@field markup string # Set the HTML text of the textbox.
---@field ellipsize text_ellipsize # Set the text ellipsize mode.
---@field wrap text_wrap # Set a textbox wrap mode.
---@field valign valign # The vertical text alignment.
---@field halign halign # The horizontal text alignment.
---@field font font # Set a textbox font.
---@field line_spacing_factor? number or nil # Set the distance between the lines.
---@field justify boolean # Justify the text when there is more space.
---@field indent number # How to indent text with multiple lines.
local M

---Set the text of the textbox . 
---@param text string # The text to set.
function M:set_text(text)
end

---Set the text of the textbox (with Pango markup). 
---@param text string # The text to set. This can contain pango markup (e.g. `<b>bold</b>`). You can use `gears.string.escape` to escape parts of it.
function M:set_markup(text)
end

---Set the text of the textbox (with Pango markup). 
---@param text string # The text to set. This can contain pango markup (e.g. `<b>bold</b>`). You can use `gears.string.escape` to escape parts of it.
---@return boolean
---@return string|nil message # Error message explaining why the markup was invalid.
function M:set_markup_silently(text)
end


---@class _wibox.widget.textbox
---@operator call: wibox.widget.textbox
local S

---Get geometry of text label, as if textbox would be created for it on the screen.
---@param text string
---@param screen? integer|screen
---@param font? string
---@return size
function S.get_markup_geometry(text, screen, font)
end

return S
