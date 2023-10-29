local capi = Capi
local ipairs = ipairs
local awful = require("awful")
local gtable = require("gears.table")


local M = {}

function M.build(args)
    local tag = {}
    capi.awesome.emit_signal("tag::build", tag)
    return gtable.crush(tag, args or {})
end

function M.add(args)
    args = args or {}
    args.screen = args.screen or capi.screen.primary
    args.name = args.name or tostring(1 + (# args.screen.tags or 0))
    return awful.tag.add(args.name, M.build(args))
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
