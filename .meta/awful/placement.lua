---@meta awful.placement

---@alias placement fun(drawable, args?: table)

---@alias corner "top_left"|"top_right"|"bottom_left"|"bottom_right"|"top"|"right"|"bottom"|"left"
---@alias position "top"|"right"|"bottom"|"left"
---@alias anchor "fron"|"middle"|"back"


---@class _awful.placement
local S

---Restore the geometry.
---@param drawable unknown
---@param args? table
---@return boolean
function S.restore(drawable, args)
end

---Move a drawable to the closest corner of the parent geometry (such as the screen).
---@param drawable unknown
---@param args? table
---@return geometry, corner
function S.closest_corner(drawable, args)
end

---Place the client so no part of it will be outside the screen (workarea).
---@param client unknown
---@param args? table
---@return geometry
function S.no_offscreen(client, args)
end

---Place the client where there's place available with minimum overlap.
---@param client unknown
---@param args? table
---@return geometry
function S.no_overlap(client, args)
end

---Place the client under the mouse.
---@param drawable unknown
---@param args? table
---@return geometry
function S.under_mouse(drawable, args)
end

---Place the client next to the mouse.
---@param drawable unknown
---@param args? table
---@return geometry
function S.next_to_mouse(drawable, args)
end

---Resize the drawable to the cursor.
---@param drawable unknown
---@param args? table
---@return geometry
function S.resize_to_mouse(drawable, args)
end

---Move the drawable (client or wibox) d to a screen position or side.
---@param drawable unknown
---@param args? table
---@return geometry
function S.align(drawable, args)
end

---Align a client to the top left of the parent area.
---@param drawable unknown
---@param args? table
---@return geometry
function S.top_left(drawable, args)
end

---Align a client to the top right of the parent area.
---@param drawable unknown
---@param args? table
---@return geometry
function S.top_right(drawable, args)
end

---Align a client to the bottom left of the parent area.
---@param drawable unknown
---@param args? table
---@return geometry
function S.bottom_left(drawable, args)
end

---Align a client to the bottom right of the parent area.
---@param drawable unknown
---@param args? table
---@return geometry
function S.bottom_right(drawable, args)
end

---Align a client to the left of the parent area.
---@param drawable unknown
---@param args? table
---@return geometry
function S.left(drawable, args)
end

---Align a client to the right of the parent area.
---@param drawable unknown
---@param args? table
---@return geometry
function S.right(drawable, args)
end

---Align a client to the top of the parent area.
---@param drawable unknown
---@param args? table
---@return geometry
function S.top(drawable, args)
end

---Align a client to the bottom of the parent area.
---@param drawable unknown
---@param args? table
---@return geometry
function S.bottom(drawable, args)
end

---Align a client to the center of the parent area.
---@param drawable unknown
---@param args? table
---@return geometry
function S.centered(drawable, args)
end

---Align a client to the vertical center of the parent area.
---@param drawable unknown
---@param args? table
---@return geometry
function S.center_vertical(drawable, args)
end

---Align a client to the horizontal center left of the parent area.
---@param drawable unknown
---@param args? table
---@return geometry
function S.center_horizontal(drawable, args)
end

---Stretch a drawable in a specific direction.
---@param drawable unknown
---@param args? table
---@return geometry
function S.stretch(drawable, args)
end

---Stretch the drawable to the left of the parent area.
---@param drawable unknown
---@param args? table
---@return geometry
function S.stretch_left(drawable, args)
end

---Stretch the drawable to the right of the parent area.
---@param drawable unknown
---@param args? table
---@return geometry
function S.stretch_right(drawable, args)
end

---Stretch the drawable to the top of the parent area.
---@param drawable unknown
---@param args? table
---@return geometry
function S.stretch_up(drawable, args)
end

---Stretch the drawable to the bottom of the parent area.
---@param drawable unknown
---@param args? table
---@return geometry
function S.stretch_down(drawable, args)
end

---Maximize a drawable horizontally, vertically or both.
---@param drawable unknown
---@param args? table
---@return geometry
function S.maximize(drawable, args)
end

---Vetically maximize the drawable in the parent area.
---@param drawable unknown
---@param args? table
---@return geometry
function S.maximize_vertically(drawable, args)
end

---Horizontally maximize the drawable in the parent area.
---@param drawable unknown
---@param args? table
---@return geometry
function S.maximize_horizontally(drawable, args)
end

---Scale the drawable by either a relative or absolute percent.
---@param drawable unknown
---@param args? table
---@return geometry
function S.scale(drawable, args)
end

---Move a drawable to a relative position next to another one.
---@param drawable unknown
---@param args? table
---@return geometry, position, anchor
function S.next_to(drawable, args)
end

---Skip all preceding results of placement pipeline for fullscreen clients.
---@param drawable unknown
---@param args? table
---@return geometry
function S.skip_fullscreen(drawable, args)
end

---@param drawable unknown
---@param args? table
---@return geometry
function S.next_to_widget(drawable, args)
end

return S
