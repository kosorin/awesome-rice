local playerctl = require("services.media.playerctl")


local media_service = {}

media_service.player = playerctl.new {
    players = { "spotify", "%any" },
    metadata = {
        title = "xesam:title",
        artist = "xesam:artist",
        length = "mpris:length",
    },
}

return media_service
