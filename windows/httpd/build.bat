REM Build environment
set "PATH=C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build;C:\Program Files\Cppcheck;%PATH%"
call vcvars64

REM Dependencies
REM We rely on label being the same. It is probably for the best, gonna keep the same MSVC...

REM OpenSSL
unzip .\dependencies\label=%label%\OpenSSL*.zip -d .\dependencies\openssl
IF NOT %ERRORLEVEL% == 0 ( exit 1 )

REM LibXML2
unzip .\dependencies\label=%label%\libxml2*.zip -d .\dependencies\libxml2
IF NOT %ERRORLEVEL% == 0 ( exit 1 )

REM ZLib
unzip .\dependencies\label=%label%\zlib*.zip -d .\dependencies\zlib
IF NOT %ERRORLEVEL% == 0 ( exit 1 )

REM APR
unzip .\dependencies\label=%label%\apr-1*.zip -d .\dependencies\apr
IF NOT %ERRORLEVEL% == 0 ( exit 1 )

REM APR Util
unzip .\dependencies\label=%label%\apr-util-1*.zip -d .\dependencies\apr-util
IF NOT %ERRORLEVEL% == 0 ( exit 1 )

REM BZIP2
unzip .\dependencies\label=%label%\bzip2* -d .\dependencies\bzip2
IF NOT %ERRORLEVEL% == 0 ( exit 1 )

REM Expat
unzip .\dependencies\label=%label%\libexpat* -d .\dependencies\libexpat
IF NOT %ERRORLEVEL% == 0 ( exit 1 )

REM PCRE
unzip .\dependencies\label=%label%\pcre*.zip -d .\dependencies\pcre
IF NOT %ERRORLEVEL% == 0 ( exit 1 )

REM Lua
unzip .\dependencies\label=%label%\lua*.zip -d .\dependencies\lua
IF NOT %ERRORLEVEL% == 0 ( exit 1 )

REM NGHttp2
unzip .\dependencies\label=%label%\nghttp2*.zip -d .\dependencies\nghttp2
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
mkdir %WORKSPACE%\httpd-%BRANCH_OR_TAG%
SET "CMAKE_INSTALL_PREFIX=%WORKSPACE%\httpd-%BRANCH_OR_TAG%"
SET "CMAKE_INSTALL_PREFIX_POSSIX=%CMAKE_INSTALL_PREFIX:\=/%"

cd %WORKSPACE%\cmakebuild

REM -DLIBXML2_ICONV_INCLUDE_DIR=%WORKSPACE_POSSIX%/dependencies/libxml2/include/ ^
REM -DLIBXML2_ICONV_LIBRARIES=%WORKSPACE_POSSIX%/dependencies/libxml2/lib/libiconv.lib;%WORKSPACE_POSSIX%/dependencies/libxml2/lib/libcharset.lib ^

REM CMake. Beware: Command must be shorter than 8191 chars...
cmake -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=RELWITHDEBINFO ^
-DCMAKE_C_FLAGS_RELWITHDEBINFO="/DWIN32 /D_WINDOWS /W3 /MD /Zi /O2 /Ob1 /DNDEBUG" ^
-DCMAKE_C_FLAGS="/DWIN32 /D_WINDOWS /W3 /MD /Zi /O2 /Ob1 /DNDEBUG" ^
-DOPENSSL_ROOT_DIR=%WORKSPACE_POSSIX%/dependencies/openssl ^
-DLIBXML2_INCLUDE_DIR=%WORKSPACE_POSSIX%/dependencies/libxml2/include/libxml2/ ^
-DLIBXML2_LIBRARIES=%WORKSPACE_POSSIX%/dependencies/libxml2/lib/libxml2.lib;%WORKSPACE_POSSIX%/dependencies/libxml2/lib/libxml2_a.lib;^
%WORKSPACE_POSSIX%/dependencies/libxml2/lib/libxml2_a_dll.lib ^
-DLIBXML2_XMLLINT_EXECUTABLE=%WORKSPACE_POSSIX%/dependencies/libxml2/bin/xmllint.exe ^
-DZLIB_INCLUDE_DIRS=%WORKSPACE_POSSIX%/dependencies/zlib/include/ -DZLIB_LIBRARY=%WORKSPACE_POSSIX%/dependencies/zlib/lib/zlib.lib ^
-DAPR_INCLUDE_DIR=%WORKSPACE_POSSIX%/dependencies/apr/include/ ^
-DAPR_LIBRARIES=%WORKSPACE_POSSIX%/dependencies/apr/lib/libapr-1.lib;%WORKSPACE_POSSIX%/dependencies/apr/lib/libaprapp-1.lib;^
%WORKSPACE_POSSIX%/dependencies/apr-util/lib/apr_crypto_openssl-1.lib;%WORKSPACE_POSSIX%/dependencies/apr-util/lib/apr_dbd_odbc-1.lib;^
%WORKSPACE_POSSIX%/dependencies/apr-util/lib/apr_ldap-1.lib;%WORKSPACE_POSSIX%/dependencies/apr-util/lib/libaprutil-1.lib ^
-DEXTRA_INCLUDES=%WORKSPACE_POSSIX%/dependencies/apr-util/include/ ^
-DAPU_HAVE_CRYPTO=ON ^
-DAPR_HAS_XLATE=ON ^
-DAPR_HAS_LDAP=ON ^
-DINSTALL_PDB=ON ^
-DPCRE_LIBRARIES=%WORKSPACE_POSSIX%/dependencies/bzip2/bz2.lib;%WORKSPACE_POSSIX%/dependencies/pcre/lib/pcre.lib;^
%WORKSPACE_POSSIX%/dependencies/pcre/lib/pcrecpp.lib;%WORKSPACE_POSSIX%/dependencies/pcre/lib/pcreposix.lib ^
-DPCRE_INCLUDE_DIR=%WORKSPACE_POSSIX%/dependencies/pcre/include/ -DLUA_LIBRARIES=%WORKSPACE_POSSIX%/dependencies/lua/lib/lua-v5-3-4.lib;^
%WORKSPACE_POSSIX%/dependencies/lua/lib/luac.lib -DLUA_INCLUDE_DIR=%WORKSPACE_POSSIX%/dependencies/lua/include/ ^
-DNGHTTP2_LIBRARIES=%WORKSPACE_POSSIX%/dependencies/nghttp2/lib/nghttp2.lib -DNGHTTP2_INCLUDE_DIR=%WORKSPACE_POSSIX%/dependencies/nghttp2/include/ ^
-DCMAKE_INSTALL_PREFIX=%CMAKE_INSTALL_PREFIX_POSSIX% ..

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
copy /Y %WORKSPACE%\dependencies\zlib\bin\*.dll %CMAKE_INSTALL_PREFIX%\bin\
copy /Y %WORKSPACE%\dependencies\zlib\bin\*.pdb %CMAKE_INSTALL_PREFIX%\bin\
copy /Y %WORKSPACE%\dependencies\zlib\lib\*.lib %CMAKE_INSTALL_PREFIX%\lib\
mkdir %CMAKE_INSTALL_PREFIX%\include\zlib
copy /Y %WORKSPACE%\dependencies\zlib\include\* %CMAKE_INSTALL_PREFIX%\include\zlib\
copy /Y %WORKSPACE%\dependencies\zlib\README %CMAKE_INSTALL_PREFIX%\licenses\zlib-README

REM BZip (also part of LibXML2 - must be kept in sync)
copy /Y %WORKSPACE%\dependencies\bzip2\*.dll %CMAKE_INSTALL_PREFIX%\bin\
copy /Y %WORKSPACE%\dependencies\bzip2\*.exe %CMAKE_INSTALL_PREFIX%\bin\
copy /Y %WORKSPACE%\dependencies\bzip2\*.exp %CMAKE_INSTALL_PREFIX%\bin\
copy /Y %WORKSPACE%\dependencies\bzip2\*.pdb %CMAKE_INSTALL_PREFIX%\bin\
copy /Y %WORKSPACE%\dependencies\bzip2\*.lib %CMAKE_INSTALL_PREFIX%\lib\
mkdir %CMAKE_INSTALL_PREFIX%\include\bzip2
copy /Y %WORKSPACE%\dependencies\bzip2\include\* %CMAKE_INSTALL_PREFIX%\include\bzip2\
copy /Y %WORKSPACE%\dependencies\bzip2\LICENSE %CMAKE_INSTALL_PREFIX%\licenses\bzip2-LICENSE

REM Expat
copy /Y %WORKSPACE%\dependencies\libexpat\bin\*.dll %CMAKE_INSTALL_PREFIX%\bin\
copy /Y %WORKSPACE%\dependencies\libexpat\bin\*.exe %CMAKE_INSTALL_PREFIX%\bin\
copy /Y %WORKSPACE%\dependencies\libexpat\bin\*.pdb %CMAKE_INSTALL_PREFIX%\bin\
copy /Y %WORKSPACE%\dependencies\libexpat\lib\*.lib %CMAKE_INSTALL_PREFIX%\lib\
mkdir %CMAKE_INSTALL_PREFIX%\include\libexpat
copy /Y %WORKSPACE%\dependencies\libexpat\include\* %CMAKE_INSTALL_PREFIX%\include\libexpat\
copy /Y %WORKSPACE%\dependencies\libexpat\COPYING %CMAKE_INSTALL_PREFIX%\licenses\libexpat-COPYING

REM VCRUNTIME Debug (not contained in Visual Studio redistributables)
REM if "%arch%" equ "64" (
REM     copy /Y "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\redist\debug_nonredist\x64\Microsoft.VC140.DebugCRT\vcruntime140d.dll" %CMAKE_INSTALL_PREFIX%\bin\vcruntime140d.dll
REM     copy /Y "C:\Program Files (x86)\Windows Kits\10\bin\x64\ucrt\ucrtbased.dll" %CMAKE_INSTALL_PREFIX%\bin\ucrtbased.dll
REM ) else (
REM     copy /Y "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\redist\debug_nonredist\x86\Microsoft.VC140.DebugCRT\vcruntime140d.dll" %CMAKE_INSTALL_PREFIX%\bin\vcruntime140d.dll
REM     copy /Y "C:\Program Files (x86)\Windows Kits\10\bin\x86\ucrt\ucrtbased.dll" %CMAKE_INSTALL_PREFIX%\bin\ucrtbased.dll
REM )

REM Symlinks to satisfy different lookups in libraries. This could be probably fixed... (TODO)
REM TODO LIBBZ2.dll versus bz2.dll
REM pushd %CMAKE_INSTALL_PREFIX%\bin
REM mklink zlib.dll z.dll
REM mklink iconv.dll libiconv.dll
REM popd

REM Substitute paths in files so as to be configurable by postinstall
powershell -Command "get-childitem %CMAKE_INSTALL_PREFIX% -include *.conf,*.cnf,*.html.* -recurse | ForEach {(Get-Content $_ | ForEach { $_ -replace '%CMAKE_INSTALL_PREFIX:\=/%', '@HTTPD_SERVER_ROOT_POSIX@'}) | Set-Content -Encoding ascii $_ }"
IF NOT %ERRORLEVEL% == 0 ( exit 1 )
mkdir %CMAKE_INSTALL_PREFIX%\cache
powershell -Command "(gc %CMAKE_INSTALL_PREFIX%\conf\extra\proxy-html.conf) -replace 'C:/path/', '@HTTPD_SERVER_ROOT_POSIX@/bin/' | Out-File -Encoding ascii %CMAKE_INSTALL_PREFIX%\conf\extra\proxy-html.conf"
IF NOT %ERRORLEVEL% == 0 ( exit 1 )
powershell -Command "(gc %CMAKE_INSTALL_PREFIX%\conf\extra\httpd-ssl.conf) -replace ':/ssl_scache', ':@HTTPD_SERVER_ROOT_POSIX@/cache/ssl_scache' | Out-File -Encoding ascii %CMAKE_INSTALL_PREFIX%\conf\extra\httpd-ssl.conf"
IF NOT %ERRORLEVEL% == 0 ( exit 1 )
REM In other words, if BRANCH_OR_TAG *contains* "2.4", execute the IF body...
if NOT "%BRANCH_OR_TAG%"=="%BRANCH_OR_TAG:2.4=%" (
    powershell -Command "(gc %CMAKE_INSTALL_PREFIX%\conf\extra\httpd-ssl.conf) -replace '/error_log', 'logs/ssl_error_log' | Out-File -Encoding ascii %CMAKE_INSTALL_PREFIX%\conf\extra\httpd-ssl.conf"
    IF NOT %ERRORLEVEL% == 0 ( exit 1 )
    powershell -Command "(gc %CMAKE_INSTALL_PREFIX%\conf\extra\httpd-ssl.conf) -replace '/access_log', 'logs/ssl_access_log' | Out-File -Encoding ascii %CMAKE_INSTALL_PREFIX%\conf\extra\httpd-ssl.conf"
    IF NOT %ERRORLEVEL% == 0 ( exit 1 )
    powershell -Command "(gc %CMAKE_INSTALL_PREFIX%\conf\extra\httpd-ssl.conf) -replace '/ssl_request_log', 'logs/ssl_request_log' | Out-File -Encoding ascii %CMAKE_INSTALL_PREFIX%\conf\extra\httpd-ssl.conf"
    IF NOT %ERRORLEVEL% == 0 ( exit 1 )
)
powershell -Command "(gc %CMAKE_INSTALL_PREFIX%\conf\extra\httpd-ssl.conf) -replace 'SSLCertificateFile .*', 'SSLCertificateFile @HTTPD_SERVER_ROOT_POSIX@/conf/ssl/certs/localhost.crt' | Out-File -Encoding ascii %CMAKE_INSTALL_PREFIX%\conf\extra\httpd-ssl.conf"
IF NOT %ERRORLEVEL% == 0 ( exit 1 )
powershell -Command "(gc %CMAKE_INSTALL_PREFIX%\conf\extra\httpd-ssl.conf) -replace 'SSLCertificateKeyFile .*', 'SSLCertificateKeyFile @HTTPD_SERVER_ROOT_POSIX@/conf/ssl/private/localhost.key' | Out-File -Encoding ascii %CMAKE_INSTALL_PREFIX%\conf\extra\httpd-ssl.conf"
IF NOT %ERRORLEVEL% == 0 ( exit 1 )

REM Add custom It works! HTML page.
powershell -Command "(gc %CMAKE_INSTALL_PREFIX%\htdocs\index.html) -replace '</body>', '<p>Packaged by https://ci.modcluster.io/<br>Maintainer: Michal Karm Babacek &lt;karm@fedoraproject.org&gt;</p></body>' | Out-File -Encoding ascii %CMAKE_INSTALL_PREFIX%\htdocs\index.html"
IF NOT %ERRORLEVEL% == 0 ( exit 1 )

REM Add a custom README file
copy /Y %WORKSPACE%\ci-scripts\windows\httpd\README.md %CMAKE_INSTALL_PREFIX%\README.md

REM Add postinstall file
copy /Y %WORKSPACE%\ci-scripts\windows\httpd\postinstall.bat %CMAKE_INSTALL_PREFIX%\postinstall.bat

REM Generate "BOM", append at the end of README.md
powershell -Command "$files = Get-ChildItem '%WORKSPACE%\dependencies\label=%label%\';foreach($file in $files){Add-Content %CMAKE_INSTALL_PREFIX%\README.md \" * $($file.Name -ireplace '(.*)\.zip', '$1')\" ;}"
IF NOT %ERRORLEVEL% == 0 ( exit 1 )
echo ## Compiler version>> %CMAKE_INSTALL_PREFIX%\README.md
REM powershell -Command "$cmd='dumpbin.exe /dependents %CMAKE_INSTALL_PREFIX%\bin\httpd.exe';Add-Content %CMAKE_INSTALL_PREFIX%\README.md \" * $($(iex $cmd) -match 'VCRUN')\" ;"
powershell -Command "$cmd='cl.exe 2>&1';Add-Content %CMAKE_INSTALL_PREFIX%\README.md \" * $($(iex $cmd) -match 'Version')\" ;"
REM IF NOT %ERRORLEVEL% == 0 ( exit 1 )

REM Visual Studio redistributables
REM Needed libraries will be downloaded and installed quietly.
REM Go to https://www.microsoft.com/en-us/download/details.aspx?id=53587 for more information
set downloadCommand= ^
$c = New-Object System.Net.WebClient; ^
if(@( Get-Content %CMAKE_INSTALL_PREFIX%\README.md ^| Where-Object { $_.Contains(' for x64') } ).Count -gt 0) { ^
 $url = 'https://download.microsoft.com/download/6/D/F/6DF3FF94-F7F9-4F0B-838C-A328D1A7D0EE/vc_redist.x64.exe'; $file = '%CMAKE_INSTALL_PREFIX%\bin\vc_redist.x64.exe'; ^
} else { ^
 $url = 'https://download.microsoft.com/download/6/D/F/6DF3FF94-F7F9-4F0B-838C-A328D1A7D0EE/vc_redist.x86.exe'; $file = '%CMAKE_INSTALL_PREFIX%\bin\vc_redist.x86.exe'; ^
} ^
$c.DownloadFile($url, $file);
powershell -Command "%downloadCommand%"

REM GIT_HEAD for branches such as trunk or 2.4.x
for /f %%x in ('pushd %WORKSPACE% ^& git log --pretty^=format:%%h -n 1 ^& popd') do set GIT_HEAD=%%x
echo GIT_HEAD: %GIT_HEAD%
IF "%HEADS_OR_TAGS%" equ "heads" (
    SET HTTPD_DEVEL_ZIP_PATH=%WORKSPACE%\httpd-%BRANCH_OR_TAG%-%GIT_HEAD%-win.64-devel.zip
    SET HTTPD_ZIP_PATH=%WORKSPACE%\httpd-%BRANCH_OR_TAG%-%GIT_HEAD%-win.64.zip
) ELSE (
    SET HTTPD_DEVEL_ZIP_PATH=%WORKSPACE%\httpd-%BRANCH_OR_TAG%-win.64-devel.zip
    SET HTTPD_ZIP_PATH=%WORKSPACE%\httpd-%BRANCH_OR_TAG%-win.64.zip
)

echo Package the big, devel package
pushd %WORKSPACE%
zip -r -9 %HTTPD_DEVEL_ZIP_PATH% httpd-%BRANCH_OR_TAG%
IF NOT %ERRORLEVEL% == 0 ( exit 1 )
popd


REM
echo Smoke test devel package - vanilla
REM
mkdir %WORKSPACE%\tmp\
pushd %WORKSPACE%\tmp\
unzip %HTTPD_DEVEL_ZIP_PATH%
IF NOT %ERRORLEVEL% == 0 ( echo "Unzip failed." & exit 1 )
pushd httpd-%BRANCH_OR_TAG%
dir
call postinstall.bat
set HTTPD_SERVER_ROOT=%cd%
pushd bin
start /B cmd /C httpd.exe
powershell -Command "Start-Sleep -s 1"
ab.exe http://localhost:80/
IF NOT %ERRORLEVEL% == 0 ( type %HTTPD_SERVER_ROOT%\logs\error_log & type %HTTPD_SERVER_ROOT%\logs\httpd_log & exit 1 )
powershell -Command "for ($j=0; $j -lt 1000; $j++) {$url = 'https://localhost:443'; $web = New-Object Net.WebClient; [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }; $output = $web.DownloadString($url); [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null; if ($output -like '*It works*') { echo 'ok' } else { exit 1 }}; exit 0"
IF NOT %ERRORLEVEL% == 0 ( type %HTTPD_SERVER_ROOT%\logs\error_log & exit 1 )
taskkill /im httpd.exe /F
powershell -Command "if(@( Get-Content %HTTPD_SERVER_ROOT%\logs\error_log | Where-Object { $_.Contains('error') -or $_.Contains('fault') -or $_.Contains('AH00427') -or $_.Contains('AH00428') -or $_.Contains('mismatch') } ).Count -gt 0) { exit 1 } else {exit 0 }"
IF NOT %ERRORLEVEL% == 0 ( type %HTTPD_SERVER_ROOT%\logs\error_log & exit 1 )

echo Wait 10s
powershell -Command "Start-Sleep -s 10"

echo Smoke test devel package - all modules
powershell -Command "(gc %HTTPD_SERVER_ROOT%\conf\httpd.conf) -replace '#Include conf/extra/', 'Include conf/extra/' | Out-File -encoding ascii %HTTPD_SERVER_ROOT%\conf\httpd.conf"
IF NOT %ERRORLEVEL% == 0 ( type %HTTPD_SERVER_ROOT%\logs\error_log & exit 1 )
powershell -Command "(gc %HTTPD_SERVER_ROOT%\conf\httpd.conf) -replace '# LoadModule', 'LoadModule' | Out-File -encoding ascii %HTTPD_SERVER_ROOT%\conf\httpd.conf"
IF NOT %ERRORLEVEL% == 0 ( type %HTTPD_SERVER_ROOT%\logs\error_log & exit 1 )
powershell -Command "(gc %HTTPD_SERVER_ROOT%\conf\httpd.conf) -replace 'LoadModule foo_module', '# LoadModule foo_module' | Out-File -encoding ascii %HTTPD_SERVER_ROOT%\conf\httpd.conf"
IF NOT %ERRORLEVEL% == 0 ( type %HTTPD_SERVER_ROOT%\logs\error_log & exit 1 )
powershell -Command "(gc %HTTPD_SERVER_ROOT%\conf\extra\httpd-policy.conf) -replace ' enforce', ' log' | Out-File -Encoding ascii %HTTPD_SERVER_ROOT%\conf\extra\httpd-policy.conf"
IF NOT %ERRORLEVEL% == 0 ( type %HTTPD_SERVER_ROOT%\logs\error_log & exit 1 )
mkdir %HTTPD_SERVER_ROOT%\docs\dummy-host.example.com
mkdir %HTTPD_SERVER_ROOT%\docs\dummy-host2.example.com
start /B cmd /C httpd.exe
powershell -Command "Start-Sleep -s 1"
ab.exe http://localhost:80/
IF NOT %ERRORLEVEL% == 0 ( type %HTTPD_SERVER_ROOT%\logs\error_log & exit 1 )
powershell -Command "for ($j=0; $j -lt 1000; $j++) {$url = 'https://localhost:443'; $web = New-Object Net.WebClient; [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }; $output = $web.DownloadString($url); [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null; if ($output -like '*It works*') { echo 'ok' } else { exit 1 }}; exit 0"
IF NOT %ERRORLEVEL% == 0 ( type %HTTPD_SERVER_ROOT%\logs\error_log & exit 1 )
taskkill /im httpd.exe /F
powershell -Command "if(@( Get-Content %HTTPD_SERVER_ROOT%\logs\error_log | Where-Object { $_.Contains('error') -or $_.Contains('fault') -or $_.Contains('AH00427') -or $_.Contains('AH00428') -or $_.Contains('mismatch') } ).Count -gt 0) { exit 1 } else {exit 0 }"
IF NOT %ERRORLEVEL% == 0 ( type %HTTPD_SERVER_ROOT%\logs\error_log & exit 1 )
popd
popd
popd

echo Wait 10s
powershell -Command "Start-Sleep -s 10"

echo Prepare trimmed package
mkdir %WORKSPACE%\httpd-%BRANCH_OR_TAG%-trimmed\
pushd %WORKSPACE%\httpd-%BRANCH_OR_TAG%-trimmed\
unzip %HTTPD_DEVEL_ZIP_PATH%
IF NOT %ERRORLEVEL% == 0 ( exit 1 )
rmdir /s /q conf\original
rmdir /s /q include
powershell -Command "get-childitem . -include *.pdb,test*.exe,*test.exe,runsuite*,*.lib,*.exp -recurse | ForEach {(Remove-Item $_)}"
zip -r -9 %HTTPD_ZIP_PATH% .
IF NOT %ERRORLEVEL% == 0 ( exit 1 )
popd


REM TODO: This testing repeats, put it in a function...
echo Smoke test trimmed package - vanilla
REM
mkdir %WORKSPACE%\tmp-trimmed\
pushd %WORKSPACE%\tmp-trimmed\
unzip %HTTPD_ZIP_PATH%
IF NOT %ERRORLEVEL% == 0 ( exit 1 )
pushd httpd-%BRANCH_OR_TAG%
call postinstall.bat
set HTTPD_SERVER_ROOT=%cd%
pushd bin
start /B cmd /C httpd.exe
powershell -Command "Start-Sleep -s 1"
ab.exe http://localhost:80/
IF NOT %ERRORLEVEL% == 0 ( type %HTTPD_SERVER_ROOT%\logs\error_log & exit 1 )
powershell -Command "for ($j=0; $j -lt 100; $j++) {$url = 'https://localhost:443'; $web = New-Object Net.WebClient; [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }; $output = $web.DownloadString($url); [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null; if ($output -like '*It works*') { echo 'ok' } else { exit 1 }}; exit 0"
IF NOT %ERRORLEVEL% == 0 ( type %HTTPD_SERVER_ROOT%\logs\error_log & exit 1 )
taskkill /im httpd.exe /F
powershell -Command "if(@( Get-Content %HTTPD_SERVER_ROOT%\logs\error_log | Where-Object { $_.Contains('error') -or $_.Contains('fault') -or $_.Contains('AH00427') -or $_.Contains('AH00428') -or $_.Contains('mismatch') } ).Count -gt 0) { exit 1 } else {exit 0 }"
IF NOT %ERRORLEVEL% == 0 ( type %HTTPD_SERVER_ROOT%\logs\error_log & exit 1 )

echo Wait 10s
powershell -Command "Start-Sleep -s 10"

echo Smoke test trimmed package - all modules
powershell -Command "(gc %HTTPD_SERVER_ROOT%\conf\httpd.conf) -replace '#Include conf/extra/', 'Include conf/extra/' | Out-File -encoding ascii %HTTPD_SERVER_ROOT%\conf\httpd.conf"
IF NOT %ERRORLEVEL% == 0 ( type %HTTPD_SERVER_ROOT%\logs\error_log & exit 1 )
powershell -Command "(gc %HTTPD_SERVER_ROOT%\conf\httpd.conf) -replace '# LoadModule', 'LoadModule' | Out-File -encoding ascii %HTTPD_SERVER_ROOT%\conf\httpd.conf"
IF NOT %ERRORLEVEL% == 0 ( type %HTTPD_SERVER_ROOT%\logs\error_log & exit 1 )
powershell -Command "(gc %HTTPD_SERVER_ROOT%\conf\httpd.conf) -replace 'LoadModule foo_module', '# LoadModule foo_module' | Out-File -encoding ascii %HTTPD_SERVER_ROOT%\conf\httpd.conf"
IF NOT %ERRORLEVEL% == 0 ( type %HTTPD_SERVER_ROOT%\logs\error_log & exit 1 )
powershell -Command "(gc %HTTPD_SERVER_ROOT%\conf\extra\httpd-policy.conf) -replace ' enforce', ' log' | Out-File -Encoding ascii %HTTPD_SERVER_ROOT%\conf\extra\httpd-policy.conf"
IF NOT %ERRORLEVEL% == 0 ( type %HTTPD_SERVER_ROOT%\logs\error_log & exit 1 )
mkdir %HTTPD_SERVER_ROOT%\docs\dummy-host.example.com
mkdir %HTTPD_SERVER_ROOT%\docs\dummy-host2.example.com
start /B cmd /C httpd.exe
powershell -Command "Start-Sleep -s 1"
ab.exe http://localhost:80/
IF NOT %ERRORLEVEL% == 0 ( type %HTTPD_SERVER_ROOT%\logs\error_log & exit 1 )
powershell -Command "for ($j=0; $j -lt 100; $j++) {$url = 'https://localhost:443'; $web = New-Object Net.WebClient; [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }; $output = $web.DownloadString($url); [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null; if ($output -like '*It works*') { echo 'ok' } else { exit 1 }}; exit 0"
IF NOT %ERRORLEVEL% == 0 ( type %HTTPD_SERVER_ROOT%\logs\error_log & exit 1 )
taskkill /im httpd.exe /F
powershell -Command "if(@( Get-Content %HTTPD_SERVER_ROOT%\logs\error_log | Where-Object { $_.Contains('error') -or $_.Contains('fault') -or $_.Contains('AH00427') -or $_.Contains('AH00428') -or $_.Contains('mismatch') } ).Count -gt 0) { exit 1 } else {exit 0 }"
IF NOT %ERRORLEVEL% == 0 ( type %HTTPD_SERVER_ROOT%\logs\error_log & exit 1 )
popd
popd
popd

REM Checksum, SHA1
sha1sum.exe %HTTPD_DEVEL_ZIP_PATH%>%HTTPD_DEVEL_ZIP_PATH%.sha1
sha1sum.exe %HTTPD_ZIP_PATH%>%HTTPD_ZIP_PATH%.sha1

REM Static analysis
IF "%RUN_STATIC_ANALYSIS%" equ "true" (
    REM use --force to expand all levels of all macros, kinda slow (single digit minutes even with such a small project)
    cppcheck --enable=all --inconclusive --std=c89  ^
    -I%WORKSPACEPOSSIX%/include/ ^
    -I%WORKSPACE_POSSIX%/dependencies/libxml2/include/ ^
    -I%WORKSPACE_POSSIX%/dependencies/zlib/include/ ^
    -I%WORKSPACE_POSSIX%/dependencies/apr/include/ ^
    -I%WORKSPACE_POSSIX%/dependencies/apr-util/include/ ^
    -I%WORKSPACE_POSSIX%/dependencies/lua/include/ ^
    -I%WORKSPACE_POSSIX%/dependencies/nghttp2/include/ ^
    -I%WORKSPACE_POSSIX%/dependencies/pcre/include/ ^
    -I%WORKSPACE_POSSIX%/dependencies/openssl/include/ ^
    -I%WORKSPACEPOSSIX%/bzip2/include/ ^
    --output-file=cppcheck.log %WORKSPACEPOSSIX%
)

echo Done
