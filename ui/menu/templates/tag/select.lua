local capi = Capi
local ipairs = ipairs
local ascreen = require("awful.screen")
local beautiful = require("theme.theme")
local dpi = Dpi
local mebox = require("widget.mebox")
local gtable = require("gears.table")
local config = require("config")


local M = {}

---@return Mebox.new.args
---@param callback fun(tag: tag)
---@param screen? iscreen
---@param exclude? tag
function M.new(callback, screen, exclude)
    ---@type Mebox.new.args
    local args = {
        item_width = dpi(150),
        items_source = function()
            ---@type MeboxItem.args[]
            local items = {}

            for _, tag in ipairs(capi.screen[screen or ascreen.focused()].tags) do
                items[#items + 1] = {
                    enabled = exclude ~= tag,
                    text = tag.name,
                    icon = config.places.theme .. "/icons/tag.svg",
                    icon_color = beautiful.palette.white,
                    callback = function() callback(tag) end,
                }
            end

            return items
        end,
    }

    return args
end

return M
