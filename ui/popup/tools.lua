local awful = require("awful")
local wibox = require("wibox")
local gtable = require("gears.table")
local tcolor = require("utils.color")
local binding = require("io.binding")
local mod = binding.modifier
local btn = binding.button
local beautiful = require("theme.theme")
local dpi = Dpi
local capsule = require("widget.capsule")
local noice = require("theme.style")
local config = require("config")
local redshift_widget = require("ui.topbar.redshift")


---@class ToolsPopup.module
---@operator call: ToolsPopup
local M = { mt = {} }

function M.mt:__call(...)
    return M.new(...)
end


---@class ToolsPopup : awful.popup, stylable
---@field package _private ToolsPopup.private
---Style properties:
---@field paddings thickness
M.object = {}
---@class ToolsPopup.private

noice.define_style(M.object, {
    bg = { proxy = true },
    fg = { proxy = true },
    border_color = { proxy = true },
    border_width = { proxy = true },
    shape = { proxy = true },
    placement = { proxy = true },
    paddings = { property = "paddings" },
})

function M.object:show()
    if self.visible then
        return
    end

    self.visible = true
end

function M.object:hide()
    self.visible = false
end

function M.object:toggle()
    if self.visible then
        self:hide()
    else
        self:show()
    end
end


---@class ToolsPopup.new.args

---@param args? ToolsPopup.new.args
---@return ToolsPopup
function M.new(args)
    args = args or {}

    local self = awful.popup {
        ontop = true,
        visible = false,
        widget = {
            widget = capsule,
            enable_overlay = false,
            bg = tcolor.transparent,
            {
                id = "#container",
                forced_width = dpi(250),
                layout = wibox.layout.fixed.vertical,
                spacing = beautiful.wibar.spacing,
            },
        },
    } --[[@as ToolsPopup]]

    gtable.crush(self, M.object, true)

    self:initialize_style(self.widget, beautiful.tools_popup.default_style)

    self:apply_style(args)

    local container = self.widget:get_children_by_id("#container")[1] --[[@as wibox.layout]]
    if config.features.redshift_widget then
        container:add(wibox.widget {
            widget = wibox.container.constraint,
            strategy = "max",
            height = beautiful.wibar.item_height,
            redshift_widget(self, true),
        })
    end

    return self
end

return setmetatable(M, M.mt)
