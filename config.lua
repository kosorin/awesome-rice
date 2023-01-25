-- DEPENDENCIES (see below)

local table = table
local filesystem = require("gears.filesystem")


local config = {}

config.features = {
    screenshot_tools = true,
    torrent_widget = true,
    weather_widget = true,
    redshift_widget = true,
    wallpaper_menu = true,
}

config.places = {}
config.places.home = os.getenv("HOME")
config.places.config = os.getenv("XDG_CONFIG_HOME") or (config.places.home .. "/.config")
config.places.awesome = string.match(filesystem.get_configuration_dir(), "^(/?.-)/*$")
config.places.theme = config.places.awesome .. "/theme"
config.places.screenshots = config.places.home .. "/inbox/screenshots"
config.places.wallpapers = config.places.home .. "/media/look/wallpapers"

config.apps = {
    shell = "bash",
    terminal = "alacritty",
    editor = "micro",
    browser = "librewolf",
    private_browser = "librewolf --private-window",
    file_manager = "lf",
    calculator = "speedcrunch",
    mixer = "pulsemixer",
    bluetooth_control = "bluetoothctl",
}

config.actions = {
    qr_code_clipboard = "qrclip",
    lock_screen = "light-locker-command --lock",
    show_launcher = "rofi -show",
    show_emoji_picker = config.places.config .. "/rofi/emoji-run.sh",
}

config.commands = {}

function config.commands.terminal_execute(args, options)
    return config.apps.terminal
        .. " " .. table.concat(options or {}, " ")
        .. " -e " .. table.concat(args, " ")
end

function config.commands.open(path)
    return "xdg-open \"" .. path .. "\""
end

function config.commands.copy_text(text)
    return "echo -n \"" .. text .. "\" | xclip -selection clipboard"
end

return config
