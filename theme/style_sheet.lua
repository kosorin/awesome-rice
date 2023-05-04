local warn, error = warn, error
local setmetatable = setmetatable
local type = type
local assert = assert
local pairs, ipairs = pairs, ipairs
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
            if pc.name == "even" then
                local index = context.hierarchy.index
                if not index or (index % 2) ~= 0 then
                    return false
                end
            elseif pc.name == "odd" then
                local index = context.hierarchy.index
                if not index or (index % 2) ~= 1 then
                    return false
                end
            elseif not context.pseudo_classes[pc.name] == not pc.negate then
                return false
            end
        end
    end

    return true
end

---@param hierarchy? wibox.hierarchy
---@return stylable|nil
local function get_stylable(hierarchy)
    if not hierarchy then
        return nil
    end

    return hierarchy._widget --[[@as stylable|nil]]
end

---@param root? wibox
---@return stylable.context|nil
local function get_wibox_context(root)
    if not root then
        return nil
    end
    ---@cast root +stylable

    local stylable_data = root._stylable
    if not stylable_data then
        return nil
    end

    return stylable_data.context
end

---@param hierarchy? wibox.hierarchy
---@return stylable.context|nil
local function get_widget_context(hierarchy)
    local stylable = get_stylable(hierarchy)
    if not stylable then
        return nil
    end

    local stylable_data = stylable._stylable
    if not stylable_data then
        return nil
    end

    return stylable_data.context
end

---@param context stylable.context
---@return stylable.context|nil
local function get_parent_context(context)
    local hierarchy = context.hierarchy
    if hierarchy.root then
        return get_wibox_context(hierarchy.root)
    elseif hierarchy.parent then
        return get_widget_context(hierarchy.parent)
    else
        return nil
    end
end

---@param context stylable.context
---@param index integer
---@return stylable.context|nil
local function get_sibling_context(context, index)
    local parent = context.hierarchy.parent
    if parent then
        local sibling = parent._children[index]
        return get_widget_context(sibling)
    end
    return nil
end

---@param context stylable.context
---@return integer|nil
---@return integer|nil
local function get_sibling_info(context)
    local hierarchy = context.hierarchy
    local parent = hierarchy.parent
    local index = hierarchy.index
    if parent and index then
        return index, #parent._children
    end
    return nil, nil
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
        local parent_context = get_parent_context(context)
        while parent_context do
            if match_selector(combinator.former, parent_context) then
                return true
            end
            parent_context = get_parent_context(parent_context)
        end
    elseif combinator.operator == ">" then
        return match_selector(combinator.former, get_parent_context(context))
    elseif combinator.operator == "+" then
        local index = get_sibling_info(context)
        if index then
            return match_selector(combinator.former, get_sibling_context(context, index - 1))
        end
        return false
    elseif combinator.operator == "~" then
        local index = get_sibling_info(context)
        if index then
            for i = index - 1, 1, -1 do
                if match_selector(combinator.former, get_sibling_context(context, i)) then
                    return true
                end
            end
        end
        return false
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
---@field pseudo_classes? { name: string, negate: boolean }[]

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

    local parts = {}
    for text in s:gmatch("(%S+)") do
        local function add_part(from, to)
            local part = text:sub(from, to)
            if part and #part > 0 then
                parts[#parts + 1] = part
            end
        end
        local position = 1
        repeat
            local from, to = text:find("[>+~]", position)
            if from then
                if from > position then
                    add_part(position, from - 1)
                end
            else
                from = position
                to = #text
            end
            add_part(from, to)
            position = to + 1
        until position > #text
    end

    local selector, operator
    for _, part in ipairs(parts) do
        if part == ">" or part == "+" or part == "~" then
            if not selector then
                error("parse_selector: unexpected operator")
            end
            operator = part
        else
            local element
            local id
            local classes
            local pseudo_classes
            for kind, modifier, name in part:gmatch("([%.:#]?)(!?)([%w_-]+)") do
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
                    pseudo_classes[#pseudo_classes + 1] = {
                        name = name,
                        negate = modifier == "!",
                    }
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
