local beautiful = require("theme.theme")
local config = require("config")

---@class AppMenu.Categories
---@field categories table<string, AppMenu.Category>

---@class AppMenu.FallbackCategory : AppMenu.Category
---@field id nil

---@class AppMenu.Category
---@field id string|string[] # Category ID. Registered categories: https://specifications.freedesktop.org/menu-spec/latest/apa.html
---@field name string
---@field icon_name? string
---@field icon_color? string
---@field enabled? boolean

---@class AppMenu.Item
---@field id? string # Desktop file ID or path to the desktop file.
---@field command? string|function
---@field name? string # Menu item name.
---@field icon? string # Icon path.
---@field icon_name? string # Icon name. Uses current icon theme.
---@field icon_color? string # Icon color for SVG icons.

---@class AppMenu
---@field favorites (AppMenu.Item|string)[]
---@field fallback_category? AppMenu.FallbackCategory
---@field categories? table<string, AppMenu.Category>
local app_menu = {
    favorites = {
        {
            command = config.apps.terminal,
            name = "Terminal",
            icon = config.places.theme .. "/icons/console-line.svg",
            icon_color = beautiful.palette.gray,
        },
        {
            command = config.apps.calculator,
            name = "Calculator",
            icon = config.places.theme .. "/icons/calculator.svg",
            icon_color = beautiful.palette.magenta,
        },
        "brave-browser.desktop",
        "spotify.desktop",
        "freetube.desktop",
        {
            id = "code.desktop",
            name = "Code",
        },
    },
    fallback_category = {
        name = "Other",
    },
    categories = {
        utility = {
            id = "Utility",
            name = "Accessories",
            icon_name = "applications-accessories",
            icon_color = beautiful.palette.green,
        },
        development = {
            id = "Development",
            name = "Development",
            icon_name = "applications-development",
            icon_color = beautiful.palette.cyan,
        },
        education = {
            id = "Education",
            name = "Education",
            icon_name = "applications-science",
            icon_color = beautiful.palette.gray,
        },
        games = {
            id = { "Game", "Games" },
            name = "Games",
            icon_name = "applications-games",
            icon_color = beautiful.palette.red,
        },
        graphics = {
            id = "Graphics",
            name = "Graphics",
            icon_name = "applications-graphics",
            icon_color = beautiful.palette.yellow,
        },
        internet = {
            id = "Network",
            name = "Internet",
            icon_name = "applications-internet",
            icon_color = beautiful.palette.blue,
        },
        multimedia = {
            id = "AudioVideo",
            name = "Multimedia",
            icon_name = "applications-multimedia",
            icon_color = beautiful.palette.cyan,
        },
        office = {
            id = "Office",
            name = "Office",
            icon_name = "applications-office",
            icon_color = beautiful.palette.white,
        },
        science = {
            id = "Science",
            name = "Science",
            icon_name = "applications-science",
            icon_color = beautiful.palette.magenta,
        },
        settings = {
            id = "Settings",
            name = "Settings",
            icon_name = "applications-utilities",
            icon_color = beautiful.palette.orange,
        },
        tools = {
            id = "System",
            name = "System Tools",
            icon_name = "applications-system",
            icon_color = beautiful.palette.gray,
        },
    },
}

return app_menu
