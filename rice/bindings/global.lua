local capi = Capi
local awful = require("awful")
local aplacement = require("awful.placement")
local ctag = require("core.tag")
local cclient = require("core.client")
local binding = require("core.binding")
local mod = binding.modifier
local btn = binding.button
local key = binding.key
local services = require("services")
local main_menu = require("ui.menu.main")
local gtable = require("gears.table")
local menu_templates = require("ui.menu.templates")
local mebox = require("widget.mebox")
local bindbox = require("widget.bindbox")
local config = require("rice.config")


local global_bindings = {

    binding.new {
        modifiers = { mod.super, mod.control },
        triggers = "j",
        path = "System",
        description = "Power menu",
        on_press = function()
            mebox(menu_templates.power.shared):show({ placement = aplacement.centered }, { source = "keyboard" })
        end,
    },

    binding.new {
        modifiers = { mod.alt, mod.super, mod.control },
        triggers = "j",
        path = "System",
        description = "Stop power timer",
        on_press = function() services.power.stop_timer() end,
    },

    binding.new {
        modifiers = { mod.super, mod.control },
        triggers = "l",
        path = "System",
        description = "Lock session",
        on_press = function() services.power.lock_screen() end,
    },


    binding.new {
        modifiers = {},
        triggers = btn.left,
        path = "Awesome",
        description = "Resize tiling clients",
        on_press = function() cclient.mouse_resize() end,
    },

    binding.new {
        modifiers = {},
        triggers = btn.right,
        path = "Awesome",
        description = "Show main menu",
        on_press = function() main_menu:toggle(nil, { source = "mouse" }) end,
    },

    binding.new {
        modifiers = { mod.super, mod.control },
        triggers = "w",
        path = "Awesome",
        description = "Show main menu",
        on_press = function() main_menu:show({ placement = aplacement.centered }, { source = "keyboard" }) end,
    },

    binding.new {
        modifiers = { mod.super },
        triggers = "h",
        path = "Awesome",
        description = "Keyboard shortcuts",
        on_press = function() bindbox.main:show() end,
    },

    binding.new {
        modifiers = { mod.super, mod.control },
        triggers = "r",
        path = "Awesome",
        description = "Restart Awesome",
        on_press = function() capi.awesome.restart() end,
    },


    binding.new {
        modifiers = { mod.super },
        triggers = "a",
        path = "Launcher",
        description = "Launcher",
        on_press = function() awful.spawn(config.actions.show_launcher) end,
    },

    binding.new {
        modifiers = { mod.super },
        triggers = "Return",
        path = "Launcher",
        description = "Terminal",
        on_press = function() awful.spawn(config.apps.terminal) end,
    },

    binding.new {
        modifiers = { mod.super },
        triggers = "d",
        path = "Launcher",
        description = "File manager",
        on_press = function() awful.spawn(config.apps.file_manager) end,
    },

    binding.new {
        modifiers = { mod.super },
        triggers = "b",
        path = "Launcher",
        description = "Web browser",
        on_press = function() awful.spawn(config.apps.browser) end,
    },

    binding.new {
        modifiers = { mod.control, mod.super },
        triggers = "b",
        path = "Launcher",
        description = "Web browser (incognito)",
        on_press = function() awful.spawn(config.apps.private_browser) end,
    },

    binding.new {
        modifiers = {},
        triggers = "XF86Calculator",
        path = "Launcher",
        description = "Calculator",
        on_press = function() awful.spawn(config.apps.calculator) end,
    },

    binding.new {
        modifiers = { mod.super },
        triggers = "e",
        path = "Launcher",
        description = "Emoji picker",
        on_press = function() awful.spawn(config.actions.show_emoji_picker) end,
    },


    binding.new {
        modifiers = { mod.super, mod.control },
        triggers = binding.group.arrows_vertical,
        path = "Layout",
        description = "Change the number of primary clients",
        on_press = function(trigger) awful.tag.incnmaster(trigger.y, nil, true) end,
    },

    binding.new {
        modifiers = { mod.super, mod.control },
        triggers = binding.group.arrows_horizontal,
        path = "Layout",
        description = "Change the number of secondary columns",
        on_press = function(trigger) awful.tag.incncol(trigger.x, nil, true) end,
    },


    binding.new {
        modifiers = { mod.super },
        triggers = "r",
        path = "Tag",
        description = "Rename selected tag",
        on_press = function()
            local screen = awful.screen.focused()
            if not screen then
                return
            end
            local tag = screen.selected_tag
            if not tag then
                return
            end
            screen.topbar.taglist:rename_tag_inline(tag)
        end,
    },

    binding.new {
        modifiers = { mod.super },
        triggers = binding.group.numrow,
        path = "Tag",
        description = "Show only the specified tag",
        on_press = function(trigger)
            local tag = ctag.get_or_create(trigger.index)
            if tag then
                tag:view_only()
            end
        end,
    },

    binding.new {
        modifiers = { mod.control, mod.super },
        triggers = binding.group.numrow,
        path = "Tag",
        description = "Toggle tag",
        on_press = function(trigger)
            local tag = ctag.get_or_create(trigger.index)
            if tag then
                awful.tag.viewtoggle(tag)
            end
        end,
    },

    binding.new {
        modifiers = { mod.super },
        triggers = {
            { trigger = ",", action = awful.tag.viewprev },
            { trigger = ".", action = awful.tag.viewnext },
        },
        path = "Tag",
        description = "View previous/next tag",
        on_press = function(trigger) trigger.action() end,
    },

    binding.new {
        modifiers = { mod.control, mod.super },
        triggers = {
            { trigger = ",", direction = -1 },
            { trigger = ".", direction = 1 },
        },
        path = "Tag",
        description = "Move tag to the left/right",
        on_press = function(trigger)
            local screen = awful.screen.focused()
            if not screen then
                return
            end
            local tag = screen.selected_tag
            if not tag then
                return
            end
            local other_tag = screen.tags[tag.index + trigger.direction]
            if not other_tag then
                return
            end
            tag:swap(other_tag)
        end,
    },

    binding.new {
        modifiers = { mod.super },
        triggers = {
            { trigger = "/" },
        },
        path = "Tag",
        description = "Create and select a new tag",
        on_press = function(trigger)
            awful.tag.add(nil, ctag.build {
                screen = awful.screen.focused(),
            }):view_only()
        end,
    },

    binding.new {
        modifiers = { mod.control, mod.super },
        triggers = {
            { trigger = "/" },
        },
        path = "Tag",
        description = "Create a new tag",
        on_press = function(trigger)
            awful.tag.add(nil, ctag.build {
                screen = awful.screen.focused(),
            })
        end,
    },

    binding.new {
        modifiers = { mod.super },
        triggers = "Escape",
        path = "Tag",
        description = "Go back to previous tag",
        on_press = function() awful.tag.history.restore() end,
    },


    binding.new {
        modifiers = { mod.super },
        triggers = "u",
        path = "Client",
        description = "Jump to urgent client",
        order = 1000,
        on_press = function() awful.client.urgent.jumpto() end,
    },

    binding.new {
        modifiers = { mod.super },
        triggers = "Tab",
        path = "Client",
        description = "Go back to previous client",
        on_press = function()
            awful.client.focus.history.previous()
            if capi.client.focus then
                capi.client.focus:raise()
            end
        end,
    },

    binding.new {
        modifiers = { mod.shift, mod.super },
        triggers = "n",
        path = { "Client", "State" },
        description = "Restore minimized",
        order = 1000,
        on_press = function()
            local client = awful.client.restore()
            if client then
                client:activate { context = "key.unminimize" }
            end
        end,
    },


    binding.new {
        modifiers = { mod.super },
        triggers = "q",
        path = "Action",
        description = "Generate QR code from clipboard",
        on_press = function() awful.spawn(config.actions.qr_code_clipboard) end,
    },


    binding.new {
        modifiers = {},
        triggers = {
            { trigger = "XF86AudioLowerVolume", direction = -1 },
            { trigger = "XF86AudioRaiseVolume", direction = 1 },
        },
        path = "Volume",
        description = "Change volume",
        on_press = function(trigger) services.volume.change_volume(trigger.direction * 5) end,
    },

    binding.new {
        modifiers = {},
        triggers = "XF86AudioMute",
        path = "Volume",
        description = "Mute",
        on_press = function() services.volume.toggle_mute() end,
    },


    binding.new {
        modifiers = {},
        triggers = "XF86AudioPlay",
        path = "Media",
        description = "Play/pause",
        on_press = function() services.media.player:play_pause() end,
    },

    binding.new {
        modifiers = {},
        triggers = "XF86AudioStop",
        path = "Media",
        description = "Stop",
        on_press = function() services.media.player:stop() end,
    },

    binding.new {
        modifiers = {},
        triggers = {
            { trigger = "XF86AudioPrev", offset = -1 },
            { trigger = "XF86AudioNext", offset = 1 },
        },
        path = "Media",
        description = "Previous/next track",
        on_press = function(trigger) services.media.player:skip(trigger.offset) end,
    },

    binding.new {
        modifiers = {},
        triggers = {
            { trigger = "XF86AudioRewind", offset = -5 },
            { trigger = "XF86AudioForward", offset = 5 },
        },
        path = "Media",
        description = "Rewind/fast forward (5s)",
        on_press = function(trigger) services.media.player:seek(trigger.offset * services.media.player.unit) end,
    },

    binding.new {
        modifiers = { mod.super },
        triggers = {
            { trigger = "XF86AudioRewind", offset = -30 },
            { trigger = "XF86AudioForward", offset = 30 },
        },
        path = "Media",
        description = "Rewind/fast forward (30s)",
        on_press = function(trigger) services.media.player:seek(trigger.offset * services.media.player.unit) end,
    },

    binding.new {
        modifiers = { mod.super },
        triggers = "XF86AudioPlay",
        path = "Media",
        description = "Pause all",
        on_press = function() services.media.player:pause("%all") end,
    },

    binding.new {
        modifiers = { mod.super },
        triggers = "XF86AudioStop",
        path = "Media",
        description = "Stop all",
        on_press = function() services.media.player:stop("%all") end,
    },


    binding.new {
        modifiers = { mod.super },
        triggers = binding.group.arrows,
        path = "Client",
        description = "Change focus",
        on_press = function(trigger) cclient.focus(nil, trigger.direction) end,
    },
}

if config.features.screenshot_tools then
    global_bindings = {

        binding.new {
            modifiers = {},
            triggers = "Print",
            path = { "Screenshot" },
            description = "Start a manual capture",
            on_press = function() awful.spawn.with_shell("flameshot gui") end,
        },

        binding.new {
            modifiers = { mod.control },
            triggers = "Print",
            path = { "Screenshot" },
            description = "Capture a window",
            on_press = function() awful.spawn.with_shell("flameshot gui --region \"$(slop -q -c 1,0,0,0.5 -b 5 -n 0 -l -t 9999999)\"") end,
        },

        binding.new {
            modifiers = { mod.shift },
            triggers = "Print",
            path = { "Screenshot" },
            description = "Capture a single screen",
            on_press = function() awful.spawn.with_shell("flameshot gui --region \"$(printf '%s' \"$DISPLAY\" | sd '^:(\\d+)' 'screen$1')\"") end,
        },

        binding.new {
            modifiers = { mod.control, mod.shift },
            triggers = "Print",
            path = { "Screenshot" },
            description = "Capture the entire desktop",
            on_press = function() awful.spawn.with_shell("flameshot gui --region all") end,
        },

        binding.new {
            modifiers = { mod.alt },
            triggers = "Print",
            path = { "Screenshot" },
            description = "Open the capture launcher",
            on_press = function() awful.spawn.with_shell("flameshot launcher") end,
        },

        table.unpack(global_bindings) }
end

if config.features.wallpaper_menu then
    global_bindings = {

        binding.new {
            modifiers = { mod.shift, mod.super, mod.control },
            triggers = "w",
            path = "Action",
            description = "Restore wallpaper",
            on_press = function() services.wallpaper.restore() end,
        },

        table.unpack(global_bindings) }
end

if config.features.magnifier_tools then
    global_bindings = {
        binding.new {
            modifiers = { mod.super },
            triggers = "z",
            path = "Action",
            description = "Magnifier",
            on_press = function() services.magnifier.run() end,
        },

        table.unpack(global_bindings) }
end

return global_bindings
