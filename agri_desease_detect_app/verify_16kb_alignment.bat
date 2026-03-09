@echo off
echo ========================================
echo Verification de l'alignement 16KB
echo ========================================
echo.

set SDK_PATH=%LOCALAPPDATA%\Android\Sdk
set BUILD_TOOLS=%SDK_PATH%\build-tools\35.0.0
set AAB_FILE=build\app\outputs\bundle\release\app-release.aab

if not exist "%AAB_FILE%" (
    echo ERREUR: Le fichier AAB n'existe pas!
    echo Chemin: %AAB_FILE%
    echo.
    echo Veuillez d'abord builder l'app avec:
    echo flutter build appbundle --release
    pause
    exit /b 1
)

echo Verification de l'alignement 16KB...
echo.

"%BUILD_TOOLS%\zipalign" -c -P 16 -v 4 "%AAB_FILE%"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo ✅ SUCCES: L'app est alignee sur 16KB!
    echo ========================================
    echo.
    echo Vous pouvez maintenant uploader le fichier sur Play Console:
    echo %AAB_FILE%
) else (
    echo.
    echo ========================================
    echo ❌ ERREUR: L'app n'est PAS alignee sur 16KB
    echo ========================================
    echo.
    echo Verifiez les bibliotheques natives dans votre projet.
)

echo.
pause
