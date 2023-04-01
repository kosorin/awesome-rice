local os = os
local wibox = require("wibox")
local gtable = require("gears.table")
local binding = require("io.binding")
local mod = binding.modifier
local btn = binding.button
local beautiful = require("theme.manager")._beautiful
local dpi = Dpi
local capsule = require("widget.capsule")
local popup = require("widget.popup")
local noice = require("theme.stylable")
local config = require("config")
local css = require("utils.css")


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


---@class CalendarPopup : Popup
---@field package _private CalendarPopup.private
M.object = {}
---@class CalendarPopup.private
---@field calendar_widget wibox.widget.calendar

noice.define {
    object = M.object,
    name = "calendar_popup",
    properties = {
        embed = { id = "#calendar", property = "fn_embed" },
    },
}

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

---@return osdate|nil
function M.object:get_date()
    return self._private.calendar_widget:get_date()
end

---@param date? osdate
---@param focus_date? osdate
function M.object:set_date(date, focus_date)
    self._private.calendar_widget:set_date(date, focus_date)
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


---@class CalendarPopup.new.args : Popup.new.args
---@field date? osdate

---@param args? CalendarPopup.new.args
---@return CalendarPopup
function M.new(args)
    args = args or {}

    local self = popup.new(args) --[[@as CalendarPopup]]

    local widget = wibox.widget {
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
                            buttons = binding.awful_buttons {
                                binding.awful({}, { btn.left }, function() self:move(-1) end),
                            },
                            {
                                widget = wibox.widget.imagebox,
                                forced_width = dpi(18),
                                forced_height = dpi(18),
                                resize = true,
                                image = config.places.theme .. "/icons/chevron-left.svg",
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
                                image = config.places.theme .. "/icons/chevron-right.svg",
                                stylesheet = css.style { path = { fill = beautiful.capsule.default_style.fg } },
                            },
                        },
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
                text = "today",
                halign = "center",
            },
        },
    }

    gtable.crush(self, M.object, true)
    noice.initialize(self, nil, widget)

    self._private.calendar_widget = widget:get_children_by_id("#calendar")[1] --[[@as wibox.widget.calendar]]

    self:set_date(args.date or now())

    self:set_widget(widget)

    self:set_buttons(binding.awful_buttons {
        binding.awful({}, { btn.middle }, function() self:today() end),
        binding.awful({}, {
            { trigger = btn.wheel_up, direction = -1 },
            { trigger = btn.wheel_down, direction = 1 },
        }, function(trigger) self:move(trigger.direction) end),
    })

    return self
end

return setmetatable(M, M.mt)
