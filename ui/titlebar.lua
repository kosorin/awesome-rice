local capi = Capi
local setmetatable = setmetatable
local pairs, ipairs = pairs, ipairs
local table = table
local awful = require("awful")
local beautiful = require("theme.theme")
local wibox = require("wibox")
local binding = require("io.binding")
local mod = binding.modifier
local btn = binding.button
local dpi = Dpi
local aplacement = require("awful.placement")
local capsule = require("widget.capsule")
local mebox = require("widget.mebox")
local wborder = require("widget.window.window_border")
local client_menu_template = require("ui.menu.templates.client.main")
local config = require("config")
local helper_client = require("utils.client")
local css = require("utils.css")
local ucolor = require("utils.color")
local apermissions = require("awful.permissions")
local apcommon = require("awful.permissions._common")


awful.titlebar.enable_tooltip = false

local titlebar_button_instances = {}

local function update_on_signal(client, signal, widget)
    local signal_instances = titlebar_button_instances[signal]
    if signal_instances == nil then
        signal_instances = setmetatable({}, { __mode = "k" })
        titlebar_button_instances[signal] = signal_instances
        capi.client.connect_signal(signal, function(c, ...)
            print("> signal " .. signal)
            local widgets = signal_instances[c]
            if widgets then
                for _, w in ipairs(widgets) do
                    print("  " .. tostring(w))
                    w.update(w, c, ...)
                end
            end
        end)
    end
    local widgets = signal_instances[client]
    if widgets == nil then
        widgets = setmetatable({}, { __mode = "v" })
        signal_instances[client] = widgets
    end
    table.insert(widgets, widget)
end

local function titlebar_button(client, action, normal_args, toggle_args, button_theme)
    local function get_state()
        return toggle_args and toggle_args.get_state(client)
    end

    local button = wibox.widget {
        widget = capsule,
        {
            widget = wibox.widget.imagebox,
            valign = "center",
        },
    }

    function button.update()
        local args = get_state() and toggle_args or normal_args

        button:apply_style(args.style)
        button.opacity = client.active
            and button_theme.opacity_focus
            or button_theme.opacity_normal

        local icon_widget = button.widget
        icon_widget:set_image(args.icon)
        icon_widget:set_stylesheet(css.style {
            path = { fill = args.style.fg },
        })
    end

    button.buttons = binding.awful_buttons {
        binding.awful({}, btn.left, nil, function()
            action(client, get_state())
        end),
    }

    normal_args.style = normal_args.style or button_theme.styles.normal
    if toggle_args then
        toggle_args.style = toggle_args.style or button_theme.styles.active
        toggle_args.icon = toggle_args.icon or normal_args.icon
        update_on_signal(client, toggle_args.property, button)
    end

    update_on_signal(client, "focus", button)
    update_on_signal(client, "unfocus", button)

    button.update()

    return button
end

local client_menu_instances = setmetatable({}, { __mode = "kv" })

local function ensure_client_menu(client)
    if client_menu_instances[client] then
        return
    end

    local template = client_menu_template.shared
    local old_on_hide = template.on_hide

    function template.on_hide(...)
        client_menu_instances[client] = nil
        old_on_hide(...)
    end

    client_menu_instances[client] = mebox(template)
end

local function toggle_client_menu(client)
    if client_menu_instances[client] then
        client_menu_instances[client]:hide()
    else
        ensure_client_menu(client)
        client_menu_instances[client]:show({
            client = client,
            placement = function(menu)
                aplacement.top_left(menu, {
                    parent = client,
                    margins = beautiful.popup.margins,
                    offset = { y = beautiful.titlebar.height },
                })
                aplacement.no_offscreen(menu, {
                    honor_workarea = true,
                    honor_padding = false,
                    margins = beautiful.popup.margins,
                })
            end,
        }, { source = "mouse" })
    end
end

capi.client.connect_signal("request::titlebars", function(client, _, args)
    local tt_type = args.properties.titlebars_type or "border"
    if tt_type == "toolbox" then
        awful.titlebar(client, {
            position = "top",
            size = beautiful.toolbox_titlebar.height + beautiful.toolbox_titlebar.border_width,
        }).widget = {
            layout = wibox.layout.align.horizontal,
            expand = "inside",
            nil,
            {
                widget = wibox.container.margin,
                buttons = binding.awful_buttons {
                    binding.awful({}, btn.left, function()
                        client:activate { context = "titlebar" }
                        helper_client.mouse_move(client)
                    end),
                    binding.awful({}, btn.right, function()
                        client:activate { context = "titlebar" }
                        helper_client.mouse_resize(client)
                    end),
                    binding.awful({}, btn.middle, function()
                        client:kill()
                    end),
                },
            },
            {
                layout = wibox.layout.fixed.horizontal,
                reverse = true,
                spacing = beautiful.toolbox_titlebar.button.spacing,
                titlebar_button(client, function(c, state) c.minimized = not state end,
                    {
                        icon = beautiful.toolbox_titlebar.button.icons.minimize,
                    },
                    {
                        property = "property::minimized",
                        get_state = function(c) return c.minimized end,
                    }, beautiful.toolbox_titlebar.button),
                titlebar_button(client, function(c, state) c.maximized = not state end,
                    {
                        icon = beautiful.toolbox_titlebar.button.icons.maximize,
                    },
                    {
                        property = "property::maximized",
                        get_state = function(c) return c.maximized end,
                    }, beautiful.toolbox_titlebar.button),
                titlebar_button(client, function(c) c:kill() end,
                    {
                        style = beautiful.toolbox_titlebar.button.styles.close,
                        icon = beautiful.toolbox_titlebar.button.icons.close,
                    }, nil, beautiful.toolbox_titlebar.button),
            },
        }
        return
    end

    local left_border = wibox.widget {
        layout = wborder,
        position = "left",
    }
    local right_border = wibox.widget {
        layout = wborder,
        position = "right",
    }
    local top_border = wibox.widget {
        layout = wborder,
        position = "top",
        corners = true,
        tt_type == "window" and {
            layout = wibox.layout.align.horizontal,
            expand = "inside",
            {
                layout = wibox.layout.fixed.horizontal,
                spacing = beautiful.titlebar.button.spacing,
                titlebar_button(client, toggle_client_menu,
                    {
                        icon = beautiful.titlebar.button.icons.menu,
                    }, nil, beautiful.titlebar.button),
            },
            {
                widget = awful.titlebar.widget.titlewidget(client),
                halign = "center",
                valign = "center",
                buttons = binding.awful_buttons {
                    binding.awful({}, btn.left, function()
                        client:activate { context = "titlebar" }
                        helper_client.mouse_move(client)
                    end),
                    binding.awful({}, btn.right, function()
                        client:activate { context = "titlebar" }
                        helper_client.mouse_resize(client)
                    end),
                    binding.awful({}, btn.middle, function()
                        client:kill()
                    end),
                },
            },
            {
                layout = wibox.layout.fixed.horizontal,
                reverse = true,
                spacing = beautiful.titlebar.button.spacing,
                titlebar_button(client, function(c, state) c.floating = not state end,
                    {
                        icon = beautiful.titlebar.button.icons.floating,
                    },
                    {
                        property = "property::floating",
                        get_state = function(c) return c.floating end,
                    }, beautiful.titlebar.button),
                titlebar_button(client, function(c, state) c.ontop = not state end,
                    {
                        icon = beautiful.titlebar.button.icons.on_top,
                    },
                    {
                        property = "property::ontop",
                        get_state = function(c) return c.ontop end,
                    }, beautiful.titlebar.button),
                titlebar_button(client, function(c, state) c.sticky = not state end,
                    {
                        icon = beautiful.titlebar.button.icons.sticky,
                    },
                    {
                        property = "property::sticky",
                        get_state = function(c) return c.sticky end,
                    }, beautiful.titlebar.button),
                titlebar_button(client, function(c, state) c.minimized = not state end,
                    {
                        icon = beautiful.titlebar.button.icons.minimize,
                    },
                    {
                        property = "property::minimized",
                        get_state = function(c) return c.minimized end,
                    }, beautiful.titlebar.button),
                titlebar_button(client, function(c, state) c.maximized = not state end,
                    {
                        icon = beautiful.titlebar.button.icons.maximize,
                    },
                    {
                        property = "property::maximized",
                        get_state = function(c) return c.maximized end,
                    }, beautiful.titlebar.button),
                titlebar_button(client, function(c) c:kill() end,
                    {
                        style = beautiful.titlebar.button.styles.close,
                        icon = beautiful.titlebar.button.icons.close,
                    }, nil, beautiful.titlebar.button),
            },
        } or nil,
    }
    local bottom_border = wibox.widget {
        layout = wborder,
        position = "bottom",
        corners = true,
    }

    local left_titlebar = awful.titlebar(client, {
        position = "left",
        size = beautiful.titlebar.border_width,
    })
    local right_titlebar = awful.titlebar(client, {
        position = "right",
        size = beautiful.titlebar.border_width,
    })
    local top_titlebar = awful.titlebar(client, {
        position = "top",
        size = beautiful.titlebar.border_width + (tt_type == "window" and beautiful.titlebar.height or 0),
    })
    local bottom_titlebar = awful.titlebar(client, {
        position = "bottom",
        size = beautiful.titlebar.border_width,
    })

    local borders = {
        [left_titlebar] = left_border,
        [right_titlebar] = right_border,
        [top_titlebar] = top_border,
        [bottom_titlebar] = bottom_border,
    }

    for titlebar, border in pairs(borders) do
        titlebar.widget = border
        border.update = function(self, c)
            self.inner_color = c.border_color
        end
        update_on_signal(client, "property::border_color", border)
    end
end)

---@param client client # The client.
---@param context string # Why is the border changed.
local function update_border(client, context)
    if not apcommon.check(client, "client", "border", context) then
        return
    end

    local style
    if client.urgent then
        style = beautiful.client.urgent
    elseif client.active then
        style = beautiful.client.active
    else
        style = beautiful.client.normal
    end

    if not client._private._user_border_width then
        client._border_width = style.border_width or 0
    end

    if not client._private._user_border_color then
        client._border_color = style.border_color or ucolor.black
    end
end

capi.client.disconnect_signal("request::border", awful.permissions.update_border)
capi.client.connect_signal("request::border", update_border)
