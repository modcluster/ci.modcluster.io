REM @author: Michal Karm Babacek <karm@fedoraproject.org>
REM This script builds libiconv from LuaDist https://github.com/LuaDist/

mkdir %WORKSPACE%\target
mkdir %WORKSPACE%\build
REM Build environment
set "PATH=C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build;C:\Program Files\Cppcheck;%PATH%"
call vcvars64

REM Note that some attributes cannot handle backslashes...
SET WORKSPACEPOSSIX=%WORKSPACE:\=/%

pushd %WORKSPACE%\build
cmake -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS_RELEASE="/MD /O2 /Ob2 /Wall /Zi" ^
-DCMAKE_INSTALL_PREFIX=%WORKSPACEPOSSIX%/target/ ..
nmake
nmake install
popd

for /f %%x in ('pushd %WORKSPACE% ^& git log --pretty^=format:%%h -n 1 ^& popd') do set GIT_HEAD=%%x
echo %GIT_HEAD%

pushd target
REM Hardcoded libiconv version to remind us of LuaDist's archaic version https://github.com/LuaDist/libiconv
REM We tried to leave LuaDist libiconv via http://git.savannah.gnu.org/cgit/libiconv.git/tree/README.windows#n57
REM but failed horribly. It is a pure hell of cygwin-ish, mingw-ish, autotools and MSVC...
zip -r -9 %WORKSPACE%\libiconv-1.14-%GIT_HEAD%.zip .
sha1sum.exe %WORKSPACE%\libiconv-1.14-%GIT_HEAD%.zip>%WORKSPACE%\libiconv-1.14-%GIT_HEAD%.zip.sha1
popd

IF "%RUN_STATIC_ANALYSIS%" equ "true" (
    REM use --force to expand all levels of all macros, kinda slow (single digit minutes even with such a small project)
    cppcheck --enable=all --inconclusive --std=c89 ^
    -I%WORKSPACEPOSSIX%/include/ ^
    -I%WORKSPACEPOSSIX%/extras/ ^
    --output-file=cppcheck.log %WORKSPACEPOSSIX%
)
