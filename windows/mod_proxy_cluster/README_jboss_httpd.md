# mod_proxy_cluster for JBoss HTTP Server

This library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See LICENSE.txt.

See http://modcluster.io for details about mod_cluster project.

## Installation
 * fetch a JBoss build of [httpd server](https://ci.modcluster.io/job/httpd-windows/) and extract it
 * copy modules contained in this zip archive into your httpd modules directory, e.g. ```copy /Y .\modules\mod_*.so %HTTPD_HOME%\modules\```
 * copy the default configuration file to your httpd config extras directory, e.g. ```copy /Y .\conf\extra\mod_cluster.conf %HTTPD_HOME%\conf\extra\```
 * include the additional file in your main configuration, e.g. ```echo Include conf/extra/mod_cluster.conf>> %HTTPD_HOME%\conf\httpd.conf```
 * load proxy_module and load proxy_ajp_module (if you intend to use AJP) into your main configuration; for http(s) communication between balancer and workers, one must load proxy_http; e.g. ```(gc %HTTPD_HOME%\conf\httpd.conf) -replace '#LoadModule proxy_module', 'LoadModule proxy_module' | Out-File -Encoding ascii %HTTPD_HOME%\conf\httpd.conf;``` and ```(gc %HTTPD_HOME%\conf\httpd.conf) -replace '#LoadModule proxy_ajp_module', 'LoadModule proxy_ajp_module' | Out-File -Encoding ascii %HTTPD_HOME%\conf\httpd.conf```
 * either run ```postinstall.bat``` in your %HTTPD_HOME% or update mod_cluster.conf with the desired location for storing temporary shared memory files, e.g. ```(gc %HTTPD_HOME%\conf\extra\mod_cluster.conf) -replace '@HTTPD_SERVER_ROOT_POSIX@', '%HTTPD_HOME%' | Out-File -Encoding ascii %HTTPD_HOME%\conf\extra\mod_cluster.conf;```

## Information about the build
