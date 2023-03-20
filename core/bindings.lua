local capi = Capi
local awful = require("awful")
local amousec = require("awful.mouse.client")
local aplacement = require("awful.placement")
local beautiful = require("theme.theme")
local grectangle = require("gears.geometry").rectangle
local helper_client = require("helpers.client")
local binding = require("io.binding")
local mod = binding.modifier
local btn = binding.button
local services = require("services")
local main_menu = require("ui.menu.main")
local menu_templates = require("ui.menu.templates")
local mebox = require("widget.mebox")
local bindbox = require("widget.bindbox")
local config = require("config")
local hclient = require("helpers.client")


-- Available keys with `super` modifier: gstpzxcv jlyiok

local main_bindbox = bindbox.new()

main_bindbox:add_groups {
    { name = "system" },
    { name = "awesome" },
    { name = "launcher" },
    { name = "screen" },
    { name = "layout" },
    {
        name = "tag",
        groups = {
            { name = "client" },
        },
    },
    {
        name = "client",
        { modifiers = { mod.alt }, "Tab", description = "client switcher" },
        groups = {
            { name = "state" },
            { name = "layer" },
        },
    },
    { name = "action" },
    { name = "volume" },
    { name = "media" },
    {
        name = "screenshot",
        groups = {
            { name = "save to file" },
            { name = "copy to clipboard" },
        },
    },
}

capi.awesome.connect_signal("main_bindbox::show", function()
    main_bindbox:show()
end)


binding.add_global_range {

    binding.new {
        modifiers = { mod.super, mod.control },
        triggers = "j",
        path = "system",
        description = "power menu",
        on_press = function()
            mebox(menu_templates.power.shared):show({ placement = aplacement.centered }, { source = "keyboard" })
        end,
    },

    binding.new {
        modifiers = { mod.super, mod.control },
        triggers = "l",
        path = "system",
        description = "lock session",
        on_press = function() services.power.lock_screen() end,
    },


    binding.new {
        modifiers = {},
        triggers = btn.left,
        path = "awesome",
        description = "resize tiled clients",
        on_press = function() helper_client.mouse_resize(true) end,
    },

    binding.new {
        modifiers = {},
        triggers = btn.right,
        path = "awesome",
        description = "show main menu",
        on_press = function() main_menu:toggle(nil, { source = "mouse" }) end,
    },

    binding.new {
        modifiers = { mod.super, mod.control },
        triggers = "w",
        path = "awesome",
        description = "show main menu",
        on_press = function() main_menu:show({ placement = aplacement.centered }, { source = "keyboard" }) end,
    },

    binding.new {
        modifiers = { mod.super },
        triggers = "h",
        path = "awesome",
        description = "keyboard shortcuts",
        on_press = function() main_bindbox:show() end,
    },

    binding.new {
        modifiers = { mod.super, mod.control },
        triggers = "r",
        path = "awesome",
        description = "restart awesome",
        on_press = function() capi.awesome.restart() end,
    },


    binding.new {
        modifiers = { mod.super },
        triggers = "a",
        path = "launcher",
        description = "launcher",
        on_press = function() awful.spawn(config.actions.show_launcher) end,
    },

    binding.new {
        modifiers = { mod.super },
        triggers = "Return",
        path = "launcher",
        description = "terminal",
        on_press = function() awful.spawn(config.apps.terminal) end,
    },

    binding.new {
        modifiers = { mod.super },
        triggers = "d",
        path = "launcher",
        description = "file manager",
        on_press = function() awful.spawn(config.apps.file_manager) end,
    },

    binding.new {
        modifiers = { mod.super },
        triggers = "b",
        path = "launcher",
        description = "browser",
        on_press = function() awful.spawn(config.apps.browser) end,
    },

    binding.new {
        modifiers = { mod.control, mod.super },
        triggers = "b",
        path = "launcher",
        description = "browser (private window)",
        on_press = function() awful.spawn(config.apps.private_browser) end,
    },

    binding.new {
        modifiers = {},
        triggers = "XF86Calculator",
        path = "launcher",
        description = "calculator",
        on_press = function() awful.spawn(config.apps.calculator) end,
    },

    binding.new {
        modifiers = { mod.super },
        triggers = "e",
        path = "launcher",
        description = "emoji picker",
        on_press = function() awful.spawn(config.actions.show_emoji_picker) end,
    },


    binding.new {
        modifiers = { mod.super, mod.control },
        triggers = "space",
        path = "layout",
        description = "select next layout",
        on_press = function() awful.layout.inc(1) end,
    },

    binding.new {
        modifiers = { mod.shift, mod.super, mod.control },
        triggers = "space",
        path = "layout",
        description = "select previous layout",
        on_press = function() awful.layout.inc(-1) end,
    },

    binding.new {
        modifiers = { mod.super, mod.control },
        triggers = binding.group.arrows_vertical,
        path = "layout",
        description = "change the number of primary clients",
        on_press = function(trigger) awful.tag.incnmaster(trigger.y, nil, true) end,
    },

    binding.new {
        modifiers = { mod.super, mod.control },
        triggers = binding.group.arrows_horizontal,
        path = "layout",
        description = "change the number of secondary columns",
        on_press = function(trigger) awful.tag.incncol(trigger.x, nil, true) end,
    },


    binding.new {
        modifiers = { mod.super },
        triggers = "r",
        path = "tag",
        description = "rename selected tag",
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
        path = "tag",
        description = "show only the specified tag",
        on_press = function(trigger)
            local screen = awful.screen.focused()
            local tag = screen.tags[trigger.index]
            if tag then
                tag:view_only()
            end
        end,
    },

    binding.new {
        modifiers = { mod.control, mod.super },
        triggers = binding.group.numrow,
        path = "tag",
        description = "toggle tag",
        on_press = function(trigger)
            local screen = awful.screen.focused()
            local tag = screen.tags[trigger.index]
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
        path = "tag",
        description = "view previous/next tag",
        on_press = function(trigger) trigger.action() end,
    },

    binding.new {
        modifiers = { mod.super },
        triggers = "Escape",
        path = "tag",
        description = "go back to previous tag",
        on_press = function() awful.tag.history.restore() end,
    },


    binding.new {
        modifiers = { mod.super },
        triggers = "u",
        path = "client",
        description = "jump to urgent client",
        order = 1000,
        on_press = function() awful.client.urgent.jumpto() end,
    },

    binding.new {
        modifiers = { mod.super },
        triggers = "Tab",
        path = "client",
        description = "go back to previous client",
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
        path = { "client", "state" },
        description = "restore minimized",
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
        path = "action",
        description = "generate QR code from clipboard",
        on_press = function() awful.spawn(config.actions.qr_code_clipboard) end,
    },

    binding.new {
        modifiers = { mod.super },
        triggers = "z",
        path = "action",
        description = "magnifier",
        on_press = function() services.magnifier.run() end,
    },


    binding.new {
        modifiers = {},
        triggers = {
            { trigger = "XF86AudioLowerVolume", direction = -1 },
            { trigger = "XF86AudioRaiseVolume", direction = 1 },
        },
        path = "volume",
        description = "change volume",
        on_press = function(trigger) services.volume.change_volume(trigger.direction * 5) end,
    },

    binding.new {
        modifiers = {},
        triggers = "XF86AudioMute",
        path = "volume",
        description = "mute",
        on_press = function() services.volume.toggle_mute() end,
    },


    binding.new {
        modifiers = {},
        triggers = "XF86AudioPlay",
        path = "media",
        description = "play/pause",
        on_press = function() services.media.player:play_pause() end,
    },

    binding.new {
        modifiers = {},
        triggers = "XF86AudioStop",
        path = "media",
        description = "stop",
        on_press = function() services.media.player:stop() end,
    },

    binding.new {
        modifiers = {},
        triggers = {
            { trigger = "XF86AudioPrev", offset = -1 },
            { trigger = "XF86AudioNext", offset = 1 },
        },
        path = "media",
        description = "previous/next track",
        on_press = function(trigger) services.media.player:skip(trigger.offset) end,
    },

    binding.new {
        modifiers = {},
        triggers = {
            { trigger = "XF86AudioRewind", offset = -5 },
            { trigger = "XF86AudioForward", offset = 5 },
        },
        path = "media",
        description = "rewind/fast forward (5s)",
        on_press = function(trigger) services.media.player:seek(trigger.offset * services.media.player.second) end,
    },

    binding.new {
        modifiers = { mod.super },
        triggers = {
            { trigger = "XF86AudioRewind", offset = -30 },
            { trigger = "XF86AudioForward", offset = 30 },
        },
        path = "media",
        description = "rewind/fast forward (30s)",
        on_press = function(trigger) services.media.player:seek(trigger.offset * services.media.player.second) end,
    },

    binding.new {
        modifiers = { mod.super },
        triggers = "XF86AudioPlay",
        path = "media",
        description = "pause all",
        on_press = function() services.media.player:pause("%all") end,
    },

    binding.new {
        modifiers = { mod.super },
        triggers = "XF86AudioStop",
        path = "media",
        description = "stop all",
        on_press = function() services.media.player:stop("%all") end,
    },

}

if config.features.screenshot_tools then
    binding.add_global_range {

        binding.new {
            modifiers = {},
            triggers = "Print",
            path = { "screenshot", "save to file" },
            description = "interactive selection",
            on_press = function() services.screenshot.take { mode = "selection", shader = "boxzoom" } end,
        },

        binding.new {
            modifiers = { mod.alt },
            triggers = "Print",
            path = { "screenshot", "save to file" },
            description = "current window",
            on_press = function() services.screenshot.take { mode = "window" } end,
        },

        binding.new {
            modifiers = { mod.control },
            triggers = "Print",
            path = { "screenshot", "save to file" },
            description = "full screen",
            on_press = function() services.screenshot.take { mode = nil } end,
        },


        binding.new {
            modifiers = { mod.super },
            triggers = "Print",
            path = { "screenshot", "copy to clipboard" },
            description = "interactive selection",
            on_press = function() services.screenshot.take { mode = "selection", shader = "boxzoom", output = "clipboard" } end,
        },

        binding.new {
            modifiers = { mod.alt, mod.super },
            triggers = "Print",
            path = { "screenshot", "copy to clipboard" },
            description = "current window",
            on_press = function() services.screenshot.take { mode = "window", output = "clipboard" } end,
        },

        binding.new {
            modifiers = { mod.control, mod.super },
            triggers = "Print",
            path = { "screenshot", "copy to clipboard" },
            description = "full screen",
            on_press = function() services.screenshot.take { mode = nil, output = "clipboard" } end,
        },

    }
end

if config.features.wallpaper_menu then
    binding.add_global_range {

        binding.new {
            modifiers = { mod.shift, mod.super, mod.control },
            triggers = "w",
            path = "action",
            description = "restore wallpaper",
            on_press = function() services.wallpaper.restore() end,
        },

    }
end

binding.add_client_range {

    binding.new {
        modifiers = { mod.super, mod.control },
        triggers = "Escape",
        path = "client",
        description = "quit",
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
        path = "client",
        description = "move",
        on_press = function(_, client)
            client:activate { context = "mouse_click" }
            helper_client.mouse_move(client)
        end,
    },

    binding.new {
        modifiers = { mod.super },
        triggers = btn.right,
        path = "client",
        description = "resize",
        on_press = function(_, client)
            client:activate { context = "mouse_click" }
            helper_client.mouse_resize(client)
        end,
    },

    binding.new {
        modifiers = { mod.super, mod.shift },
        triggers = binding.group.numrow,
        path = { "tag", "client" },
        description = "move to tag",
        on_press = function(trigger, client)
            local tag = client.screen.tags[trigger.index]
            if tag then
                client:move_to_tag(tag)
            end
        end,
    },

    binding.new {
        modifiers = { mod.control, mod.super, mod.shift },
        triggers = binding.group.numrow,
        path = { "tag", "client" },
        description = "toggle on tag",
        on_press = function(trigger, client)
            local tag = client.screen.tags[trigger.index]
            if tag then
                client:toggle_tag(tag)
            end
        end,
    },

    binding.new {
        modifiers = { mod.super },
        triggers = "w",
        path = "client",
        description = "show client menu",
        on_press = function(_, client)
            mebox(menu_templates.client.new()):show({
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
        modifiers = { mod.super },
        triggers = binding.group.arrows,
        path = "client",
        description = "change focus",
        on_press = function(trigger, client) awful.client.focus.global_bydirection(trigger.direction, client) end,
    },

    binding.new {
        modifiers = { mod.shift, mod.super },
        triggers = binding.group.arrows,
        path = "client",
        description = "move",
        on_press = function(trigger, client) hclient.move(client, trigger.direction) end,
    },

    binding.new {
        modifiers = { mod.control, mod.shift, mod.super },
        triggers = binding.group.arrows,
        path = "client",
        description = "resize",
        on_press = function(trigger, client) hclient.resize(client, trigger.direction) end,
    },


    binding.new {
        modifiers = { mod.super },
        triggers = "t",
        path = { "client", "layer" },
        description = "keep on top",
        on_press = function(_, client) client.ontop = not client.ontop end,
    },

    binding.new {
        modifiers = { mod.super, mod.alt },
        triggers = "a",
        path = { "client", "layer" },
        description = "above normal clients",
        on_press = function(_, client) client.above = not client.above end,
    },

    binding.new {
        modifiers = { mod.super, mod.alt },
        triggers = "b",
        path = { "client", "layer" },
        description = "below normal clients",
        on_press = function(_, client) client.below = not client.below end,
    },


    binding.new {
        modifiers = { mod.super },
        triggers = "space",
        path = { "client", "state" },
        description = "toggle floating/tiling",
        order = 0,
        on_press = function(_, client)
            client.floating = not client.floating
            client:raise()
        end,
    },


    binding.new {
        modifiers = { mod.super },
        triggers = "f",
        path = { "client", "state" },
        description = "fullscreen",
        on_press = function(_, client)
            client.fullscreen = not client.fullscreen
            client:raise()
        end,
    },

    binding.new {
        modifiers = { mod.super },
        triggers = "m",
        path = { "client", "state" },
        description = "maximize",
        on_press = function(_, client)
            client.maximized = not client.maximized
            client:raise()
        end,
    },

    binding.new {
        modifiers = { mod.super },
        triggers = "n",
        path = { "client", "state" },
        description = "minimize",
        on_press = function(_, client) client.minimized = true end,
    },


    binding.new {
        modifiers = { mod.super, mod.shift },
        triggers = "s",
        path = { "tag", "client" },
        description = "keep on all tags (sticky)",
        on_press = function(_, client) client.sticky = not client.sticky end,
    },

}


main_bindbox:add_group {
    name = "mpv",
    rule = { rule = { instance = "gl", class = "mpv" } },
    bg = "#5f2060",
    { "q", description = "quit" },
    { modifiers = { mod.shift }, "q", description = "store the playback position and quit" },
    { "f", description = "toggle fullscreen" },
    groups = {
        {
            name = "playback",
            { "space", "p", description = "toggle pause" },
            { ",", ".", description = "step backward/forward 1 frame" },
            { modifiers = { mod.shift }, "Left", "Right", description = "seek backward/forward 1 second" },
            { "Left", "Right", description = "seek backward/forward 5 seconds" },
            { "Up", "Down", description = "seek backward/forward 1 minute" },
            { binding.button.wheel_up, binding.button.wheel_down, description = "seek backward/forward 10 seconds" },
            { "l", description = "set/clear A-B loop points" },
            { modifiers = { mod.shift }, "l", description = "toggle infinite looping" },
            { "[", "]", description = "decrease/increase current playback speed by 10%" },
            { "{", "}", description = "halve/double current playback speed" },
            { "BackSpace", description = "reset playback speed to normal" },
        },
        {
            name = "video",
            { "_", description = "cycle through the available video tracks" },
            { "w", "W", description = "decrease/increase pan-and-scan range" },
            { modifiers = { mod.shift }, "a", description = "cycle aspect ratio override" },
            { "1", "2", description = "adjust contrast" },
            { "3", "4", description = "adjust brightness" },
            { "5", "6", description = "adjust gamma" },
            { "7", "8", description = "adjust saturation" },
            { modifiers = { mod.alt }, "Left", "Up", "Right", "Down", description = "move the video rectangle" },
            { modifiers = { mod.alt }, "+", "-", description = "zoom the video" },
            { modifiers = { mod.alt }, "BackSpace", description = "reset the pan/zoom settings" },
        },
        {
            name = "audio",
            { "#", description = "cycle through the available audio tracks" },
            { "m", description = "mute sound" },
            { binding.button.wheel_left, "/", "9", description = "decrease volume" },
            { binding.button.wheel_right, "*", "0", description = "increase volume" },
            { modifiers = { mod.control }, "+", "-", description = "adjust audio delay by +/- 0.1 seconds" },
        },
        {
            name = "subtitles",
            { "v", description = "toggle subtitle visibility" },
            { "j", "J", description = "cycle through the available subtitles" },
            { "z", "Z", description = "adjust subtitle delay by +/- 0.1 seconds" },
            {
                modifiers = { mod.control },
                "Left",
                "Right",
                description = "seek to the previous/next subtitle"
            },
            {
                modifiers = { mod.control, mod.shift },
                "Left",
                "Right",
                description = "adjust subtitle delay so that the previous/next subtitle is displayed now"
            },
            { "r", "R", description = "move subtitles up/down" },
            { modifiers = { mod.shift }, "g", "f", description = "adjust subtitle font size by +/- 10%" },
        },
        {
            name = "playlist",
            { "&lt;", "&gt;", description = "go backward/forward" },
            { "Return", description = "go forward" },
            { binding.button.extra_back, binding.button.extra_forward, description = "skip to previous/next entry" },
            { "F8", description = "show the playlist and the current position in it" },
        },
        {
            name = "other",
            { modifiers = {}, "s", description = "take a screenshot" },
            { modifiers = { mod.shift }, "s", description = "take a screenshot without subtitles" },
            { modifiers = { mod.control }, "s", description = "take a screenshot as the window shows it" },
            { "o", "O", description = "show/toggle OSD playback" },
            { "i", "I", description = "show/toggle an overlay displaying statistics" },
            { "F9", description = "show the list of audio and subtitle streams" },
            { "`", description = "show the console" },
        },
    },
}

main_bindbox:add_group {
    name = "feh",
    rule = { rule = { instance = "feh", class = "feh" } },
    bg = "#70011a",
    { "Escape", "q", description = "quit" },
    { "x", description = "close current window" },
    { "f", description = "toggle fullscreen" },
    { "c", description = "caption entry mode" },
    { modifiers = { mod.control }, "Delete", description = "delete current image file" },
    groups = {
        {
            name = "image",
            { "s", description = "save the image" },
            { "r", description = "reload the image" },
            { modifiers = { mod.control }, "r", description = "render the image" },
            { modifiers = { mod.shift }, binding.button.left, description = "blur the image" },
            { "&lt;", "&gt;", description = "rotate 90 degrees" },
            { modifiers = { mod.shift }, binding.button.middle, description = "rotate" },
            { "_", description = "vertically flip" },
            { "|", description = "horizontally flip" },
            { modifiers = { mod.control }, "Left", "Up", "Right", "Down", description = "scroll/pan" },
            { modifiers = { mod.alt }, "Left", "Up", "Right", "Down", description = "scroll/pan by one page" },
            { binding.button.left, description = "pan" },
            { binding.button.middle, "KP_Add", "KP_Subtract", "Up", "Down", description = "zoom in/out" },
            { "*", description = "zoom to 100%" },
            { "/", description = "zoom to fit the window size" },
            { "!", description = "zoom to fill the window size" },
            { modifiers = { mod.shift }, "z", description = "toggle auto-zoom in fullscreen" },
            { "k", description = "toggle zoom and viewport keeping" },
            { "g", description = "toggle window size keeping" },
        },
        {
            name = "filelist",
            { modifiers = { mod.shift }, "l", description = "save the filelist" },
            { binding.button.wheel_up, "space", "Right", "n", description = "show next image" },
            { binding.button.wheel_down, "BackSpace", "Left", "p", description = "show previous image" },
            { "Home", "End", description = "show first/last image" },
            { "Prior", "Next", description = "go ~5% of the filelist" },
            { "z", description = "jump to a random image" },
            { "Delete", description = "remove the image" },
        },
        {
            name = "ui",
            { binding.button.right, "m", description = "show menu" },
            { "d", description = "toggle filename display" },
            { "e", description = "toggle EXIF tag display" },
            { "i", description = "toggle info display" },
            { "o", description = "toggle pointer visibility" },
        },
        {
            name = "slideshow",
            { "h", description = "pause/continue the slideshow" },
        },
    },
}

return {
    main_bindbox = main_bindbox,
}
