local binding = require("core.binding")
local mod = binding.modifier
local btn = binding.button

---@type BindboxGroup
return {
    name = "feh",
    rule = { rule = { instance = "feh", class = "feh" } },
    bg = "#70011a",
    { "Escape", "q", description = "Quit" },
    { "x", description = "Close current window" },
    { "f", description = "Toggle fullscreen" },
    { "c", description = "Caption entry mode" },
    { modifiers = { mod.control }, "Delete", description = "Delete current image file" },
    groups = {
        {
            name = "Image",
            { "s", description = "Save the image" },
            { "r", description = "Reload the image" },
            { modifiers = { mod.control }, "r", description = "Render the image" },
            { modifiers = { mod.shift }, binding.button.left, description = "Blur the image" },
            { "&lt;", "&gt;", description = "Rotate 90 degrees" },
            { modifiers = { mod.shift }, binding.button.middle, description = "Rotate" },
            { "_", description = "Vertically flip" },
            { "|", description = "Horizontally flip" },
            { modifiers = { mod.control }, "Left", "Up", "Right", "Down", description = "Scroll/pan" },
            { modifiers = { mod.alt }, "Left", "Up", "Right", "Down", description = "Scroll/pan by one page" },
            { binding.button.left, description = "Pan" },
            { binding.button.middle, "KP_Add", "KP_Subtract", "Up", "Down", description = "Zoom in/out" },
            { "*", description = "Zoom to 100%" },
            { "/", description = "Zoom to fit the window size" },
            { "!", description = "Zoom to fill the window size" },
            { modifiers = { mod.shift }, "z", description = "Toggle auto-zoom in fullscreen" },
            { "k", description = "Toggle zoom and viewport keeping" },
            { "g", description = "Toggle window size keeping" },
        },
        {
            name = "Filelist",
            { modifiers = { mod.shift }, "l", description = "Save the filelist" },
            { binding.button.wheel_up, "space", "Right", "n", description = "Show next image" },
            { binding.button.wheel_down, "BackSpace", "Left", "p", description = "Show previous image" },
            { "Home", "End", description = "Show first/last image" },
            { "Prior", "Next", description = "Go ~5% of the filelist" },
            { "z", description = "Jump to a random image" },
            { "Delete", description = "Remove the image" },
        },
        {
            name = "UI",
            { binding.button.right, "m", description = "Show menu" },
            { "d", description = "Toggle filename display" },
            { "e", description = "Toggle EXIF tag display" },
            { "i", description = "Toggle info display" },
            { "o", description = "Toggle pointer visibility" },
        },
        {
            name = "Slideshow",
            { "h", description = "Pause/continue the slideshow" },
        },
    },
}
