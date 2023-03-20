local pairs = pairs
local tostring = tostring
local format = string.format


local css = {}

---Convert lua table to css styles.
---@param rules table
---@return string
---
---**Example:**
---
---    local style = css.style {
---        path = {
---            stroke = "#ff0000",
---            ["stroke-width"] = 5,
---        },
---        [".foobar::before"] = {
---            content = "\"lorem ipsum\"",
---        },
---    }
---    -- path { stroke: #ff0000; stroke-width: 5; } .foobar::before { content: "lorem ipsum"; }
---
function css.style(rules)
    local result = ""
    for selector, declarations in pairs(rules) do
        result = format("%s %s {", result, selector)
        for property, value in pairs(declarations) do
            result = format("%s %s: %s;", result, property, tostring(value))
        end
        result = format("%s } ", result)
    end
    return result
end

return css
