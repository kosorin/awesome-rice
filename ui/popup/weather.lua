local capi = Capi
local awful = require("awful")
local wibox = require("wibox")
local gtable = require("gears.table")
local tcolor = require("utils.color")
local binding = require("core.binding")
local mod = binding.modifier
local btn = binding.button
local beautiful = require("theme.theme")
local weather_service = require("services.weather")
local widget_helper = require("core.widget")
local hui = require("utils.thickness")
local dpi = Dpi
local humanizer = require("utils.humanizer")
local umath = require("utils.math")
local glib = require("lgi").GLib
local DateTime = glib.DateTime
local DateTime_new_from_unix_local = DateTime.new_from_unix_local


local wind_info = {
    [8] = {
        { icon = "", short = "N", long = "north" },
        { icon = "", short = "NE", long = "northeast" },
        { icon = "", short = "E", long = "east" },
        { icon = "", short = "SE", long = "southeast" },
        { icon = "", short = "S", long = "south" },
        { icon = "", short = "SW", long = "southwest" },
        { icon = "", short = "W", long = "west" },
        { icon = "", short = "NW", long = "northwest" },
    },
    [16] = {
        { icon = "", short = "S", long = "sever" },
        { icon = "", short = "SSV", long = "severo-severovýchod" },
        { icon = "", short = "SV", long = "severovýchod" },
        { icon = "", short = "VSV", long = "východo-severovýchod" },
        { icon = "", short = "V", long = "východ" },
        { icon = "", short = "VJV", long = "východo-jihovýchod" },
        { icon = "", short = "JV", long = "jihovýchod" },
        { icon = "", short = "JJV", long = "jiho-jihovýchod" },
        { icon = "", short = "J", long = "jih" },
        { icon = "", short = "JJZ", long = "jiho-jihozápad" },
        { icon = "", short = "JZ", long = "jihozápad" },
        { icon = "", short = "ZJZ", long = "západo-jihozápad" },
        { icon = "", short = "Z", long = "západ" },
        { icon = "", short = "ZSZ", long = "západo-severozápad" },
        { icon = "", short = "SZ", long = "severozápad" },
        { icon = "", short = "SSZ", long = "severo-severozápad" },
    },
}

local function get_wind_direction_info(direction, count)
    local index = 1 + (umath.round(direction / (360 / count)) % count)
    return wind_info[count][index]
end

local ns = "<span size='x-small'> </span>"

local display_info = {
    time = { title = "Time", format = "%a, %b %-e, %-H:%M:%S" },
    humidity = { title = "Humidity", format = "%d %%%%" },
    pressure = { title = "Pressure", format = "%.2f hPa" },
    dew_point = { title = "Dew point", format = "%.1f &#176;C" },
    temperature = { title = "Temperature", format = "%.1f" .. ns .. "&#176;C" },
    wind_speed = { title = "Wind speed", format = "%.1f m/s" },
    wind_gust = { title = "Wind gust", format = "%.1f m/s" },
    wind_chill = { title = "Wind chill", format = "%.1f &#176;C" },
    wind_direction = { title = "Wind direction", format = "%d&#176;" },
    apparent_temperature = { title = "Feels like", format = "%.1f &#176;C" },
    uv = { title = "UV index", format = "%d " },
    solar_radiation = { title = "Solar radiation", format = "%.1f W/m<sup>2</sup>" },
    precipitation_rate = { title = "Rain rate", format = "%.1f mm/h" },
    precipitation_day = { title = "Rain (day)", format = "%.1f mm" },
    precipitation_week = { title = "Rain (week)", format = "%.1f mm" },
    precipitation_month = { title = "Rain (month)", format = "%.1f mm" },
    indoor_humidity = { title = "Humidity", format = "%d %%%%" },
    indoor_temperature = { title = "Temperature", format = "%.1f &#176;C" },
    indoor_apparent_temperature = { title = "Feels like", format = "%.1f &#176;C" },
}

local weather_popup = {}

local WeatherPopup = {}

local function data_header(id)
    return {
        id = "_" .. id,
        widget = wibox.widget.textbox,
        halign = "right",
        pattern = "<span weight='bold'>{title}</span>",
    }
end

local function data_cell(id, args)
    return gtable.crush({
        id = id,
        widget = wibox.widget.textbox,
        halign = "left",
        pattern = "<span>{value}</span>",
    }, args or {})
end

local empty_cell = {
    layout = wibox.layout.manual,
    forced_width = dpi(0),
    forced_height = dpi(4),
}

local function create_temperature_data_widget()
    local time_tooltip

    local data_widget = wibox.widget {
        visible = false,
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(16),
        {
            id = "temperature",
            widget = wibox.widget.textbox,
            halign = "center",
            pattern = "<span weight='bold' size='300%' fgcolor='"
                .. beautiful.common.primary
                .. "'>{value}</span>",
        },
        {
            layout = wibox.container.place,
            halign = "center",
            {
                layout = wibox.layout.grid,
                orientation = "vertical",
                horizontal_homogeneous = true,
                vertical_homogeneous = false,
                expand_horizontal = true,
                forced_num_cols = 2,
                horizontal_spacing = dpi(12),
                vertical_spacing = dpi(8),
                data_header("apparent_temperature"),
                data_cell("apparent_temperature"),
                data_header("humidity"),
                data_cell("humidity"),
                data_header("dew_point"),
                data_cell("dew_point"),
                data_header("pressure"),
                data_cell("pressure"),
                empty_cell,
                empty_cell,
                data_header("wind_chill"),
                data_cell("wind_chill"),
                data_header("wind_speed"),
                data_cell("wind_speed"),
                data_header("wind_gust"),
                data_cell("wind_gust"),
                data_header("wind_direction"),
                data_cell("wind_direction", {
                    formatter = function(format, value)
                        local info = get_wind_direction_info(value, 8)
                        return string.format(format, value)
                            .. " " .. info.short
                            .. " " .. info.icon
                    end,
                }),
                empty_cell,
                empty_cell,
                data_header("solar_radiation"),
                data_cell("solar_radiation"),
                data_header("uv"),
                data_cell("uv"),
                empty_cell,
                empty_cell,
                data_header("precipitation_rate"),
                data_cell("precipitation_rate"),
                data_header("precipitation_day"),
                data_cell("precipitation_day"),
                data_header("precipitation_week"),
                data_cell("precipitation_week"),
                data_header("precipitation_month"),
                data_cell("precipitation_month"),
            },
        },
        {
            id = "time",
            widget = wibox.widget.textbox,
            halign = "center",
            pattern = "<span fgalpha='75%'>{value}</span>",
            formatter = function(format, value)
                return DateTime_new_from_unix_local(value):format(format)
            end,
            on_bind = function(widget, value, info)
                time_tooltip.value = value
            end,
        },
    }

    time_tooltip = awful.tooltip {
        text = "?",
        mode = "outside",
        preferred_positions = "bottom",
        preferred_alignments = "middle",
        objects = { data_widget.time },
        timer_function = function()
            local time = time_tooltip.value or 0
            local now = os.time()
            local seconds = os.difftime(now, time)
            return humanizer.relative_time(seconds, {
                formats = humanizer.long_time_formats,
                part_count = 2,
                suffix = " ago",
            })
        end,
    }

    return data_widget
end

local function create_indoor_data_widget()
    local time_tooltip

    local data_widget = wibox.widget {
        visible = false,
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(16),
        {
            id = "indoor_temperature",
            widget = wibox.widget.textbox,
            halign = "center",
            pattern = "<span weight='bold' size='300%' fgcolor='"
                .. beautiful.common.primary
                .. "'>{value}</span>",
        },
        {
            layout = wibox.container.place,
            halign = "center",
            {
                layout = wibox.layout.grid,
                orientation = "vertical",
                horizontal_homogeneous = true,
                vertical_homogeneous = false,
                expand_horizontal = true,
                forced_num_cols = 2,
                horizontal_spacing = dpi(12),
                vertical_spacing = dpi(8),
                data_header("indoor_apparent_temperature"),
                data_cell("indoor_apparent_temperature"),
                data_header("indoor_humidity"),
                data_cell("indoor_humidity"),
            },
        },
        {
            id = "time",
            widget = wibox.widget.textbox,
            halign = "center",
            pattern = "<span fgalpha='75%'>{value}</span>",
            formatter = function(format, value)
                return DateTime_new_from_unix_local(value):format(format)
            end,
            on_bind = function(widget, value, info)
                time_tooltip.value = value
            end,
        },
    }

    time_tooltip = awful.tooltip {
        text = "?",
        mode = "outside",
        preferred_positions = "bottom",
        preferred_alignments = "middle",
        objects = { data_widget.time },
        timer_function = function()
            local time = time_tooltip.value or 0
            local now = os.time()
            local seconds = os.difftime(now, time)
            return humanizer.relative_time(seconds, {
                formats = humanizer.long_time_formats,
                part_count = 2,
                suffix = " ago",
            })
        end,
    }

    return data_widget
end

local function bind_data(data_widget)
    local response = weather_service.last_response
    for id, info in pairs(display_info) do
        local name = info.name or id
        local value = response.data[name]
        if value then
            local value_widget = data_widget:get_children_by_id(id)[1]
            if value_widget then
                local value_markup = (value_widget.formatter or string.format)(info.format, value)
                local markup = string.gsub(value_widget.pattern, "{value}", value_markup)
                value_widget:set_markup(markup)
                if value_widget.on_bind then
                    value_widget.on_bind(value_widget, value, info)
                end
            end
            local header_widget = data_widget:get_children_by_id("_" .. id)[1]
            if header_widget then
                local markup = string.gsub(header_widget.pattern, "{title}", info.title)
                header_widget:set_markup(markup)
            end
        end
    end
end

function WeatherPopup:can_show()
    return self.parent.wibar and self.parent.widget
end

function WeatherPopup:show()
    if self.popup.visible or not self:can_show() then
        return
    end

    self:refresh(true)

    local parent_geometry = widget_helper.find_geometry(
        self.parent.widget,
        self.parent.wibar)
    awful.placement.infobubble(self.popup, {
        geometry = parent_geometry,
        position = self.position,
        anchor = self.anchor,
        honor_workarea = true,
        honor_padding = true,
        margins = self.margins,
        corner_radius = self.corner_radius,
        arrow_size = self.arrow_size,
    })

    self.popup.visible = true
end

function WeatherPopup:hide()
    self.popup.visible = false
end

function WeatherPopup:toggle()
    if self.popup.visible then
        self:hide()
    else
        self:show()
    end
end

function WeatherPopup:refresh(force)
    if not (self.popup.visible or force) or not self:can_show() then
        return
    end

    local response = weather_service.last_response

    -- Hide "no_data" only once
    -- Once there are any data they will be shown forever
    if self.no_data_widget.visible and response.success then
        self.no_data_widget.visible = false
    end

    -- Show and bind data only on success
    if response.success then
        self.data_widget.visible = true
        bind_data(self.data_widget)
    end
end

local function new(parent, data_widget_factory, args)
    args = args or {}
    local self = setmetatable({
        parent = parent,
        popup = nil,
        data_widget = nil,
        no_data_widget = nil,
        corner_radius = args.corner_radius or dpi(0),
        arrow_size = args.arrow_size or dpi(12),
        position = args.placement or "bottom",
        anchor = args.placement or "middle",
        width = args.width or dpi(320),
        height = args.height or dpi(592),
        bg = args.bg or beautiful.popup.default_style.bg,
        opacity = args.opacity or 1,
        border_width = args.border_width or dpi(1),
        border_color = args.border_color or beautiful.common.primary_66,
        padding = args.padding or dpi(24),
    }, { __index = WeatherPopup })

    self.margins = args.margins or hui.new {
        beautiful.gap,
        top = beautiful.gap - (self.arrow_size / 2) - self.border_width,
    }

    self.data_widget = data_widget_factory()

    self.no_data_widget = wibox.widget {
        visible = true,
        widget = wibox.container.place,
        halign = "center",
        valign = "center",
        {
            widget = wibox.widget.textbox,
            markup = "<span size='150%' fgcolor='" .. beautiful.common.fg_66 .. "'>No Data</span>",
        },
    }

    self.popup = awful.popup {
        ontop = true,
        visible = false,
        placement = false,
        width = self.width,
        height = self.height,
        bg = self.bg,
        opacity = self.opacity,
        shape = nil,
        border_width = self.border_width,
        border_color = self.border_color,
        widget = {
            layout = wibox.container.constraint,
            strategy = "exact",
            width = self.width,
            height = self.height,
            {
                widget = wibox.container.margin,
                top = self.arrow_size,
                {
                    widget = wibox.container.margin,
                    margins = self.padding,
                    {
                        layout = wibox.layout.stack,
                        self.no_data_widget,
                        self.data_widget,
                    },
                },
            },
        },
    }

    self.popup.buttons = binding.awful_buttons {
        binding.awful({}, { btn.left }, function() self:hide() end),
    }

    capi.awesome.connect_signal("weather::updated", function() self:refresh() end)

    return self
end

function weather_popup.new_temperature(parent, args)
    return new(parent,
        create_temperature_data_widget,
        gtable.crush({ height = dpi(592) }, args or {}))
end

function weather_popup.new_indoor(parent, args)
    return new(parent,
        create_indoor_data_widget,
        gtable.crush({ height = dpi(216) }, args or {}))
end

return weather_popup
