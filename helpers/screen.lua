local ipairs = ipairs


local screen_helper = {}

--- Move clients from selected tags on the screen to the tag
function screen_helper.clients_to_tag(screen, tag)
    if not screen or not tag or not tag.activated then
        return
    end
    for _, client in ipairs(screen.all_clients) do
        for _, client_tag in ipairs(client:tags()) do
            if client_tag.selected then
                client:move_to_tag(tag)
                break
            end
        end
    end
end

return screen_helper
