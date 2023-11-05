local capi = Capi
local type = type
local tonumber = tonumber
local setmetatable = setmetatable
local ipairs = ipairs
local math = math
local awful = require("awful")
local beautiful = require("theme.theme")
local gtable = require("gears.table")
local grectangle = require("gears.geometry").rectangle
local gtimer = require("gears.timer")
local wibox = require("wibox")
local base = require("wibox.widget.base")
local binding = require("core.binding")
local mod = binding.modifier
local btn = binding.button
local widget_helper = require("core.widget")
local gmath = require("gears.math")
local noice = require("core.style")
local templates = require("widget.mebox.templates")
local ui_controller = require("ui.controller")


---@param value? any
---@return sign
local function sign(value)
    return gmath.sign(tonumber(value) or 0)
end

---@todo Create helper function
---@param screen? iscreen
---@return screen|nil
local function get_screen(screen)
    return screen and capi.screen[screen]
end


---@class Mebox.module
---@operator call: Mebox
local M = { mt = {} }

function M.mt:__call(...)
    return M.new(...)
end

---@alias Mebox.items_source (fun(menu: Mebox, args: Mebox.show.args, context: Mebox.context): MeboxItem.args[])|MeboxItem.args[]

---@alias MeboxItem.args (fun(menu: Mebox, args: Mebox.show.args, context: Mebox.context): MeboxItem)|MeboxItem

---@alias MeboxItem.submenu (fun(parent: Mebox): Mebox.new.args)|Mebox.new.args

---@class MeboxItem
---@field index integer
---@field visible boolean
---@field enabled boolean
---@field selected boolean
---@field mouse_move_select? boolean
---@field mouse_move_show_submenu? boolean
---@field cache_submenu? boolean
---@field submenu? MeboxItem.submenu
---@field callback? fun(item: MeboxItem, menu: Mebox, context: Mebox.context): boolean?
---@field on_show? fun(item: MeboxItem, menu: Mebox, args: Mebox.show.args, context: Mebox.context): boolean?
---@field on_hide? fun(item: MeboxItem, menu: Mebox)
---@field on_ready? fun(item_widget?: wibox.widget.base, item: MeboxItem, menu: Mebox, args: Mebox.show.args, context: Mebox.context)
---@field layout_id? string
---@field layout_add? fun(layout: wibox.layout, item_widget: wibox.widget.base)
---@field buttons_builder? fun(item: MeboxItem, menu: Mebox, default_click_action: function): awful.button[]
---@field template? widget_template

---@class Mebox.context
---@field action? "callback"|"submenu"
---@field source? "keyboard"|"mouse"
---@field select_parent? boolean

---@class Mebox : wibox, stylable
---@field package _private Mebox.private
---Style properties:
---@field paddings thickness
---@field item_width number
---@field item_height number
---@field placement placement
---@field placement_bounding_args table
---@field active_opacity number
---@field inactive_opacity number
---@field submenu_offset number
M.object = {}
---@class Mebox.private
---@field parent? Mebox
---@field active_submenu? { index: integer, menu: Mebox }
---@field submenu_delay? number|boolean
---@field submenu_delay_timer? gears.timer
---@field submenu_delay_callback? function
---@field submenu_cache? (Mebox|false)[]
---@field items? MeboxItem[]
---@field item_widgets? (wibox.widget.base|false)[]
---@field selected_index? integer
---@field orientation orientation
---@field layout? wibox.layout
---@field layout_template widget_value
---@field layout_container wibox.container
---@field layout_navigator? fun(menu: Mebox, x: sign, y: sign, direction?: direction, context: Mebox.context)
---@field items_source Mebox.items_source
---@field on_show? fun(menu: Mebox, args: Mebox.show.args, context: Mebox.context): boolean
---@field on_hide? fun(menu: Mebox)
---@field on_ready? fun(menu: Mebox, args: Mebox.show.args, context: Mebox.context)
---@field mouse_move_select boolean
---@field mouse_move_show_submenu boolean
---@field keygrabber_auto boolean
---@field keygrabber awful.keygrabber
---@field item_template widget_template
---@field separator_template widget_template
---@field header_template widget_template
---@field info_template widget_template
---@field is_hiding boolean

noice.define_style(M.object, {
    bg = { proxy = true },
    fg = { proxy = true },
    border_color = { proxy = true },
    border_width = { proxy = true },
    shape = { proxy = true },
    paddings = { id = "#layout_container", property = "margins" },
    item_width = {},
    item_height = {},
    placement = {},
    placement_bounding_args = {},
    active_opacity = {},
    inactive_opacity = {},
    submenu_offset = {},
})

---@param menu Mebox
---@return MeboxItem
function M.separator(menu)
    return {
        enabled = false,
        template = menu._private.separator_template,
    }
end

---@param text string
---@return fun(menu: Mebox): MeboxItem
function M.header(text)
    return function(menu)
        return {
            enabled = false,
            text = text,
            template = menu._private.header_template,
        }
    end
end

---@param text string
---@return fun(menu: Mebox): MeboxItem
function M.info(text)
    return function(menu)
        return {
            enabled = false,
            text = text,
            template = menu._private.info_template,
        }
    end
end

M.placement = {}

---@param menu Mebox
---@param args { geometry?: geometry, coords: point, bounding_rect: geometry }
function M.placement.default(menu, args)
    local border_width = menu.border_width
    local width = menu.width + 2 * border_width
    local height = menu.height + 2 * border_width
    local min_x = args.bounding_rect.x
    local min_y = args.bounding_rect.y
    local max_x = min_x + args.bounding_rect.width - width
    local max_y = min_y + args.bounding_rect.height - height

    local x, y

    if args.geometry then
        local paddings = menu.paddings
        local submenu_offset = menu.submenu_offset

        x = args.geometry.x + args.geometry.width + submenu_offset
        if x > max_x then
            x = args.geometry.x - width - submenu_offset
        end
        y = args.geometry.y - paddings.top - border_width
    else
        local coords = args.coords
        x = coords.x
        y = coords.y
    end

    menu.x = x < min_x and min_x or (x > max_x and max_x or x)
    menu.y = y < min_y and min_y or (y > max_y and max_y or y)
end

---@param menu Mebox
---@param args { geometry?: geometry, coords: point, bounding_rect: geometry }
function M.placement.confirmation(menu, args)
    local border_width = menu.border_width
    local width = menu.width + 2 * border_width
    local height = menu.height + 2 * border_width
    local min_x = args.bounding_rect.x
    local min_y = args.bounding_rect.y
    local max_x = min_x + args.bounding_rect.width - width
    local max_y = min_y + args.bounding_rect.height - height

    local parent_border_width = menu._private.parent.border_width
    local parent_paddings = menu._private.parent.paddings
    local paddings = menu.paddings
    local x = args.geometry.x - parent_paddings.left - parent_border_width
    local y = args.geometry.y - paddings.top - border_width

    menu.x = x < min_x and min_x or (x > max_x and max_x or x)
    menu.y = y < min_y and min_y or (y > max_y and max_y or y)
end

---@param menu Mebox
---@param args? Mebox.show.args
local function place(menu, args)
    args = args or {}

    local coords = args.coords or capi.mouse.coords()
    local screen = args.screen
        or awful.screen.getbycoord(coords.x, coords.y)
        or capi.mouse.screen
    screen = assert(get_screen(screen))
    local bounds = screen:get_bounding_geometry(menu.placement_bounding_args)

    local border_width = menu.border_width
    local max_width = bounds.width - 2 * border_width
    local max_height = bounds.height - 2 * border_width
    local width, height = base.fit_widget(menu._private.layout_container, { dpi = screen.dpi }, menu._private.layout_container, max_width, max_height)

    menu.width = math.max(1, width)
    menu.height = math.max(1, height)

    local parent = menu._private.parent
    local placement_args = {
        geometry = parent and parent:get_item_geometry(parent._private.active_submenu.index),
        coords = coords,
        bounding_rect = bounds,
        screen = screen,
    }

    local placement = args.placement
        or menu.placement
        or M.placement.default
    placement(menu, placement_args)
end

---@param item MeboxItem
---@param menu Mebox
---@return widget_template
local function get_item_template(item, menu)
    return (item and item.template) or (menu and menu._private.item_template)
end

---@param menu Mebox
---@param keep_selected_index boolean
local function fix_selected_item(menu, keep_selected_index)
    local actual_selected_index

    for index = 1, #menu._private.items do
        local item = menu._private.items[index]

        if keep_selected_index then
            item.selected = index == menu._private.selected_index
            if item.selected then
                actual_selected_index = index
            end
        else
            if item.selected then
                if actual_selected_index then
                    item.selected = false
                else
                    actual_selected_index = index
                end
            end
        end

        local item_widget = menu:get_item_widget(index)
        if item_widget then
            menu:update_item(index)
        end
    end

    menu._private.selected_index = actual_selected_index
end

---@param index integer
---@return wibox.widget.base|nil
function M.object:get_item_widget(index)
    -- Leave it as it is!
    -- Return `nil` if item widget is `false`
    return self._private.item_widgets[index] or nil
end

---@param index integer
---@return geometry|nil
function M.object:get_item_geometry(index)
    local border_width = self.border_width
    local geometry = self:geometry()
    local item_widget = self:get_item_widget(index)
    if not item_widget then
        return
    end

    local item_geometry = widget_helper.find_geometry(item_widget, self)
    return item_geometry and {
        x = geometry.x + item_geometry.x + border_width,
        y = geometry.y + item_geometry.y + border_width,
        width = item_geometry.width,
        height = item_geometry.height,
    }
end

---Returns `true` if item at specified index is visible and enabled.
---@param index? integer
---@return boolean
function M.object:is_item_active(index)
    local item = self._private.items[index]
    return item and item.visible and item.enabled
end

---@param index? integer
function M.object:update_item(index)
    if not self._private.items then
        return
    end
    local item = index and self._private.items[index]
    local item_widget = index and self:get_item_widget(index)
    if not item or not item_widget then
        return
    end
    local template = get_item_template(item, self)
    if type(template.update_callback) == "function" then
        template.update_callback(item_widget, item, self)
    end
end

---@param menu Mebox
---@param submenu Mebox
---@param submenu_index integer
local function attach_active_submenu(menu, submenu, submenu_index)
    assert(not menu._private.active_submenu)
    menu._private.active_submenu = {
        menu = submenu,
        index = submenu_index,
    }
    menu.opacity = menu.inactive_opacity or 1
    menu:unselect()
end

---@param menu Mebox
local function detach_active_submenu(menu)
    if menu._private.active_submenu then
        local clear_parent = true
        local submenu = menu._private.active_submenu.menu
        if menu._private.submenu_cache then
            local cached_submenu = menu._private.submenu_cache[menu._private.active_submenu.index]
            if cached_submenu ~= false then
                assert(submenu == cached_submenu)
                clear_parent = false
            end
        end
        if clear_parent then
            submenu._private.parent = nil
        end
    end
    menu._private.active_submenu = nil
    menu.opacity = menu.active_opacity or 1
end

---@param menu Mebox
local function hide_active_submenu(menu)
    if menu._private.active_submenu then
        menu._private.active_submenu.menu:hide()
        detach_active_submenu(menu)
    end
end

---@return Mebox
function M.object:get_active_menu()
    local active = self
    while active._private.active_submenu do
        active = active._private.active_submenu.menu
    end
    return active
end

---@return Mebox
function M.object:get_root_menu()
    local root = self
    ---@diagnostic disable-next-line: need-check-nil
    while root._private.parent do
        root = root._private.parent
    end
    ---@diagnostic disable-next-line: return-type-mismatch
    return root
end

---@param index integer
---@param context Mebox.context
function M.object:show_submenu(index, context)
    context = context or {}

    if self._private.active_submenu then
        if self._private.active_submenu.index == index then
            return
        else
            hide_active_submenu(self)
        end
    end

    index = index or self._private.selected_index
    if not self:is_item_active(index) then
        return
    end
    ---@cast index -nil

    local item = self._private.items[index]
    if not item.submenu then
        return
    end

    local submenu = self._private.submenu_cache and self._private.submenu_cache[index]
    if not submenu then
        local submenu_args = type(item.submenu) == "function"
            and item.submenu(self) --[[@as Mebox.new.args]]
            or item.submenu
        submenu = M.new(submenu_args, true)
        submenu._private.parent = self
        if self._private.submenu_cache then
            self._private.submenu_cache[index] = item.cache_submenu ~= false and submenu
        end
    end

    attach_active_submenu(self, submenu, index)

    submenu:show(nil, context)
end

function M.object:hide_all()
    local root_menu = self:get_root_menu()
    if root_menu then
        root_menu:hide()
    end
end

---@param context? Mebox.context
function M.object:hide(context)
    if not self.visible then
        return
    end

    if self._private.is_hiding then
        return
    end
    self._private.is_hiding = true

    context = context or {}

    if self._private.submenu_delay_timer then
        self._private.submenu_delay_timer:stop()
    end
    self._private.submenu_delay_timer = nil
    self._private.submenu_delay_callback = nil

    hide_active_submenu(self)

    local parent = self._private.parent
    if parent and parent._private.active_submenu then
        if context.source == "keyboard" or context.select_parent then
            parent:select(parent._private.active_submenu.index)
        end
        detach_active_submenu(parent)
    end

    for _, item in ipairs(self._private.items) do
        if type(item.on_hide) == "function" then
            item.on_hide(item, self)
        end
    end

    if type(self._private.on_hide) == "function" then
        self._private.on_hide(self)
    end
    self:emit_signal("menu::hide", context)

    if self._private.keygrabber_auto and self._private.keygrabber then
        self._private.keygrabber:stop()
    end

    self.visible = false
    self._private.is_hiding = false

    self._private.layout = nil
    self._private.layout_container:set_widget(nil)
    self._private.items = nil
    self._private.item_widgets = nil
    self._private.selected_index = nil

    ui_controller.leave(self)
end

---@param self Mebox
---@param args Mebox.show.args
---@param context Mebox.context
local function add_items(self, args, context)
    local items = type(self._private.items_source) == "function"
        and self._private.items_source(self, args, context)
        or self._private.items_source
    ---@cast items MeboxItem[]
    for index, item in ipairs(items) do
        if type(item) == "function" then
            item = item(self, args, context)
        end
        self._private.items[index] = item

        item.index = index
        item.selected = false

        if type(item.on_show) == "function" then
            if item.on_show(item, self, args, context) == false then
                item.visible = false
            end
        end

        item.visible = item.visible == nil or item.visible ~= false
        item.enabled = item.enabled == nil or item.enabled ~= false
        item.selected = item.selected == nil or item.selected ~= false

        if item.visible then
            local item_template = get_item_template(item, self)
            local item_widget = assert(base.make_widget_from_value(item_template))

            local function click_action()
                self:execute(index, { source = "mouse" })
            end

            item_widget.buttons = item.buttons_builder
                and item.buttons_builder(item, self, click_action)
                or binding.awful_buttons {
                    binding.awful({}, btn.left, click_action),
                }

            item_widget:connect_signal("mouse::enter", function()
                local select = item.mouse_move_select
                if select == nil then
                    select = self._private.mouse_move_select
                end
                if select then
                    self:select(index)
                end

                local show_submenu = item.mouse_move_show_submenu
                if show_submenu == nil then
                    show_submenu = self._private.mouse_move_show_submenu
                end
                if show_submenu then
                    context = setmetatable({ source = "mouse" }, context)
                    local p = self:get_root_menu()._private
                    if p.submenu_delay_timer then
                        p.submenu_delay_callback = function()
                            self:show_submenu(index, context)
                        end
                        p.submenu_delay_timer:again()
                    else
                        self:show_submenu(index, context)
                    end
                else
                    hide_active_submenu(self)
                end
            end)

            item_widget:connect_signal("mouse::leave", function()
                local p = self:get_root_menu()._private
                if p.submenu_delay_timer then
                    p.submenu_delay_timer:stop()
                end
                p.submenu_delay_callback = nil
            end)

            local layout = item.layout_id
                and self._private.layout:get_children_by_id(item.layout_id)[1]
                or self._private.layout
            ---@cast layout wibox.layout

            local layout_add = item.layout_add or assert(layout.add)
            layout_add(layout, item_widget)

            self._private.item_widgets[index] = item_widget
        else
            self._private.item_widgets[index] = false
        end
    end
end

---@class Mebox.show.args
---@field selected_index? integer
---@field coords? point
---@field screen? screen
---@field placement? placement

---@param args? Mebox.show.args
---@param context? Mebox.context
---@param force? boolean
function M.object:show(args, context, force)
    local root_menu = self:get_root_menu()

    if root_menu == self then
        local p = root_menu._private

        if p.submenu_delay_timer then
            p.submenu_delay_timer:stop()
        end

        p.submenu_delay_timer = nil
        p.submenu_delay_callback = nil

        local delay = p.submenu_delay
        if delay == true then
            delay = 0.25
        end

        if delay then
            ---@cast delay number
            p.submenu_delay_timer = gtimer {
                timeout = delay,
                autostart = false,
                call_now = false,
                callback = function()
                    if p.submenu_delay_timer then
                        p.submenu_delay_timer:stop()
                    end
                    if root_menu.visible and p.submenu_delay_callback then
                        p.submenu_delay_callback()
                    end
                    p.submenu_delay_callback = nil
                end,
            }
        end
    end

    if not force and (self.visible or not ui_controller.enter(root_menu)) then
        return
    end

    args = args or {}
    context = context or {}

    if type(self._private.on_show) == "function" then
        if self._private.on_show(self, args, context) == false then
            return
        end
    end
    self:emit_signal("menu::show", args, context)

    self._private.layout = base.make_widget_from_value(self._private.layout_template) --[[@as wibox.layout]]
    self._private.layout_container:set_widget(self._private.layout)
    self._private.items = {}
    self._private.item_widgets = {}
    self._private.selected_index = nil

    add_items(self, args, context)

    if type(self._private.on_ready) == "function" then
        self._private.on_ready(self, args, context)
    end
    for index, item in ipairs(self._private.items) do
        if type(item.on_ready) == "function" then
            local item_widget = self:get_item_widget(index)
            item.on_ready(item_widget, item, self, args, context)
        end
    end
    self:emit_signal("menu::ready", args, context)

    if self._private.keygrabber_auto and self._private.keygrabber then
        self._private.keygrabber:start()
    end

    self._private.selected_index = args.selected_index
    fix_selected_item(self, true)

    if self._private.selected_index == nil and context.source == "keyboard" then
        self:select_next("begin")
    end

    place(self, args)

    self._private.is_hiding = false
    self.visible = true
end

---@param args? Mebox.show.args
---@param context? Mebox.context
function M.object:toggle(args, context)
    if self.visible then
        self:hide(context)
        return false
    else
        self:show(args, context)
        return true
    end
end

function M.object:unselect()
    local index = self._private.selected_index

    self._private.selected_index = nil

    local item = self._private.items[index]
    if item then
        item.selected = false
    end

    self:update_item(index)
end

---@param index? integer
---@return boolean
function M.object:select(index)
    if not self:is_item_active(index) then
        return false
    end
    ---@cast index -nil

    self:unselect()

    self._private.selected_index = index

    local item = self._private.items[index]
    if item then
        item.selected = true
    end

    self:update_item(index)
    return true
end

---@param index? integer
---@param context? Mebox.context
function M.object:execute(index, context)
    index = index or self._private.selected_index
    if not self:is_item_active(index) then
        return
    end
    ---@cast index -nil

    context = context or {}

    local item = self._private.items[index]
    local done

    local function can_process(action)
        return done == nil
            and item[action]
            and (context.action == nil or context.action == action)
    end

    if can_process("submenu") then
        self:show_submenu(index, context)
        done = false
    end

    if can_process("callback") then
        done = item.callback(item, self, context) ~= false
    end

    if done then
        self:hide_all()
    end
end

---@param direction? sign|"begin"|"end"
---@param seek_origin integer|"begin"|"end"
---@overload fun(seek_origin: "begin"|"end")
function M.object:select_next(direction, seek_origin)
    if not self._private.items then
        return
    end
    local count = #self._private.items
    if count < 1 then
        return
    end

    if direction == "begin" then
        seek_origin = direction
        direction = 1
    elseif direction == "end" then
        seek_origin = direction
        direction = -1
    else
        direction = sign(direction)
    end

    local index
    if type(seek_origin) == "number" then
        index = seek_origin
    elseif seek_origin == "begin" then
        index = 0
    elseif seek_origin == "end" then
        index = count + 1
    else
        index = self._private.selected_index or 0
    end

    if direction == 0 then
        return
    end
    for _ = 1, count do
        index = index + direction
        if index < 1 then
            index = count
        elseif index > count then
            index = 1
        end

        if self:select(index) then
            return
        end
    end
end

M.layout_navigators = {}

---@param menu Mebox
---@param x? sign
---@param y? sign
---@param direction? direction
---@param context Mebox.context
function M.layout_navigators.direction(menu, x, y, direction, context)
    local current_region_index
    local current_region
    local boundary = {}
    local regions = {}
    local region_map = {}
    local i = 0
    for index, item_widget in ipairs(menu._private.item_widgets) do
        if item_widget then
            local region = widget_helper.find_geometry(item_widget, menu)
            if region then
                i = i + 1
                regions[i] = region
                region_map[i] = index
                if index == menu._private.selected_index then
                    current_region_index = i
                    current_region = region
                end

                if not boundary.left or boundary.left > region.x then
                    boundary.left = region.x
                end
                if not boundary.top or boundary.top > region.y then
                    boundary.top = region.y
                end
                if not boundary.right or boundary.right < region.x + region.width then
                    boundary.right = region.x + region.width
                end
                if not boundary.bottom or boundary.bottom < region.y + region.height then
                    boundary.bottom = region.y + region.height
                end
            end
        end
    end

    if not current_region then
        if direction == "down" or direction == "right" then
            menu:select_next("begin")
        elseif direction == "up" or direction == "left" then
            menu:select_next("end")
        end
        return
    end

    -- TODO: Swap left/right if submenu on other side
    if direction == "left" then
        regions[#regions + 1] = {
            x = boundary.left - 2,
            y = boundary.top,
            width = 1,
            height = boundary.bottom - boundary.top,
        }
    elseif direction == "right" then
        regions[#regions + 1] = {
            x = boundary.right + 1,
            y = boundary.top,
            width = 1,
            height = boundary.bottom - boundary.top,
        }
    end

    local found = false
    repeat
        local target_region_index = grectangle.get_in_direction(direction, regions, current_region)
        if not target_region_index or target_region_index == current_region_index then
            break
        end

        local index = region_map[target_region_index]
        if index then
            found = menu:select(index)
            if not found then
                current_region_index = target_region_index
                current_region = regions[current_region_index]
            end
        elseif target_region_index > #region_map then
            if direction == "left" then
                if menu._private.parent then
                    menu:hide(context)
                end
                found = true
            elseif direction == "right" then
                menu:execute(nil, setmetatable({ action = "submenu" }, { __index = context }))
                found = true
            end
        end
    until found
end

---@param x? sign
---@param y? sign
---@param direction? direction
---@param context? Mebox.context
function M.object:navigate(x, y, direction, context)
    context = context or {}
    local layout_navigator = type(self._private.layout_navigator) == "function"
        and self._private.layout_navigator
        or M.layout_navigators.direction
    layout_navigator(self, sign(x), sign(y), direction, context)
end

---@class Mebox.new.args
---@field orientation? orientation
---@field layout_template? widget_value -- TODO: Rename `layout_template` property
---@field layout_navigator? fun(menu: Mebox, x: sign, y: sign, direction?: direction, context: Mebox.context)
---@field submenu_delay? number|boolean
---@field cache_submenus? boolean
---@field items_source Mebox.items_source
---@field on_show? fun(menu: Mebox, args: Mebox.show.args, context: Mebox.context): boolean?
---@field on_hide? fun(menu: Mebox)
---@field on_ready? fun(menu: Mebox, args: Mebox.show.args, context: Mebox.context)
---@field mouse_move_select? boolean
---@field mouse_move_show_submenu? boolean
---@field keygrabber_auto? boolean
---@field keygrabber_builder? fun(menu: Mebox): awful.keygrabber
---@field buttons_builder? fun(menu: Mebox): awful.button[]
---@field item_template? widget_template
---@field separator_template? widget_template
---@field header_template? widget_template
---@field info_template? widget_template
---@field [integer] MeboxItem.args -- TODO: Remove this, always use `items_source`

---@param args? Mebox.new.args
---@param is_submenu? boolean
---@return Mebox
function M.new(args, is_submenu)
    args = args or {}

    local self = wibox {
        type = "popup_menu",
        ontop = true,
        visible = false,
        widget = {
            id = "#layout_container",
            layout = wibox.container.margin,
        },
    }
    ---@cast self Mebox

    gtable.crush(self, M.object, true)

    self._private.submenu_delay = args.submenu_delay == nil or args.submenu_delay
    self._private.submenu_cache = args.cache_submenus ~= false and {} or nil
    self._private.items_source = args.items_source or args
    self._private.on_show = args.on_show
    self._private.on_hide = args.on_hide
    self._private.on_ready = args.on_ready
    self._private.mouse_move_select = args.mouse_move_select == true
    self._private.mouse_move_show_submenu = args.mouse_move_show_submenu ~= false

    self._private.orientation = args.orientation or "vertical"
    self._private.layout_navigator = args.layout_navigator
    self._private.layout_template = args.layout_template or wibox.layout.fixed[self._private.orientation]
    self._private.layout_container = self:get_children_by_id("#layout_container")[1] --[[@as wibox.container]]
    self._private.item_template = args.item_template or templates.item
    self._private.separator_template = args.separator_template or templates.separator
    self._private.header_template = args.header_template or templates.header
    self._private.info_template = args.info_template or templates.info

    self.buttons = type(args.buttons_builder) == "function"
        and args.buttons_builder(self)
        or binding.awful_buttons {
            binding.awful({}, btn.right, function() self:hide() end),
        }

    if not is_submenu then
        self._private.keygrabber_auto = args.keygrabber_auto ~= false
        self._private.keygrabber = type(args.keygrabber_builder) == "function"
            and args.keygrabber_builder(self)
            or awful.keygrabber {
                keybindings = binding.awful_keys {
                    binding.awful({}, {
                        { trigger = "Left", x = -1, direction = "left" },
                        { trigger = "h", x = -1, direction = "left" },
                        { trigger = "Right", x = 1, direction = "right" },
                        { trigger = "l", x = 1, direction = "right" },
                        { trigger = "Up", y = -1, direction = "up" },
                        { trigger = "k", y = -1, direction = "up" },
                        { trigger = "Down", y = 1, direction = "down" },
                        { trigger = "j", y = 1, direction = "down" },
                    }, function(trigger)
                        local active_menu = self:get_active_menu()
                        active_menu:navigate(trigger.x, trigger.y, trigger.direction, { source = "keyboard" })
                    end),
                    binding.awful({}, {
                        { trigger = "Home", direction = "begin" },
                        { trigger = "End", direction = "end" },
                    }, function(trigger)
                        local active_menu = self:get_active_menu()
                        active_menu:select_next(trigger.direction)
                    end),
                    binding.awful({}, "Tab", function()
                        local active_menu = self:get_active_menu()
                        active_menu:select_next(1)
                    end),
                    binding.awful({ mod.shift }, "Tab", function()
                        local active_menu = self:get_active_menu()
                        active_menu:select_next(-1)
                    end),
                    binding.awful({}, "Return", function()
                        local active_menu = self:get_active_menu()
                        active_menu:execute(nil, { source = "keyboard" })
                    end),
                    binding.awful({ mod.shift }, "Return", function()
                        local active_menu = self:get_active_menu()
                        active_menu:execute(nil, { source = "keyboard", action = "callback" })
                    end),
                    binding.awful({}, "Escape", function()
                        self:hide({ source = "keyboard" })
                    end),
                    binding.awful({ mod.shift }, "Escape", function()
                        local active_menu = self:get_active_menu()
                        active_menu:hide({ source = "keyboard" })
                    end),
                },
            }
    end

    self:initialize_style(beautiful.mebox.default_style, self.widget)

    self:apply_style(args)

    return self
end

return setmetatable(M, M.mt)
