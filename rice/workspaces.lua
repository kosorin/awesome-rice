local capi = Capi
local pairs = pairs
local core_workspaces = require("core.workspace")


---@class Rice.Workspaces
---@field factories table<string, fun(): tag>
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
