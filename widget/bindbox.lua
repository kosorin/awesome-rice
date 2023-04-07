local capi = Capi
local type = type
local setmetatable = setmetatable
local ipairs = ipairs
local select = select
local tostring = tostring
local math = math
local table = table
local string = string
local awful = require("awful")
local beautiful = require("theme.theme")
local gtable = require("gears.table")
local gmatcher = require("gears.matcher")
local wibox = require("wibox")
local pbinding = require("io.binding")
local mod = pbinding.modifier
local btn = pbinding.button
local utree = require("utils.tree")
local capsule = require("widget.capsule")
local noice = require("theme.style")
local pango = require("utils.pango")
local ui_controller = require("ui.controller")


local s25p = pango.span { size = "25%", " " }
local s50p = pango.span { size = "50%", " " }
local force_ltr = "&#x200E;"
local mouse_label_icon = ""
local labels = {
    [btn.left]            = mouse_label_icon .. " Left",
    [btn.middle]          = mouse_label_icon .. " Middle",
    [btn.right]           = mouse_label_icon .. " Right",
    [btn.wheel_up]        = mouse_label_icon .. " Wheel Up",
    [btn.wheel_down]      = mouse_label_icon .. " Wheel Down",
    [btn.wheel_left]      = mouse_label_icon .. " Wheel Left",
    [btn.wheel_right]     = mouse_label_icon .. " Wheel Right",
    [btn.extra_back]      = mouse_label_icon .. " Back",
    [btn.extra_forward]   = mouse_label_icon .. " Forward",
    --
    Control               = "Ctrl",
    Mod1                  = "Alt",
    ISO_Level3_Shift      = "Alt Gr",
    Mod4                  = "Super",
    --
    Insert                = "Ins",
    Delete                = "Del",
    Next                  = "PgDn",
    Prior                 = "PgUp",
    Left                  = "" .. s25p,
    Up                    = "" .. s25p,
    Right                 = "" .. s25p,
    Down                  = "" .. s25p,
    Escape                = "Esc",
    Tab                   = "Tab",
    space                 = "Space",
    Return                = "Enter",
    BackSpace             = " ",
    --
    KP_End                = "Num1",
    KP_Down               = "Num2",
    KP_Next               = "Num3",
    KP_Left               = "Num4",
    KP_Begin              = "Num5",
    KP_Right              = "Num6",
    KP_Home               = "Num7",
    KP_Up                 = "Num8",
    KP_Prior              = "Num9",
    KP_Insert             = "Num0",
    KP_Delete             = "Num.",
    KP_Divide             = "Num/",
    KP_Multiply           = "Num*",
    KP_Subtract           = "Num-",
    KP_Add                = "Num+",
    KP_Enter              = "NumEnter",
    --
    dead_acute            = "´",
    dead_circumflex       = "^",
    dead_grave            = "`",
    --
    XF86MonBrightnessUp   = "󰃟 +",
    XF86MonBrightnessDown = "󰃟 -",
    XF86AudioRaiseVolume  = force_ltr .. "ﱛ",
    XF86AudioLowerVolume  = force_ltr .. "ﱜ",
    XF86AudioMute         = force_ltr .. "ﱝ",
    XF86AudioPlay         = "契",
    XF86AudioPause        = "",
    XF86AudioStop         = "栗",
    XF86AudioPrev         = "玲",
    XF86AudioNext         = "怜",
    XF86AudioRewind       = "丹",
    XF86AudioForward      = "",
    --
    Print                 = "" .. s50p,
    XF86Calculator        = "" .. s50p,
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
---@field find_highlight_fg unknown
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
    find_highlight_fg = {},
    group_path_separator_markup = {},
    slash_separator_markup = {},
    plus_separator_markup = {},
    range_separator_markup = {},
    status_style = { id = "#status_container", property = "style" }, -- TODO: Fix me - capsule:set_style() no longer exists
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
local function get_modifier_label(modifier)
    return labels[modifier] or modifier
end

---@param trigger BindingTrigger.value
---@return string
local function get_trigger_label(trigger)
    local label
    local tt = type(trigger)
    if tt == pbinding.trigger_type.key then
        local keysym, keyprint = awful.keyboard.get_key_name(trigger)
        label = labels[keysym] or keyprint or keysym
    elseif tt == pbinding.trigger_type.button then
        label = labels[trigger]
    end
    return label or tostring(trigger)
end

---@class Bindbox.highlight.args
---@field find_terms? string[]

---@param self Bindbox
---@param text string
---@param args? Bindbox.highlight.args
---@return string
---@return boolean
local function highlight_text(self, text, args)
    text = text or ""

    if #text == 0 or not args or not args.find_terms or #args.find_terms == 0 then
        return text, true
    end

    local substitutions = {}

    local function is_available(from, to)
        for _, s in ipairs(substitutions) do
            if from <= s.to and to >= s.from then
                return false
            end
        end
        return true
    end

    local total_found = 0
    local lower_text = string.lower(text)
    for _, ft in ipairs(args.find_terms) do
        local found = false
        local from = 1
        local to
        while true do
            from, to = string.find(lower_text, ft, from, true)
            if from == nil then
                break
            end
            if is_available(from, to) then
                table.insert(substitutions, { matched = true, from = from, to = to })
                if not found then
                    found = true
                    total_found = total_found + 1
                end
            end
            from = to + 1
        end
    end

    if total_found ~= #args.find_terms then
        return pango.span {
            fgcolor = self.find_dim_fg,
            bgcolor = self.find_dim_bg,
            pango.escape(text),
        }, false
    end

    table.sort(substitutions, function(a, b) return a.from < b.from end)

    local parts = {}
    local length = #text
    local next_substitution = substitutions[1]
    local i = 1
    while i <= length do
        if next_substitution then
            if next_substitution.from == i then
                table.insert(parts, next_substitution)
                i = next_substitution.to + 1
                table.remove(substitutions, 1)
                next_substitution = substitutions[1]
            else
                table.insert(parts, { from = i, to = next_substitution.from - 1 })
                i = next_substitution.from
            end
        else
            table.insert(parts, { from = i, to = length })
            break
        end
    end

    return table.concat(gtable.map(function(part)
        local capture = string.sub(text, part.from, part.to)
        if part.matched then
            return pango.span {
                fgcolor = self.find_highlight_fg,
                bgcolor = self.find_highlight_bg,
                bgalpha = "100%",
                pango.escape(capture),
            }
        else
            return capture
        end
    end, parts), ""), true
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
---@return string
local function get_trigger_markup(self, binding)
    local function trigger_box(content)
        return pango.span {
            bgcolor = self.trigger_bg,
            bgalpha = self.trigger_bg_alpha,
            " ",
            content,
            " ",
        }
    end

    local modifier_markup = ""
    if #binding.modifiers > 0 then
        local modifier_label_markups = gtable.map(function(m)
            return trigger_box(get_modifier_label(m))
        end, binding.modifiers)
        modifier_markup = table.concat(modifier_label_markups, self.plus_separator_markup) ..
            self.plus_separator_markup
    end

    local trigger_text
    if binding.text then
        trigger_text = binding.text
    else
        if binding.from and binding.to then
            local from = get_trigger_label(binding.from)
            local to = get_trigger_label(binding.to)
            trigger_text = from .. self.range_separator_markup .. to
        else
            local trigger_labels = gtable.map(function(t)
                return get_trigger_label(t.trigger)
            end, binding.triggers)
            trigger_text = table.concat(trigger_labels, self.slash_separator_markup)
        end
    end

    if binding.target then
        trigger_text = trigger_text .. pango.span {
            fgalpha = "50%",
            size = "smaller",
            " (",
            pango.escape(binding.target),
            ")",
        }
    end

    return modifier_markup .. trigger_box(trigger_text)
end

---@param self Bindbox
---@param binding Binding
---@param highlight_args? Bindbox.highlight.args
---@return string
local function get_description_markup(self, binding, highlight_args)
    return select(1, highlight_text(self, binding.description, highlight_args))
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

    local max_description_width = width - data.max_trigger_width - self.item_spacing

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
                    x = offset_x + data.max_trigger_width + self.item_spacing,
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
                            x = offset_x + data.max_trigger_width + self.item_spacing,
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

    local highlight_args = {
        find_terms = terms,
    }

    for _, group in ipairs(data) do
        for _, item in ipairs(group) do
            item.trigger.highlighted = get_trigger_markup(self, item.binding)
            item.trigger.widget:set_markup(item.trigger.highlighted)
            item.description.highlighted = get_description_markup(self, item.binding, highlight_args)
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
---@field groups BindboxGroup[]

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
    local workarea_width = workarea.width - beautiful.gap * 4
    local workarea_height = workarea.height - beautiful.gap * 4

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
---@field include_awesome_bindings? boolean # Default: `true`

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
    self._private.include_awesome_bindings = args.include_awesome_bindings ~= false

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

return setmetatable(M, M.mt)
