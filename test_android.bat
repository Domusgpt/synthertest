@echo off
echo ===================================
echo  SYNTHER ANDROID TEST BUILD
echo ===================================
echo.

REM Check if Flutter is in PATH
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: Flutter not found in PATH!
    echo Please install Flutter and add it to your PATH
    echo Visit: https://docs.flutter.dev/get-started/install/windows
    pause
    exit /b 1
)

echo Flutter found. Running doctor...
flutter doctor -v

echo.
echo ===================================
echo  PREPARING BUILD
echo ===================================
echo.

REM Clean and get dependencies
echo Cleaning previous builds...
flutter clean

echo.
echo Getting dependencies...
flutter pub get

echo.
echo ===================================
echo  DEVICE CHECK
echo ===================================
echo.
echo Looking for connected devices...
flutter devices

echo.
echo ===================================
echo  BUILD OPTIONS
echo ===================================
echo.
echo 1. Run on connected device (debug mode with hot reload)
echo 2. Build APK only (for manual installation)
echo 3. Build and install APK
echo 4. Run on device with logs
echo.
set /p choice="Choose option (1-4): "

if "%choice%"=="1" (
    echo.
    echo Running on device in debug mode...
    flutter run
) else if "%choice%"=="2" (
    echo.
    echo Building release APK...
    flutter build apk --release
    echo.
    echo APK built successfully!
    echo Location: build\app\outputs\flutter-apk\app-release.apk
    echo.
    echo You can transfer this APK to your phone via:
    echo - USB cable
    echo - Google Drive
    echo - Email
    echo.
) else if "%choice%"=="3" (
    echo.
    echo Building and installing APK...
    flutter build apk --release
    echo.
    echo Installing on device...
    adb install build\app\outputs\flutter-apk\app-release.apk
) else if "%choice%"=="4" (
    echo.
    echo Running with logs...
    flutter run --verbose
) else (
    echo Invalid choice!
)

echo.
pause