local capi = Capi
local pairs = pairs
local ipairs = ipairs
local table = table
local awful = require("awful")
local beautiful = require("theme.theme")
local desktop_utils = require("services.desktop")
local mebox = require("widget.mebox")
local hstring = require("utils.string")
local config = require("rice.config")
local app_menu = require("rice.apps").menu
local dpi = Dpi


---@class AppMenu.Categories
---@field categories table<string, AppMenu.Category>

---@class AppMenu.FallbackCategory : AppMenu.Category
---@field id nil

---@class AppMenu.Category
---@field id string|string[] # Category ID. Registered categories: https://specifications.freedesktop.org/menu-spec/latest/apa.html
---@field name? string # Menu item name.
---@field icon? string # Icon path.
---@field icon_name? string # Icon name. Uses current icon theme.
---@field icon_color? string # Icon color for SVG icons.
---@field enabled? boolean

---@class AppMenu.Item
---@field id? string # Desktop file ID or path to the desktop file.
---@field command? string|function
---@field name? string # Menu item name.
---@field icon? string # Icon path.
---@field icon_name? string # Icon name. Uses current icon theme.
---@field icon_color? string # Icon color for SVG icons.

---@alias AppMenu.ItemCollection (AppMenu.Item|string)[]

---@class AppMenu
---@field favorites AppMenu.ItemCollection
---@field fallback_category? AppMenu.FallbackCategory
---@field categories? table<string, AppMenu.Category>


local M = {}

---@return MeboxItem.args[]
local favorites_items

---@return Mebox.new.args
local categories_menu

---@param callback? DesktopFile|string|function
---@return MeboxItem.args?
local function build_item_base(callback)
    if not callback then
        return nil
    end

    ---@type MeboxItem.args
    local item = {
        flex = true,
    }

    local callback_type = type(callback)
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

---@param args? string|AppMenu.Item
---@param desktop_files? DesktopFileCollection
---@return MeboxItem.args?
local function build_item(args, desktop_files)
    desktop_files = desktop_files or desktop_utils.desktop_files

    ---@type MeboxItem.args?
    local item

    if type(args) == "string" then
        item = build_item_base(desktop_files:find(args))
    elseif type(args) == "table" then
        if args.id then
            item = build_item_base(desktop_files:find(args.id))
        elseif args.command then
            item = build_item_base(args.command)
        end

        if item then
            if args.name then
                item.text = args.name
            end

            if args.icon then
                item.icon = args.icon
            elseif args.icon_name then
                item.icon = desktop_utils.lookup_icon(args.icon_name)
            end

            if args.icon_color then
                item.icon_color = args.icon_color
            end
        end
    end

    return item
end

---@param items_source? AppMenu.ItemCollection
---@param desktop_files? DesktopFileCollection
---@return MeboxItem.args[]
function M.build_items(items_source, desktop_files)
    desktop_files = desktop_files or desktop_utils.desktop_files

    local items = {}

    if items_source then
        for _, args in ipairs(items_source) do
            local item = build_item(args, desktop_files)
            if item then
                table.insert(items, item)
            end
        end
    end

    return items
end

---@param desktop_files? DesktopFileCollection
local function generate_favorites(desktop_files)
    favorites_items = M.build_items(app_menu.favorites, desktop_files)
end

local function new_category_manager()
    local function build_category(menu_category, is_fallback)
        return {
            text = menu_category.name,
            icon = menu_category.icon_name and desktop_utils.lookup_icon(menu_category.icon_name),
            icon_color = menu_category.icon_color,
            is_fallback = is_fallback,
            desktop_file_ids = {},
        }
    end

    local categories = {}
    local category_map = {}
    local fallback_category = build_category(app_menu.fallback_category, true)
    local fallback_category_map = {}

    if app_menu.categories then
        for _, menu_category in pairs(app_menu.categories) do
            local category = build_category(menu_category)
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

    local function category_mapper(desktop_file_categories)
        local first_category_id
        if desktop_file_categories then
            for _, category_id in pairs(desktop_file_categories) do
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
                category = build_category({ name = tostring(first_category_id) }, true)
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
            ---@cast desktop_file DesktopFile
            if desktop_file.id then
                local category = category_mapper(desktop_file.Categories)
                table.insert(category.desktop_file_ids, desktop_file.id)
            end
        end,
    }
end

---@param desktop_files? DesktopFileCollection
local function generate_categories(desktop_files)
    desktop_files = desktop_files or desktop_utils.desktop_files

    local category_manager = new_category_manager()

    for _, desktop_file in ipairs(desktop_files) do
        category_manager.add(desktop_file)
    end

    local categories = {}

    for _, category in ipairs(category_manager.all) do
        if #category.desktop_file_ids > 0 then
            local items = M.build_items(category.desktop_file_ids, desktop_files)
            if #items > 0 then
                category.submenu = items
                table.sort(category.submenu, function(a, b) return a.text < b.text end)
                table.insert(categories, category)
            end
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

    table.insert(categories, mebox.separator)
    table.insert(categories, {
        text = "Reload",
        icon = beautiful.icon("refresh.svg"),
        icon_color = beautiful.palette.gray,
        callback = function() desktop_utils.load_desktop_files() end,
    })

    ---@type Mebox.new.args
    categories_menu = {
        item_width = dpi(200),
        items_source = categories,
    }
end

capi.awesome.connect_signal("desktop::files", function(desktop_files)
    generate_favorites(desktop_files)
    generate_categories(desktop_files)
end)

generate_favorites()
generate_categories()

---@return MeboxItem.args[]
function M.get_favorites_items()
    return favorites_items or {}
end

---@return Mebox.new.args
function M.get_categories_menu()
    return categories_menu or {}
end

return M
