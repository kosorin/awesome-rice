local pcall = pcall
local setmetatable = setmetatable
local rawget = rawget
local rawset = rawset
local assert = assert
local type = type
local pairs, ipairs = pairs, ipairs
local protected_call = require("gears.protected_call")
local gtable = require("gears.table")
local manager = require("theme.manager")
local Nil = require("theme.nil")


local M = {}

---@class stylable.property_changing_args
---@field property stylable.property
---@field value any
---@field cancel? boolean

---@class stylable.context
---@field element string
---@field id? string
---@field classes table<string, boolean>
---@field pseudo_classes table<string, boolean>
---@field hierarchy { root?: wibox, parent?: wibox.hierarchy, index?: integer }

---@class stylable.property
---@field name string
---@field value any
---@field empty boolean # If `true` then `value` should be `nil`
---@field override boolean
---@field descriptor? style.property_descriptor

---@class stylable.data
---@field context stylable.context
---@field properties table<string, stylable.property>
---@field ignore_override integer
---@field local_style? style
---@field ignore_hierarchy? boolean # TODO

---@class stylable : gears.object, widget_container
---@field _stylable stylable.data
M.stylable = {}

function M.stylable:ignore_override(callback)
    if not callback then
        return
    end
    self._stylable.ignore_override = self._stylable.ignore_override + 1
    protected_call(callback)
    self._stylable.ignore_override = self._stylable.ignore_override - 1
end

---@param name string
---@param value any
---@return boolean
---@return any
function M.stylable:set_style_value(name, value)
    local property = self._stylable.properties[name]
    if not property then
        return false
    end

    if self._stylable.ignore_override == 0 then
        property.override = true
    end

    if property.descriptor.coerce then
        value = property.descriptor.coerce(value, self, property)
    end

    if not property.empty then
        if property.descriptor.equality_comparer then
            if property.descriptor.equality_comparer(property.value, value, self, property) then
                return false
            end
        elseif property.value == value then
            return false
        end
    end

    -- if self._stylable.context.element == "wibox" then
    -- if name == "height" then
    --     print(("> [%s] %s.%s = %s %d"):format(self._stylable.context.id, self._stylable.context.element, name, value, self._stylable.ignore_override))
    -- end
    property.value = value
    property.empty = false
    return true, value
end

---@param name string
---@return any
function M.stylable:get_style_value(name)
    local property = self._stylable.properties[name]

    local value

    if not property or property.empty then
        value = nil
    end

    value = property.value

    if value == nil and property.descriptor.fallback then
        value = property.descriptor.fallback(self, property)
    end

    return value
end

function M.stylable:clear_local_style()
    for _, property in pairs(self._stylable.properties) do
        property.override = false
    end

    self._stylable.local_style = nil

    self:request_style(true)
end

---@param style? style
function M.stylable:set_style(style)
    if self._stylable.local_style == style then
        return
    end

    self._stylable.local_style = style

    self:request_style()
end

---@param id? string
function M.stylable:set_sid(id)
    if self._stylable.context.id == id then
        return
    end

    self._stylable.context.id = id

    self:request_style()
end

---@param class? string|string[]
---@return string[]
local function parse_class(class)
    local classes = class or {}
    if type(class) == "string" then
        classes = {}
        for c in class:gmatch("%S+") do
            if #c > 0 then
                classes[#classes + 1] = c
            end
        end
    end
    return classes --[[@as (string[])]]
end

---@param target table<string, boolean>
---@param source string[]
---@return boolean
local function merge_classes(target, source)
    local changed = false
    local source_map = {}
    for _, class in ipairs(source) do
        if not target[class] then
            target[class] = true
            changed = true
        end
        source_map[class] = true
    end
    for class, set in pairs(target) do
        if set and not source_map[class] then
            target[class] = nil
            changed = true
        end
    end
    return changed
end

---@param class? string|string[]
function M.stylable:set_class(class)
    if not merge_classes(self._stylable.context.classes, parse_class(class)) then
        return
    end

    self:request_style()
end

---@param hierarchy? wibox.hierarchy
local function request_styles(hierarchy)
    if not hierarchy then
        return
    end

    local stylable = hierarchy._widget --[[@as stylable?]]
    if stylable then
        stylable:request_style()
    end

    for _, child in ipairs(hierarchy._children) do
        request_styles(child)
    end
end

---@param stylable? stylable
local function hierarchy_request_style(stylable)
    if not stylable then
        return
    end

    local current = stylable._stylable.context.hierarchy.parent

    request_styles(current)

    if not current then
        return
    end

    while current and current._parent do
        stylable = current._parent._widget --[[@as stylable?]]
        if stylable then
            stylable:request_style()
        end
        current = current._parent
    end
end

---@param pseudo_class string
---@param state? boolean
function M.stylable:change_state(pseudo_class, state)
    if not pseudo_class then
        return
    end

    state = state and true or nil

    if self._stylable.context.pseudo_classes[pseudo_class] == state then
        return
    end

    self._stylable.context.pseudo_classes[pseudo_class] = state

    hierarchy_request_style(self)
end

---@param root? wibox
function M.stylable:set_hierarchy_root(root)
    local context = self._stylable.context.hierarchy
    if context.root == root then
        return
    end

    context.root = root
    context.parent = nil
    context.index = nil

    -- TODO: don't request if hierarchy doesn't changed
    self:request_style()
end

---@param parent? wibox.hierarchy
---@param index? integer
function M.stylable:set_parent_hierarchy(parent, index)
    local context = self._stylable.context.hierarchy
    if context.parent == parent and context.index == index then
        return
    end

    context.root = nil
    context.parent = parent
    context.index = index

    -- TODO: don't request if hierarchy doesn't changed
    self:request_style()
end

---@param self stylable
---@param property stylable.property
---@param value any
local function update_property(self, property, value)
    if not property or property.override or value == nil then
        return
    end

    if value == Nil then
        value = nil
    end

    ---@type stylable.property_changing_args
    local args = {
        property = property,
        value = value,
    }

    self:emit_signal("style::update::" .. property.name, value, args)

    if args.cancel then
        return
    end

    local setter = self["set_" .. property.name]
    if setter then
        setter(self, args.value)
    end
end

---@param self stylable
---@param style style
local function update_style_core(self, style)
    self:ignore_override(function()
        for name, value in pairs(style) do
            update_property(self, self._stylable.properties[name], value)
        end
    end)
end

---@param style? style
function M.stylable:update_style(style)
    style = style or {}

    local local_style = self._stylable.local_style
    if local_style then
        for name, value in pairs(local_style) do
            style[name] = value
        end
    end

    update_style_core(self, style)
end

---@param now? boolean
function M.stylable:request_style(now)
    manager.request_style(self, now)
end

---@param name string
---@return stylable.data
local function new_data(name)
    ---@type stylable.data
    local data = {
        context = {
            element = name,
            id = nil,
            classes = {},
            pseudo_classes = {},
            hierarchy = setmetatable({}, { __mode = "v" }),
        },
        properties = {},
        ignore_override = 0,
        local_style = nil,
    }
    return data
end

---@param descriptor style.property_descriptor
---@return stylable.property
local function new_property(descriptor)
    ---@type stylable.property
    local property = {
        name = descriptor.name,
        value = nil,
        empty = true,
        override = false,
        descriptor = descriptor,
    }
    return property
end

---@param module stylable
---@param instance stylable
---@return style.element_info
function M.initialize(instance, module)
    ---@type style.element_info
    local element_info = assert(rawget(module, "_stylable_element_info"))

    ---@type stylable.data
    local _stylable = rawget(instance, "_stylable")

    if element_info.parent then
        assert(_stylable)
        assert(_stylable.context.element == element_info.parent.name)
        _stylable.context.element = element_info.name
    else
        assert(not _stylable)
        _stylable = new_data(element_info.name)
        rawset(instance, "_stylable", _stylable)
        gtable.crush(instance, M.stylable, true)
    end

    for name, descriptor in pairs(element_info.property_descriptors) do
        _stylable.properties[name] = new_property(descriptor)
    end

    update_style_core(instance, element_info.rule.declarations)

    manager.register_instance(instance)

    return element_info
end

return M
