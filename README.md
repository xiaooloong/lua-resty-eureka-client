## Netflix Eureka client for Openresty/ngx_lua

is a [Netflix Eureka][3] client written for [OpenResty][1].

Inspired by [PavelLoparev/php-eureka-client][2].

### Nginx Worker Service

Using `eureka.workerservice` to register nginx itself to Eureka

##### workerservice:run(eurekaserver, instancedata)

```lua
init_worker_by_lua_block {
    (require 'eureka.workerservice'):run({
        host = '127.0.0.1',     -- eureka server address
        port = 8761,            -- eureka server port
        uri  = '/eureka/v2',    -- eureka server context uri, like '/eureka' or '/'
        timeval = 15,           -- heartbeat time interval in second, default value is 30s
    },
        instancedata            -- eureka instance data, see 'InstanceData Builder'
    )
}
```

### Client APIs

##### `client:new(host, port, uri)`

return the eureka client instance which uses eureka server at `http://{host}:{port}{uri}`, for example :

```lua
local eureka = require 'eureka.client'
local client， err = eureka:new(
                            '127.0.0.1',    --add 'resolver' directive in nginx.conf if using domainname
                            8761,           --port number
                            '/eureka/v2'    --eureka server context uri, like '/eureka' or '/'
                            )
if not client then
    print('failed to create eureka client instance : ' .. err)
end
```

In case of error, `nil` will be returned as well as a string describing the error

##### `client:register(appid, instancedata)`

register new application instance to eureka server, `appid` is a string holding the name of your app

`instancedata` is a lua table conforms to this [XSD][3], which you can build by `eureka.instance`

in case of success, `true` will be returned

in case of application or network error, `nil` will be returned as well as a string describing the error

in case of eureka server error, `false` will be returned as well as a string describing the error

##### `client:heartBeat(appid, instanceid)`

send application instance heartbeat for `appid/instanceid`

in case of success, a json string will be returned

in case of application or network error, `nil` will be returned as well as a string describing the error

in case of eureka server error, `false` will be returned as well as a string describing the error

if `instanceid` does not exist, `ngx.null` will be returned

##### `client:deRegister(appid, instanceid)`

de-register application instance for `appid/instanceid`

in case of success, `true` will be returned

in case of application or network error, `nil` will be returned as well as a string describing the error

in case of eureka server error, `false` will be returned as well as a string describing the error

##### `client:getAllApps()`

query for all instances registed in eureka server

in case of success, a json string will be returned

in case of application or network error, `nil` will be returned as well as a string describing the error

in case of eureka server error, `false` will be returned as well as a string describing the error

##### `client:getApp(appid)`

query for all `appid` instances

in case of success, a json string will be returned

in case of application or network error, `nil` will be returned as well as a string describing the error

in case of eureka server error, `false` will be returned as well as a string describing the error

##### `client:getAppInstance(appid, instanceid)`

query for a specific `appid/instanceid`

in case of success, a json string will be returned

in case of application or network error, `nil` will be returned as well as a string describing the error

in case of eureka server error, `false` will be returned as well as a string describing the error

##### `client:getInstance(instanceid)`

query for a specific `instanceid`

in case of success, a json string will be returned

in case of application or network error, `nil` will be returned as well as a string describing the error

in case of eureka server error, `false` will be returned as well as a string describing the error

##### `client:getInstanceByVipAddress(vipaddress)`

query for all instances under a particular `vipaddress`

in case of success, a json string will be returned

in case of application or network error, `nil` will be returned as well as a string describing the error

in case of eureka server error, `false` will be returned as well as a string describing the error

if `vipaddress` does not exist, `ngx.null` will be returned

##### `client:getInstancesBySecureVipAddress(vipaddress)`

query for all instances under a particular secure `vipaddress`

in case of success, a json string will be returned

in case of application or network error, `nil` will be returned as well as a string describing the error

in case of eureka server error, `false` will be returned as well as a string describing the error

if `vipaddress` does not exist, `ngx.null` will be returned

##### `client:takeInstanceOut(appid, instanceid)`

take instance out of service for `appid/instanceid`

in case of success, a json string will be returned

in case of failure, `ngx.null` will be returned

in case of application or network error, `nil` will be returned as well as a string describing the error

in case of eureka server error, `false` will be returned as well as a string describing the error

##### `client:putInstanceBack(appid, instanceid)`

move instance back into service for `appid/insanceid`

in case of success, `true` will be returned

in case of failure, `ngx.null` will be returned

in case of application or network error, `nil` will be returned as well as a string describing the error

in case of eureka server error, `false` will be returned as well as a string describing the error

##### `client:removeOverriddenStatus(appid, instanceid)`

remove the `overriddenstatus` for `appid/instanceid`

in case of success, `true` will be returned

in case of failure, `ngx.null` will be returned

in case of application or network error, `nil` will be returned as well as a string describing the error

in case of eureka server error, `false` will be returned as well as a string describing the error

##### `client:updateAppInstanceMetadata(appid, instanceid, metadata)`

update metadata for `appid/instanceid`

`instancedata` is a lua table holding key-value pairs to be set.

in case of success, `true` will be returned

in case of failure, `ngx.null` will be returned

in case of application or network error, `nil` will be returned as well as a string describing the error

in case of eureka server error, `false` will be returned as well as a string describing the error

### InstanceData Builder

these following methods are used to build `instancedata`

use `instance:new()` to create new `instancedata` object

then use `instance:set*` to set attributes

finally use `instance:export()` to dump a lua table, which will be used at `client:register()`

* `instance:export()`
* `instance:new()`
* `instance:setInstanceId(string)`
* `instance:setHostName(string)`
* `instance:setApp(string)`
* `instance:setIpAddr(string)`
* `instance:setVipAddress(string)`
* `instance:setSecureVipAddress(string)`
* `instance:setStatus(string)`
* `instance:setPort(number, enabled)`
* `instance:setSecurePort(number, enabled)`
* `instance:setHomePageUrl(string)`
* `instance:setStatusPageUrl(string)`
* `instance:setHealthCheckUrl(string)`
* `instance:setDataCenterInfo(name, class, metadata)`
* `instance:setLeaseInfo(table)`
* `instance:setMetadata(table)`

for example:

```lua
local i = require 'eureka.instance'
local ins = i:new()

local app = 'ngx-eureka-service'
local host = 'localhost'
local ip = '127.0.0.1'

ins:setInstanceId(('%s:%s:%s'):format(ip, app, ngx.worker.pid()))
ins:setHostName(host):setApp(app:upper())
ins:setIpAddr(host):setVipAddress(host)
ins:setStatus('UP'):setPort(80, true):setSecurePort(443, false)
ins:setHomePageUrl('http://' .. host):setStatusPageUrl('http://' .. host .. '/status')
ins:setHealthCheckUrl('http://' .. host .. '/check')
ins:setDataCenterInfo('Amazon', 'com.netflix.appinfo.AmazonInfo', {
    data_center_test_key = 'data_center_test_value'
})
ins:setLeaseInfo({
    evictionDurationInSecs = 60,
})
ins:setMetadata({
    language = 'ngx_lua'
})
local ok, err = client:register(app:upper(), ins:export())
```

### Prerequisites

This library requires [`pintsized/lua-resty-http`][4] to be installed.

## See Also

 * Eureka REST operations: https://github.com/Netflix/eureka/wiki/Eureka-REST-operations
 * PavelLoparev/php-eureka-client: https://github.com/PavelLoparev/php-eureka-client

  [1]: http://openresty.org/
  [2]: https://github.com/PavelLoparev/php-eureka-client
  [3]: https://github.com/Netflix/eureka/wiki/Eureka-REST-operations
  [4]: https://github.com/pintsized/lua-resty-http