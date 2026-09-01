# FADER — Final Verification

Validated on 2026-09-01 in the build sandbox.

## Passed

- `python -m compileall -q app scripts`
- `python scripts/smoke_test.py`
- `node --check backend/web_demo/app.js`
- live Uvicorn startup on an isolated SQLite database
- `GET /health` returned 200
- `GET /demo/` returned 200 and served the executable browser application
- OpenAPI document served successfully with 17 registered path entries
- `bash -n run_fader.sh`
- bundled `backend/fader.db` confirmed migrated and clean: 0 rows in all five business tables

## Smoke-test coverage

The isolated smoke test verifies browser assets, driver create/update, trip create/end, route calculation, weather, engagement, risk, CO2, telemetry persistence/history, fatigue persistence/summary, WebSocket ping/pong, and WebSocket telemetry updates.

## Environment limitation

Flutter and Dart SDKs are not installed in the build sandbox, so the modified Flutter source could not be freshly compiled here. The guaranteed executable demo is therefore the FastAPI-served `/demo/` website, which requires only Python. The integrated Flutter source remains included for use on a machine with Flutter installed.

## Windows launch

Run `run_fader.bat` from the project root, then open `http://127.0.0.1:8000/demo/`.

## Linux/macOS launch

Run `./run_fader.sh`, then open `http://127.0.0.1:8000/demo/`.
