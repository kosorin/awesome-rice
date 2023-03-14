---@meta

---@class LgiGioFile
local M

---@param attributes string
---@param flags unknown
function M:async_enumerate_children(attributes, flags)
end

---@return string|nil
function M:get_path()
end

---@return string|nil
function M:get_uri()
end


---@class _LgiGioFile
local S

---@param path string
---@return LgiGioFile
function S.new_for_path(path)
end
