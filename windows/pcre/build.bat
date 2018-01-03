REM @author: Michal Karm Babacek <karm@fedoraproject.org>
REM This script builds pcre

unzip label=%label%\bzip2* -d .\bzip2
unzip label=%label%\zlib*  -d .\zlib

REM Build environment
set "PATH=C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build;C:\Program Files\Cppcheck;%PATH%"
call vcvars64

mkdir %WORKSPACE%\target
mkdir %WORKSPACE%\build

pushd %WORKSPACE%\build

REM Note that some attributes cannot handle backslashes...
SET WORKSPACEPOSSIX=%WORKSPACE:\=/%

cmake -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS_RELEASE="/MD /O2 /Ob2 /Wall /Zi" ^
-DBUILD_SHARED_LIBS=ON ^
-DBUILD_STATIC_LIBS=OFF ^
-DPCRE_NEWLINE=ANYCRLF ^
-DPCRE_SUPPORT_JIT=ON ^
-DPCRE_SUPPORT_UTF=ON ^
-DPCRE_SUPPORT_UNICODE_PROPERTIES=ON ^
-DPCRE_SUPPORT_BSR_ANYCRLF=ON ^
-DCMAKE_INSTALL_ALWAYS=1 ^
-DINSTALL_MSVC_PDB=ON ^
-DBZIP2_INCLUDE_DIR=%WORKSPACEPOSSIX%/bzip2/include ^
-DBZIP2_LIBRARIES=%WORKSPACEPOSSIX%/bzip2/bz2.lib ^
-DZLIB_INCLUDE_DIR=%WORKSPACEPOSSIX%/zlib/include ^
-DZLIB_LIBRARY=%WORKSPACEPOSSIX%/zlib/lib/zlib.lib ^
-DCMAKE_INSTALL_PREFIX=%WORKSPACEPOSSIX%/target/ ..

nmake

pcre_jit_test.exe
IF NOT %ERRORLEVEL% == 0 ( exit 1 )
pcre_scanner_unittest.exe
IF NOT %ERRORLEVEL% == 0 ( exit 1 )
pcrecpp_unittest.exe
IF NOT %ERRORLEVEL% == 0 ( exit 1 )

nmake install
popd

copy %WORKSPACE%\COPYING %WORKSPACE%\target\
copy %WORKSPACE%\LICENCE %WORKSPACE%\target\
copy %WORKSPACE%\AUTHORS %WORKSPACE%\target\

pushd %WORKSPACE%\target\
zip -r -9 %WORKSPACE%\%TAGNAME%-64.zip .
sha1sum.exe %WORKSPACE%\%TAGNAME%-64.zip>%WORKSPACE%\%TAGNAME%-64.zip.sha1
popd

IF "%RUN_STATIC_ANALYSIS%" equ "true" (
    REM use --force to expand all levels of all macros, kinda slow (single digit minutes even with such a small project)
    cppcheck --enable=all --inconclusive --std=c99  ^
    -I%WORKSPACEPOSSIX%/zlib/include/ ^
    -I%WORKSPACEPOSSIX%/zlib/ ^
    -I%WORKSPACEPOSSIX%/bzip2/include/ ^
    --output-file=cppcheck.log %WORKSPACEPOSSIX%/src
)
