local capi = {
    awesome = awesome,
}
local wibox = require("wibox")
local beautiful = require("beautiful")
local config = require("config")
local network_service = require("services.network")
local dpi = dpi
local binding = require("io.binding")
local mod = binding.modifier
local btn = binding.button
local humanizer = require("utils.humanizer")
local gtable = require("gears.table")
local capsule = require("widget.capsule")
local mebox = require("widget.mebox")
local pango = require("utils.pango")
local tcolor = require("theme.color")
local aplacement = require("awful.placement")
local widget_helper = require("helpers.widget")


local network_widget = { mt = {} }

local mb = 1000 * 1000
local max_download_speed = 1 * mb
local max_upload_speed = 1 * mb
local download_factor = 1
local upload_factor = 1

local units = {
    { format = "%4.0f%s%s", text = "B/s ", to = 1000 },
    { format = "%4.2f%s%s", text = "kB/s", to = 1000 * 9.99, next = false },
    { format = "%4.1f%s%s", text = "kB/s", to = 1000 * 99.9, next = false },
    { format = "%4.0f%s%s", text = "kB/s", to = 1000 * 1000 },
    { format = "%4.2f%s%s", text = "MB/s", to = 1000 * 1000 * 9.99, next = false },
    { format = "%4.1f%s%s", text = "MB/s", to = 1000 * 1000 * 99.9, next = false },
    { format = "%4.0f%s%s", text = "MB/s", to = 1000 * 1000 * 1000 },
    { format = "%4.1f%s%s", text = "GB/s", to = 1000 * 1000 * 1000 * 1000 },
}

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

        refresh_info(widgets.connected.children[1], style, humanizer.humanize_units(units, status.download))
        refresh_info(widgets.connected.children[2], style, humanizer.humanize_units(units, status.upload))

        self:apply_style(style)
        self:set_widget(widgets.connected)
        self._private.graph_widget:add_value(download_factor * status.download, 1)
        self._private.graph_widget:add_value(-upload_factor * status.upload, 2)
    else
        local style = status.success == nil
            and styles.loading
            or (status.success and styles.disconnected or styles.error)

        refresh_info(widgets.disconnected, style)

        self:apply_style(style)
        self:set_widget(widgets.disconnected)
        self._private.graph_widget:add_value(nil, 1)
        self._private.graph_widget:add_value(nil, 2)
    end
end

local dim_opacity = 0.25
local function update_opacity(self)
    local show_graph = self._private.show_graph ~= self._private.hover_widget
    self._private.graph_container.opacity = show_graph and 1 or dim_opacity
    for _, w in pairs(self._private.widgets) do
        w.opacity = not show_graph and 1 or dim_opacity
    end
end

function network_widget:show_graph(show)
    self._private.show_graph = show
    update_opacity(self)
end

function network_widget:toggle_graph()
    self:show_graph(not self._private.show_graph)
end

function network_widget.new(wibar)
    local self = capsule()

    self.enabled = false

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

    self._private.hover_widget = false
    self._private.show_graph = false

    self._private.graph_widget = wibox.widget {
        widget = wibox.widget.graph,
        background_color = tcolor.transparent,
        group_colors = {
            beautiful.palette.blue_bright,
            beautiful.palette.red_bright,
        },
        nan_indication = true,
        nan_color = beautiful.palette.red,
        step_width = 2,
        step_spacing = 0,
        min_value = -max_upload_speed,
        max_value = max_download_speed,
        scale = true,
    }
    self._private.graph_container = wibox.container.mirror(self._private.graph_widget, { horizontal = true })
    self._private.layout:get_children_by_id("#background_content")[1]
        :insert(1, self._private.graph_container)

    self:connect_signal("mouse::enter", function() self._private.hover_widget = true; update_opacity(self) end)
    self:connect_signal("mouse::leave", function() self._private.hover_widget = false; update_opacity(self) end)
    update_opacity(self)

    self.buttons = binding.awful_buttons {
        binding.awful({}, btn.middle, function()
            if not self._private.menu.visible then
                self:toggle_graph()
            end
        end),
        binding.awful({}, btn.right, function()
            self._private.menu:toggle()
        end),
    }

    capi.awesome.connect_signal("network::updated", function() self:refresh() end)

    self:refresh()

    self._private.menu = mebox {
        item_width = dpi(144),
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
            text = "show graph",
            on_show = function(item) item.checked = not not self._private.show_graph end,
            callback = function(_, item) self:show_graph(not item.checked) end,
        },
    }

    return self
end

function network_widget.mt:__call(...)
    return network_widget.new(...)
end

return setmetatable(network_widget, network_widget.mt)
