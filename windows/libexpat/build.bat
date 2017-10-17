REM @author: Michal Karm Babacek <karm@fedoraproject.org>
REM This script builds libexpat

mkdir %WORKSPACE%\target\64
mkdir %WORKSPACE%\expat\build-64

patch.exe --verbose -p1 CMakeLists.txt -i ci-scripts\windows\libexpat\libexpat-win-CMakeLists.patch

REM Build environment
set "PATH=C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build;C:\Program Files\Cppcheck;%PATH%"
call vcvars64

cd %WORKSPACE%\expat\build-64

SET WORKSPACEPOSSIX=%WORKSPACE:\=/%

cmake -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS_RELEASE="/O2 /Wall /Zi" -DCMAKE_CXX_FLAGS_RELEASE="/O2 /Wall /Zi" ^
-DBUILD_tests=OFF -DBUILD_shared=ON -DCMAKE_INSTALL_PREFIX=%WORKSPACEPOSSIX%/target/64/ ..

nmake

echo "This is not well formed">test.xml
xmlwf\xmlwf.exe test.xml | findstr /R /C:"syntax error"
IF NOT %ERRORLEVEL% == 0 ( exit 1 )

nmake install

copy %WORKSPACE%\expat\Changes %WORKSPACE%\target\64\
copy %WORKSPACE%\expat\COPYING %WORKSPACE%\target\64\
copy %WORKSPACE%\expat\README %WORKSPACE%\target\64\

copy %WORKSPACE%\expat\build-64\*.pdb %WORKSPACE%\target\64\bin\

xcopy %WORKSPACE%\expat\build-64\examples %WORKSPACE%\target\64\examples\ /s /e /h

cd %WORKSPACE%\target\64

zip -r -9 %WORKSPACE%\libexpat-%TAGNAME%-64.zip .
sha1sum.exe %WORKSPACE%\libexpat-%TAGNAME%-64.zip>%WORKSPACE%\libexpat-%TAGNAME%-64.zip.sha1

IF "%RUN_STATIC_ANALYSIS%" equ "true" (
    REM use --force to expand all levels of all macros, kinda slow (single digit minutes even with such a small project)
    cppcheck --enable=all --inconclusive --std=c89 ^
    -I%WORKSPACEPOSSIX%/include/ ^
    --output-file=cppcheck.log %WORKSPACEPOSSIX%
)
