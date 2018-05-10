local setmetatable = setmetatable
local type = type

local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function (narr, nrec) return {} end
end

local _M = new_tab(0, 32)

_M._VERSION = '0.0.1'

local mt = { __index = _M }

local _keys = {
    'instanceId',   'hostName', 'app',
    'ipAddr',   'vipAddress',   'secureVipAddress',
    'status',   'homePageUrl',  'statusPageUrl',
    'healthCheckUrl',           --all above are string value
    'leaseInfo',  'metadata',   --these two are table value
}

for i = 1, #_keys do
    local key = _keys[i]
    local cmd = ('set%s%s'):format(
        key:sub(1, 1):upper(),
        key:sub(2)
    )
    _M[cmd] =
        function(self, value)
            local instancedata = self.instancedata
            if not instancedata then
                return nil, 'not initialized'
            end
            instancedata[key] = value
            return self
        end
end

local port_keys = {
    'port', 'securePort',
}

for i = 1, #port_keys do
    local key = port_keys[i]
    local cmd = ('set%s%s'):format(
        key:sub(1, 1):upper(),
        key:sub(2)
    )
    _M[cmd] =
        function(self, value, enabled)
            local instancedata = self.instancedata
            if not instancedata then
                return nil, 'not initialized'
            end
            instancedata[key] = {
                ['$'] = value,
                ['@class'] = enabled,
            }
            return self
        end
end

function _M.new(self)
    local instancedata = new_tab(0, 16)
    return setmetatable({
        instancedata = instancedata,
    }, mt)
end

function _M.setDataCenterInfo(self, name, class, metadata)
    local instancedata = self.instancedata
    if not instancedata then
        return nil, 'not initialized'
    else
        instancedata.dataCenterInfo = {
            name = name,
            ['@class'] = class,
        }
        if metadata and 'table' == type(metadata) then
            instancedata.dataCenterInfo.metadata = metadata
        end
        return self
    end
end

function _M.export(self)
    local instancedata = self.instancedata
    if not instancedata then
        return nil, 'not initialized'
    else
        return {
            instance = instancedata,
        }
    end
end

return _M