require("develop")

require("globals")

require("config")

require("theme.manager").load(require("theme.styles.default") --[[@as Theme]])

-- require("core")
-- require("services")
-- require("ui")

-- ---@diagnostic disable: param-type-mismatch
-- collectgarbage("setpause", 110)
-- collectgarbage("setstepmul", 1000)
-- ---@diagnostic enable: param-type-mismatch


local awful = require("awful")
local wibox = require("wibox")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local binding = require("io.binding")
local btn = binding.button
local mod = binding.modifier
local stylable = require("theme.stylable")
local manager = require("theme.manager")
local pango = require("utils.pango")
local uui = require("utils.ui")
local umouse = require("utils.mouse")


if true then
    local pbar = wibox.widget.progressbar()
    local popup = awful.popup {
        x = 50,
        y = 50,
        bg = "#333333",
        border_color = "#555555",
        border_width = 1,
        widget = {
            layout = wibox.container.constraint,
            width = 500,
            height = 500,
            {
                layout = wibox.container.margin,
                margins = 10,
                {
                    layout = wibox.layout.fixed.vertical,
                    spacing = 10,
                    {
                        widget = wibox.widget.textbox,
                        text = "foo bar",
                    },
                    {
                        forced_height = 50,
                        widget = pbar,
                        value = 5,
                        max_value = 12,
                    },
                    {
                        widget = wibox.widget.textbox,
                        text = "foo bar",
                    },
                    {
                        forced_height = 50,
                        widget = pbar,
                        class = "test",
                        value = 5,
                        max_value = 12,
                    },
                    {
                        widget = wibox.widget.textbox,
                        text = "foo bar",
                    },
                    {
                        forced_height = 50,
                        widget = pbar,
                        class = "test",
                        value = 5,
                        max_value = 12,
                        color = "#00ff00",
                    },
                    {
                        widget = wibox.widget.textbox,
                        text = "foo bar",
                    },
                    {
                        forced_height = 50,
                        widget = pbar,
                        class = "test powerline",
                        value = 5,
                        max_value = 12,
                    },
                },
            },
        },
    }
else
    local capsule = require("widget.capsule")
    local popup = require("widget.popup")
    local fixed = require("widget.fixed")
    local progressbar = require("widget.progressbar")

    local button = {}

    button.object = {}

    stylable.define {
        object = button.object,
        name = "button",
        properties = {
            icon = { id = "#icon", property = "image" },
            stylesheet = { id = "#icon", property = "stylesheet" },
            text = { id = "#text", property = "markup" },
        },
    }

    function button.new(args)
        args = args or {}

        local self = wibox.widget {
            widget = capsule,
            {
                layout = wibox.layout.fixed.horizontal,
                {
                    id = "#icon",
                    widget = wibox.widget.imagebox,
                    resize = true,
                },
                {
                    id = "#text",
                    widget = wibox.widget.textbox,
                },
            },
        } --[[@as Capsule]]

        gtable.crush(self, button.object, true)
        stylable.initialize(self)

        return self
    end

    setmetatable(button, { __call = function(_, ...) return button.new(...) end })

    ---@type Popup
    local main_popup

    main_popup = popup.new {
        show = true,
        widget = {
            layout = wibox.container.constraint,
            strategy = "exact",
            width = 800,
            height = 800,
            {
                layout = wibox.layout.align.vertical,
                expand = "inside",
                {
                    layout = wibox.layout.fixed.horizontal,
                    spacing = 10,
                    {
                        widget = button,
                        text = "Add item",
                        buttons = binding.awful_buttons {
                            binding.awful({}, btn.left, nil, function()
                                local item_container = main_popup:get_children_by_id("item_container")[1]
                                item_container:add(wibox.widget {
                                    widget = capsule,
                                    wibox.widget.textbox("foobar"),
                                })
                            end),
                        },
                    },
                    {
                        widget = button,
                        text = "Brake it",
                        buttons = binding.awful_buttons {
                            binding.awful({}, btn.left, nil, function()
                                for _, w in ipairs(main_popup:get_children_by_id("brake")) do
                                    w.widget = wibox.widget {
                                        widget = wibox.container.margin,
                                        margins = 4,
                                        w.widget,
                                    }
                                    -- pr(main_popup._private.wibox._drawable._widget_hierarchy, 0)
                                end
                            end),
                            binding.awful({}, btn.right, nil, function()
                                for _, w in ipairs(main_popup:get_children_by_id("brake")) do
                                    w.widget = w.widget.widget
                                    -- pr(main_popup._private.wibox._drawable._widget_hierarchy, 0)
                                end
                            end),
                        },
                    },
                    {
                        id = "toggle_button",
                        widget = button,
                        text = "Click me!",
                        buttons = binding.awful_buttons {
                            binding.awful({}, btn.left, nil, function()
                                local widget = main_popup:get_children_by_id("toggle_button")[1]
                                widget.checked = not widget.checked
                                widget.text = "Click me again"
                                widget.class = widget.checked and "foobar"
                            end),
                        },
                    },
                    {
                        widget = button,
                        text = "Tomorrow Night",
                        buttons = binding.awful_buttons {
                            binding.awful({}, btn.left, nil, function()
                                manager.load(require("theme.styles.tomorrow_night") --[[@as Theme]])
                            end),
                        },
                    },
                    {
                        widget = button,
                        text = "Gruvbox",
                        buttons = binding.awful_buttons {
                            binding.awful({}, btn.left, nil, function()
                                manager.load(require("theme.styles.gruvbox_dark") --[[@as Theme]])
                            end),
                        },
                    },
                },
                {
                    id = "item_container",
                    layout = fixed.vertical,
                    sid = "item_container",
                    spacing = 10,
                    {
                        id = "brake",
                        widget = capsule,
                        margins = { 0, top = 10 },
                        {
                            id = "child",
                            why = true,
                            widget = capsule,
                            margins = 20,
                            class = "child",
                            {
                                widget = wibox.widget.textbox,
                                text = "content",
                            },
                        },
                    },
                    {
                        id = "brake",
                        widget = capsule,
                        {
                            widget = capsule,
                            margins = 20,
                            {
                                widget = wibox.widget.textbox,
                                text = "content",
                            },
                        },
                    },
                    {
                        id = "brake",
                        widget = capsule,
                        {
                            widget = capsule,
                            margins = 20,
                            {
                                widget = wibox.widget.textbox,
                                text = "content",
                            },
                            {
                                id = "#pb",
                                widget = progressbar,
                                max_value = 100,
                            },
                        },
                    },
                    {
                        id = "brake",
                        widget = capsule,
                        class = "descendant",
                        {
                            widget = capsule,
                            margins = 20,
                            {
                                widget = wibox.widget.textbox,
                                text = "content",
                            },
                            {
                                id = "#pb",
                                widget = progressbar,
                                max_value = 100,
                            },
                        },
                    },
                },
            },
        },
    }

    for _, pb in ipairs(main_popup:get_children_by_id("#pb")) do
        umouse.attach_slider {
            widget = pb,
            wibox = main_popup._private.wibox,
            minimum = 0,
            maximum = 100,
            update = function(value)
                pb.value = value
            end,
        }
    end
end
