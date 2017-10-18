REM @author: Michal Karm Babacek <karm@fedoraproject.org>
REM This script builds bzip2

mkdir %WORKSPACE%\target\64

REM Build environment
set "PATH=C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build;C:\Program Files\Cppcheck;%PATH%"
call vcvars64
cd %WORKSPACE%\target\64
cmake -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS_RELEASE="/MD /O2 /Ob2 /Wall /Zi" ^
%WORKSPACE%\
nmake
copy %WORKSPACE%\LICENSE .
mkdir include
copy %WORKSPACE%\*.h .\include

zip -r -9 %WORKSPACE%\bzip2-%LUADIST_BZIP2_VERSION%-64.zip include *.exe *.ilk *.pdb *.dll *.lib *.h *.exp LICENSE
sha1sum.exe %WORKSPACE%\bzip2-%LUADIST_BZIP2_VERSION%-64.zip>%WORKSPACE%\bzip2-%LUADIST_BZIP2_VERSION%-64.zip.sha1

IF "%RUN_STATIC_ANALYSIS%" equ "true" (
    REM use --force to expand all levels of all macros, kinda slow (single digit minutes even with such a small project)
    cppcheck --enable=all --inconclusive --std=c89 ^
    --output-file=cppcheck.log %WORKSPACE%\
)
