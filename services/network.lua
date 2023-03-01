local capi = Capi
local time = os.time
local open = io.open
local format = string.format
local gears = require("gears")


local network_service = {
    config = {
        interval = 2,
        interface = "enp6s0",
    },
    last_data = {
        time = 0,
        download = nil,
        upload = nil,
    },
    status = {
        success = nil,
        connected = false,
        download = nil,
        upload = nil,
    },
    timer = nil,
}

local function read_file(path, type)
    local file = open(path, "r")
    if not file then
        return nil
    end
    local value = file:read(type)
    file:close()
    return value
end

local function read_data()
    local connected = read_file(format("/sys/class/net/%s/operstate", network_service.config.interface), "l") == "up"
    local download, upload
    if connected then
        download = read_file(format("/sys/class/net/%s/statistics/rx_bytes", network_service.config.interface), "n") or 0
        upload = read_file(format("/sys/class/net/%s/statistics/tx_bytes", network_service.config.interface), "n") or 0
    end
    return connected, download, upload
end

local function update()
    local status = network_service.status
    local last_data = network_service.last_data
    local success, connected, download, upload = pcall(read_data)
    local now = time()

    if success then
        if connected then
            local diff = now - last_data.time
            local is_valid = diff > 0 and diff < 3 * network_service.config.interval
                and last_data.download
                and last_data.upload
            if is_valid then
                status.download = (download - last_data.download) / diff
                status.upload = (upload - last_data.upload) / diff
            else
                status.download = 0
                status.upload = 0
            end
        end
    end

    status.success = success
    status.connected = connected
    if not success or not connected then
        status.download = nil
        status.upload = nil
    end

    last_data.time = now
    last_data.download = download
    last_data.upload = upload

    capi.awesome.emit_signal("network::updated", status)
end

function network_service.watch()
    network_service.timer = network_service.timer or gears.timer {
        timeout = network_service.config.interval,
        call_now = true,
        callback = update,
    }
    network_service.timer:again()
end

return network_service
