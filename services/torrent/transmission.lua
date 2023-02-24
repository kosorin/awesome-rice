-- https://github.com/transmission/transmission/blob/main/docs/rpc-spec.md

local ipairs = ipairs
local gobject = require("gears.object")
local gtable = require("gears.table")
local transmission_rpc = require("services.torrent.transmission_rpc")


local transmission = {
    status_codes = {
        idle = 0,
        seeding = 1,
        verifying = 2,
        leeching = 3,
    },
}

transmission.default_data = {
    alternative_speed_enabled = false,
    status = transmission.status_codes.idle,
    eta = -1,
    any_unknown_eta = false,
    wanted_size = 0,
    downloaded_size = 0,
    total_count = 0,
    downloaded_count = 0,
}

function transmission:fetch_data()
    local data = gtable.clone(transmission.default_data)

    local session_response = self._private.rpc:request {
        method = "session-get",
        arguments = {
            fields = {
                "alt-speed-enabled",
            },
        },
    }

    data.alternative_speed_enabled = session_response.arguments["alt-speed-enabled"]


    local torrents_response = self._private.rpc:request {
        method = "torrent-get",
        arguments = {
            fields = {
                "id",
                "status",
                "doneDate",
                "eta",
                "files",
                "fileStats",
            },
        },
    }

    for _, torrent in ipairs(torrents_response.arguments.torrents) do
        data.total_count = data.total_count + 1
        if torrent.doneDate > 0 then
            data.downloaded_count = data.downloaded_count + 1
        end

        if torrent.status == 4 then
            data.status = transmission.status_codes.leeching

            if torrent.eta < 0 then
                data.any_unknown_eta = true
            elseif data.eta < torrent.eta then
                data.eta = torrent.eta
            end

            for f, file in ipairs(torrent.files) do
                if torrent.fileStats[f].wanted then
                    data.downloaded_size = data.downloaded_size + (file.bytesCompleted or 0)
                    data.wanted_size = data.wanted_size + (file.length or 0)
                end
            end
        elseif torrent.status == 2 then
            if data.status < transmission.status_codes.verifying then
                data.status = transmission.status_codes.verifying
            end
        elseif torrent.status == 6 then
            if data.status < transmission.status_codes.seeding then
                data.status = transmission.status_codes.seeding
            end
        end
    end

    return data
end

function transmission:start()
    self._private.rpc:request { method = "torrent-start" }
    return self:fetch_data()
end

function transmission:stop()
    self._private.rpc:request { method = "torrent-stop" }
    return self:fetch_data()
end

function transmission:alternative_speed(enable)
    self._private.rpc:request {
        method = "session-set",
        arguments = {
            ["alt-speed-enabled"] = not not enable,
        },
    }
    return self:fetch_data()
end

function transmission.new(args)
    args = args or {}

    local self = gtable.crush(gobject {}, transmission, true)
    self._private = {}

    self._private.rpc = transmission_rpc.new(args.base_address)

    return self
end

return transmission
