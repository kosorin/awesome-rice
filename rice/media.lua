---@class Rice.Media
---@field players (string|"%any")[]
---@field menu AppMenu.ItemCollection
local media = {
    players = { "spotify", "%any" },
    menu = {
        "spotify.desktop",
        "freetube.desktop",
    },
}

return media
