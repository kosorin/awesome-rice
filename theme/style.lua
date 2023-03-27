local assert = assert
local pairs = pairs
local gtable = require("gears.table")


---@alias style table<string, any>

---@class style_property.base
---@field fallback? any
---@field convert? fun(value: any): any

---@class style_property.proxy : style_property.base
---@field proxy true

---@class style_property.custom : style_property.base
---@field emit_layout_changed? boolean
---@field emit_redraw_needed? boolean

---@class style_property.child
---@field id? string
---@field property string

---@alias style_property
---| style_property.proxy
---| style_property.custom
---| style_property.child

---@alias style_properties table<string, style_property>


local noice = {
    ---Special values used in styles. Translated into actual values when applying the style.
    value = {
        Nil = { name = "Nil" },
        Keep = { name = "Keep" },
        Default = { name = "Default" },
    },
}


---@class stylable.data
---@field default style
---@field current style
---@field root? wibox.widget.base

---@class stylable : gears.object
---@field package _style stylable.data
---@field package get_style_properties fun(): style_properties
noice.object = {}

---@param default_style style
---@param root? wibox.widget.base
function noice.object:initialize_style(default_style, root)
    self._style = {
        default = default_style,
        current = {},
        root = root,
    }
    self:reset_style()
end

---@param value any
---@param property style_property
---@return any
local function parse_value(value, property)
    if value == noice.value.Nil then
        value = nil
    elseif value == noice.value.Default then
        value = property.fallback
    elseif value == noice.value.Keep then
        value = nil
    end
    return value
end

---@param self stylable
---@param property_name string
---@param property style_property
---@return any
local function get_value(self, property_name, property)
    if property.proxy then
        return self[property_name]
    else
        return self._style.current[property_name]
    end
end

---@param self stylable
---@param property_name string
---@param property style_property
---@param value any
local function set_value(self, property_name, property, value)
    if value == noice.value.Nil then
        value = nil
    else
        if value ~= nil then
            if value == noice.value.Default then
                value = parse_value(self._style.default[property_name], property)
            elseif value == noice.value.Keep then
                return
            end
        end
        if value == nil then
            value = property.fallback
        end
    end

    if property.convert then
        value = property.convert(value)
    end

    if property.proxy then
        self[property_name] = value
    else
        if self._style.current[property_name] == value then
            return
        end
        self._style.current[property_name] = value
        self:emit_signal("property::" .. property_name, value)
        if property.property then
            assert(self._style.root)
            local widget = property.id
                and self._style.root:get_children_by_id(property.id)[1]
                or self._style.root
            if widget then
                widget[property.property] = value
            end
        else
            if property.emit_layout_changed then
                self:emit_signal("widget::layout_changed")
            end
            if property.emit_redraw_needed then
                self:emit_signal("widget::redraw_needed")
            end
        end
    end
end

---@param self stylable
---@param style style
local function update_style(self, style)
    if not style then
        return
    end
    for property_name, property in pairs(self.get_style_properties()) do
        local value = style[property_name]
        if value ~= nil then
            set_value(self, property_name, property, value)
        end
    end
end

---@param style style
function noice.object:apply_style(style)
    update_style(self, style)
end

function noice.object:reset_style()
    update_style(self, self._style.default)
end

---@param stylable stylable
---@param style_properties style_properties
function noice.define_style(stylable, style_properties)
    function stylable.get_style_properties()
        return style_properties
    end

    gtable.crush(stylable, noice.object, true)

    for property_name, property in pairs(style_properties) do
        if not property.proxy then
            local getter = "get_" .. property_name
            local setter = "set_" .. property_name
            assert(not stylable[getter] and not stylable[setter],
                "Property '" .. property_name .. "' already exists.")

            stylable[getter] = function(self)
                return get_value(self, property_name, property)
            end
            stylable[setter] = function(self, value)
                set_value(self, property_name, property, value)
            end
        end
    end
end

return noice
