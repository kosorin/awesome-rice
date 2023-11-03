local beautiful = require("theme.theme")
local wibox = require("wibox")
local capsule = require("widget.capsule")
local css = require("utils.css")
local pango = require("utils.pango")
local config = require("rice.config")
local dpi = Dpi
local hui = require("utils.thickness")


return {
    id = "#container",
    widget = capsule,
    margins = hui.new { dpi(2), 0 },
    paddings = hui.new { dpi(6), dpi(8) },
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
            right = -dpi(2),
            {
                visible = false,
                id = "#right_icon",
                widget = wibox.widget.imagebox,
                resize = true,
            },
        },
    },
    update_callback = function(self, item, menu)
        self.forced_width = item.width or menu.item_width
        self.forced_height = item.height or menu.item_height

        self.enable_overlay = item.enabled
        self.opacity = item.opacity or (item.enabled and 1 or 0.5)

        local styles = item.selected
            and beautiful.mebox.item_styles.selected
            or beautiful.mebox.item_styles.normal
        local style = (not item.selected and item.style) or (item.urgent
            and styles.urgent
            or styles.normal)
        self:apply_style(style)

        local icon_widget = self:get_children_by_id("#icon")[1]
        if icon_widget then
            local paddings = menu.paddings
            icon_widget.forced_width = self.forced_height - paddings.top - paddings.bottom

            local icon = item.icon
            if icon == false then
                icon_widget.visible = false
                icon_widget:set_image(nil)
            else
                local color = item.icon_color
                if icon and color ~= false then
                    if not color or item.selected then
                        color = style.fg
                    end
                    local stylesheet = css.style { path = { fill = color } }
                    icon_widget:set_stylesheet(stylesheet)
                else
                    icon_widget:set_stylesheet(nil)
                end
                icon_widget:set_image(icon)
            end
        end

        local text_widget = self:get_children_by_id("#text")[1]
        if text_widget then
            local text = item.text or ""
            text_widget:set_markup(pango.span { fgcolor = style.fg, text })
        end

        local right_icon_widget = self:get_children_by_id("#right_icon")[1]
        if right_icon_widget then
            local icon, color
            if item.checked ~= nil then
                local checkbox_type = item.checkbox_type or "checkbox"
                local checkbox_style = (type(checkbox_type) == "table" and checkbox_type or beautiful.mebox[checkbox_type])[not not item.checked]
                icon = checkbox_style.icon
                color = checkbox_style.color
            elseif item.submenu then
                icon = item.submenu_icon or beautiful.icon("chevron-right.svg")
                color = style.fg
            end

            if item.selected then
                color = style.fg
            end

            right_icon_widget.visible = not not icon
            if right_icon_widget.visible then
                right_icon_widget:set_stylesheet(css.style { path = { fill = color } })
                right_icon_widget:set_image(icon)
            end
        end

        if item.flex then
            local width = self:fit({
                screen = menu.screen,
                dpi = menu.screen.dpi,
                drawable = menu._drawable,
            }, menu.screen.geometry.width, menu.screen.geometry.height)
            if type(item.flex) == "function" then
                width = item.flex(width, self.forced_width)
            end
            self.forced_width = width
        end
    end,
}
