local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local dpi = dpi
local capsule = require("widget.capsule")
local pango = require("utils.pango")


local tag_layout_menu_template = { mt = { __index = {} } }

local info_menu_item_template = {
    widget = wibox.container.margin,
    margins = {
        left = dpi(16),
        right = dpi(16),
        top = dpi(12),
        bottom = dpi(12),
    },
    {
        layout = wibox.container.place,
        halign = "center",
        valign = "center",
        {
            id = "#text",
            widget = wibox.widget.textbox,
        },
    },
    update_callback = function(self, item)
        local style = beautiful.capsule.styles.mebox.normal
        local text_widget = self:get_children_by_id("#text")[1]
        if text_widget then
            local text = item.text
            text_widget:set_markup(pango.span {
                foreground = style.foreground,
                weight = "bold",
                pango.i(text),
            })
        end
    end,
}

local menu_item_template = {
    id = "#container",
    widget = capsule,
    margins = {
        left = 0,
        right = 0,
        top = dpi(2),
        bottom = dpi(2),
    },
    paddings = {
        left = dpi(12),
        right = dpi(12),
        top = dpi(8),
        bottom = dpi(8),
    },
    {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(12),
        {
            id = "#icon",
            widget = wibox.widget.imagebox,
            resize = true,
        },
        {
            id = "#text",
            widget = wibox.widget.textbox,
        },
    },
    update_callback = function(self, item, menu)
        self.forced_width = item.width or menu.item_width
        self.forced_height = item.height or menu.item_height

        local style = item.active
            and (item.selected
                and beautiful.capsule.styles.mebox.active_selected
                or beautiful.capsule.styles.mebox.active)
            or (item.selected
                and beautiful.capsule.styles.mebox.normal_selected
                or beautiful.capsule.styles.mebox.normal)
        self:apply_style(style)

        local icon_widget = self:get_children_by_id("#icon")[1]
        if icon_widget then
            local color = style.foreground
            local stylesheet = beautiful.build_layout_stylesheet(color)
            icon_widget:set_stylesheet(stylesheet)
            icon_widget:set_image(item.icon)
        end

        local text_widget = self:get_children_by_id("#text")[1]
        if text_widget then
            local text = item.text
            text_widget:set_markup(pango.span {
                foreground = style.foreground,
                weight = "bold",
                text,
            })
        end
    end,
}

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

local function info_menu_item(text)
    return {
        enabled = false,
        text = text,
        template = info_menu_item_template,
    }
end

function tag_layout_menu_template.new()
    return {
        item_width = dpi(200),
        item_height = dpi(48),
        on_show = on_show,
        on_hide = on_hide,
        items_source = function(menu)
            local tag = menu.tag
            if not tag then
                return { info_menu_item("No tag selected") }
            end
            local screen = tag.screen
            if not screen then
                return { info_menu_item("Unknown screen") }
            end
            local layouts = tag.layouts
            local count = layouts and #layouts or awful.layout.layouts
            if count == 0 then
                return { info_menu_item("No layout available") }
            end

            local items = {}
            for i = 1, count do
                local layout = layouts[i]

                local name = layout.name or ""
                local icon = beautiful.layout_icons[name]
                local active = tag.layout == layout

                items[i] = {
                    text = name,
                    icon = icon,
                    active = active,
                    callback = function() tag.layout = layout end,
                    template = menu_item_template,
                }
            end
            return items
        end,
    }
end

tag_layout_menu_template.mt.__index.shared = tag_layout_menu_template.new()

return setmetatable(tag_layout_menu_template, tag_layout_menu_template.mt)
