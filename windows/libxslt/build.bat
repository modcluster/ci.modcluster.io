REM @author: Michal Karm Babacek <karm@fedoraproject.org>
REM This script builds libxslt

unzip label=%label%\zlib* -d .\zlib
IF NOT %ERRORLEVEL% == 0 ( exit 1 )

unzip label=%label%\libxml2* -d .\libxml2
IF NOT %ERRORLEVEL% == 0 ( exit 1 )

REM Build environment
set "PATH=C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build;C:\Program Files\Cppcheck;%PATH%"
call vcvars64

pushd win32

copy %WORKSPACE%\libxml2\lib\libxml2.lib .

cscript configure.js ^
compiler=msvc ^
prefix="%WORKSPACE%\target" ^
bindir="%WORKSPACE%\target\bin" ^
incdir="%WORKSPACE%\target\include" ^
libdir="%WORKSPACE%\target\lib" ^
sodir="%WORKSPACE%\target\bin" ^
include="%WORKSPACE%\libxml2\include\libxml2;%WORKSPACE%\zlib\include" ^
lib="%WORKSPACE%\libxml2\lib;%WORKSPACE%\zlib\lib" ^
zlib=yes ^
iconv=no ^
cruntime="'/MD /O2 /Ob2 /Zi'"

nmake

nmake install

popd

set "PATH=%WORKSPACE%\zlib\bin;%WORKSPACE%\libxml2\bin;%PATH%"

%WORKSPACE%\target\bin\xsltproc.exe -V
IF NOT %ERRORLEVEL% == 0 ( exit 1 )

copy %WORKSPACE%\ChangeLog %WORKSPACE%\target\
copy %WORKSPACE%\Copyright %WORKSPACE%\target\
copy %WORKSPACE%\AUTHORS   %WORKSPACE%\target\
copy %WORKSPACE%\README    %WORKSPACE%\target\

for /f %%x in ('pushd %WORKSPACE% ^& git log --pretty^=format:%%h -n 1 ^& popd') do set GIT_HEAD=%%x
echo %GIT_HEAD%

pushd %WORKSPACE%\target\
zip -r -9 %WORKSPACE%\libxslt-%BRANCH_OR_TAG%-%GIT_HEAD%-64.zip .
sha1sum.exe %WORKSPACE%\libxslt-%BRANCH_OR_TAG%-%GIT_HEAD%-64.zip>%WORKSPACE%\libxslt-%BRANCH_OR_TAG%-%GIT_HEAD%-64.zip.sha1
popd

SET WORKSPACEPOSSIX=%WORKSPACE:\=/%
IF "%RUN_STATIC_ANALYSIS%" equ "true" (
    REM use --force to expand all levels of all macros, kinda slow (single digit minutes even with such a small project)
    cppcheck --enable=all --inconclusive --std=c89 ^
    -I%WORKSPACEPOSSIX%/include/ ^
    -I%WORKSPACEPOSSIX%/zlib/include/ ^
    -I%WORKSPACEPOSSIX%/libxml2/include/ ^
    --output-file=cppcheck.log %WORKSPACEPOSSIX%
)
