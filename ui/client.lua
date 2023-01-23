local capi = {
    client = client,
}


require("awful.autofocus")

capi.client.connect_signal("mouse::enter", function(client)
    client:activate { context = "mouse_enter", raise = false }
end)
