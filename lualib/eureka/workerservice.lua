local client = require 'eureka.client'

local handler
handler = function(premature, eurekaclient, instance, timeval)
    if premature then
        return eurekaclient:deRegister(instance.app, instance.instanceId)
    end
    local ok, err = eurekaclient:heartBeat(instance.app, instance.instanceId)
    if not ok or ngx.null == ok then
        ngx.log(ngx.ALERT, ('failed to renew instance %s : %s'):format(instance.instanceId, err))
    else
        ngx.timer.at(timeval, handler, eurekaclient, instance, timeval)
    end
end

local _M = {
    ['_VERSION'] = '0.0.1'
}

function _M.run(self, eurekaserver, instance)
    instance.metadata.language = 'ngx_lua'
    instance.dataCenterinfo = {
        name = 'MyOwn',
        ['@class'] = 'com.netflix.appinfo.InstanceInfo$DefaultDataCenterInfo',
    }
    instance.instanceId = ('%s:%s:%d'):format(instance.ipAddr, instance.app, ngx.worker.pid())

    local eurekaclient = client:new(eurekaserver.host, eurekaserver.port, eurekaserver.uri)
    local ok, err = eurekaclient:register(instance.app, {
        instance = instance,
    })

    if ok then
        ngx.timer.at(0, handler, eurekaclient, instance, tonumber(param.timeval) or 5)
    else
        ngx.log(ngx.ALERT, ('failed to start eureka service at %s : %s'):format(instance.instanceId, err))
    end
end

return _M