local capi = Capi
local awful = require("awful")
local amousec = require("awful.mouse.client")
local aplacement = require("awful.placement")
local beautiful = require("theme.theme")
local grectangle = require("gears.geometry").rectangle
local helper_client = require("utils.client")
local binding = require("io.binding")
local mod = binding.modifier
local btn = binding.button
local services = require("services")
local main_menu = require("ui.menu.main")
local menu_templates = require("ui.menu.templates")
local mebox = require("widget.mebox")
local bindbox = require("widget.bindbox")
local config = require("config")
local hclient = require("utils.client")


---@type table<client, screen>
local fullscreen_restore_screens = setmetatable({}, { __mode = "kv" })

-- Available keys with `super` modifier: gstpzxcv jlyiok

local main_bindbox = bindbox.new()

main_bindbox:add_groups {
    { name = "System" },
    { name = "Awesome" },
    { name = "Launcher" },
    { name = "Screen" },
    { name = "Layout" },
    {
        name = "Tag",
        groups = {
            { name = "Client" },
        },
    },
    {
        name = "Client",
        { modifiers = { mod.alt }, "Tab", description = "Switcher" },
        groups = {
            { name = "State" },
            { name = "Layer" },
        },
    },
    { name = "Action" },
    { name = "Volume" },
    { name = "Media" },
    {
        name = "Screenshot",
        groups = {
            { name = "Save to File" },
            { name = "Copy to Clipboard" },
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
        description = "Resize tiled clients",
        on_press = function() helper_client.mouse_resize(true) end,
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
        on_press = function() main_bindbox:show() end,
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
        triggers = "space",
        path = "Layout",
        description = "Select next layout",
        on_press = function() awful.layout.inc(1) end,
    },

    binding.new {
        modifiers = { mod.shift, mod.super, mod.control },
        triggers = "space",
        path = "Layout",
        description = "Select previous layout",
        on_press = function() awful.layout.inc(-1) end,
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
            local screen = awful.screen.focused()
            local tag = screen and screen.tags[trigger.index]
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
            local screen = awful.screen.focused()
            local tag = screen and screen.tags[trigger.index]
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
        modifiers = { mod.super },
        triggers = "z",
        path = "Action",
        description = "Magnifier",
        on_press = function() services.magnifier.run() end,
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
        on_press = function(trigger) hclient.focus(nil, trigger.direction) end,
    },
}

if config.features.screenshot_tools then
    binding.add_global_range {

        binding.new {
            modifiers = {},
            triggers = "Print",
            path = { "Screenshot", "Save to file" },
            description = "Interactive selection",
            on_press = function() services.screenshot.take { mode = "selection", shader = "boxzoom" } end,
        },

        binding.new {
            modifiers = { mod.alt },
            triggers = "Print",
            path = { "Screenshot", "Save to file" },
            description = "Current window",
            on_press = function() services.screenshot.take { mode = "window" } end,
        },

        binding.new {
            modifiers = { mod.control },
            triggers = "Print",
            path = { "Screenshot", "Save to file" },
            description = "Full screen",
            on_press = function() services.screenshot.take { mode = nil } end,
        },


        binding.new {
            modifiers = { mod.super },
            triggers = "Print",
            path = { "Screenshot", "Copy to clipboard" },
            description = "Interactive selection",
            on_press = function() services.screenshot.take { mode = "selection", shader = "boxzoom", output = "clipboard" } end,
        },

        binding.new {
            modifiers = { mod.alt, mod.super },
            triggers = "Print",
            path = { "Screenshot", "Copy to clipboard" },
            description = "Current window",
            on_press = function() services.screenshot.take { mode = "window", output = "clipboard" } end,
        },

        binding.new {
            modifiers = { mod.control, mod.super },
            triggers = "Print",
            path = { "Screenshot", "Copy to clipboard" },
            description = "Full screen",
            on_press = function() services.screenshot.take { mode = nil, output = "clipboard" } end,
        },

    }
end

if config.features.wallpaper_menu then
    binding.add_global_range {

        binding.new {
            modifiers = { mod.shift, mod.super, mod.control },
            triggers = "w",
            path = "Action",
            description = "Restore wallpaper",
            on_press = function() services.wallpaper.restore() end,
        },

    }
end

binding.add_client_range {

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
            helper_client.mouse_move(client)
        end,
    },

    binding.new {
        modifiers = { mod.super },
        triggers = btn.right,
        path = "Client",
        description = "Resize",
        on_press = function(_, client)
            client:activate { context = "mouse_click" }
            helper_client.mouse_resize(client)
        end,
    },

    binding.new {
        modifiers = { mod.super, mod.shift },
        triggers = binding.group.numrow,
        path = { "Tag", "Client" },
        description = "Move to tag",
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
        path = { "Tag", "Client" },
        description = "Toggle on tag",
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
        on_press = function(trigger, client) hclient.move(client, trigger.direction) end,
    },

    binding.new {
        modifiers = { mod.control, mod.shift, mod.super },
        triggers = binding.group.arrows,
        path = "Client",
        description = "Resize",
        on_press = function(trigger, client) hclient.resize(client, trigger.direction) end,
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
            ---@cast client client
            local client_screen = client.screen
            if not client.fullscreen then
                fullscreen_restore_screens[client] = nil
                client.fullscreen = true
            else
                local restore_screen = fullscreen_restore_screens[client]
                if restore_screen and restore_screen ~= client_screen then
                    client:move_to_screen(restore_screen)
                    fullscreen_restore_screens[client] = nil
                end
                client.fullscreen = false
            end
            client:raise()
        end,
    },

    binding.new {
        modifiers = { mod.alt, mod.super },
        triggers = "f",
        path = { "Client", "State" },
        description = "Fullscreen on primary screen",
        on_press = function(_, client)
            ---@cast client client
            local primary_screen = capi.screen["primary"]
            local client_screen = client.screen
            if not client.fullscreen or client_screen ~= primary_screen then
                fullscreen_restore_screens[client] = client_screen
                client:move_to_screen(primary_screen)
                client.fullscreen = true
            else
                local restore_screen = fullscreen_restore_screens[client]
                if restore_screen and restore_screen ~= client_screen then
                    client:move_to_screen(restore_screen)
                    fullscreen_restore_screens[client] = nil
                end
                client.fullscreen = false
            end
            client:raise()
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


    binding.new {
        modifiers = { mod.super, mod.shift },
        triggers = "s",
        path = { "Tag", "Client" },
        description = "Keep on all tags (sticky)",
        on_press = function(_, client) client.sticky = not client.sticky end,
    },

}


main_bindbox:add_group {
    name = "mpv",
    rule = { rule = { instance = "gl", class = "mpv" } },
    bg = "#5f2060",
    { "q", description = "Quit" },
    { modifiers = { mod.shift }, "q", description = "Store the playback position and quit" },
    { "f", description = "Toggle fullscreen" },
    groups = {
        {
            name = "Playback",
            { "space", "p", description = "Toggle pause" },
            { ",", ".", description = "Step backward/forward 1 frame" },
            { modifiers = { mod.shift }, "Left", "Right", description = "Seek backward/forward 1 second" },
            { "Left", "Right", description = "Seek backward/forward 5 seconds" },
            { "Up", "Down", description = "Seek backward/forward 1 minute" },
            { binding.button.wheel_up, binding.button.wheel_down, description = "Seek backward/forward 10 seconds" },
            { "l", description = "Set/clear A-B loop points" },
            { modifiers = { mod.shift }, "l", description = "Toggle infinite looping" },
            { "[", "]", description = "Decrease/increase current playback speed by 10%" },
            { "{", "}", description = "Halve/double current playback speed" },
            { "BackSpace", description = "Reset playback speed to normal" },
        },
        {
            name = "Video",
            { "_", description = "Cycle through the available video tracks" },
            { "w", "W", description = "Decrease/increase pan-and-scan range" },
            { modifiers = { mod.shift }, "a", description = "Cycle aspect ratio override" },
            { "1", "2", description = "Adjust contrast" },
            { "3", "4", description = "Adjust brightness" },
            { "5", "6", description = "Adjust gamma" },
            { "7", "8", description = "Adjust saturation" },
            { modifiers = { mod.alt }, "Left", "Up", "Right", "Down", description = "Move the video rectangle" },
            { modifiers = { mod.alt }, "+", "-", description = "Zoom the video" },
            { modifiers = { mod.alt }, "BackSpace", description = "Reset the pan/zoom settings" },
        },
        {
            name = "Audio",
            { "#", description = "Cycle through the available audio tracks" },
            { "m", description = "Mute sound" },
            { binding.button.wheel_left, "/", "9", description = "Decrease volume" },
            { binding.button.wheel_right, "*", "0", description = "Increase volume" },
            { modifiers = { mod.control }, "+", "-", description = "Adjust audio delay by +/- 0.1 seconds" },
        },
        {
            name = "Subtitles",
            { "v", description = "Toggle subtitle visibility" },
            { "j", "J", description = "Cycle through the available subtitles" },
            { "z", "Z", description = "Adjust subtitle delay by +/- 0.1 seconds" },
            {
                modifiers = { mod.control },
                "Left",
                "Right",
                description = "Seek to the previous/next subtitle",
            },
            {
                modifiers = { mod.control, mod.shift },
                "Left",
                "Right",
                description = "Adjust subtitle delay so that the previous/next subtitle is displayed now",
            },
            { "r", "R", description = "Move subtitles up/down" },
            { modifiers = { mod.shift }, "g", "f", description = "Adjust subtitle font size by +/- 10%" },
        },
        {
            name = "Playlist",
            { "&lt;", "&gt;", description = "Go backward/forward" },
            { "Return", description = "Go forward" },
            { binding.button.extra_back, binding.button.extra_forward, description = "Skip to previous/next entry" },
            { "F8", description = "Show the playlist and the current position in it" },
        },
        {
            name = "Other",
            { modifiers = {}, "s", description = "Take a screenshot" },
            { modifiers = { mod.shift }, "s", description = "Take a screenshot without subtitles" },
            { modifiers = { mod.control }, "s", description = "Take a screenshot as the window shows it" },
            { "o", "O", description = "Show/toggle OSD playback" },
            { "i", "I", description = "Show/toggle an overlay displaying statistics" },
            { "F9", description = "Show the list of audio and subtitle streams" },
            { "`", description = "Show the console" },
        },
    },
}

main_bindbox:add_group {
    name = "feh",
    rule = { rule = { instance = "feh", class = "feh" } },
    bg = "#70011a",
    { "Escape", "q", description = "Quit" },
    { "x", description = "Close current window" },
    { "f", description = "Toggle fullscreen" },
    { "c", description = "Caption entry mode" },
    { modifiers = { mod.control }, "Delete", description = "Delete current image file" },
    groups = {
        {
            name = "Image",
            { "s", description = "Save the image" },
            { "r", description = "Reload the image" },
            { modifiers = { mod.control }, "r", description = "Render the image" },
            { modifiers = { mod.shift }, binding.button.left, description = "Blur the image" },
            { "&lt;", "&gt;", description = "Rotate 90 degrees" },
            { modifiers = { mod.shift }, binding.button.middle, description = "Rotate" },
            { "_", description = "Vertically flip" },
            { "|", description = "Horizontally flip" },
            { modifiers = { mod.control }, "Left", "Up", "Right", "Down", description = "Scroll/pan" },
            { modifiers = { mod.alt }, "Left", "Up", "Right", "Down", description = "Scroll/pan by one page" },
            { binding.button.left, description = "Pan" },
            { binding.button.middle, "KP_Add", "KP_Subtract", "Up", "Down", description = "Zoom in/out" },
            { "*", description = "Zoom to 100%" },
            { "/", description = "Zoom to fit the window size" },
            { "!", description = "Zoom to fill the window size" },
            { modifiers = { mod.shift }, "z", description = "Toggle auto-zoom in fullscreen" },
            { "k", description = "Toggle zoom and viewport keeping" },
            { "g", description = "Toggle window size keeping" },
        },
        {
            name = "Filelist",
            { modifiers = { mod.shift }, "l", description = "Save the filelist" },
            { binding.button.wheel_up, "space", "Right", "n", description = "Show next image" },
            { binding.button.wheel_down, "BackSpace", "Left", "p", description = "Show previous image" },
            { "Home", "End", description = "Show first/last image" },
            { "Prior", "Next", description = "Go ~5% of the filelist" },
            { "z", description = "Jump to a random image" },
            { "Delete", description = "Remove the image" },
        },
        {
            name = "UI",
            { binding.button.right, "m", description = "Show menu" },
            { "d", description = "Toggle filename display" },
            { "e", description = "Toggle EXIF tag display" },
            { "i", description = "Toggle info display" },
            { "o", description = "Toggle pointer visibility" },
        },
        {
            name = "Slideshow",
            { "h", description = "Pause/continue the slideshow" },
        },
    },
}

return {
    main_bindbox = main_bindbox,
}
