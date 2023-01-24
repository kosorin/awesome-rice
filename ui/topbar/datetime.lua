local table = table
local floor = math.floor
local awful = require("awful")
local wibox = require("wibox")
local config = require("config")
local binding = require("io.binding")
local mod = binding.modifier
local btn = binding.button
local beautiful = require("beautiful")
local calendar_popup = require("ui.popup.calendar")
local dpi = dpi
local gtimer = require("gears.timer")
local gtable = require("gears.table")
local capsule = require("widget.capsule")
local mebox = require("widget.mebox")
local clock_icon = require("widget.clock_icon")
local aplacement = require("awful.placement")
local widget_helper = require("helpers.widget")


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
    self._private.widgets.clock.text.format = self._private.seconds and "%-H:%M:%S" or "%-H:%M"
    self._private.widgets.clock.text.refresh = self._private.seconds and 1 or 60
end

function datetime_widget:toggle_seconds()
    self:show_seconds(not self._private.seconds)
end

function datetime_widget.new(wibar)
    local self = wibox.widget {
        widget = capsule,
        {
            layout = wibox.layout.fixed.horizontal,
            spacing = beautiful.capsule.item_spacing,
        },
    }

    gtable.crush(self, datetime_widget, true)

    self._private.wibar = wibar

    local style = beautiful.capsule.styles.normal
    self:apply_style(style)

    self._private.widgets = {
        calendar = wibox.widget {
            layout = wibox.layout.fixed.horizontal,
            spacing = beautiful.capsule.item_content_spacing,
            buttons = binding.awful_buttons {
                binding.awful({}, btn.left, function()
                    if not self._private.menu.visible then
                        self._private.popup:toggle()
                    end
                end),
            },
            {
                widget = wibox.widget.imagebox,
                resize = true,
                image = beautiful.dir .. "/icons/calendar-month.svg",
                stylesheet = "path { fill: " .. style.foreground .. "; }",
            },
            {
                id = "text",
                widget = wibox.widget.textclock,
                format = "%a, %b %-e",
                refresh = 3600,
            },
        },
        clock = wibox.widget {
            layout = wibox.layout.fixed.horizontal,
            spacing = beautiful.capsule.item_content_spacing,
            buttons = binding.awful_buttons {
                binding.awful({}, btn.middle, function()
                    if self._private.menu.visible then
                        return
                    end
                    self:toggle_seconds()
                end),
            },
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
        },
    }

    self.widget:add(self._private.widgets.calendar)
    self.widget:add(self._private.widgets.clock)

    self:show_seconds(false)

    self._private.menu = mebox {
        item_width = dpi(200),
        placement = function(menu)
            aplacement.wibar(menu, {
                geometry = widget_helper.find_geometry(self, self._private.wibar),
                position = "bottom",
                anchor = "middle",
                honor_workarea = true,
                honor_padding = false,
                margins = beautiful.wibar_popup_margin,
            })
        end,
        {
            text = "copy date &amp; time",
            icon = beautiful.dir .. "/icons/content-copy.svg",
            icon_color = beautiful.palette.gray,
            callback = function() self:to_clipboard() end,
        },
        {
            text = "copy date",
            icon = beautiful.dir .. "/icons/content-copy.svg",
            icon_color = beautiful.palette.gray,
            callback = function() self:to_clipboard("date") end,
        },
        {
            text = "copy time",
            icon = beautiful.dir .. "/icons/content-copy.svg",
            icon_color = beautiful.palette.gray,
            callback = function() self:to_clipboard("time") end,
        },
        mebox.separator,
        {
            text = "show seconds",
            on_show = function(item) item.checked = not not self._private.seconds end,
            callback = function(_, item) self:show_seconds(not item.checked) end,
        },
    }

    self.buttons = binding.awful_buttons {
        binding.awful({}, btn.right, function()
            self._private.menu:toggle()
        end),
    }

    self._private.popup = calendar_popup.new {
        wibar = wibar,
        widget = self._private.widgets.calendar,
    }

    self._private.widgets.calendar.text._timer:connect_signal("timeout", function()
        self._private.popup:refresh()
    end)

    gtimer {
        timeout = 60,
        autostart = true,
        call_now = true,
        callback = function()
            self._private.widgets.clock.icon:set_image(clock_icon.generate_svg())
        end,
    }

    return self
end

function datetime_widget.mt:__call(...)
    return datetime_widget.new(...)
end

return setmetatable(datetime_widget, datetime_widget.mt)
