# Netflix Eureka client for Openresty/ngx_lua

is a [Netflix Eureka][3] client written for [OpenResty][1].

Inspired by [PavelLoparev/php-eureka-client][2].

## Register nginx itself to Eureka:
```lua
init_worker_by_lua_block {
    (require 'eureka.workerservice'):run({
        host = '127.0.0.1',
        port = 8761,
        uri  = '/eureka/v2',
        timeval = 5,
    },
    {
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
        ['homePageUrl'] = 'http://localhost/',
        ['statusPageUrl'] = 'http://localhost/status',
        ['healthCheckUrl'] = 'http://localhost/check',
        ['vipAddress'] = 'ngx-eureka-client',
        ['secureVipAddress'] = 'ngx-eureka-client',
        ['metadata'] = {
            ['foo'] = 'bar',
        },
    })
}
```

## APIs

### client:new(host, port, uri)
### client:getAllApps()
### client:getApp(appid)
### client:getAppInstance(appid, instanceid)
### client:getInstance(instanceid)
### client:getInstanceByVipAddress(vipaddress)
### client:getInstancesBySecureVipAddress(vipaddress)
### client:takeInstanceOut(appid, instanceid)
### client:heartBeat(appid, instanceid)
### client:updateAppInstanceMetadata(appid, instanceid, metadata)
### client:deRegister(appid, instanceid)
### client:putInstanceBack(appid, instanceid)
### client:removeOverriddenStatus(appid, instanceid)
### client:register(appid, instancedata)

  [1]: http://openresty.org/
  [2]: https://github.com/PavelLoparev/php-eureka-client
  [3]: https://github.com/Netflix/eureka/wiki/Eureka-REST-operations