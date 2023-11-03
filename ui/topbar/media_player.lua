local capi = Capi
local select = select
local table = table
local string = string
local wibox = require("wibox")
local config = require("rice.config")
local binding = require("core.binding")
local mod = binding.modifier
local btn = binding.button
local beautiful = require("theme.theme")
local gshape = require("gears.shape")
local dpi = Dpi
local gtable = require("gears.table")
local gcolor = require("gears.color")
local hstring = require("utils.string")
local hmouse = require("core.mouse")
local capsule = require("widget.capsule")
local css = require("utils.css")
local tcolor = require("utils.color")
local pango = require("utils.pango")
local desktop = require("services.desktop")
local humanizer = require("utils.humanizer")
local mebox = require("widget.mebox")
local media_player_menu_template = require("ui.menu.templates.media_player")
local media_player = require("services.media").player
local thickness = require("utils.thickness")


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

---@param useconds integer
---@return string
local function format_time(useconds)
    local text = humanizer.relative_time(useconds / media_player.unit, time_args)
    local trimmed = string.gsub(text, "^[0:]+", "")
    if #trimmed >= 4 then
        return trimmed
    else
        -- Always show atleast "m:ss"
        return text:sub(-4)
    end
end

---@param position_data? Playerctl.position_data
---@return number ratio
---@return integer position
---@return integer length
local function get_playback_position(position_data)
    local ratio, position, length
    if position_data then
        position = position_data.position or 0
        length = position_data.length or 0
        if position <= 0 or length <= 0 then
            position = 0
            ratio = 0
        elseif position >= length then
            position = length
            ratio = 1
        else
            ratio = position / length
        end
    else
        ratio = 0
        position = 0
        length = 0
    end
    return ratio, position, length
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


---@class MediaPlayer : wibox.widget.base
---@field package no_player_button Capsule
---@field package player_container wibox.container
---@field package _private MediaPlayer.private
M.object = {}
---@class MediaPlayer.private
---@field wibar unknown
---@field content_container Capsule
---@field app_button Capsule
---@field previous_button Capsule
---@field play_pause_button Capsule
---@field next_button Capsule
---@field icon wibox.widget.imagebox
---@field text wibox.widget.textbox
---@field time wibox.widget.textbox
---@field playback_bar unknown
---@field is_seeking? "drag"|"wheel"
---@field drag_seeking_interrupt function
---@field wheel_seeking_interrupt function

---@param self MediaPlayer
local function interrupt_seeking(self)
    self._private.drag_seeking_interrupt()
    self._private.wheel_seeking_interrupt()
end

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
    interrupt_seeking(self)

    self.no_player_button.visible = not player_data
    if self.no_player_button.visible then
        self.no_player_button:apply_style(beautiful.capsule.styles.disabled)
    end

    self.player_container.visible = not not player_data
    if self.player_container.visible then
        self._private.content_container:set_visible(not not player_data)

        local button_style = player_data
            and beautiful.capsule.styles.normal
            or beautiful.capsule.styles.disabled
        self._private.app_button:apply_style(button_style)
        self._private.previous_button:apply_style(button_style)
        self._private.play_pause_button:apply_style(button_style)
        self._private.next_button:apply_style(button_style)

        local icon = desktop.lookup_icon(player_data and player_data.name)
        self._private.icon:set_image(icon)
    end
end

---@param self MediaPlayer
---@param player_data? Playerctl.data
local function update_metadata(self, player_data)
    interrupt_seeking(self)

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
        text = "?"
        any_text = false
    end
    self._private.text:set_markup(text)
    self._private.text:set_visible(any_text)
end

---@param self MediaPlayer
---@param player_data? Playerctl.data
local function update_playback_status(self, player_data)
    interrupt_seeking(self)

    local playback_status = player_data and player_data.playback_status
    local is_playing = playback_status == "PLAYING"

    self._private.content_container:apply_style(is_playing
        and beautiful.media_player.content_styles.normal
        or beautiful.media_player.content_styles.disabled)

    self._private.play_pause_button.widget --[[@as wibox.widget.imagebox]]:set_image(is_playing
        and beautiful.icon("pause.svg")
        or beautiful.icon("play.svg"))

    self._private.playback_bar.opacity = is_playing and 0.5 or 0.2
    self._private.icon.opacity = is_playing and 1 or 0.5
end

---@param self MediaPlayer
---@param player_data? Playerctl.data
local function update_playback_position(self, player_data)
    interrupt_seeking(self)

    local position_data = media_player:get_position_data(player_data)
    local ratio, position, length = get_playback_position(position_data)
    set_playback_position_ratio(self, ratio)
    set_playback_time(self, position, length)
end

---@param self MediaPlayer
---@param player_data? Playerctl.data
local function update_all(self, player_data)
    interrupt_seeking(self)

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

    do
        local function on_enter(enter)
            self._private.text:set_opacity(enter and 0.5 or 1)
            self._private.time:set_visible(enter)
        end

        on_enter()

        self._private.content_container:connect_signal("mouse::enter", function() on_enter(true) end)
        self._private.content_container:connect_signal("mouse::leave", function() on_enter(false) end)
    end

    self._private.content_container:set_background_widget(self._private.playback_bar)

    set_playback_position_ratio(self, 0)
    set_playback_time(self, 0, 0)

    self._private.drag_seeking_interrupt = select(2, hmouse.attach_slider {
        wibox = self._private.wibar,
        widget = self._private.content_container,
        minimum = 0,
        maximum = 1,
        start = function()
            if self._private.is_seeking then
                return false
            end

            self._private.is_seeking = "drag"
            return true
        end,
        update = function(ratio)
            local position_data = media_player:get_position_data()
            local _, _, length = get_playback_position(position_data)
            set_playback_position_ratio(self, ratio)
            set_playback_time(self, ratio * length, length)
        end,
        finish = function(ratio, interrupted)
            self._private.is_seeking = nil

            if not interrupted then
                local position_data = media_player:get_position_data()
                local _, _, length = get_playback_position(position_data)
                media_player:set_position(ratio * length)
            end
        end,
    })

    self._private.wheel_seeking_interrupt = select(2, hmouse.attach_wheel {
        widget = self,
        step = 5 * media_player.unit,
        start = function()
            if self._private.is_seeking then
                return false
            end

            self._private.is_seeking = "wheel"
            return true
        end,
        update = function(total_delta)
            local position_data = media_player:get_position_data()
            if position_data then
                position_data.position = position_data.position + total_delta
            end
            local ratio, position, length = get_playback_position(position_data)
            set_playback_position_ratio(self, ratio)
            set_playback_time(self, position, length)
        end,
        finish = function(total_delta, interrupted)
            self._private.is_seeking = nil

            if not interrupted then
                media_player:seek(total_delta)
            end
        end,
    })
end

---@param self MediaPlayer
local function initialize_buttons(self)
    local function update_icon_color(button, fg)
        button.widget:set_stylesheet(css.style { path = { fill = gcolor.ensure_pango_color(fg) } })
    end

    self._private.app_button = self:get_children_by_id("#app")[1] --[[@as Capsule]]
    self._private.previous_button = self:get_children_by_id("#previous")[1] --[[@as Capsule]]
    self._private.play_pause_button = self:get_children_by_id("#play_pause")[1] --[[@as Capsule]]
    self._private.next_button = self:get_children_by_id("#next")[1] --[[@as Capsule]]

    self._private.app_button.fg = tcolor.transparent
    self._private.previous_button.fg = tcolor.transparent
    self._private.play_pause_button.fg = tcolor.transparent
    self._private.next_button.fg = tcolor.transparent

    self._private.app_button:connect_signal("property::fg", update_icon_color)
    self._private.previous_button:connect_signal("property::fg", update_icon_color)
    self._private.play_pause_button:connect_signal("property::fg", update_icon_color)
    self._private.next_button:connect_signal("property::fg", update_icon_color)


    self.no_player_button.fg = tcolor.transparent
    local icon = self:get_children_by_id("#no_player_button.icon")[1] --[[@as wibox.widget.imagebox]]
    self.no_player_button:connect_signal("property::fg", function(_, fg)
        icon:set_stylesheet(css.style { path = { fill = gcolor.ensure_pango_color(fg) } })
    end)
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
        if by_timer and self._private.is_seeking then
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
        layout = wibox.layout.stack,
        {
            id = "no_player_button",
            widget = capsule,
            margins = thickness.new { beautiful.wibar.paddings.top, 0, beautiful.wibar.paddings.bottom },
            {
                layout = wibox.layout.fixed.horizontal,
                spacing = beautiful.capsule.item_content_spacing,
                {
                    id = "#no_player_button.icon",
                    widget = wibox.widget.imagebox,
                    image = beautiful.icon("music.svg"),
                    resize = true,
                },
                {
                    widget = wibox.widget.textbox,
                    text = "No Player",
                },
            },
        },
        {
            id = "player_container",
            widget = wibox.container.constraint,
            strategy = "max",
            width = dpi(600),
            {
                layout = wibox.layout.align.horizontal,
                expand = "inside",
                {
                    id = "#app",
                    widget = capsule,
                    margins = thickness.new { beautiful.wibar.paddings.top, 0, beautiful.wibar.paddings.bottom },
                    paddings = thickness.new { dpi(6), beautiful.capsule.default_style.paddings.right },
                    shape = left_shape,
                    buttons = binding.awful_buttons {
                        binding.awful({}, btn.left, function()
                            local player_data = media_player:get_primary_player_data()
                            if not player_data then
                                return
                            end
                            for _, client in ipairs(capi.client.get()) do
                                if string.lower(client.class) == string.lower(player_data.name) then
                                    client:activate {
                                        switch_to_tag = true,
                                        raise = true,
                                    }
                                    break
                                end
                            end
                        end),
                    },
                    {
                        id = "#icon",
                        widget = wibox.widget.imagebox,
                        image = beautiful.icon("music.svg"),
                        resize = true,
                    },
                },
                {
                    id = "#content_container",
                    widget = capsule,
                    enable_overlay = false,
                    margins = thickness.new { beautiful.wibar.paddings.top, 0, beautiful.wibar.paddings.bottom },
                    shape = false,
                    {
                        layout = wibox.layout.fixed.horizontal,
                        reverse = true,
                        fill_space = true,
                        spacing = beautiful.capsule.item_spacing,
                        {
                            id = "#text",
                            widget = wibox.widget.textbox,
                            halign = "left",
                        },
                        {
                            id = "#time",
                            widget = wibox.widget.textbox,
                            halign = "right",
                        },
                    },
                },
                {
                    layout = wibox.layout.fixed.horizontal,
                    {
                        id = "#previous",
                        widget = capsule,
                        margins = thickness.new { beautiful.wibar.paddings.top, 0, beautiful.wibar.paddings.bottom },
                        paddings = thickness.new { dpi(6), left = beautiful.capsule.default_style.paddings.left },
                        shape = false,
                        buttons = binding.awful_buttons {
                            binding.awful({}, btn.left, function() media_player:previous() end),
                        },
                        {
                            widget = wibox.widget.imagebox,
                            image = beautiful.icon("skip-previous.svg"),
                            resize = true,
                        },
                    },
                    {
                        id = "#play_pause",
                        widget = capsule,
                        margins = thickness.new { beautiful.wibar.paddings.top, 0, beautiful.wibar.paddings.bottom },
                        paddings = thickness.new {
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
                        margins = thickness.new { beautiful.wibar.paddings.top, 0, beautiful.wibar.paddings.bottom },
                        paddings = thickness.new { dpi(6), right = beautiful.capsule.default_style.paddings.right },
                        shape = right_shape,
                        buttons = binding.awful_buttons {
                            binding.awful({}, btn.left, function() media_player:next() end),
                        },
                        {
                            widget = wibox.widget.imagebox,
                            image = beautiful.icon("skip-next.svg"),
                            resize = true,
                        },
                    },
                },
            },
        },
    }
    ---@cast self MediaPlayer

    gtable.crush(self, M.object, true)

    self._private.wibar = wibar

    self._private.menu = mebox(media_player_menu_template.shared)

    self.player_container.buttons = binding.awful_buttons {
        binding.awful({}, btn.right, function()
            self._private.menu:toggle {
                placement = beautiful.wibar.build_placement(self, self._private.wibar),
            }
        end),
        binding.awful({}, btn.middle, function()
            if not self.player_container.visible then
                return
            end
            media_player:play_pause()
        end),
    }

    initialize_content_container(self)
    initialize_buttons(self)
    initialize_signals(self)

    update_all(self, media_player:get_primary_player_data())

    return self
end

return setmetatable(M, M.mt)
