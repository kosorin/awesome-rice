local pairs = pairs
local ipairs = ipairs
local table = table
local awful = require("awful")
local beautiful = require("beautiful")
local gtable = require("gears.table")
local gfilesystem = require("gears.filesystem")
local desktop_utils = require("utils.desktop")
local mebox = require("widget.mebox")
local config = require("config")
local dpi = dpi


local application_menu_template = { mt = {} }

local root_menu

local function get_xdg_directories()
    local dirs = gfilesystem.get_xdg_data_dirs()
    table.insert(dirs, 1, gfilesystem.get_xdg_data_home())
    return gtable.map(function(dir) return dir .. 'applications/' end, dirs)
end

local function lookup_category_icons()
    for _, category in pairs(beautiful.application_categories) do
        category.icon = desktop_utils.lookup_icon(category.icon_name) or category.icon
    end
end

local function get_category_name_and_usage_by_type(app_type)
    for category_key, category in pairs(beautiful.application_categories) do
        if category.app_type == app_type then
            return category.enabled ~= false and category_key
        end
    end
end

local generate_all

local function generate_menu(result)
    local fallback_category = {
        text = "other",
        submenu = {},
    }
    local categories = {}
    local categoriy_keys = {}

    for category_key, category in pairs(beautiful.application_categories) do
        local category_item = {
            text = category.name,
            icon = category.icon,
            icon_color = category.icon_color,
            submenu = {},
        }
        local index = #categories + 1
        categoriy_keys[category_key] = index
        categories[index] = category_item
    end

    for _, application in pairs(result) do
        local category = categories[categoriy_keys[application.category_key]]
        table.insert((category or fallback_category).submenu, {
            flex = true,
            text = application.name,
            icon = application.icon,
            icon_color = false,
            callback = function()
                awful.spawn(application.cmdline)
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
        callback = function() generate_all() end,
    })
end

local function get_desktop_file_id(directory, path)
    return string.gsub(string.sub(path, #directory + 1), "/", "-")
end

function generate_all()
    lookup_category_icons()

    local all_entries = {}
    local parsed_directories = 0

    local all_directories = get_xdg_directories()
    local directory_count = #all_directories
    for priority, directory in ipairs(all_directories) do
        desktop_utils.parse_directory(directory, function(entries)
            entries = entries or {}
            for _, entry in ipairs(entries) do
                local id = get_desktop_file_id(directory, entry.file)
                if not all_entries[id] then
                    all_entries[id] = {}
                end
                if entry.show and entry.Name and entry.cmdline then
                    local target_category_key = nil
                    if entry.categories then
                        for _, category in pairs(entry.categories) do
                            local category_key = get_category_name_and_usage_by_type(category)
                            if category_key then
                                target_category_key = category_key
                                break
                            end
                        end
                    end
                    local name = desktop_utils.rtrim(entry.Name) or ""
                    local cmdline = desktop_utils.rtrim(entry.cmdline) or ""
                    local icon = entry.icon_path or nil
                    all_entries[id][priority] = {
                        name = name,
                        cmdline = cmdline,
                        icon = icon,
                        category_key = target_category_key,
                    }
                else
                    all_entries[id][priority] = true
                end
            end
            parsed_directories = parsed_directories + 1
            if parsed_directories == directory_count then
                local result = {}
                for id, file_entries in pairs(all_entries) do
                    for p = 1, directory_count do
                        local entry = file_entries[p]
                        if entry then
                            if type(entry) == "table" then
                                result[id] = entry
                            end
                            break
                        end
                    end
                end
                generate_menu(result)
            end
        end)
    end
end

application_menu_template.shared = function()
    return root_menu or {}
end

generate_all()

return setmetatable(application_menu_template, application_menu_template.mt)
