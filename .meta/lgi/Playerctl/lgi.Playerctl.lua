---@meta

---@alias LgiPlayerctlMetadata { value: table<string, any> }

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

---@class LgiPlayerctl
---@field Player LgiPlayerctlPlayer
---@field PlayerManager LgiPlayerctlPlayerManager
local M

---@return LgiPlayerctlPlayerName[]
function M.list_players()
end
