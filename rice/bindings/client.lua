local capi = Capi
local awful = require("awful")
local aplacement = require("awful.placement")
local beautiful = require("theme.theme")
local ctag = require("core.tag")
local cclient = require("core.client")
local binding = require("core.binding")
local mod = binding.modifier
local btn = binding.button
local menu_templates = require("ui.menu.templates")
local mebox = require("widget.mebox")


local client_bindings = {

    binding.new {
        modifiers = { mod.super, mod.control },
        triggers = "Escape",
        path = "Client",
        description = "Quit",
        order = 0,
        on_press = function(_, client)
            if client.minimize_on_close then
                client.minimized = true
            else
                client:kill()
            end
        end,
    },


    binding.new {
        modifiers = {},
        triggers = btn.left,
        on_press = function(_, client) client:activate { context = "mouse_click" } end,
    },

    binding.new {
        modifiers = { mod.super },
        triggers = btn.left,
        path = "Client",
        description = "Move",
        on_press = function(_, client)
            client:activate { context = "mouse_click" }
            cclient.mouse_move(client)
        end,
    },

    binding.new {
        modifiers = { mod.super },
        triggers = btn.right,
        path = "Client",
        description = "Resize",
        on_press = function(_, client)
            client:activate { context = "mouse_click" }
            cclient.mouse_resize(client)
        end,
    },

    binding.new {
        modifiers = { mod.super, mod.shift },
        triggers = binding.group.numrow,
        path = { "Tag", "Client" },
        description = "Move to tag",
        on_press = function(trigger, client)
            local tag = ctag.get_or_create(trigger.index, client.screen)
            if tag then
                client:move_to_tag(tag)
            end
        end,
    },

    binding.new {
        modifiers = { mod.control, mod.super, mod.shift },
        triggers = binding.group.numrow,
        path = { "Tag", "Client" },
        description = "Toggle on tag",
        on_press = function(trigger, client)
            local tag = ctag.get_or_create(trigger.index, client.screen)
            if tag then
                client:toggle_tag(tag)
            end
        end,
    },

    binding.new {
        modifiers = { mod.super, mod.shift },
        triggers = {
            { trigger = ",", x = -1 },
            { trigger = ".", x = 1 },
        },
        path = { "Tag", "Client" },
        description = "Move client to previous/next tag",
        on_press = function(trigger, client)
            local current_tag = client.screen.selected_tags[1]
            local tag = client.screen.tags[current_tag.index + trigger.x]
            if tag then
                tag:view_only()
                client:move_to_tag(tag)
                client.selected = true
            end
        end,
    },

    binding.new {
        modifiers = { mod.super, mod.shift },
        triggers = {
            { trigger = "/" },
        },
        path = { "Tag", "Client" },
        description = "Move client to a new tag",
        on_press = function(trigger, client)
            local tag = awful.tag.add(nil, ctag.build {
                screen = awful.screen.focused(),
            })
            tag:view_only()
            client:move_to_tag(tag)
            client.selected = true
        end,
    },

    binding.new {
        modifiers = { mod.control, mod.super, mod.shift },
        triggers = {
            { trigger = "/" },
        },
        path = { "Tag", "Client" },
        description = "Move client to a new tag and switch to it",
        on_press = function(trigger, client)
            local tag = awful.tag.add(nil, ctag.build {
                screen = awful.screen.focused(),
            })
            client:move_to_tag(tag)
        end,
    },

    binding.new {
        modifiers = { mod.super, mod.shift },
        triggers = "s",
        path = { "Tag", "Client" },
        description = "Keep on all tags (sticky)",
        on_press = function(_, client) client.sticky = not client.sticky end,
    },

    binding.new {
        modifiers = { mod.super },
        triggers = "w",
        path = "Client",
        description = "Show client menu",
        on_press = function(_, client)
            mebox(menu_templates.client.main.shared):show({
                client = client,
                placement = function(menu)
                    aplacement.centered(menu, { parent = client })
                    aplacement.no_offscreen(menu, {
                        honor_workarea = true,
                        honor_padding = false,
                        margins = beautiful.popup.margins,
                    })
                end,
            }, { source = "keyboard" })
        end,
    },

    binding.new {
        modifiers = { mod.shift, mod.super },
        triggers = binding.group.arrows,
        path = "Client",
        description = "Move",
        on_press = function(trigger, client) cclient.move(client, trigger.direction) end,
    },

    binding.new {
        modifiers = { mod.control, mod.shift, mod.super },
        triggers = binding.group.arrows,
        path = "Client",
        description = "Resize",
        on_press = function(trigger, client) cclient.resize(client, trigger.direction) end,
    },


    binding.new {
        modifiers = { mod.super },
        triggers = "t",
        path = { "Client", "Layer" },
        description = "Keep on top",
        on_press = function(_, client) client.ontop = not client.ontop end,
    },

    binding.new {
        modifiers = { mod.super, mod.alt },
        triggers = "a",
        path = { "Client", "Layer" },
        description = "Above normal clients",
        on_press = function(_, client) client.above = not client.above end,
    },

    binding.new {
        modifiers = { mod.super, mod.alt },
        triggers = "b",
        path = { "Client", "Layer" },
        description = "Below normal clients",
        on_press = function(_, client) client.below = not client.below end,
    },


    binding.new {
        modifiers = { mod.super },
        triggers = "space",
        path = { "Client", "State" },
        description = "Toggle floating/tiling",
        order = 0,
        on_press = function(_, client)
            client.floating = not client.floating
            client:raise()
        end,
    },


    binding.new {
        modifiers = { mod.super },
        triggers = "f",
        path = { "Client", "State" },
        description = "Fullscreen",
        on_press = function(_, client)
            cclient.fullscreen(client, false)
        end,
    },

    binding.new {
        modifiers = { mod.alt, mod.super },
        triggers = "f",
        path = { "Client", "State" },
        description = "Fullscreen on primary screen",
        on_press = function(_, client)
            cclient.fullscreen(client, true)
        end,
    },

    binding.new {
        modifiers = { mod.super },
        triggers = "m",
        path = { "Client", "State" },
        description = "Maximize",
        on_press = function(_, client)
            client.maximized = not client.maximized
            client:raise()
        end,
    },

    binding.new {
        modifiers = { mod.super },
        triggers = "n",
        path = { "Client", "State" },
        description = "Minimize",
        on_press = function(_, client) client.minimized = true end,
    },
}

return client_bindings
