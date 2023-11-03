local capi = Capi
local pairs, ipairs = pairs, ipairs
local table = table
local aspawn = require("awful.spawn")
local wibox = require("wibox")
local config = require("rice.config")
local gtable = require("gears.table")
local binding = require("core.binding")
local mod = binding.modifier
local btn = binding.button
local beautiful = require("theme.theme")
local dpi = Dpi
local desktop = require("services.desktop")
local mebox = require("widget.mebox")
local media_player = require("services.media").player
local applications_menu_template = require("ui.menu.templates.applications")
local rice_media = require("rice.media")


local play_pause_status = {
    [false] = {
        icon = beautiful.icon("play.svg"),
        color = beautiful.palette.gray,
    },
    [true] = {
        icon = beautiful.icon("pause.svg"),
        color = beautiful.palette.gray_bright,
    },
}

local pin_status = {
    [false] = {
        icon = beautiful.icon("pin-off.svg"),
        color = beautiful.palette.gray_75,
    },
    [true] = {
        icon = beautiful.icon("pin.svg"),
        color = beautiful.palette.gray_bright,
    },
}


local M = {}

---@param item MeboxItem
---@param player_data Playerctl.data
local function update_title(item, player_data)
    item.text = ("%s"):format(player_data and player_data.metadata.title or "")
end

---@param item MeboxItem
---@param player_data Playerctl.data
local function update_play_pause_icon(item, player_data)
    local style = play_pause_status[player_data and player_data.playback_status == "PLAYING" or false]
    item.icon = style.icon
    item.icon_color = style.color
end

---@param item MeboxItem
---@param player_data Playerctl.data
local function update_pin_icon(item, player_data)
    local style = pin_status[not not media_player:is_pinned(player_data)]
    item.icon = style.icon
    item.icon_color = style.color
end

---@return Mebox.new.args
function M.new()
    ---@type Mebox.new.args
    local args = {
        item_width = beautiful.mebox.default_style.item_height,
        on_show = function(menu, args, context)
            local signals = menu._private.player_signals
            if not signals then
                signals = {}
                menu._private.player_signals = signals

                ---@param player_data Playerctl.data
                function signals.metadata(_, player_data)
                    for _, item in ipairs(menu._private.items or {}) do
                        if item.player and item.player.field == "title" and item.player.data == player_data then
                            update_title(item, item.player.data)
                            menu:update_item(item.index)
                            break
                        end
                    end
                end

                ---@param player_data Playerctl.data
                function signals.playback_status(_, player_data)
                    for _, item in ipairs(menu._private.items or {}) do
                        if item.player and item.player.field == "play_pause" and item.player.data == player_data then
                            update_play_pause_icon(item, item.player.data)
                            menu:update_item(item.index)
                            break
                        end
                    end
                end

                function signals.pinned(_)
                    for _, item in ipairs(menu._private.items or {}) do
                        if item.player and item.player.field == "pin" then
                            update_pin_icon(item, item.player.data)
                            menu:update_item(item.index)
                        end
                    end
                end

                function signals.reopen()
                    menu:show(args, context, true)
                end
            end
            media_player:connect_signal("media::player::appeared", signals.reopen)
            media_player:connect_signal("media::player::vanished", signals.reopen)
            media_player:connect_signal("media::player::metadata", signals.metadata)
            media_player:connect_signal("media::player::playback_status", signals.playback_status)
            media_player:connect_signal("media::player::pinned", signals.pinned)
        end,
        on_hide = function(menu)
            local signals = menu._private.player_signals
            if signals then
                media_player:disconnect_signal("media::player::appeared", signals.reopen)
                media_player:disconnect_signal("media::player::vanished", signals.reopen)
                media_player:disconnect_signal("media::player::metadata", signals.metadata)
                media_player:disconnect_signal("media::player::playback_status", signals.playback_status)
                media_player:disconnect_signal("media::player::pinned", signals.pinned)
            end
        end,
        layout_template = {
            layout = wibox.layout.fixed.vertical,
            {
                id = "#players",
                layout = wibox.layout.grid,
                homogeneous = false,
                forced_num_cols = 4,
            },
        },
        items_source = function()
            ---@type Playerctl.data[]
            local players_data = media_player:list()
            table.sort(players_data, function(a, b)
                ---@cast a Playerctl.data
                ---@cast b Playerctl.data
                return a.instance < b.instance
            end)
            ---@type MeboxItem.args[]
            local items = {}
            if #players_data > 0 then
                for row, player_data in ipairs(players_data) do
                    local function layout_add(column)
                        return function(layout, item_widget)
                            ---@cast layout wibox.layout.grid
                            layout:add_widget_at(item_widget, row, column)
                        end
                    end
                    items[#items + 1] = {
                        player = {
                            data = player_data,
                            field = "play_pause",
                        },
                        layout_id = "#players",
                        layout_add = layout_add(1),
                        on_show = function(item, menu, args, context)
                            update_play_pause_icon(item, player_data)
                        end,
                        callback = function(item, menu, context)
                            ---@type Playerctl.data?
                            local player_data = item.player and item.player.data or nil
                            if player_data then
                                media_player:play_pause(player_data.instance)
                            end
                            return false
                        end,
                    }
                    items[#items + 1] = function(...)
                        local item = mebox.separator(...)
                        item.layout_id = "#players"
                        item.layout_add = layout_add(2)
                        item.orientation = "horizontal"
                        return item
                    end
                    items[#items + 1] = {
                        player = {
                            data = player_data,
                            field = "title",
                        },
                        layout_id = "#players",
                        layout_add = layout_add(3),
                        width = dpi(250),
                        icon = desktop.lookup_icon(player_data and player_data.name),
                        icon_color = false,
                        on_show = function(item, menu, args, context)
                            update_title(item, player_data)
                        end,
                        callback = function(item, menu, context)
                            for _, client in ipairs(capi.client.get()) do
                                if string.lower(client.class) == string.lower(player_data.name) then
                                    client:activate {
                                        switch_to_tag = true,
                                        raise = true,
                                    }
                                    break
                                end
                            end
                        end,
                    }
                    items[#items + 1] = {
                        template = item_template,
                        player = {
                            data = player_data,
                            field = "pin",
                        },
                        layout_id = "#players",
                        layout_add = layout_add(4),
                        on_show = function(item, menu, args, context)
                            update_pin_icon(item, player_data)
                        end,
                        callback = function(item, menu, context)
                            ---@type Playerctl.data?
                            local player_data = item.player and item.player.data or nil
                            if player_data then
                                local is_pinned = media_player:is_pinned(player_data)
                                media_player:pin(not is_pinned and player_data or nil)
                            end
                            return false
                        end,
                    }
                end
            end

            local media_players = applications_menu_template.build_items(rice_media.menu)
            if #media_players > 0 then
                if #items > 0 then
                    items[#items + 1] = mebox.separator
                end
                for _, item in ipairs(media_players) do
                    items[#items + 1] = item
                end
            end

            if #items == 0 then
                items[#items + 1] = mebox.info("No Player")
            end
            return items
        end,
    }
    return args
end

M.shared = M.new()

return M
