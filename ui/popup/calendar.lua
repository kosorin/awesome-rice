local os = os
local awful = require("awful")
local wibox = require("wibox")
local gtable = require("gears.table")
local tcolor = require("utils.color")
local binding = require("core.binding")
local mod = binding.modifier
local btn = binding.button
local beautiful = require("theme.theme")
local dpi = Dpi
local capsule = require("widget.capsule")
local noice = require("core.style")
local config = require("rice.config")
local css = require("utils.css")
local ui_controller = require("ui.controller")


---@param time? integer
---@return osdate
local function now(time)
    return os.date("*t", time) --[[@as osdate]]
end


---@class CalendarPopup.module
---@operator call: CalendarPopup
local M = { mt = {} }

function M.mt:__call(...)
    return M.new(...)
end


---@class CalendarPopup : awful.popup, stylable
---@field package _private CalendarPopup.private
---Style properties:
---@field paddings thickness
---@field embed function
M.object = {}
---@class CalendarPopup.private
---@field calendar_widget wibox.widget.calendar

noice.define_style(M.object, {
    bg = { proxy = true },
    fg = { proxy = true },
    border_color = { proxy = true },
    border_width = { proxy = true },
    shape = { proxy = true },
    placement = { proxy = true },
    paddings = { property = "paddings" },
    embed = { id = "#calendar", property = "fn_embed" },
})

function M.object:show()
    if self.visible or not ui_controller.enter(self) then
        return
    end

    self:today()

    self.visible = true
end

function M.object:hide()
    self.visible = false
    ui_controller.leave(self)
end

function M.object:toggle()
    if self.visible then
        self:hide()
    else
        self:show()
    end
end

---@param self CalendarPopup
---@param year integer|string
---@param month integer|string
local function set_year_month(self, year, month)
    local date = now(os.time {
        year = year,
        month = month,
        day = 1,
    })
    local today = now()

    self:set_date(date, today)
end

function M.object:refresh()
    local date = self:get_date() or now()
    set_year_month(self, date.year, date.month)
end

function M.object:today()
    local date = now()
    set_year_month(self, date.year, date.month)
end

---@param direction sign
function M.object:move(direction)
    local date = self:get_date() or now()
    set_year_month(self, date.year, date.month + direction)
end

---@return osdate|nil
function M.object:get_date()
    return self._private.calendar_widget:get_date()
end

---@param date? osdate
---@param focus_date? osdate
function M.object:set_date(date, focus_date)
    self._private.calendar_widget:set_date(date, focus_date)
end


---@class CalendarPopup.new.args
---@field date? osdate

---@param args? CalendarPopup.new.args
---@return CalendarPopup
function M.new(args)
    args = args or {}

    local self
    self = awful.popup {
        type = "utility",
        ontop = true,
        visible = false,
        widget = {
            widget = capsule,
            enable_overlay = false,
            bg = tcolor.transparent,
            {
                layout = wibox.layout.fixed.vertical,
                spacing = dpi(16),
                {
                    layout = wibox.layout.stack,
                    {
                        id = "#calendar",
                        widget = wibox.widget.calendar.month,
                        font = beautiful.build_font(),
                        fill_month = true,
                        week_numbers = true,
                        long_weekdays = true,
                        start_sunday = false,
                    },
                    {
                        layout = wibox.container.place,
                        valign = "top",
                        halign = "left",
                        {
                            widget = capsule,
                            buttons = binding.awful_buttons {
                                binding.awful({}, { btn.left }, function() self:move(-1) end),
                            },
                            {
                                widget = wibox.widget.imagebox,
                                forced_width = dpi(18),
                                forced_height = dpi(18),
                                resize = true,
                                image = beautiful.icon("chevron-left.svg"),
                                stylesheet = css.style { path = { fill = beautiful.capsule.default_style.fg } },
                            },
                        },
                    },
                    {
                        layout = wibox.container.place,
                        valign = "top",
                        halign = "right",
                        {
                            widget = capsule,
                            buttons = binding.awful_buttons {
                                binding.awful({}, { btn.left }, function() self:move(1) end),
                            },
                            {
                                widget = wibox.widget.imagebox,
                                forced_width = dpi(18),
                                forced_height = dpi(18),
                                resize = true,
                                image = beautiful.icon("chevron-right.svg"),
                                stylesheet = css.style { path = { fill = beautiful.capsule.default_style.fg } },
                            },
                        },
                    },
                },
                {
                    widget = capsule,
                    buttons = binding.awful_buttons {
                        binding.awful({}, { btn.left }, function() self:today() end),
                    },
                    {
                        widget = wibox.widget.textbox,
                        text = "Today",
                        halign = "center",
                    },
                },
            },
        },
    } --[[@as CalendarPopup]]

    gtable.crush(self, M.object, true)

    self._private.calendar_widget = self.widget:get_children_by_id("#calendar")[1] --[[@as wibox.widget.calendar]]

    self.buttons = binding.awful_buttons {
        binding.awful({}, { btn.middle }, function() self:today() end),
        binding.awful({}, {
            { trigger = btn.wheel_up, direction = -1 },
            { trigger = btn.wheel_down, direction = 1 },
        }, function(trigger) self:move(trigger.direction) end),
    }

    self:initialize_style(beautiful.calendar_popup.default_style, self.widget)

    self:apply_style(args)

    self:set_date(args.date or now())

    return self
end

return setmetatable(M, M.mt)
