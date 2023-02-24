-- Transmission's RPC specification: https://github.com/transmission/transmission/blob/main/docs/rpc-spec.md

-- DEPENDENCIES: lua-http
-- https://daurnimator.github.io/lua-http/
local http_request = require("http.request")

-- DEPENDENCIES: lua-dkjson
-- http://dkolf.de/src/dkjson-lua.fsl/home
local json = require("dkjson")

local error = error


local transmission_rpc = {}

local function build_error_message(title, value)
    return title .. ": " .. (tostring(value) or "???")
end

function transmission_rpc.new(args)
    args = args or {}

    local timeout = args.timeout or 2
    local request = http_request.new_from_uri(args.base_address or "http://localhost:9091/transmission/rpc")
    request.headers:upsert(":method", "POST")

    return function(data)
        request:set_body(json.encode(data))
        local headers, stream = assert(request:go(timeout))
        if headers:get(":status") == "409" then
            request.headers:upsert("X-Transmission-Session-Id", tostring(headers:get("x-transmission-session-id")))
            headers, stream = assert(request:go(timeout))
        end
        if headers:get(":status") ~= "200" then
            error(build_error_message("response_status_code", headers:get(":status")))
        end

        local body = assert(stream:get_body_as_string())
        local response, _, json_error = json.decode(body, 1, nil)
        if json_error then
            error(build_error_message("transmission_response_json", json_error))
        elseif response.result ~= "success" then
            error(build_error_message("transmission_response_result", response.result))
        else
            return response
        end
    end
end

return transmission_rpc
