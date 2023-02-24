-- Transmission's RPC specification: https://github.com/transmission/transmission/blob/main/docs/rpc-spec.md

-- DEPENDENCIES: lua-socket
-- https://w3.impa.br/~diego/software/luasocket/http.html
local http = require("socket.http")
-- https://w3.impa.br/~diego/software/luasocket/ltn12.html
local ltn12 = require("ltn12")

-- DEPENDENCIES: lua-dkjson
-- http://dkolf.de/src/dkjson-lua.fsl/home
local json = require("dkjson")

local setmetatable = setmetatable
local select = select
local error = error


local transmission_rpc = {}

local function built_error_message(title, value)
    return title .. ": " .. (tostring(value) or "???")
end

function transmission_rpc:request(request)
    local request_body = json.encode(request)

    local resend_for_session_id = false
    ::again::
    local response_body_chunks = {}
    local response_status_code, response_headers = select(2, http.request {
        url = self.base_address,
        method = "POST",
        headers =
        {
            ["X-Transmission-Session-Id"] = self.session_id,
            ["Content-Length"] = #request_body,
        },
        sink = ltn12.sink.table(response_body_chunks),
        source = ltn12.source.string(request_body),
    })

    if response_status_code == 200 then
        local body = table.concat(response_body_chunks)
        local response, _, json_error = json.decode(body, 1, nil)
        if json_error then
            error(built_error_message("transmission_response_json", response.json_error))
        elseif response.result ~= "success" then
            error(built_error_message("transmission_response_result", response.result))
        else
            return response
        end
    elseif response_status_code == 409 then
        self.session_id = response_headers and response_headers["x-transmission-session-id"]
        if not resend_for_session_id then
            resend_for_session_id = true
            goto again
        end
        error("Could not get session id")
    end
    error(built_error_message("response_status_code", response_status_code))
end

function transmission_rpc.new(base_address)
    return setmetatable({
        base_address = base_address or "http://localhost:9091/transmission/rpc",
    }, { __index = transmission_rpc })
end

return transmission_rpc
