@echo off
setlocal

REM
REM Convert backslashes to forward slashes for peace of mind.
REM
set CWD=%~dp0
set "CWD=%CWD:\=/%"

REM
REM Check what architecture we are running on
REM
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    echo Detected 64 bit system...
    set SYSARCH=64
) else if "%PROCESSOR_ARCHITECTURE%"=="x86" (
    if "%PROCESSOR_ARCHITEW6432%"=="AMD64" (
        echo Detected 64 bit system running 32 bit shell...
        set SYSARCH=64
    ) else (
        echo Detected 32 bit system...
        set SYSARCH=32
    )
) else (
    echo Error: Could not detect current platform architecture!"
    exit /b 5
)

REM
REM Iterate command line parameters
REM
:checkparams
REM Help option
if "x%~1" == "x-help" (
  call :printhelp "%~nx0"
  exit /b %ERRORLEVEL%
)
if "x%~1" == "x--help" (
  call :printhelp "%~nx0"
  exit /b %ERRORLEVEL%
)
if "x%~1" == "x-?" (
  call :printhelp "%~nx0"
  exit /b %ERRORLEVEL%
)
if "x%~1" == "x/?" (
  call :printhelp "%~nx0"
  exit /b %ERRORLEVEL%
)
if "x%~1" == "x-here" shift& set CHERE_INVOKING=enabled_from_arguments& goto :checkparams
if "x%~1" == "x-target" (
    if "x%~2" == "x" (
        echo Architecture was not defined for -target parameter. 1>&2
        exit /b 2
    )
    set TARGET_ARCH=%~2
)& shift& shift& goto :checkparams
if "x%~1" == "x-directory" (
    if "x%~2" == "x" (
        echo Build directory is not specified for -builddir parameter. 1>&2
        exit /b 2
    )
    if defined BUILD_DIR (
        echo Build directory cannot be defined more than once. 1>&2
        exit /b 3
    )
    if exist %~2 goto skip1
    echo Making new build directory "%~2"
    mkdir %~2
    :skip1
    cd /d "%~2" || (
        echo Cannot set specified build directory "%~2". 1>&2
        exit /b 2
    )
    set BUILD_DIR=%~2
)& shift& shift& goto :checkparams
if "x%~1" == "x-configure" shift& set CONFIGURE=yes& goto :checkparams
if "x%~1" == "x-build" shift& set BUILD=yes& goto :checkparams
if "x%~1" == "x-static" shift& set STATIC=yes& goto :checkparams
if "x%~1" == "x-debug" shift& set DEBUG=yes& goto :checkparams

:next
if not defined CONFIGURE (
    echo CONFIGURE=no
    goto nextparam1
) else (
    echo CONFIGURE=%CONFIGURE%
    goto nextparam1
)
:nextparam1
if not defined BUILD (
    echo BUILD=no
    goto nextparam2
) else (
    echo BUILD=%BUILD%
    goto nextparam2
)
:nextparam2
if not defined STATIC (
    echo STATIC=no
    goto nextparam3
) else (
    echo STATIC=%STATIC%
    goto nextparam3
)
:nextparam3
if not defined DEBUG (
    echo DEBUG=no
    goto nextparam4
) else (
    echo DEBUG=%DEBUG%
    goto nextparam4
)
:nextparam4
if not defined TARGET_ARCH (
    set TARGET_ARCH=amd64
    echo Defaulted TARGET_ARCH to amd64
    goto nextparam5
) else (
    echo TARGET_ARCH=%TARGET_ARCH%
    goto nextparam5
)
:nextparam5
echo BUILD_DIR=%BUILD_DIR%

REM
REM Check if already running in an environment with VS setup
REM
if defined VCINSTALLDIR (
    if defined VisualStudioVersion (
        echo Existing Visual Studio environment version %VisualStudioVersion% detected...
        if "%VisualStudioVersion%"=="15.0" (
            set MSVC_VER=15
            goto msvcdone
        ) else if "%VisualStudioVersion%"=="14.0" (
            set MSVC_VER=14
            goto msvcdone
        ) else if "%VisualStudioVersion%"=="12.0" (
            set MSVC_VER=12
            goto msvcdone
        ) else (
            echo Unknown Visual Studio environment detected '%VisualStudioVersion%', Creating a new one...
        )
    )
)
REM
REM Check for default install locations based on current system architecture
REM
if "%SYSARCH%"=="32" (
    set MSVCVARSDIR=
    set WOWNODE=
) else if "%SYSARCH%"=="64" (
    set MSVCVARSDIR=\amd64
    set WOWNODE=\WOW6432Node
) else (
    echo Error: Running on invalid architecture!
    exit /b 5
)
echo TARGET_ARCH=%TARGET_ARCH%
if "%TARGET_ARCH%" == "64" ( 
    set TARGET_ARCH_BITS=64
) else if "%TARGET_ARCH%" == "amd64" (
    set TARGET_ARCH_BITS=64
) else if "%TARGET_ARCH%" == "x64" (
    set TARGET_ARCH_BITS=64
) else if "%TARGET_ARCH%" == "32" (
    set TARGET_ARCH_BITS=32
) else if "%TARGET_ARCH%" == "Win32" (
    set TARGET_ARCH_BITS=32
) else if "%TARGET_ARCH%" == "x86" (
    set TARGET_ARCH_BITS=32
) else (
    echo Error: Invalid target architecture specified!
    exit /b 5
)
reg.exe query "HKLM\SOFTWARE%WOWNODE%\Microsoft\VisualStudio\SxS\VS7" /v "15.0" >nul 2>&1
if not ERRORLEVEL 1 (
    echo Visual Studio 2017 installation detected...
    for /f "skip=2 tokens=2,*" %%a in ('reg.exe query "HKLM\SOFTWARE%WOWNODE%\Microsoft\VisualStudio\SxS\VS7" /v "15.0"') do (
        if exist "%%bVC\Auxiliary\Build\vcvars%TARGET_ARCH_BITS%.bat" (
            set VSINSTALLDIR=%%b
            echo Found vcvars file at "%%bVC\Auxiliary\Build\vcvars%TARGET_ARCH_BITS%.bat"
            call "%%bVC\Auxiliary\Build\vcvars%TARGET_ARCH_BITS%.bat" >nul 2>&1
            goto breakoutmsvc15
        ) else (
            echo Error: vcvars "%%bVC\Auxiliary\Build\vcvars%TARGET_ARCH_BITS%.bat" not found!
        )
    )
    exit /b 5
    :breakoutmsvc15
    set MSVC_VER=15
    goto msvcdone
)
reg.exe query "HKLM\Software%WOWNODE%\Microsoft\VisualStudio\14.0" /v "InstallDir" >nul 2>&1
if not ERRORLEVEL 1 (
    echo Visual Studio 2015 installation detected...
    for /f "skip=2 tokens=2,*" %%a in ('reg.exe query "HKLM\Software%WOWNODE%\Microsoft\VisualStudio\14.0" /v "InstallDir"') do (
        if exist "%%b..\..\VC\bin%MSVCVARSDIR%\vcvars%TARGET_ARCH_BITS%.bat" (
            set VSINSTALLDIR=%%b..\..\
            echo Found vcvars file at "%%b..\..\VC\bin%MSVCVARSDIR%\vcvars%TARGET_ARCH_BITS%.bat"
            call "%%b..\..\VC\bin%MSVCVARSDIR%\vcvars%TARGET_ARCH_BITS%.bat" >nul 2>&1
            goto breakoutmsvc14
        ) else (
            echo Error: vcvars "%%b..\..\VC\bin%MSVCVARSDIR%\vcvars%TARGET_ARCH_BITS%.bat" not found!
        )
    )
    exit /b 5
    :breakoutmsvc14
    set MSVC_VER=14
    goto msvcdone
)
reg.exe query "HKLM\Software%WOWNODE%\Microsoft\VisualStudio\12.0" /v "InstallDir" >nul 2>&1
if not ERRORLEVEL 1 (
    echo Visual Studio 2013 installation detected...
    for /f "skip=2 tokens=2,*" %%a in ('reg.exe query "HKLM\Software%WOWNODE%\Microsoft\VisualStudio\12.0" /v "InstallDir"') do (
        if exist "%%b..\..\VC\bin%MSVCVARSDIR%\vcvars%TARGET_ARCH_BITS%.bat" (
            set VSINSTALLDIR=%%b..\..\
            echo Found vcvars file at "%%b..\..\VC\bin%MSVCVARSDIR%\vcvars%TARGET_ARCH_BITS%.bat"
            call "%%b..\..\VC\bin%MSVCVARSDIR%\vcvars%TARGET_ARCH_BITS%.bat" >nul 2>&1
            goto breakoutmsvc12
        ) else (
            echo Error: vcvars "%%b..\..\VC\bin%MSVCVARSDIR%\vcvars%TARGET_ARCH_BITS%.bat" not found!
        )
    )
     exit /b 5
    :breakoutmsvc12
    set MSVC_VER=12
    goto msvcdone
)
reg.exe query "HKLM\Software%WOWNODE%\Microsoft\VisualStudio\9.0" /v "InstallDir" >nul 2>&1
if not ERRORLEVEL 1 (
    echo Visual Studio 2008 installation detected...
    for /f "skip=2 tokens=2,*" %%a in ('reg.exe query "HKLM\Software%WOWNODE%\Microsoft\VisualStudio\12.0" /v "InstallDir"') do (
        if exist "%%b..\..\VC\bin%MSVCVARSDIR%\vcvars%TARGET_ARCH_BITS%.bat" (
            set VSINSTALLDIR=%%b..\..\
            echo Found vcvars file at "%%b..\..\VC\bin%MSVCVARSDIR%\vcvars%TARGET_ARCH_BITS%.bat"
            call "%%b..\..\VC\bin%MSVCVARSDIR%\vcvars%TARGET_ARCH_BITS%.bat" >nul 2>&1
            goto breakoutmsvc9
        ) else (
            echo Error: vcvars "%%b..\..\VC\bin%MSVCVARSDIR%\vcvars%TARGET_ARCH_BITS%.bat" not found!
        )
    )
     exit /b 5
    :breakoutmsvc9
    set MSVC_VER=9
    goto msvcdone
)
REM
REM If none were found check for an environment variable to help locate the VS installation
REM
if defined VS140COMNTOOLS (
    if exist "%VS140COMNTOOLS%\..\..\VC\vcvars%TARGET_ARCH_BITS%.bat" (
        set VSINSTALLDIR=%VS140COMNTOOLS%\..\..\
        echo Visual Studio 2015 environment detected through environment variable...
        call "%VS140COMNTOOLS%\..\..\VC\vcvars%TARGET_ARCH_BITS%.bat" >nul 2>&1
        set MSVC_VER=14
        goto msvcdone
    )
)
if defined VS120COMNTOOLS (
    if exist "%VS120COMNTOOLS%\..\..\VC\vcvars%TARGET_ARCH_BITS%.bat" (
        set VSINSTALLDIR=%VS120COMNTOOLS%\..\..\
        echo Visual Studio 2013 environment detected through environment variable...
        call "%VS120COMNTOOLS%\..\..\VC\vcvars%TARGET_ARCH_BITS%.bat" >nul 2>&1
        set MSVC_VER=12
        goto msvcdone
    )
)
echo Error: Could not find valid Visual Studio installation!
exit /b 6

:msvcdone

echo VSINSTALLDIR=%VSINSTALLDIR%

:checkconfigure
if defined CONFIGURE (
    echo Configuring...
    goto doconfigure
)
:checkbuild
if defined BUILD (
    echo Building...
    goto dobuild
)

:doconfigure
if not defined DEBUG (set BUILD_TYPE=Release) else (set BUILD_TYPE=Debug)
if not defined STATIC (set CRT_TYPE_RELEASE=MD& set CRT_TYPE_DEBUG=MDd) else (set CRT_TYPE_RELEASE=MT& set CRT_TYPE_DEBUG=MTd)
if "x%TARGET_ARCH_BITS%" == "x64" (set ARCH=x64) else (set ARCH=x86)
if "x%ARCH%" == "xx64" (set LLVM_BIN_PATH=C:/PROGRA~1/LLVM/bin) else (set LLVM_BIN_PATH=C:/PROGRA~2/LLVM/bin)
if "x%ARCH%" == "xx64" (set GENERATOR_PLATFORM=x64) else (set GENERATOR_PLATFORM=)

set ZLIB_PATH=%CWD%third-party/zlib
set ZLIB_LIBRARY_PATH=%ZLIB_PATH%/%ARCH%
set ZLIB_INCLUDE_PATH=%ZLIB_PATH%
echo ZLIB_PATH is %ZLIB_PATH%

cmake -H. -G"Visual Studio 15 2017" -Bbuild^
        -DBUILD_SHARED_LIBS=Off^
        -DLLVM_INCLUDE_TESTS=Off^
        -DLLVM_ENABLE_RTTI=0^
        -DLLVM_ENABLE_DIA_SDK=1^
        -DLLVM_USE_CRT_RELEASE=%CRT_TYPE_RELEASE%^
        -DLLVM_USE_CRT_DEBUG=%CRT_TYPE_DEBUG%^
        -DLLVM_TARGETS_TO_BUILD="X86"^
        -DHAVE_LIBZ=1^
        -DCMAKE_C_FLAGS="/I%ZLIB_INCLUDE_PATH% /DLLVM_ENABLE_DIA_SDK"^
        -DCMAKE_CXX_FLAGS="/I%ZLIB_INCLUDE_PATH% /DLLVM_ENABLE_DIA_SDK"^
        -DCMAKE_EXE_LINKER_FLAGS="%ZLIB_LIBRARY_PATH%/zlibstatic.lib"^
        -DCMAKE_STATIC_LINKER_FLAGS="%ZLIB_LIBRARY_PATH%/zlibstatic.lib"^
        -DCMAKE_SHARED_LINKER_FLAGS="%ZLIB_LIBRARY_PATH%/zlibstatic.lib"^
        -DCMAKE_GENERATOR_PLATFORM=%GENERATOR_PLATFORM%^
        -DCMAKE_BUILD_TYPE=%BUILD_TYPE%^
        %CWD%

if defined BUILD goto checkbuild
exit /b 0

:dobuild
cmake --build . --config %BUILD_TYPE%
exit /b 0

:printhelp
echo Usage:
echo     %~1 [options]
echo.
echo Options:
echo     -configure                   Configure the project
echo     -build                       Build the project
echo     -static                      Configure and build the project statically
echo     -debug                       Build project with debug configuration
echo     -target ARCH                 Set the target architecture: [ 64 ^| amd64 ^| x64 ^| 32 ^| Win32 ^| x86 ]
echo     -directory DIRECTORY         Use specified DIRECTORY for build directory
echo     -help ^| --help ^| -? ^| /?     Display this help and exit
echo.
echo Examples:
echo     build-llvm.bat -configure -build -static -target x64 -directory build-release-x64
echo     build-llvm.bat -configure -build -static -target x86 -directory build-release-x32
echo.
exit /b 0

pause>nul
