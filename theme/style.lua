local setmetatable = setmetatable
local type = type
local pairs = pairs
local gtable = require("gears.table")


local noice = {
    object = {},
    value = {
        Nil = { name = "Nil" },
        Keep = { name = "Keep" },
        Default = { name = "Default" },
    },
}

local function parse_value(value, property_descriptor)
    if value == noice.value.Nil then
        value = nil
    elseif value == noice.value.Default then
        value = property_descriptor.fallback
    elseif value == noice.value.Keep then
        value = nil
    end
    return value
end

local function get_value(self, property_name, property_descriptor)
    if property_descriptor.proxy then
        return self[property_name]
    else
        return self._style.data[property_name]
    end
end

local function set_value(self, property_name, property_descriptor, value)
    if value == noice.value.Nil then
        value = nil
    else
        if value ~= nil then
            if value == noice.value.Default then
                value = parse_value(self._style.default[property_name], property_descriptor)
            elseif value == noice.value.Keep then
                return
            end
        end
        if value == nil then
            value = property_descriptor.fallback
        end
    end
    if property_descriptor.proxy then
        self[property_name] = value
    else
        if self._style.data[property_name] == value then
            return
        end
        self._style.data[property_name] = value
        self:emit_signal("property::" .. property_name, value)
        if property_descriptor.property then
            local widget = property_descriptor.id
                and self._style.root:get_children_by_id(property_descriptor.id)[1]
                or self._style.root
            if widget then
                widget[property_descriptor.property] = value
            end
        end
    end
end

local function update_style(self, style)
    if not style then
        return
    end
    for property_name in pairs(self._style_properties) do
        local value = style[property_name]
        if value ~= nil then
            self:set_style_value(property_name, value)
        end
    end
end

function noice.object:apply_style(style)
    update_style(self, style)
end

function noice.object:reset_style()
    update_style(self, self._style.default)
end

function noice.object:get_style_value(property_name)
    local property_descriptor = self._style_properties[property_name]
    if property_descriptor then
        return get_value(self, property_name, property_descriptor)
    end
end

function noice.object:set_style_value(property_name, value)
    local property_descriptor = self._style_properties[property_name]
    if property_descriptor then
        set_value(self, property_name, property_descriptor, value)
    end
end

function noice.initialize_style(instance, root, default_style)
    instance._style = {
        root = root,
        default = default_style,
        data = {},
    }

    gtable.crush(instance, noice.object, true)

    instance:reset_style()
end

function noice.define_style_properties(module, style_properties)
    module._style_properties = style_properties
    if not style_properties then
        return
    end
    for property_name, property_descriptor in pairs(module._style_properties) do
        if not property_descriptor.proxy then
            assert(not module["get_" .. property_name] and not module["set_" .. property_name],
                "Property '" .. property_name .. "' already exists.")
            module["get_" .. property_name] = function(self)
                return get_value(self, property_name, property_descriptor)
            end
            module["set_" .. property_name] = function(self, value)
                set_value(self, property_name, property_descriptor, value)
            end
        end
    end
end

return noice
