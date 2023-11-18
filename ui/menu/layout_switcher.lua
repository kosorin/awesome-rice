local capi = Capi
local ipairs = ipairs
local format = string.format
local dpi = Dpi
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("theme.theme")
local focus_history = awful.client.focus.history
local binding = require("core.binding")
local mod = binding.modifier
local btn = binding.button
local gtable = require("gears.table")
local tcolor = require("utils.color")
local hui = require("utils.thickness")
local mebox = require("widget.mebox")
local capsule = require("widget.capsule")
local pango = require("utils.pango")
local layout_menu_template = require("ui.menu.templates.tag.layout")


local function get_mod_keys(...)
    return { mod.super, mod.control, ... }
end

local base_template = layout_menu_template.new()
local base_items_source = base_template.items_source

return mebox(gtable.crush(base_template, {
    bg = tcolor.change(beautiful.common.bg, { alpha = 0.85 }),
    placement = awful.placement.centered,
    paddings = hui.new { dpi(16) },
    items_source = function(menu, ...)
        local items = base_items_source(menu, ...)
        for _, item in ipairs(items) do
            item.buttons_builder = function(item, menu, click_action)
                return binding.awful_buttons {
                    binding.awful(get_mod_keys(), btn.left, function()
                        menu.clicked = true
                        click_action()
                    end),
                }
            end
        end
        return items
    end,
    item_template = {
        id = "#container",
        widget = capsule,
        margins = hui.new { dpi(2), 0 },
        paddings = hui.new { dpi(8), dpi(12) },
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

            local styles = item.selected
                and beautiful.mebox.item_styles.selected
                or beautiful.mebox.item_styles.normal
            local style = item.urgent
                and styles.urgent
                or (item.checked
                    and styles.active
                    or styles.normal)
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
        end,
    },
    on_show = function(self)
        self.clicked = false

        local tag = awful.screen.focused().selected_tag
        if not tag then
            return false
        end
        self.tag = tag
    end,
    on_hide = function(self)
        self.tag = nil

        if not self.clicked then
            self:execute()
        end
    end,
    buttons_builder = function(self)
        return binding.awful_buttons {
            binding.awful(get_mod_keys(), binding.group.mouse_wheel, function(trigger)
                self:select_next(-trigger.y)
            end),
        }
    end,
    keygrabber_auto = false,
    keygrabber_builder = function(self)
        return awful.keygrabber {
            root_keybindings = binding.awful_keys {
                binding.awful(get_mod_keys(), "space", function()
                    self:select_next(1)
                end),
                binding.awful(get_mod_keys(mod.shift), "space", function()
                    self:select_next(-1)
                end),
            },
            keybindings = binding.awful_keys {
                binding.awful(get_mod_keys(), "space", function()
                    self:select_next(1)
                end),
                binding.awful(get_mod_keys(mod.shift), "space", function()
                    self:select_next(-1)
                end),
                binding.awful(get_mod_keys(), {
                    { trigger = "Up", direction = -1 },
                    { trigger = "k", direction = -1 },
                    { trigger = "Down", direction = 1 },
                    { trigger = "j", direction = 1 },
                    { trigger = "Home", direction = "begin" },
                    { trigger = "End", direction = "end" },
                }, function(trigger)
                    self:select_next(trigger.direction)
                end),
                binding.awful({}, "Escape", function()
                    self:hide()
                end),
            },
            stop_key = get_mod_keys()[1],
            stop_event = "release",
            start_callback = function()
                self:show()
                for index, item in ipairs(self._private.items) do
                    if item.checked then
                        self:select(index)
                        break
                    end
                end
            end,
            stop_callback = function()
                self:hide()
            end,
        }
    end,
}))
