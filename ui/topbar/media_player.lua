local table = table
local string = string
local wibox = require("wibox")
local config = require("config")
local binding = require("io.binding")
local mod = binding.modifier
local btn = binding.button
local beautiful = require("theme.theme")
local gshape = require("gears.shape")
local dpi = Dpi
local gtable = require("gears.table")
local hstring = require("helpers.string")
local hmouse = require("helpers.mouse")
local capsule = require("widget.capsule")
local css = require("utils.css")
local tcolor = require("helpers.color")
local pango = require("utils.pango")
local desktop = require("utils.desktop")
local humanizer = require("utils.humanizer")
local media_player = require("services.media").player
local hui = require("helpers.ui")


---@type utils.humanizer.relative_time.args
local time_args = {
    formats = {
        day = { text = "+", format = "%.0f" },
        hour = { text = ":", format = "%02.0f" },
        minute = { text = ":", format = "%02.0f" },
        second = { format = "%02.0f" },
    },
    include_leading_zero = false,
    force_from_part = "minute",
    unit_separator = "",
    part_separator = "",
}

---@param seconds integer
---@return string
local function format_time(seconds)
    local text = humanizer.relative_time(seconds / 1000000, time_args)
    local trimmed = string.gsub(text, "^[0:]+", "")
    if #trimmed >= 4 then
        return trimmed
    else
        -- Always show atleast "m:ss"
        return text:sub(-4)
    end
end

---@param cr cairo_context
---@param width number
---@param height number
local function left_shape(cr, width, height)
    gshape.partially_rounded_rect(cr, width, height, true, false, false, true, beautiful.capsule.border_radius)
end

---@param cr cairo_context
---@param width number
---@param height number
local function right_shape(cr, width, height)
    gshape.partially_rounded_rect(cr, width, height, false, true, true, false, beautiful.capsule.border_radius)
end


---@class MediaPlayer.module
---@operator call: MediaPlayer
local M = { mt = {} }

function M.mt:__call(...)
    return M.new(...)
end


---@class MediaPlayer : wibox.container
---@field package _private MediaPlayer.private
M.object = {}
---@class MediaPlayer.private
---@field wibar unknown
---@field content_container Capsule
---@field previous_button Capsule
---@field play_pause_button Capsule
---@field next_button Capsule
---@field icon wibox.widget.imagebox
---@field text wibox.widget.textbox
---@field time wibox.widget.textbox
---@field pin wibox.container.margin
---@field playback_bar unknown
---@field is_dragging? boolean
---@field drag_interrupted? boolean

---@param self MediaPlayer
---@param ratio number
local function set_playback_position_ratio(self, ratio)
    self._private.playback_bar:set_ratio(1, ratio)
end

---@param self MediaPlayer
---@param position integer
---@param length integer
local function set_playback_time(self, position, length)
    self._private.time:set_markup(pango.span {
        fgcolor = beautiful.common.fg,
        format_time(position),
        pango.thin_space,
        "/",
        pango.thin_space,
        format_time(length),
    })
end

---@param self MediaPlayer
---@param player_data? Playerctl.data
local function update_player(self, player_data)
    self._private.drag_interrupted = true

    local icon = desktop.lookup_icon(player_data and player_data.name)
    self._private.icon:set_image(icon)

    self._private.content_container:set_visible(not not player_data)
    self._private.content_container:set_shape(player_data and right_shape or nil)
    self._private.next_button:set_shape(not player_data and right_shape or nil)
    self._private.pin:set_visible(not player_data or media_player:is_pinned(player_data))

    -- self.widget --[[@as wibox.layout.fixed]].fill_space = not player_data
    -- self.strategy = player_data and "exact" or "max"


    local button_style = player_data
        and beautiful.capsule.styles.normal
        or beautiful.capsule.styles.disabled
    self._private.previous_button:apply_style(button_style)
    self._private.play_pause_button:apply_style(button_style)
    self._private.next_button:apply_style(button_style)
end

---@param self MediaPlayer
---@param player_data? Playerctl.data
local function update_metadata(self, player_data)
    self._private.drag_interrupted = true

    local metadata = player_data and player_data.metadata
    local text, any_text
    if metadata then
        local title = pango.escape(hstring.trim(metadata.title or ""))
        local artist = pango.escape(hstring.trim(table.concat(metadata.artist or {}, ", ")))
        local separator = pango.escape(#title > 0 and #artist > 0 and " / " or "")
        any_text = #title > 0 or #artist > 0

        title = title
        artist = #artist > 0 and pango.span { fgalpha = "65%", artist } or ""
        separator = #separator > 0 and pango.span { fgalpha = "65%", separator } or ""
        text = table.concat({ title, artist }, separator)
    else
        text = ""
        any_text = false
    end
    self._private.text:set_markup(text)
    self._private.text:set_visible(any_text)
end

---@param self MediaPlayer
---@param player_data? Playerctl.data
local function update_playback_status(self, player_data)
    self._private.drag_interrupted = true

    local playback_status = player_data and player_data.playback_status
    local is_playing = playback_status == "PLAYING"

    self._private.content_container:apply_style(is_playing
        and beautiful.media_player.content_styles.normal
        or beautiful.media_player.content_styles.disabled)

    self._private.play_pause_button.widget --[[@as wibox.widget.imagebox]]:set_image(is_playing
        and config.places.theme .. "/icons/pause.svg"
        or config.places.theme .. "/icons/play.svg")

    self._private.playback_bar.opacity = is_playing and 0.5 or 0.2
    self._private.icon.opacity = is_playing and 1 or 0.5
    self._private.pin.opacity = is_playing and 1 or 0.5
end

---@param self MediaPlayer
---@param player_data? Playerctl.data
local function update_playback_position(self, player_data)
    self._private.drag_interrupted = true

    local ratio, position, length
    if player_data then
        position = player_data.position or 0
        length = player_data.metadata.length or 0
        if position <= 0 or length <= 0 then
            ratio = 0
        elseif position >= length then
            ratio = 1
        else
            ratio = position / length
        end
    else
        ratio = 0
        position = 0
        length = 0
    end

    set_playback_position_ratio(self, ratio)
    set_playback_time(self, position, length)
end

---@param self MediaPlayer
---@param player_data? Playerctl.data
local function update_all(self, player_data)
    self._private.drag_interrupted = true

    update_player(self, player_data)
    update_metadata(self, player_data)
    update_playback_status(self, player_data)
    update_playback_position(self, player_data)
end

---@param self MediaPlayer
local function initialize_content_container(self)
    self._private.content_container = self:get_children_by_id("#content_container")[1] --[[@as Capsule]]
    self._private.icon = self:get_children_by_id("#icon")[1] --[[@as wibox.widget.imagebox]]
    self._private.text = self:get_children_by_id("#text")[1] --[[@as wibox.widget.textbox]]
    self._private.time = self:get_children_by_id("#time")[1] --[[@as wibox.widget.textbox]]
    self._private.pin = self:get_children_by_id("#pin")[1] --[[@as wibox.container.margin]]

    self._private.text:set_opacity(1)
    self._private.time:set_visible(false)

    self._private.content_container:connect_signal("mouse::enter", function()
        self._private.text:set_opacity(0.5)
        self._private.time:set_visible(true)
    end)

    self._private.content_container:connect_signal("mouse::leave", function()
        self._private.text:set_opacity(1)
        self._private.time:set_visible(false)
    end)
end

---@param self MediaPlayer
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
        hmouse.attach_slider_grabber {
            wibox = self._private.wibar,
            widget = self._private.playback_bar,
            minimum = 0,
            maximum = 1,
            start = function()
                if self._private.is_dragging then
                    return
                end

                local player_data = media_player:get_primary_player_data()
                if not player_data then
                    return
                end

                length = player_data.metadata.length or 0
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

---@param self MediaPlayer
local function initialize_buttons(self)
    local function update_icon_color(button, fg)
        button.widget:set_stylesheet(css.style { path = { fill = fg } })
    end

    self._private.previous_button = self:get_children_by_id("#previous")[1] --[[@as Capsule]]
    self._private.play_pause_button = self:get_children_by_id("#play_pause")[1] --[[@as Capsule]]
    self._private.next_button = self:get_children_by_id("#next")[1] --[[@as Capsule]]

    self._private.previous_button.fg = tcolor.transparent
    self._private.play_pause_button.fg = tcolor.transparent
    self._private.next_button.fg = tcolor.transparent

    self._private.previous_button:connect_signal("property::fg", update_icon_color)
    self._private.play_pause_button:connect_signal("property::fg", update_icon_color)
    self._private.next_button:connect_signal("property::fg", update_icon_color)
end

---@param self MediaPlayer
local function initialize_signals(self)
    media_player:connect_signal("media::player::metadata", function(_, player_data)
        if media_player:is_primary_player(player_data) then
            update_metadata(self, player_data)
        end
    end)

    media_player:connect_signal("media::player::playback_status", function(_, player_data)
        if media_player:is_primary_player(player_data) then
            update_playback_status(self, player_data)
        end
    end)

    media_player:connect_signal("media::player::position", function(_, player_data, by_timer)
        if by_timer and self._private.is_dragging then
            return
        end
        if media_player:is_primary_player(player_data) then
            update_playback_position(self, player_data)
        end
    end)

    media_player:connect_signal("media::player::pinned", function(_)
        update_player(self, media_player:get_primary_player_data())
    end)

    media_player:connect_signal("media::player::primary", function(_, player_data)
        update_all(self, player_data)
    end)
end


---@param wibar unknown
---@return MediaPlayer
function M.new(wibar)
    local self = wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        {
            id = "#previous",
            widget = capsule,
            margins = hui.thickness { beautiful.wibar.paddings.top, 0, beautiful.wibar.paddings.bottom },
            paddings = hui.thickness { dpi(6), left = beautiful.capsule.default_style.paddings.left },
            shape = left_shape,
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
            margins = hui.thickness { beautiful.wibar.paddings.top, 0, beautiful.wibar.paddings.bottom },
            paddings = hui.thickness {
                dpi(6),
                left = beautiful.capsule.default_style.paddings.left,
                right = beautiful.capsule.default_style.paddings.right,
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
            margins = hui.thickness { beautiful.wibar.paddings.top, 0, beautiful.wibar.paddings.bottom },
            paddings = hui.thickness { dpi(6), right = beautiful.capsule.default_style.paddings.right },
            shape = false,
            buttons = binding.awful_buttons {
                binding.awful({}, btn.left, function() media_player:next() end),
            },
            {
                widget = wibox.widget.imagebox,
                image = config.places.theme .. "/icons/skip-next.svg",
                resize = true,
            },
        },
        {
            id = "#content_container",
            widget = capsule,
            enable_overlay = false,
            margins = hui.thickness { beautiful.wibar.paddings.top, 0, beautiful.wibar.paddings.bottom },
            shape = false,
            {
                widget = wibox.container.constraint,
                strategy = "exact",
                width = dpi(350),
                {
                    layout = wibox.layout.fixed.horizontal,
                    spacing = beautiful.capsule.item_content_spacing,
                    {
                        id = "#icon",
                        widget = wibox.widget.imagebox,
                        resize = true,
                    },
                    {
                        layout = wibox.layout.fixed.horizontal,
                        reverse = true,
                        fill_space = true,
                        spacing = beautiful.capsule.item_spacing,
                        {
                            id = "#text",
                            widget = wibox.widget.textbox,
                        },
                        {
                            id = "#time",
                            widget = wibox.widget.textbox,
                        },
                        {
                            id = "#pin",
                            widget = wibox.container.margin,
                            margins = hui.thickness { dpi(2), -dpi(2) },
                            {
                                widget = wibox.widget.imagebox,
                                image = config.places.theme .. "/icons/pin.svg",
                                resize = true,
                                stylesheet = css.style { path = { fill = beautiful.common.secondary_bright } },
                            },
                        },
                    },
                },
            },
        },
    }
    ---@cast self MediaPlayer

    gtable.crush(self, M.object, true)

    self._private.wibar = wibar

    self.buttons = binding.awful_buttons {
        binding.awful({}, btn.middle, function()
            local player_data = media_player:get_primary_player_data()
            local is_pinned = player_data and media_player:is_pinned(player_data)
            media_player:pin(not is_pinned and player_data or nil)
        end),
    }

    initialize_content_container(self)
    initialize_playback_bar(self)
    initialize_buttons(self)
    initialize_signals(self)

    update_all(self, media_player:get_primary_player_data())

    return self
end

return setmetatable(M, M.mt)
