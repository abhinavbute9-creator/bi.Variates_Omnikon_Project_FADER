# FADER — Fatigue Awareness and Driver Engagement Routing

Submission-ready full-stack hackathon prototype for long-route driver fatigue awareness.

## One-domain architecture

```text
Public browser
     │
     ▼
FastAPI service
 ├── /demo/             FADER submission UI
 ├── /api/v1/*          REST backend
 ├── /api/v1/ws/*       realtime WebSocket
 ├── /health            health check
 └── /docs              OpenAPI docs
```

The root URL redirects directly to the FADER UI, so the same URL can be submitted to judges.

## Submission UI

The browser interface is aligned to the original Flutter visual language:

- FADER cyan → deep-blue gradient
- eye/pupil splash entry
- light Material-style dashboard
- deep-blue navigation
- cyan information accents
- red fatigue intervention state
- pre-trip → active journey → end-trip flow

## Routing behavior

The backend requests genuine driving-road geometry in this order:

1. Mapbox Directions if `MAPBOX_ACCESS_TOKEN` is configured.
2. OSRM public road routing when no Mapbox token is present.
3. Haversine fallback for distance/duration only.

If only fallback geometry is available, the public UI does **not** draw the straight interpolation as a road map.

## Local run

From `backend/`:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
.\.venv\Scripts\python.exe -m alembic upgrade head
.\.venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

Open `http://127.0.0.1:8000`.

## Verification

From `backend/`:

```powershell
.\.venv\Scripts\python.exe scripts\smoke_test.py
```

The smoke test covers static UI assets, persistence, route/weather endpoints, risk, CO2, telemetry, fatigue events, WebSocket behavior and trip completion.

See `SUBMISSION_DEPLOY.md` for the deadline deployment steps.
