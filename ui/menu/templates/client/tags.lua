local ipairs = ipairs
local beautiful = require("theme.theme")
local dpi = Dpi
local mebox = require("widget.mebox")
local gtable = require("gears.table")
local config = require("config")
local common = require("ui.menu.templates.client._common")


local M = {}

---@return Mebox.new.args
function M.new()
    ---@type Mebox.new.args
    local args = {
        item_width = dpi(150),
        on_show = common.on_show,
        on_hide = common.on_hide,
        items_source = function(menu)
            local client = menu.client --[[@as client]]
            local tags = client:tags()
            local screen_tags = client.screen.tags

            ---@type MeboxItem.args[]
            local items = {
                common.build_simple_toggle("Sticky", "sticky", nil, "/icons/pin.svg", beautiful.palette.white),
            }

            if #screen_tags > 0 then
                items[#items + 1] = mebox.separator
                for _, tag in ipairs(screen_tags) do
                    items[#items + 1] = {
                        enabled = false,
                        text = tag.name,
                        icon = config.places.theme .. "/icons/tag.svg",
                        icon_color = beautiful.palette.white,
                        on_show = function(item) item.checked = not not gtable.hasitem(tags, tag) end,
                    }
                end
            end

            return items
        end,
    }

    return args
end

M.shared = M.new()

return M
