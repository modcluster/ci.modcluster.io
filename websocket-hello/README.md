# Web socket and Apache httpd example for various tests.

Since version 2.4.44 Apache httpd supports proxy\_check\_trans hook that allows a better
processing of websocket upgrades.

## Building

To build the app simply execute

```
mvn clean install
```

you should find the `websocket-hello.war` in `target/` subdirectory.

## WebSocket and mod\_cluster/mod\_proxy\_cluster

You can use the following configuration:

```
LoadModule watchdog_module modules/mod_watchdog.so
LoadModule proxy_module modules/mod_proxy.so
LoadModule proxy_http_module modules/mod_proxy_http.so
LoadModule proxy_hcheck_module modules/mod_proxy_hcheck.so
LoadModule slotmem_shm_module modules/mod_slotmem_shm.so
LoadModule manager_module modules/mod_manager.so
LoadModule proxy_cluster_module modules/mod_proxy_cluster.so

ProxyPreserveHost On

Listen 8090
ServerName httpd-mod_proxy_cluster
CreateBalancers 0
EnableOptions On

WSUpgradeHeader websocket
EnableWsTunnel

<VirtualHost *:8090>
    EnableMCMPReceive
    <Location />
        # For demo only
        Require all granted
    </Location>
</VirtualHost>
```
and run tomcat with the application deployed.

## WebSocket and mod\_cluster/mod\_proxy

Simple example use:

```
WSUpgradeHeader websocket

ProxyPass "/"  "ws://localhost:8080/"
ProxyPass "/"  "http://localhost:8080/"
ProxyPassReverse "/" "http://localhost:8080/"
```

with tomcat (on port 8080) once again running the application.

## Test for https://issues.redhat.com/browse/JBCS-1001
Change `WSUpgradeHeader none` to `WSUpgradeHeader *`.

## Test for MODCLUSTER-580 and JBCS-291

See https://issues.redhat.com/browse/JBCS-291 and https://issues.redhat.com/browse/MODCLUSTER-580

