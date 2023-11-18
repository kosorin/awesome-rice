local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("theme.theme")
local dpi = Dpi
local capsule = require("widget.capsule")
local pango = require("utils.pango")
local hui = require("utils.thickness")
local css = require("utils.css")
local common = require("ui.menu.templates.tag._common")
local mebox = require("widget.mebox")


local M = {}

---@return Mebox.new.args
function M.new()
    ---@type Mebox.new.args
    local args = {
        item_width = dpi(224),
        item_height = dpi(48),
        on_show = common.on_show,
        on_hide = common.on_hide,
        items_source = function(menu)
            local tag = menu.tag --[[@as tag]]
            if not tag then
                return { mebox.info("No tag selected") }
            end
            local screen = tag.screen
            if not screen then
                return { mebox.info("Unknown screen") }
            end
            local layouts = tag.layouts
            local count = layouts and #layouts or awful.layout.layouts
            if count == 0 then
                return { mebox.info("No layout available") }
            end

            ---@type MeboxItem.args[]
            local items = {}
            for i = 1, count do
                local layout = layouts[i]

                local name = layout.name or ""
                local checked = tag.layout == layout
                local style = beautiful.layouts[name] or {}

                items[i] = {
                    text = style.text or name,
                    icon = style.icon,
                    checked = checked,
                    callback = function() tag.layout = layout end,
                }
            end
            return items
        end,
        item_template = {
            id = "#container",
            widget = capsule,
            margins = hui.new { dpi(2), 0 },
            paddings = hui.new { dpi(8), dpi(12) },
            {
                layout = wibox.layout.align.horizontal,
                expand = "inside",
                nil,
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
                {
                    widget = wibox.container.margin,
                    margins = hui.new { dpi(4), right = 0 },
                    {
                        id = "#right_icon",
                        widget = wibox.widget.imagebox,
                        resize = true,
                    },
                },
            },
            update_callback = function(self, item, menu)
                self.forced_width = item.width or menu.item_width
                self.forced_height = item.height or menu.item_height

                local styles = item.selected
                    and beautiful.mebox.item_styles.selected
                    or beautiful.mebox.item_styles.normal
                local style = item.urgent
                    and styles.urgent
                    or styles.normal
                self:apply_style(style)

                local icon_widget = self:get_children_by_id("#icon")[1]
                if icon_widget then
                    local color = style.fg
                    local stylesheet = beautiful.build_layout_stylesheet(color)
                    icon_widget:set_stylesheet(stylesheet)
                    icon_widget:set_image(item.icon)
                end

                local text_widget = self:get_children_by_id("#text")[1]
                if text_widget then
                    local text = item.text or ""
                    text_widget:set_markup(pango.span { fgcolor = style.fg, pango.escape(text) })
                end

                local right_icon_widget = self:get_children_by_id("#right_icon")[1]
                if right_icon_widget then
                    local checkbox_type = item.checkbox_type or "radiobox"
                    local checkbox_style = beautiful.mebox[checkbox_type][not not item.checked]
                    local icon = checkbox_style.icon
                    local color = checkbox_style.color

                    if item.selected then
                        color = style.fg
                    end

                    right_icon_widget:set_stylesheet(css.style { path = { fill = color } })
                    right_icon_widget:set_image(icon)
                end
            end,
        },
    }

    return args
end

M.shared = M.new()

return M
