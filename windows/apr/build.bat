REM @author: Michal Karm Babacek <karm@fedoraproject.org>
REM This script builds apr
REM We rely on label being the same. It is probably for the best, gonna keep the same MSVC...
unzip arch=64,label=%label%\libxml2* -d .\libxml2
unzip arch=64,label=%label%\OpenSSL* -d .\openssl

mkdir %WORKSPACE%\target\64
mkdir %WORKSPACE%\build-64

REM Build environment
set "PATH=C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build;C:\Program Files\Cppcheck;%PATH%"
call vcvars64

cd %WORKSPACE%\build-64

REM Note that some attributes cannot handle backslashes...
SET WORKSPACEPOSSIX=%WORKSPACE:\=/%

cmake -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=Release ^
-DAPU_USE_EXPAT=OFF -DAPU_USE_LIBXML2=ON ^
-DLIBXML2_INCLUDE_DIR=%WORKSPACEPOSSIX%/libxml2/include/libxml2 ^
-DLIBXML2_LIBRARIES=%WORKSPACEPOSSIX%/libxml2/lib/libxml2.lib;^
%WORKSPACEPOSSIX%/libxml2/lib/libxml2_a.lib;%WORKSPACEPOSSIX%/libxml2/lib/libxml2_a_dll.lib ^
-DLIBXML2_XMLLINT_EXECUTABLE=%WORKSPACEPOSSIX%/libxml2/bin/xmllint.exe -DOPENSSL_ROOT_DIR=%WORKSPACEPOSSIX%/openssl/ ^
-DAPR_INSTALL_PRIVATE_H=ON -DAPU_HAVE_CRYPTO=ON -DAPU_HAVE_ODBC=ON -DAPR_HAVE_IPV6=ON ^
-DINSTALL_PDB=ON -DAPR_BUILD_TESTAPR=ON -DLIBXML2_ICONV_INCLUDE_DIR=%WORKSPACEPOSSIX%/libxml2/include/ ^
-DLIBXML2_ICONV_LIBRARIES=%WORKSPACEPOSSIX%/libxml2/lib/libiconv.lib;%WORKSPACEPOSSIX%/libxml2/lib/libcharset.lib ^
-DCMAKE_INSTALL_PREFIX=%WORKSPACEPOSSIX%/target/64/ ..

nmake

.\testall.exe -v testatomic testdir testdso testdup testenv testescape testfile testfilecopy ^
testfileinfo testflock testfmt testfnmatch testargs testhash testipsub testlock testcond ^
testlfs testmmap testnames testoc testpath testpipe testpoll testpools testproc testprocmutex ^
testrand testsleep testshm testsock testsockets testsockopt teststr teststrnatcmp testtable ^
testtemp testthread testtime testud testvsn testskiplist

IF NOT %ERRORLEVEL% == 0 ( exit 1 )

nmake install

copy %WORKSPACE%\LICENSE %WORKSPACE%\target\64\
copy %WORKSPACE%\NOTICE %WORKSPACE%\target\64\
copy %WORKSPACE%\CHANGES %WORKSPACE%\target\64\

cd %WORKSPACE%\target\64

for /f %%x in ('pushd %WORKSPACE% ^& git log --pretty^=format:%%h -n 1 ^& popd') do set GIT_HEAD=%%x
echo %GIT_HEAD%

zip -r -9 %WORKSPACE%\apr-%BRANCH_OR_TAG%-%GIT_HEAD%-64.zip .
sha1sum.exe %WORKSPACE%\apr-%BRANCH_OR_TAG%-%GIT_HEAD%-64.zip>%WORKSPACE%\apr-%BRANCH_OR_TAG%-%GIT_HEAD%-64.zip.sha1

IF "%RUN_STATIC_ANALYSIS%" equ "true" (
    REM use --force to expand all levels of all macros, kinda slow (single digit minutes even with such a small project)
    cppcheck --enable=all --inconclusive --std=c89 ^
    -I%WORKSPACEPOSSIX%/libxml2/include/libxml2 ^
    -I%WORKSPACEPOSSIX%/libxml2/include/ ^
    --output-file=cppcheck.log %WORKSPACEPOSSIX%
)
