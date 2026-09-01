#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/backend"

if [ ! -x ".venv/bin/python" ]; then
  echo "[FADER] Creating Python virtual environment..."
  python3 -m venv .venv
fi

source .venv/bin/activate
python -m pip install --upgrade pip
pip install -r requirements.txt
[ -f .env ] || cp .env.example .env
alembic upgrade head

echo "[FADER] Starting executable browser demo at http://127.0.0.1:8000/demo/"
echo "[FADER] API docs at http://127.0.0.1:8000/docs"
exec python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
