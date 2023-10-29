local playerctl = require("services.media.playerctl")
local rice_media = require("rice.media")


local media_service = {}

media_service.player = playerctl.new {
    players = rice_media.players,
    metadata = {
        title = "xesam:title",
        artist = "xesam:artist",
    },
}

return media_service
