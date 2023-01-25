local config = require("config")

local services = {
    screenshot = require("services.screenshot"),
    volume = require("services.volume"),
    weather = require("services.weather"),
    network = require("services.network"),
    torrent = require("services.torrent"),
    wallpaper = require("services.wallpaper"),
}

for _, service in pairs(services) do
    if type(service.watch) == "function" then
        service.watch()
    end
end

return services
