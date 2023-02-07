local capi = {
    client = client,
}
local setmetatable = setmetatable
local ipairs = ipairs
local table = table
local awful = require("awful")
local beautiful = require("beautiful")
local wibox = require("wibox")
local binding = require("io.binding")
local mod = binding.modifier
local btn = binding.button
local dpi = dpi
local aplacement = require("awful.placement")
local amousec = require("awful.mouse.client")
local capsule = require("widget.capsule")
local mebox = require("widget.mebox")
local client_menu_template = require("ui.menu.templates.client")
local config = require("config")


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

local function titlebar_button(client, action, normal_args, toggle_args)
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
            and beautiful.titlebar.button.opacity_focus
            or beautiful.titlebar.button.opacity_normal

        local icon_widget = button.widget
        icon_widget:set_image(args.icon)
        icon_widget:set_stylesheet("path, .fill { fill: " .. args.style.foreground .. "; }")
    end

    button.buttons = binding.awful_buttons {
        binding.awful({}, btn.left, nil, function()
            action(client, get_state())
        end)
    }

    normal_args.style = normal_args.style or beautiful.titlebar.button.styles.normal
    if toggle_args then
        toggle_args.style = toggle_args.style or beautiful.titlebar.button.styles.active
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

    local template = client_menu_template.new()
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
    if args.properties.titlebars_factory then
        args.properties.titlebars_factory(client, args.properties)
        return
    end
    awful.titlebar(client, {
        position = "top",
        size = beautiful.titlebar.height,
    }).widget = {
        layout = wibox.container.margin,
        margins = beautiful.titlebar.paddings,
        {
            layout = wibox.layout.align.horizontal,
            expand = "inside",
            {
                layout = wibox.layout.fixed.horizontal,
                spacing = beautiful.titlebar.button.spacing,
                titlebar_button(client, toggle_client_menu,
                    { icon = beautiful.titlebar.button.icons.menu, }),
            },
            {
                widget = awful.titlebar.widget.titlewidget(client),
                halign = "center",
                valign = "center",
                buttons = binding.awful_buttons {
                    binding.awful({}, btn.left, function()
                        client:activate { context = "titlebar" }
                        amousec.move(client)
                    end),
                    binding.awful({}, btn.right, function()
                        client:activate { context = "titlebar" }
                        amousec.resize(client)
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
                    { icon = beautiful.titlebar.button.icons.floating, },
                    {
                        property = "property::floating",
                        get_state = function(c) return c.floating end,
                    }),
                titlebar_button(client, function(c, state) c.ontop = not state end,
                    { icon = beautiful.titlebar.button.icons.on_top, },
                    {
                        property = "property::ontop",
                        get_state = function(c) return c.ontop end,
                    }),
                titlebar_button(client, function(c, state) c.sticky = not state end,
                    { icon = beautiful.titlebar.button.icons.sticky, },
                    {
                        property = "property::sticky",
                        get_state = function(c) return c.sticky end,
                    }),
                titlebar_button(client, function(c, state) c.minimized = not state end,
                    { icon = beautiful.titlebar.button.icons.minimize, },
                    {
                        property = "property::minimized",
                        get_state = function(c) return c.minimized end,
                    }),
                titlebar_button(client, function(c, state) c.maximized = not state end,
                    { icon = beautiful.titlebar.button.icons.maximize, },
                    {
                        property = "property::maximized",
                        get_state = function(c) return c.maximized end,
                    }),
                titlebar_button(client, function(c) c:kill() end,
                    {
                        style = beautiful.titlebar.button.styles.close,
                        icon = beautiful.titlebar.button.icons.close,
                    }),
            },
        },
    }
end)
