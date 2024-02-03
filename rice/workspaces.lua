local capi = Capi
local pairs = pairs
local tostring = tostring
local awful = require("awful")
local core_workspaces = require("core.workspace")
local layouts = require("rice.layouts")
local tags = require("rice.tags")
local gtable = require("gears.table")


---@class Rice.Workspaces
---@field factories table<string, fun(): table>[]
local workspaces = {
    factories = {
        hearthstone = function()
            return {
                name = "Hearthstone",
                screen = capi.screen.primary,
                volatile = true,
                layout = awful.layout.suit.floating,
            }
        end,
        chat = function()
            return {
                name = "Chat",
                volatile = true,
            }
        end,
        git = function()
            return {
                name = "Git",
                volatile = true,
            }
        end,
    },
}

capi.awesome.connect_signal("request::workspaces", function()
    for key, factory in workspaces.factories do
        core_workspaces.add(key, factory)
    end
end)

return workspaces
