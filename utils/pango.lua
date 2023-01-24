local type = type


local pango = {}

pango.thin_space = [[<span size="xx-small"> </span>]]

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

function pango.b(data)
    return "<b>" .. data .. "</b>"
end

function pango.big(data)
    return "<big>" .. data .. "</big>"
end

function pango.i(data)
    return "<i>" .. data .. "</i>"
end

function pango.s(data)
    return "<s>" .. data .. "</s>"
end

function pango.sub(data)
    return "<sub>" .. data .. "</sub>"
end

function pango.sup(data)
    return "<sup>" .. data .. "</sup>"
end

function pango.small(data)
    return "<small>" .. data .. "</small>"
end

function pango.tt(data)
    return "<tt>" .. data .. "</tt>"
end

function pango.u(data)
    return "<u>" .. data .. "</u>"
end

return pango
