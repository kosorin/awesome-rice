local capi = {
    client = client,
}
local insert = table.insert
local beautiful = require("beautiful")
local naughty = require("naughty")
local dpi = dpi
local mebox = require("widget.mebox")
local screen_helper = require("helpers.screen")
local tag_layout_menu_template = require("ui.menu.templates.tag_layout")
local config = require("config")


local tag_menu_template = { mt = {} }

local function build_simple_toggle(name, property, checkbox_type)
    return {
        text = name,
        checkbox_type = checkbox_type,
        on_show = function(item, menu) item.checked = not not menu.tag[property] end,
        callback = function(_, item, menu) menu.tag[property] = not item.checked end,
    }
end

local function on_hide(menu)
    menu.tag = nil
    menu.taglist = nil
end

local function on_show(menu, args)
    local parent = menu._private.parent
    menu.tag = parent and parent.tag or args.tag
    menu.taglist = parent and parent.taglist or args.taglist

    if not menu.tag or not menu.tag.activated then
        on_hide(menu)
        return false
    end
end

function tag_menu_template.new()
    return {
        item_width = dpi(180),
        on_show = on_show,
        on_hide = on_hide,
        items_source = function(menu)
            local tag = menu.tag
            local taglist = menu.taglist

            local items = {}

            insert(items, mebox.header("client"))
            insert(items, {
                text = "move here",
                icon = config.places.theme .. "/icons/arrow-down-right-bold.svg",
                icon_color = beautiful.palette.gray,
                callback = function()
                    local client = capi.client.focus
                    if client then
                        client:move_to_tag(tag)
                    end
                end,
            })
            insert(items, {
                text = "move all here",
                icon = config.places.theme .. "/icons/arrow-down-right-bold.svg",
                icon_color = beautiful.palette.gray,
                callback = function() screen_helper.clients_to_tag(tag.screen, tag) end,
            })
            insert(items, mebox.separator)

            insert(items, mebox.header("tag"))
            if taglist then
                insert(items, {
                    text = "rename",
                    icon = config.places.theme .. "/icons/rename.svg",
                    icon_color = beautiful.palette.green,
                    callback = function() taglist:rename_tag_inline(tag) end,
                })
            end
            insert(items, {
                text = "layout",
                icon = config.places.theme .. "/icons/view-grid.svg",
                icon_color = beautiful.palette.blue,
                submenu = tag_layout_menu_template.new(),
            })
            insert(items, mebox.separator)

            insert(items, {
                text = "volatile",
                on_show = function(item) item.checked = not not tag.volatile end,
                callback = function(_, item)
                    tag.volatile = not item.checked
                end,
            })
            insert(items, mebox.separator)

            insert(items, {
                urgent = true,
                text = "delete",
                icon = config.places.theme .. "/icons/delete-forever.svg",
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
        end
    }
end

tag_menu_template.shared = tag_menu_template.new()

return setmetatable(tag_menu_template, tag_menu_template.mt)
