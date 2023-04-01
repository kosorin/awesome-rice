local setmetatable = setmetatable
local assert = assert
local rawset = rawset
local type = type
local pairs = pairs
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local style_sheet = require("theme.style_sheet")

---@class theme_manager : gears.object
---@field element_map table<string, { parents?: string[], rule: style_sheet.rule }>
---@field default_style_sheet style_sheet
---@field style_sheet style_sheet
---@field stylables table<stylable, boolean>
---@field requests? stylable[]
---@field _beautiful Theme # TODO: obsolete
local M = gobject { enable_properties = false }

gtable.crush(M, {
    element_map = {},
    default_style_sheet = style_sheet.new(),
    style_sheet = style_sheet.new(),
    stylables = setmetatable({}, { __mode = "k" }),
    _beautiful = setmetatable({}, {
        __index = function() error("Theme is not loaded yet!") end,
        __newindex = function() error("Theme is not loaded yet!") end,
    }),
}, true)

---@param theme Theme
function M.load(theme)
    M._beautiful = theme

    M.style_sheet = style_sheet.parse(theme.style_sheet)

    for stylable in pairs(M.stylables) do
        M.apply_style(stylable)
    end
end

---@param context stylable.context
---@return style
function M.get_style(context)
    local style = {}
    M.default_style_sheet:enrich(style, context)
    if M.style_sheet then
        M.style_sheet:enrich(style, context)
    end
    return style
end

---@param stylable stylable
function M.apply_style(stylable)
    local style = M.get_style(stylable._style.context)
    stylable:apply_style(style)
end

function M.process_requests()
    if not M.requests then
        return
    end

    for i = 1, #M.requests do
        M.apply_style(M.requests[i])
    end

    M.requests = nil
end

---@param stylable stylable
---@param context? widget_context
function M.request_style(stylable, context)
    local style = M.get_style(stylable._style.context)
    stylable:apply_style(style)
end

---@param stylable stylable
function M.subscribe(stylable)
    M.stylables[stylable] = true
    M.request_style(stylable, false)
end

---@param stylable stylable
function M.unsubscribe(stylable)
    M.stylables[stylable] = nil
end

---@param selector style_sheet.selector
---@param parents string[]
local function add_to_parents(selector, parents)
    for i = 1, #parents do
        local parent = assert(M.element_map[parents[i]])
        parent.rule.selectors[#parent.rule.selectors + 1] = selector
        add_to_parents(selector, parent.parents)
    end
end

---@param module? table
---@param name string
---@param parents? string|string[] # TODO: Allow multiple parents?
---@param default_style? style
function M.register_type(module, name, parents, default_style)
    if type(parents) == "string" then
        parents = { parents }
    elseif not parents then
        parents = {}
    end
    ---@cast parents string[]

    default_style = default_style or {}

    ---@type style_sheet.selector
    local selector = { element = name }

    ---@type style_sheet.rule
    local rule = {
        selectors = { selector },
        declarations = default_style,
    }

    M.element_map[name] = {
        parents = parents,
        rule = rule,
    }
    add_to_parents(selector, parents)

    M.default_style_sheet:add_rule(rule)

    if module then
        ---@type stylable.type_info
        local type_info = {
            name = name,
            parents = parents,
            default_style = default_style,
        }
        rawset(module, "_style_type_info", type_info)
    end
end

return M
