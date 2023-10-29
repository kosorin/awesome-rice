local lgi = require("lgi")
local Gdk = lgi.require("Gdk", "3.0")
local Gtk = lgi.require("Gtk", "3.0")
local gtable = require("gears.table")


---@class Selection
---@field clipboard selection
---@field primary selection
local M = {}

---@class selection
---@field package _selection unknown
local selection_object = {}

---@param value any
function selection_object:copy(value)
    self._selection:set_text(tostring(value) or "", -1)
end

local function new_selection(selection_type)
    ---@type selection
    local self = {
        _selection = Gtk.Clipboard.get(selection_type),
    }

    gtable.crush(self, selection_object, true)

    return self
end

M.clipboard = new_selection(Gdk.SELECTION_CLIPBOARD)
M.primary = new_selection(Gdk.SELECTION_PRIMARY)

return M
