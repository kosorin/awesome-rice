---@meta

---@alias LgiPlayerctlSource
---| "NONE"
---| "DBUS_SESSION"
---| "DBUS_SYSTEM"

---@alias LgiPlayerctlPlaybackStatus
---| "PLAYING"
---| "PAUSED"
---| "STOPPED"

---@alias LgiPlayerctlLoopStatus
---| "NONE"
---| "TRACK"
---| "PLAYLIST"


---@class _LgiPlayerctl
---@field Player _LgiPlayerctlPlayer
---@field PlayerManager _LgiPlayerctlPlayerManager
local S

---@return LgiPlayerctlPlayerName[]
function S.list_players()
end
