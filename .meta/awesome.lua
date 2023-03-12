---@meta

---@alias thickness { top: number, right: number, bottom: number, left: number }
---@alias geometry { x: number, y: number, width: number, height: number }
---@alias point { x: number, y: number }
---@alias size { width: number, height: number }
---@alias sign -1|0|1
---@alias direction "up"|"right"|"bottom"|"left"
---@alias orientation "vertical"|"horizontal"

---@alias screen integer|awful.screen

---@alias widget_template table
---@alias widget_value wibox.widget|widget_template|function

---@alias placement fun(drawable, args?: table)
