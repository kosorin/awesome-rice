local services = {
    screenshot = require("services.screenshot"),
    volume = require("services.volume"),
    weather = require("services.weather"),
    network = require("services.network"),
    torrent = require("services.torrent"),
    wallpaper = require("services.wallpaper"),
}

services.torrent.watch()
services.network.watch()
services.volume.watch()
services.weather.watch()

return services
