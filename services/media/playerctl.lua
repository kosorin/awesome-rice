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

function playerctl:find_players(player_name)
    local players = {}
    for _, player in ipairs(self._private.manager.players) do
        if player.player_name == player_name then
            players[#players + 1] = player
        end
    end
    return players
end

function playerctl:find_player(player_instance)
    for _, player in ipairs(self._private.manager.players) do
        if player.player_instance == player_instance then
            return player
        end
    end
end

local function for_each_player(self, player_pattern, action)
    local players
    if not player_pattern then
        players = { self._private.primary_player }
    elseif type(player_pattern) == "string" then
        players = { self:find_player(player_pattern) }
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
    self:seek( -offset, player_pattern)
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
    local loop_status = loop_status:upper()
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

function playerctl:is_primary_player(player)
    return self._private.primary_player == player
end

function playerctl:get_primary_player()
    return self._private.primary_player
end

local function update_primary_player(self, candidate)
    if candidate then
        self._private.manager:move_player_to_top(candidate)
    end

    local old = self._private.primary_player
    local new = self._private.manager.players[1]
    if old ~= new then
        self._private.primary_player = new
        self:emit_signal("media::player::primary", new, old)
    end
end

local function filter_name(self, player_name)
    if self.excluded_players[player_name] then
        return false
    end
    if self.player_priorities[any_player] or self.player_priorities[player_name] then
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

    local priority_a = self.player_priorities[player_a.player_name] or self.player_priorities[any_player] or lowest_priority
    local priority_b = self.player_priorities[player_b.player_name] or self.player_priorities[any_player] or lowest_priority
    return priority_a - priority_b
end

local function manage_player(self, full_name)
    local new_player = lgi_playerctl.Player.new_from_name(full_name)

    function new_player.on_exit(p)
        if self._private.vanished_players[p] == true then
            return
        else
            self._private.vanished_players[p] = true
        end
        self:emit_signal("media::player::exit", p)
    end

    function new_player.on_metadata(p, metadata)
        if self._private.vanished_players[p] ~= nil then
            return
        end
        self:emit_signal("media::player::metadata", p, metadata)
    end

    function new_player.on_playback_status(p, playback_status)
        if self._private.vanished_players[p] ~= nil then
            return
        end
        update_primary_player(self, p)
        self:emit_signal("media::player::playback_status", p, playback_status)
    end

    function new_player.on_seeked(p, position)
        if self._private.vanished_players[p] ~= nil then
            return
        end
        self:emit_signal("media::player::seeked", p, position)
    end

    function new_player.on_shuffle(p, shuffle)
        if self._private.vanished_players[p] ~= nil then
            return
        end
        self:emit_signal("media::player::shuffle", p, shuffle)
    end

    function new_player.on_loop_status(p, loop_status)
        if self._private.vanished_players[p] ~= nil then
            return
        end
        self:emit_signal("media::player::loop_status", p, loop_status)
    end

    function new_player.on_volume(p, volume)
        if self._private.vanished_players[p] ~= nil then
            return
        end
        self:emit_signal("media::player::volume", p, volume)
    end

    self._private.manager:manage_player(new_player)
    return new_player
end

local function initialize_manager(self)
    --[[
    FIXME: vanished_players
    This is a workaround for lgi bug (memory leak).
    There are few issues on github already (for example https://github.com/lgi-devs/lgi/issues/55).
    Signals (on_*) are not GCed or are GCed too late so handlers are called even after players are vanished.
    ]]
    self._private.vanished_players = setmetatable({}, { __mode = "k" })
    self._private.manager = lgi_playerctl.PlayerManager()
    self._private.manager:set_sort_func(function(a, b)
        local player_a = lgi_playerctl.Player(a)
        local player_b = lgi_playerctl.Player(b)
        return compare_players(self, player_a, player_b)
    end)

    local function try_manage(full_name)
        if filter_name(self, full_name.name) then
            manage_player(self, full_name)
        end
    end

    function self._private.manager.on_name_appeared(_, full_name)
        try_manage(full_name)
    end

    function self._private.manager.on_player_appeared(_, player)
        self:emit_signal("media::player::appeared", player)
        update_primary_player(self)
    end

    function self._private.manager.on_player_vanished(_, player)
        self._private.vanished_players[player] = false
        self:emit_signal("media::player::vanished", player)
        update_primary_player(self)
    end

    for _, full_name in ipairs(self._private.manager.player_names) do
        try_manage(full_name)
    end

    update_primary_player(self)
end

local function parse_args(self, args)
    args = args or {}

    self.excluded_players = {}
    if type(args.excluded_players) == "string" then
        self.excluded_players[args.excluded_players] = true
    elseif args.excluded_players then
        for _, name in ipairs(args.excluded_players) do
            self.excluded_players[name] = true
        end
    end

    local function get_priority_key(name)
        return name == any_player.name and any_player or name
    end
    if type(args.players) == "string" then
        self.player_priorities = { [get_priority_key(args.players)] = 1 }
    elseif type(args.players) == "table" and #args.players > 0 then
        self.player_priorities = {}
        for i, name in ipairs(args.players) do
            self.player_priorities[get_priority_key(name)] = i
        end
    else
        self.player_priorities = { [any_player] = 1 }
    end
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
