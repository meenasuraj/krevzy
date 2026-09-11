@echo off
setlocal
cd /d %~dp0
call flutter clean || exit /b 1
call flutter pub get || exit /b 1
call flutter analyze || exit /b 1
call flutter test || exit /b 1
call flutter build appbundle --release || exit /b 1
echo.
echo KREVZY release build completed. Configure a real release keystore before publishing.
