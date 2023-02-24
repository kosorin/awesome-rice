-- https://github.com/transmission/transmission/blob/main/docs/rpc-spec.md

local pairs = pairs
local ipairs = ipairs
local gobject = require("gears.object")
local gtable = require("gears.table")
local transmission_rpc = require("services.torrent.transmission_rpc")


local transmission = {
    status = {
        idle = 0,
        seeding = 1,
        verifying = 2,
        leeching = 3,
    },
}

function transmission:fetch_status()
    local session_response = self._private.rpc:request {
        method = "session-get",
        arguments = {
            fields = {
                "alt-speed-enabled",
            },
        },
    }
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

    local output = {
        alternative_speed_enabled = session_response.arguments["alt-speed-enabled"],
        status = transmission.status.idle,
        eta = nil,
        any_unknown_eta = false,
        wanted_size = 0,
        downloaded_size = 0,
        total_count = 0,
        downloaded_count = 0,
    }

    for _, torrent in ipairs(torrents_response.arguments.torrents) do
        output.total_count = output.total_count + 1
        if torrent.doneDate > 0 then
            output.downloaded_count = output.downloaded_count + 1
        end

        if torrent.status == 4 then
            output.status = transmission.status.leeching

            if torrent.eta < 0 then
                output.any_unknown_eta = true
            elseif not output.eta or output.eta < torrent.eta then
                output.eta = torrent.eta
            end

            for f, file in ipairs(torrent.files) do
                if torrent.fileStats[f].wanted then
                    output.downloaded_size = output.downloaded_size + (file.bytesCompleted or 0)
                    output.wanted_size = output.wanted_size + (file.length or 0)
                end
            end
        elseif torrent.status == 2 then
            if output.status < transmission.status.verifying then
                output.status = transmission.status.verifying
            end
        elseif torrent.status == 6 then
            if output.status < transmission.status.seeding then
                output.status = transmission.status.seeding
            end
        end
    end

    if not output.eta then
        output.eta = -1
    end

    return output
end

function transmission:start()
    self._private.rpc:request { method = "torrent-start" }
    return self:fetch_status()
end

function transmission:stop()
    self._private.rpc:request { method = "torrent-stop" }
    return self:fetch_status()
end

function transmission:alternative_speed(enable)
    self._private.rpc:request {
        method = "session-set",
        arguments = {
            ["alt-speed-enabled"] = enable ~= false,
        },
    }
    return self:fetch_status()
end

function transmission.new(args)
    args = args or {}

    local self = gtable.crush(gobject {}, transmission, true)
    self._private = {}

    self._private.rpc = transmission_rpc.new(args.base_address)

    return self
end

return transmission
