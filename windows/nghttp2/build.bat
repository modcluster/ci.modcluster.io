REM @author: Michal Karm Babacek <karm@fedoraproject.org>
REM This script builds nghttp2

REM Build environment
set "PATH=C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build;C:\Program Files\Cppcheck;%PATH%"
call vcvars64

mkdir %WORKSPACE%\target
mkdir %WORKSPACE%\build

pushd %WORKSPACE%\build

REM Note that some attributes cannot handle backslashes...
SET WORKSPACEPOSSIX=%WORKSPACE:\=/%

cmake -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS_RELEASE="/MD /O2 /Ob2 /Wall /Zi" ^
-DCMAKE_INSTALL_PREFIX=%WORKSPACEPOSSIX%/target/ ..

nmake

nmake install
popd

copy %WORKSPACE%\LICENSE %WORKSPACE%\target\
copy %WORKSPACE%\COPYING %WORKSPACE%\target\
copy %WORKSPACE%\ChangeLog %WORKSPACE%\target\
copy %WORKSPACE%\AUTHORS %WORKSPACE%\target\

for /f %%x in ('pushd %WORKSPACE% ^& git log --pretty^=format:%%h -n 1 ^& popd') do set GIT_HEAD=%%x
echo %GIT_HEAD%

pushd %WORKSPACE%\target\
zip -r -9 %WORKSPACE%\nghttp2-%BRANCH_OR_TAG%-%GIT_HEAD%-64.zip .
sha1sum.exe %WORKSPACE%\nghttp2-%BRANCH_OR_TAG%-%GIT_HEAD%-64.zip>%WORKSPACE%\nghttp2-%BRANCH_OR_TAG%-%GIT_HEAD%-64.zip.sha1
popd

IF "%RUN_STATIC_ANALYSIS%" equ "true" (
    REM use --force to expand all levels of all macros, kinda slow (single digit minutes even with such a small project)
    cppcheck --enable=all --inconclusive --std=c++11  ^
    --output-file=cppcheck.log %WORKSPACEPOSSIX%/src
)
