local http = require 'resty.http'
local json = require 'cjson.safe'
local setmetatable = setmetatable
local tonumber = tonumber
local byte = string.byte
local type = type
local null = ngx.null

local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function (narr, nrec) return {} end
end

local _M = new_tab(0, 16)

_M._VERSION = '0.0.1'

local mt = { __index = _M }

local useragent = 'ngx_lua-EurekaClient/v' .. _M._VERSION

local function request(eurekaclient, method, path, query, body)
    local host = ('http://%s:%s'):format(
        eurekaclient.host,
        eurekaclient.port
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

function _M.getAllApps(self)
    local res, err = request(self, 'GET', '/apps')
    if not res then
        return nil, err
    end
    if 200 ~= res.status then
        return nil, ('status is %d : %s'):format(res.status, res.body)
    else
        return res.body
    end
end

function _M.getApp(self, appid)
    if not appid or 'string' ~= type(appid) or 1 > #appid then
        return nil, 'appid required'
    end
    local res, err = request(self, 'GET', '/apps/' .. appid)
    if not res then
        return nil, err
    end
    if 200 ~= res.status then
        return nil, ('status is %d : %s'):format(res.status, res.body)
    else
        return res.body
    end
end

function _M.getAppInstance(self, appid, instanceid)
    if not appid or 'string' ~= type(appid) or 1 > #appid then
        return nil, 'appid required'
    end
    if not instanceid or 'string' ~= type(instanceid) or 1 > #instanceid then
        return nil, 'instanceid required'
    end
    local res, err = request(self, 'GET', '/apps/' .. appid .. '/' .. instanceid)
    if not res then
        return nil, err
    end
    if 200 ~= res.status then
        return nil, ('status is %d : %s'):format(res.status, res.body)
    else
        return res.body
    end
end

function _M.getInstance(self, instanceid)
    if not instanceid or 'string' ~= type(instanceid) or 1 > #instanceid then
        return nil, 'instanceid required'
    end
    local res, err = request(self, 'GET', '/instances/' .. instanceid)
    if not res then
        return nil, err
    end
    if 200 ~= res.status then
        return nil, ('status is %d : %s'):format(res.status, res.body)
    else
        return res.body
    end
end

function _M.getInstanceByVipAddress(self, vipaddress)
    if not vipaddress or 'string' ~= type(vipaddress) or 1 > #vipaddress then
        return nil, 'vipaddress required'
    end
    local res, err = request(self, 'GET', '/vips/' .. vipaddress)
    if not res then
        return nil, err
    end
    if 200 == res.status then
        return res.body
    elseif 404 == res.status then
        return null, res.body
    else
        return nil, ('status is %d : %s'):format(res.status, res.body)
    end
end

function _M.getInstancesBySecureVipAddress(self, vipaddress)
    if not vipaddress or 'string' ~= type(vipaddress) or 1 > #vipaddress then
        return nil, 'vipaddress required'
    end
    local res, err = request(self, 'GET', '/svips/' .. vipaddress)
    if not res then
        return nil, err
    end
    if 200 == res.status then
        return res.body
    elseif 404 == res.status then
        return null, res.body
    else
        return nil, ('status is %d : %s'):format(res.status, res.body)
    end
end

function _M.takeInstanceOut(self, appid, instanceid)
    if not appid or 'string' ~= type(appid) or 1 > #appid then
        return nil, 'appid required'
    end
    if not instanceid or 'string' ~= type(instanceid) or 1 > #instanceid then
        return nil, 'instanceid required'
    end
    local res, err = request(self, 'PUT', '/apps/' .. appid .. '/' .. instanceid .. '/status', {
        value = 'OUT_OF_SERVICE',
    })
    if not res then
        return nil, err
    end
    if 200 == res.status then
        return true, res.body
    elseif 500 == res.status then
        return null, res.body
    else
        return nil, ('status is %d : %s'):format(res.status, res.body)
    end
end

function _M.putInstanceBack(self, appid, instanceid)
    if not appid or 'string' ~= type(appid) or 1 > #appid then
        return nil, 'appid required'
    end
    if not instanceid or 'string' ~= type(instanceid) or 1 > #instanceid then
        return nil, 'instanceid required'
    end
    local res, err = request(self, 'PUT', '/apps/' .. appid .. '/' .. instanceid .. '/status', {
        value = 'UP',
    })
    if not res then
        return nil, err
    end
    if 200 == res.status then
        return true, res.body
    elseif 500 == res.status then
        return null, res.body
    else
        return nil, ('status is %d : %s'):format(res.status, res.body)
    end
end

function _M.heartBeat(self, appid, instanceid)
    if not appid or 'string' ~= type(appid) or 1 > #appid then
        return nil, 'appid required'
    end
    if not instanceid or 'string' ~= type(instanceid) or 1 > #instanceid then
        return nil, 'instanceid required'
    end
    local res, err = request(self, 'PUT', '/apps/' .. appid .. '/' .. instanceid)
    if not res then
        return nil, err
    end
    if 200 == res.status then
        return true, res.body
    elseif 404 == res.status then
        return null, res.body
    else
        return nil, ('status is %d : %s'):format(res.status, res.body)
    end
end

function _M.updateAppInstanceMetadata(self, appid, instanceid, metadata)
    if not appid or 'string' ~= type(appid) or 1 > #appid then
        return nil, 'appid required'
    end
    if not instanceid or 'string' ~= type(instanceid) or 1 > #instanceid then
        return nil, 'instanceid required'
    end
    if not metadata or 'table' ~= type(metadata) or 1> #metadata then
        return nil, 'metadata required'
    end
    local res, err = request(self, 'PUT', '/apps/' .. appid .. '/' .. instanceid .. '/metadata', metadata)
    if not res then
        return nil, err
    end
    if 200 == res.status then
        return true, res.body
    elseif 500 == res.status then
        return null, res.body
    else
        return nil, ('status is %d : %s'):format(res.status, res.body)
    end
end

return _M