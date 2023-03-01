local capi = Capi
local pairs = pairs
local ipairs = ipairs
local table = table
local awful = require("awful")
local beautiful = require("theme.theme")
local gtable = require("gears.table")
local gfilesystem = require("gears.filesystem")
local desktop_utils = require("utils.desktop")
local mebox = require("widget.mebox")
local hstring = require("helpers.string")
local config = require("config")
local dpi = Dpi


local application_menu_template = { mt = { __index = {} } }

local root_menu

local function build_categories(category_factory)
    local categories = {}
    local category_map = {}

    for _, menu_category in pairs(beautiful.application_menu_categories) do
        local category = category_factory(menu_category)
        categories[#categories + 1] = category
        category_map[menu_category.id] = category_map[menu_category.id]
            or (menu_category.enabled ~= false and category)
    end

    local function category_mapper(desktop_file)
        if desktop_file.Categories then
            for _, category_id in pairs(desktop_file.Categories) do
                local category = category_map[category_id]
                if category then
                    return category
                end
            end
        end
    end

    return categories, category_mapper
end

local function generate_menu(desktop_files)
    desktop_files = desktop_files or desktop_utils.desktop_files or {}

    local categories, category_mapper = build_categories(function(menu_category)
        return {
            text = menu_category.name,
            icon = desktop_utils.lookup_icon(menu_category.icon_name),
            icon_color = menu_category.icon_color,
            submenu = {},
        }
    end)

    local fallback_category = {
        text = "other",
        submenu = {},
    }

    for _, desktop_file in pairs(desktop_files) do
        local category = category_mapper(desktop_file) or fallback_category
        table.insert(category.submenu, {
            flex = true,
            text = hstring.trim(desktop_file.Name) or "",
            icon = desktop_file.icon_path,
            icon_color = false,
            callback = function()
                awful.spawn(hstring.trim(desktop_file.command) or "")
            end,
        })
    end

    table.sort(categories, function(a, b)
        local sma = a.submenu and 0 or 1
        local smb = b.submenu and 0 or 1
        if sma ~= smb then
            return sma < smb
        else
            return a.text < b.text
        end
    end)
    if #fallback_category.submenu > 0 then
        table.insert(categories, fallback_category)
    end
    for _, category in ipairs(categories) do
        if category.submenu then
            table.sort(category.submenu, function(a, b) return a.text < b.text end)
        end
    end

    root_menu = {
        item_width = dpi(200),
        items_source = categories,
    }

    table.insert(root_menu.items_source, mebox.separator)
    table.insert(root_menu.items_source, {
        text = "reload",
        icon = config.places.theme .. "/icons/refresh.svg",
        icon_color = beautiful.palette.gray,
        callback = function() desktop_utils.load_desktop_files() end,
    })
end

capi.awesome.connect_signal("desktop::files", function(desktop_files)
    generate_menu(desktop_files)
end)

generate_menu()

function application_menu_template.mt.__index.shared()
    return root_menu or {}
end

return setmetatable(application_menu_template, application_menu_template.mt)
