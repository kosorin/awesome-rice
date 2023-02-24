-- https://github.com/transmission/transmission/blob/main/docs/rpc-spec.md

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

function transmission_rpc:handle_session_id_response(response_status_code, response_headers)
    if response_headers and response_status_code == 409 or response_status_code == 200 then
        self.session_id = response_headers["x-transmission-session-id"]
    else
        error(response_status_code)
    end
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
        if json_error or response.result ~= "success" then
            error(json_error)
        end
        return response
    elseif response_status_code == 409 then
        self:handle_session_id_response(response_status_code, response_headers)
        if resend_for_session_id then
            error("Could not get session id")
        else
            resend_for_session_id = true
            goto again
        end
    else
        error(response_status_code)
    end
end

local function fetch_session_id(self)
    self:handle_session_id_response(select(2, http.request {
        url = self.base_address,
        method = "POST",
    }))
end

function transmission_rpc.new(base_address)
    local self = setmetatable({
        base_address = base_address or "http://localhost:9091/transmission/rpc",
    }, { __index = transmission_rpc })

    fetch_session_id(self)

    return self
end

return transmission_rpc
