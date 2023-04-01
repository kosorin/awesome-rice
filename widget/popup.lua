local capi = Capi
local math = math
local setmetatable = setmetatable
local beautiful = require("theme.manager")._beautiful
local gobject = require("gears.object")
local gtable = require("gears.table")
local awful = require("awful")
local wibox = require("wibox")
local wbase = require("wibox.widget.base")
local noice = require("theme.stylable")
local ui_controller = require("ui.controller")
local uscreen = require("utils.screen")


---@class Popup.module
---@operator call: Popup
local M = { mt = {} }

function M.mt:__call(...)
    return M.new(...)
end


---@class Popup : stylable
---@field get_bg fun(self: Popup): lgi.cairo.Pattern
---@field get_fg fun(self: Popup): lgi.cairo.Pattern
---@field get_border_color fun(self: Popup): lgi.cairo.Pattern
---@field get_border_width fun(self: Popup): number
---@field get_shape fun(self: Popup): shape|nil
---@field get_paddings fun(self: Popup): thickness
---
---@field set_bg fun(self: Popup, bg: color)
---@field set_fg fun(self: Popup, fg: color)
---@field set_border_color fun(self: Popup, border_color: color)
---@field set_border_width fun(self: Popup, border_width: number)
---@field set_shape fun(self: Popup, shape?: shape)
---@field set_paddings fun(self: Popup, paddings: thickness_value)
---
---@field package _private Popup.private
M.object = {}
---@class Popup.private
---@field wibox wibox
---@field widget_container wibox.container
---@field widget? wibox.widget.base
---@field placement? placement
---@field show_args? Popup.show.args

noice.define {
    object = M.object,
    name = "popup",
    properties = {
        visible = { proxy = true },
        opacity = { property = "opacity" },
        bg = { property = "bg" },
        fg = { property = "fg" },
        border_color = { property = "border_color" },
        border_width = { property = "border_width" },
        shape = { property = "shape" },
        paddings = { id = "#root", property = "margins" },
    },
}

---@return boolean
function M.object:get_visible()
    return self._private.wibox.visible
end

---@param visible boolean
function M.object:set_visible(visible)
    if visible then
        self:show()
    else
        self:hide()
    end
end

---@return awful.button[]
function M.object:get_buttons()
    return self._private.wibox:get_buttons()
end

---@param buttons awful.button[]
function M.object:set_buttons(buttons)
    self._private.wibox:set_buttons(buttons)
end

---@param self Popup
---@param force? boolean
local function place(self, force)
    local w = self._private.wibox
    if not force and not w.visible then
        return
    end

    local args = self._private.show_args or {}

    local coords = args.coords or capi.mouse.coords()
    local screen = args.screen
        or awful.screen.getbycoord(coords.x, coords.y)
        or capi.mouse.screen
    screen = assert(uscreen(screen))
    local bounds = screen:get_bounding_geometry({
        honor_workarea = true,
        honor_padding = false,
    })

    local border_width = self._style.current.border_width or 0
    local max_width = math.max(1, math.ceil(math.min(self._style.current.width or math.maxinteger, bounds.width) - 2 * border_width))
    local max_height = math.max(1, math.ceil(math.min(self._style.current.height or math.maxinteger, bounds.height) - 2 * border_width))
    local content = self._private.widget_container
    local width, height = wbase.fit_widget(content, { dpi = screen.dpi }, content, max_width, max_height)

    w.width = math.max(1, width)
    w.height = math.max(1, height)

    local placement_args = {
        parent = screen,
        coords = coords,
        bounding_rect = bounds,
        screen = screen,
    }

    local placement = args.placement
        or self._private.placement
        or awful.placement.centered
    placement(w, placement_args)
end

---@return placement|nil
function M.object:get_placement()
    return self._private.placement
end

---@param placement? placement
function M.object:set_placement(placement)
    if self._private.placement == placement then
        return
    end

    place(self)

    self._private.placement = placement
    self:emit_signal("property::placement", self._private.placement)
end

---@return wibox.widget.base|nil
function M.object:get_widget()
    return self._private.widget
end

---@param widget? widget_value
function M.object:set_widget(widget)
    if self._private.widget == widget then
        return
    end

    widget = widget and wbase.make_widget_from_value(widget)
    self._private.widget_container:set_widget(widget)
    place(self)

    self._private.widget = widget
    self:emit_signal("property::widget", widget)
end

---@class Popup.show.args
---@field coords? point
---@field screen? screen
---@field placement? placement

---@param args? Popup.show.args
function M.object:show(args)
    local w = self._private.wibox
    if w.visible or not ui_controller.enter(w) then
        return
    end
    self._private.show_args = args or {}

    place(self, true)

    w.visible = true
end

function M.object:hide()
    local w = self._private.wibox
    if not w.visible then
        return
    end

    w.visible = false
    ui_controller.leave(w)

    self._private.show_args = nil
end

---@param args? Popup.show.args
function M.object:toggle(args)
    if self._private.wibox.visible then
        self:hide()
    else
        self:show(args)
    end
end

---@param id string
---@return wibox.widget.base[]|nil
function M.object:get_children_by_id(id)
    return self._private.widget:get_children_by_id(id)
end


---@class Popup.new.args
---@field widget? widget_value
---@field placement? placement
---@field show? Popup.show.args|true

---@param args? Popup.new.args
---@return Popup
function M.new(args)
    args = args or {}

    local w = wibox {
        type = "utility",
        ontop = true,
        visible = false,
        widget = {
            id = "#root",
            layout = wibox.container.margin,
        },
    }

    local self = gobject { enable_properties = true } --[[@as Popup]]

    self._private = {
        wibox = w,
        widget_container = w:get_children_by_id("#root")[1] --[[@as wibox.container]],
    }

    gtable.crush(self, M.object, true)
    noice.initialize(self, nil, w)

    self:set_widget(args.widget)
    self:set_placement(args.placement)

    local show_args = args.show
    if show_args == true then
        self:show()
    elseif show_args then
        self:show(show_args)
    end

    return self
end

return setmetatable(M, M.mt)
