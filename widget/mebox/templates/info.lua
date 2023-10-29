local beautiful = require("theme.theme")
local wibox = require("wibox")
local pango = require("utils.pango")
local dpi = Dpi
local hui = require("utils.thickness")


return {
    widget = wibox.container.margin,
    margins = hui.new { dpi(12), dpi(16) },
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
        local style = beautiful.mebox.item_styles.normal.normal
        local text_widget = self:get_children_by_id("#text")[1]
        if text_widget then
            local text = item.text
            text_widget:set_markup(pango.span {
                fgcolor = style.fg,
                weight = "bold",
                pango.i(pango.escape(text)),
            })
        end
    end,
}
