local client = require 'eureka.client'

local instance = {
    ['instance'] = {
        ['instanceId'] = 'localhost:ngx-eureka-client:80',
        ['hostName'] = 'localhost',
        ['app'] = 'NGX-EUREKA-CLIENT',
        ['ipAddr'] = '127.0.0.1',
        ['port'] = {
            ['$'] = 80,
            ['@enabled'] = true,
        },
        ['securePort'] = {
            ['$'] = 443,
            ['@enabled'] = false
        },
        ['homePageUrl'] = 'http://127.0.0.1:80/ngx-eureka-client',
        ['statusPageUrl'] = 'http://127.0.0.1:80/status',
        ['healthCheckUrl'] = 'http://127.0.0.1:80/health-check',
        ['vipAddress'] = 'ngx-eureka-client',
        ['secureVipAddress'] = 'ngx-eureka-client',
        ['metadata'] = {
            ['language'] = 'ngx_lua',
        },
        ['dataCenterinfo'] = {
            ['name'] = 'MyOwn',
            ['@class'] = 'com.netflix.appinfo.InstanceInfo$DefaultDataCenterInfo',
        },
    },
}

local handler
handler = function(premature, client, instance, param)
    if premature then
        return client:deRegister(instance.instance.app, instance.instance.instanceId)
    end
    client:heartBeat(instance.instance.app, instance.instance.instanceId)
    ngx.timer.at(param.timeval, handler, client, instance, param)
end


local _M

_M._VERSION = '0.0.1'

function _M.run(self, param)
    local instance = instance
    instance.instance.instanceId = instance.instance.instanceId .. ngx.worker.pid()
    local client:new(param.host, param.port, param.uri)
    client:register(instance.instance.app, instance)
    ngx.timer.at(0, handler, client, instance, {
        timeval = tonumber(param.timeval) or 5,
    })
end

return _M