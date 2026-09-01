@echo off
setlocal
cd /d "%~dp0fader_app"
where flutter >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Flutter is not available in PATH.
  pause
  exit /b 1
)
flutter pub get || exit /b 1
call flutter run -d chrome -t lib/second_main.dart --dart-define=FADER_API_URL=http://127.0.0.1:8000
