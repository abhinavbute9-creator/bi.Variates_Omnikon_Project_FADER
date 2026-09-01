@echo off
setlocal
cd /d "%~dp0backend"
if not exist ".venv\Scripts\python.exe" (
  echo [ERROR] Backend virtual environment does not exist yet.
  echo Run run_fader.bat once to create it.
  pause
  exit /b 1
)
echo Starting FADER backend in this window...
echo Press Ctrl+C to stop it.
echo.
.venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000
pause
