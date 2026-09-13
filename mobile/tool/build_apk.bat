@echo off
rem Build APK Android (universal + tach theo ABI) cho app "Thong Ke 24" va copy ra dist\.
rem
rem Chay:            tool\build_apk.bat
rem Chi dinh API:    tool\build_apk.bat https://api.vvn.freedev.app/v1
rem
rem Bản release chặn HTTP thường, nên API_BASE_URL nên là HTTPS.
setlocal
if not defined JAVA_HOME set "JAVA_HOME=C:\Program Files\Android\Android Studio\jbr"
set "API_ARG="
if not "%~1"=="" set "API_ARG=--dart-define=API_BASE_URL=%~1"
cd /d "%~dp0.."

echo [1/2] Build APK pho thong (universal, cai duoc cho moi may)...
call flutter build apk --release %API_ARG% || exit /b 1
if not exist dist mkdir dist
copy /y build\app\outputs\flutter-apk\app-release.apk dist\ThongKe24-universal.apk >nul

echo [2/2] Build APK tach theo ABI (nhe hon, khuyen dung cho dien thoai)...
call flutter build apk --release %API_ARG% --split-per-abi || exit /b 1
copy /y build\app\outputs\flutter-apk\app-arm64-v8a-release.apk dist\ThongKe24-arm64-v8a.apk >nul
copy /y build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk dist\ThongKe24-armeabi-v7a.apk >nul
copy /y build\app\outputs\flutter-apk\app-x86_64-release.apk dist\ThongKe24-x86_64.apk >nul

echo.
echo XONG. APK nam trong thu muc dist\
echo Luu y: APK nay dung chu ky debug cua Flutter (cai truc tiep duoc, chua len Google Play).
endlocal

