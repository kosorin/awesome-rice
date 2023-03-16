local capi = Capi
local math = math
local setmetatable = setmetatable
local alayout = require("awful.layout")


local layout_descriptor = { object = {} }

function layout_descriptor.object:find_client(client, clients)
    if not client or not clients then
        return
    end

    local client_index

    for i = 1, #clients do
        if clients[i] == client then
            client_index = i
            break
        end
    end

    if client_index then
        for i = 1, self.size do
            local cd = self[i]
            if cd.from <= client_index and client_index <= cd.to then
                local id = cd[client_index - cd.from + 1]
                if id.client_index == client_index and id.window_id == client.window then
                    return cd, id
                end
                break
            end
        end
    end
end

local function normalize_factors(descriptor)
    local size = descriptor.size
    if size < 1 then
        return
    end

    local last_size = descriptor.last_size or 1
    if last_size < 1 then
        last_size = 1
    end

    local total_factor = 0

    for i = 1, size do
        local item_descriptor = descriptor[i]
        if not item_descriptor.factor then
            item_descriptor.factor = 1 / last_size
        end
        total_factor = total_factor + item_descriptor.factor
    end

    if total_factor > 0 then
        for i = 1, #descriptor do
            local item_descriptor = descriptor[i]
            item_descriptor.factor = item_descriptor.factor / total_factor
        end
    end
end

function layout_descriptor.new(tag)
    return setmetatable({
        tag = tag,
        padding = setmetatable({}, { __mode = "k" }),
    }, { __index = layout_descriptor.object })
end

function layout_descriptor.update(tag, clients)
    local is_new = false
    local self = tag.tilted_layout_descriptor

    if not self then
        is_new = true
        self = layout_descriptor.new(tag)
    end

    local column_index = 1
    local client_index = 1

    local function update_next_column_descriptor(size, is_primary)
        local column_descriptor = self[column_index]
        if not column_descriptor then
            column_descriptor = { index = column_index }
            self[column_index] = column_descriptor
        end
        column_descriptor.is_primary = is_primary
        column_descriptor.from = client_index
        column_descriptor.to = client_index + size - 1
        column_descriptor.last_size = column_descriptor.size
        column_descriptor.size = size

        for item_index = 1, size do
            local item_descriptor = column_descriptor[item_index]
            if not item_descriptor then
                item_descriptor = { index = item_index }
                column_descriptor[item_index] = item_descriptor
            end
            item_descriptor.client_index = client_index
            item_descriptor.window_id = clients[client_index].window

            client_index = client_index + 1
        end

        column_index = column_index + 1
    end

    local total_count = #clients
    local primary_count = total_count <= tag.master_count and total_count or tag.master_count
    local secondary_count = total_count - primary_count
    local secondary_column_count = secondary_count <= tag.column_count and secondary_count or tag.column_count

    if primary_count > 0 then
        update_next_column_descriptor(primary_count, true)
    end

    if secondary_count > 0 and secondary_column_count > 0 then
        local column_size = math.floor(secondary_count / secondary_column_count)
        local extra_count = math.fmod(secondary_count, secondary_column_count)
        local last_simple_column = column_index - 1 + (secondary_column_count - extra_count)
        repeat
            local size = column_size
            if column_index > last_simple_column then
                size = size + 1
            end
            update_next_column_descriptor(size)
        until client_index > total_count
    end

    local size = column_index - 1
    self.from = size > 0 and 1 or 0
    self.to = size
    self.last_size = self.size
    self.size = size
    self.allow_padding = tag.master_fill_policy == "master_width_factor"
        and size == 1
        and self[1].is_primary

    for i = 1, self.size do
        normalize_factors(self[i])
    end
    normalize_factors(self)

    if is_new then
        tag.tilted_layout_descriptor = self
    else
        tag:emit_signal("property::tilted_layout_descriptor")
    end

    return self
end

local function arrange_tag(tag)
    alayout.arrange(tag.screen)
end

capi.tag.connect_signal("property::tilted_layout_descriptor", arrange_tag)

return layout_descriptor
