local capi = Capi
local ipairs = ipairs
local beautiful = require("theme.theme")
local dpi = Dpi
local mebox = require("widget.mebox")
local gtable = require("gears.table")
local config = require("rice.config")
local common = require("ui.menu.templates.client._common")


local M = {}

---@return Mebox.new.args
function M.new()
    ---@type Mebox.new.args
    local args = {
        item_width = dpi(100),
        on_show = common.on_show,
        on_hide = common.on_hide,
        items_source = function(menu)
            local client = menu.client --[[@as client]]

            ---@type MeboxItem.args[]
            local items = {}

            for screen in capi.screen do
                items[#items + 1] = {
                    text = screen.index,
                    icon = beautiful.icon("monitor.svg"),
                    icon_color = beautiful.palette.white,
                    checkbox_type = "radiobox",
                    on_show = function(item, menu, args, context)
                        if client.screen == screen then
                            item.checked = true
                            if context.source == "keyboard" then
                                args.selected_index = item.index
                            end
                        else
                            item.checked = false
                        end
                    end,
                    callback = function()
                        client:move_to_screen(screen)
                    end,
                }
            end

            return items
        end,
    }

    return args
end

M.shared = M.new()

return M
