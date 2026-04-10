@echo off
setlocal enabledelayedexpansion
chcp 65001 > nul

echo ==========================================
echo   YumYum - Automated Launcher
echo ==========================================

:: 1. Backend saltado (Ahora usamos Supabase)
echo [1/2] El backend local ha sido desactivado porque ahora usas Supabase Cloud ^<3
:: if not exist "yumyum-backend\node_modules" (
::     echo Instalando dependencias del servidor...
::     pushd yumyum-backend && call npm install && popd
:: )

:: 2. Start server in a new window (Comentado por migración a Supabase)
:: echo Iniciando servidor local...
:: start "YumYum Backend" cmd /k "cd yumyum-backend && node server.js"

:: 3. Start Flutter application in Chrome automatically
echo [2/2] Starting Flutter application in Chrome...
echo (This may take a few seconds...)
call flutter run -d chrome

endlocal
pause
