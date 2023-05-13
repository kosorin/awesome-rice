require("develop")

require("globals")

require("config")

local dark = true
---@return Theme.default
local function toggle_light_dark()
    local theme = dark
        and require("theme.styles.default")
        or require("theme.styles.default_light")
    dark = not dark
    ---@diagnostic disable-next-line: return-type-mismatch
    return theme
end

require("theme.manager").load(toggle_light_dark())

local awful = require("awful")
local wibox = require("wibox")
local gshape = require("gears.shape")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local gears = require("gears")
local gfilesystem = require("gears.filesystem")
local binding = require("io.binding")
local btn = binding.button
local mod = binding.modifier
local stylable = require("theme.stylable")
local manager = require("theme.manager")
local pango = require("utils.pango")
local uui = require("utils.ui")
local umouse = require("utils.mouse")
local ext = require("ext")
local capi = Capi
local helper_client = require("utils.client")

capi.screen.connect_signal("request::desktop_decoration", function(screen)
    for index = 1, 5 do
        awful.tag.add(tostring(index), {
            screen = screen,
            selected = index == 1,
        })
    end
end)

capi.screen.connect_signal("request::desktop_decoration", function(screen)
    awful.wibar {
        class = "topbar",
        widget = {
            layout = wibox.container.margin,
            class = "paddings",
            {
                layout = wibox.layout.align.horizontal,
                class = "container",
                {
                    layout = wibox.layout.fixed.horizontal,
                    sid = "left",
                    {
                        layout = wibox.layout.stack,
                        {
                            sid = "bar",
                            widget = ext.capsule,
                            wibox.widget.textbox(""),
                        },
                        {
                            sid = "foo",
                            widget = ext.capsule,
                            wibox.widget.textbox("Hello World"),
                        },
                    },
                    {
                        layout = wibox.layout.stack,
                        {
                            sid = "bar",
                            widget = ext.capsule,
                            wibox.widget.textbox(""),
                        },
                        {
                            sid = "foo",
                            widget = ext.capsule,
                            wibox.widget.textbox("🥰 Foo Bar"),
                        },
                    },
                },
                {
                    layout = wibox.layout.fixed.horizontal,
                    sid = "middle",
                    ext.taglist {
                        screen = screen,
                        buttons = binding.awful_buttons {
                            binding.awful({}, btn.left, function(_, tag)
                                tag:view_only()
                            end),
                            binding.awful({}, btn.right, function(_, tag)
                                tag.volatile = not tag.volatile
                            end),
                            binding.awful({}, btn.middle, function(_, tag)
                                awful.tag.viewtoggle(tag)
                            end),
                        },
                        base_layout = {
                            layout = wibox.layout.fixed.horizontal,
                            class = "layout",
                        },
                        widget_template = {
                            widget = ext.capsule,
                            class = "tag",
                            {
                                id = "text",
                                widget = wibox.widget.textbox,
                            },
                        },
                    },
                },
                {
                    layout = wibox.layout.fixed.horizontal,
                    sid = "right",
                    {
                        widget = wibox.widget.textclock,
                        class = "date",
                    },
                    {
                        widget = wibox.widget.textclock,
                        class = "time",
                    },
                    awful.widget.layoutbox(),
                },
            },
        },
    }
end)

binding.add_global_range {

    binding.new {
        modifiers = {},
        triggers = btn.left,
        on_press = function()
            awful.spawn("xterm")
        end,
    },

}

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

}

require("awful.autofocus")
