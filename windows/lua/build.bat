REM @author: Michal Karm Babacek <karm@fedoraproject.org>
REM This script builds lua

REM Build environment
set "PATH=C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build;C:\Program Files\Cppcheck;%PATH%"
call vcvars64

REM Additional Luac source
copy luac-repo\luac.c .

REM Build
cl /MD /O2 /Ob2 /Zi /c /DLUA_BUILD_AS_DLL /DLUA_COMPAT_5_1 /DLUA_COMPAT_MODULE *.c
IF NOT %ERRORLEVEL% == 0 ( exit 1 )
ren lua.obj lua.o
IF NOT %ERRORLEVEL% == 0 ( exit 1 )
ren luac.obj luac.o
IF NOT %ERRORLEVEL% == 0 ( exit 1 )
link /DLL /IMPLIB:lua-%BRANCH_OR_TAG%.lib /OUT:lua-%BRANCH_OR_TAG%.dll *.obj
IF NOT %ERRORLEVEL% == 0 ( exit 1 )
link /OUT:lua.exe lua.o lua-%BRANCH_OR_TAG%.lib
IF NOT %ERRORLEVEL% == 0 ( exit 1 )
lib /OUT:lua-%BRANCH_OR_TAG%-static.lib *.obj
IF NOT %ERRORLEVEL% == 0 ( exit 1 )
link /OUT:luac.exe luac.o lua-%BRANCH_OR_TAG%-static.lib
IF NOT %ERRORLEVEL% == 0 ( exit 1 )

REM Test
REM for %g in (%LUA_SMOKE_TEST_URL%) do lua %~nxg
lua tests-repo\strings.lua
IF NOT %ERRORLEVEL% == 0 ( exit 1 )

REM Prepare package
mkdir %WORKSPACE%\target\bin
mkdir %WORKSPACE%\target\include
mkdir %WORKSPACE%\target\lib

copy %WORKSPACE%\*.exe %WORKSPACE%\target\bin\
copy %WORKSPACE%\*.dll %WORKSPACE%\target\bin\
copy %WORKSPACE%\*.lib %WORKSPACE%\target\lib\
copy %WORKSPACE%\*.pdb %WORKSPACE%\target\lib\
copy %WORKSPACE%\*.h   %WORKSPACE%\target\include

copy %WORKSPACE%\license.html %WORKSPACE%\target\
copy %WORKSPACE%\bugs %WORKSPACE%\target\

for /f %%x in ('pushd %WORKSPACE% ^& git log --pretty^=format:%%h -n 1 ^& popd') do set GIT_HEAD=%%x
echo %GIT_HEAD%

pushd %WORKSPACE%\target\
zip -r -9 %WORKSPACE%\lua-%BRANCH_OR_TAG%-%GIT_HEAD%-64.zip .
sha1sum.exe %WORKSPACE%\lua-%BRANCH_OR_TAG%-%GIT_HEAD%-64.zip>%WORKSPACE%\lua-%BRANCH_OR_TAG%-%GIT_HEAD%-64.zip.sha1
popd

SET WORKSPACEPOSSIX=%WORKSPACE:\=/%
IF "%RUN_STATIC_ANALYSIS%" equ "true" (
    REM use --force to expand all levels of all macros, kinda slow (single digit minutes even with such a small project)
    cppcheck --enable=all --inconclusive --std=c99 ^
    --output-file=cppcheck.log %WORKSPACEPOSSIX%
)
