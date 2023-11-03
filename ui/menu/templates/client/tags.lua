local ipairs = ipairs
local beautiful = require("theme.theme")
local dpi = Dpi
local math = math
local wibox = require("wibox")
local mebox = require("widget.mebox")
local gtable = require("gears.table")
local config = require("rice.config")
local common = require("ui.menu.templates.client._common")
local capsule = require("widget.capsule")
local hui = require("utils.thickness")
local css = require("utils.css")


local M = {}

local checkbox_item_template = {
    id = "#container",
    widget = capsule,
    margins = hui.new { dpi(2), 0 },
    paddings = hui.new { dpi(6), 0 },
    {
        layout = wibox.container.place,
        halign = "center",
        {
            id = "#icon",
            widget = wibox.widget.imagebox,
            resize = true,
        },
    },
    update_callback = function(self, item, menu)
        self.forced_height = item.height or menu.item_height
        self.forced_width = self.forced_height - dpi(2 * 2)

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
            local checkbox_type = item.checkbox_type or "checkbox"
            local checkbox_style = beautiful.mebox[checkbox_type][not not item.checked]
            local icon = checkbox_style.icon
            local color = checkbox_style.color

            if item.selected then
                color = style.fg
            end

            icon_widget.visible = not not icon
            if icon_widget.visible then
                icon_widget:set_stylesheet(css.style { path = { fill = color } })
                icon_widget:set_image(icon)
            end
        end
    end,
}

---@return Mebox.new.args
function M.new()
    ---@type Mebox.new.args
    local args = {
        item_width = dpi(100),
        layout_template = {
            layout = wibox.layout.fixed.vertical,
            {
                id = "#sticky",
                layout = wibox.layout.fixed.vertical,
            },
            {
                id = "#tags",
                layout = wibox.layout.grid,
                homogeneous = false,
                forced_num_cols = 3,
            },
        },
        on_show = common.on_show,
        on_hide = common.on_hide,
        items_source = function(menu)
            local client = menu.client --[[@as client]]
            local tags = client:tags()
            local screen_tags = client.screen.tags

            ---@type MeboxItem.args[]
            local items = {
                function()
                    local item = common.build_simple_toggle("Sticky", "sticky", nil, beautiful.icon("pin.svg"), beautiful.palette.white)
                    item.layout_id = "#sticky"
                    return item
                end,
            }

            if #screen_tags > 0 then
                items[#items + 1] = function(...)
                    local item = mebox.separator(...)
                    item.layout_id = "#sticky"
                    return item
                end
                for _, tag in ipairs(screen_tags) do
                    items[#items + 1] = {
                        layout_id = "#tags",
                        flex = function(new_width, old_width)
                            return math.max(new_width, old_width)
                        end,
                        text = tag.name,
                        icon = beautiful.icon("tag.svg"),
                        icon_color = beautiful.palette.white,
                        callback = function()
                            client:move_to_tag(tag)
                        end,
                    }
                    items[#items + 1] = function(...)
                        local item = mebox.separator(...)
                        item.layout_id = "#tags"
                        item.orientation = "horizontal"
                        return item
                    end
                    items[#items + 1] = {
                        layout_id = "#tags",
                        template = checkbox_item_template,
                        on_show = function(item)
                            item.checked = not not gtable.hasitem(tags, tag)
                        end,
                        callback = function(item)
                            client:toggle_tag(tag)
                            item.checked = not not gtable.hasitem(client:tags(), tag)
                            menu:update_item(item.index)
                            return false
                        end,
                    }
                end
            end

            return items
        end,
    }

    return args
end

M.shared = M.new()

return M
