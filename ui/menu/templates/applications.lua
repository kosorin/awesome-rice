local capi = Capi
local pairs = pairs
local ipairs = ipairs
local table = table
local awful = require("awful")
local beautiful = require("theme.theme")
local desktop_utils = require("services.desktop")
local mebox = require("widget.mebox")
local hstring = require("utils.string")
local config = require("config")
local app_menu = require("app_menu")
local dpi = Dpi


local M = {}

local favorites_items
local categories_menu

---@param callback DesktopFile|string|function|nil
---@return MeboxItem.args?
local function build_item(callback)
    if not callback then
        return nil
    end

    local callback_type = type(callback)
    local item = {
        flex = true,
    }
    if callback_type == "table" then
        local desktop_file = callback --[[@as DesktopFile]]
        item.text = hstring.trim(desktop_file.Name) or ""
        item.icon = desktop_file.icon_path
        item.icon_color = false
        item.callback = function()
            awful.spawn(hstring.trim(desktop_file.command) or "")
        end
    elseif callback_type == "string" then
        item.callback = function()
            awful.spawn(callback)
        end
    elseif callback_type == "function" then
        item.callback = callback
    end
    return item
end

---@param desktop_files? DesktopFileCollection
local function generate_favorites(desktop_files)
    desktop_files = desktop_files or desktop_utils.desktop_files

    local items = {}

    if app_menu.favorites then
        for _, favorite in ipairs(app_menu.favorites) do
            local item

            if type(favorite) == "string" then
                item = build_item(desktop_files:find(favorite))
            else
                if favorite.id then
                    item = build_item(desktop_files:find(favorite.id))
                elseif favorite.command then
                    item = build_item(favorite.command)
                end

                if item then
                    if favorite.name then
                        item.text = favorite.name
                    end

                    if favorite.icon then
                        item.icon = favorite.icon
                    elseif favorite.icon_name then
                        item.icon = desktop_utils.lookup_icon(favorite.icon_name)
                    end

                    if favorite.icon_color then
                        item.icon_color = favorite.icon_color
                    end
                end
            end

            if item then
                table.insert(items, item)
            end
        end
    end

    favorites_items = items
end

local function create_category_manager(category_builder)
    local categories = {}
    local category_map = {}
    local fallback_category = category_builder(app_menu.fallback_category, true)
    local fallback_category_map = {}

    if app_menu.categories then
        for _, menu_category in pairs(app_menu.categories) do
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
            table.insert(category.submenu, build_item(desktop_file))
        end,
    }
end

---@param desktop_files? DesktopFileCollection
local function generate_categories(desktop_files)
    desktop_files = desktop_files or desktop_utils.desktop_files

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

    for _, desktop_file in ipairs(desktop_files) do
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

    categories_menu = {
        item_width = dpi(200),
        items_source = categories,
    }

    table.insert(categories_menu.items_source, mebox.separator)
    table.insert(categories_menu.items_source, {
        text = "Reload",
        icon = config.places.theme .. "/icons/refresh.svg",
        icon_color = beautiful.palette.gray,
        callback = function() desktop_utils.load_desktop_files() end,
    })
end

capi.awesome.connect_signal("desktop::files", function(desktop_files)
    generate_favorites(desktop_files)
    generate_categories(desktop_files)
end)

generate_favorites()
generate_categories()

function M.get_favorites_items()
    return favorites_items or {}
end

function M.get_categories_menu()
    return categories_menu or {}
end

return M
