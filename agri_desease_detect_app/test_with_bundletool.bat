@echo off
chcp 65001 >nul
echo ========================================
echo 🔍 TEST AVEC BUNDLETOOL (Outil Google)
echo ========================================
echo.

set AAB_FILE=build\app\outputs\bundle\release\app-release.aab
set BUNDLETOOL_URL=https://github.com/google/bundletool/releases/latest/download/bundletool-all.jar
set BUNDLETOOL_JAR=bundletool.jar

rem Vérifier si le AAB existe
if not exist "%AAB_FILE%" (
    echo ❌ ERREUR: Le fichier AAB n'existe pas!
    echo    Buildez d'abord avec: flutter build appbundle --release
    pause
    exit /b 1
)

rem Télécharger bundletool si nécessaire
if not exist "%BUNDLETOOL_JAR%" (
    echo 📥 Téléchargement de bundletool (outil officiel Google)...
    powershell -Command "Invoke-WebRequest -Uri '%BUNDLETOOL_URL%' -OutFile '%BUNDLETOOL_JAR%'" >nul 2>&1
    if %ERRORLEVEL% NEQ 0 (
        echo ❌ ERREUR: Impossible de télécharger bundletool
        echo    Téléchargez manuellement depuis:
        echo    https://github.com/google/bundletool/releases
        pause
        exit /b 1
    )
    echo ✅ Bundletool téléchargé
    echo.
)

echo ========================================
echo TEST 1: Validation du AAB
echo ========================================
java -jar "%BUNDLETOOL_JAR%" validate --bundle="%AAB_FILE%"
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ❌ ERREUR: Le AAB n'est pas valide!
    echo    Google Play va REJETER cette version.
    pause
    exit /b 1
)
echo ✅ AAB valide
echo.

echo ========================================
echo TEST 2: Vérification alignement 16KB
echo ========================================
java -jar "%BUNDLETOOL_JAR%" dump config --bundle="%AAB_FILE%" | findstr "alignment"
echo.
echo Si vous voyez "PAGE_ALIGNMENT_16K" = ✅ Bon
echo Si vous voyez "PAGE_ALIGNMENT_4K" = ❌ Problème
echo.

echo ========================================
echo TEST 3: Informations sur le bundle
echo ========================================
java -jar "%BUNDLETOOL_JAR%" dump manifest --bundle="%AAB_FILE%" | findstr /C:"versionCode" /C:"versionName" /C:"package"
echo.

echo ========================================
echo TEST 4: Taille estimée des APKs
echo ========================================
java -jar "%BUNDLETOOL_JAR%" get-size total --bundle="%AAB_FILE%"
echo.

echo ========================================
echo ✅ TESTS TERMINÉS
echo ========================================
echo.
echo Si tous les tests sont OK, vous pouvez uploader sur Play Store!
echo.
pause
