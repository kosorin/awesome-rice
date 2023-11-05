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
local tcolor = require("utils.color")
local hui = require("utils.thickness")
local mebox = require("widget.mebox")
local capsule = require("widget.capsule")
local pango = require("utils.pango")


local mod_key = mod.alt

return mebox {
    item_width = dpi(1000),
    bg = tcolor.change(beautiful.common.bg, { alpha = 0.85 }),
    placement = awful.placement.centered,
    paddings = hui.new { dpi(16) },
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
                callback = function()
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
                buttons_builder = function(item, menu, click_action)
                    return binding.awful_buttons {
                        binding.awful({ mod_key }, btn.left, function()
                            menu.clicked = true
                            click_action()
                        end),
                    }
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
            items[#items + 1] = mebox.header("Hidden Clients")
            for _, client in ipairs(hidden_clients) do
                add_client(client)
            end
        end

        if #items == 0 then
            items[#items + 1] = mebox.info("Client list is empty")
        end

        return items
    end,
    item_template = {
        widget = capsule,
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
    on_show = function(self)
        self.clicked = false
    end,
    on_hide = function(self)
        if not self.clicked then
            self:execute()
        end
    end,
    buttons_builder = function(self)
        return binding.awful_buttons {
            binding.awful({ mod_key }, binding.group.mouse_wheel, function(trigger)
                self:select_next(-trigger.y)
            end),
        }
    end,
    keygrabber_auto = false,
    keygrabber_builder = function(self)
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
                binding.awful({}, "Escape", function()
                    self:hide()
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
