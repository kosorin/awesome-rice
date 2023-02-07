local table = table
local awful = require("awful")
local wibox = require("wibox")
local config = require("config")
local binding = require("io.binding")
local mod = binding.modifier
local btn = binding.button
local beautiful = require("beautiful")
local gshape = require("gears.shape")
local calendar_popup = require("ui.popup.calendar")
local dpi = dpi
local gtimer = require("gears.timer")
local gtable = require("gears.table")
local capsule = require("widget.capsule")
local mebox = require("widget.mebox")
local clock_icon = require("widget.clock_icon")
local aplacement = require("awful.placement")
local widget_helper = require("helpers.widget")
local htable = require("helpers.table")


local datetime_widget = { mt = {} }

function datetime_widget:to_clipboard(what)
    local formats = {}
    if not what or what == "date" then
        table.insert(formats, "%Y-%m-%d")
    end
    if not what or what == "time" then
        table.insert(formats, self._private.seconds and "%H:%M:%S" or "%H:%M")
    end
    if #formats == 0 then
        return
    end
    local format = table.concat(formats, " ")
    local text = os.date(format)
    awful.spawn.with_shell(config.commands.copy_text(text))
end

function datetime_widget:show_seconds(show)
    self._private.seconds = show
    self._private.time_widget.text.format = self._private.seconds and "%-H:%M:%S" or "%-H:%M"
    self._private.time_widget.text.refresh = self._private.seconds and 1 or 60
end

function datetime_widget:toggle_seconds()
    self:show_seconds(not self._private.seconds)
end

local function initialize_date_widget(self, style)
    self._private.date_widget = wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        spacing = beautiful.capsule.item_content_spacing,
        {
            widget = wibox.widget.imagebox,
            resize = true,
            image = config.places.theme .. "/icons/calendar-month.svg",
            stylesheet = "path { fill: " .. style.foreground .. "; }",
        },
        {
            id = "text",
            widget = wibox.widget.textclock,
            format = "%a, %b %-e",
            refresh = 3600,
        },
    }

    local date_container = self["#date"]
    date_container:apply_style(style)
    date_container.paddings = htable.crush_clone(date_container.paddings, {
        right = beautiful.capsule.item_spacing / 2,
    })
    date_container.widget = self._private.date_widget
    date_container.buttons = binding.awful_buttons {
        binding.awful({}, btn.right, function()
            self._private.date_menu:toggle()
        end),
        binding.awful({}, btn.left, function()
            if not self._private.date_menu.visible then
                self._private.calendar_popup:toggle()
            end
        end),
    }

    local popup_placement = beautiful.wibar.build_placement(date_container, self._private.wibar)

    self._private.date_menu = mebox {
        item_width = dpi(192),
        placement = popup_placement,
        {
            text = "copy date",
            icon = config.places.theme .. "/icons/content-copy.svg",
            icon_color = beautiful.palette.gray,
            callback = function() self:to_clipboard("date") end,
        },
        {
            text = "copy date &amp; time",
            icon = config.places.theme .. "/icons/content-copy.svg",
            icon_color = beautiful.palette.gray,
            callback = function() self:to_clipboard() end,
        },
    }

    self._private.calendar_popup = calendar_popup.new {
        placement = popup_placement,
    }

    self._private.date_widget.text._timer:connect_signal("timeout", function()
        self._private.calendar_popup:refresh()
    end)
end

local function initialize_time_widget(self, style)
    self._private.time_widget = wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        spacing = beautiful.capsule.item_content_spacing,
        {
            id = "icon",
            widget = wibox.widget.imagebox,
            resize = true,
            stylesheet = clock_icon.generate_style(style.foreground),
        },
        {
            id = "text",
            widget = wibox.widget.textclock,
        },
    }

    local time_container = self["#time"]
    time_container:apply_style(style)
    time_container.paddings = htable.crush_clone(time_container.paddings, {
        left = beautiful.capsule.item_spacing / 2,
    })
    time_container.widget = self._private.time_widget
    time_container.buttons = binding.awful_buttons {
        binding.awful({}, btn.right, function()
            self._private.time_menu:toggle()
        end),
        binding.awful({}, btn.middle, function()
            if self._private.time_menu.visible then
                return
            end
            self:toggle_seconds()
        end),
    }

    self:show_seconds(false)

    self._private.time_menu = mebox {
        item_width = dpi(192),
        placement = beautiful.wibar.build_placement(time_container, self._private.wibar),
        {
            text = "copy time",
            icon = config.places.theme .. "/icons/content-copy.svg",
            icon_color = beautiful.palette.gray,
            callback = function() self:to_clipboard("time") end,
        },
        {
            text = "copy date &amp; time",
            icon = config.places.theme .. "/icons/content-copy.svg",
            icon_color = beautiful.palette.gray,
            callback = function() self:to_clipboard() end,
        },
        mebox.separator,
        {
            text = "show seconds",
            on_show = function(item) item.checked = not not self._private.seconds end,
            callback = function(_, item) self:show_seconds(not item.checked) end,
        },
    }

    gtimer {
        timeout = 60,
        autostart = true,
        call_now = true,
        callback = function()
            self._private.time_widget.icon:set_image(clock_icon.generate_svg())
        end,
    }
end

function datetime_widget.new(wibar)
    local self = wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        {
            id = "#date",
            widget = capsule,
            margins = {
                left = beautiful.capsule.default_style.margins.left,
                right = 0,
                top = beautiful.wibar.padding.top,
                bottom = beautiful.wibar.padding.bottom,
            },
            shape = function(cr, width, height)
                gshape.partially_rounded_rect(cr, width, height, true, false, false, true, beautiful.capsule.shape_radius)
            end,
        },
        {
            id = "#time",
            widget = capsule,
            margins = {
                left = 0,
                right = beautiful.capsule.default_style.margins.right,
                top = beautiful.wibar.padding.top,
                bottom = beautiful.wibar.padding.bottom,
            },
            shape = function(cr, width, height)
                gshape.partially_rounded_rect(cr, width, height, false, true, true, false, beautiful.capsule.shape_radius)
            end,
        }
    }

    gtable.crush(self, datetime_widget, true)

    self._private.wibar = wibar

    local style = beautiful.capsule.styles.normal

    initialize_date_widget(self, style)
    initialize_time_widget(self, style)

    return self
end

function datetime_widget.mt:__call(...)
    return datetime_widget.new(...)
end

return setmetatable(datetime_widget, datetime_widget.mt)
