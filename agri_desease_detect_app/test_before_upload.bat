@echo off
chcp 65001 >nul
echo ========================================
echo 🔍 TEST COMPLET AVANT UPLOAD PLAY STORE
echo ========================================
echo.

set SDK_PATH=%LOCALAPPDATA%\Android\Sdk
set BUILD_TOOLS=%SDK_PATH%\build-tools\35.0.0
set AAB_FILE=build\app\outputs\bundle\release\app-release.aab
set TEMP_DIR=%TEMP%\aab_check

set ERRORS=0

echo [1/5] Vérification de l'existence du fichier AAB...
if not exist "%AAB_FILE%" (
    echo ❌ ERREUR: Le fichier AAB n'existe pas!
    echo    Chemin: %AAB_FILE%
    echo.
    echo    Buildez d'abord avec: flutter build appbundle --release
    pause
    exit /b 1
)
echo ✅ Fichier AAB trouvé
echo.

echo [2/5] Vérification de l'alignement 16KB...
"%BUILD_TOOLS%\zipalign" -c -P 16 -v 4 "%AAB_FILE%" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ❌ ERREUR: L'app n'est PAS alignée sur 16KB
    echo    Google Play va REJETER cette version!
    set ERRORS=1
) else (
    echo ✅ Alignement 16KB correct
)
echo.

echo [3/5] Extraction et analyse du AAB...
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%"
mkdir "%TEMP_DIR%"

rem Extraire le AAB (c'est un fichier ZIP)
powershell -Command "Expand-Archive -Path '%AAB_FILE%' -DestinationPath '%TEMP_DIR%' -Force" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ❌ ERREUR: Impossible d'extraire le AAB
    set ERRORS=1
) else (
    echo ✅ AAB extrait avec succès
)
echo.

echo [4/5] Vérification des bibliothèques natives (.so)...
set FOUND_SO=0
if exist "%TEMP_DIR%\base\lib" (
    for /r "%TEMP_DIR%\base\lib" %%f in (*.so) do (
        set FOUND_SO=1
        echo    Trouvé: %%~nxf
    )
)

if %FOUND_SO% EQU 0 (
    echo ✅ Aucune bibliothèque native trouvée (app Dart pur)
    echo    Pas de problème d'alignement possible
) else (
    echo ⚠️  Bibliothèques natives détectées
    echo    Vérification de l'alignement ELF...
    
    rem Vérifier l'alignement des fichiers .so
    for /r "%TEMP_DIR%\base\lib\arm64-v8a" %%f in (*.so) do (
        echo    Analyse: %%~nxf
        "%SDK_PATH%\ndk\28.0.12433566\toolchains\llvm\prebuilt\windows-x86_64\bin\llvm-readelf.exe" -l "%%f" 2>nul | findstr /C:"align 2**14" >nul
        if %ERRORLEVEL% NEQ 0 (
            echo    ❌ ERREUR: %%~nxf n'est pas aligné sur 16KB
            set ERRORS=1
        ) else (
            echo    ✅ %%~nxf correctement aligné
        )
    )
)
echo.

echo [5/5] Vérification de la signature...
"%BUILD_TOOLS%\apksigner" verify --verbose "%AAB_FILE%" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ❌ ERREUR: Signature invalide ou absente
    set ERRORS=1
) else (
    echo ✅ Signature valide
)
echo.

rem Nettoyage
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%"

echo ========================================
if %ERRORS% EQU 0 (
    echo ✅✅✅ TOUS LES TESTS RÉUSSIS! ✅✅✅
    echo ========================================
    echo.
    echo Votre app est PRÊTE pour Play Store!
    echo Vous pouvez uploader en toute confiance:
    echo %AAB_FILE%
    echo.
    echo Taille du fichier:
    for %%A in ("%AAB_FILE%") do echo %%~zA octets
) else (
    echo ❌❌❌ DES ERREURS ONT ÉTÉ DÉTECTÉES ❌❌❌
    echo ========================================
    echo.
    echo ⚠️  NE PAS UPLOADER SUR PLAY STORE!
    echo.
    echo Google Play va REJETER cette version.
    echo Corrigez les erreurs ci-dessus avant d'uploader.
)
echo.
echo ========================================
pause
