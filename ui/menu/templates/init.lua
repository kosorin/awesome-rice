local config = require("config")

return {
    applications = require("ui.menu.templates.applications"),
    client = require("ui.menu.templates.client"),
    tag = require("ui.menu.templates.tag"),
    tag_layout = require("ui.menu.templates.tag_layout"),
    power = require("ui.menu.templates.power"),
    wallpaper = require("ui.menu.templates.wallpaper"),
}
