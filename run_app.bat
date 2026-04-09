@echo off
setlocal enabledelayedexpansion
chcp 65001 > nul

echo ==========================================
echo   YumYum - Automated Launcher
echo ==========================================

:: 1. Check backend dependencies
if not exist "yumyum-backend\node_modules" (
    echo [1/3] Installing server dependencies...
    pushd yumyum-backend
    call npm install
    popd
) else (
    echo [1/3] Server dependencies are ready.
)

:: 2. Start server in a new window
echo [2/3] Starting server in background...
start "YumYum Backend" cmd /k "cd yumyum-backend && node server.js"

:: 3. Start Flutter application in Chrome automatically
echo [3/3] Starting Flutter application in Chrome...
echo (This may take a few seconds...)
call flutter run -d chrome

endlocal
pause
