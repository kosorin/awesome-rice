local config = require("rice.config")
if not config.features.torrent_widget then
    return
end

local capi = Capi
local setmetatable = setmetatable
local concat = table.concat
local insert = table.insert
local max = math.max
local format = string.format
local awful = require("awful")
local wibox = require("wibox")
local binding = require("core.binding")
local mod = binding.modifier
local btn = binding.button
local beautiful = require("theme.theme")
local torrent_service = require("services.torrent")
local dpi = Dpi
local humanizer = require("utils.humanizer")
local gtable = require("gears.table")
local capsule = require("widget.capsule")
local aplacement = require("awful.placement")
local widget_helper = require("core.widget")
local mebox = require("widget.mebox")
local pango = require("utils.pango")
local css = require("utils.css")
local hui = require("utils.thickness")


local file_size_units = setmetatable({ space = pango.thin_space }, { __index = humanizer.file_size_units })

local torrent_widget = { mt = {} }

local time_args = {
    formats = {
        year = { text = "yr" },
        month = { text = "mo" },
        week = { text = "wk" },
        day = { text = "d" },
        hour = { text = "h" },
        minute = { text = "min" },
        second = { text = "s", format = "%2d" },
    },
    part_count = 2,
    unit_separator = pango.thin_space,
}

local styles = {
    leeching = beautiful.capsule.styles.palette.magenta,
    leeching_missing = beautiful.capsule.styles.palette.orange,
    verifying = beautiful.capsule.styles.palette.cyan,
    seeding = beautiful.capsule.styles.normal,
    idle = beautiful.capsule.styles.disabled,
    incomplete = beautiful.capsule.styles.palette.yellow,
    unknown_status = beautiful.capsule.styles.palette.red,
    error = beautiful.capsule.styles.palette.red,
    loading = beautiful.capsule.styles.disabled,
}

function torrent_widget:refresh()
    local response = torrent_service.last_response

    local style, text, icon

    if response.success == nil then
        style = styles.loading
        text = "Loading"
        icon = "pirate"
    elseif response.success then
        local data = response.data
        local incomplete = data.downloaded_count ~= data.total_count

        if data.status == torrent_service.status_codes.leeching then
            local eta = data.eta or -1
            style = data.any_unknown_eta and styles.leeching_missing or styles.leeching
            text = eta >= 0
                and humanizer.relative_time(eta, time_args)
                or "Missing"
        elseif data.status == torrent_service.status_codes.idle then
            style = incomplete and styles.incomplete or styles.idle
            text = "Idle"
        elseif data.status == torrent_service.status_codes.seeding then
            style = incomplete and styles.incomplete or styles.seeding
            text = "Seeding"
        elseif data.status == torrent_service.status_codes.verifying then
            style = incomplete and styles.incomplete or styles.verifying
            text = "Verifying"
        else
            style = styles.unknown_status
            text = format("Status:%s", pango.escape(tostring(data.status) or "-"))
        end

        local info_parts = {}
        local missing_size = max(0, data.wanted_size - data.downloaded_size)
        if missing_size > 0 then
            insert(info_parts, humanizer.humanize_units(file_size_units, max(0, data.wanted_size - data.downloaded_size)))
        end
        if data.total_count > 0 then
            insert(info_parts, format("%d/%d", data.downloaded_count, data.total_count))
        end

        if #info_parts > 0 then
            text = format("%s (%s)", text, concat(info_parts, ", "))
        end
        icon = data.alternative_speed_enabled and "speedometer-slow" or "speedometer"
    else
        style = styles.error
        text = "Error"
        icon = "pirate"
    end

    self:apply_style(style)

    local text_widget = self:get_children_by_id("text")[1]
    text_widget:set_markup(pango.span { fgcolor = style.fg, text })

    local icon_path = beautiful.icon(icon .. ".svg")
    local icon_stylesheet = css.style { path = { fill = style.fg } }
    local icon_widget = self:get_children_by_id("icon")[1]
    icon_widget:set_stylesheet(icon_stylesheet)
    icon_widget:set_image(icon_path)
end

function torrent_widget.new(wibar)
    local self = wibox.widget {
        widget = capsule,
        margins = hui.new {
            top = beautiful.wibar.paddings.top,
            right = beautiful.capsule.default_style.margins.right,
            bottom = beautiful.wibar.paddings.bottom,
            left = beautiful.capsule.default_style.margins.left,
        },
        {
            layout = wibox.layout.fixed.horizontal,
            spacing = beautiful.capsule.item_content_spacing,
            {
                id = "icon",
                widget = wibox.widget.imagebox,
                resize = true,
            },
            {
                id = "text",
                widget = wibox.widget.textbox,
            },
        },
    }

    gtable.crush(self, torrent_widget, true)

    self._private.wibar = wibar

    self._private.menu = mebox {
        item_width = dpi(300),
        placement = beautiful.wibar.build_placement(self, self._private.wibar),
        {
            text = "Open Transmission",
            icon = beautiful.icon("open-in-new.svg"),
            icon_color = beautiful.palette.gray,
            callback = function() awful.spawn.spawn(config.commands.open("http://127.0.0.1:9091/transmission/web/")) end,
        },
        {
            text = "Open Sonarr",
            icon = beautiful.icon("open-in-new.svg"),
            icon_color = beautiful.palette.gray,
            callback = function() awful.spawn.spawn(config.commands.open("http://127.0.0.1:8989/")) end,
        },
        {
            text = "Open Radarr",
            icon = beautiful.icon("open-in-new.svg"),
            icon_color = beautiful.palette.gray,
            callback = function() awful.spawn.spawn(config.commands.open("http://127.0.0.1:7878/")) end,
        },
        mebox.separator,
        {
            text = "Start All",
            icon = beautiful.icon("play.svg"),
            icon_color = beautiful.palette.green,
            callback = function() torrent_service.start() end,
        },
        {
            text = "Pause All",
            icon = beautiful.icon("pause.svg"),
            icon_color = beautiful.palette.blue,
            callback = function() torrent_service.stop() end,
        },
        {
            text = "Alternative Speed Limit",
            icon = beautiful.icon("tortoise.svg"),
            icon_color = beautiful.palette.gray,
            on_show = function(item) item.checked = not not torrent_service.last_response.data.alternative_speed_enabled end,
            callback = function(item) torrent_service.alternative_speed(not item.checked) end,
        },
        mebox.separator,
        {
            text = "Refresh",
            icon = beautiful.icon("refresh.svg"),
            icon_color = beautiful.palette.gray,
            callback = function() torrent_service.update() end,
        },
    }

    self.buttons = binding.awful_buttons {
        binding.awful({}, btn.middle, function()
            if self._private.menu.visible then
                return
            end
            torrent_service.alternative_speed()
        end),
        binding.awful({}, btn.right, function()
            self._private.menu:toggle()
        end),
    }

    capi.awesome.connect_signal("torrent::updated", function() self:refresh() end)

    self:refresh()

    return self
end

function torrent_widget.mt:__call(...)
    return torrent_widget.new(...)
end

return setmetatable(torrent_widget, torrent_widget.mt)
