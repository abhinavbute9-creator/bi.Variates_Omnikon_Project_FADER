@echo off
setlocal
cd /d "%~dp0backend"

if not exist ".venv\Scripts\python.exe" (
  echo [FADER] Creating Python virtual environment...
  python -m venv .venv || exit /b 1
)

call .venv\Scripts\activate.bat
python -m pip install --upgrade pip
pip install -r requirements.txt || exit /b 1

if not exist ".env" copy ".env.example" ".env" >nul
alembic upgrade head || exit /b 1

echo.
echo [FADER] Starting emergency browser fallback...
echo [FADER] Open http://127.0.0.1:8000/demo/
echo [FADER] API docs: http://127.0.0.1:8000/docs
echo.
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
