local capi = Capi
local ipairs = ipairs
local format = string.format
local dpi = Dpi
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("theme.theme")
local focus_history = awful.client.focus.history
local binding = require("io.binding")
local mod = binding.modifier
local btn = binding.button
local tcolor = require("utils.color")
local hui = require("utils.ui")
local mebox = require("widget.mebox")
local capsule = require("widget.capsule")
local pango = require("utils.pango")


return mebox {
    item_width = dpi(1000),
    bg = tcolor.change(beautiful.common.bg, { alpha = 0.85 }),
    placement = awful.placement.centered,
    paddings = hui.thickness { dpi(16) },
    items_source = function()
        local items = {}

        ---@param client client
        local function add_client(client)
            local tag = client:tags()[1]
            items[#items + 1] = {
                client = client,
                active = client.active,
                text = pango.span {
                    pango.span { fgalpha = "65%", weight = "light", "[", pango.escape(tag and tag.name or ""), "]" },
                    " ",
                    pango.b(pango.escape(client.class or "")),
                    " ",
                    pango.span { fgalpha = "65%", weight = "light", size = "small", pango.escape(client.name or "") },
                },
                on_hide = function(item)
                    if not item.selected then
                        return
                    end
                    if not client.valid then
                        return
                    end
                    if client.hidden then
                        client.hidden = false
                    end
                    if not client:isvisible() then
                        awful.tag.viewmore(client:tags(), client.screen)
                    end
                    client:emit_signal("request::activate", "switcher", { raise = true })
                end,
            }
        end

        local hidden_clients = {}
        for _, client in ipairs(focus_history.list) do
            if client.hidden then
                hidden_clients[#hidden_clients + 1] = client
            else
                add_client(client)
            end
        end

        if #hidden_clients > 0 then
            if #items > 0 then
                items[#items + 1] = mebox.separator
            end
            items[#items + 1] = mebox.header("hidden clients")
            for _, client in ipairs(hidden_clients) do
                add_client(client)
            end
        end

        return items
    end,
    item_template = {
        widget = capsule,
        enable_overlay = false,
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

            local styles = item.selected
                and beautiful.mebox.item_styles.selected
                or beautiful.mebox.item_styles.normal
            local style = item.urgent
                and styles.urgent
                or (item.active
                and styles.active
                or styles.normal)
            self:apply_style(style)

            local icon_widget = self:get_children_by_id("#icon")[1]
            if icon_widget then
                icon_widget.client = item.client
            end

            local text_widget = self:get_children_by_id("#text")[1]
            if text_widget then
                text_widget:set_markup(pango.span {
                    fgcolor = style.fg,
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
