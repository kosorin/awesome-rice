local type = type
local lgi = require("lgi")
local Gdk = lgi.require("Gdk", "3.0")
local Gtk = lgi.require("Gtk", "3.0")
local gtable = require("gears.table")


---@class Clipboard
---@field clipboard selection
---@field primary selection
local M = {}

---@class selection
---@field package instance unknown
local selection_object = {}

---@param text any
---@return boolean
function selection_object:copy(value)
    local text = tostring(value) or ""
    if #text == 0 then
        return false
    end

    self.instance:set_text(text, -1)
    return true
end

local function new_selection(selection_type)
    ---@type selection
    local self = {
        instance = Gtk.Clipboard.get(selection_type),
    }

    gtable.crush(self, selection_object, true)

    return self
end

M.clipboard = new_selection(Gdk.SELECTION_CLIPBOARD)
M.primary = new_selection(Gdk.SELECTION_PRIMARY)

return M
