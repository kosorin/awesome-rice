local capi = Capi
local pairs = pairs
local ipairs = ipairs
local table = table
local awful = require("awful")
local beautiful = require("theme.theme")
local gtable = require("gears.table")
local gfilesystem = require("gears.filesystem")
local desktop_utils = require("services.desktop")
local mebox = require("widget.mebox")
local hstring = require("utils.string")
local config = require("config")
local dpi = Dpi


local M = {}

local root_menu

local function create_category_manager(category_builder)
    local categories = {}
    local category_map = {}
    local fallback_category = category_builder(beautiful.application.fallback_category, true)
    local fallback_category_map = {}

    for _, menu_category in pairs(beautiful.application.categories) do
        local category = category_builder(menu_category)
        categories[#categories + 1] = category
        local ids = menu_category.id
        if type(ids) ~= "table" then
            ids = { ids }
        end
        for _, id in ipairs(ids) do
            category_map[id] = category_map[id] or (menu_category.enabled ~= false and category)
        end
    end

    categories[#categories + 1] = fallback_category

    local function category_mapper(desktop_file)
        local first_category_id
        if desktop_file.Categories then
            for _, category_id in pairs(desktop_file.Categories) do
                if not first_category_id then
                    first_category_id = category_id
                end
                local category = category_map[category_id]
                if category then
                    return category
                end
            end
        end

        if first_category_id then
            local category = fallback_category_map[first_category_id]
            if not category then
                category = category_builder({ name = tostring(first_category_id) }, true)
                categories[#categories + 1] = category
                fallback_category_map[first_category_id] = category
            end
            return category
        else
            return fallback_category
        end
    end

    return {
        all = categories,
        add = function(desktop_file)
            local category = category_mapper(desktop_file)
            table.insert(category.submenu, {
                flex = true,
                text = hstring.trim(desktop_file.Name) or "",
                icon = desktop_file.icon_path,
                icon_color = false,
                callback = function()
                    awful.spawn(hstring.trim(desktop_file.command) or "")
                end,
            })
        end,
    }
end

local function generate_menu(desktop_files)
    desktop_files = desktop_files or desktop_utils.desktop_files or {}

    local function category_builder(menu_category, is_fallback)
        return {
            text = menu_category.name,
            icon = menu_category.icon_name and desktop_utils.lookup_icon(menu_category.icon_name),
            icon_color = menu_category.icon_color,
            submenu = {},
            is_fallback = is_fallback,
        }
    end

    local category_manager = create_category_manager(category_builder)

    for _, desktop_file in pairs(desktop_files) do
        category_manager.add(desktop_file)
    end

    local categories = {}

    for _, category in ipairs(category_manager.all) do
        if category.submenu and #category.submenu > 0 then
            table.sort(category.submenu, function(a, b) return a.text < b.text end)
            categories[#categories + 1] = category
        end
    end

    table.sort(categories, function(a, b)
        local av = a.submenu and 0 or 1
        local ab = b.submenu and 0 or 1
        if av ~= ab then
            return av < ab
        end

        av = a.is_fallback and 1 or 0
        ab = b.is_fallback and 1 or 0
        if av ~= ab then
            return av < ab
        end

        return a.text < b.text
    end)

    root_menu = {
        item_width = dpi(200),
        items_source = categories,
    }

    table.insert(root_menu.items_source, mebox.separator)
    table.insert(root_menu.items_source, {
        text = "Reload",
        icon = config.places.theme .. "/icons/refresh.svg",
        icon_color = beautiful.palette.gray,
        callback = function() desktop_utils.load_desktop_files() end,
    })
end

capi.awesome.connect_signal("desktop::files", function(desktop_files)
    generate_menu(desktop_files)
end)

generate_menu()

function M.shared()
    return root_menu or {}
end

return M
