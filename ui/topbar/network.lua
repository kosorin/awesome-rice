local capi = {
    awesome = awesome,
}
local wibox = require("wibox")
local beautiful = require("beautiful")
local config = require("config")
local network_service = require("services.network")
local dpi = dpi
local humanizer = require("utils.humanizer")
local gtable = require("gears.table")
local capsule = require("widget.capsule")
local pango = require("utils.pango")


local network_widget = { mt = {} }

local styles = {
    connected = gtable.clone(beautiful.capsule.styles.normal),
    disconnected = gtable.crush(gtable.clone(beautiful.capsule.styles.palette.yellow),
        {
            text = "disconnected",
            icon = "lan-disconnect",
        }),
    error = gtable.crush(gtable.clone(beautiful.capsule.styles.palette.red),
        {
            text = "error",
            icon = "lan-disconnect",
        }),
    loading = gtable.crush(gtable.clone(beautiful.capsule.styles.disabled),
        {
            text = "loading",
            icon = "lan-pending",
        }),
}

local function colorize_path(color)
    return "path { fill: " .. color .. "; }"
end

local function refresh_info(container_widget, style, text, icon)
    local text_widget = container_widget:get_children_by_id("text")[1]
    text = style.text or text or ""
    text_widget:set_markup(pango.span { foreground = style.foreground, text, })

    local icon_widget = container_widget:get_children_by_id("icon")[1]
    icon = style.icon or icon
    if icon then
        icon_widget:set_image(config.places.theme .. "/icons/" .. icon .. ".svg")
    end
    icon_widget:set_stylesheet(colorize_path(style.foreground))
end

function network_widget:refresh()
    local status = network_service.status
    local widgets = self._private.widgets

    if status.success and status.connected then
        local style = styles.connected

        refresh_info(widgets.connected.children[1], style, humanizer.io_speed(status.download))
        refresh_info(widgets.connected.children[2], style, humanizer.io_speed(status.upload))

        self:apply_style(style)
        self:set_widget(widgets.connected)
    else
        local style = status.success == nil
            and styles.loading
            or (status.success and styles.disconnected or styles.error)

        refresh_info(widgets.disconnected, style)

        self:apply_style(style)
        self:set_widget(widgets.disconnected)
    end
end

function network_widget.new(wibar)
    local self = capsule()

    gtable.crush(self, network_widget, true)

    self._private.wibar = wibar

    self._private.widgets = {
        connected = wibox.widget {
            layout = wibox.layout.fixed.horizontal,
            spacing = beautiful.capsule.item_spacing,
            wibox.widget {
                layout = wibox.layout.fixed.horizontal,
                spacing = beautiful.capsule.item_content_spacing,
                {
                    id = "icon",
                    widget = wibox.widget.imagebox,
                    resize = true,
                    image = config.places.theme .. "/icons/download.svg",
                },
                {
                    id = "text",
                    widget = wibox.widget.textbox,
                },
            },
            wibox.widget {
                layout = wibox.layout.fixed.horizontal,
                spacing = beautiful.capsule.item_content_spacing,
                {
                    id = "icon",
                    widget = wibox.widget.imagebox,
                    resize = true,
                    image = config.places.theme .. "/icons/upload.svg",
                },
                {
                    id = "text",
                    widget = wibox.widget.textbox,
                },
            },
        },
        disconnected = wibox.widget {
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

    capi.awesome.connect_signal("network::updated", function() self:refresh() end)

    self:refresh()

    return self
end

function network_widget.mt:__call(...)
    return network_widget.new(...)
end

return setmetatable(network_widget, network_widget.mt)
