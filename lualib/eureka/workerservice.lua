local client = require 'eureka.client'

local _register, _renew

_register = function(premature, instance)
    if premature then
        return
    end
    return eurekaclient:register(instance.app, {
        instance = instance,
    })

end

_renew = function(premature, eurekaclient, instance, timeval)
    if premature then
        return eurekaclient:deRegister(instance.app, instance.instanceId)
    end
    local ok, err = eurekaclient:heartBeat(instance.app, instance.instanceId)
    if not ok or ngx.null == ok then
        ngx.log(ngx.ALERT, ('failed to renew instance %s : %s'):format(instance.instanceId, err))
    else
        ngx.timer.at(timeval, _renew, eurekaclient, instance, timeval)
    end
end

local _M = {
    ['_VERSION'] = '0.0.1'
}

function _M.run(self, eurekaserver, instance)
    local timeval = tonumber(eurekaserver.timeval) or 5
    instance.metadata.language = 'ngx_lua'
    instance.dataCenterinfo = {
        name = 'MyOwn',
        ['@class'] = 'com.netflix.appinfo.InstanceInfo$DefaultDataCenterInfo',
    }
    instance.instanceId = ('%s:%s:%d'):format(instance.ipAddr, instance.app, ngx.worker.pid())

    local eurekaclient = client:new(eurekaserver.host, eurekaserver.port, eurekaserver.uri)

    ngx.timer.at(0, _register, instance)

    if ok then
        ngx.timer.at(timeval, _renew, eurekaclient, instance, timeval)
    else
        ngx.log(ngx.ALERT, ('failed to start eureka service at %s : %s'):format(instance.instanceId, err))
    end
end

return _M