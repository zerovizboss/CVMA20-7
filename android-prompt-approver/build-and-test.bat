@echo off
echo CVMA Prompt Approver - Build and Test Script
echo ===============================================

echo.
echo 1. Building Android APK...
echo.

rem Build the debug APK
call gradlew.bat assembleDebug

if %ERRORLEVEL% neq 0 (
    echo.
    echo ❌ Build failed! Please check the error messages above.
    pause
    exit /b 1
)

echo.
echo ✅ Build successful!
echo.

echo 2. Checking for connected devices...
adb devices

echo.
echo 3. APK location: app\build\outputs\apk\debug\app-debug.apk
echo.

echo 4. To install the APK:
echo    Option A) Use Android Studio: Open project and click Run
echo    Option B) Command line: adb install app\build\outputs\apk\debug\app-debug.apk
echo.

echo 5. To start the WebSocket server:
echo    cd /c/Users/zerov/IdeaProjects
echo    node claude_ws_bridge.js
echo.

echo Build complete! 🚀
pause