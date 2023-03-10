---@meta

---@class LgiPlayerctlPlayerManager
---@operator call: LgiPlayerctlPlayerManager
---@field players LgiPlayerctlPlayer[]
---@field player_names LgiPlayerctlPlayerName[]
---@field on_name_appeared fun(self: LgiPlayerctlPlayerManager, name: LgiPlayerctlPlayerName)
---@field on_name_vanished fun(self: LgiPlayerctlPlayerManager, name: LgiPlayerctlPlayerName)
---@field on_player_appeared fun(self: LgiPlayerctlPlayerManager, player: LgiPlayerctlPlayer)
---@field on_player_vanished fun(self: LgiPlayerctlPlayerManager, player: LgiPlayerctlPlayer)
local LgiPlayerctlPlayerManager

---@return LgiPlayerctlPlayerManager
function LgiPlayerctlPlayerManager.new()
end

---@param player LgiPlayerctlPlayer
function LgiPlayerctlPlayerManager:manage_player(player)
end

---@param sort_func fun(a: userdata, b: userdata): integer
function LgiPlayerctlPlayerManager:set_sort_func(sort_func)
end

---@param player LgiPlayerctlPlayer
function LgiPlayerctlPlayerManager:move_player_to_top(player)
end
