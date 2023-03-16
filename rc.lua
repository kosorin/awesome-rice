local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local fixed2 = require("wibox.layout.fixed_new")
local capi = {
    mousegrabber = mousegrabber,
}
local min, max = math.min, math.max

local resize_helper = {}

do
    local orientations = {
        horizontal = {
            position = "x",
            size = "width",
        },
        vertical = {
            position = "y",
            size = "height",
        },
    }

    function resize_helper.attach_slider_grabber(args)
        local calculate_value
        if args.minimum and args.maximum then
            assert(args.minimum < args.maximum)
            if args.raw then
                calculate_value = function(value)
                    return args.minimum + min(max(args.minimum, value), args.maximum)
                end
            else
                local size = args.maximum - args.minimum
                calculate_value = function(value)
                    return args.minimum + min(max(0, value * size), size)
                end
            end
        else
            calculate_value = function(value)
                return value
            end
        end

        local function callback(_, x, y, button, modifiers, geometry)
            if button ~= (args.button or 1) or capi.mousegrabber.isrunning() then
                return
            end

            if args.start and not args.start() then
                return
            end

            local orientation = assert(orientations[args.orientation or "horizontal"])

            local wibox_geometry = args.wibox and args.wibox:geometry()
            local wibox_position = wibox_geometry and wibox_geometry[orientation.position] or 0

            do
                local positions = { x = x, y = y }
                local position = positions[orientation.position]
                local size = args.raw and 1 or geometry[orientation.size]
                local value = calculate_value(position / size)
                if args.fix_value then
                    value = args.fix_value(value)
                end
                args.update(value)
            end

            capi.mousegrabber.run(function(grab)
                local position = grab[orientation.position] - geometry[orientation.position] - wibox_position
                local size = args.raw and 1 or geometry[orientation.size]
                local value = calculate_value(position / size)
                if args.fix_value then
                    value = args.fix_value(value)
                end

                if args.interrupt and args.interrupt(value) then
                    if args.finish then
                        args.finish(value, true)
                    end
                    return false
                end

                if grab.buttons[button] then
                    args.update(value)
                    return true
                else
                    if args.finish then
                        args.finish(value, false)
                    else
                        args.update(value, true)
                    end
                    return false
                end
            end, args.cursor or "sb_up_arrow")
        end

        args.widget:connect_signal("button::press", callback)

        return function()
            args.widget:disconnect_signal("button::press", callback)
        end
    end
end






local spacing = 20
local spacing_widget = wibox.widget {
    opacity = 0.5,
    color   = "#ff0000",
    shape   = gears.shape.losange,
    widget  = wibox.widget.separator,
} --[[{
    widget = wibox.widget.separator,
    orientation = "vertical",
    thickness = 4,
    color = "#d00",
}]]

local widgets = {}

for i = 1, 5 do
    widgets[#widgets + 1] = wibox.widget {
        widget = wibox.container.constraint,
        strategy = "min",
        width = 80,
        {
            widget = wibox.container.background,
            bg = "#080",
            fg = "#eee",
            border_width = 2,
            border_color = "#00c",
            shape = gears.shape.powerline,
            {
                widget = wibox.widget.textbox,
                text = string.format("( %d )", i),
            },
        },
    }
end

-- widgets[#widgets + 1] = wibox.widget {
--     widget = wibox.container.constraint,
--     strategy = "min",
--     width = 80,
--     {
--         {
--             max_value    = 1,
--             value        = 0.5,
--             paddings     = 1,
--             border_width = 1,
--             border_color = "#00c",
--             widget       = wibox.widget.progressbar,
--         },
--         {
--             text   = "50%",
--             valign = "center",
--             halign = "center",
--             widget = wibox.widget.textbox,
--         },
--         layout = wibox.layout.stack,
--     },
-- }

local function build(layout, y, ...)
    local popup = wibox {
        ontop = true,
        visible = true,
        x = 20,
        y = 20 + y,
        bg = "#022",
        width = 1500,
        height = 20,
        widget = wibox.widget {
            widget = wibox.container.margin,
            left = 100,
            {
                widget = wibox.container.place,
                halign = "left",
                {
                    widget = wibox.container.background,
                    bg = "#ffa",
                    {
                        id = "#container",
                        widget = wibox.container.constraint,
                        strategy = "max",
                        {
                            id = "#layout",
                            layout = layout,
                            spacing = spacing,
                            spacing_widget = spacing_widget,
                            spacing_widget_on_top = false,
                        },
                    },
                },
            },
        },
    }

    local result = {
        popup = popup,
        container = popup.widget:get_children_by_id("#container")[1],
        layout = popup.widget:get_children_by_id("#layout")[1],
    }

    if result.layout then
        if result.layout.add then
            result.layout:add(...)
        else
            result.layout:set_widget(...)
        end
    end

    return result
end

local foo = build(wibox.container.background, 20, wibox.widget {
    widget = wibox.container.background,
    bg = "#939",
    fg = "#fff",
    {
        widget = wibox.container.place,
        fill_horizontal = true,
        halign = "right",
        {
            widget = wibox.widget.textbox,
            text = " ",
        },
    },
})
local old = build(wibox.layout.fixed.horizontal, 0, table.unpack(widgets))
local new = build(fixed2.horizontal, 40, table.unpack(widgets))

local function update_info()
    foo.layout.widget.widget.widget.text = string.format("spacing: %.0f, width: %.0f", new.layout.spacing or 0, new.container.width or 0)
end

local function change_width(value, relative)
    local new_width = relative and foo.container.width + value or value
    if new_width < 1 then
        new_width = 1
    end
    foo.container.width = new_width
    old.container.width = new_width
    new.container.width = new_width
    update_info()
end

local function change_spacing(value, relative)
    local new_spacing = relative and new.layout.spacing + value or value
    old.layout.spacing = new_spacing
    new.layout.spacing = new_spacing
    update_info()
end

local menu

local buttons = {
    awful.button({}, 4, function() change_width(1, true) end),
    awful.button({}, 5, function() change_width(-1, true) end),
    awful.button({ "Control" }, 4, function() change_spacing(1, true) end),
    awful.button({ "Control" }, 5, function() change_spacing(-1, true) end),
    awful.button({}, 3, nil, function()
        if menu and menu.wibox.visible then
            menu:hide()
            return
        end
        local items = {
            { "fill space : " .. tostring(not not new.layout._private.fill_space), function()
                old.layout:fill_space(not old.layout._private.fill_space)
                new.layout:fill_space(not new.layout._private.fill_space)
            end, nil, },
            { "reverse (bottom only) : " .. tostring(not not new.layout._private.reverse), function()
                new.layout.reverse = not new.layout._private.reverse
            end, nil, },
            { "spacing widget on top (bottom only) : " .. tostring(not not new.layout._private.spacing_widget_on_top), function()
                new.layout.spacing_widget_on_top = not new.layout._private.spacing_widget_on_top
            end, nil, },
            { " ------ " },
        }

        for i = 1, #widgets do
            local w = widgets[i]
            items[#items + 1] = {
                tostring(i) .. " visible : " .. tostring(w.visible),
                function()
                    w.visible = not w.visible
                end,
                nil,
            }
        end
        menu = awful.menu({
            theme = {
                width = 250,
                border_width = 1,
                border_color = "#bbb",
                bg_normal = "#333",
                bg_focus = "#666",
            },
            auto_expand = true,
            items = items,
        })
        menu:show()
    end),
}

resize_helper.attach_slider_grabber {
    widget = foo.container,
    wibox = foo.popup,
    raw = true,
    minimum = 1,
    maximum = math.huge,
    update = function(value)
        change_width(value)
    end,
}

foo.popup.buttons = buttons
old.popup.buttons = buttons
new.popup.buttons = buttons

change_width(500)
