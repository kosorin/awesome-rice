local setmetatable = setmetatable
local rawget = rawget
local rawset = rawset
local assert = assert
local type = type
local pairs, ipairs = pairs, ipairs
local gtable = require("gears.table")
local manager = require("theme.manager")
local Nil = require("theme.nil")


local M = {}

---@class stylable.type_info
---@field name string
---@field parents string[]
---@field default_style style

---@class stylable.context
---@field element string
---@field id? string
---@field classes table<string, boolean>
---@field pseudo_classes table<string, boolean>
---@field hierarchy { parent?: wibox.hierarchy, index?: integer }

---@class stylable.data
---@field context stylable.context
---@field override table<string, boolean>
---@field current table<string, any>
---@field style? style

---@class stylable : gears.object, widget_container
---@field _style stylable.data
M.stylable = {}

---@param self stylable
---@param property string
---@return any
local function get_value(self, property)
    return self._style.current[property]
end

---@param self stylable
---@param property string
---@param value any
local function set_value(self, property, value)
    if value == Nil then
        value = nil
    end
    self._style.current[property] = value
end

---@param style? style
function M.stylable:set_style(style)
    if self._style.style == style then
        return
    end

    self._style.style = style

    self:emit_signal("widget::redraw_needed")
    self:emit_signal("widget::layout_changed")
end

---@param id? string
function M.stylable:set_sid(id)
    if self._style.context.id == id then
        return
    end

    self._style.context.id = id

    self:emit_signal("widget::redraw_needed")
    self:emit_signal("widget::layout_changed")
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
    if merge_classes(self._style.context.classes, parse_class(class)) then
        self:emit_signal("widget::redraw_needed")
        self:emit_signal("widget::layout_changed")
    end
end

---@param pseudo_class string
---@param state? boolean
function M.stylable:change_state(pseudo_class, state)
    if not pseudo_class then
        return
    end

    state = state and true or nil

    if self._style.context.pseudo_classes[pseudo_class] == state then
        return
    end

    self._style.context.pseudo_classes[pseudo_class] = state

    self:emit_signal("widget::redraw_needed")
    self:emit_signal("widget::layout_changed")
end

---@param parent? wibox.hierarchy
---@param index? integer
function M.stylable:set_parent_hierarchy(parent, index)
    local context = self._style.context.hierarchy
    if context.parent == parent and context.index == index then
        return
    end

    context.parent = parent
    context.index = index

    -- TODO: don't request if hierarchy doesn't changed
    -- self:emit_signal("widget::redraw_needed")
    -- self:emit_signal("widget::layout_changed")
end

---@param style? style
function M.stylable:apply_style(style)
    if not style then
        style = self._style.style
    elseif self._style.style then
        for name, value in pairs(self._style.style) do
            style[name] = value
        end
    end

    if style then
        for name, value in pairs(style) do
            if not self._style.override[name] then
                set_value(self, name, value)
            end
        end
    end
end

---@param context? widget_context
function M.stylable:request_style(context)
    manager.request_style(self, context)
end

---@param self stylable
function M.initialize(self)
    local _style = rawget(self, "_style")
    if not _style then
        gtable.crush(self, M.stylable, true)
        ---@type stylable.data
        _style = {
            context = {
                ---@diagnostic disable-next-line: assign-type-mismatch
                element = nil,
                id = nil,
                classes = {},
                pseudo_classes = {},
                hierarchy = setmetatable({}, { __mode = "v" }),
            },
            override = {},
            current = {},
        }
        rawset(self, "_style", _style)
    end

    ---@type stylable.type_info
    local type_info = assert(rawget(self, "_style_type_info"))

    _style.context.element = type_info.name

    manager.subscribe(self)
end

return M
