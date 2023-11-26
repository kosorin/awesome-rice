local capi = Capi
local awful = require("awful")
local core = require("core")
local tilted = require("layouts.tilted")
local beautiful = require("theme.theme")


---@class Rice.Apps
---@field menu AppMenu
local apps = {
    menu = {
        favorites = {
            "Alacritty.desktop",
            "speedcrunch.desktop",
            {
                id = "firefox.desktop",
                name = "Firefox",
            },
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
    },
}

return apps
