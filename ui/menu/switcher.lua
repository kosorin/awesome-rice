local capi = {
    client = client,
}
local ipairs = ipairs
local format = string.format
local dpi = dpi
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local focus_history = awful.client.focus.history
local binding = require("io.binding")
local mod = binding.modifier
local btn = binding.button
local tcolor = require("theme.color")
local mebox = require("widget.mebox")
local capsule = require("widget.capsule")
local pango = require("utils.pango")


return mebox {
    item_width = dpi(1000),
    bg = tcolor.change(beautiful.common.background, { alpha = 0.85 }),
    placement = awful.placement.centered,
    paddings = {
        left = dpi(16),
        right = dpi(16),
        top = dpi(16),
        bottom = dpi(16),
    },
    items_source = function()
        local items = {}
        for _, client in ipairs(focus_history.list) do
            local tag = client:tags()[1]
            items[#items + 1] = {
                client = client,
                active = client.active,
                text = pango.span {
                    pango.span { fgalpha = "65%", weight = "light", "[", tag and tag.name or "", "]" },
                    " ",
                    pango.b(client.class or ""),
                    " ",
                    pango.span { fgalpha = "65%", weight = "light", size = "small", client.name or "" },
                },
                on_hide = function(item)
                    if not item.selected then
                        return
                    end
                    if not client.valid then
                        return
                    end
                    if not client:isvisible() then
                        awful.tag.viewmore(client:tags(), client.screen)
                    end
                    client:emit_signal("request::activate", "switcher", { raise = true })
                end,
            }
        end
        return items
    end,
    item_template = {
        widget = capsule,
        enabled = false,
        hover_overlay = tcolor.transparent,
        press_overlay = tcolor.transparent,
        {
            layout = wibox.layout.fixed.horizontal,
            spacing = dpi(12),
            {
                widget = wibox.container.margin,
                forced_width = dpi(20),
                top = dpi(2),
                bottom = dpi(2),
                {
                    id = "#icon",
                    widget = awful.widget.clienticon,
                },
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
                icon_widget.client = item.client
            end

            local text_widget = self:get_children_by_id("#text")[1]
            if text_widget then
                text_widget:set_markup(pango.span {
                    foreground = style.foreground,
                    item.text or "",
                })
            end
        end,
    },
    mouse_move_select = true,
    keygrabber_auto = false,
    keygrabber_builder = function(self)
        local mod_key = mod.alt
        local tab_key = binding.awful({ mod_key }, "Tab", function()
            self:select_next(1)
        end)
        local shift_tab_key = binding.awful({ mod_key, mod.shift }, "Tab", function()
            self:select_next(-1)
        end)
        return awful.keygrabber {
            root_keybindings = binding.awful_keys {
                tab_key,
                shift_tab_key,
            },
            keybindings = binding.awful_keys {
                tab_key,
                shift_tab_key,
                binding.awful({ mod_key }, {
                    { trigger = "Up", direction = -1 },
                    { trigger = "k", direction = -1 },
                    { trigger = "Down", direction = 1 },
                    { trigger = "j", direction = 1 },
                    { trigger = "Home", direction = "begin" },
                    { trigger = "End", direction = "end" },
                }, function(trigger)
                    self:select_next(trigger.direction)
                end),
            },
            stop_key = mod_key,
            stop_event = "release",
            start_callback = function()
                self:show()
                if capi.client.focus then
                    self:select_next(1)
                end
            end,
            stop_callback = function()
                self:hide()
            end,
        }
    end,
}
