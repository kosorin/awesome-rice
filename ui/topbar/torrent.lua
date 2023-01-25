local capi = {
    awesome = awesome,
    mouse = mouse,
}
local setmetatable = setmetatable
local concat = table.concat
local insert = table.insert
local max = math.max
local format = string.format
local awful = require("awful")
local wibox = require("wibox")
local config = require("config")
local binding = require("io.binding")
local mod = binding.modifier
local btn = binding.button
local beautiful = require("beautiful")
local torrent_service = require("services.torrent")
local dpi = dpi
local config = require("config")
local humanizer = require("utils.humanizer")
local gtable = require("gears.table")
local capsule = require("widget.capsule")
local aplacement = require("awful.placement")
local widget_helper = require("helpers.widget")
local mebox = require("widget.mebox")
local pango = require("utils.pango")


local torrent_widget = { mt = {} }

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
        text = "loading"
        icon = "pirate"
    elseif response.success then
        local data = response.data
        local incomplete = data.downloaded_count ~= data.total_count

        if data.status == torrent_service.status_codes.leeching then
            local eta = data.eta or -1
            style = data.any_unknown_eta and styles.leeching_missing or styles.leeching
            text = eta >= 0
                and humanizer.relative_time(eta, { part_count = 2 })
                or "missing"
        elseif data.status == torrent_service.status_codes.idle then
            style = incomplete and styles.incomplete or styles.idle
            text = "idle"
        elseif data.status == torrent_service.status_codes.seeding then
            style = incomplete and styles.incomplete or styles.seeding
            text = "seeding"
        elseif data.status == torrent_service.status_codes.verifying then
            style = incomplete and styles.incomplete or styles.verifying
            text = "verifying"
        else
            style = styles.unknown_status
            text = format("status:%s", tostring(data.status) or "-")
        end

        local info_parts = {}
        local missing_size = max(0, data.wanted_size - data.downloaded_size)
        if missing_size > 0 then
            insert(info_parts, humanizer.file_size(max(0, data.wanted_size - data.downloaded_size)))
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
        text = "error"
        icon = "pirate"
    end

    self:apply_style(style)

    local text_widget = self:get_children_by_id("text")[1]
    text_widget:set_markup(pango.span { foreground = style.foreground, text, })

    local icon_path = config.places.theme .. "/icons/" .. icon .. ".svg"
    local icon_stylesheet = "path { fill: " .. style.foreground .. "; }"
    local icon_widget = self:get_children_by_id("icon")[1]
    icon_widget:set_stylesheet(icon_stylesheet)
    icon_widget:set_image(icon_path)
end

function torrent_widget.new(wibar)
    local self = wibox.widget {
        widget = capsule,
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
        item_width = dpi(260),
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
            text = "open transmission",
            icon = config.places.theme .. "/icons/open-in-new.svg",
            icon_color = beautiful.palette.gray,
            callback = function() awful.spawn.spawn(config.commands.open("http://localhost:9091/transmission/web/")) end,
        },
        {
            text = "open sonarr",
            icon = config.places.theme .. "/icons/open-in-new.svg",
            icon_color = beautiful.palette.gray,
            callback = function() awful.spawn.spawn(config.commands.open("http://localhost:8989/")) end,
        },
        {
            text = "open radarr",
            icon = config.places.theme .. "/icons/open-in-new.svg",
            icon_color = beautiful.palette.gray,
            callback = function() awful.spawn.spawn(config.commands.open("http://localhost:7878/")) end,
        },
        mebox.separator,
        {
            text = "start all",
            icon = config.places.theme .. "/icons/play.svg",
            icon_color = beautiful.palette.green,
            callback = function() torrent_service.start() end,
        },
        {
            text = "pause all",
            icon = config.places.theme .. "/icons/pause.svg",
            icon_color = beautiful.palette.blue,
            callback = function() torrent_service.stop() end,
        },
        {
            text = "alternative speed limit",
            on_show = function(item) item.checked = not not torrent_service.last_response.data.alternative_speed_enabled end,
            callback = function(_, item) torrent_service.alternative_speed(not item.checked) end,
        },
        mebox.separator,
        {
            text = "refresh",
            icon = config.places.theme .. "/icons/refresh.svg",
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
