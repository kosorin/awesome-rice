local capi = Capi
local type = type
local setmetatable = setmetatable
local ipairs = ipairs
local select = select
local tostring = tostring
local dpi = Dpi
local hui = require("utils.thickness")
local math = math
local table = table
local string = string
local awful = require("awful")
local beautiful = require("theme.theme")
local gtable = require("gears.table")
local gmatcher = require("gears.matcher")
local wibox = require("wibox")
local pbinding = require("core.binding")
local mod = pbinding.modifier
local btn = pbinding.button
local utree = require("utils.tree")
local capsule = require("widget.capsule")
local noice = require("core.style")
local pango = require("utils.pango")
local ui_controller = require("ui.controller")


local s25p = pango.span { size = "25%", " " }
local s50p = pango.span { size = "50%", " " }
local force_ltr = "&#x200E;"
local mouse_label_icon = ""

---@class Bindbox.label
---@field text string
---@field find_terms? string[]

---@type { [string|integer]: Bindbox.label }
local labels = {
    [btn.left]            = { text = mouse_label_icon .. " Left", find_terms = { "mouse", "left" } },
    [btn.middle]          = { text = mouse_label_icon .. " Middle", find_terms = { "mouse", "middle" } },
    [btn.right]           = { text = mouse_label_icon .. " Right", find_terms = { "mouse", "right" } },
    [btn.wheel_up]        = { text = mouse_label_icon .. " Wheel Up", find_terms = { "mouse", "wheel", "up" } },
    [btn.wheel_down]      = { text = mouse_label_icon .. " Wheel Down", find_terms = { "mouse", "wheel", "down" } },
    [btn.wheel_left]      = { text = mouse_label_icon .. " Wheel Left", find_terms = { "mouse", "wheel", "left" } },
    [btn.wheel_right]     = { text = mouse_label_icon .. " Wheel Right", find_terms = { "mouse", "wheel", "right" } },
    [btn.extra_back]      = { text = mouse_label_icon .. " Back", find_terms = { "mouse", "back" } },
    [btn.extra_forward]   = { text = mouse_label_icon .. " Forward", find_terms = { "mouse", "forward" } },
    --
    Control               = { text = "Ctrl", find_terms = { "ctrl" } },
    Mod1                  = { text = "Alt", find_terms = { "alt" } },
    ISO_Level3_Shift      = { text = "Alt Gr", find_terms = { "altgr" } },
    Mod4                  = { text = "Super", find_terms = { "super" } },
    --
    Insert                = { text = "Ins", find_terms = { "ins", "insert" } },
    Delete                = { text = "Del", find_terms = { "del", "delete" } },
    Next                  = { text = "PgDn", find_terms = { "pgdn", "pagedown", "page" } },
    Prior                 = { text = "PgUp", find_terms = { "pgup", "pageup", "page" } },
    Left                  = { text = "" .. s25p, find_terms = { "left", "arrow" } },
    Up                    = { text = "" .. s25p, find_terms = { "up", "arrow" } },
    Right                 = { text = "" .. s25p, find_terms = { "right", "arrow" } },
    Down                  = { text = "" .. s25p, find_terms = { "down", "arrow" } },
    Escape                = { text = "Esc", find_terms = { "esc", "escape" } },
    Tab                   = { text = "Tab", find_terms = { "tab" } },
    space                 = { text = "Space", find_terms = { "space" } },
    Return                = { text = "Enter", find_terms = { "enter" } },
    BackSpace             = { text = " ", find_terms = { "backspace" } },
    --
    KP_End                = { text = "Num1", find_terms = { "numpad", "1" } },
    KP_Down               = { text = "Num2", find_terms = { "numpad", "2" } },
    KP_Next               = { text = "Num3", find_terms = { "numpad", "3" } },
    KP_Left               = { text = "Num4", find_terms = { "numpad", "4" } },
    KP_Begin              = { text = "Num5", find_terms = { "numpad", "5" } },
    KP_Right              = { text = "Num6", find_terms = { "numpad", "6" } },
    KP_Home               = { text = "Num7", find_terms = { "numpad", "7" } },
    KP_Up                 = { text = "Num8", find_terms = { "numpad", "8" } },
    KP_Prior              = { text = "Num9", find_terms = { "numpad", "9" } },
    KP_Insert             = { text = "Num0", find_terms = { "numpad", "0" } },
    KP_Delete             = { text = "Num.", find_terms = { "numpad", "." } },
    KP_Divide             = { text = "Num/", find_terms = { "numpad", "/" } },
    KP_Multiply           = { text = "Num*", find_terms = { "numpad", "*" } },
    KP_Subtract           = { text = "Num-", find_terms = { "numpad", "-" } },
    KP_Add                = { text = "Num+", find_terms = { "numpad", "+" } },
    KP_Enter              = { text = "NumEnter", find_terms = { "numpad", "enter" } },
    --
    dead_acute            = { text = "´" },
    dead_circumflex       = { text = "^" },
    dead_grave            = { text = "`" },
    --
    XF86MonBrightnessUp   = { text = "󰃟 +", find_terms = { "brightness" } },
    XF86MonBrightnessDown = { text = "󰃟 -", find_terms = { "brightness" } },
    XF86AudioRaiseVolume  = { text = force_ltr .. "ﱛ", find_terms = { "volume" } },
    XF86AudioLowerVolume  = { text = force_ltr .. "ﱜ", find_terms = { "volume" } },
    XF86AudioMute         = { text = force_ltr .. "ﱝ", find_terms = { "volume" } },
    XF86AudioPlay         = { text = "契", find_terms = { "media" } },
    XF86AudioPause        = { text = "", find_terms = { "media" } },
    XF86AudioStop         = { text = "栗", find_terms = { "media" } },
    XF86AudioPrev         = { text = "玲", find_terms = { "media" } },
    XF86AudioNext         = { text = "怜", find_terms = { "media" } },
    XF86AudioRewind       = { text = "丹", find_terms = { "media" } },
    XF86AudioForward      = { text = "", find_terms = { "media" } },
    --
    Print                 = { text = "" .. s50p, find_terms = { "printscreen" } },
    XF86Calculator        = { text = "" .. s50p, find_terms = { "calculator" } },
}


---@class Bindbox.module
---@operator call: Bindbox
local M = { mt = {} }

function M.mt:__call(...)
    return M.new(...)
end


---@class Bindbox.data.item
---@field binding Binding
---@field trigger { size: size, markup: string, highlighted?: string, widget?: wibox.widget.textbox }
---@field description { size: size, markup: string, highlighted?: string, widget?: wibox.widget.textbox }

---@class Bindbox.data.group
---@field markup string
---@field size size
---@field page_break? boolean
---@field [integer] Bindbox.data.item

---@class Bindbox.data
---@field max_trigger_width number
---@field max_description_width number -- also used for group header
---@field [integer] Bindbox.data.group

---@class Bindbox : awful.popup, stylable
---@field package _private Bindbox.private
---Style properties:
---@field font unknown
---@field paddings unknown
---@field page_paddings unknown
---@field page_width unknown
---@field page_height unknown
---@field page_columns unknown
---@field group_spacing unknown
---@field item_spacing unknown
---@field trigger_bg unknown
---@field trigger_bg_alpha unknown
---@field trigger_fg unknown
---@field group_bg unknown
---@field group_fg unknown
---@field group_ruled_bg unknown
---@field group_ruled_fg unknown
---@field find_dim_bg unknown
---@field find_dim_fg unknown
---@field find_highlight_bg unknown
---@field find_highlight_bg_alpha unknown
---@field find_highlight_fg unknown
---@field find_highlight_trigger_bg unknown
---@field find_highlight_trigger_bg_alpha unknown
---@field find_highlight_trigger_fg unknown
---@field group_path_separator_markup unknown
---@field slash_separator_markup unknown
---@field plus_separator_markup unknown
---@field range_separator_markup unknown
---@field status_style unknown
---@field status_spacing unknown
---@field find_placeholder_fg unknown
---@field find_cursor_bg unknown
---@field find_cursor_fg unknown
M.object = {}
---@class Bindbox.private
---@field current_page? integer
---@field pages unknown
---@field find unknown
---@field matcher gears.matcher
---@field source_binding_tree Tree
---@field include_awesome_bindings boolean

noice.define_style(M.object, {
    bg = { proxy = true },
    fg = { proxy = true },
    border_color = { proxy = true },
    border_width = { proxy = true },
    shape = { proxy = true },
    placement = { proxy = true },
    font = {},
    paddings = { id = "#padding", property = "margins" },
    page_paddings = { id = "#page_container_border", property = "margins" },
    page_width = {},
    page_height = {},
    page_columns = {},
    group_spacing = {},
    item_spacing = {},
    trigger_bg = {},
    trigger_bg_alpha = {},
    trigger_fg = {},
    group_bg = {},
    group_fg = {},
    group_ruled_bg = {},
    group_ruled_fg = {},
    find_dim_bg = {},
    find_dim_fg = {},
    find_highlight_bg = {},
    find_highlight_bg_alpha = {},
    find_highlight_fg = {},
    find_highlight_trigger_bg = {},
    find_highlight_trigger_bg_alpha = {},
    find_highlight_trigger_fg = {},
    group_path_separator_markup = {},
    slash_separator_markup = {},
    plus_separator_markup = {},
    range_separator_markup = {},
    status_bg = { id = "#status_container", property = "bg" },
    status_fg = { id = "#status_container", property = "fg" },
    status_border_color = { id = "#status_container", property = "border_color" },
    status_border_width = { id = "#status_container", property = "border_width" },
    status_paddings = { id = "#status_container", property = "paddings" },
    status_spacing = { id = "#status_bindings", property = "spacing" },
    find_placeholder_fg = { id = "#find_placeholder", property = "fg" },
    find_cursor_bg = {},
    find_cursor_fg = {},
})

---@param a Node
---@param b Node
---@return boolean
local function default_group_sort(a, b)
    local ga, gb = a.state --[[@as BindboxGroup]], b.state --[[@as BindboxGroup]]
    local ra, rb = not not ga.rule, not not gb.rule
    if ra == rb then
        local oa, ob = ga.order, gb.order
        if oa and ob then
            return oa < ob
        elseif not oa and not ob then
            return a.name < b.name
        else
            return not not oa
        end
    else
        return ra
    end
end

---@param a Binding
---@param b Binding
---@return boolean
local function default_binding_sort(a, b)
    local oa, ob = a.order, b.order
    if oa and ob then
        return oa < ob
    elseif not oa and not ob then
        return (a.description or "") < (b.description or "")
    else
        return not not oa
    end
end

---@param modifier key_modifier
---@return string
---@return Bindbox.label?
local function get_modifier_label(modifier)
    local label = labels[modifier]
    return label and label.text or modifier, label
end

---@param trigger BindingTrigger.value
---@return string
---@return Bindbox.label?
local function get_trigger_label(trigger)
    local label
    local label_text
    local tt = type(trigger)
    if tt == pbinding.trigger_type.key then
        local keysym, keyprint = awful.keyboard.get_key_name(trigger)
        label = labels[keysym]
        label_text = label and label.text or keyprint or keysym
    elseif tt == pbinding.trigger_type.button then
        label = labels[trigger]
        label_text = label and label.text
    end
    return label_text or tostring(trigger), label
end

---@class Bindbox.highlight.part
---@field highlight boolean
---@field from integer
---@field to integer

---@class Bindbox.highlight.result
---@field triggers? boolean[]
---@field description? Bindbox.highlight.part[]

---@param self Bindbox
---@param binding Binding
---@param find_terms string[]
---@return Bindbox.highlight.result?
local function get_binding_highlighting(self, binding, find_terms)
    if #find_terms == 0 then
        return nil
    end

    ---@type Bindbox.highlight.result
    local result = {}

    do
        local highlighted_triggers = {}

        local handled_find_terms = { count = 0 }

        ---@param label_text string
        ---@param label? Bindbox.label
        ---@return boolean
        local function handle_highlighting(label_text, label)
            local label_find_terms = label and label.find_terms

            if not label_find_terms or #label_find_terms == 0 then
                label_find_terms = { string.lower(label_text) }
            end

            for _, lft in ipairs(label_find_terms) do
                for i, ft in ipairs(find_terms) do
                    if not handled_find_terms[i] and lft == ft then
                        handled_find_terms.count = handled_find_terms.count + 1
                        handled_find_terms[i] = true
                        return true
                    end
                end
            end

            return false
        end

        for i, m in ipairs(binding.modifiers) do
            local label_text, label = get_modifier_label(m)
            if handle_highlighting(label_text, label) then
                highlighted_triggers[i] = true
            end
        end

        for _, t in ipairs(binding.triggers) do
            local label_text, label = get_trigger_label(t.trigger)
            if handle_highlighting(label_text, label) then
                highlighted_triggers[0] = true
            end
        end

        if handled_find_terms.count == #find_terms then
            result.triggers = highlighted_triggers
        end
    end

    do
        local description = binding.description or ""

        if #description > 0 then
            description = string.lower(description)

            ---@type Bindbox.highlight.part[]
            local parts = {}
            local found_find_terms = 0

            local function is_available(from, to)
                for _, s in ipairs(parts) do
                    if from <= s.to and to >= s.from then
                        return false
                    end
                end
                return true
            end

            for _, ft in ipairs(find_terms) do
                ---@type integer?, integer?
                local from, to = 1, nil
                while true do
                    from, to = string.find(description, ft, from, true)
                    if not from then
                        break
                    end
                    if is_available(from, to) then
                        table.insert(parts, { highlight = true, from = from, to = to })
                        found_find_terms = found_find_terms + 1
                        break
                    end
                    from = to + 1
                end
            end

            if found_find_terms == #find_terms then
                table.sort(parts, function(a, b) return a.from < b.from end)

                ---@type Bindbox.highlight.part[]
                local merged_parts = {}
                local length = #description
                local next_part = parts[1]
                local i = 1
                while i <= length do
                    if next_part then
                        if next_part.from == i then
                            table.insert(merged_parts, next_part)
                            i = next_part.to + 1
                            table.remove(parts, 1)
                            next_part = parts[1]
                        else
                            table.insert(merged_parts, { from = i, to = next_part.from - 1 })
                            i = next_part.from
                        end
                    else
                        table.insert(merged_parts, { from = i, to = length })
                        break
                    end
                end

                result.description = merged_parts
            end
        end
    end

    return result
end

---@param self Bindbox
---@param node Node
---@param path string[]
---@return string
local function get_group_markup(self, node, path)
    local is_ruled = node:find_parent(function(n) return (n.state --[[@as BindboxGroup]]).rule end, true)
    local _, bg = node:find_parent(function(n) return (n.state --[[@as BindboxGroup]]).bg end, true)
    local _, fg = node:find_parent(function(n) return (n.state --[[@as BindboxGroup]]).fg end, true)
    bg = bg or (is_ruled and self.group_ruled_bg or self.group_bg)
    fg = fg or (is_ruled and self.group_ruled_fg or self.group_fg)
    local text = " " .. table.concat(path, self.group_path_separator_markup) .. " "
    return pango.span {
        fgcolor = fg,
        bgcolor = bg,
        text,
    }
end

---@param self Bindbox
---@param binding Binding
---@param highlight_result? Bindbox.highlight.result
---@return string
local function get_trigger_markup(self, binding, highlight_result)
    local dim_triggers = highlight_result and not highlight_result.triggers and not highlight_result.description

    ---@param index integer
    ---@return boolean?
    local function highlight_trigger(index)
        return highlight_result and highlight_result.triggers and highlight_result.triggers[index]
    end

    ---@param content string
    ---@param highlight? boolean
    local function trigger_box(content, highlight)
        return pango.span {
            fgcolor = highlight and self.find_highlight_trigger_fg or (dim_triggers and self.find_dim_fg or self.trigger_fg),
            bgcolor = highlight and self.find_highlight_trigger_bg or self.trigger_bg,
            bgalpha = highlight and self.find_highlight_trigger_bg_alpha or self.trigger_bg_alpha,
            " " .. content .. " ",
        }
    end

    local result_markup = ""

    for i, m in ipairs(binding.modifiers) do
        local modifier_label_text = get_modifier_label(m)
        local modifier_markup = trigger_box(modifier_label_text, highlight_trigger(i))
        result_markup = result_markup .. modifier_markup .. self.plus_separator_markup
    end

    if binding.text then
        local trigger_label_text = binding.text or ""
        local trigger_markup = trigger_box(trigger_label_text, highlight_trigger(0))
        result_markup = result_markup .. trigger_markup
    elseif binding.from and binding.to then
        local from_label_text = get_trigger_label(binding.from)
        local to_label_text = get_trigger_label(binding.to)
        local trigger_label_text = from_label_text .. self.range_separator_markup .. to_label_text
        local trigger_markup = trigger_box(trigger_label_text, highlight_trigger(0))
        result_markup = result_markup .. trigger_markup
    else
        local trigger_label_texts = gtable.map(function(t) return get_trigger_label(t.trigger) end, binding.triggers)
        local trigger_label_text = table.concat(trigger_label_texts, self.slash_separator_markup)
        local trigger_markup = trigger_box(trigger_label_text, highlight_trigger(0))
        result_markup = result_markup .. trigger_markup
    end

    return result_markup
end

---@param self Bindbox
---@param binding Binding
---@param highlight_result? Bindbox.highlight.result
---@return string
local function get_description_markup(self, binding, highlight_result)
    local description = binding.description or ""

    if not highlight_result then
        return description
    elseif not highlight_result.description and not highlight_result.triggers then
        return pango.span {
            fgcolor = self.find_dim_fg,
            bgcolor = self.find_dim_bg,
            pango.escape(description),
        }
    elseif not highlight_result.description then
        return description
    else
        return table.concat(gtable.map(function(part)
            ---@cast part Bindbox.highlight.part
            local capture = string.sub(description, part.from, part.to)
            if part.highlight then
                return pango.span {
                    fgcolor = self.find_highlight_fg,
                    bgcolor = self.find_highlight_bg,
                    bgalpha = self.find_highlight_bg_alpha,
                    pango.escape(capture),
                }
            else
                return capture
            end
        end, highlight_result.description), "")
    end
end

---@param self Bindbox
---@param markup string
---@return size
local function get_markup_geometry(self, markup)
    return wibox.widget.textbox.get_markup_geometry(
        markup,
        self.screen,
        self.font)
end

---@param node Node
---@param binding Binding
local function merge_binding(node, binding)
    table.insert(node.state, binding)
end

---@param self Bindbox
---@param tree Tree
---@param node Node
---@param group BindboxGroup
local function merge_group(self, tree, node, group)
    if not group or not group.groups then
        return
    end
    for _, g in ipairs(group.groups) do
        local child, is_new = tree:get_or_add_node(node, g.name, g)
        if is_new then
            if not g.order then
                g.order = (self._private.last_group_order or 0) + 1
            end
            self._private.last_group_order = g.order
        end
        for i = 1, #g do
            local binding = pbinding.new(g[i])
            if is_new then
                -- Just replace binding args with an actual binding
                g[i] = binding
            else
                merge_binding(child, binding)
            end
        end
        merge_group(self, tree, child, g)
    end
end

---@param tree Tree
local function merge_awesome_bindings(tree)
    for _, binding in ipairs(pbinding.awesome_bindings) do
        local node = tree:ensure_path(binding.path)
        merge_binding(node, binding)
    end
end

---@param self Bindbox
---@param client? client
---@return Tree
local function build_binding_tree(self, client)
    local function group_clone(node)
        return gtable.clone(node.state, false)
    end
    local function node_filter(node)
        local group = node.state --[[@as BindboxGroup]]
        local rule = group.rule
        return not rule or (client and self._private.matcher:matches_rule(client, rule))
    end

    local binding_tree = self._private.source_binding_tree:clone(group_clone, node_filter)

    if self._private.include_awesome_bindings then
        merge_awesome_bindings(binding_tree)
    end

    for node in binding_tree:traverse() do
        table.sort(node.children, default_group_sort)
        table.sort(node.state, default_binding_sort)
    end

    return binding_tree
end

---@param self Bindbox
---@param binding_tree Tree
---@return Bindbox.data
local function build_data(self, binding_tree)
    ---@type Bindbox.data
    local data = {
        max_trigger_width = 0,
        max_description_width = 0,
    }
    for node, path in binding_tree:traverse() do
        local group = node.state --[[@as BindboxGroup]]
        if #path > 0 and #group > 0 then
            local group_markup = get_group_markup(self, node, path)
            local group_size = get_markup_geometry(self, group_markup)
            ---@type Bindbox.data.group
            local group_data = {
                markup = group_markup,
                size = group_size,
                page_break = group.page_break,
            }
            if data.max_description_width < group_data.size.width then
                data.max_description_width = group_data.size.width
            end
            for _, binding in ipairs(group) do
                if binding.description then
                    local trigger_markup = get_trigger_markup(self, binding)
                    local trigger_size = get_markup_geometry(self, trigger_markup)
                    local description_markup = get_description_markup(self, binding)
                    local description_size = get_markup_geometry(self, description_markup)
                    ---@type Bindbox.data.item
                    local item = {
                        binding = binding,
                        trigger = {
                            markup = trigger_markup,
                            size = trigger_size,
                            highlighted = nil,
                            widget = nil,
                        },
                        description = {
                            markup = description_markup,
                            size = description_size,
                            highlighted = nil,
                            widget = nil,
                        },
                    }
                    group_data[#group_data + 1] = item
                    if data.max_trigger_width < trigger_size.width then
                        data.max_trigger_width = trigger_size.width
                    end
                    if data.max_description_width < description_size.width then
                        data.max_description_width = description_size.width
                    end
                end
            end
            if #group_data > 0 then
                data[#data + 1] = group_data
            end
        end
    end
    return data
end

---@param self Bindbox
---@param data Bindbox.data
---@param width number
---@param height number
---@param filter_highlighted? boolean
---@return table
local function build_pages(self, data, width, height, filter_highlighted)
    local font = self.font or beautiful.build_font()
    local line_size = get_markup_geometry(self, "foobar")

    width = math.floor(width / self.page_columns) - ((self.page_columns - 1) * self.group_spacing)
    height = height

    local description_offset = math.ceil(self.item_spacing * 1.6)
    local max_description_width = width - data.max_trigger_width - description_offset

    -- It's useless to have too narrow description column,
    -- so set the minimum width according to the width of the "foobar" text
    local show_description_column = max_description_width >= line_size.width

    if width < 0 or width < data.max_trigger_width or height < 0 then
        return {}
    end

    local columns = {}
    local function add_column(column)
        if #column == 0 then
            return false
        end
        local widget = wibox.layout.manual(table.unpack(column))
        widget:set_forced_width(width)
        widget:set_forced_height(height)
        table.insert(columns, widget)
        return true
    end

    local next_column = { group = 1, item = 1 }
    local ignore_page_break = {}
    ::next_column::
    local current_column = {}
    local is_first_column = (#columns % self.page_columns) == 0
    local is_last_column = (#columns % self.page_columns) == (self.page_columns - 1)
    local offset_x = 0
    local offset_y = 0
    for i = next_column.group, #data do
        local initial_offset_y = offset_y

        local group = data[i]

        if not ignore_page_break[i] and group.page_break then
            ignore_page_break[i] = true
            if #columns > 0 then
                next_column.group = i
                next_column.item = 1
                if add_column(current_column) then
                    goto next_column
                else
                    goto done
                end
            end
        end

        local group_widget
        if show_description_column and (next_column.item == 1 or is_first_column) then
            group_widget = wibox.widget {
                widget = wibox.widget.textbox,
                font = font,
                align = "left",
                valign = "top",
                markup = group.markup,
                point = {
                    x = offset_x + data.max_trigger_width + description_offset,
                    y = offset_y,
                    width = max_description_width,
                    height = group.size.height,
                },
            }
            offset_y = offset_y + group_widget.point.height
            if offset_y > height then
                next_column.group = i
                next_column.item = 1
                if add_column(current_column) then
                    goto next_column
                else
                    goto done
                end
            end
            offset_y = offset_y + self.item_spacing
        end

        local item_count = 0
        for j = next_column.item, #group do
            local item = group[j]
            if not filter_highlighted or item.trigger.highlighted or item.description.highlighted then
                local trigger_offset_x = data.max_trigger_width - item.trigger.size.width
                local trigger_widget = wibox.widget {
                    widget = wibox.widget.textbox,
                    font = font,
                    align = "right",
                    valign = "top",
                    markup = item.trigger.highlighted or item.trigger.markup,
                    point = {
                        x = offset_x + (show_description_column and trigger_offset_x or 0),
                        y = offset_y,
                        width = item.trigger.size.width,
                        height = item.trigger.size.height,
                    },
                } --[[@as wibox.widget.textbox]]
                item.trigger.widget = trigger_widget
                local description_widget
                if show_description_column then
                    description_widget = wibox.widget {
                        widget = wibox.widget.textbox,
                        font = font,
                        align = "left",
                        valign = "top",
                        markup = item.description.highlighted or item.description.markup,
                        point = {
                            x = offset_x + data.max_trigger_width + description_offset,
                            y = offset_y,
                            width = max_description_width,
                        },
                    } --[[@as wibox.widget.textbox]]
                    item.description.widget = description_widget
                    description_widget.line_spacing_factor = 1 + (self.item_spacing / item.description.size.height)
                    description_widget.point.height = description_widget:get_height_for_width(max_description_width, self.screen)
                        + self.item_spacing
                    offset_y = offset_y +
                        math.max(trigger_widget.point.height, description_widget.point.height - self.item_spacing)
                else
                    offset_y = offset_y + trigger_widget.point.height
                end
                if offset_y > height then
                    next_column.group = i
                    next_column.item = j
                    if add_column(current_column) then
                        goto next_column
                    else
                        goto done
                    end
                end
                offset_y = offset_y + self.item_spacing

                if group_widget then
                    -- Add a group widget only if at least one item fits in the column
                    table.insert(current_column, group_widget)
                    group_widget = nil
                end
                table.insert(current_column, trigger_widget)
                if description_widget then
                    table.insert(current_column, description_widget)
                end
                item_count = item_count + 1
            end
        end
        next_column.item = 1

        if item_count > 0 then
            offset_y = offset_y + self.group_spacing
        else
            offset_y = initial_offset_y
        end
    end
    if #current_column > 0 then
        add_column(current_column)
    end

    ::done::
    local pages = {}
    if self.page_columns > 1 then
        for i = 1, #columns, self.page_columns do
            local page_layout = wibox.layout.fixed.horizontal()
            page_layout.spacing = self.group_spacing
            for j = 1, self.page_columns do
                local column = columns[i + j - 1]
                if column then
                    page_layout:add(column)
                end
            end
            table.insert(pages, page_layout)
        end
    else
        pages = columns
    end
    return pages
end

---@param query string
---@return string[]
local function get_find_terms(query)
    local terms = {}
    local unique_term_map = {}
    query = string.gsub(query, "%s+", " ")
    for term in string.gmatch(query, "([^%s]+)") do
        term = string.lower(term)
        if #term > 0 and not unique_term_map[term] then
            unique_term_map[term] = true
            if pcall(string.find, "", term) then
                table.insert(terms, term)
            end
        end
    end
    table.sort(terms, function(a, b) return #a > #b end)
    return terms
end

---@param self Bindbox
---@param query? string
---@param data Bindbox.data
local function find(self, query, data)
    self._private.find.query = query or ""

    local terms = get_find_terms(self._private.find.query)

    local hash = table.concat(terms, " ")
    if self._private.find.hash == hash then
        return
    end
    self._private.find.hash = hash

    for _, group in ipairs(data) do
        for _, item in ipairs(group) do
            local highlight_result = get_binding_highlighting(self, item.binding, terms)
            item.trigger.highlighted = get_trigger_markup(self, item.binding, highlight_result)
            item.trigger.widget:set_markup(item.trigger.highlighted)
            item.description.highlighted = get_description_markup(self, item.binding, highlight_result)
            item.description.widget:set_markup(item.description.highlighted)
        end
    end
end

---@param current? integer
---@param total? integer
---@return string
local function format_page_info(current, total)
    return string.format("%s/%s", tostring(current) or "-", tostring(total) or "-")
end

---@param self Bindbox
---@param page? wibox.widget.base
---@param page_info? string
local function set_page_content(self, page, page_info)
    self.widget:get_children_by_id("#page_container")[1] --[[@as wibox.container]]
        :set_widget(page)
    self.widget:get_children_by_id("#page_info")[1] --[[@as wibox.widget.textbox]]
        :set_markup(page_info or format_page_info())
end

---@return integer
function M.object:get_page()
    return self._private.current_page or 0
end

---@param page? integer
---@param force? boolean
function M.object:set_page(page, force)
    local pages = self._private.pages or {}
    local page_count = #pages

    page = page or self:get_page()
    if page < 1 then
        page = 1
    end
    if page > page_count then
        page = page_count
    end

    self._private.current_page = page

    if self.visible or force then
        if page > 0 and pages then
            set_page_content(self, pages[page], format_page_info(page, page_count))
        else
            set_page_content(self)
        end
    end
end

---@class BindboxGroup
---@field name string
---@field order? integer
---@field rule? gears.matcher.rule
---@field bg? hex_color
---@field fg? hex_color
---@field page_break? boolean
---@field groups? BindboxGroup[]

---@param group BindboxGroup
function M.object:add_group(group)
    self:add_groups { group }
end

---@param groups BindboxGroup[]
function M.object:add_groups(groups)
    merge_group(self, self._private.source_binding_tree, self._private.source_binding_tree.root, { groups = groups })
end

---@param self Bindbox
local function stop_find(self)
    awful.keygrabber.stop()
    capi.mousegrabber.stop()
end

---@param self Bindbox
---@param data Bindbox.data
---@param restore_find? boolean
local function start_find(self, data, restore_find)
    local find_text_widget = self.widget:get_children_by_id("#find_text")[1]
    local find_placeholder_widget = self.widget:get_children_by_id("#find_placeholder")[1]
    local function show_placeholder(text)
        local visible = not text or #text == 0
        find_text_widget.visible = not visible
        find_placeholder_widget.visible = visible
    end

    if restore_find then
        self._private.find = self._private.find or { query = "" }
        self._private.find.hash = nil
        find(self, self._private.find.query, data)
    else
        self._private.find = {}
    end

    find_text_widget.text = self._private.find.query or ""
    show_placeholder(self._private.find.query)

    capi.mousegrabber.stop()
    capi.mousegrabber.run(function(grab)
        if grab.buttons[btn.left] or grab.buttons[btn.right] then
            self:hide()
        elseif grab.buttons[btn.wheel_up] then
            self.page = self.page - 1
        elseif grab.buttons[btn.wheel_down] then
            self.page = self.page + 1
        end
        return true
    end, nil)

    awful.prompt.run {
        textbox = find_text_widget,
        text = self._private.find.query,
        bg_cursor = self.find_cursor_bg,
        fg_cursor = self.find_cursor_fg,
        ul_cursor = "none",
        changed_callback = function(input)
            find(self, input, data)
            show_placeholder(input)
        end,
        done_callback = function()
            self:hide()
        end,
        keypressed_callback = function(_, key)
            if key == "Return" or key == "KP_Enter" then
                return true
            elseif key == "Prior" or key == "Up" then
                self.page = self.page - 1
                return true
            elseif key == "Next" or key == "Down" then
                self.page = self.page + 1
                return true
            end
        end,
    }
end

---@param self Bindbox
---@param screen screen
---@return number width
---@return number height
local function prepare_wibox(self, screen)
    self.screen = screen

    local workarea = screen.workarea
    local workarea_width = workarea.width - beautiful.edge_gap * 2
    local workarea_height = workarea.height - beautiful.edge_gap * 2

    local page_container = self.widget:get_children_by_id("#page_container")[1]
    page_container.width = self.page_width
    page_container.height = self.page_height


    local max_width, max_height = self.widget:fit({
        screen = screen,
        dpi = screen.dpi,
        drawable = self._drawable,
    }, math.maxinteger, math.maxinteger)

    local horizontal_padding = max_width - page_container.width
    local vertical_padding = max_height - page_container.height

    local width = math.min(workarea_width - horizontal_padding, page_container.width)
    local height = math.min(workarea_height - vertical_padding, page_container.height)

    page_container.width = width
    page_container.height = height

    self.width = width + horizontal_padding
    self.height = height + vertical_padding

    return width, height
end

function M.object:hide()
    self._private.pages = nil
    self:set_page(nil, true)

    stop_find(self)

    self.visible = false
    ui_controller.leave(self)
end

---@class Bindbox.show.args
---@field client? client
---@field screen? screen

---@param args? Bindbox.show.args
function M.object:show(args)
    if self.visible or not ui_controller.enter(self) then
        return
    end

    args = args or {}

    local client = args.client or capi.client.focus
    local screen = args.screen or capi.mouse.screen
    local width, height = prepare_wibox(self, screen)
    local binding_tree = build_binding_tree(self, client)
    local data = build_data(self, binding_tree)
    local pages = build_pages(self, data, width, height)

    self._private.pages = pages
    self:set_page(1, true)

    start_find(self, data)

    self.visible = true
end

---@param args? Bindbox.show.args
---@return boolean
function M.object:toggle(args)
    if self.visible then
        self:hide()
        return false
    else
        self:show(args)
        return true
    end
end


---@class Bindbox.new.args
---@field include_awesome_bindings? boolean # Default: `false`

---@param args? Bindbox.new.args
---@return Bindbox
function M.new(args)
    args = args or {}

    local self = awful.popup {
        type = "utility",
        ontop = true,
        visible = false,
        widget = {
            id = "#padding",
            layout = wibox.container.margin,
            {
                layout = wibox.layout.align.vertical,
                expand = "inside",
                nil,
                {
                    id = "#page_container_border",
                    widget = wibox.container.margin,
                    {
                        id = "#page_container",
                        widget = wibox.container.constraint,
                        strategy = "exact",
                    },
                },
                {
                    id = "#status_container",
                    widget = capsule,
                    enable_overlay = false,
                    {
                        layout = wibox.layout.stack,
                        {
                            id = "#find_text",
                            widget = wibox.widget.textbox,
                        },
                        {
                            id = "#find_placeholder",
                            layout = wibox.container.background,
                            {
                                widget = wibox.widget.textbox,
                                text = "Type to find",
                            },
                        },
                        {
                            layout = wibox.container.place,
                            halign = "right",
                            {
                                id = "#status_bindings",
                                layout = wibox.layout.fixed.horizontal,
                                {
                                    id = "#binding_hide",
                                    widget = wibox.widget.textbox,
                                },
                                {
                                    id = "#binding_next_page",
                                    widget = wibox.widget.textbox,
                                },
                                {
                                    id = "#binding_previous_page",
                                    widget = wibox.widget.textbox,
                                },
                                {
                                    id = "#page_info",
                                    widget = wibox.widget.textbox,
                                },
                            },
                        },
                    },
                },
            },
        },
    } --[[@as Bindbox]]

    gtable.crush(self, M.object, true)

    self._private.matcher = gmatcher()
    self._private.source_binding_tree = utree.new()
    self._private.include_awesome_bindings = not not args.include_awesome_bindings

    self:initialize_style(beautiful.bindbox.default_style, self.widget)

    self:apply_style(args)

    ---@param id string
    ---@param triggers BindingTrigger.new.args
    ---@param description string
    local function set_binding_hint(id, triggers, description)
        local binding = pbinding.new {
            triggers = triggers,
            description = description,
        }
        local markup = get_trigger_markup(self, binding) .. " " .. get_description_markup(self, binding)
        self.widget:get_children_by_id(id)[1] --[[@as wibox.widget.textbox]]:set_markup(markup)
    end

    set_binding_hint("#binding_hide", "Escape", "Close")
    set_binding_hint("#binding_next_page", { btn.wheel_down, "Down", "Next" }, "Next Page")
    set_binding_hint("#binding_previous_page", { btn.wheel_up, "Up", "Prior" }, "Previous Page")

    return self
end

M.main = M.new {
    include_awesome_bindings = true,
}

return setmetatable(M, M.mt)
