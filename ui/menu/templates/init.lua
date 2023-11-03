local config = require("rice.config")

return {
    applications = require("ui.menu.templates.applications"),
    client = require("ui.menu.templates.client"),
    tag = require("ui.menu.templates.tag"),
    power = require("ui.menu.templates.power"),
    media_player = require("ui.menu.templates.media_player"),
    wallpaper = config.features.wallpaper_menu and require("ui.menu.templates.wallpaper") or nil,
}
