local capi = Capi
local ipairs = ipairs
local format = string.format
local awful = require("awful")
local common = require("awful.widget.common")
local base = require("wibox.widget.base")
local wibox = require("wibox")
local beautiful = require("theme.theme")
local tcolor = require("utils.color")
local config = require("config")
local binding = require("core.binding")
local mod = binding.modifier
local btn = binding.button
local dpi = Dpi
local capsule = require("widget.capsule")
local gtable = require("gears.table")
local gcolor = require("gears.color")
local core_tag = require("core.tag")
local mebox = require("widget.mebox")
local tag_menu_template = require("ui.menu.templates.tag.main")
local aplacement = require("awful.placement")
local widget_helper = require("core.widget")
local screen_helper = require("core.screen")
local pango = require("utils.pango")
local css = require("utils.css")
local hui = require("utils.thickness")


local taglist = { mt = {} }

function taglist:rename_tag_inline(tag)
    if not tag or not tag.activated then
        return
    end
    local item = self._private.cache and self._private.cache[tag]
    local textbox = item and item.text
    if textbox then
        local old_name = tag.name
        local new_name = nil
        capi.mousegrabber.run(function() return true end, nil)
        awful.prompt.run {
            text = old_name,
            bg_cursor = beautiful.taglist.rename.bg,
            fg_cursor = beautiful.taglist.rename.fg,
            ul_cursor = "none",
            selectall = true,
            textbox = textbox,
            exe_callback = function(value)
                new_name = value
            end,
            done_callback = function()
                local name = new_name or old_name or ""
                if name:match("^%s*$") then
                    name = tostring(tag.index)
                end
                if not name:match("^%d") then
                    name = format("%d:%s", tag.index, name)
                end
                textbox:set_text(name)
                tag.name = name
                capi.mousegrabber.stop()
            end,
        }
    end
end

function taglist:show_tag_menu(tag)
    if not tag or not tag.activated then
        return
    end
    local item = self._private.cache and self._private.cache[tag]
    local container = item and item.container
    if container then
        local menu = self._private.menu
        if not menu then
            menu = mebox(tag_menu_template.shared)
            self._private.menu = menu
        end
        local old_tag = menu.tag
        menu:hide()
        if old_tag ~= tag then
            menu:show {
                taglist = self,
                tag = tag,
                placement = beautiful.wibar.build_placement(container, self._private.wibar),
            }
        end
    end
end

function taglist.new(wibar)
    local plus_button_initialized
    local self
    self = awful.widget.taglist {
        screen = wibar.screen,
        filter = awful.widget.taglist.filter.all,
        update_function = function(layout, buttons, label, cache, tags, args)
            if not self._private.cache or self._private.cache ~= cache then
                self._private.cache = cache
            end

            local root_container = layout.widget.children[1]

            if not plus_button_initialized then
                plus_button_initialized = true

                local plus_button = layout.widget.children[2]
                local plus_button_icon = layout:get_children_by_id("#icon")[1]
                plus_button_icon:set_stylesheet(css.style { path = { fill = gcolor.ensure_pango_color(plus_button.fg) } })
            end

            root_container:reset()
            for index, tag in ipairs(tags) do
                local item = cache[tag]
                if item and item.buttons ~= buttons then
                    item = nil
                end

                if not item then
                    local root = base.make_widget_from_value(args.widget_template)
                    root.buttons = { common.create_buttons(buttons, tag) }
                    root:connect_signal("mouse::enter", function()
                        local menu = self._private.menu
                        if menu and menu.visible and menu.tag ~= tag then
                            self:show_tag_menu(tag)
                        end
                    end)

                    item = {
                        buttons = buttons,
                        root = root,
                        container = root:get_children_by_id("#container")[1],
                        text = root:get_children_by_id("#text")[1],
                    }
                    cache[tag] = item

                    if args and args.create_callback then
                        args.create_callback(item.root, tag, index, tags)
                    end
                else
                    if args and args.update_callback then
                        args.update_callback(item.root, tag, index, tags)
                    end
                end

                local text, bg, _, _, item_args = label(tag, item.text)
                text = text or ""
                item_args = item_args or {}

                if item.container then
                    item.container.bg = bg
                    item.container.border_width = item_args.shape_border_width
                    item.container.border_color = item_args.shape_border_color
                end

                if item.text then
                    if not item.text:set_markup_silently(text) then
                        item.text:set_markup(pango.i(pango.escape("<invalid>")))
                    end
                end

                root_container:add(item.root)
            end
        end,
        buttons = binding.awful_buttons {
            binding.awful({}, btn.left, function(_, tag)
                tag:view_only()
            end),
            binding.awful({}, btn.right, function(_, tag)
                self:show_tag_menu(tag)
            end),
            binding.awful({}, btn.middle, function(_, tag)
                awful.tag.viewtoggle(tag)
            end),
            binding.awful({ mod.super }, btn.left, function(_, tag)
                screen_helper.clients_to_tag(self.screen, tag)
            end),
            binding.awful({}, {
                { trigger = btn.wheel_up, action = awful.tag.viewprev },
                { trigger = btn.wheel_down, action = awful.tag.viewnext },
            }, function(trigger)
                trigger.action(self.screen)
            end),
        },
        layout = {
            layout = wibox.container.margin,
            left = -beautiful.wibar.spacing / 2,
            right = -beautiful.wibar.spacing / 2,
            {
                layout = wibox.layout.fixed.horizontal,
                {
                    layout = wibox.layout.fixed.horizontal,
                },
                {
                    widget = capsule,
                    margins = hui.thickness {
                        beautiful.wibar.paddings.top,
                        beautiful.wibar.spacing / 2,
                        beautiful.wibar.paddings.bottom,
                    },
                    paddings = hui.thickness { dpi(6) },
                    bg = tcolor.transparent,
                    fg = beautiful.capsule.styles.disabled.fg,
                    border_width = 0,
                    buttons = binding.awful_buttons {
                        binding.awful({}, btn.left, function()
                            core_tag.add { screen = wibar.screen, volatile = true }:view_only()
                        end),
                        binding.awful({}, btn.middle, function()
                            core_tag.add { screen = wibar.screen, volatile = true }
                        end),
                    },
                    {
                        id = "#icon",
                        widget = wibox.widget.imagebox,
                        image = config.places.theme .. "/icons/plus.svg",
                        resize = true,
                    },
                },
            },
        },
        widget_template = {
            id = "#container",
            widget = capsule,
            margins = hui.thickness {
                beautiful.wibar.paddings.top,
                beautiful.wibar.spacing / 2,
                beautiful.wibar.paddings.bottom,
            },
            {
                id = "#text",
                widget = wibox.widget.textbox,
            },
        },
    }

    gtable.crush(self, taglist, true)

    self._private.wibar = wibar

    return self
end

function taglist.mt:__call(...)
    return taglist.new(...)
end

return setmetatable(taglist, taglist.mt)
