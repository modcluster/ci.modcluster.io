REM @author: Michal Karm Babacek <karm@fedoraproject.org>
REM postinstall script to setup your httpd instance

set HTTPD_SERVER_ROOT=%cd%
set HTTPD_SERVER_ROOT_POSIX=%HTTPD_SERVER_ROOT:\=/%

powershell -Command "(gc %HTTPD_SERVER_ROOT%\conf\httpd.conf) -replace '# LoadModule socache_shmcb_module', 'LoadModule socache_shmcb_module' | Out-File -encoding ascii %HTTPD_SERVER_ROOT%\conf\httpd.conf"
powershell -Command "(gc %HTTPD_SERVER_ROOT%\conf\httpd.conf) -replace '# LoadModule ssl_module', 'LoadModule ssl_module' | Out-File -encoding ascii %HTTPD_SERVER_ROOT%\conf\httpd.conf"
powershell -Command "(gc %HTTPD_SERVER_ROOT%\conf\httpd.conf) -replace '#Include conf/extra/httpd-ssl.conf', 'Include conf/extra/httpd-ssl.conf' | Out-File -encoding ascii %HTTPD_SERVER_ROOT%\conf\httpd.conf"
powershell -Command "(gc %HTTPD_SERVER_ROOT%\conf\extra\httpd-ssl.conf) -replace 'www.example.com', 'localhost' | Out-File -Encoding ascii %HTTPD_SERVER_ROOT%\conf\extra\httpd-ssl.conf"

echo "WARNING - the following command might take minutes to complete..."

powershell -Command "get-childitem %HTTPD_SERVER_ROOT% -include *.conf,*.cnf,*.html.* -recurse | ForEach {(Get-Content $_ | ForEach { $_ -replace '@HTTPD_SERVER_ROOT_POSIX@', '%HTTPD_SERVER_ROOT_POSIX%'}) | Set-Content -Encoding ascii $_ }"

echo "WARNING - the following certificates are for testing purposes only."
set "OPENSSL_CONF=%HTTPD_SERVER_ROOT%\conf\ssl\openssl.cnf"
echo Creating '%COMPUTERNAME%' SSL certificates...
mkdir %HTTPD_SERVER_ROOT%\conf\ssl\certs
mkdir %HTTPD_SERVER_ROOT%\conf\ssl\private

pushd %HTTPD_SERVER_ROOT%\bin

set "SSL_CERT=%HTTPD_SERVER_ROOT%\conf\ssl\certs\%COMPUTERNAME%.crt"
set "SSL_PKEY=%HTTPD_SERVER_ROOT%\conf\ssl\private\%COMPUTERNAME%.key"
openssl genrsa -rand 2048>"%SSL_PKEY%"
echo -->stdin.tmp
echo SomeState>>stdin.tmp
echo SomeCity>>stdin.tmp
echo SomeOrganization>>stdin.tmp
echo SomeOrganizationalUnit>>stdin.tmp
echo %COMPUTERNAME%>>stdin.tmp
echo root@%COMPUTERNAME%>>stdin.tmp
type stdin.tmp | openssl req -new -key %HTTPD_SERVER_ROOT_POSIX%/conf/ssl/private/%COMPUTERNAME%.key -x509 -days 365 -set_serial %RANDOM% -out %HTTPD_SERVER_ROOT_POSIX%/conf/ssl/certs/%COMPUTERNAME%.crt
del /Q stdin.tmp

set "SSL_CERT=%HTTPD_SERVER_ROOT%\conf\ssl\certs\localhost.crt"
set "SSL_PKEY=%HTTPD_SERVER_ROOT%\conf\ssl\private\localhost.key"
openssl genrsa -rand 2048>"%SSL_PKEY%"
echo -->stdin.tmp
echo SomeState>>stdin.tmp
echo SomeCity>>stdin.tmp
echo SomeOrganization>>stdin.tmp
echo SomeOrganizationalUnit>>stdin.tmp
echo localhost>>stdin.tmp
echo root@localhost>>stdin.tmp
type stdin.tmp | openssl req -new -key %HTTPD_SERVER_ROOT_POSIX%/conf/ssl/private/localhost.key -x509 -days 365 -set_serial %RANDOM% -out %HTTPD_SERVER_ROOT_POSIX%/conf/ssl/certs/localhost.crt
del /Q stdin.tmp

echo [%DATE% %TIME%] Done
