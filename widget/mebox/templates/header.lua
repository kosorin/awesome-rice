local beautiful = require("theme.theme")
local wibox = require("wibox")
local pango = require("utils.pango")
local dpi = Dpi
local hui = require("utils.thickness")


return {
    widget = wibox.container.margin,
    margins = hui.new { dpi(6), dpi(8) },
    {
        id = "#text",
        widget = wibox.widget.textbox,
    },
    update_callback = function(self, item)
        local text_widget = self:get_children_by_id("#text")[1]
        if text_widget then
            local color = beautiful.common.fg_66
            local text = item.text or ""
            text_widget:set_markup(pango.span {
                size = "smaller",
                text_transform = "uppercase",
                fgcolor = color,
                weight = "bold",
                pango.escape(text),
            })
        end
    end,
}
