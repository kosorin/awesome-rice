local awful = require("awful")
local wibox = require("wibox")


awful.screen.connect_for_each_screen(function(screen)
    local fswibox = wibox {
        screen = screen,
        visible = false,
        ontop = true,
        bg = "#000000",
        opacity = 0.1,
    }

    function screen.show_fswibox(click_action)
        if fswibox.visible then
            return
        end

        if fswibox.click_action then
            fswibox:disconnect_signal("button::release", fswibox.click_action)
        end

        function fswibox.click_action()
            if click_action then
                click_action()
            end
        end

        fswibox:connect_signal("button::release", fswibox.click_action)

        fswibox:geometry(screen.geometry)
        fswibox.visible = true
    end

    function screen.hide_fswibox()
        if fswibox.click_action then
            fswibox:disconnect_signal("button::release", fswibox.click_action)
        end

        fswibox.visible = false
    end

    screen.fswibox = fswibox
end)
