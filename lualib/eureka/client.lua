local http = require 'resty.http'
local json = require 'cjson.safe'
local setmetatable = setmetatable
local tonumber = tonumber
local byte = string.byte
local type = type

local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function (narr, nrec) return {} end
end

local _M = new_tab(0, 8)

_M._VERSION = '0.0.1'

local mt = { __index = _M }

local useragent = 'ngx_lua-EurekaClient/v' .. _M._VERSION

local function request(eurekaclient, method, path, query, body)
    local host = ('http://%s:%s'):format(
        eurekaclient.host,
        eurekaclient.port,
    )
    local path = eurekaclient.uri .. path

    local headers = new_tab(0, 4)
    headers['User-Agent'] = useragent
    headers['Connection'] = 'Keep-Alive'
    headers['Accept'] = 'application/json'

    if body and 'table' == type(body) then
        local err
        body, err = cjson.encode(body)
        if not body then
            return nil, 'invalid body : ' .. err
        end
        headers['Content-Type'] = 'application/json'
    end

    return httpc:request_uri(host, {
        version = '1.1',
        method = method,
        headers = headers,
        path = path,
        query = query,
        body = body,
    })
end

function _M.new(self, host, port, uri)
    if not host or 'string' ~= type(host) or 1 > #host then
        return nil, 'host required'
    end
    local port = tonumber(port) or 80
    if not port or 1 > port or 65535 < port then
        return nil, 'wrong port number'
    end
    local uri = uri or '/eureka'
    if 'string' ~= type(uri) or byte(uri) ~= 47 then -- '/'
        return nil, 'wrong uri prefix'
    end
    local httpc, err = http.new()
    if not httpc then
        return nil, 'failed to init http client instance : ' .. err
    end
    return setmetatable({
        host = host,
        port = port,
        uri = uri,
        httpc = httpc,
    }, mt)
end

return _M