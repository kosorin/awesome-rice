local pairs = pairs
local table = table
local string = string
local wibox = require("wibox")
local config = require("config")
local gstring = require("gears.string")
local binding = require("io.binding")
local mod = binding.modifier
local btn = binding.button
local beautiful = require("beautiful")
local gshape = require("gears.shape")
local dpi = dpi
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local hstring = require("helpers.string")
local hmouse = require("helpers.mouse")
local capsule = require("widget.capsule")
local css = require("utils.css")
local tcolor = require("theme.color")
local pango = require("utils.pango")
local desktop = require("utils.desktop")
local media_player = require("services.media").player


local media_player_widget = { mt = {} }

local function left_shape(cr, width, height)
    gshape.partially_rounded_rect(cr, width, height, true, false, false, true, beautiful.capsule.shape_radius)
end

local function right_shape(cr, width, height)
    gshape.partially_rounded_rect(cr, width, height, false, true, true, false, beautiful.capsule.shape_radius)
end

local function set_playback_position_ratio(self, ratio)
    self._private.playback_bar:set_ratio(1, ratio)
end

local function update_player(self, player)
    self._private.drag_interrupted = true

    local icon = desktop.lookup_icon(player and player.player_name)
    self._private.icon:set_image(icon)

    self._private.content_container:set_visible(not not player)
    self._private.content_container:set_shape(player and left_shape)
    self._private.previous_button:set_shape(not player and left_shape)

    local button_style = player
        and beautiful.capsule.styles.normal
        or beautiful.capsule.styles.disabled
    self._private.previous_button:apply_style(button_style)
    self._private.play_pause_button:apply_style(button_style)
    self._private.next_button:apply_style(button_style)
end

local function update_metadata(self, player, metadata)
    self._private.drag_interrupted = true

    metadata = metadata or (player and player.metadata)
    local text, any_text
    if metadata then
        local md = metadata.value

        local title = gstring.xml_escape(hstring.trim(md["xesam:title"] or ""))
        local artist = gstring.xml_escape(hstring.trim(table.concat(md["xesam:artist"] or {}, ", ")))
        local separator = #title > 0 and #artist > 0 and " / " or ""
        any_text = #title > 0 or #artist > 0

        title = title
        artist = #artist > 0 and pango.span { alpha = "65%", artist } or ""
        separator = #separator > 0 and pango.span { alpha = "65%", separator } or ""
        text = table.concat({ title, artist }, separator)
    else
        text = ""
        any_text = false
    end
    self._private.text:set_markup(text)
    self._private.text:set_visible(any_text)
end

local function update_playback_status(self, player, playback_status)
    self._private.drag_interrupted = true

    playback_status = playback_status or (player and player.playback_status)
    local is_playing = playback_status == "PLAYING"

    self._private.content_container:apply_style(is_playing
    and beautiful.media_player.capsule.normal
    or beautiful.media_player.capsule.disabled)

    self._private.play_pause_button.widget:set_image(is_playing
    and config.places.theme .. "/icons/pause.svg"
    or config.places.theme .. "/icons/play.svg")

    self._private.playback_bar.opacity = is_playing and 0.5 or 0.2
    self._private.icon.opacity = is_playing and 1 or 0.5
end

local function update_playback_position(self, player, position)
    self._private.drag_interrupted = true

    local ratio
    if player then
        position = position or player:get_position() or 0
        local length = player.metadata.value["mpris:length"] or 0
        if position <= 0 or length <= 0 then
            ratio = 0
        elseif position >= length then
            ratio = 1
        else
            ratio = position / length
        end
    else
        ratio = 0
    end

    set_playback_position_ratio(self, ratio)
end

local function update(self, player)
    self._private.drag_interrupted = true

    update_player(self, player)
    update_metadata(self, player)
    update_playback_status(self, player)
    update_playback_position(self, player)
end

local function refresh_timer(self, player)
    if player and player.playback_status == "PLAYING" then
        self._private.playback_position_timer:again()
    else
        self._private.playback_position_timer:stop()
    end
end

local function initialize_content_container(self)
    self._private.content_container = self:get_children_by_id("#content_container")[1]
    self._private.icon = self:get_children_by_id("#icon")[1]
    self._private.text = self:get_children_by_id("#text")[1]
end

local function initialize_playback_bar(self)
    self._private.playback_bar = wibox.widget {
        layout = wibox.layout.ratio.horizontal,
        {
            widget = wibox.container.background,
            bg = beautiful.common.secondary_66,
        },
        {
            widget = wibox.container.background,
            bg = tcolor.transparent,
        },
    }

    self._private.content_container._private.layout:get_children_by_id("#background_content")[1]
        :insert(1, self._private.playback_bar)

    set_playback_position_ratio(self, 0)

    do
        local length
        hmouse.start_grabbing {
            wibox = self._private.wibar,
            widget = self._private.playback_bar,
            minimum = 0,
            maximum = 1,
            start = function()
                if self._private.is_dragging then
                    return
                end

                local player = media_player:get_primary_player()
                if not player then
                    return
                end

                length = player.metadata.value["mpris:length"] or 0
                if length <= 0 then
                    return
                end

                self._private.is_dragging = true
                self._private.drag_interrupted = false
                return true
            end,
            update = function(ratio)
                set_playback_position_ratio(self, ratio)
            end,
            finish = function(ratio, interrupted)
                self._private.is_dragging = false
                self._private.drag_interrupted = false

                refresh_timer(self, media_player:get_primary_player())

                if not interrupted then
                    self._private.is_dragging = false
                    media_player:set_position(ratio * length)
                end
            end,
            interrupt = function()
                return self._private.drag_interrupted
            end,
        }
    end
end

local function initialize_buttons(self)
    local function update_icon_foreground(button, foreground)
        button.widget:set_stylesheet(css.style { path = { fill = foreground } })
    end

    self._private.previous_button = self:get_children_by_id("#previous")[1]
    self._private.play_pause_button = self:get_children_by_id("#play_pause")[1]
    self._private.next_button = self:get_children_by_id("#next")[1]

    self._private.previous_button.foreground = tcolor.transparent
    self._private.play_pause_button.foreground = tcolor.transparent
    self._private.next_button.foreground = tcolor.transparent

    self._private.previous_button:connect_signal("property::foreground", update_icon_foreground)
    self._private.play_pause_button:connect_signal("property::foreground", update_icon_foreground)
    self._private.next_button:connect_signal("property::foreground", update_icon_foreground)
end

local function initialize_signals(self)
    media_player:connect_signal("media::player::metadata", function(_, player, metadata)
        if media_player:is_primary_player(player) then
            update_metadata(self, player, metadata)
            update_playback_position(self, player)
            refresh_timer(self, player)
        end
    end)

    media_player:connect_signal("media::player::playback_status", function(_, player, playback_status)
        if media_player:is_primary_player(player) then
            update_playback_status(self, player, playback_status)
            update_playback_position(self, player)
            refresh_timer(self, player)
        end
    end)

    media_player:connect_signal("media::player::seeked", function(_, player, position)
        if media_player:is_primary_player(player) then
            update_playback_position(self, player, position)
            refresh_timer(self, player)
        end
    end)

    media_player:connect_signal("media::player::primary", function(_, player)
        update(self, player)
        refresh_timer(self, player)
    end)
end

function media_player_widget.new(wibar)
    local self = wibox.widget {
        widget = wibox.container.constraint,
        strategy = "max",
        width = dpi(500),
        {
            layout = wibox.layout.fixed.horizontal,
            reverse = true,
            fill_space = true,
            {
                id = "#content_container",
                enabled = false,
                widget = capsule,
                margins = {
                    left = beautiful.capsule.default_style.margins.left,
                    right = 0,
                    top = beautiful.wibar.padding.top,
                    bottom = beautiful.wibar.padding.bottom,
                },
                {
                    widget = wibox.container.constraint,
                    strategy = "min",
                    width = dpi(150),
                    {
                        layout = wibox.layout.fixed.horizontal,
                        spacing = beautiful.capsule.item_content_spacing,
                        {
                            id = "#icon",
                            widget = wibox.widget.imagebox,
                            resize = true,
                        },
                        {
                            id = "#text",
                            widget = wibox.widget.textbox,
                        },
                    },
                },
            },
            {
                id = "#previous",
                widget = capsule,
                margins = {
                    left = 0,
                    right = 0,
                    top = beautiful.wibar.padding.top,
                    bottom = beautiful.wibar.padding.bottom,
                },
                paddings = {
                    left = beautiful.capsule.default_style.paddings.left,
                    right = dpi(6),
                    top = dpi(6),
                    bottom = dpi(6),
                },
                buttons = binding.awful_buttons {
                    binding.awful({}, btn.left, function() media_player:previous() end),
                },
                {
                    widget = wibox.widget.imagebox,
                    image = config.places.theme .. "/icons/skip-previous.svg",
                    resize = true,
                },
            },
            {
                id = "#play_pause",
                widget = capsule,
                margins = {
                    left = 0,
                    right = 0,
                    top = beautiful.wibar.padding.top,
                    bottom = beautiful.wibar.padding.bottom,
                },
                paddings = {
                    left = beautiful.capsule.default_style.paddings.left,
                    right = beautiful.capsule.default_style.paddings.right,
                    top = dpi(6),
                    bottom = dpi(6),
                },
                shape = false,
                buttons = binding.awful_buttons {
                    binding.awful({}, btn.left, function() media_player:play_pause() end),
                },
                {
                    widget = wibox.widget.imagebox,
                    resize = true,
                },
            },
            {
                id = "#next",
                widget = capsule,
                margins = {
                    left = 0,
                    right = beautiful.capsule.default_style.margins.right,
                    top = beautiful.wibar.padding.top,
                    bottom = beautiful.wibar.padding.bottom,
                },
                paddings = {
                    left = dpi(6),
                    right = beautiful.capsule.default_style.paddings.right,
                    top = dpi(6),
                    bottom = dpi(6),
                },
                shape = right_shape,
                buttons = binding.awful_buttons {
                    binding.awful({}, btn.left, function() media_player:next() end),
                },
                {
                    widget = wibox.widget.imagebox,
                    image = config.places.theme .. "/icons/skip-next.svg",
                    resize = true,
                },
            },
        },
    }

    gtable.crush(self, media_player_widget, true)

    self._private.wibar = wibar

    initialize_content_container(self)
    initialize_playback_bar(self)
    initialize_buttons(self)
    initialize_signals(self)

    self._private.playback_position_timer = gtimer {
        timeout = 1,
        callback = function()
            if self._private.is_dragging then
                return
            end
            update_playback_position(self, media_player:get_primary_player())
        end,
    }

    local player = media_player:get_primary_player()
    update(self, player)
    refresh_timer(self, player)

    return self
end

function media_player_widget.mt:__call(...)
    return media_player_widget.new(...)
end

return setmetatable(media_player_widget, media_player_widget.mt)
