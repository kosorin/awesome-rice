local capi = Capi
local insert = table.insert
local beautiful = require("theme.theme")
local naughty = require("naughty")
local dpi = Dpi
local mebox = require("widget.mebox")
local screen_helper = require("core.screen")
local config = require("rice.config")
local common = require("ui.menu.templates.tag._common")
local layout_menu_template = require("ui.menu.templates.tag.layout")


local M = {}

---@return Mebox.new.args
function M.new()
    ---@type Mebox.new.args
    local args = {
        item_width = dpi(212),
        on_show = common.on_show,
        on_hide = common.on_hide,
        items_source = function(menu)
            local tag = menu.tag
            local taglist = menu.taglist

            local items = {}

            insert(items, mebox.header("Client"))
            insert(items, {
                text = "Move Here",
                icon = beautiful.icon("arrow-down-right-bold.svg"),
                icon_color = beautiful.palette.gray,
                callback = function()
                    local client = capi.client.focus
                    if client then
                        client:move_to_tag(tag)
                    end
                end,
            })
            insert(items, {
                text = "Move All Here",
                icon = beautiful.icon("arrow-down-right-bold.svg"),
                icon_color = beautiful.palette.gray,
                callback = function() screen_helper.clients_to_tag(tag.screen, tag) end,
            })
            insert(items, mebox.separator)

            insert(items, mebox.header("Tag"))
            if taglist then
                insert(items, {
                    text = "Rename",
                    icon = beautiful.icon("rename.svg"),
                    icon_color = beautiful.palette.green,
                    callback = function() taglist:rename_tag_inline(tag) end,
                })
            end
            insert(items, {
                text = "Layout",
                icon = beautiful.icon("view-grid.svg"),
                icon_color = beautiful.palette.blue,
                submenu = layout_menu_template.shared,
            })
            insert(items, mebox.separator)

            insert(items, common.build_simple_toggle("Volatile", "volatile", nil, beautiful.icon("delete-clock.svg"), beautiful.palette.gray))
            insert(items, mebox.separator)

            insert(items, {
                text = "Delete",
                icon = beautiful.icon("delete-forever.svg"),
                icon_color = beautiful.palette.red,
                callback = function()
                    if not tag:delete() then
                        naughty.notification {
                            urgency = "low",
                            title = "Awesome",
                            text = "The tag could not deleted. Only empty tags can be deleted.",
                        }
                    end
                end,
            })

            return items
        end,
    }

    return args
end

M.shared = M.new()

return M
