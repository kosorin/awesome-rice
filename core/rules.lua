local capi = Capi
local table = table
local awful = require("awful")
local beautiful = require("theme.theme")
local ruled = require("ruled")
local binding = require("io.binding")
local helper_client = require("utils.client")
local mod = binding.modifier
local btn = binding.button
local dpi = Dpi


local blacklisted_snid = setmetatable({}, { __mode = "v" })
ruled.client.add_rule_source("fix_snid", function(client)
    if client.startup_id then
        blacklisted_snid[client.startup_id] = blacklisted_snid[client.startup_id] or client
        return
    end

    if not client.pid then
        return
    end

    local file = io.open("/proc/" .. client.pid .. "/environ", "rb")
    if not file then
        return
    end

    local snid = file:read("*all"):match("STARTUP_ID=([^\0]*)\0")
    file:close()

    if not snid or blacklisted_snid[snid] then
        return
    end
    blacklisted_snid[snid] = client

    client.startup_id = snid
end, { "awful.spawn", "awful.rules" }, {})


ruled.client.add_rule_source("fix_dialog", function(client, properties)
    if client.type ~= "dialog" then
        return
    end

    if not properties.placement then
        local parent = client.transient_for
        if not parent and client.pid then
            local screen = properties.screen
                and (type(properties.screen) == "function"
                    and capi.screen[properties.screen(client, properties)]
                    or capi.screen[properties.screen])
                or nil
            if screen then
                local possible_parents = {}
                for _, cc in ipairs(screen.clients) do
                    if client ~= cc and client.pid == cc.pid then
                        table.insert(possible_parents, cc)
                    end
                end
                parent = possible_parents[1]
            end
        end

        local placement = awful.placement.centered + awful.placement.no_offscreen
        placement(client, { parent = parent })
    end
end, { "awful.spawn", "awful.rules" }, {})


ruled.client.connect_signal("request::rules", function()
    ----------------------------------------------------------------------------------------------------
    ruled.client.append_rule {
        id = "global",
        rule = {},
        properties = {
            screen = awful.screen.preferred,
            focus = awful.client.focus.filter,
            titlebars_enabled = DEBUG,
            raise = true,
            shape = beautiful.client.shape,
        },
        callback = function(client)
            awful.client.setslave(client)
        end,
    }
    ruled.client.append_rule {
        id = "floating",
        rule_any = {
            class = {
                "Arandr",
            },
            name = {
                "Event Tester",
            },
            role = {
                "pop-up",
            },
        },
        properties = {
            floating = true,
            titlebars_enabled = true,
        },
    }
    ruled.client.append_rule {
        id = "picture_in_picture",
        rule_any = {
            name = {
                "Picture in picture",
                "Picture-in-Picture",
            },
        },
        properties = {
            floating = true,
            ontop = true,
            sticky = true,
            placement = function(client)
                awful.placement.bottom_right(client, {
                    honor_workarea = true,
                    margins = dpi(32),
                })
            end,
        },
    }
    ruled.client.append_rule {
        id = "size_hints",
        rule_any = {
            class = {
                "XTerm",
            },
        },
        properties = {
            size_hints_honor = false,
        },
    }
    ----------------------------------------------------------------------------------------------------
    ruled.client.append_rule {
        rule = {
            class = "SpeedCrunch",
        },
        properties = {
            floating = true,
            ontop = true,
            titlebars_enabled = true,
        },
    }
    ----------------------------------------------------------------------------------------------------
    ruled.client.append_rule {
        rule = {
            class = "1Password",
        },
        properties = {
            floating = true,
            titlebars_enabled = true,
        },
    }
    ruled.client.append_rule {
        rule = {
            class = "1Password",
            name = "Quick Access",
        },
        properties = {
            skip_taskbar = true,
            titlebars_enabled = "toolbox",
        },
    }
    ----------------------------------------------------------------------------------------------------
    ruled.client.append_rule {
        rule = {
            class = "qr_code_clipboard",
        },
        properties = {
            floating = true,
            ontop = true,
            placement = awful.placement.centered,
            skip_taskbar = true,
            titlebars_enabled = "toolbox",
            buttons = binding.awful_buttons {
                binding.new {
                    modifiers = { mod.super },
                    triggers = btn.left,
                    on_press = function(_, client)
                        client:activate { context = "mouse_click" }
                        helper_client.mouse_move(client)
                    end,
                },
                binding.new {
                    modifiers = { mod.super },
                    triggers = btn.right,
                    on_press = function(_, client)
                        client:activate { context = "mouse_click" }
                        helper_client.mouse_resize(client)
                    end,
                },
            },
        },
    }
    ----------------------------------------------------------------------------------------------------
    ruled.client.append_rule {
        rule = {
            class = "Dragon-drop",
        },
        properties = {
            floating = true,
            ontop = true,
            sticky = true,
            placement = awful.placement.centered,
            titlebars_enabled = "toolbox",
            border_width = dpi(4),
            border_color = beautiful.common.secondary_bright,
            shape = false,
        },
    }
    ----------------------------------------------------------------------------------------------------
    ruled.client.append_rule {
        rule = {
            class = "Xephyr",
        },
        properties = {
            floating = false,
        },
    }
    ----------------------------------------------------------------------------------------------------
end)
