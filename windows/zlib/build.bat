REM @author: Michal Karm Babacek <karm@fedoraproject.org>
REM This script builds zlib

mkdir %WORKSPACE%\build
mkdir %WORKSPACE%\target

REM Build environment
set "PATH=C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build;C:\Program Files\Cppcheck;%PATH%"
call vcvars64

pushd %WORKSPACE%\build

SET WORKSPACEPOSSIX=%WORKSPACE:\=/%

C:\Users\Administrator\Tools\cmder\vendor\git-for-windows\usr\bin\patch.exe --verbose -p1 %WORKSPACE%\CMakeLists.txt -i %WORKSPACE%\ci-scripts\windows\zlib\CMakeLists.patch

cmake -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS_RELEASE="/MD /O2 /Ob2 /Wall /Zi" ^
-DAMD64=ON -DCMAKE_INSTALL_PREFIX=%WORKSPACEPOSSIX%/target/ ..

nmake
IF NOT %ERRORLEVEL% == 0 ( exit 1 )

example.exe
IF NOT %ERRORLEVEL% == 0 ( exit 1 )

nmake install
popd

copy %WORKSPACE%\ChangeLog %WORKSPACE%\target\
copy %WORKSPACE%\README %WORKSPACE%\target\

for /f %%x in ('pushd %WORKSPACE% ^& git log --pretty^=format:%%h -n 1 ^& popd') do set GIT_HEAD=%%x
echo %GIT_HEAD%

pushd target
zip -r -9 %WORKSPACE%\zlib-%BRANCH_OR_TAG%-%GIT_HEAD%-64.zip .
sha1sum.exe %WORKSPACE%\zlib-%BRANCH_OR_TAG%-%GIT_HEAD%-64.zip>%WORKSPACE%\zlib-%BRANCH_OR_TAG%-%GIT_HEAD%-64.zip.sha1
popd

IF "%RUN_STATIC_ANALYSIS%" equ "true" (
    REM use --force to expand all levels of all macros, kinda slow (single digit minutes even with such a small project)
    cppcheck --enable=all --inconclusive --std=c89 ^
    -I%WORKSPACEPOSSIX%/include/ ^
    -I%WORKSPACEPOSSIX%/contrib/blast/ ^
    -I%WORKSPACEPOSSIX%/contrib/infback9/ ^
    -I%WORKSPACEPOSSIX%/contrib/iostream/ ^
    -I%WORKSPACEPOSSIX%/contrib/iostream2/ ^
    -I%WORKSPACEPOSSIX%/contrib/iostream3/ ^
    -I%WORKSPACEPOSSIX%/contrib/minizip/ ^
    -I%WORKSPACEPOSSIX%/contrib/puff/ ^
    --output-file=cppcheck.log %WORKSPACEPOSSIX%
)
