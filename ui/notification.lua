-- DEPENDENCIES: lua-socket (optional)

local os_date = os.date
local _, socket = pcall(require, "socket")
local awful = require("awful")
local naughty = require("naughty")
local wibox = require("wibox")
local ruled = require("ruled")
local beautiful = require("theme.theme")
local capsule = require("widget.capsule")
local gtimer = require("gears.timer")
local binding = require("core.binding")
local mod = binding.modifier
local btn = binding.button
local config = require("rice.config")
local gcolor = require("gears.color")
local ucolor = require("utils.color")
local css = require("utils.css")

local get_time = socket and socket.gettime


naughty.connect_signal("request::display", function(n)
    local box = naughty.layout.box {
        notification = n,
        bg = n.style.bg,
        fg = n.style.fg,
        border_color = n.style.border_color,
        border_width = n.style.border_width,
        shape = n.style.shape,
        widget_template = {
            widget = wibox.container.constraint,
            {
                widget = wibox.layout.fixed.vertical,
                {
                    widget = wibox.container.background,
                    bg = n.style.header_bg,
                    fg = n.style.header_fg,
                    {
                        layout = wibox.layout.fixed.horizontal,
                        reverse = true,
                        fill_space = true,
                        {
                            widget = wibox.container.margin,
                            margins = n.style.header_paddings,
                            {
                                widget = naughty.widget.title,
                                valign = "top",
                            },
                        },
                        {
                            widget = wibox.container.margin,
                            margins = n.style.header_paddings,
                            {
                                widget = wibox.widget.textbox,
                                opacity = 0.5,
                                text = os_date("%H:%M"):gsub("^0", ""),
                                valign = "top",
                            },
                        },
                        {
                            widget = wibox.container.margin,
                            margins = n.style.close_button_margins,
                            {
                                layout = wibox.layout.fixed.vertical,
                                {
                                    widget = wibox.container.constraint,
                                    strategy = "max",
                                    width = n.style.close_button_size,
                                    height = n.style.close_button_size,
                                    {
                                        id = "#close",
                                        widget = capsule,
                                        {
                                            widget = wibox.widget.imagebox,
                                            image = beautiful.icon("close.svg"),
                                            resize = true,
                                        },
                                    },
                                },
                            },
                        },
                    },
                },
                {
                    id = "#timer_bar",
                    widget = wibox.widget.progressbar,
                    color = n.style.timer_bg,
                    background_color = n.style.header_border_color,
                    forced_height = n.style.timer_height,
                    value = 0,
                    max_value = 1,
                },
                {
                    widget = wibox.container.margin,
                    margins = n.style.paddings,
                    {
                        layout = wibox.layout.fixed.horizontal,
                        fill_space = true,
                        spacing = n.style.icon_spacing,
                        {
                            widget = naughty.widget.icon,
                        },
                        {
                            widget = naughty.widget.message,
                            valign = "top",
                        },
                    },
                },
                {
                    widget = wibox.container.margin,
                    margins = n.style.actions_paddings,
                    visible = #n.actions > 0,
                    {
                        widget = naughty.list.actions,
                        base_layout = wibox.widget {
                            layout = wibox.layout.flex.horizontal,
                            spacing = n.style.actions_spacing,
                        },
                        style = {
                            underline_normal = false,
                            underline_selected = true,
                        },
                        widget_template = {
                            widget = capsule,
                            {
                                id = "text_role",
                                widget = wibox.widget.textbox,
                                halign = "center",
                            },
                        },
                    },
                },
            },
        },
    }

    -- Reset default buttons
    box.buttons = {}

    local close_button = box.widget:get_children_by_id("#close")[1] --[[@as Capsule]]
    close_button.fg = ucolor.transparent
    close_button:connect_signal("property::fg", function(button, fg)
        button.widget:set_stylesheet(css.style { path = { fill = gcolor.ensure_pango_color(fg) } })
    end)
    close_button:apply_style(n.style.close_button)
    close_button.buttons = binding.awful_buttons {
        binding.awful({}, btn.left, nil, function()
            local notification = box._private.notification[1]
            if notification then
                notification:destroy()
            end
        end),
    }

    if get_time then
        local timer_bar = box.widget:get_children_by_id("#timer_bar")[1]
        local timer
        local function stop_timer()
            if timer then
                timer:stop()
                timer = nil
            end
            timer_bar.value = 0
        end
        local function update_timeout()
            stop_timer()
            local timeout = tonumber(n.timeout) or 0
            local start = get_time()
            if timeout > 0 then
                timer = gtimer {
                    timeout = 1 / 30,
                    autostart = true,
                    call_now = true,
                    callback = function()
                        local now = get_time()
                        local value = 1 - ((now - start) / timeout)
                        if value <= 0 then
                            value = 0
                        end
                        timer_bar.value = value
                        if value == 0 then
                            stop_timer()
                        end
                    end,
                }
            end
        end
        n:connect_signal("destroyed", stop_timer)
        n:connect_signal("property::timeout", update_timeout)
        update_timeout()
    end
end)


ruled.notification.connect_signal("request::rules", function()
    ruled.notification.append_rule {
        rule = {},
        properties = {
            screen = awful.screen.preferred,
            max_width = beautiful.notification.width,
            style = beautiful.notification.default_style,
        },
    }
    ruled.notification.append_rule {
        rule = { urgency = "low" },
        properties = {
            implicit_timeout = 8,
        },
    }
    ruled.notification.append_rule {
        rule = { urgency = "normal" },
        properties = {
            implicit_timeout = 30,
        },
    }
    ruled.notification.append_rule {
        rule = { urgency = "critical" },
        properties = {
            never_timeout = true,
            style = beautiful.notification.styles.critical,
        },
    }
    ruled.notification.append_rule {
        rule = { category = "awesome.power.timer" },
        properties = {
            never_timeout = false,
        },
    }
end)
