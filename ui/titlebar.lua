local capi = {
    client = client,
}
local awful = require("awful")
local wibox = require("wibox")
local binding = require("io.binding")
local mod = binding.modifier
local btn = binding.button
local dpi = dpi
local amousec = require("awful.mouse.client")


awful.titlebar.enable_tooltip = false

capi.client.connect_signal("request::titlebars", function(client, _, args)
    if args.properties.titlebars_factory then
        args.properties.titlebars_factory(client, args.properties)
        return
    end
    awful.titlebar(client).widget = {
        layout = wibox.layout.flex.horizontal,
        buttons = binding.awful_buttons {
            binding.awful({}, btn.left, function()
                client:activate { context = "titlebar" }
                amousec.move(client)
            end),
            binding.awful({}, btn.right, function()
                client:activate { context = "titlebar" }
                amousec.resize(client)
            end),
            binding.awful({}, btn.middle, function()
                client:kill()
            end),
        },
        {
            widget = awful.titlebar.widget.titlewidget(client),
            halign = "center",
        },
    }
end)
