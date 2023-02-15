local format = string.format


local css = {}

function css.style(rules)
    local result = ""
    for selector, declarations in pairs(rules) do
        result = format("%s %s { ", result, selector)
        for property, value in pairs(declarations) do
            result = format("%s %s: %s; ", result, property, tostring(value))
        end
        result = format("%s} ", result)
    end
    return result
end

return css
