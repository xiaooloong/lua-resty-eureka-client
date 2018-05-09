# Netflix Eureka client for Openresty/ngx_lua

is a [Netflix Eureka][3] client written for [OpenResty][1].

Inspired by [PavelLoparev/php-eureka-client][2].

## Nginx Worker Service

Using `eureka.workerservice` to register nginx itself to Eureka

### workerservice:run(eurekaserver, instancedata)

```lua
init_worker_by_lua_block {
    (require 'eureka.workerservice'):run({
        host = '127.0.0.1',     -- eureka server address
        port = 8761,            -- eureka server port
        uri  = '/eureka/v2',    -- eureka server context uri, like '/eureka' or '/'
        timeval = 10,           -- heartbeat time interval in second, default value is 30s
    },
        instancedata            -- eureka instance data, see 'client:register(appid, instancedata)'
    )
}
```

## Client APIs

client:new(host, port, uri)
---

return the eureka client instance which uses eureka server at `http://{host}:{port}{uri}`, for example :

```lua
local eureka = require 'eureka.client'
local client = eureka:new(  '127.0.0.1',    --if use a domain name, you should use 'resolver' directive in nginx.conf
                            8761,           --port number
                            '/eureka/v2')   --eureka server context uri, like '/eureka' or '/'
```

client:register(appid, instancedata)
---

register an instance to eureka server, `appid` is a string holding the name of your app,

`instancedata` is a lua table conforms to this XSD:

```xsd
<?xml version="1.0" encoding="UTF-8"?>
<xsd:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema" elementFormDefault="qualified" attributeFormDefault="unqualified">
    <xsd:element name="instance">
        <xsd:complexType>
            <xsd:all>
                <!-- hostName in ec2 should be the public dns name, within ec2 public dns name will
                     always resolve to its private IP -->
                <xsd:element name="hostName" type="xsd:string" />
                <xsd:element name="app" type="xsd:string" />
                <xsd:element name="ipAddr" type="xsd:string" />
                <xsd:element name="vipAddress" type="xsd:string" />
                <xsd:element name="secureVipAddress" type="xsd:string" />
                <xsd:element name="status" type="statusType" />
                <xsd:element name="port" type="xsd:positiveInteger" minOccurs="0" />
                <xsd:element name="securePort" type="xsd:positiveInteger" />
                <xsd:element name="homePageUrl" type="xsd:string" />
                <xsd:element name="statusPageUrl" type="xsd:string" />
                <xsd:element name="healthCheckUrl" type="xsd:string" />
               <xsd:element ref="dataCenterInfo" minOccurs="1" maxOccurs="1" />
                <!-- optional -->
                <xsd:element ref="leaseInfo" minOccurs="0"/>
                <!-- optional app specific metadata -->
                <xsd:element name="metadata" type="appMetadataType" minOccurs="0" />
            </xsd:all>
        </xsd:complexType>
    </xsd:element>

    <xsd:element name="dataCenterInfo">
        <xsd:complexType>
             <xsd:all>
                 <xsd:element name="name" type="dcNameType" />
                 <!-- metadata is only required if name is Amazon -->
                 <xsd:element name="metadata" type="amazonMetdataType" minOccurs="0"/>
             </xsd:all>
        </xsd:complexType>
    </xsd:element>

    <xsd:element name="leaseInfo">
        <xsd:complexType>
            <xsd:all>
                <!-- (optional) if you want to change the length of lease - default if 90 secs -->
                <xsd:element name="evictionDurationInSecs" minOccurs="0"  type="xsd:positiveInteger"/>
            </xsd:all>
        </xsd:complexType>
    </xsd:element>

    <xsd:simpleType name="dcNameType">
        <!-- Restricting the values to a set of value using 'enumeration' -->
        <xsd:restriction base = "xsd:string">
            <xsd:enumeration value = "MyOwn"/>
            <xsd:enumeration value = "Amazon"/>
        </xsd:restriction>
    </xsd:simpleType>

    <xsd:simpleType name="statusType">
        <!-- Restricting the values to a set of value using 'enumeration' -->
        <xsd:restriction base = "xsd:string">
            <xsd:enumeration value = "UP"/>
            <xsd:enumeration value = "DOWN"/>
            <xsd:enumeration value = "STARTING"/>
            <xsd:enumeration value = "OUT_OF_SERVICE"/>
            <xsd:enumeration value = "UNKNOWN"/>
        </xsd:restriction>
    </xsd:simpleType>

    <xsd:complexType name="amazonMetdataType">
        <!-- From <a class="jive-link-external-small" href="http://docs.amazonwebservices.com/AWSEC2/latest/DeveloperGuide/index.html?AESDG-chapter-instancedata.html" target="_blank">http://docs.amazonwebservices.com/AWSEC2/latest/DeveloperGuide/index.html?AESDG-chapter-instancedata.html</a> -->
        <xsd:all>
            <xsd:element name="ami-launch-index" type="xsd:string" />
            <xsd:element name="local-hostname" type="xsd:string" />
            <xsd:element name="availability-zone" type="xsd:string" />
            <xsd:element name="instance-id" type="xsd:string" />
            <xsd:element name="public-ipv4" type="xsd:string" />
            <xsd:element name="public-hostname" type="xsd:string" />
            <xsd:element name="ami-manifest-path" type="xsd:string" />
            <xsd:element name="local-ipv4" type="xsd:string" />
            <xsd:element name="hostname" type="xsd:string"/>       
            <xsd:element name="ami-id" type="xsd:string" />
            <xsd:element name="instance-type" type="xsd:string" />
        </xsd:all>
    </xsd:complexType>

    <xsd:complexType name="appMetadataType">
        <xsd:sequence>
            <!-- this is optional application specific name, value metadata -->
            <xsd:any minOccurs="0" maxOccurs="unbounded" processContents="skip"/>
        </xsd:sequence>
    </xsd:complexType>

</xsd:schema>
```

which is like :

```lua
local instancedata = {
        ['instance'] = {
            ['instanceId'] = ('%s:%s:%d'):format('127.0.0.1', 'NGX-EUREKA-CLIENT', ngx.worker.pid()),
            ['hostName'] = 'localhost',
            ['app'] = 'NGX-EUREKA-CLIENT',
            ['ipAddr'] = '127.0.0.1',
            ['vipAddress'] = 'ngx-eureka-client',
            ['secureVipAddress'] = 'ngx-eureka-client',
            ['status'] = 'UP',
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
            ['dataCenterInfo'] = {
                ['name'] = 'MyOwn',
                ['@class'] = 'com.netflix.appinfo.InstanceInfo$DefaultDataCenterInfo',
            },
            ['leaseInfo'] = {
                ['evictionDurationInSecs'] = 60,
            },
            ['metadata'] = {
                ['language'] = 'ngx_lua',
            },
        },
    }
```

client:getAllApps()
---


client:getApp(appid)
---

client:getAppInstance(appid, instanceid)
---

client:getInstance(instanceid)
---

client:getInstanceByVipAddress(vipaddress)
---

client:getInstancesBySecureVipAddress(vipaddress)
---

client:takeInstanceOut(appid, instanceid)
---

client:heartBeat(appid, instanceid)
---

client:updateAppInstanceMetadata(appid, instanceid, metadata)
---

client:deRegister(appid, instanceid)
---

client:putInstanceBack(appid, instanceid)
---

client:removeOverriddenStatus(appid, instanceid)
---


  [1]: http://openresty.org/
  [2]: https://github.com/PavelLoparev/php-eureka-client
  [3]: https://github.com/Netflix/eureka/wiki/Eureka-REST-operations