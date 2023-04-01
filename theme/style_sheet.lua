local warn, error = warn, error
local setmetatable = setmetatable
local type = type
local assert = assert
local pairs = pairs
local ustring = require("utils.string")


---@alias style_sheet.source { id?: string, [integer]: { [integer]: string, [string]: any } }

---@alias style table<string, any>

local M = {}

local match_combinator

---@param selector? style_sheet.selector
---@param context? stylable.context
---@return boolean
local function match_selector(selector, context)
    if not selector or not context then
        return false
    end

    if selector.combinator then
        return match_combinator(selector.combinator, context)
    end

    if selector.all then
        return true
    end

    if selector.element and selector.element ~= context.element then
        return false
    end

    if selector.id and selector.id ~= context.id then
        return false
    end

    if selector.classes then
        for i = 1, #selector.classes do
            if not context.classes[selector.classes[i]] then
                return false
            end
        end
    end

    if selector.pseudo_classes then
        for i = 1, #selector.pseudo_classes do
            local pc = selector.pseudo_classes[i]
            if pc == "even" then
                local index = context.hierarchy.index
                if not index or (index % 2) ~= 0 then
                    return false
                end
            elseif pc == "odd" then
                local index = context.hierarchy.index
                if not index or (index % 2) ~= 1 then
                    return false
                end
            elseif not context.pseudo_classes[pc] then
                return false
            end
        end
    end

    return true
end

---@param hierarchy? wibox.hierarchy
---@return stylable.context|nil
local function get_context(hierarchy)
    if not hierarchy then
        return nil
    end

    local widget = hierarchy._widget --[[@as stylable|nil]]
    if not widget then
        return nil
    end

    local style_data = widget._style
    if not style_data then
        return nil
    end

    return style_data.context
end

---@param combinator style_sheet.combinator
---@param context? stylable.context
---@return boolean
function match_combinator(combinator, context)
    if not context then
        return false
    end

    if not match_selector(combinator.target, context) then
        return false
    end

    if not combinator.operator then
        local parent = context.hierarchy.parent
        while parent do
            local parent_context = get_context(parent)
            if match_selector(combinator.former, parent_context) then
                return true
            end
            parent = parent._parent
        end
    elseif combinator.operator == ">" then
        return match_selector(combinator.former, get_context(context.hierarchy.parent))
    elseif combinator.operator == "+" then
        local parent = context.hierarchy.parent
        local index = context.hierarchy.index
        if parent and index then
            local sibling = parent._children[index - 1]
            return match_selector(combinator.former, get_context(sibling))
        end
    elseif combinator.operator == "~" then
        local parent = context.hierarchy.parent
        local index = context.hierarchy.index
        if parent and index then
            for i = index - 1, 1, -1 do
                local sibling = parent._children[i]
                if match_selector(combinator.former, get_context(sibling)) then
                    return true
                end
            end
        end
    end

    return false
end

---@param rule? style_sheet.rule
---@param context? stylable.context
---@return boolean
local function match_rule(rule, context)
    if not rule or not context then
        return false
    end

    for i = 1, #rule.selectors do
        local selector = rule.selectors[i]
        if match_selector(selector, context) then
            return true
        end
    end

    return false
end

---@class style_sheet.combinator
---@field operator string
---@field former style_sheet.selector
---@field target style_sheet.selector

---@class style_sheet.selector
---@field combinator? style_sheet.combinator
---@field all? boolean
---@field element? string
---@field id? string
---@field classes? string[]
---@field pseudo_classes? string[]

---@class style_sheet.rule
---@field selectors style_sheet.selector[]
---@field declarations style

---@class style_sheet
---@field id? string
---@field [integer] style_sheet.rule
M.object = {}

---@param style style
---@param context stylable.context
function M.object:enrich(style, context)
    for i = 1, #self do
        local rule = self[i]
        if match_rule(rule, context) then
            for property, value in pairs(rule.declarations) do
                style[property] = value
            end
        end
    end
end

---@param rule style_sheet.rule
function M.object:add_rule(rule)
    self[#self + 1] = rule
end

---@param s string
---@return style_sheet.selector|nil
local function parse_selector(s)
    if not s then
        return nil
    end

    s = ustring.trim(s)

    if s == "*" then
        return { all = true }
    end

    local selector, operator

    for x in s:gmatch("(%S+)") do
        if x == ">" or x == "+" or x == "~" then
            if not selector then
                error("parse_selector: unexpected operator")
            end
            operator = x
        else
            local element
            local id
            local classes
            local pseudo_classes
            for kind, name in x:gmatch("([%.:#]?)([%w_-]+)") do
                if kind == "" then
                    assert(not id, "parse_selector: too many elements")
                    element = name
                elseif kind == "#" then
                    assert(not id, "parse_selector: too many ids")
                    id = name
                elseif kind == "." then
                    classes = classes or {}
                    classes[#classes + 1] = name
                elseif kind == ":" then
                    pseudo_classes = pseudo_classes or {}
                    pseudo_classes[#pseudo_classes + 1] = name
                else
                    error("parse_selector: unexpected input")
                end
            end
            assert(element or id or classes or pseudo_classes, "parse_selector: empty selector or unexpected input")

            ---@type style_sheet.selector
            local new_selector = {
                element = element,
                id = id,
                classes = classes,
                pseudo_classes = pseudo_classes,
            }

            if selector then
                ---@type style_sheet.selector
                selector = {
                    combinator = {
                        operator = operator,
                        former = selector,
                        target = new_selector,
                    },
                }
            else
                selector = new_selector
            end

            operator = nil
        end
    end

    if operator then
        error("parse_selector: missing selector for operator " .. operator)
    end

    return selector
end

---@param source style_sheet.source
---@return style_sheet
function M.parse(source)
    local style_sheet = M.new()

    if not source then
        return style_sheet
    end

    style_sheet.id = source.id

    for i = 1, #source do
        local selectors, declarations
        for k, value in pairs(source[i]) do
            local t = type(k)
            if t == "number" then
                local selector = parse_selector(value)
                if selector then
                    selectors = selectors or {}
                    selectors[#selectors + 1] = selector
                end
            elseif t == "string" then
                declarations = declarations or {}
                declarations[k] = value
            end
        end
        if selectors and declarations then
            style_sheet[#style_sheet + 1] = {
                selectors = selectors,
                declarations = declarations,
            }
        end
    end

    return style_sheet
end

---@return style_sheet
function M.new()
    return setmetatable({}, { __index = M.object })
end

return M