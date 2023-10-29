local capi = Capi
local math = math
local infinity = math.huge
local find = string.find
local aclient = require("awful.client")
local amouse = require("awful.mouse")
local alayout = require("awful.layout")
local ugeometry = require("utils.geometry")


local tilted = {
    object = { is_tilted = true },
    layout_descriptor = require("layouts.tilted.layout_descriptor"),
    column_strategy = require("layouts.tilted.column_strategy"),
}

tilted.cursors = {
    { "cross", "sb_v_double_arrow", "cross" },
    { "sb_h_double_arrow", "pirate", "sb_h_double_arrow" },
    { "cross", "sb_v_double_arrow", "cross" },
}

local empty_padding = { left = 0, right = 0, top = 0, bottom = 0 }

tilted.mirror_padding = true

tilted.resize_only_adjacent = false

tilted.resize_jump_to_corner = false

local function any_button(buttons)
    for i = 1, #buttons do
        if buttons[i] then
            return true
        end
    end
    return false
end

local function get_titlebar_size(client)
    local _, top = client:titlebar_top()
    local _, bottom = client:titlebar_bottom()
    local _, left = client:titlebar_left()
    local _, right = client:titlebar_right()
    return {
        width = left + right,
        height = top + bottom,
    }
end

local function get_decoration_size(client, useless_gap)
    local border_width = 2 * (client.border_width + useless_gap)
    local decoration_size = get_titlebar_size(client)
    decoration_size.width = decoration_size.width + border_width
    decoration_size.height = decoration_size.height + border_width
    return decoration_size
end

function tilted.object:resize(screen, tag, client, corner)
    if not screen or not tag or not client or not client.valid then
        return
    end

    local layout_descriptor = tag.tilted_layout_descriptor
    if not layout_descriptor then
        return
    end

    local parameters = alayout.parameters(tag, screen)

    local column_descriptor, item_descriptor = layout_descriptor:find_client(client, parameters.clients)
    if not column_descriptor then
        return
    end

    local column_display_index = self.column_strategy.get_column_display_index(
        column_descriptor.index, layout_descriptor.size, self.is_reversed)
    local item_display_index = item_descriptor.index

    local oi = self.orientation_info

    local directions = { x = 0, y = 0 }
    local cursor_directions = { x = 0, y = 0 }
    if find(corner, "left", nil, true) then
        local direction = -1
        directions[oi.x] = self.is_horizontal
            and (column_display_index > 1 and direction or 0)
            or (item_display_index > 1 and direction or 0)
        cursor_directions.x = layout_descriptor.allow_padding
            and direction
            or directions[oi.x]
    elseif find(corner, "right", nil, true) then
        local direction = 1
        directions[oi.x] = self.is_horizontal
            and (column_display_index < layout_descriptor.size and direction or 0)
            or (item_display_index < column_descriptor.size and direction or 0)
        cursor_directions.x = layout_descriptor.allow_padding
            and direction
            or directions[oi.x]
    end
    if find(corner, "top", nil, true) then
        local direction = -1
        directions[oi.y] = self.is_horizontal
            and (item_display_index > 1 and direction or 0)
            or (column_display_index > 1 and direction or 0)
        cursor_directions.y = layout_descriptor.allow_padding
            and direction
            or directions[oi.y]
    elseif find(corner, "bottom", nil, true) then
        local direction = 1
        directions[oi.y] = self.is_horizontal
            and (item_display_index < column_descriptor.size and direction or 0)
            or (column_display_index < layout_descriptor.size and direction or 0)
        cursor_directions.y = layout_descriptor.allow_padding
            and direction
            or directions[oi.y]
    end

    local cursor = tilted.cursors[cursor_directions.y + 2][cursor_directions.x + 2]

    if cursor_directions.x == 0 and cursor_directions.y == 0 then
        capi.mousegrabber.run(function(coords) return any_button(coords.buttons) end, cursor)
        return
    end

    local full_workarea = parameters.workarea
    local workarea = ugeometry.shrink(full_workarea, layout_descriptor.allow_padding and layout_descriptor.padding[self] or nil)
    local useless_gap = parameters.useless_gap

    local initial_geometry = ugeometry.inflate(client:geometry(), client.border_width + useless_gap)
    initial_geometry = {
        x = initial_geometry.x,
        y = initial_geometry.y,
        width = (self.is_horizontal and column_descriptor or item_descriptor).factor * workarea.width,
        height = (self.is_horizontal and item_descriptor or column_descriptor).factor * workarea.height,
    }
    local initial_coords = {
        x = initial_geometry.x + ((cursor_directions.x + 1) * 0.5 * initial_geometry.width),
        y = initial_geometry.y + ((cursor_directions.y + 1) * 0.5 * initial_geometry.height),
    }

    local coords_offset
    if tilted.resize_jump_to_corner then
        capi.mouse.coords(initial_coords)
        coords_offset = { x = 0, y = 0 }
    else
        local mouse_coords = capi.mouse.coords()
        coords_offset = {
            x = initial_coords.x - mouse_coords.x,
            y = initial_coords.y - mouse_coords.y,
        }
    end

    layout_descriptor.resize = nil

    capi.mousegrabber.stop()
    capi.mousegrabber.run(function(coords)
        if not client.valid then
            layout_descriptor.resize = nil
            return false
        end

        local current_cd, current_id = layout_descriptor:find_client(client, aclient.tiled(screen))
        if column_descriptor ~= current_cd or item_descriptor ~= current_id then
            layout_descriptor.resize = nil
            return false
        end

        if not any_button(coords.buttons) then
            if layout_descriptor.resize then
                layout_descriptor.resize.apply = true
                alayout.arrange(screen)
            end
            return false
        end

        coords.x = coords.x + coords_offset.x
        coords.y = coords.y + coords_offset.y

        local size = {}

        if directions.x ~= 0 then
            local value = directions.x < 0
                and (initial_geometry[oi.x] + initial_geometry[oi.width] - coords[oi.x])
                or (coords[oi.x] - initial_geometry[oi.x])
            if value < 1 then
                value = 1
            end
            size.x = value
        end
        if directions.y ~= 0 then
            local value = directions.y < 0
                and (initial_geometry[oi.y] + initial_geometry[oi.height] - coords[oi.y])
                or (coords[oi.y] - initial_geometry[oi.y])
            if value < 1 then
                value = 1
            end
            size.y = value
        end

        if layout_descriptor.allow_padding then
            local padding = layout_descriptor.padding[self]
            if directions[oi.x] == 0 and cursor_directions.x ~= 0 then
                local value = cursor_directions.x > 0
                    and (full_workarea.x + full_workarea.width - coords.x)
                    or (coords.x - full_workarea.x)
                -- value = value - 32 -- Easier resetting
                if value < 0 then
                    value = 0
                end
                if tilted.mirror_padding then
                    padding.right = value
                    padding.left = value
                else
                    if cursor_directions.x > 0 then
                        padding.right = value
                    else
                        padding.left = value
                    end
                end
            end
            if directions[oi.y] == 0 and cursor_directions.y ~= 0 then
                local value = cursor_directions.y > 0
                    and (full_workarea.y + full_workarea.height - coords.y)
                    or (coords.y - full_workarea.y)
                -- value = value - 32 -- Easier resetting
                if value < 0 then
                    value = 0
                end
                if tilted.mirror_padding then
                    padding.bottom = value
                    padding.top = value
                else
                    if cursor_directions.y > 0 then
                        padding.bottom = value
                    else
                        padding.top = value
                    end
                end
            end
        end

        layout_descriptor.resize = {
            apply = false,
            column_display_index = column_display_index,
            item_display_index = item_display_index,
            size = size,
            directions = directions,
        }
        alayout.arrange(screen)
        return true
    end, cursor)
end

local min_fit_context = {
    must_resize = function(item) return item.size < item.min_size end,
    get_bounding_size = function(item) return item.min_size end,
    get_default_factor = function(item) return item.factor end,
}
local max_fit_context = {
    must_resize = function(item) return item.size > item.max_size end,
    get_bounding_size = function(item) return item.max_size end,
    get_default_factor = function(item, total_size) return item.size / total_size end,
}
local function fit_core(context, items, total_size)
    assert(total_size > 0)
    local count = #items
    local any_adjusted
    local adjusted = {}
    local factors = {}
    local available_size = total_size
    repeat
        any_adjusted = false
        local total_factor = 0
        for i = 1, count do
            local item = items[i]
            if not adjusted[i] then
                if context.must_resize(item) then
                    available_size = available_size - context.get_bounding_size(item)
                else
                    if not factors[i] then
                        factors[i] = context.get_default_factor(item, total_size)
                    end
                    total_factor = total_factor + factors[i]
                end
            end
        end
        for i = 1, count do
            local item = items[i]
            if not adjusted[i] then
                if context.must_resize(item) then
                    item.size = context.get_bounding_size(item)
                    adjusted[i] = true
                    any_adjusted = true
                else
                    factors[i] = total_factor > 0 and (factors[i] / total_factor) or 0
                    item.size = available_size * factors[i]
                end
            end
        end
    until not (any_adjusted and #adjusted < count)
end

local function fit(items, total_size)
    fit_core(min_fit_context, items, total_size)
    if items.any_max_size then
        fit_core(max_fit_context, items, total_size)
    end
end

local function resize_fit(items, start, direction, new_size, apply)
    local stop = tilted.resize_only_adjacent
        and start + direction
        or direction < 0 and 1 or #items
    if start == stop then
        return
    end

    local resize_item = items[start]
    if resize_item.size == new_size then
        return
    end

    local min_size = resize_item.min_size
    if new_size < min_size then
        new_size = min_size
    end
    local max_size = resize_item.max_size
    if new_size > max_size then
        new_size = max_size
    end

    local full_factor = resize_item.factor
    local full_size = resize_item.size
    local total_size = 0
    local total_min_size = 0
    local total_max_size = 0
    local new_items = {}
    for i = start + direction, stop, direction do
        local item = items[i]
        full_factor = full_factor + item.factor
        full_size = full_size + item.size
        total_size = total_size + item.size
        total_min_size = total_min_size + item.min_size
        total_max_size = total_max_size + item.max_size
        new_items[#new_items + 1] = {
            original_item = item,
            size = item.size,
            min_size = item.min_size,
            max_size = item.max_size,
        }
        if item.max_size < infinity then
            new_items.any_max_size = true
        end
    end
    assert(full_size > 0)
    assert(total_size > 0)

    if new_size > full_size - total_min_size then
        new_size = full_size - total_min_size
    end
    if new_size < full_size - total_max_size then
        new_size = full_size - total_max_size
    end

    local new_total_size = full_size - new_size
    if new_total_size < total_min_size then
        new_total_size = total_min_size
    end

    local new_total_factor = 0
    for i = 1, #new_items do
        local new_item = new_items[i]
        new_item.factor = new_item.size / total_size
        new_item.size = new_item.factor * new_total_size
        new_total_factor = new_total_factor + new_item.factor
    end
    for i = 1, #new_items do
        local new_item = new_items[i]
        new_item.factor = new_total_factor > 0 and (new_item.factor / new_total_factor) or 0
    end

    fit(new_items, new_total_size)

    new_items[0] = {
        original_item = resize_item,
        size = new_size,
    }
    for i = 0, #new_items do
        local new_item = new_items[i]
        new_item.original_item.factor = full_factor * (new_item.size / full_size)
        new_item.original_item.size = new_item.size
        if apply then
            new_item.original_item.descriptor.factor = new_item.original_item.factor
        end
    end
end

function tilted.object:arrange(parameters)
    local tag = parameters.tag
    local screen = parameters.screen and capi.screen[parameters.screen]
    if not tag and screen then
        tag = screen.selected_tag
    end
    if not tag or not screen then
        return
    end

    local clients = parameters.clients
    local layout_descriptor = tilted.layout_descriptor.update(tag, clients)

    local oi = self.orientation_info
    local full_workarea = parameters.workarea

    if layout_descriptor.allow_padding and not layout_descriptor.padding[self] then
        local factor = (1 - (tag.master_width_factor or 0.5)) / 2
        layout_descriptor.padding[self] = {
            [oi.left] = full_workarea[oi.width] * factor,
            [oi.right] = full_workarea[oi.width] * factor,
            [oi.top] = 0,
            [oi.bottom] = 0,
        }
    end

    local workarea = ugeometry.shrink(full_workarea, layout_descriptor.allow_padding and layout_descriptor.padding[self] or nil)
    local useless_gap = parameters.useless_gap

    local width = workarea[oi.width]
    local height = workarea[oi.height]

    local layout_data = {
        descriptor = layout_descriptor,
    }

    local max_size_behavior = false -- TODO infinity or zeso

    for column_display_index = 1, layout_descriptor.size do
        local column_index = self.column_strategy.get_column_index(
            column_display_index, layout_descriptor.size, self.is_reversed)
        local column_descriptor = layout_descriptor[column_index]
        local column_data = {
            descriptor = column_descriptor,
            factor = column_descriptor.factor,
            size = column_descriptor.factor * width,
            min_size = 0,
            max_size = max_size_behavior and infinity or 0,
        }

        if column_descriptor.size == 0 then
            column_data.min_size = 1
            column_data.max_size = infinity
        end

        for item_display_index = 1, column_descriptor.size do
            local item_index = item_display_index
            local item_descriptor = column_descriptor[item_index]
            local client = clients[item_descriptor.client_index]
            local decoration_size = get_decoration_size(client, useless_gap)

            local min_width, min_height, max_width, max_height
            if client.size_hints_honor then
                local size_hints = client.size_hints
                min_width = decoration_size[oi.width]
                    + math.max(1, size_hints["min_" .. oi.width] or size_hints["base_" .. oi.width] or 0)
                min_height = decoration_size[oi.height]
                    + math.max(1, size_hints["min_" .. oi.height] or size_hints["base_" .. oi.height] or 0)
                max_width = decoration_size[oi.width]
                    + (size_hints["max_" .. oi.width] or infinity)
                max_height = decoration_size[oi.height]
                    + (size_hints["max_" .. oi.height] or infinity)
            else
                min_width = decoration_size[oi.width] + 1
                min_height = decoration_size[oi.height] + 1
                max_width = infinity
                max_height = infinity
            end

            local item_data = {
                descriptor = item_descriptor,
                factor = item_descriptor.factor,
                size = item_descriptor.factor * height,
                min_size = min_height,
                max_size = max_height,
            }

            if item_data.max_size < infinity then
                column_data.any_max_size = true
            end
            column_data[item_display_index] = item_data

            if column_data.min_size < min_width then
                column_data.min_size = min_width
            end
            if column_data.max_size < max_width then
                column_data.max_size = max_width
            end
        end

        if column_data.max_size < infinity then
            layout_data.any_max_size = true
        end
        layout_data[column_display_index] = column_data
    end

    fit(layout_data, math.max(1, width))
    for i = 1, #layout_data do
        fit(layout_data[i], math.max(1, height))
    end

    local resize = layout_descriptor.resize
    if resize then
        if resize.size.x and resize.directions.x ~= 0 then
            resize_fit(layout_data, resize.column_display_index,
                resize.directions.x, resize.size.x, resize.apply)
        end
        if resize.size.y and resize.directions.y ~= 0 then
            resize_fit(layout_data[resize.column_display_index], resize.item_display_index,
                resize.directions.y, resize.size.y, resize.apply)
        end
        if resize.apply then
            layout_descriptor.resize = nil
        end
    end

    local x = workarea[oi.x]
    for column_display_index = 1, layout_descriptor.size do
        local column_index = self.column_strategy.get_column_index(
            column_display_index, layout_descriptor.size, self.is_reversed)
        local column_descriptor = layout_descriptor[column_index]
        local column_data = layout_data[column_display_index]
        local column_width = column_data.size

        local y = workarea[oi.y]
        for item_display_index = 1, column_descriptor.size do
            local item_index = item_display_index
            local item_descriptor = column_descriptor[item_index]
            local item_data = column_data[item_display_index]
            local item_height = item_data.size

            parameters.geometries[clients[item_descriptor.client_index]] = {
                [oi.width] = column_width,
                [oi.height] = item_height,
                [oi.x] = x,
                [oi.y] = y,
            }

            y = y + item_height
        end
        x = x + column_width
    end
end

function tilted.object.skip_gap(tiled_client_count, tag)
    return tiled_client_count == 1 and tag.master_fill_policy == "expand"
end

---@class Tilted.new.args
---@field name string # Unique layout name.
---@field is_horizontal? boolean # Default: `true`
---@field is_reversed? boolean # Default: `false`
---@field column_strategy? Tilted.ColumnStrategy # Default: `linear`

---@param args? string|Tilted.new.args
---@return awful.layout
function tilted.new(args)
    if type(args) == "string" then
        args = { name = args }
    end
    args = args or {}
    args.name = args.name or "tilted"

    local self = {
        name = args.name,
        is_horizontal = args.is_horizontal ~= false,
        is_reversed = not not args.is_reversed,
        column_strategy = args.column_strategy or tilted.column_strategy.linear,
    }

    local oi = {}
    oi.x = self.is_horizontal and "x" or "y"
    oi.y = self.is_horizontal and "y" or "x"
    oi.width = self.is_horizontal and "width" or "height"
    oi.height = self.is_horizontal and "height" or "width"
    oi.left = self.is_horizontal and "left" or "top"
    oi.right = self.is_horizontal and "right" or "bottom"
    oi.top = self.is_horizontal and "top" or "left"
    oi.bottom = self.is_horizontal and "bottom" or "right"
    self.orientation_info = oi

    function self.arrange(parameters)
        tilted.object.arrange(self, parameters)
    end

    return setmetatable(self, { __index = tilted.object })
end

amouse.resize.add_enter_callback(function(client, args)
    if client.floating then
        return
    end
    local screen = client.screen
    local tag = screen.selected_tag
    local layout = tag and tag.layout or nil
    if layout and layout.is_tilted then
        layout:resize(screen, tag, client, args.corner)
        return false
    end
end, "mouse.resize")

return tilted
