---@meta

---@class LgiPlayerctlPlayerManager
---@field players LgiPlayerctlPlayer[]
---@field player_names LgiPlayerctlPlayerName[]
---@field on_name_appeared fun(self: LgiPlayerctlPlayerManager, name: LgiPlayerctlPlayerName)
---@field on_name_vanished fun(self: LgiPlayerctlPlayerManager, name: LgiPlayerctlPlayerName)
---@field on_player_appeared fun(self: LgiPlayerctlPlayerManager, player: LgiPlayerctlPlayer)
---@field on_player_vanished fun(self: LgiPlayerctlPlayerManager, player: LgiPlayerctlPlayer)
local M

---@return LgiPlayerctlPlayerManager
function M.new()
end

---@param player LgiPlayerctlPlayer
function M:manage_player(player)
end

---@param sort_func fun(a: userdata, b: userdata): integer
function M:set_sort_func(sort_func)
end

---@param player LgiPlayerctlPlayer
function M:move_player_to_top(player)
end


---@class _LgiPlayerctlPlayerManager
---@operator call: LgiPlayerctlPlayerManager
local S

---@return LgiPlayerctlPlayerManager
function S.new()
end
