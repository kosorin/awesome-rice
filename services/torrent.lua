-- DEPENDENCIES (feature flag "torrent_widget"): transmission-status, lua-dkjson

local config = require("rice.config")
if not config.features.torrent_widget then
    return
end

local capi = Capi
local table = table
local json = require("dkjson")
local gears = require("gears")
local awful = require("awful")


local torrent_service = {
    status_codes = {
        idle = 0,
        seeding = 1,
        verifying = 2,
        leeching = 3,
    },
    config = {
        interval = 5,
        error_interval = 300,
    },
    last_response = {
        success = nil,
        data = {
            alternative_speed_enabled = false,
            status = 0,
            eta = nil,
            any_unknown_eta = false,
            downloaded_size = 0,
            total_size = 0,
        },
    },
    timer = nil,
}

local function update_response(data)
    local response = torrent_service.last_response
    response.time = os.time()
    if data then
        if response.success ~= true then
            torrent_service.timer.timeout = torrent_service.config.interval
            torrent_service.timer:again()
        end
        response.success = true
        gears.table.crush(response.data, data)
    else
        if response.success ~= false then
            torrent_service.timer.timeout = torrent_service.config.error_interval
            torrent_service.timer:again()
        end
        response.success = false
    end
    capi.awesome.emit_signal("torrent::updated", response)
end

local function validate_data(data)
    if type(data) == "table" then
        if not data.error then
            return nil
        else
            return tostring(data.error)
        end
    else
        return "Bad data"
    end
end

local function on_raw_data(stdout, stderr, exitreason, exitcode)
    local unknown_error, data, error

    if exitreason == "exit" and exitcode == 0 then
        unknown_error, data, _, error = pcall(json.decode, stdout)
        if not unknown_error and not error then
            error = "Torrent status error: Unknown error"
        end
    else
        error = "Torrent status error: " .. tostring(exitcode) .. ", " .. exitreason .. " => " .. stderr
    end

    error = error or validate_data(data)

    if error then
        gears.debug.print_error(error)
    end

    update_response(data)
end

local function update(reset_timer, options)
    if reset_timer then
        torrent_service.timer:again()
    end
    local command = "transmission-status"
    if options and #options > 0 then
        command = command .. " " .. table.concat(options, " ")
    end
    awful.spawn.easy_async(command, on_raw_data)
end

function torrent_service.update()
    update(true)
end

function torrent_service.start()
    update(true, { "--start" })
end

function torrent_service.stop()
    update(true, { "--stop" })
end

function torrent_service.alternative_speed(enable)
    if enable == nil then
        enable = not torrent_service.last_response.data.alternative_speed_enabled
    end
    update(true, { "-a", enable and 1 or 0 })
end

function torrent_service.watch()
    torrent_service.timer = torrent_service.timer or gears.timer {
        timeout = torrent_service.config.interval,
        call_now = true,
        callback = function() update(false) end,
    }
    torrent_service.timer:again()
end

return torrent_service
