REM Architecture
if "%arch%" equ "64" (
    call vcvars64
) else (
    set "PATH=C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\bin;%PATH%"
    call vcvars32
)

REM Dependencies
REM We rely on label being the same. It is probably for the best, gonna keep the same MSVC...

REM OpenSSL
unzip .\dependencies\arch=%arch%,label=%label%\OpenSSL*.zip -d .\dependencies\openssl
IF NOT %ERRORLEVEL% == 0 ( exit 1 )

REM LibXML2
unzip .\dependencies\arch=%arch%,label=%label%\libxml2*.zip -d .\dependencies\libxml2
IF NOT %ERRORLEVEL% == 0 ( exit 1 )

REM ZLib
unzip .\dependencies\arch=%arch%,label=%label%\zlib*.zip -d .\dependencies\zlib
IF NOT %ERRORLEVEL% == 0 ( exit 1 )

REM APR
unzip .\dependencies\arch=%arch%,label=%label%\apr-1*.zip -d .\dependencies\apr
IF NOT %ERRORLEVEL% == 0 ( exit 1 )

REM APR Util
unzip .\dependencies\arch=%arch%,label=%label%\apr-util-1*.zip -d .\dependencies\apr-util
IF NOT %ERRORLEVEL% == 0 ( exit 1 )

REM PCRE
unzip .\dependencies\arch=%arch%,label=%label%\pcre*.zip -d .\dependencies\pcre
IF NOT %ERRORLEVEL% == 0 ( exit 1 )

REM Lua
unzip .\dependencies\arch=%arch%,label=%label%\lua*.zip -d .\dependencies\lua
IF NOT %ERRORLEVEL% == 0 ( exit 1 )

REM NGHttp2
unzip .\dependencies\arch=%arch%,label=%label%\nghttp2*.zip -d .\dependencies\nghttp2
IF NOT %ERRORLEVEL% == 0 ( exit 1 ) 

REM Patch CMakeLists.txt?
if exist ci-scripts\windows\httpd\httpd-%BRANCH_OR_TAG%_CMakeLists.txt.patch (
    patch.exe --verbose -p1 CMakeLists.txt -i ci-scripts\windows\httpd\httpd-%BRANCH_OR_TAG%_CMakeLists.txt.patch
)

REM Note that some attributes cannot handle backslashes...
SET WORKSPACE_POSSIX=%WORKSPACE:\=/%


REM CMake worksapce
mkdir %WORKSPACE%\cmakebuild

REM httpd build install directory
mkdir %WORKSPACE%\target
SET "CMAKE_INSTALL_PREFIX=%WORKSPACE%\target"
SET "CMAKE_INSTALL_PREFIX_POSSIX=%CMAKE_INSTALL_PREFIX:\=/%"

cd %WORKSPACE%\cmakebuild

REM CMake. Beware: Command must be shorter than 8191 chars...
cmake -G "NMake Makefiles" -DOPENSSL_ROOT_DIR=%WORKSPACE_POSSIX%/dependencies/openssl -DLIBXML2_INCLUDE_DIR=%WORKSPACE_POSSIX%/dependencies/libxml2/include/libxml2/ -DLIBXML2_LIBRARIES=%WORKSPACE_POSSIX%/dependencies/libxml2/lib/libxml2.lib;%WORKSPACE_POSSIX%/dependencies/libxml2/lib/libxml2_a.lib;%WORKSPACE_POSSIX%/dependencies/libxml2/lib/libxml2_a_dll.lib -DLIBXML2_XMLLINT_EXECUTABLE=%WORKSPACE_POSSIX%/dependencies/libxml2/bin/xmllint.exe -DLIBXML2_ICONV_INCLUDE_DIR=%WORKSPACE_POSSIX%/dependencies/libxml2/include/ -DLIBXML2_ICONV_LIBRARIES=%WORKSPACE_POSSIX%/dependencies/libxml2/lib/libiconv.lib;%WORKSPACE_POSSIX%/dependencies/libxml2/lib/libcharset.lib -DZLIB_INCLUDE_DIRS=%WORKSPACE_POSSIX%/dependencies/zlib/include/ -DZLIB_LIBRARY=%WORKSPACE_POSSIX%/dependencies/zlib/z.lib -DAPR_INCLUDE_DIR=%WORKSPACE_POSSIX%/dependencies/apr/include/ -DAPR_LIBRARIES=%WORKSPACE_POSSIX%/dependencies/apr/lib/libapr-1.lib;%WORKSPACE_POSSIX%/dependencies/apr/lib/libaprapp-1.lib;%WORKSPACE_POSSIX%/dependencies/apr-util/lib/apr_crypto_openssl-1.lib;%WORKSPACE_POSSIX%/dependencies/apr-util/lib/apr_dbd_odbc-1.lib;%WORKSPACE_POSSIX%/dependencies/apr-util/lib/apr_ldap-1.lib;%WORKSPACE_POSSIX%/dependencies/apr-util/lib/libaprutil-1.lib -DEXTRA_INCLUDES=%WORKSPACE_POSSIX%/dependencies/apr-util/include/ -DAPU_HAVE_CRYPTO=ON -DAPR_HAS_XLATE=ON -DAPR_HAS_LDAP=ON -DPCRE_LIBRARIES=%WORKSPACE_POSSIX%/dependencies/pcre/lib/bz2.lib;%WORKSPACE_POSSIX%/dependencies/pcre/lib/pcrecppd.lib;%WORKSPACE_POSSIX%/dependencies/pcre/lib/pcred.lib;%WORKSPACE_POSSIX%/dependencies/pcre/lib/pcreposixd.lib -DPCRE_INCLUDE_DIR=%WORKSPACE_POSSIX%/dependencies/pcre/include/ -DLUA_LIBRARIES=%WORKSPACE_POSSIX%/dependencies/lua/lib/lua-v5-3-4.lib;%WORKSPACE_POSSIX%/dependencies/lua/lib/luac.lib -DLUA_INCLUDE_DIR=%WORKSPACE_POSSIX%/dependencies/lua/include/ -DNGHTTP2_LIBRARIES=%WORKSPACE_POSSIX%/dependencies/nghttp2/lib/nghttp2.lib -DNGHTTP2_INCLUDE_DIR=%WORKSPACE_POSSIX%/dependencies/nghttp2/include/ -DCMAKE_INSTALL_PREFIX=%CMAKE_INSTALL_PREFIX_POSSIX% ..
IF NOT %ERRORLEVEL% == 0 ( exit 1 )
REM Compile
nmake
IF NOT %ERRORLEVEL% == 0 ( exit 1 )
REM Install
nmake install
IF NOT %ERRORLEVEL% == 0 ( exit 1 )
REM Copy all stuff to create a developer release.

mkdir %CMAKE_INSTALL_PREFIX%\licenses
copy /Y %CMAKE_INSTALL_PREFIX%\manual\LICENSE %CMAKE_INSTALL_PREFIX%\licenses\httpd-LICENSE

REM APR
copy /Y %WORKSPACE%\dependencies\apr\bin\*.dll %CMAKE_INSTALL_PREFIX%\bin\
copy /Y %WORKSPACE%\dependencies\apr\bin\*.pdb %CMAKE_INSTALL_PREFIX%\bin\
copy /Y %WORKSPACE%\dependencies\apr\lib\*.lib %CMAKE_INSTALL_PREFIX%\lib\
mkdir %CMAKE_INSTALL_PREFIX%\include\apr
copy /Y %WORKSPACE%\dependencies\apr\include\* %CMAKE_INSTALL_PREFIX%\include\apr\
copy /Y %WORKSPACE%\dependencies\apr\LICENSE %CMAKE_INSTALL_PREFIX%\licenses\apr-LICENSE
copy /Y %WORKSPACE%\dependencies\apr\NOTICE %CMAKE_INSTALL_PREFIX%\licenses\apr-NOTICE

REM APR Util
copy /Y %WORKSPACE%\dependencies\apr-util\bin\*.dll %CMAKE_INSTALL_PREFIX%\bin\
copy /Y %WORKSPACE%\dependencies\apr-util\bin\*.pdb %CMAKE_INSTALL_PREFIX%\bin\
copy /Y %WORKSPACE%\dependencies\apr-util\lib\*.lib %CMAKE_INSTALL_PREFIX%\lib\
copy /Y %WORKSPACE%\dependencies\apr-util\include\* %CMAKE_INSTALL_PREFIX%\include\apr\

REM PCRE
copy /Y %WORKSPACE%\dependencies\pcre\bin\*.dll %CMAKE_INSTALL_PREFIX%\bin\
copy /Y %WORKSPACE%\dependencies\pcre\bin\*.exe %CMAKE_INSTALL_PREFIX%\bin\
copy /Y %WORKSPACE%\dependencies\pcre\bin\*.pdb %CMAKE_INSTALL_PREFIX%\bin\
copy /Y %WORKSPACE%\dependencies\pcre\lib\*.lib %CMAKE_INSTALL_PREFIX%\lib\
mkdir %CMAKE_INSTALL_PREFIX%\include\pcre
copy /Y %WORKSPACE%\dependencies\pcre\include\* %CMAKE_INSTALL_PREFIX%\include\pcre\
copy /Y %WORKSPACE%\dependencies\pcre\LICENSE %CMAKE_INSTALL_PREFIX%\licenses\pcre-LICENSE
copy /Y %WORKSPACE%\dependencies\pcre\COPYING %CMAKE_INSTALL_PREFIX%\licenses\pcre-COPYING

REM LibXML2
copy /Y %WORKSPACE%\dependencies\libxml2\bin\*.dll %CMAKE_INSTALL_PREFIX%\bin\
copy /Y %WORKSPACE%\dependencies\libxml2\bin\*.exe %CMAKE_INSTALL_PREFIX%\bin\
copy /Y %WORKSPACE%\dependencies\libxml2\bin\*.pdb %CMAKE_INSTALL_PREFIX%\bin\
copy /Y %WORKSPACE%\dependencies\libxml2\lib\*.lib %CMAKE_INSTALL_PREFIX%\lib\
mkdir %CMAKE_INSTALL_PREFIX%\include\libxml2
copy /Y %WORKSPACE%\dependencies\libxml2\include\* %CMAKE_INSTALL_PREFIX%\include\libxml2\
copy /Y %WORKSPACE%\dependencies\libxml2\Copyright %CMAKE_INSTALL_PREFIX%\licenses\libxml2-Copyright

REM nghttp2
copy /Y %WORKSPACE%\dependencies\nghttp2\lib\*.dll %CMAKE_INSTALL_PREFIX%\bin\
copy /Y %WORKSPACE%\dependencies\nghttp2\lib\*.pdb %CMAKE_INSTALL_PREFIX%\bin\
copy /Y %WORKSPACE%\dependencies\nghttp2\lib\*.lib %CMAKE_INSTALL_PREFIX%\lib\
mkdir %CMAKE_INSTALL_PREFIX%\include\nghttp2
copy /Y %WORKSPACE%\dependencies\nghttp2\include\nghttp2\* %CMAKE_INSTALL_PREFIX%\include\nghttp2\
copy /Y %WORKSPACE%\dependencies\nghttp2\share\doc\nghttp2\README.rst %CMAKE_INSTALL_PREFIX%\licenses\nghttp2-README.rst

REM Lua
copy /Y %WORKSPACE%\dependencies\lua\bin\*.dll %CMAKE_INSTALL_PREFIX%\bin\
copy /Y %WORKSPACE%\dependencies\lua\bin\*.exe %CMAKE_INSTALL_PREFIX%\bin\
copy /Y %WORKSPACE%\dependencies\lua\bin\*.pdb %CMAKE_INSTALL_PREFIX%\lib\
copy /Y %WORKSPACE%\dependencies\lua\lib\*.lib %CMAKE_INSTALL_PREFIX%\lib\
mkdir %CMAKE_INSTALL_PREFIX%\include\lua
copy /Y %WORKSPACE%\dependencies\lua\include\* %CMAKE_INSTALL_PREFIX%\include\lua\
copy /Y %WORKSPACE%\dependencies\lua\license.html %CMAKE_INSTALL_PREFIX%\licenses\lua-license.html

REM OpenSSL
copy /Y %WORKSPACE%\dependencies\openssl\bin\*.dll %CMAKE_INSTALL_PREFIX%\bin\
copy /Y %WORKSPACE%\dependencies\openssl\bin\*.exe %CMAKE_INSTALL_PREFIX%\bin\
copy /Y %WORKSPACE%\dependencies\openssl\bin\*.pdb %CMAKE_INSTALL_PREFIX%\bin\
copy /Y %WORKSPACE%\dependencies\openssl\lib\*.lib %CMAKE_INSTALL_PREFIX%\lib\
copy /Y %WORKSPACE%\dependencies\openssl\lib\*.pdb %CMAKE_INSTALL_PREFIX%\lib\
mkdir %CMAKE_INSTALL_PREFIX%\lib\engines
copy /Y %WORKSPACE%\dependencies\openssl\lib\engines\* %CMAKE_INSTALL_PREFIX%\lib\engines\
mkdir %CMAKE_INSTALL_PREFIX%\include\openssl
copy /Y %WORKSPACE%\dependencies\openssl\include\openssl\* %CMAKE_INSTALL_PREFIX%\include\openssl\
mkdir %CMAKE_INSTALL_PREFIX%\conf\ssl
copy /Y %WORKSPACE%\dependencies\openssl\ssl\* %CMAKE_INSTALL_PREFIX%\conf\ssl
copy /Y %WORKSPACE%\dependencies\openssl\LICENSE %CMAKE_INSTALL_PREFIX%\licenses\openssl-LICENSE

REM ZLib (also part of LibXML2 - must be kept in sync)
copy /Y %WORKSPACE%\dependencies\zlib\*.dll %CMAKE_INSTALL_PREFIX%\bin\
copy /Y %WORKSPACE%\dependencies\zlib\*.exe %CMAKE_INSTALL_PREFIX%\bin\
copy /Y %WORKSPACE%\dependencies\zlib\*.pdb %CMAKE_INSTALL_PREFIX%\bin\
copy /Y %WORKSPACE%\dependencies\zlib\*.lib %CMAKE_INSTALL_PREFIX%\lib\
mkdir %CMAKE_INSTALL_PREFIX%\include\zlib
copy /Y %WORKSPACE%\dependencies\zlib\include\* %CMAKE_INSTALL_PREFIX%\include\zlib\
copy /Y %WORKSPACE%\dependencies\zlib\*.h %CMAKE_INSTALL_PREFIX%\include\zlib\
copy /Y %WORKSPACE%\dependencies\zlib\README %CMAKE_INSTALL_PREFIX%\licenses\zlib-README


REM Symlinks to satisfy different lookups in libraries. This could be probably fixed... (TODO)
pushd %CMAKE_INSTALL_PREFIX%\bin
mklink zlib.dll z.dll
mklink iconv.dll libiconv.dll
popd

REM Substitute paths in files so as to be configurable by postinstall
powershell -Command "get-childitem %CMAKE_INSTALL_PREFIX% -include *.conf,*.cnf,*.html.* -recurse | ForEach {(Get-Content $_ | ForEach { $_ -replace '%CMAKE_INSTALL_PREFIX:\=/%', '@HTTPD_SERVER_ROOT_POSIX@'}) | Set-Content -Encoding ascii $_ }"
mkdir %CMAKE_INSTALL_PREFIX%\cache
powershell -Command "(gc %CMAKE_INSTALL_PREFIX%\conf\extra\proxy-html.conf) -replace 'C:/path/', '@HTTPD_SERVER_ROOT_POSIX@/bin/' | Out-File -Encoding ascii %CMAKE_INSTALL_PREFIX%\conf\extra\proxy-html.conf"
powershell -Command "(gc %CMAKE_INSTALL_PREFIX%\conf\extra\httpd-ssl.conf) -replace ':/ssl_scache', ':@HTTPD_SERVER_ROOT_POSIX@/cache/ssl_scache' | Out-File -Encoding ascii %CMAKE_INSTALL_PREFIX%\conf\extra\httpd-ssl.conf"
powershell -Command "(gc %CMAKE_INSTALL_PREFIX%\conf\extra\httpd-ssl.conf) -replace '/error_log', 'logs/ssl_error_log' | Out-File -Encoding ascii %CMAKE_INSTALL_PREFIX%\conf\extra\httpd-ssl.conf"
powershell -Command "(gc %CMAKE_INSTALL_PREFIX%\conf\extra\httpd-ssl.conf) -replace '/access_log', 'logs/ssl_access_log' | Out-File -Encoding ascii %CMAKE_INSTALL_PREFIX%\conf\extra\httpd-ssl.conf"
powershell -Command "(gc %CMAKE_INSTALL_PREFIX%\conf\extra\httpd-ssl.conf) -replace '/ssl_request_log', 'logs/ssl_request_log' | Out-File -Encoding ascii %CMAKE_INSTALL_PREFIX%\conf\extra\httpd-ssl.conf"
powershell -Command "(gc %CMAKE_INSTALL_PREFIX%\conf\extra\httpd-ssl.conf) -replace '/server.crt', '@HTTPD_SERVER_ROOT_POSIX@/conf/ssl/certs/localhost.crt' | Out-File -Encoding ascii %CMAKE_INSTALL_PREFIX%\conf\extra\httpd-ssl.conf"
powershell -Command "(gc %CMAKE_INSTALL_PREFIX%\conf\extra\httpd-ssl.conf) -replace '/server.key', '@HTTPD_SERVER_ROOT_POSIX@/conf/ssl/private/localhost.key' | Out-File -Encoding ascii %CMAKE_INSTALL_PREFIX%\conf\extra\httpd-ssl.conf"

REM Add custom It works! HTML page.
powershell -Command "(gc %CMAKE_INSTALL_PREFIX%\htdocs\index.html) -replace '</body>', '<p>Packaged by https://ci.modcluster.io/<br>Maintainer: Michal Karm Babacek &lt;karm@fedoraproject.org&gt;</p></body>' | Out-File -Encoding ascii %CMAKE_INSTALL_PREFIX%\htdocs\index.html"

REM Add a custom README file
copy /Y %WORKSPACE%\ci-scripts\windows\httpd\README.md %CMAKE_INSTALL_PREFIX%\README.md

REM Add postinstall file
copy /Y %WORKSPACE%\ci-scripts\windows\httpd\postinstall.bat %CMAKE_INSTALL_PREFIX%\postinstall.bat

REM Generate "BOM", append at the end of README.md
powershell -Command "$files = Get-ChildItem %WORKSPACE%\dependencies\arch=%arch%,label=%label%\;foreach($file in $files){Add-Content %CMAKE_INSTALL_PREFIX%\README.md \" * $($file.Name -ireplace '(.*)\.zip', '$1')\" ;}"
echo ## VC Runtime dependency>> %CMAKE_INSTALL_PREFIX%\README.md
powershell -Command "$cmd='dumpbin.exe /dependents %CMAKE_INSTALL_PREFIX%\bin\httpd.exe';Add-Content %CMAKE_INSTALL_PREFIX%\README.md \" * $($(iex $cmd) -match 'VCRUN')\" ;"

REM Package the big, devel package
pushd %CMAKE_INSTALL_PREFIX%
SET HTTPD_DEVEL_ZIP_PATH=%WORKSPACE%\httpd-%BRANCH_OR_TAG%-win.%arch%-devel.zip
zip -r -9 %HTTPD_DEVEL_ZIP_PATH% .
popd


REM
REM Smoke test devel package - vanilla
REM
mkdir %WORKSPACE%\tmp\
pushd %WORKSPACE%\tmp\
unzip %HTTPD_DEVEL_ZIP_PATH%
dir
call postinstall.bat
set HTTPD_SERVER_ROOT=%cd%
pushd %WORKSPACE%\tmp\bin
start cmd /C httpd.exe
powershell -Command "Start-Sleep -s 1"
ab.exe http://localhost:80/
IF NOT %ERRORLEVEL% == 0 ( exit 1 )
powershell -Command "for ($j=0; $j -lt 100; $j++) {$url = 'https://localhost:443'; $web = New-Object Net.WebClient; [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }; $output = $web.DownloadString($url); [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null; if ($output -like '*It works*') { echo 'ok' } else { exit 1 }}; exit 0"
IF NOT %ERRORLEVEL% == 0 ( exit 1 )
taskkill /im httpd.exe /F
powershell -Command "if(@( Get-Content %HTTPD_SERVER_ROOT%\logs\error_log | Where-Object { $_.Contains('error') -or $_.Contains('fault') -or $_.Contains('mismatch') } ).Count -gt 0) { exit 1 } else {exit 0 }"
IF NOT %ERRORLEVEL% == 0 ( exit 1 )

REM Smoke test devel package - all modules
powershell -Command "(gc %HTTPD_SERVER_ROOT%\conf\httpd.conf) -replace '#Include conf/extra/', 'Include conf/extra/' | Out-File -encoding ascii %HTTPD_SERVER_ROOT%\conf\httpd.conf"
powershell -Command "(gc %HTTPD_SERVER_ROOT%\conf\httpd.conf) -replace '# LoadModule', 'LoadModule' | Out-File -encoding ascii %HTTPD_SERVER_ROOT%\conf\httpd.conf"
powershell -Command "(gc %HTTPD_SERVER_ROOT%\conf\httpd.conf) -replace '#LoadModule foo_module', '# LoadModule foo_module' | Out-File -encoding ascii %HTTPD_SERVER_ROOT%\conf\httpd.conf"
mkdir %HTTPD_SERVER_ROOT%\docs\dummy-host.example.com
mkdir %HTTPD_SERVER_ROOT%\docs\dummy-host2.example.com
start cmd /C httpd.exe
powershell -Command "Start-Sleep -s 1"
ab.exe http://localhost:80/
IF NOT %ERRORLEVEL% == 0 ( exit 1 )
powershell -Command "for ($j=0; $j -lt 100; $j++) {$url = 'https://localhost:443'; $web = New-Object Net.WebClient; [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }; $output = $web.DownloadString($url); [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null; if ($output -like '*It works*') { echo 'ok' } else { exit 1 }}; exit 0"
IF NOT %ERRORLEVEL% == 0 ( exit 1 )
taskkill /im httpd.exe /F
powershell -Command "if(@( Get-Content %HTTPD_SERVER_ROOT%\logs\error_log | Where-Object { $_.Contains('error') -or $_.Contains('fault') -or $_.Contains('mismatch') } ).Count -gt 0) { exit 1 } else {exit 0 }"
IF NOT %ERRORLEVEL% == 0 ( exit 1 )
popd
popd


REM Prepare trimmed package
mkdir %WORKSPACE%\target-trimmed\
pushd %WORKSPACE%\target-trimmed\
unzip %HTTPD_DEVEL_ZIP_PATH%
rmdir /s /q conf\original
rmdir /s /q include
powershell -Command "get-childitem . -include *.pdb,test*.exe,*test.exe,runsuite*,*.lib,*.exp -recurse | ForEach {(Remove-Item $_)}"
SET HTTPD_ZIP_PATH=%WORKSPACE%\httpd-%BRANCH_OR_TAG%-win.%arch%.zip
zip -r -9 %HTTPD_ZIP_PATH% .
popd


REM TODO: This testing repeats, put it in a function...
REM Smoke test trimmed package - vanilla
REM
mkdir %WORKSPACE%\tmp-trimmed\
pushd %WORKSPACE%\tmp-trimmed\
unzip %HTTPD_ZIP_PATH%
call postinstall.bat
set HTTPD_SERVER_ROOT=%cd%
pushd %WORKSPACE%\tmp-trimmed\bin
start cmd /C httpd.exe
powershell -Command "Start-Sleep -s 1"
ab.exe http://localhost:80/
IF NOT %ERRORLEVEL% == 0 ( exit 1 )
powershell -Command "for ($j=0; $j -lt 100; $j++) {$url = 'https://localhost:443'; $web = New-Object Net.WebClient; [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }; $output = $web.DownloadString($url); [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null; if ($output -like '*It works*') { echo 'ok' } else { exit 1 }}; exit 0"
IF NOT %ERRORLEVEL% == 0 ( exit 1 )
taskkill /im httpd.exe /F
powershell -Command "if(@( Get-Content %HTTPD_SERVER_ROOT%\logs\error_log | Where-Object { $_.Contains('error') -or $_.Contains('fault') -or $_.Contains('mismatch') } ).Count -gt 0) { exit 1 } else {exit 0 }"
IF NOT %ERRORLEVEL% == 0 ( exit 1 )

REM Smoke test trimmed package - all modules
powershell -Command "(gc %HTTPD_SERVER_ROOT%\conf\httpd.conf) -replace '#Include conf/extra/', 'Include conf/extra/' | Out-File -encoding ascii %HTTPD_SERVER_ROOT%\conf\httpd.conf"
powershell -Command "(gc %HTTPD_SERVER_ROOT%\conf\httpd.conf) -replace '# LoadModule', 'LoadModule' | Out-File -encoding ascii %HTTPD_SERVER_ROOT%\conf\httpd.conf"
powershell -Command "(gc %HTTPD_SERVER_ROOT%\conf\httpd.conf) -replace '#LoadModule foo_module', '# LoadModule foo_module' | Out-File -encoding ascii %HTTPD_SERVER_ROOT%\conf\httpd.conf"
mkdir %HTTPD_SERVER_ROOT%\docs\dummy-host.example.com
mkdir %HTTPD_SERVER_ROOT%\docs\dummy-host2.example.com
start cmd /C httpd.exe
powershell -Command "Start-Sleep -s 1"
ab.exe http://localhost:80/
IF NOT %ERRORLEVEL% == 0 ( exit 1 )
powershell -Command "for ($j=0; $j -lt 100; $j++) {$url = 'https://localhost:443'; $web = New-Object Net.WebClient; [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }; $output = $web.DownloadString($url); [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null; if ($output -like '*It works*') { echo 'ok' } else { exit 1 }}; exit 0"
IF NOT %ERRORLEVEL% == 0 ( exit 1 )
taskkill /im httpd.exe /F
powershell -Command "if(@( Get-Content %HTTPD_SERVER_ROOT%\logs\error_log | Where-Object { $_.Contains('error') -or $_.Contains('fault') -or $_.Contains('mismatch') } ).Count -gt 0) { exit 1 } else {exit 0 }"
IF NOT %ERRORLEVEL% == 0 ( exit 1 )
popd
popd

REM Checksum, SHA1
sha1sum.exe %HTTPD_DEVEL_ZIP_PATH%>%HTTPD_DEVEL_ZIP_PATH%.sha1
sha1sum.exe %HTTPD_ZIP_PATH%>%HTTPD_ZIP_PATH%.sha1

echo Done