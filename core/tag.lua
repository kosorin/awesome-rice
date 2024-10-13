local capi = Capi
local type = type
local ipairs = ipairs
local ruled = require("ruled")
local ascreen = require("awful.screen")
local atag = require("awful.tag")
local gtable = require("gears.table")


local M = {}

---@param args table
---@return table
function M.build(args)
    args = args or {}
    args.screen = args.screen or capi.screen.primary
    args.name = args.name or ""

    local tag = {}
    capi.awesome.emit_signal("tag::build", tag, args)
    gtable.crush(tag, args)
    return tag
end

---@param tag_index integer
---@param screen? screen
---@return tag?
function M.get_or_create(tag_index, screen)
    screen = screen or ascreen.focused()
    if not screen then
        return nil
    end
    local tag = screen.tags[tag_index]
    if not tag then
        tag = atag.add(nil, M.build {
            screen = screen,
        })
    end
    return tag
end

function ruled.client.high_priority_properties.new_tag(client, value, properties)
    local value_type = type(value)

    local args
    if value_type == "boolean" then
        args = {
            name = client.class,
            screen = client.screen,
        }
    elseif value_type == "string" then
        args = {
            name = value,
            screen = client.screen,
        }
    elseif value_type == "table" then
        args = gtable.clone(value)
        args.name = args.name or client.class
        args.screen = args.screen or client.screen
    else
        return
    end

    local tag = atag.add(nil, M.build(args))

    properties.screen = tag.screen
    client.screen = tag.screen
    client:tags { tag }
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
