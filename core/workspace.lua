local capi = Capi
local awful = require("awful")
local ruled = require("ruled")
local core_tag = require("core.tag")


---@class _Workspace
---@field items Workspace.Item[]
local M = {
    items = {},
}

do
    ---@class Workspace.Item
    ---@field key string
    ---@field factory fun(): tag
    ---@field container { value: tag }
    local Item = {}

    function Item:get_tag()
        local tag = self.container.value
        if not tag or not tag.activated then
            self.container.value = awful.tag.add(self.key, core_tag.build(self:factory()))
        end
        return self.container.value
    end

    function M.add(key, factory)
        M.items[key] = setmetatable({
            key = key,
            factory = factory,
            container = setmetatable({}, { __mode = "v" }),
        }, { __index = Item })
    end
end

---@param client client
---@param value string
---@param properties table
function ruled.client.high_priority_properties.workspace(client, value, properties)
    local item = M.items[value]
    local tag = item and item:get_tag()
    if not tag then
        return
    end

    if client.screen ~= tag.screen then
        client.screen = tag.screen
        properties.screen = tag.screen
    end

    client:tags { tag }
end

capi.screen.connect_signal("request::desktop_decoration", function(screen)
    capi.awesome.emit_signal("request::workspaces", screen)
end)

return M
