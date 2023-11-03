local tostring = tostring
local wibox = require("wibox")
local beautiful = require("theme.theme")
local dpi = Dpi
local mebox = require("widget.mebox")
local binding = require("core.binding")
local mod = binding.modifier
local btn = binding.button
local pango = require("utils.pango")
local umath = require("utils.math")
local config = require("rice.config")
local common = require("ui.menu.templates.client._common")


local M = {}

---@return Mebox.new.args
function M.new()
    local value_widget
    local step = 0.05
    local min_opacity = 0
    local max_opacity = 1

    local function update_opacity_text(opacity)
        if not value_widget then
            return
        end
        opacity = tonumber(opacity)
        local text = opacity
            and tostring(umath.round(opacity * 100))
            or "--"
        value_widget:set_markup(text .. pango.thin_space .. "%")
    end

    local function change_opacity(menu, value)
        local client = menu.client --[[@as client]]
        client.opacity = umath.clamp(client.opacity + value, min_opacity, max_opacity)
        update_opacity_text(menu.client.opacity)
    end

    local function set_opacity(menu, value)
        local client = menu.client --[[@as client]]
        client.opacity = value or max_opacity
        update_opacity_text(client.opacity)
    end

    ---@type Mebox.new.args
    local args = {
        item_width = beautiful.mebox.default_style.item_height,
        on_show = common.on_show,
        on_hide = common.on_hide,
        orientation = "horizontal",
        layout_navigator = function(menu, x, y, direction, context)
            if y ~= 0 then
                change_opacity(menu, -y * step)
                return
            end
            mebox.layout_navigators.direction(menu, x, y, direction, context)
        end,
        items_source = {
            {
                icon = beautiful.icon("minus.svg"),
                icon_color = beautiful.palette.white,
                callback = function(item, menu)
                    change_opacity(menu, -step)
                    return false
                end,
            },
            {
                enabled = false,
                buttons_builder = function(_, menu)
                    return binding.awful_buttons {
                        binding.awful({}, binding.group.mouse_wheel, function(trigger)
                            change_opacity(menu, trigger.y * step)
                        end),
                    }
                end,
                template = {
                    widget = wibox.widget.textbox,
                    forced_width = dpi(64),
                    halign = "center",
                    update_callback = function(_, _, menu)
                        local client = menu.client --[[@as client]]
                        update_opacity_text(client.opacity)
                    end,
                },
                on_ready = function(item_widget)
                    value_widget = item_widget
                end,
            },
            {
                icon = beautiful.icon("plus.svg"),
                icon_color = beautiful.palette.white,
                callback = function(item, menu)
                    change_opacity(menu, step)
                    return false
                end,
            },
            mebox.separator,
            {
                width = dpi(100),
                text = "Reset",
                icon = beautiful.icon("arrow-u-left-top.svg"),
                icon_color = beautiful.palette.gray,
                callback = function(item, menu)
                    set_opacity(menu, max_opacity)
                end,
            },
        },
    }

    return args
end

M.shared = M.new()

return M
