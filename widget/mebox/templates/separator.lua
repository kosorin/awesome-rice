local beautiful = require("theme.theme")
local wibox = require("wibox")
local dpi = Dpi


return {
    widget = wibox.widget.separator,
    orientation = "auto",
    color = beautiful.common.bg_bright,
    thickness = dpi(1),
    span_ratio = 1,
    update_callback = function(self, item, menu)
        -- This orientation is inverted from the actual orientation of the separator
        local orientation = item.orientation or menu.orientation
        local size = dpi(16)
        if orientation == "vertical" then
            self.forced_width = item.width or menu.item_width
            self.forced_height = size
        elseif orientation == "horizontal" then
            self.forced_width = size
            self.forced_height = item.height or menu.item_height
        else
            error(orientation)
        end
    end,
}
