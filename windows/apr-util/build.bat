REM @author: Michal Karm Babacek <karm@fedoraproject.org>
REM This script builds apr-util
REM We rely on label being the same. It is probably for the best, gonna keep the same MSVC...
unzip label=%label%\apr*.zip -d .\apr
IF NOT %ERRORLEVEL% == 0 ( exit 1 )
unzip arch=64,label=%label%\OpenSSL*.zip -d .\openssl
IF NOT %ERRORLEVEL% == 0 ( exit 1 )

mkdir %WORKSPACE%\target\64
mkdir %WORKSPACE%\build-64

REM Build environment
set "PATH=C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build;C:\Program Files\Cppcheck;%PATH%"
call vcvars64

cd %WORKSPACE%\build-64

REM Note that some attributes cannot handle backslashes...
SET WORKSPACEPOSSIX=%WORKSPACE:\=/%

cmake -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS_RELEASE="/MD /O2 /Ob2 /Wall /Zi" ^
-DAPR_INCLUDE_DIR=%WORKSPACEPOSSIX%/apr/include/ ^
-DAPR_LIBRARIES=%WORKSPACEPOSSIX%/apr/lib/libapr-1.lib;%WORKSPACEPOSSIX%/apr/lib/libaprapp-1.lib ^
-DOPENSSL_ROOT_DIR=%WORKSPACEPOSSIX%/openssl/ -DAPU_HAVE_CRYPTO=ON -DAPU_HAVE_ODBC=ON ^
-DAPU_HAVE_OPENSSL=ON -DINSTALL_PDB=ON -DAPR_BUILD_TESTAPR=ON ^
-DCMAKE_INSTALL_PREFIX=%WORKSPACEPOSSIX%/target/64/ ..

nmake

copy %WORKSPACE%\apr\bin\libapr-1.dll .

.\testall.exe

IF NOT %ERRORLEVEL% == 0 ( exit 1 )

del libapr-1.dll /Q

nmake install

copy %WORKSPACE%\LICENSE %WORKSPACE%\target\64\
copy %WORKSPACE%\NOTICE %WORKSPACE%\target\64\
copy %WORKSPACE%\CHANGES %WORKSPACE%\target\64\

cd %WORKSPACE%\target\64

for /f %%x in ('pushd %WORKSPACE% ^& git log --pretty^=format:%%h -n 1 ^& popd') do set GIT_HEAD=%%x
echo %GIT_HEAD%

zip -r -9 %WORKSPACE%\apr-util-%BRANCH_OR_TAG%-%GIT_HEAD%-64.zip .
sha1sum.exe %WORKSPACE%\apr-util-%BRANCH_OR_TAG%-%GIT_HEAD%-64.zip>%WORKSPACE%\apr-util-%BRANCH_OR_TAG%-%GIT_HEAD%-64.zip.sha1

IF "%RUN_STATIC_ANALYSIS%" equ "true" (
    REM use --force to expand all levels of all macros, kinda slow (single digit minutes even with such a small project)
    cppcheck --enable=all --inconclusive --std=c89 ^
    -I%WORKSPACEPOSSIX%/apr/include/ ^
    --output-file=cppcheck.log %WORKSPACEPOSSIX%
)
