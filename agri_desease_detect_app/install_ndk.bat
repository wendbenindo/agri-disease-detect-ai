@echo off
echo ========================================
echo Installation du Android NDK r28
echo ========================================
echo.

set SDK_PATH=%LOCALAPPDATA%\Android\Sdk
set SDKMANAGER=%SDK_PATH%\cmdline-tools\latest\bin\sdkmanager.bat

echo Verification du SDK Manager...
if not exist "%SDKMANAGER%" (
    echo ERREUR: SDK Manager non trouve
    echo Installez Android Studio d'abord
    pause
    exit /b 1
)

echo.
echo Installation du NDK version 28.0.12433566...
echo Cela peut prendre quelques minutes...
echo.

call "%SDKMANAGER%" "ndk;28.0.12433566"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo NDK installe avec succes!
    echo ========================================
    echo.
    echo Maintenant, rebuilder l'app:
    echo   flutter clean
    echo   flutter build appbundle --release
) else (
    echo.
    echo ERREUR lors de l'installation du NDK
)

pause
