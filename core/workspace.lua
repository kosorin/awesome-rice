local capi = Capi
local atag = require("awful.tag")
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
            tag = atag.add(nil, core_tag.build(self:factory()))
            self.container.value = tag
        end
        return tag
    end

    ---@param key string
    ---@param factory fun(): tag
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

    properties.screen = tag.screen
    client.screen = tag.screen
    client:tags { tag }
    return tag
end

return M
