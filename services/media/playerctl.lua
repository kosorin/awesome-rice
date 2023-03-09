-- DEPENDENCIES: playerctl

local setmetatable = setmetatable
local type = type
local pairs = pairs
local ipairs = ipairs
local gobject = require("gears.object")
local gtable = require("gears.table")
local lgi_playerctl = require("lgi").Playerctl


local lowest_priority = math.huge
local any_player = { name = "%any" }

local playerctl = { mt = {} }

local function find_player(self, instance)
    for _, player in ipairs(self._private.manager.players) do
        if player.player_instance == instance then
            return player
        end
    end
end

local function for_each_player(self, player_pattern, action)
    local players
    if not player_pattern then
        local player_data = self._private.primary_player_data
        if player_data then
            players = { find_player(self, player_data.instance) }
        end
    elseif type(player_pattern) == "string" then
        players = { find_player(self, player_pattern) }
    elseif player_pattern == true then
        players = self._private.manager.players
    end

    if players then
        for _, p in ipairs(players) do
            action(p)
        end
    end
end

function playerctl:play_pause(player_pattern)
    for_each_player(self, player_pattern, function(p)
        p:play_pause()
    end)
end

function playerctl:play(player_pattern)
    for_each_player(self, player_pattern, function(p)
        p:play()
    end)
end

function playerctl:pause(player_pattern)
    for_each_player(self, player_pattern, function(p)
        p:pause()
    end)
end

function playerctl:stop(player_pattern)
    for_each_player(self, player_pattern, function(p)
        p:stop()
    end)
end

function playerctl:previous(player_pattern)
    for_each_player(self, player_pattern, function(p)
        p:previous()
    end)
end

function playerctl:next(player_pattern)
    for_each_player(self, player_pattern, function(p)
        p:next()
    end)
end

function playerctl:skip(offset, player_pattern)
    if offset > 0 then
        self:next(player_pattern)
    else
        self:previous(player_pattern)
    end
end

function playerctl:rewind(offset, player_pattern)
    self:seek(-offset, player_pattern)
end

function playerctl:fast_forward(offset, player_pattern)
    self:seek(offset, player_pattern)
end

function playerctl:seek(offset, player_pattern)
    for_each_player(self, player_pattern, function(p)
        p:seek(offset)
    end)
end

function playerctl:set_loop_status(loop_status, player_pattern)
    loop_status = loop_status:upper()
    for_each_player(self, player_pattern, function(p)
        p:set_loop_status(loop_status)
    end)
end

function playerctl:cycle_loop_status(player_pattern)
    for_each_player(self, player_pattern, function(p)
        if p.loop_status == "NONE" then
            p:set_loop_status("TRACK")
        elseif p.loop_status == "TRACK" then
            p:set_loop_status("PLAYLIST")
        elseif p.loop_status == "PLAYLIST" then
            p:set_loop_status("NONE")
        end
    end)
end

function playerctl:set_position(position, player_pattern)
    for_each_player(self, player_pattern, function(p)
        p:set_position(position)
    end)
end

function playerctl:set_shuffle(shuffle, player_pattern)
    for_each_player(self, player_pattern, function(p)
        p:set_shuffle(shuffle)
    end)
end

function playerctl:toggle_shuffle(player_pattern)
    for_each_player(self, player_pattern, function(p)
        p:set_shuffle(not p.shuffle)
    end)
end

function playerctl:set_volume(volume, player_pattern)
    for_each_player(self, player_pattern, function(p)
        p:set_shuffle(volume)
    end)
end

function playerctl:is_primary_player(player_data)
    return self._private.primary_player_data == player_data
end

function playerctl:get_primary_player_data()
    return self._private.primary_player_data
end

local function update_primary_player(self, candidate)
    if candidate then
        self._private.manager:move_player_to_top(candidate)
    end

    local primary_player = self._private.manager.players[1]

    local old = self._private.primary_player_data
    local new = self._private.player_data[primary_player and primary_player.player_instance]
    if old ~= new then
        self._private.primary_player_data = new
        self:emit_signal("media::player::primary", new, old)
    end
end

local function filter_name(self, player_name)
    if self._private.excluded_players[player_name] then
        return false
    end
    if self._private.player_priorities[any_player] or self._private.player_priorities[player_name] then
        return true
    end
    return false
end

local function compare_players(self, player_a, player_b)
    local playing_a = player_a.playback_status == "PLAYING" and 0 or 1
    local playing_b = player_b.playback_status == "PLAYING" and 0 or 1
    if playing_a ~= playing_b then
        return playing_a - playing_b
    end

    local priorities = self._private.player_priorities
    local priority_a = priorities[player_a.player_name] or priorities[any_player] or lowest_priority
    local priority_b = priorities[player_b.player_name] or priorities[any_player] or lowest_priority
    return priority_a - priority_b
end

local function update_metadata(player_data, metadata, tracked_metadata)
    assert(player_data)

    metadata = metadata and metadata.value or {}

    local changed = false
    if not player_data.metadata then
        player_data.metadata = {}
        changed = true
    end

    -- Keep only primitive data types in metadata
    -- So for example convert "as" variant to table

    player_data.metadata = player_data.metadata or {}
    for name, mpris_name in pairs(tracked_metadata) do
        local value = metadata[mpris_name]
        local value_type = type(value)
        if value_type == "nil" or value_type == "boolean" or value_type == "number" or value_type == "string" then
            if player_data.metadata[name] ~= value then
                player_data.metadata[name] = value
                changed = true
            end
        elseif value_type == "userdata" and value.type == "as" then
            local old = player_data.metadata[name]
            if type(old) ~= "table" then
                old = {}
            end

            local new = {}
            for _, s in value:ipairs() do
                new[#new + 1] = s
            end

            player_data.metadata[name] = new

            if not changed then
                if #old ~= #new then
                    changed = true
                else
                    for i = 1, #new do
                        if old[i] ~= new[i] then
                            changed = true
                            break
                        end
                    end
                end
            end
        end
    end

    return changed
end

local function manage_player(self, full_name)
    local new_player = lgi_playerctl.Player.new_from_name(full_name)

    function new_player.on_metadata(p, metadata)
        local player_data = self._private.player_data[p.player_instance]
        if player_data and update_metadata(player_data, metadata, self._private.tracked_metadata) then
            self:emit_signal("media::player::metadata", player_data)
        end
    end

    function new_player.on_playback_status(p, playback_status)
        update_primary_player(self, p)

        local player_data = self._private.player_data[p.player_instance]
        if player_data and player_data.playback_status ~= playback_status then
            player_data.playback_status = playback_status
            self:emit_signal("media::player::playback_status", player_data)
        end
    end

    function new_player.on_seeked(p, position)
        local player_data = self._private.player_data[p.player_instance]
        if player_data and player_data.position ~= position then
            player_data.position = position
            self:emit_signal("media::player::position", player_data)
        end
    end

    function new_player.on_shuffle(p, shuffle)
        local player_data = self._private.player_data[p.player_instance]
        if player_data and player_data.shuffle ~= shuffle then
            player_data.shuffle = shuffle
            self:emit_signal("media::player::shuffle", player_data)
        end
    end

    function new_player.on_loop_status(p, loop_status)
        local player_data = self._private.player_data[p.player_instance]
        if player_data and player_data.loop_status ~= loop_status then
            player_data.loop_status = loop_status
            self:emit_signal("media::player::loop_status", player_data)
        end
    end

    function new_player.on_volume(p, volume)
        local player_data = self._private.player_data[p.player_instance]
        if player_data and player_data.volume ~= volume then
            player_data.volume = volume
            self:emit_signal("media::player::volume", player_data)
        end
    end

    self._private.manager:manage_player(new_player)

    return new_player
end

local function initialize_manager(self)
    self._private.player_data = {}

    self._private.manager = lgi_playerctl.PlayerManager()
    self._private.manager:set_sort_func(function(a, b)
        local player_a = lgi_playerctl.Player(a)
        local player_b = lgi_playerctl.Player(b)
        return compare_players(self, player_a, player_b)
    end)

    local function try_manage(full_name)
        if filter_name(self, full_name.name) then
            return manage_player(self, full_name)
        end
    end

    function self._private.manager.on_name_appeared(_, full_name)
        try_manage(full_name)
    end

    function self._private.manager.on_player_appeared(_, player)
        local player_data = {
            name = player.player_name,
            instance = player.player_instance,
            playback_status = player.playback_status,
            position = player.position,
            shuffle = player.shuffle,
            loop_status = player.loop_status,
            volume = player.volume,
        }
        update_metadata(player_data, player.metadata, self._private.tracked_metadata)

        self._private.player_data[player_data.instance] = player_data
        self:emit_signal("media::player::appeared", player_data)

        update_primary_player(self, player)
    end

    function self._private.manager.on_player_vanished(_, player)
        update_primary_player(self)

        self:emit_signal("media::player::vanished", assert(self._private.player_data[player.player_instance]))
        self._private.player_data[player.player_instance] = nil
    end

    for _, full_name in ipairs(self._private.manager.player_names) do
        try_manage(full_name)
    end

    update_primary_player(self)
end

local function parse_args(self, args)
    args = args or {}

    self._private.tracked_metadata = args.metadata or {}

    local excluded_players = {}
    if type(args.excluded_players) == "string" then
        excluded_players[args.excluded_players] = true
    elseif args.excluded_players then
        for _, name in ipairs(args.excluded_players) do
            excluded_players[name] = true
        end
    end
    self._private.excluded_players = excluded_players

    local function get_priority_key(name)
        return name == any_player.name and any_player or name
    end
    local player_priorities
    if type(args.players) == "string" then
        player_priorities = { [get_priority_key(args.players)] = 1 }
    elseif type(args.players) == "table" and #args.players > 0 then
        player_priorities = {}
        for i, name in ipairs(args.players) do
            player_priorities[get_priority_key(name)] = i
        end
    else
        player_priorities = { [any_player] = 1 }
    end
    self._private.player_priorities = player_priorities
end

function playerctl.new(args)
    local self = gtable.crush(gobject {}, playerctl, true)
    self._private = {}

    parse_args(self, args)

    initialize_manager(self)

    return self
end

function playerctl.mt:__call(...)
    return playerctl.new(...)
end

return setmetatable(playerctl, playerctl.mt)
