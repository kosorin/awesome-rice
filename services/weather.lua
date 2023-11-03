-- DEPENDENCIES (feature flag "weather_widget"): curl, lua-dkjson

local config = require("rice.config")
if not config.features.weather_widget then
    return
end

local capi = Capi
local format = string.format
local gears = require("gears")
local awful = require("awful")
local json = require("dkjson")


local weather_service = {
    config = {
        interval = 10 * 60,
    },
    last_response = {
        time = 0,
        success = nil,
        data = {
            station = "",
            time = 0,
            humidity = 0,
            pressure = 0,
            dew_point = 0,
            temperature = 0,
            wind_speed = 0,
            wind_gust = 0,
            wind_chill = 0,
            wind_direction = 0,
            apparent_temperature = 0,
            uv = 0,
            solar_radiation = 0,
            precipitation_rate = 0,
            precipitation_day = 0,
            precipitation_week = 0,
            precipitation_month = 0,
            indoor_humidity = 0,
            indoor_temperature = 0,
            indoor_apparent_temperature = 0,
        },
    },
    timer = nil,
}

local function update_response(data)
    local response = weather_service.last_response
    response.time = os.time()
    if data then
        response.success = true
        gears.table.crush(response.data, data)
    else
        response.success = false
    end
    capi.awesome.emit_signal("weather::updated", response)
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
    local data, error

    if exitreason == "exit" and exitcode == 0 then
        data, _, error = json.decode(stdout)
    else
        error = "Weather fetch error: " .. tostring(exitcode) .. ", " .. exitreason .. " => " .. stderr
    end

    error = error or validate_data(data)

    if error then
        gears.debug.print_error(error)
    end

    update_response(data)
end

function weather_service.update()
    -- TODO: Needs rework
    local data_url = weather_service.config.data_url
    if data_url then
        local command = format([[curl --silent --fail "%s"]], data_url)
        awful.spawn.easy_async(command, on_raw_data)
    end
end

function weather_service.watch()
    weather_service.timer = weather_service.timer or gears.timer {
        timeout = weather_service.config.interval,
        call_now = true,
        callback = weather_service.update,
    }
    weather_service.timer:again()
end

return weather_service
