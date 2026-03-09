@echo off
echo ========================================
echo Installation NDK 28.0.12433566
echo ========================================
echo.

set SDK_PATH=%LOCALAPPDATA%\Android\Sdk
set SDKMANAGER=%SDK_PATH%\cmdline-tools\latest\bin\sdkmanager.bat

if not exist "%SDKMANAGER%" (
    echo ERREUR: SDK Manager non trouve
    pause
    exit /b 1
)

echo Installation de NDK 28.0.12433566...
echo.

call "%SDKMANAGER%" --install "ndk;28.0.12433566"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo NDK 28.0.12433566 installe!
    echo ========================================
) else (
    echo.
    echo ERREUR lors de l'installation
)

pause
