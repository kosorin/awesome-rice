local capi = {
    screen = screen,
    awesome = awesome,
    client = client,
    button = button,
}
local setmetatable = setmetatable
local pairs = pairs
local ipairs = ipairs
local table = table
local atag = require("awful.tag")
local fixed = require("wibox.layout.fixed")
local gtimer = require("gears.timer")
local gstring = require("gears.string")
local base = require("wibox.widget.base")
local gtable = require("gears.table")
local noice = require("theme.manager")
local stylable = require("theme.stylable")
local Nil = require("theme.nil")

local function get_screen(s)
    return s and capi.screen[s]
end


local taglist = { mt = {} }


taglist.filter = {}

function taglist.filter.noempty(t)
    return #t:clients() > 0 or t.selected
end

function taglist.filter.selected(t)
    return t.selected
end

function taglist.filter.all()
    return true
end


taglist.source = {}

function taglist.source.for_screen(s)
    return s.tags
end


taglist.object = {}

noice.register_element(taglist.object, "taglist", "widget", {})


function _create_buttons(buttons, object)
    local is_formatted = buttons and buttons[1] and (type(buttons[1]) == "button" or buttons[1]._is_capi_button)

    if buttons then
        local btns = {}
        for _, src in ipairs(buttons) do
            --TODO v6 Remove this legacy overhead
            for _, b in ipairs(is_formatted and { src } or src) do
                -- Create a proxy button object: it will receive the real
                -- press and release events, and will propagate them to the
                -- button object the user provided, but with the object as
                -- argument.
                local btn = capi.button { modifiers = b.modifiers, button = b.button }
                btn:connect_signal("press", function() b:emit_signal("press", object) end)
                btn:connect_signal("release", function() b:emit_signal("release", object) end)
                btns[#btns + 1] = btn
            end
        end

        return btns
    end
end

function default_update_function(self, tags)
    local layout = self._private.base_layout
    local data = self._private.data
    local buttons = self._private.buttons

    layout:reset()
    for _, tag in ipairs(tags) do
        local item = data[tag]
        if item and item.buttons ~= buttons then
            item = nil
        end

        ---@type wibox.widget.base
        local widget
        if item then
            widget = item.widget
        else
            widget = assert(base.make_widget_from_value(self._private.widget_template))
            widget.buttons = { _create_buttons(buttons, tag) }

            item = {
                buttons = buttons,
                widget = widget,
            }
            data[tag] = item
        end

        local text_widget = widget:get_children_by_id("text")[1] --[[@as wibox.widget.textbox]]
        if text_widget then
            if not text_widget:set_markup_silently(gstring.xml_escape(tag.name) or "") then
                text_widget:set_markup("?")
            end
        end

        widget:change_state("empty", #tag:clients() == 0)
        widget:change_state("selected", tag.selected)
        widget:change_state("volatile", tag.volatile)
        widget:change_state("urgent", tag.urgent)

        layout:add(item.widget)
    end
end

---@private
function taglist.object:_update_now()
    if self._private.screen.valid then
        local tags = {}

        local source_tags = self._private.source(self._private.screen) or self._private.screen.tags
        for _, t in ipairs(source_tags) do
            if self._private.filter(t) then
                table.insert(tags, t)
            end
        end

        local tag_count = #tags
        if self._private.last_count ~= tag_count then
            self:emit_signal("property::count", tag_count, self._private.last_count)
            self._private.last_count = tag_count
        end

        self._private.update_function(self, tags)
    end
    self._private.queued_update = false
end

---@private
function taglist.object:_update()
    -- Add a delayed callback for the first update.
    if not self._private.queued_update then
        self._private.queued_update = true
        gtimer.delayed_call(function()
            self:_update_now()
        end)
    end
end


function taglist.object:set_base_layout(layout)
    self._private.base_layout = assert(base.make_widget_from_value(layout or fixed.horizontal))

    self:_update()

    self:emit_signal("widget::layout_changed")
    self:emit_signal("widget::redraw_needed")
    self:emit_signal("property::base_layout", layout)
end

function taglist.object:get_count()
    if not self._private.last_count then
        self:_update_now()
    end
    return self._private.last_count
end

function taglist.object:layout(_, width, height)
    if self._private.base_layout then
        return { base.place_widget_at(self._private.base_layout, 0, 0, width, height) }
    end
end

function taglist.object:fit(context, width, height)
    if not self._private.base_layout then
        return 0, 0
    end
    return base.fit_widget(self, context, self._private.base_layout, width, height)
end

for _, property in ipairs { "screen", "filter", "source", "update_function", "widget_template" } do
    taglist.object["set_" .. property] = function(self, value)
        if self._private[property] == value then
            return
        end
        self._private[property] = value

        self:_update()

        self:emit_signal("widget::layout_changed")
        self:emit_signal("widget::redraw_needed")
        self:emit_signal("property::" .. property, value)
    end
    taglist.object["get_" .. property] = function(self)
        return self._private[property]
    end
end

local all_instances = nil

local function get_instances_for_screen(screen)
    if all_instances == nil then
        all_instances = setmetatable({}, { __mode = "k" })
        local function update(s)
            local screen_instances = all_instances[get_screen(s)]
            if screen_instances then
                for instance in pairs(screen_instances) do
                    instance:_update()
                end
            else
                -- No screen? Update all taglists
                for _, instances in pairs(all_instances) do
                    for instance in pairs(instances) do
                        instance:_update()
                    end
                end
            end
        end
        local client_update = function(c) return update(c.screen) end
        local tag_update = function(t) return update(t.screen) end
        capi.client.connect_signal("property::active", client_update)
        atag.attached_connect_signal(nil, "property::selected", tag_update)
        atag.attached_connect_signal(nil, "property::icon", tag_update)
        atag.attached_connect_signal(nil, "property::hide", tag_update)
        atag.attached_connect_signal(nil, "property::name", tag_update)
        atag.attached_connect_signal(nil, "property::activated", tag_update)
        atag.attached_connect_signal(nil, "property::screen", tag_update)
        atag.attached_connect_signal(nil, "property::index", tag_update)
        atag.attached_connect_signal(nil, "property::urgent", tag_update)
        atag.attached_connect_signal(nil, "property::volatile", tag_update)
        capi.client.connect_signal("property::screen", function(c, old_screen)
            update(c.screen)
            update(old_screen)
        end)
        capi.client.connect_signal("tagged", client_update)
        capi.client.connect_signal("untagged", client_update)
        capi.client.connect_signal("request::unmanage", client_update)
        capi.screen.connect_signal("removed", function(s)
            all_instances[get_screen(s)] = nil
        end)
    end

    local screen_instances = all_instances[screen]
    if not screen_instances then
        screen_instances = setmetatable({}, { __mode = "k" })
        all_instances[screen] = screen_instances
    end
    return screen_instances
end

local function add_instance(self)
    get_instances_for_screen(self._private.screen)[self] = true
end

function taglist.new(args)
    local screen = get_screen(args.screen)

    local self = base.make_widget(nil, nil, { enable_properties = true })

    gtable.crush(self, taglist.object, true)
    stylable.initialize(self, taglist.object)

    gtable.crush(self._private, {
        screen = screen,
        buttons = args.buttons,
        filter = args.filter or taglist.filter.all,
        source = args.source or taglist.source.for_screen,
        update_function = args.update_function or default_update_function,
        widget_template = args.widget_template,
        queued_update = false,
        data = setmetatable({}, { __mode = "k" }),
    })

    self:set_base_layout(args.base_layout)

    self:_update()

    add_instance(self)

    return self
end

function taglist.mt:__call(...)
    return taglist.new(...)
end

return setmetatable(taglist, taglist.mt)
