local ipairs = ipairs
local wibox = require("wibox")
local beautiful = require("theme.theme")
local dpi = Dpi
local mebox = require("widget.mebox")
local binding = require("io.binding")
local mod = binding.modifier
local btn = binding.button
local gtable = require("gears.table")
local pango = require("utils.pango")
local umath = require("utils.math")
local config = require("config")


local function on_hide(menu)
    menu.client = nil
end

local function on_show(menu, args)
    local parent = menu._private.parent
    menu.client = parent and parent.client or args.client

    if not menu.client or not menu.client.valid then
        on_hide(menu)
        return false
    end

    local client = menu.client

    local function unmanage()
        client:disconnect_signal("request::unmanage", unmanage)
        menu:hide()
    end

    client:connect_signal("request::unmanage", unmanage)
end

local opacity_menu_template = { mt = { __index = {} } }

function opacity_menu_template.new()
    local value_widget
    local step = 0.05
    local min_opacity = 0
    local max_opacity = 1

    local function update_opacity_text(opacity)
        if not value_widget then
            return
        end
        opacity = tonumber(opacity)
        local text = opacity
            and tostring(umath.round(opacity * 100))
            or "--"
        value_widget:set_markup(text .. pango.thin_space .. "%")
    end

    local function change_opacity(menu, value)
        menu.client.opacity = umath.clamp(menu.client.opacity + value, min_opacity, max_opacity)
        update_opacity_text(menu.client.opacity)
    end

    local function set_opacity(menu, value)
        menu.client.opacity = value or max_opacity
        update_opacity_text(menu.client.opacity)
    end

    return {
        item_width = beautiful.mebox.default_style.item_height,
        on_show = on_show,
        on_hide = on_hide,
        orientation = "horizontal",
        layout_navigator = function(menu, x, y, direction, context)
            if y ~= 0 then
                change_opacity(menu, -y * step)
                return
            end
            mebox.layout_navigators.direction(menu, x, y, direction, context)
        end,
        {
            icon = config.places.theme .. "/icons/minus.svg",
            icon_color = beautiful.palette.white,
            callback = function(item, menu)
                change_opacity(menu, -step)
                return false
            end,
        },
        {
            enabled = false,
            buttons_builder = function(_, menu)
                return binding.awful_buttons {
                    binding.awful({}, binding.group.mouse_wheel, function(trigger)
                        change_opacity(menu, trigger.y * step)
                    end),
                }
            end,
            template = {
                widget = wibox.widget.textbox,
                forced_width = dpi(64),
                halign = "center",
                update_callback = function(_, _, menu)
                    update_opacity_text(menu.client.opacity)
                end,
            },
            on_ready = function(item_widget)
                value_widget = item_widget
            end,
        },
        {
            icon = config.places.theme .. "/icons/plus.svg",
            icon_color = beautiful.palette.white,
            callback = function(item, menu)
                change_opacity(menu, step)
                return false
            end,
        },
        mebox.separator,
        {
            width = dpi(100),
            text = "reset",
            icon = config.places.theme .. "/icons/arrow-u-left-top.svg",
            icon_color = beautiful.palette.gray,
            callback = function(item, menu)
                set_opacity(menu, max_opacity)
            end,
        },
    }
end

opacity_menu_template.mt.__index.shared = opacity_menu_template.new()

setmetatable(opacity_menu_template, opacity_menu_template.mt)


local client_menu_template = { mt = { __index = {} } }

local function build_simple_toggle(name, property, checkbox_type, icon, icon_color)
    return {
        text = name,
        checkbox_type = checkbox_type,
        icon = icon and (config.places.theme .. icon) or nil,
        icon_color = icon_color,
        on_show = function(item, menu) item.checked = not not menu.client[property] end,
        callback = function(item, menu) menu.client[property] = not item.checked end,
    }
end

-- TODO:
-- - toggle titlebar
function client_menu_template.new()
    ---@type Mebox.new.args
    return {
        item_width = dpi(184),
        on_show = on_show,
        on_hide = on_hide,
        {
            text = "tags",
            icon = config.places.theme .. "/icons/tag-multiple.svg",
            icon_color = beautiful.palette.green,
            ---@type Mebox.new.args
            submenu = {
                item_width = dpi(150),
                on_show = on_show,
                on_hide = on_hide,
                items_source = function(menu)
                    local client = menu.client --[[@as client|nil]]
                    if not client then
                        return {}
                    end

                    local tags = client:tags()
                    local screen_tags = client.screen.tags

                    ---@type MeboxItem.submenu[]
                    local items = { build_simple_toggle("sticky", "sticky", nil, "/icons/pin.svg", beautiful.palette.white) }
                    if #screen_tags > 0 then
                        items[#items + 1] = mebox.separator
                        for _, tag in ipairs(screen_tags) do
                            items[#items + 1] = {
                                enabled = false,
                                text = tag.name,
                                icon = config.places.theme .. "/icons/tag.svg",
                                icon_color = beautiful.palette.white,
                                on_show = function(item) item.checked = not not gtable.hasitem(tags, tag) end,
                            }
                        end
                    end
                    return items
                end,
            },
        },
        mebox.separator,
        build_simple_toggle("minimize", "minimized", nil, "/icons/window-minimize.svg", beautiful.palette.white),
        build_simple_toggle("maximize", "maximized", nil, "/icons/window-maximize.svg", beautiful.palette.white),
        build_simple_toggle("fullscreen", "fullscreen", nil, "/icons/fullscreen.svg", beautiful.palette.white),
        mebox.separator,
        build_simple_toggle("on top", "ontop", nil, "/icons/chevron-double-up.svg", beautiful.palette.white),
        build_simple_toggle("floating", "floating", nil, "/icons/arrange-bring-forward.svg", beautiful.palette.white),
        mebox.separator,
        {
            text = "opacity",
            icon = config.places.theme .. "/icons/circle-opacity.svg",
            icon_color = beautiful.palette.cyan,
            submenu = opacity_menu_template.shared,
        },
        mebox.separator,
        {
            text = "more",
            icon = config.places.theme .. "/icons/cogs.svg",
            icon_color = beautiful.palette.blue,
            submenu = {
                item_width = dpi(184),
                on_show = on_show,
                on_hide = on_hide,
                mebox.header("layer"),
                build_simple_toggle("top", "ontop", "radiobox", "/icons/chevron-double-up.svg", beautiful.palette.white),
                build_simple_toggle("above", "above", "radiobox", "/icons/chevron-up.svg", beautiful.palette.white),
                {
                    text = "normal",
                    checkbox_type = "radiobox",
                    icon = config.places.theme .. "/icons/unfold-less-vertical.svg",
                    icon_color = beautiful.palette.white,
                    on_show = function(item, menu)
                        item.checked = not (menu.client.ontop or menu.client.above or menu.client.below)
                    end,
                    callback = function(item, menu)
                        menu.client.ontop = false
                        menu.client.above = false
                        menu.client.below = false
                    end,
                },
                build_simple_toggle("below", "below", "radiobox", "/icons/chevron-down.svg", beautiful.palette.white),
                mebox.separator,
                build_simple_toggle("dockable", "dockable", nil, "/icons/dock-left.svg", beautiful.palette.white),
                build_simple_toggle("focusable", "focusable", nil, "/icons/image-filter-center-focus.svg", beautiful.palette.white),
                build_simple_toggle("size hints", "size_hints_honor", nil, "/icons/move-resize.svg", beautiful.palette.white),
                mebox.separator,
                {
                    text = "hide",
                    icon = config.places.theme .. "/icons/eye-off.svg",
                    icon_color = beautiful.palette.gray,
                    callback = function(item, menu) menu.client.hidden = true end,
                },
            },
        },
        mebox.separator,
        {
            text = "quit",
            icon = config.places.theme .. "/icons/close.svg",
            icon_color = beautiful.palette.red,
            callback = function(item, menu) menu.client:kill() end,
        },
    }
end

client_menu_template.mt.__index.shared = client_menu_template.new()

return setmetatable(client_menu_template, client_menu_template.mt)
