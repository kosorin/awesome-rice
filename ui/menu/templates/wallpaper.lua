local config = require("rice.config")
if not config.features.wallpaper_menu then
    return
end

local insert = table.insert
local awful = require("awful")
local beautiful = require("theme.theme")
local mebox = require("widget.mebox")
local dpi = Dpi
local wallpaper_service = require("services.wallpaper")
local places = require("rice.places")


local M = {}

---@return Mebox.new.args
function M.new()
    ---@type Mebox.new.args
    local args = {
        items_source = function()
            ---@type MeboxItem.args[]
            local items = {
                {
                    flex = true,
                    text = "Restore",
                    icon = beautiful.icon("shuffle-variant.svg"),
                    icon_color = beautiful.palette.gray,
                    callback = function()
                        wallpaper_service.restore()
                        return false
                    end,
                },
                mebox.separator,
            }

            local contains_any_collection
            for _, collection in ipairs(wallpaper_service.get_collections()) do
                contains_any_collection = true
                insert(items, {
                    flex = true,
                    text = collection.name,
                    callback = function()
                        wallpaper_service.set_collection(collection)
                        return false
                    end,
                })
            end
            if contains_any_collection then
                insert(items, mebox.separator)
            end

            insert(items, {
                flex = true,
                text = "Open Directory",
                icon = beautiful.icon("folder-image.svg"),
                icon_color = beautiful.palette.blue,
                callback = function()
                    awful.spawn(config.commands.open(places.wallpapers))
                end,
            })

            return items
        end,
    }

    return args
end

M.shared = M.new()

return M
