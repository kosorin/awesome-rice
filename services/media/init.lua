local playerctl = require("services.media.playerctl")


local media_service = {}

media_service.player = playerctl.new {
    players = { "spotify", "%any" },
}

return media_service
