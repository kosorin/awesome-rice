-- DEPENDENCIES: pulsemixer

local capi = Capi
local tonumber = tonumber
local string = string
local gtimer = require("gears.timer")
local awful = require("awful")


local volume_service = {
    config = {
        interval = 3,
        limit = 150,
        app = "pulsemixer",
    },
    data = nil,
    timer = nil,
}

local commands = {}

---@return string
function commands.get_data()
    return " --get-volume --get-mute"
end

---@param volume number
---@return string
function commands.set_volume(volume)
    return " --set-volume " .. string.format("%.0f", volume) .. " --max-volume " .. volume_service.config.limit
end

---@param step number
---@return string
function commands.change_volume(step)
    step = step or 1
    return " --change-volume " .. (step > 0 and "+" or "") .. string.format("%.0f", step) .. " --max-volume " .. volume_service.config.limit
end

---@return string
function commands.toggle_mute()
    return " --toggle-mute"
end

local function parse_raw_data(raw_data)
    local volume = nil
    local muted = nil

    local l = 1
    for line in string.gmatch(raw_data, "([^\n]*)\n?") do
        if l == 1 then
            -- Just take first channel, ignore other channels
            local volume_text = line:match("^(%d+)")
            volume = tonumber(volume_text)
        elseif l == 2 then
            local muted_text = line:match("^(%d)$")
            muted = muted_text == "1"
        else
            break
        end
        l = l + 1
    end

    return {
        volume = volume,
        muted = muted,
    }
end

local function process_command_output(stdout, stderr, exitreason, exitcode)
    local data = nil
    if exitreason == "exit" and exitcode == 0 then
        data = parse_raw_data(stdout)
    end
    return data
end

local function update(command, skip_osd)
    awful.spawn.easy_async(command, function(...)
        volume_service.data = process_command_output(...) or {}
        volume_service.data.skip_osd = skip_osd
        capi.awesome.emit_signal("volume::update", volume_service.data)
    end)
end

function volume_service.set_volume(volume, skip_osd)
    update(volume_service.config.app .. commands.set_volume(volume) .. commands.get_data(), skip_osd)
end

function volume_service.change_volume(step, skip_osd)
    update(volume_service.config.app .. commands.change_volume(step) .. commands.get_data(), skip_osd)
end

function volume_service.toggle_mute(skip_osd)
    update(volume_service.config.app .. commands.toggle_mute() .. commands.get_data(), skip_osd)
end

function volume_service.watch()
    volume_service.timer = volume_service.timer or gtimer {
        timeout = volume_service.config.interval,
        call_now = true,
        callback = function()
            update(volume_service.config.app .. commands.get_data(), true)
        end,
    }
    volume_service.timer:again()
end

return volume_service
