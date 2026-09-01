# FADER — Executable Setup Guide

This repository now has **two runnable frontends** backed by the same FastAPI API:

1. **Browser demo (recommended for immediate judging/demo):** served directly by FastAPI, no Flutter SDK required.
2. **Flutter app:** the original polished interface, now wired to real trip/route/weather/risk/CO2/telemetry/engagement APIs.

The camera / MediaPipe EAR detector is still intentionally not claimed as implemented. The UI exposes an explicit **Simulate fatigue signal** action to demonstrate the complete intervention pipeline honestly.

---

## Fastest Windows launch — one file

From the repository root, double-click or run:

```bat
run_fader.bat
```

The script creates `.venv`, installs requirements, applies Alembic migrations, and starts the backend.

Open:

- Executable FADER browser demo: <http://127.0.0.1:8000/demo/>
- API docs: <http://127.0.0.1:8000/docs>
- Health check: <http://127.0.0.1:8000/health>

The first run needs internet access only if Python packages are not already installed.

---

## Linux/macOS launch

```bash
./run_fader.sh
```

Then open <http://127.0.0.1:8000/demo/>.

---

## Manual backend setup

```bat
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
alembic upgrade head
python -m uvicorn app.main:app --reload --port 8000
```

### Backend verification

Run the isolated smoke test; it uses a temporary database and does not modify `fader.db`:

```bat
cd backend
.venv\Scripts\activate
python scripts\smoke_test.py
```

Expected final line:

```text
FADER smoke test: PASS
```

---

## Flutter web

Keep the backend running in one terminal, then in a second terminal:

```bat
cd fader_app
flutter pub get
flutter test
flutter analyze
flutter run -d chrome
```

`lib/main.dart` now launches the integrated app by default, so `-t lib/second_main.dart` is no longer necessary.

If your backend is not at `http://127.0.0.1:8000`, override it without editing source:

```bat
flutter run -d chrome --dart-define=FADER_API_URL=https://YOUR-BACKEND.example.com
```

The WebSocket URL is derived automatically (`https` → `wss`). You can also explicitly provide `FADER_WS_URL`.

### Android emulator

Without a dart-define, Android automatically uses `http://10.0.2.2:8000`.

### Physical Android phone

Use the development PC's LAN IP or a public HTTPS backend:

```bat
flutter run --dart-define=FADER_API_URL=http://192.168.1.42:8000
```

Both devices must be on the same local network for a LAN address.

---

## What is real in the executable flow

- driver creation and update endpoint
- trip creation/read/end + SQLite persistence
- route calculation (Mapbox if configured, deterministic fallback otherwise)
- weather retrieval (Tomorrow.io if configured, deterministic fallback otherwise)
- fatigue-event persistence + summary endpoint
- telemetry persistence + history endpoint
- transparent composite risk engine
- deterministic cabin CO2 prototype model
- location-aware engagement fallback service
- live WebSocket telemetry broadcast
- browser UI using all of the above
- Flutter UI wired to the same core flow

## What remains a prototype/simulation

- camera capture / MediaPipe Face Mesh / automatic EAR inference
- physical CO2 sensor input
- true geocoding for arbitrary city text (Flutter currently uses five demo cities)
- live roadside POI lookup
- a real LLM provider (the current engagement service is a local fallback knowledge base)

---

## Optional real API keys

Edit `backend/.env`:

```env
MAPBOX_ACCESS_TOKEN=...
WEATHER_API_KEY=...
```

No API key is required for the demo to execute because both integrations have working fallbacks.
