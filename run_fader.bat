@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

set "ROOT=%~dp0"
set "BACKEND=%ROOT%backend"
set "FRONTEND=%ROOT%fader_app"
set "VENV_PY=%BACKEND%\.venv\Scripts\python.exe"
set "BACKEND_OUT=%BACKEND%\fader_backend_stdout.log"
set "BACKEND_ERR=%BACKEND%\fader_backend_stderr.log"
set "BACKEND_PID=%BACKEND%\fader_backend.pid"

echo ============================================================
echo  FADER - Flutter UI + FastAPI Backend
echo ============================================================
echo.

where python >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Python was not found in PATH.
  echo Install Python 3.11+ and enable "Add python.exe to PATH".
  pause
  exit /b 1
)

where flutter >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Flutter was not found in PATH.
  echo Reopen PowerShell after installing/upgrading Flutter, then run this file again.
  pause
  exit /b 1
)

echo [1/6] Preparing backend virtual environment...
cd /d "%BACKEND%"
if not exist "%VENV_PY%" (
  python -m venv .venv
  if errorlevel 1 goto :fail
)

"%VENV_PY%" -m pip install --upgrade pip >nul
"%VENV_PY%" -m pip install -r requirements.txt
if errorlevel 1 goto :fail

if not exist ".env" copy ".env.example" ".env" >nul
"%VENV_PY%" -m alembic upgrade head
if errorlevel 1 goto :fail

echo [2/6] Checking whether FADER backend is already running...
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $r=Invoke-RestMethod 'http://127.0.0.1:8000/health' -TimeoutSec 2; if($r.status -eq 'ok'){exit 0}else{exit 1} } catch { exit 1 }"
if not errorlevel 1 (
  echo [OK] Existing healthy backend detected on port 8000. Reusing it.
  goto :backend_ready
)

if exist "%BACKEND_OUT%" del /q "%BACKEND_OUT%" >nul 2>&1
if exist "%BACKEND_ERR%" del /q "%BACKEND_ERR%" >nul 2>&1
if exist "%BACKEND_PID%" del /q "%BACKEND_PID%" >nul 2>&1

echo [3/6] Starting FastAPI directly with the venv Python...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$p=Start-Process -FilePath '%VENV_PY%' -ArgumentList @('-m','uvicorn','app.main:app','--host','127.0.0.1','--port','8000') -WorkingDirectory '%BACKEND%' -RedirectStandardOutput '%BACKEND_OUT%' -RedirectStandardError '%BACKEND_ERR%' -WindowStyle Normal -PassThru; Set-Content -Path '%BACKEND_PID%' -Value $p.Id"
if errorlevel 1 goto :backend_fail

echo [4/6] Waiting for backend health check ^(up to 60 seconds^)...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ok=$false; for($i=0;$i -lt 60;$i++){ try { $r=Invoke-RestMethod 'http://127.0.0.1:8000/health' -TimeoutSec 2; if($r.status -eq 'ok'){$ok=$true;break} } catch {}; Start-Sleep -Seconds 1 }; if($ok){exit 0}else{exit 1}"
if errorlevel 1 goto :backend_fail

:backend_ready
echo [OK] Backend healthy: http://127.0.0.1:8000/health

echo [5/6] Preparing Flutter dependencies...
cd /d "%FRONTEND%"
call flutter pub get
if errorlevel 1 goto :fail

echo [6/6] Launching your original FADER Flutter interface in Chrome...
echo.
echo Backend : http://127.0.0.1:8000
echo API docs: http://127.0.0.1:8000/docs
echo Flutter : lib/second_main.dart
echo.
call flutter run -d chrome -t lib/second_main.dart --dart-define=FADER_API_URL=http://127.0.0.1:8000
exit /b %errorlevel%

:backend_fail
echo.
echo [ERROR] Backend did not become healthy.
echo.
echo ================= BACKEND STDERR =================
if exist "%BACKEND_ERR%" type "%BACKEND_ERR%"
echo.
echo ================= BACKEND STDOUT =================
if exist "%BACKEND_OUT%" type "%BACKEND_OUT%"
echo.
echo ==================================================
echo Logs are saved at:
echo   %BACKEND_ERR%
echo   %BACKEND_OUT%
echo.
echo Manual diagnostic command:
echo   cd /d "%BACKEND%"
echo   .\.venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000
pause
exit /b 1

:fail
echo.
echo [ERROR] FADER setup/launch failed. Read the command output above.
pause
exit /b 1
