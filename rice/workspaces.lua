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
            }
        end,
        chat = function()
            return {
                name = "Chat",
            }
        end,
        git = function()
            return {
                name = "Git",
            }
        end,
    },
}

for key, factory in pairs(workspaces.factories) do
    core_workspaces.add(key, factory)
end

return workspaces
