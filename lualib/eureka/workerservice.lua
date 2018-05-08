local client = require 'eureka.client'

local _register, _renew

local eurekaclient, eurekaserver, instance, timeval

_register = function(premature)
    if premature then
        return
    end
    local err
    eurekaclient, err = client:new(eurekaserver.host, eurekaserver.port, eurekaserver.uri)
    if not eurekaclient then
        ngx.log(ngx.ALERT, ('can not create client instance %s : %s'):format(instance.instanceId, err))
    else
        local ok, err = eurekaclient:register(instance.app, {
            instance = instance,
        })
        if not ok then
            ngx.log(ngx.ALERT, ('can not register instance %s : %s'):format(instance.instanceId, err))
        end
    end
end

_renew = function(premature)
    if premature then
        return eurekaclient:deRegister(instance.app, instance.instanceId)
    end
    local eurekaclient = eurekaclient
    local ok, err = eurekaclient:heartBeat(instance.app, instance.instanceId)
    if not ok or ngx.null == ok then
        ngx.log(ngx.ALERT, ('failed to renew instance %s : %s'):format(instance.instanceId, err))
    else
        ngx.timer.at(timeval, _renew)
    end
end

local _M = {
    ['_VERSION'] = '0.0.1'
}

function _M.run(self, _eurekaserver, _instance)
    instance = _instance
    eurekaserver = _eurekaserver
    timeval = tonumber(eurekaserver.timeval) or 5

    instance.metadata.language = 'ngx_lua'
    instance.dataCenterInfo = {
        name = 'MyOwn',
        ['@class'] = 'com.netflix.appinfo.InstanceInfo$DefaultDataCenterInfo',
    }
    instance.instanceId = ('%s:%s:%d'):format(instance.ipAddr, instance.app, ngx.worker.pid())

    ngx.timer.at(0, _register)
    ngx.timer.at(timeval, _renew)
end

return _M