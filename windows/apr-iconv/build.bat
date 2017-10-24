REM @author: Michal Karm Babacek <karm@fedoraproject.org>
REM This script builds apr-iconv
REM It is kinda garbage, but I don't want to be pushed to building all apr*at once...dunno. apr-iconv is a big TODO.
REM We rely on label being the same. It is probably for the best, gonna keep the same MSVC...

unzip label=%label%\apr*.zip -d .\apr
IF NOT %ERRORLEVEL% == 0 ( exit 1 )

REM Build environment
set "PATH=C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build;C:\Program Files\Cppcheck;%PATH%"
call vcvars64

copy %WORKSPACE%\ci-scripts\windows\apr-iconv\NMakeFiles.patch .
REM copy C:\httpd\ci.modcluster.io\windows\apr-iconv\NMakeFiles.patch .
REM Make sure this is not patch.exe from Strawberry perl...
C:\Users\Administrator\Tools\cmder\vendor\git-for-windows\usr\bin\patch.exe --verbose -p1 -i NMakeFiles.patch
IF NOT %ERRORLEVEL% == 0 ( exit 1 )

copy apr\include\apr.h              .\lib\
copy apr\include\apr_pools.h        .\lib\
copy apr\include\apr_errno.h        .\lib\
copy apr\include\apr_general.h      .\lib\
copy apr\include\apr_want.h         .\lib\
copy apr\include\apr_allocator.h    .\lib\
copy apr\include\apr_thread_mutex.h .\lib\

nmake /f "apriconv.mak" CFG="apriconv - x64 Release" ALL
IF NOT %ERRORLEVEL% == 0 ( exit 1 )

nmake /f "libapriconv.mak" CFG="libapriconv - x64 Release" ALL
IF NOT %ERRORLEVEL% == 0 ( exit 1 )

pushd ccs
nmake /f Makefile.win APR_SOURCE=.. BUILD_MODE="x64 Release"
IF NOT %ERRORLEVEL% == 0 ( exit 1 )
popd

pushd ces
nmake /f Makefile.win APR_SOURCE=.. BUILD_MODE="x64 Release"
IF NOT %ERRORLEVEL% == 0 ( exit 1 )
popd

del /Q /F .\lib\apr.h
del /Q /F .\lib\apr_pools.h
del /Q /F .\lib\apr_errno.h
del /Q /F .\lib\apr_general.h
del /Q /F .\lib\apr_want.h
del /Q /F .\lib\apr_allocator.h
del /Q /F .\lib\apr_thread_mutex.h

mkdir target\include
mkdir target\bin\iconv
mkdir target\lib

copy /Y include\*.h target\include\
copy /Y lib\*.h     target\include\
copy /Y util\*.h    target\include\

copy /Y x64\Release\iconv\*.so          target\bin\iconv\
copy /Y x64\Release\iconv\*.pdb         target\bin\iconv\
copy /Y x64\Release\libapriconv-1.dll   target\bin\
copy /Y x64\Release\libapriconv-1.pdb   target\bin\
copy /Y x64\Release\libapriconv_src.pdb target\bin\

copy /Y x64\Release\libapriconv-1.lib target\lib\
copy /Y x64\LibR\apriconv-1.lib       target\lib\
copy /Y x64\LibR\apriconv-1.pdb       target\lib\

copy /Y AUTHORS target\
copy /Y CHANGES target\
copy /Y COPYING target\
copy /Y LICENSE target\
copy /Y NOTICE  target\
copy /Y README  target\
copy /Y STATUS  target\

for /f %%x in ('pushd %WORKSPACE% ^& git log --pretty^=format:%%h -n 1 ^& popd') do set GIT_HEAD=%%x
echo %GIT_HEAD%

pushd target
zip -r -9 %WORKSPACE%\apr-iconv-%BRANCH_OR_TAG%-%GIT_HEAD%-64.zip .
sha1sum.exe %WORKSPACE%\apr-iconv-%BRANCH_OR_TAG%-%GIT_HEAD%-64.zip>%WORKSPACE%\apr-iconv-%BRANCH_OR_TAG%-%GIT_HEAD%-64.zip.sha1
popd

REM Note that some attributes cannot handle backslashes...
SET WORKSPACEPOSSIX=%WORKSPACE:\=/%

IF "%RUN_STATIC_ANALYSIS%" equ "true" (
    REM use --force to expand all levels of all macros, kinda slow (single digit minutes even with such a small project)
    cppcheck --enable=all --inconclusive --std=c89 ^
    -I%WORKSPACEPOSSIX%/include/ ^
    -I%WORKSPACEPOSSIX%/lib/ ^
    -I%WORKSPACEPOSSIX%/util/ ^
    -I%WORKSPACEPOSSIX%/apr/include/ ^
    --output-file=cppcheck.log %WORKSPACEPOSSIX%
)
