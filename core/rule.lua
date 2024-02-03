local capi = Capi
local table = table
local type = type
local ipairs = ipairs
local open = io.open
local awful = require("awful")
local ruled = require("ruled")
local gtimer = require("gears.timer")


local M = {}

function M.delayed_callback(callback, timeout)
    if type(callback) ~= "function" then
        return nil
    end
    return function(client)
        gtimer {
            timeout = tonumber(timeout) or 0.1,
            autostart = true,
            single_shot = true,
            callback = function()
                callback(client)
            end,
        }
    end
end

do
    local blacklisted_snids = setmetatable({}, { __mode = "v" })

    ruled.client.add_rule_source("fix_snid", function(client)
        if client.startup_id then
            blacklisted_snids[client.startup_id] = blacklisted_snids[client.startup_id] or client
            return
        end

        if not client.pid then
            return
        end

        local file = open("/proc/" .. client.pid .. "/environ", "rb")
        if not file then
            return
        end

        local snid = file:read("*all"):match("STARTUP_ID=([^\0]*)\0")

        file:close()

        if not snid or blacklisted_snids[snid] then
            return
        end
        blacklisted_snids[snid] = client

        client.startup_id = snid
    end, { "awful.spawn", "awful.rules" }, {})
end

do
    local dialog_placement = awful.placement.centered + awful.placement.no_offscreen

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

            properties.placement = function(c)
                dialog_placement(c, { parent = parent })
            end
        end
    end, { "awful.spawn", "awful.rules" }, {})
end

return M
