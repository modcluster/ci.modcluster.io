REM @author: Michal Karm Babacek <karm@fedoraproject.org>
REM This script builds libxml2

REM unzip label=%label%\libiconv* -d .\libiconv
REM IF NOT %ERRORLEVEL% == 0 ( exit 1 )
unzip label=%label%\zlib* -d .\zlib
IF NOT %ERRORLEVEL% == 0 ( exit 1 )

REM Build environment
set "PATH=C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build;C:\Program Files\Cppcheck;%PATH%"
call vcvars64

REM TODO: For some reason, some? variables from config.msvc are not properly included, hence hard-coded patch.
C:\Users\Administrator\Tools\cmder\vendor\git-for-windows\usr\bin\patch.exe --verbose -p1 win32\Makefile.msvc -i C:\httpd\ci.modcluster.io\windows\libxml2\Makefile.msvc.CRUNTIME.patch

pushd win32

copy %WORKSPACE%\zlib\include\zlib.h             ..\include\
copy %WORKSPACE%\zlib\include\zconf.h            ..\include\
REM copy %WORKSPACE%\libiconv\include\iconv.h        ..\include\
REM copy %WORKSPACE%\libiconv\include\libcharset.h   ..\include\
REM copy %WORKSPACE%\libiconv\include\localcharset.h ..\include\

copy %WORKSPACE%\zlib\lib\zlib.lib .
copy %WORKSPACE%\zlib\bin\zlib.dll .
REM copy %WORKSPACE%\libiconv\lib\libcharset.lib .
REM copy %WORKSPACE%\libiconv\bin\libcharset.dll .
REM copy %WORKSPACE%\libiconv\lib\libiconv.lib iconv.lib
REM copy %WORKSPACE%\libiconv\bin\libiconv.dll iconv.dll
REM copy %WORKSPACE%\libiconv\lib\libiconv.lib .
REM copy %WORKSPACE%\libiconv\bin\libiconv.dll .

REM Note iconv=no; it can be easily set to yes, the script is ready for that, but we don't want to use it. We have APR Iconv.
cscript configure.js ^
compiler=msvc ^
prefix=%WORKSPACE%\target\ ^
bindir=%WORKSPACE%\target\bin ^
incdir=%WORKSPACE%\target\include ^
libdir=%WORKSPACE%\target\lib ^
sodir=%WORKSPACE%\target\bin ^
include=%WORKSPACE%\libiconv\include\;%WORKSPACE%\zlib\include\ ^
lib=%WORKSPACE%\zlib\lib\;%WORKSPACE%\libiconv\lib\ ^
debug=no ^
zlib=yes ^
threads=native ^
icu=no ^
iconv=no ^
cruntime="'/MD /O2 /Ob2 /Zi'"

echo BINPREFIX=%WORKSPACE%\target\bin>>config.msvc

nmake /f Makefile.msvc all

nmake /f Makefile.msvc install

nmake /f Makefile.msvc install-libs

popd

REM set "PATH=%WORKSPACE%\libiconv\bin;%WORKSPACE%\zlib\bin;%PATH%"
set "PATH=%WORKSPACE%\zlib\bin;%PATH%"

%WORKSPACE%\target\bin\testlimits.exe
IF NOT %ERRORLEVEL% == 0 ( exit 1 )

copy %WORKSPACE%\ChangeLog %WORKSPACE%\target\
copy %WORKSPACE%\Copyright %WORKSPACE%\target\
copy %WORKSPACE%\AUTHORS   %WORKSPACE%\target\
copy %WORKSPACE%\README    %WORKSPACE%\target\

for /f %%x in ('pushd %WORKSPACE% ^& git log --pretty^=format:%%h -n 1 ^& popd') do set GIT_HEAD=%%x
echo %GIT_HEAD%

pushd %WORKSPACE%\target\
zip -r -9 %WORKSPACE%\libxml2-%BRANCH_OR_TAG%-%GIT_HEAD%-64.zip .
sha1sum.exe %WORKSPACE%\libxml2-%BRANCH_OR_TAG%-%GIT_HEAD%-64.zip>%WORKSPACE%\libxml2-%BRANCH_OR_TAG%-%GIT_HEAD%-64.zip.sha1
popd

SET WORKSPACEPOSSIX=%WORKSPACE:\=/%
IF "%RUN_STATIC_ANALYSIS%" equ "true" (
    REM use --force to expand all levels of all macros, kinda slow (single digit minutes even with such a small project)
    cppcheck --enable=all --inconclusive --std=c89 ^
    -I%WORKSPACEPOSSIX%/include/ ^
    -I%WORKSPACEPOSSIX%/zlib/include/ ^
    --output-file=cppcheck.log %WORKSPACEPOSSIX%
)
