---@meta

---@class LgiPlayerctlPlayer
---@operator call: LgiPlayerctlPlayer
---@field player_name string
---@field player_instance string
---@field source LgiPlayerctlSource
---@field playback_status LgiPlayerctlPlaybackStatus
---@field position integer
---@field shuffle boolean
---@field loop_status LgiPlayerctlLoopStatus
---@field volume number
---@field metadata LgiPlayerctlMetadata
---@field can_control boolean
---@field can_go_next boolean
---@field can_go_previous boolean
---@field can_pause boolean
---@field can_play boolean
---@field can_seek boolean
---@field on_exit fun(player: LgiPlayerctlPlayer)
---@field on_loop_status fun(player: LgiPlayerctlPlayer, loop_status: LgiPlayerctlLoopStatus)
---@field on_metadata fun(player: LgiPlayerctlPlayer, metadata: LgiPlayerctlMetadata)
---@field on_playback_status fun(player: LgiPlayerctlPlayer, playback_status: LgiPlayerctlPlaybackStatus)
---@field on_seeked fun(player: LgiPlayerctlPlayer, position: integer)
---@field on_shuffle fun(player: LgiPlayerctlPlayer, shuffle: boolean)
---@field on_volume fun(player: LgiPlayerctlPlayer, volume: number)
local LgiPlayerctlPlayer

---@param name string
---@return LgiPlayerctlPlayer
function LgiPlayerctlPlayer.new(name)
end

---@param name string
---@param source LgiPlayerctlSource
---@return LgiPlayerctlPlayer
function LgiPlayerctlPlayer.new_for_source(name, source)
end

---@param name LgiPlayerctlPlayerName
---@return LgiPlayerctlPlayer
function LgiPlayerctlPlayer.new_from_name(name)
end

---@param uri string
function LgiPlayerctlPlayer:open(uri)
end

function LgiPlayerctlPlayer:play_pause()
end

function LgiPlayerctlPlayer:play()
end

function LgiPlayerctlPlayer:stop()
end

---@param offset integer
function LgiPlayerctlPlayer:seek(offset)
end

function LgiPlayerctlPlayer:pause()
end

function LgiPlayerctlPlayer:next()
end

function LgiPlayerctlPlayer:previous()
end

---@param property? string
---@return string|nil
function LgiPlayerctlPlayer:get_metadata_prop(property)
end

---@return string|nil
function LgiPlayerctlPlayer:get_artist()
end

---@return string|nil
function LgiPlayerctlPlayer:get_title()
end

---@return string|nil
function LgiPlayerctlPlayer:get_album()
end

---@param volume number
function LgiPlayerctlPlayer:set_volume(volume)
end

---@return integer
function LgiPlayerctlPlayer:get_position()
end

---@param position integer
function LgiPlayerctlPlayer:set_position(position)
end

---@param loop_status LgiPlayerctlLoopStatus
function LgiPlayerctlPlayer:set_loop_status(loop_status)
end

---@param shuffle boolean
function LgiPlayerctlPlayer:set_shuffle(shuffle)
end
