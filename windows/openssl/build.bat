REM @author: Michal Karm Babacek <karm@fedoraproject.org>
REM This script builds OpenSSL

REM Build environment
set "PATH=C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build;C:\Program Files\Cppcheck;%PATH%"
set "PATH=%PATH%;C:\Program Files\NASM"

call vcvars64

mkdir %WORKSPACE%\target

perl Configure VC-WIN64A --prefix=%WORKSPACE%\target

if NOT "%TAGNAME%"=="%TAGNAME:OpenSSL_1_0_2=%" (
    call ms\do_nasm
    call ms\do_win64a
    nmake -f ms\ntdll.mak
    IF NOT %ERRORLEVEL% == 0 ( exit 1 )
    nmake -f ms\ntdll.mak test
    IF NOT %ERRORLEVEL% == 0 ( exit 1 )
    nmake -f ms\ntdll.mak install
    IF NOT %ERRORLEVEL% == 0 ( exit 1 )
) ELSE (
    nmake
    IF NOT %ERRORLEVEL% == 0 ( exit 1 )
    nmake test
    IF NOT %ERRORLEVEL% == 0 ( exit 1 )
    nmake install
    IF NOT %ERRORLEVEL% == 0 ( exit 1 )
)

copy %WORKSPACE%\AUTHORS %WORKSPACE%\target\
copy %WORKSPACE%\CHANGES %WORKSPACE%\target\
copy %WORKSPACE%\CONTRIBUTING %WORKSPACE%\target\
copy %WORKSPACE%\LICENSE %WORKSPACE%\target\

pushd %WORKSPACE%\target\
zip -r -9 %WORKSPACE%\%TAGNAME%-64.zip .
sha1sum.exe %WORKSPACE%\%TAGNAME%-64.zip>%WORKSPACE%\%TAGNAME%-64.zip.sha1
popd

IF "%RUN_STATIC_ANALYSIS%" equ "true" (
    REM use --force to expand all levels of all macros, kinda slow (single digit minutes even with such a small project)
    cppcheck --enable=all --inconclusive --std=c89  ^
    --output-file=cppcheck.log %WORKSPACE%
)
