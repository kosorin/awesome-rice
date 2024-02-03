local capi = Capi
local ipairs = ipairs
local tostring = tostring
local gtable = require("gears.table")


local M = {}

---@param args table
---@return table
function M.build(args)
    args = args or {}
    args.screen = args.screen or capi.screen.primary
    args.name = args.name or tostring(1 + #args.screen.tags)

    local tag = {}
    capi.awesome.emit_signal("tag::build", tag, args)
    gtable.crush(tag, args)
    return tag
end

capi.screen.connect_signal("tag::history::update", function(screen)
    for _, tag in ipairs(screen.tags) do
        if tag.selected then
            tag.visited = true
        elseif tag.volatile and tag.visited and #tag:clients() == 0 then
            tag:delete()
        end
    end
end)

return M
