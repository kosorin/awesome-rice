local type = type
local pairs = pairs
local ipairs = ipairs
local gstring = require("gears.string")


local pango = {}

pango.thin_space = [[<span size="xx-small"> </span>]]

---Convert lua table to pango "span".
---@param data table|string
---@param separator? string # Value separator.
---@return string
---
---**Example 1:**
---
---    local markup = pango.span {
---        fgcolor = "#ff0000",
---        size = "small",
---        "content",
---    }
---    -- <span fgcolor='#ff0000' size='small'>content</span>
---
---**Example 2:**
---
---    local markup = pango.span({
---        weight = "light",
---        "a",
---        tostring(23),
---        pango.big("X"),
---    }, " / ")
---    -- <span weight='light'>a / 23 / <big>X</big></span>
---
function pango.span(data, separator)
    if type(data) == "table" then
        separator = separator or ""

        local t = ""
        for _, v in ipairs(data) do
            t = t .. separator .. v
        end

        local s = "<span "
        for k, v in pairs(data) do
            if type(k) ~= "number" then
                s = s .. k .. "='" .. v .. "' "
            end
        end
        return s .. ">" .. t .. "</span>"
    elseif type(data) == "string" then
        return data
    end
    return ""
end

---@param data string
---@return string
function pango.escape(data)
    return gstring.xml_escape(data)
end

---@param data string
---@return string
function pango.b(data)
    return "<b>" .. data .. "</b>"
end

---@param data string
---@return string
function pango.big(data)
    return "<big>" .. data .. "</big>"
end

---@param data string
---@return string
function pango.i(data)
    return "<i>" .. data .. "</i>"
end

---@param data string
---@return string
function pango.s(data)
    return "<s>" .. data .. "</s>"
end

---@param data string
---@return string
function pango.sub(data)
    return "<sub>" .. data .. "</sub>"
end

---@param data string
---@return string
function pango.sup(data)
    return "<sup>" .. data .. "</sup>"
end

---@param data string
---@return string
function pango.small(data)
    return "<small>" .. data .. "</small>"
end

---@param data string
---@return string
function pango.tt(data)
    return "<tt>" .. data .. "</tt>"
end

---@param data string
---@return string
function pango.u(data)
    return "<u>" .. data .. "</u>"
end

return pango
