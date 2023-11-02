local beautiful = require("theme.theme")


local M = {}

---@param menu Mebox
function M.on_hide(menu)
    menu.tag = nil
    menu.taglist = nil
end

---@param menu Mebox
---@param args Mebox.show.args
function M.on_show(menu, args)
    local parent = menu._private.parent
    menu.tag = parent and parent.tag or args.tag
    menu.taglist = parent and parent.taglist or args.taglist

    if not menu.tag or not menu.tag.activated then
        M.on_hide(menu)
        return false
    end
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
            local tag = menu.tag --[[@as tag]]
            item.checked = not not tag[property]
        end,
        callback = function(item, menu)
            local tag = menu.tag --[[@as tag]]
            tag[property] = not item.checked
        end,
    }
end

return M
