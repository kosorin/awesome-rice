local capi = Capi
local setmetatable = setmetatable
local pairs, ipairs = pairs, ipairs
local table = table
local awful = require("awful")
local beautiful = require("theme.theme")
local wibox = require("wibox")
local binding = require("core.binding")
local mod = binding.modifier
local btn = binding.button
local dpi = Dpi
local aplacement = require("awful.placement")
local amousec = require("awful.mouse.client")
local capsule = require("widget.capsule")
local mebox = require("widget.mebox")
local client_menu_template = require("ui.menu.templates.client.main")
local config = require("rice.config")
local cclient = require("core.client")
local css = require("utils.css")


awful.titlebar.enable_tooltip = false

local titlebar_button_instances = {}

local function update_on_signal(client, signal, widget)
    local signal_instances = titlebar_button_instances[signal]
    if signal_instances == nil then
        signal_instances = setmetatable({}, { __mode = "k" })
        titlebar_button_instances[signal] = signal_instances
        capi.client.connect_signal(signal, function(c)
            local widgets = signal_instances[c]
            if widgets then
                for _, w in ipairs(widgets) do
                    w.update()
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

local function titlebar_button(args)
    local button_widget = wibox.widget {
        widget = capsule,
        buttons = binding.awful_buttons {
            binding.awful({}, btn.left, nil, function()
                args.action(args)
            end),
        },
        {
            widget = wibox.widget.imagebox,
            valign = "center",
        },
    }

    function button_widget.update()
        local focus_state = args.client.active and "focus" or "normal"
        local toggle_state = args.get_state and args.get_state() and "toggle" or "normal"
        local button_style = args.style.buttons[args.id] or args.style.buttons.default
        local icon = args.style.icons[args.id]

        button_style = button_style[focus_state][toggle_state]
        button_widget:apply_style(button_style)

        local icon_widget = button_widget.widget
        if icon then
            icon_widget:set_image(icon)
            icon_widget:set_stylesheet(css.style {
                path = { fill = button_style.fg },
            })
        else
            icon_widget:set_image(nil)
        end
    end

    update_on_signal(args.client, "focus", button_widget)
    update_on_signal(args.client, "unfocus", button_widget)
    if args.get_state and args.property then
        update_on_signal(args.client, args.property, button_widget)
    end

    button_widget.update()

    return button_widget
end

local client_menu_instances = setmetatable({}, { __mode = "kv" })

local function ensure_client_menu(client)
    if client_menu_instances[client] then
        return
    end

    local menu = mebox(client_menu_template.shared)

    menu:connect_signal("menu::hide", function()
        client_menu_instances[client] = nil
    end)

    client_menu_instances[client] = menu
end

local function toggle_client_menu(args)
    local client = args.client
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
                    offset = { y = args.style.height },
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

---@param client client
---@param args table
local function toolbox_titlebar(client, args)
    local style = beautiful.titlebar.toolbox
    awful.titlebar(client, {
        position = "top",
        size = style.height,
    }).widget = {
        layout = wibox.container.margin,
        margins = style.paddings,
        {
            layout = wibox.layout.align.horizontal,
            expand = "inside",
            {
                layout = wibox.layout.fixed.horizontal,
                spacing = style.spacing,
                titlebar_button {
                    id = "menu",
                    client = client,
                    style = style,
                    action = toggle_client_menu,
                },
            },
            {
                widget = awful.titlebar.widget.titlewidget(client),
                halign = "center",
                valign = "center",
                buttons = binding.awful_buttons {
                    binding.awful({}, btn.left, function()
                        client:activate { context = "titlebar" }
                        cclient.mouse_move(client)
                    end),
                    binding.awful({}, btn.right, function()
                        client:activate { context = "titlebar" }
                        cclient.mouse_resize(client)
                    end),
                    binding.awful({}, btn.middle, function()
                        client:kill()
                    end),
                },
            },
            {
                layout = wibox.layout.fixed.horizontal,
                reverse = true,
                spacing = style.spacing,
                titlebar_button {
                    id = "close",
                    client = client,
                    style = style,
                    action = function() client:kill() end,
                },
            },
        },
    }
end

---@param client client
---@param args table
local function default_titlebar(client, args)
    local style = beautiful.titlebar.default
    awful.titlebar(client, {
        position = "top",
        size = style.height,
    }).widget = {
        layout = wibox.container.margin,
        margins = style.paddings,
        {
            layout = wibox.layout.align.horizontal,
            expand = "inside",
            {
                layout = wibox.layout.fixed.horizontal,
                spacing = style.spacing,
                titlebar_button {
                    id = "menu",
                    client = client,
                    style = style,
                    action = toggle_client_menu,
                },
            },
            {
                widget = awful.titlebar.widget.titlewidget(client),
                halign = "center",
                valign = "center",
                buttons = binding.awful_buttons {
                    binding.awful({}, btn.left, function()
                        client:activate { context = "titlebar" }
                        cclient.mouse_move(client)
                    end),
                    binding.awful({}, btn.right, function()
                        client:activate { context = "titlebar" }
                        cclient.mouse_resize(client)
                    end),
                    binding.awful({}, btn.middle, function()
                        client:kill()
                    end),
                },
            },
            {
                layout = wibox.layout.fixed.horizontal,
                reverse = true,
                spacing = style.spacing,
                titlebar_button {
                    id = "sticky",
                    client = client,
                    style = style,
                    action = function() client.sticky = not client.sticky end,
                    get_state = function() return client.sticky end,
                    property = "property::sticky",
                },
                titlebar_button {
                    id = "floating",
                    client = client,
                    style = style,
                    action = function() client.floating = not client.floating end,
                    get_state = function() return client.floating end,
                    property = "property::floating",
                },
                titlebar_button {
                    id = "on_top",
                    client = client,
                    style = style,
                    action = function() client.ontop = not client.ontop end,
                    get_state = function() return client.ontop end,
                    property = "property::ontop",
                },
                titlebar_button {
                    id = "minimize",
                    client = client,
                    style = style,
                    action = function() client.minimized = not client.minimized end,
                    get_state = function() return client.minimized end,
                    property = "property::minimized",
                },
                titlebar_button {
                    id = "maximize",
                    client = client,
                    style = style,
                    action = function() client.maximized = not client.maximized end,
                    get_state = function() return client.maximized end,
                    property = "property::maximized",
                },
                titlebar_button {
                    id = "close",
                    client = client,
                    style = style,
                    action = function() client:kill() end,
                },
            },
        },
    }
end

capi.client.connect_signal("request::titlebars", function(client, _, args)
    local titlebar
    local titlebar_type = args.properties and args.properties.titlebars_enabled

    if titlebar_type == "toolbox" then
        titlebar = toolbox_titlebar
    else
        titlebar = default_titlebar
    end

    if titlebar then
        titlebar(client, args)
    end
end)
