local capi = Capi
local setmetatable = setmetatable
local wibox = require("wibox")
local beautiful = require("theme.theme")
local config = require("rice.config")
local network_service = require("services.network")
local dpi = Dpi
local binding = require("core.binding")
local mod = binding.modifier
local btn = binding.button
local humanizer = require("utils.humanizer")
local gtable = require("gears.table")
local capsule = require("widget.capsule")
local mebox = require("widget.mebox")
local pango = require("utils.pango")
local css = require("utils.css")
local tcolor = require("utils.color")
local aplacement = require("awful.placement")
local widget_helper = require("core.widget")
local htable = require("utils.table")
local hui = require("utils.thickness")
local ucolor = require("utils.color")


local network_widget = { mt = {} }

local mb = 1000 * 1000
local max_download_speed = 1 * mb
local max_upload_speed = 1 * mb
local download_factor = 1
local upload_factor = 1

local speed_units = {
    space = pango.thin_space,
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
    connected = setmetatable({
    }, { __index = beautiful.capsule.styles.normal }),
    disconnected = setmetatable({
        text = "Disconnected",
        icon = "lan-disconnect",
    }, { __index = beautiful.capsule.styles.palette.yellow }),
    error = setmetatable({
        text = "Error",
        icon = "lan-disconnect",
    }, { __index = beautiful.capsule.styles.palette.red }),
    loading = setmetatable({
        text = "Loading",
        icon = "lan-pending",
    }, { __index = beautiful.capsule.styles.disabled }),
}

local function refresh_info(container_widget, style, text, icon)
    local text_widget = container_widget:get_children_by_id("text")[1]
    text = style.text or text or ""
    text_widget:set_markup(pango.span { fgcolor = style.fg, text })

    local icon_widget = container_widget:get_children_by_id("icon")[1]
    icon = style.icon or icon
    if icon then
        icon_widget:set_image(beautiful.icon(icon .. ".svg"))
    end
    icon_widget:set_stylesheet(css.style { path = { fill = style.fg } })
end

function network_widget:refresh()
    local status = network_service.status
    local widgets = self._private.widgets

    if status.success and status.connected then
        local style = styles.connected

        refresh_info(widgets.connected.children[1], style, humanizer.humanize_units(speed_units, status.download))
        refresh_info(widgets.connected.children[2], style, humanizer.humanize_units(speed_units, status.upload))

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

local function update_opacity(self)
    local dim_opacity = 0.25
    local show_graph = self._private.show_graph ~= self._private.hover_widget
    self.graph_container.opacity = show_graph and 1 or dim_opacity
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

function network_widget:set_graph_offset(offset)
    offset = offset or 0
    local total_graph_size = self._private.graph_widget.capacity
        * (self._private.graph_widget.step_width + self._private.graph_widget.step_spacing)
    total_graph_size = total_graph_size - (self._private.latest_width or 0)
    if offset < 0 then
        offset = 0
    elseif offset > total_graph_size then
        offset = total_graph_size
    end
    self.graph_container.right = -offset
    self._private.graph_offset = offset
end

function network_widget:fit(...)
    local width, height = capsule.object.fit(self, ...)
    self._private.latest_width = width
    return width, height
end

function network_widget.new(wibar)
    local self = wibox.widget {
        widget = capsule,
        enable_overlay = false,
        margins = hui.new {
            top = beautiful.wibar.paddings.top,
            right = beautiful.capsule.default_style.margins.right,
            bottom = beautiful.wibar.paddings.bottom,
            left = beautiful.capsule.default_style.margins.left,
        },
        nil, -- Content placeholder
        {
            id = "graph_container",
            layout = wibox.container.margin,
            {
                layout = wibox.container.mirror,
                reflection = { horizontal = true },
                {
                    id = "#graph",
                    widget = wibox.widget.graph,
                    capacity = math.floor(900 / network_service.config.interval), -- 900 ~ 15 minutes
                    background_color = tcolor.transparent,
                    group_colors = {
                        beautiful.palette.blue_bright,
                        beautiful.palette.red_bright,
                    },
                    nan_indication = true,
                    nan_color = ucolor.transparent,
                    step_width = 2,
                    step_spacing = 0,
                    min_value = -max_upload_speed,
                    max_value = max_download_speed,
                    scale = true,
                },
            },
        },
    }

    gtable.crush(self, network_widget, true)

    self._private.wibar = wibar
    self._private.hover_widget = false
    self._private.show_graph = false
    self._private.graph_offset = 0

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
                    image = beautiful.icon("download.svg"),
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
                    image = beautiful.icon("upload.svg"),
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

    self._private.graph_widget = self:get_children_by_id("#graph")[1]

    self._private.menu = mebox {
        item_width = dpi(136),
        placement = beautiful.wibar.build_placement(self, self._private.wibar),
        {
            text = "Graph",
            icon = beautiful.icon("chart-line.svg"),
            icon_color = beautiful.palette.gray,
            on_show = function(item) item.checked = not not self._private.show_graph end,
            callback = function(item) self:show_graph(not item.checked) end,
        },
    }

    self.buttons = binding.awful_buttons {
        binding.awful({}, btn.middle, function()
            if not self._private.menu.visible then
                self:toggle_graph()
            end
        end),
        binding.awful({}, btn.right, function()
            self._private.menu:toggle()
        end),
        binding.awful({}, binding.group.mouse_wheel, function(trigger)
            local step_size = math.floor(10 / network_service.config.interval)
                * (self._private.graph_widget.step_width + self._private.graph_widget.step_spacing)
            self:set_graph_offset(self._private.graph_offset - (step_size * trigger.y))
        end),
    }

    capi.awesome.connect_signal("network::updated", function() self:refresh() end)

    self:connect_signal("mouse::enter", function()
        self._private.hover_widget = true
        update_opacity(self)
    end)
    self:connect_signal("mouse::leave", function()
        self._private.hover_widget = false
        update_opacity(self)
        self:set_graph_offset(0)
    end)

    update_opacity(self)
    self:set_graph_offset(0)
    self:refresh()

    return self
end

function network_widget.mt:__call(...)
    return network_widget.new(...)
end

return setmetatable(network_widget, network_widget.mt)
