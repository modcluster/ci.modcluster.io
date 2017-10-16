REM @author: Michal Karm Babacek <karm@fedoraproject.org>

REM This script is used to build and package mod_proxy_cluster modules for JBoss httpd and Apache Lounge httpd.

REM @echo off
SetLocal EnableDelayedExpansion

REM Build environment
set "PATH=C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build;C:\Program Files\Cppcheck;%PATH%"
call vcvars64

REM Dependencies
IF "%DISTRO%" equ "jboss" (
    REM We rely on label being the same. It is probably for the best, gonna keep the same MSVC...
    REM httpd
    del /s /f /q httpd-devel
    unzip .\httpd\arch=64,label=%label%\httpd*64-devel.zip -d httpd-devel
    IF NOT %ERRORLEVEL% == 0 ( exit 1 )
    del /s /f /q httpd-prod
    unzip .\httpd\arch=64,label=%label%\httpd*64.zip -d httpd-prod
    IF NOT %ERRORLEVEL% == 0 ( exit 1 )
) else (
    REM Fetch Apache Lounge Apache HTTP Server distribution
    if not exist httpd-%APACHE_LOUNGE_DISTRO_VERSION%-Win64-VC15.zip (
        powershell -Command "$c = New-Object System.Net.WebClient; $url = 'http://www.apachelounge.com/download/VC15/binaries/httpd-%APACHE_LOUNGE_DISTRO_VERSION%-Win64-VC15.zip'; $file = '%WORKSPACE%\httpd-%APACHE_LOUNGE_DISTRO_VERSION%-Win64-VC15.zip'; $c.DownloadFile($url, $file);"
    )
    del /s /f /q httpd-apache-lounge
    unzip httpd-%APACHE_LOUNGE_DISTRO_VERSION%-Win64-VC15.zip -d httpd-apache-lounge
    IF NOT %ERRORLEVEL% == 0 ( exit 1 )
)

REM Remove old artifacts
del /Q /F %WORKSPACE%\mod_proxy_cluster*.zip
del /Q /F %WORKSPACE%\mod_proxy_cluster*.zip.sha1

REM Note that some attributes cannot handle backslashes...
SET WORKSPACE_POSSIX=%WORKSPACE:\=/%

REM CMake workspace
del /s /f /q %WORKSPACE%\cmakebuild
mkdir %WORKSPACE%\cmakebuild
pushd %WORKSPACE%\cmakebuild

IF "%DISTRO%" equ "jboss" (
    for /f %%z in ('powershell -Command "get-childitem %WORKSPACE%\httpd-devel | Foreach-Object {$_ -replace 'httpd-(.*)','$1'}"') do set JBOSS_HTTPD_VERSION=%%z
    SET HTTPD_DEV_HOME=%WORKSPACE%\httpd-devel\httpd-!JBOSS_HTTPD_VERSION!
    copy /Y !HTTPD_DEV_HOME!\include\apr\* !HTTPD_DEV_HOME!\include\
) else (
    SET HTTPD_DEV_HOME=%WORKSPACE%\httpd-apache-lounge\Apache24
    REM It is not a good idea to try to generate the mod_proxy.lib file, so:

    copy /Y %WORKSPACE%\ci-scripts\windows\mod_proxy_cluster\apache_lounge_%APACHE_LOUNGE_DISTRO_VERSION%\win64\mod_proxy.lib !HTTPD_DEV_HOME!\lib\mod_proxy.lib

    REM dumpbin /exports /nologo /out:!HTTPD_DEV_HOME!\lib\mod_proxy.def.tmp !HTTPD_DEV_HOME!\modules\mod_proxy.so
    REM IF NOT %ERRORLEVEL% == 0 ( exit 1 )
    REM echo EXPORTS> !HTTPD_DEV_HOME!\lib\mod_proxy.def
    REM powershell -Command "(Get-Content !HTTPD_DEV_HOME!\lib\mod_proxy.def.tmp) ^| Foreach-Object {$_ -replace '.*\s(_?ap_proxy.*^|_?proxy_.*)$','$1'} ^| select-string -pattern '^^_?ap_proxy^|^^_?proxy_' ^| Add-Content !HTTPD_DEV_HOME!\lib\mod_proxy.def"
    REM IF NOT %ERRORLEVEL% == 0 ( exit 1 )
    REM lib /def:!HTTPD_DEV_HOME!\lib\mod_proxy.def /OUT:!HTTPD_DEV_HOME!\lib\mod_proxy.lib /MACHINE:X64 /NAME:mod_proxy.so
    REM IF NOT %ERRORLEVEL% == 0 ( exit 1 )

)

SET HTTPD_DEV_HOME_POSSIX=%HTTPD_DEV_HOME:\=/%

cmake -G "NMake Makefiles" ^
-DCMAKE_BUILD_TYPE=Release ^
-DAPR_LIBRARY=%HTTPD_DEV_HOME_POSSIX%/lib/libapr-1.lib ^
-DAPR_INCLUDE_DIR=%HTTPD_DEV_HOME_POSSIX%/include/ ^
-DAPACHE_INCLUDE_DIR=%HTTPD_DEV_HOME_POSSIX%/include/ ^
-DAPRUTIL_LIBRARY=%HTTPD_DEV_HOME_POSSIX%/lib/libaprutil-1.lib ^
-DAPRUTIL_INCLUDE_DIR=%HTTPD_DEV_HOME_POSSIX%/include/ ^
-DAPACHE_LIBRARY=%HTTPD_DEV_HOME_POSSIX%/lib/libhttpd.lib ^
-DPROXY_LIBRARY=%HTTPD_DEV_HOME_POSSIX%/lib/mod_proxy.lib ^
%WORKSPACE_POSSIX%/mod_proxy_cluster/native/

IF NOT %ERRORLEVEL% == 0 ( exit 1 )
REM Compile
nmake
IF NOT %ERRORLEVEL% == 0 ( exit 1 )

REM Build is done. Let's smoke test the modules:
REM TODO: It is hardly enough, we must start tomcats and carry out failover.
REM On the other hand, running the whole NOE TS is an overkill. This build job must be FAST.

REM Test

SET HTTPD_DEV_HOME_POSSIX=%HTTPD_DEV_HOME:\=/%
REM TODO: Merge these if-else branches as much as possible.
IF "%DISTRO%" equ "jboss" (
    REM We test with prod, not dev version of httpd
    SET HTTPD_DEV_HOME=%WORKSPACE%\httpd-prod\httpd-%JBOSS_HTTPD_VERSION%
    SET HTTPD_DEV_HOME_POSSIX=!HTTPD_DEV_HOME:\=/!
    copy /Y %WORKSPACE%\cmakebuild\modules\mod_*.so !HTTPD_DEV_HOME!\modules\
    copy /Y %WORKSPACE%\ci-scripts\windows\mod_proxy_cluster\mod_cluster.conf !HTTPD_DEV_HOME!\conf\extra\
    echo Include conf/extra/mod_cluster.conf>> !HTTPD_DEV_HOME!\conf\httpd.conf

    set "cfgcmd=!cfgcmd!(gc !HTTPD_DEV_HOME!\conf\httpd.conf) -replace '#\s*LoadModule proxy_module', 'LoadModule proxy_module' | Out-File -Encoding ascii !HTTPD_DEV_HOME!\conf\httpd.conf;"
    set "cfgcmd=!cfgcmd!(gc !HTTPD_DEV_HOME!\conf\httpd.conf) -replace '#\s*LoadModule proxy_ajp_module', 'LoadModule proxy_ajp_module' | Out-File -Encoding ascii !HTTPD_DEV_HOME!\conf\httpd.conf"
    powershell -Command "!cfgcmd!"
    pushd !HTTPD_DEV_HOME!
    call postinstall.bat
    popd
) else (
    copy /Y %WORKSPACE%\cmakebuild\modules\mod_*.so %HTTPD_DEV_HOME%\modules\
    copy /Y %WORKSPACE%\ci-scripts\windows\mod_proxy_cluster\mod_cluster.conf %HTTPD_DEV_HOME%\conf\extra\
    echo Include conf/extra/mod_cluster.conf>> %HTTPD_DEV_HOME%\conf\httpd.conf

    set "cfgcmd=(gc %HTTPD_DEV_HOME%\conf\extra\mod_cluster.conf) -replace '@HTTPD_SERVER_ROOT_POSIX@/cache', 'c:/Apache24/logs' | Out-File -Encoding ascii %HTTPD_DEV_HOME%\conf\extra\mod_cluster.conf;"
    set "cfgcmd=!cfgcmd!get-childitem %HTTPD_DEV_HOME% -include *.conf -recurse | ForEach {(Get-Content $_ | ForEach { $_ -replace 'c:/Apache24', '%HTTPD_DEV_HOME_POSSIX%'}) | Set-Content -Encoding ascii $_ };"
    set "cfgcmd=!cfgcmd!(gc %HTTPD_DEV_HOME%\conf\httpd.conf) -replace '#LoadModule proxy_module', 'LoadModule proxy_module' | Out-File -Encoding ascii %HTTPD_DEV_HOME%\conf\httpd.conf;"
    set "cfgcmd=!cfgcmd!(gc %HTTPD_DEV_HOME%\conf\httpd.conf) -replace '#LoadModule proxy_ajp_module', 'LoadModule proxy_ajp_module' | Out-File -Encoding ascii %HTTPD_DEV_HOME%\conf\httpd.conf"
    powershell -Command "!cfgcmd!"
)

pushd %HTTPD_DEV_HOME%\bin

start /B cmd /C httpd.exe -e Debug
REM If it doesn't start under 1 s, you are fired.
powershell -Command "Start-Sleep -s 1"
ab.exe http://localhost:80/
IF NOT %ERRORLEVEL% == 0 ( type %HTTPD_DEV_HOME%\logs\error_log & exit 1 )

REM Play fake worker node and send configuration messages to Apache HTTP Server
set testcommand= ^
$port=6666; ^
$remoteHost = 'localhost'; ^
$socket = new-object System.Net.Sockets.TcpClient($remoteHost, $port); ^
$stream = $socket.GetStream(); ^
$writer = new-object System.IO.StreamWriter($stream); ^
$writer.Write(\"CONFIG / HTTP/1.1`r`nHost: localhost`r`nContent-Length: 85`r`nUser-Agent: PowerShell`r`nConnection: Keep-Alive`r`n`r`nJVMRoute=fake-worker-1^&Host=127.0.0.1^&Maxattempts=100^&Port=8009^&Type=ajp^&ping=100\"); ^
$writer.Flush(); ^
$writer.Write(\"ENABLE-APP / HTTP/1.1`r`nHost: localhost`r`nContent-Length: 67`r`nUser-Agent: PowerShell`r`nConnection: Keep-Alive`r`n`r`nJVMRoute=fake-worker-1^&Alias=default-host^&Context=%%2ffake-webapp\"); ^
$writer.Flush(); ^
$writer.Write(\"STATUS / HTTP/1.1`r`nHost: localhost`r`nContent-Length: 33`r`nUser-Agent: PowerShell`r`nConnection: Keep-Alive`r`n`r`nJVMRoute=fake-worker-1^&Load=99\"); ^
$writer.Flush();
powershell -Command "%testcommand%"

REM Test that Apache HTTP Server registered this fake "worker"
powershell -Command "for ($j=0; $j -lt 10; $j++) {$url = 'http://localhost:6666/mod_cluster_manager'; $web = New-Object Net.WebClient; [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }; $output = $web.DownloadString($url); [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null; if ($output -like '*Node fake-worker-1*') { echo 'ok' } else { exit 1 }}; exit 0"
IF NOT %ERRORLEVEL% == 0 ( type %HTTPD_DEV_HOME%\logs\error_log & exit 1 )

taskkill /im httpd.exe /F

popd
popd

REM Get mod_proxy_cluster version for packaging and README
for /f %%z in ('powershell -Command "Get-Content %WORKSPACE%\mod_proxy_cluster\native\include\mod_proxy_cluster.h | Select-String '#define MOD_CLUSTER_EXPOSED_VERSION ""mod_cluster/([^^""]*)""""' -AllMatches | Foreach-Object {$_.Matches} | Foreach-Object {$_.Groups[1].Value}"') do set MOD_PROXY_CLUSTER_VERSION=%%z
echo %MOD_PROXY_CLUSTER_VERSION%

for /f %%x in ('pushd C:\httpd\mod_proxy_cluster ^& git log --pretty^=format:%%h -n 1 ^& popd') do set GIT_HEAD=%%x
echo %GIT_HEAD%

REM If we operate on SNAPSHOT version, we append GIT HEAD to the version string
SET MOD_PROXY_CLUSTER_VERSION=%MOD_PROXY_CLUSTER_VERSION:SNAPSHOT=SNAPSHOT-!GIT_HEAD!%
echo %MOD_PROXY_CLUSTER_VERSION%

REM Prepare the distribution
IF "%DISTRO%" equ "jboss" (
    SET DISTRO_TARGET_DIR=mod_proxy_cluster-%MOD_PROXY_CLUSTER_VERSION%-httpd-%JBOSS_HTTPD_VERSION%-win64
) else (
    SET DISTRO_TARGET_DIR=mod_proxy_cluster-%MOD_PROXY_CLUSTER_VERSION%-apachelounge-%APACHE_LOUNGE_DISTRO_VERSION%-Win64
)

mkdir %WORKSPACE%\%DISTRO_TARGET_DIR%\conf\extra
mkdir %WORKSPACE%\%DISTRO_TARGET_DIR%\modules
mkdir %WORKSPACE%\%DISTRO_TARGET_DIR%\include

copy /Y %WORKSPACE%\ci-scripts\windows\mod_proxy_cluster\mod_cluster.conf %WORKSPACE%\%DISTRO_TARGET_DIR%\conf\extra\
IF NOT %ERRORLEVEL% == 0 ( exit 1 )
copy /Y %WORKSPACE%\mod_proxy_cluster\lgpl.txt %WORKSPACE%\%DISTRO_TARGET_DIR%\LICENSE.txt
IF NOT %ERRORLEVEL% == 0 ( exit 1 )

IF "%DISTRO%" equ "jboss" (
    copy /Y %WORKSPACE%\ci-scripts\windows\mod_proxy_cluster\README_jboss_httpd.md %WORKSPACE%\%DISTRO_TARGET_DIR%\README.md
    IF NOT %ERRORLEVEL% == 0 ( exit 1 )
) else (
    copy /Y %WORKSPACE%\ci-scripts\windows\mod_proxy_cluster\README_apachelounge.md %WORKSPACE%\%DISTRO_TARGET_DIR%\README.md
    IF NOT %ERRORLEVEL% == 0 ( exit 1 )
)

echo ### Compatible with Apache HTTP Server>> %WORKSPACE%\%DISTRO_TARGET_DIR%\README.md
IF "%DISTRO%" equ "jboss" (
    echo JBoss build of Apache HTTP Server %JBOSS_HTTPD_VERSION% from https://ci.modcluster.io/job/httpd-windows/>> %WORKSPACE%\%DISTRO_TARGET_DIR%\README.md
) else (
    echo ApacheLounge HTTP Server %APACHE_LOUNGE_DISTRO_VERSION% from http://www.apachelounge.com/download>> %WORKSPACE%\%DISTRO_TARGET_DIR%\README.md
)

echo ### mod_proxy_cluster version>> %WORKSPACE%\%DISTRO_TARGET_DIR%\README.md
echo %MOD_PROXY_CLUSTER_VERSION%, Git HEAD: %GIT_HEAD%>> %WORKSPACE%\%DISTRO_TARGET_DIR%\README.md

echo ### Compiler version>> %WORKSPACE%\%DISTRO_TARGET_DIR%\README.md
powershell -Command "$cmd='cl.exe 2>&1';Add-Content %WORKSPACE%\%DISTRO_TARGET_DIR%\README.md \" * $($(iex $cmd) -match 'Version')\" ;"

copy /Y %WORKSPACE%\cmakebuild\modules\mod_*.pdb %WORKSPACE%\%DISTRO_TARGET_DIR%\modules\
copy /Y %WORKSPACE%\cmakebuild\modules\mod_*.lib %WORKSPACE%\%DISTRO_TARGET_DIR%\modules\
copy /Y %WORKSPACE%\cmakebuild\modules\mod_*.so %WORKSPACE%\%DISTRO_TARGET_DIR%\modules\

powershell -command "Get-Childitem '%WORKSPACE%/mod_proxy_cluster/native/' -recurse -filter '*.h' | Copy-Item -Destination '%WORKSPACE%\%DISTRO_TARGET_DIR%\include\'"

pushd %WORKSPACE%
zip -r -9 %DISTRO_TARGET_DIR%-devel.zip %DISTRO_TARGET_DIR%

del /Q /F %WORKSPACE%\%DISTRO_TARGET_DIR%\modules\*.pdb
del /Q /F %WORKSPACE%\%DISTRO_TARGET_DIR%\modules\*.lib
del /S /F /Q %WORKSPACE%\%DISTRO_TARGET_DIR%\include

zip -r -9 %DISTRO_TARGET_DIR%.zip %DISTRO_TARGET_DIR%

sha1sum.exe %DISTRO_TARGET_DIR%-devel.zip>%DISTRO_TARGET_DIR%-devel.zip.sha1
sha1sum.exe %DISTRO_TARGET_DIR%.zip>%DISTRO_TARGET_DIR%.zip.sha1

popd

IF "%RUN_STATIC_ANALYSIS%" equ "true" (
    REM use --force to expand all levels of all macros, kinda slow (single digit minutes even with such a small project)
    cppcheck --enable=all --inconclusive --std=c99 ^
    -I%HTTPD_DEV_HOME_POSSIX%/include/ ^
    -I%WORKSPACE_POSSIX%/mod_proxy_cluster/native/include/ ^
    --output-file=cppcheck.log %WORKSPACE_POSSIX%/mod_proxy_cluster/native/
)

tree /f /a
echo Done.
