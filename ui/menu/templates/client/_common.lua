local beautiful = require("theme.theme")


local M = {}

---@param menu Mebox
function M.on_hide(menu)
    menu.client = nil
end

---@param menu Mebox
---@param args Mebox.show.args
function M.on_show(menu, args)
    local parent = menu._private.parent
    menu.client = parent and parent.client or args.client

    if not menu.client or not menu.client.valid then
        M.on_hide(menu)
        return false
    end

    local client = menu.client --[[@as client]]

    local function unmanage()
        client:disconnect_signal("request::unmanage", unmanage)
        menu:hide()
    end

    client:connect_signal("request::unmanage", unmanage)
end

---comment
---@param text string
---@param property string
---@param checkbox_type? "checkmark"|"checkbox"|"radiobox"|"switch"
---@param icon? path
---@param icon_color? color
---@return table
function M.build_simple_toggle(text, property, checkbox_type, icon, icon_color)
    return {
        text = text,
        checkbox_type = checkbox_type,
        icon = icon,
        icon_color = icon_color,
        on_show = function(item, menu)
            local client = menu.client --[[@as client]]
            item.checked = not not client[property]
        end,
        callback = function(item, menu)
            local client = menu.client --[[@as client]]
            client[property] = not item.checked
        end,
    }
end

return M
