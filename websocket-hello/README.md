# Web socket and Apache httpd example for various tests.
Apache httpd since 2.4.44 support since  the proxy check_trans hook that allows a better processing of the websocket upgrades.
If your httpd is older use the patch:
http://people.apache.org/~covener/patches/wstunnel-decline.diff

# WebSocket and mod_cluster/mod_proxy
Simple example use:
```
ProxyPass "/"  "ws://localhost:8080/"
ProxyPass "/"  "http://localhost:8080/"
ProxyPassReverse "/" "http://localhost:8080/"
```

# Test for https://issues.redhat.com/browse/JBCS-1001
Change WSUpgradeHeader none to WSUpgradeHeader ANY and use JBCS httpd-2.4.37 SP6

Note that httpd-trunk needs WSUpgradeHeader "*" instead ANY

# Test for MODCLUSTER-580 and JBCS-291

See https://issues.redhat.com/browse/JBCS-291 and https://issues.redhat.com/browse/MODCLUSTER-580
