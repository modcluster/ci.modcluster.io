# mod_proxy_cluster for ApacheLounge HTTP Server

This library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See LICENSE.txt.

See http://modcluster.io for details about mod_cluster project.

## Installation

 * copy modules contained in this zip archive into your Apache Lounge modules directory, e.g. ```copy /Y .\modules\mod_*.so %APACHE24%\modules\```
 * copy the default configuration file to your Apache Lounge config extras directory, e.g. ```copy /Y .\conf\extra\mod_cluster.conf %APACHE24%\conf\extra\```
 * include the additional file in your main configuration, e.g. ```echo Include conf/extra/mod_cluster.conf>> %APACHE24%\conf\httpd.conf```
 * update mod_cluster.conf with the desired location for storing temporary shared memory files, e.g. ```(gc %APACHE24%\conf\extra\mod_cluster.conf) -replace '@HTTPD_SERVER_ROOT_POSIX@/cache', '%APACHE24%/logs' | Out-File -Encoding ascii %APACHE24%\conf\extra\mod_cluster.conf;```
 * load proxy_module and load proxy_ajp_module (if you intend to use AJP) into your main configuration; for http(s) communication between balancer and workers, one must load proxy_http; e.g. ```(gc %APACHE24%\conf\httpd.conf) -replace '#LoadModule proxy_module', 'LoadModule proxy_module' | Out-File -Encoding ascii %APACHE24%\conf\httpd.conf;``` and ```(gc %APACHE24%\conf\httpd.conf) -replace '#LoadModule proxy_ajp_module', 'LoadModule proxy_ajp_module' | Out-File -Encoding ascii %APACHE24%\conf\httpd.conf```

## Information about the build
