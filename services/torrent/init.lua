local config = require("config")
if not config.features.torrent_widget then
    return
end

local capi = {
    awesome = awesome,
}
local type = type
local pcall = pcall
local tostring = tostring
local time = os.time
local gdebug = require("gears.debug")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local transmission = require("services.torrent.transmission")


local torrent_service = {
    instance = transmission.new(),
    status_codes = transmission.status_codes,
    config = {
        interval = 5,
        error_interval = 300,
    },
    last_response = {
        success = nil,
        data = gtable.clone(transmission.default_data),
    },
    timer = nil,
}

local function update_response(data)
    local response = torrent_service.last_response
    response.time = time()
    if data then
        if response.success ~= true then
            torrent_service.timer.timeout = torrent_service.config.interval
            torrent_service.timer:again()
        end
        response.success = true
        gtable.crush(response.data, data)
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

local function call(callback, ...)
    local success, data = pcall(callback, torrent_service.instance, ...)

    local error_message
    if success then
        error_message = validate_data(data)
    else
        error_message = tostring(data)
    end

    if error_message then
        gdebug.print_error(error_message)
        data = nil
    end

    update_response(data)
end

local function reset_timer()
    if reset_timer then
        torrent_service.timer:again()
    end
end

function torrent_service.update()
    reset_timer()
    call(transmission.fetch_data)
end

function torrent_service.start()
    reset_timer()
    call(transmission.start)
end

function torrent_service.stop()
    reset_timer()
    call(transmission.stop)
end

function torrent_service.alternative_speed(enable)
    reset_timer()
    if enable == nil then
        enable = not torrent_service.last_response.data.alternative_speed_enabled
    end
    call(transmission.alternative_speed, enable)
end

function torrent_service.watch()
    torrent_service.timer = torrent_service.timer or gtimer {
            timeout = torrent_service.config.interval,
            callback = function() call(transmission.fetch_data) end,
        }
    torrent_service.timer:again()
end

return torrent_service
