local setmetatable = setmetatable
local assert, error = assert, error
local rawset = rawset
local type = type
local pairs, ipairs = pairs, ipairs
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local style_sheet = require("theme.style_sheet")

---@class style.property_descriptor
---@field name string
---@field equality_comparer? fun(a, b, self: stylable, property: stylable.property): boolean
---@field fallback? fun(self: stylable, property: stylable.property): any
---@field coerce? fun(value: any, self: stylable, property: stylable.property): any

---@class style.element_info
---@field module stylable
---@field name string
---@field parent? style.element_info
---@field property_descriptors table<string, style.property_descriptor>
---@field rule style_sheet.rule

---@class theme_manager : gears.object
---@field element_info_map table<string, style.element_info>
---@field stylables table<stylable, boolean>
---@field requests? table<stylable, boolean>
---@field default_style_sheet style_sheet
---@field style_sheets? style_sheet[]
---@field _beautiful Theme.default # TODO: obsolete
local M = gobject { enable_properties = false }

M.element_info_map = {}
M.stylables = setmetatable({}, { __mode = "k" })

M.default_style_sheet = style_sheet.new()
M.style_sheets = {}

M._beautiful = setmetatable({}, {
    __index = function() error("Theme is not loaded yet!") end,
    __newindex = function() error("Theme is not loaded yet!") end,
})

---@param theme Theme.default
function M.load(theme)
    M._beautiful = theme

    local style_sheets = {}
    for _, source in ipairs(theme.style_sheets or {}) do
        local parsed, ss = pcall(style_sheet.parse, source)
        if parsed then
            style_sheets[#style_sheets + 1] = ss
        end
    end
    M.style_sheets = style_sheets

    for stylable in pairs(M.stylables) do
        M.process_request(stylable)
    end
end

---@param context stylable.context
---@return style
function M.build_style(context)
    local style = {}
    M.default_style_sheet:enrich(style, context)
    if M.style_sheets then
        for _, ss in ipairs(M.style_sheets) do
            ss:enrich(style, context)
        end
    end
    return style
end

---@private
---@param stylable stylable
function M.process_request(stylable)
    local style = M.build_style(stylable._stylable.context)
    stylable:update_style(style)
end

---@private
function M.process_pending_requests()
    if not M.requests then
        return
    end

    for stylable in pairs(M.requests) do
        M.process_request(stylable)
    end

    M.requests = nil
end

---@param stylable stylable
---@param now? boolean
function M.request_style(stylable, now)
    if now then
        M.process_request(stylable)
        return
    end

    if not M.requests then
        M.requests = setmetatable({}, { __mode = "k" })
        gtimer.delayed_call(M.process_pending_requests)
    end

    M.requests[stylable] = true
end

---@param stylable stylable
function M.register_instance(stylable)
    M.stylables[stylable] = true
end

---@param stylable stylable
function M.unregister_instance(stylable)
    M.stylables[stylable] = nil
end

---@param names string[]
---@param descriptors? table<string, style.property_descriptor>
---@return table<string, style.property_descriptor>
local function intialize_property_descriptors(names, descriptors)
    local result = {}
    for _, name in ipairs(names) do
        local descriptor = descriptors and descriptors[name] or {}

        descriptor.name = name

        result[name] = descriptor
    end
    return result
end

---@param element_info style.element_info
---@param parent? style.element_info
local function add_to_parents(element_info, parent)
    if not parent then
        return
    end

    for property_name in pairs(element_info.property_descriptors) do
        if parent.property_descriptors[property_name] then
            error(("Property '%s.%s' already defined in '%s'."):format(element_info.name, property_name, parent.name))
        end
    end

    local selector = element_info.rule.selectors[1]
    parent.rule.selectors[#parent.rule.selectors + 1] = selector

    add_to_parents(element_info, parent.parent)
end

---@param element_info style.element_info
local function add_element_info(element_info)
    add_to_parents(element_info, element_info.parent)
    M.element_info_map[element_info.name] = element_info
    M.default_style_sheet:add_rule(element_info.rule)
end

---@param module stylable
---@param name string
---@param parent? string
---@param default_style? style
---@param property_descriptors? table<string, style.property_descriptor>
function M.register_element(module, name, parent, default_style, property_descriptors)
    default_style = default_style or {}

    local property_names = gtable.keys(default_style --[[@as table]])
    property_descriptors = intialize_property_descriptors(property_names, property_descriptors)

    ---@type style.element_info
    local element_info = {
        module = module,
        name = name,
        parent = parent and assert(M.element_info_map[parent]) or nil,
        property_descriptors = property_descriptors,
        rule = {
            selectors = { { element = name } },
            declarations = default_style,
        },
    }
    rawset(module, "_stylable_element_info", element_info)

    add_element_info(element_info)
end

return M
