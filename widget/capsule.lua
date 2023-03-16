local setmetatable = setmetatable
local beautiful = require("theme.theme")
local gtable = require("gears.table")
local wibox = require("wibox")
local base = require("wibox.widget.base")
local noice = require("theme.style")


---@class Capsule.module
---@operator call: Capsule
local M = { mt = {} }

function M.mt:__call(...)
    return M.new(...)
end


---@class Capsule : wibox.widget.base, stylable
---@field package _private Capsule.private
---Style properties:
---@field bg color
---@field fg color
---@field border_color color
---@field border_width number
---@field shape shape
---@field margins thickness
---@field paddings thickness
---@field hover_overlay color
---@field press_overlay color
M.object = {}
---@class Capsule.private
---@field layout wibox.widget.base
---@field content_container wibox.container
---@field enable_overlay boolean

noice.define_style(M.object, {
    bg = { id = "#background", property = "bg" },
    fg = { id = "#background", property = "fg" },
    border_color = { id = "#background", property = "border_color" },
    border_width = { id = "#background", property = "border_width" },
    shape = { id = "#background", property = "shape" },
    margins = { id = "#margin", property = "margins" },
    paddings = { id = "#padding", property = "margins" },
    hover_overlay = { id = "#hover_overlay", property = "bg" },
    press_overlay = { id = "#press_overlay", property = "bg" },
})

---@param _ any
---@param width any
---@param height any
---@return widget_layout_result[]|nil
function M.object:layout(_, width, height)
    if not self._private.layout then
        return
    end
    return { base.place_widget_at(self._private.layout, 0, 0, width, height) }
end

---@param context widget_context
---@param width number
---@param height number
---@return number width
---@return number height
function M.object:fit(context, width, height)
    if not self._private.layout then
        return 0, 0
    end
    return base.fit_widget(self, context, self._private.layout, width, height)
end

---@return wibox.widget.base|nil
function M.object:get_widget()
    return self._private.content_container:get_widget()
end

---@param widget? widget_value
function M.object:set_widget(widget)
    if self._private.content_container:get_widget() == widget then
        return
    end

    widget = widget and base.make_widget_from_value(widget)
    if widget then
        base.check_widget(widget)
    end

    self._private.content_container:set_widget(widget)
    self:emit_signal("property::widget")
end

---@return wibox.widget.base[]
function M.object:get_children()
    return self._private.content_container:get_children()
end

---@param children wibox.widget.base[]
function M.object:set_children(children)
    self:set_widget(children[1])
end

---@return boolean
function M.object:get_enable_overlay()
    return self._private.enable_overlay
end

---@param enable? boolean
function M.object:set_enable_overlay(enable)
    enable = not not enable
    if self._private.enable_overlay == enable then
        return
    end
    self._private.enable_overlay = enable

    local overlay = self._private.layout:get_children_by_id("#overlay")[1]
    if overlay then
        overlay.visible = self._private.enable_overlay
    end
end


---@class Capsule.new.args
---@field widget? widget_value
---@field enable_overlay? boolean

---@param args? Capsule.new.args
---@return Capsule
function M.new(args)
    args = args or {}

    local self = base.make_widget(nil, nil, { enable_properties = true }) --[[@as Capsule]]

    gtable.crush(self, M.object, true)

    self._private.layout = wibox.widget {
        id = "#margin",
        layout = wibox.container.margin,
        {
            id = "#background",
            layout = wibox.container.background,
            {
                id = "#background_content",
                layout = wibox.layout.stack,
                {
                    id = "#overlay",
                    layout = wibox.container.background,
                    visible = false,
                    {
                        layout = wibox.layout.stack,
                        {
                            id = "#hover_overlay",
                            layout = wibox.container.background,
                            visible = false,
                        },
                        {
                            id = "#press_overlay",
                            layout = wibox.container.background,
                            visible = false,
                        },
                    },
                },
                {
                    id = "#padding",
                    layout = wibox.container.margin,
                    {
                        id = "#content_container",
                        layout = wibox.container.constraint,
                    },
                },
            },
        },
    }

    self._private.content_container = self._private.layout:get_children_by_id("#content_container")[1] --[[@as wibox.container]]

    self:set_widget(args.widget)

    local hover_overlay = self._private.layout:get_children_by_id("#hover_overlay")[1]
    local press_overlay = self._private.layout:get_children_by_id("#press_overlay")[1]

    self:connect_signal("mouse::enter", function()
        hover_overlay.visible = true
    end)
    self:connect_signal("mouse::leave", function()
        hover_overlay.visible = false
        press_overlay.visible = false
    end)

    self:connect_signal("button::press", function()
        press_overlay.visible = true
    end)
    self:connect_signal("button::release", function()
        press_overlay.visible = false
    end)

    local background = self._private.layout:get_children_by_id("#background")[1]
    local overlay = self._private.layout:get_children_by_id("#overlay")[1]

    background:connect_signal("property::shape", function(_, shape)
        overlay.shape = shape
    end)

    self.enable_overlay = args.enable_overlay ~= false

    self:initialize_style(self._private.layout, beautiful.capsule.default_style)

    self:apply_style(args)

    return self
end

return setmetatable(M, M.mt)
